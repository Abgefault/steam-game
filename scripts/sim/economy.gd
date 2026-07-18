class_name EconomySim
## Money, transactions, pricing policies, daily accounting, loan, valuation.
## All functions are static and operate on the Game state dictionary so the
## same logic drives play, background simulation and headless tests.


static func spend(s: Dictionary, amount: float, reason: String, dept: String = "") -> bool:
	var overdraft: float = DataRegistry.bal("overdraft_limit", -15000.0)
	if float(s.cash) - amount < overdraft:
		EventBus.notify("Not enough cash for %s ($%s)." % [reason, _fmt(amount)], "error")
		return false
	s.cash = float(s.cash) - amount
	s.daily.expenses += amount
	_log(s, -amount, reason, dept)
	EventBus.cash_changed.emit(float(s.cash), -amount, reason)
	return true


static func earn(s: Dictionary, amount: float, reason: String) -> void:
	s.cash = float(s.cash) + amount
	s.daily.revenue += amount
	s.stats.total_revenue += amount
	_log(s, amount, reason, "")
	EventBus.cash_changed.emit(float(s.cash), amount, reason)


static func _log(s: Dictionary, amount: float, reason: String, dept: String) -> void:
	var entry := {"day": s.day, "amount": amount, "reason": reason, "dept": dept}
	s.daily.transactions.append(entry)
	if s.daily.transactions.size() > 400:
		s.daily.transactions.pop_front()
	EventBus.transaction_logged.emit(entry)


static func _fmt(v: float) -> String:
	return String.num(v, 0)


## Effective retail price for a product under the current policy/overrides.
static func effective_price(s: Dictionary, product_id: String) -> float:
	if s.prices.has(product_id):
		return float(s.prices[product_id])
	var p: Dictionary = DataRegistry.products.get(product_id, {})
	if p.is_empty():
		return 0.0
	var base := float(p.retail_price)
	match str(s.price_policy):
		"budget": return snappedf(base * 0.85, 0.5)
		"premium": return snappedf(base * 1.2, 0.5)
		"match_market": return snappedf(base * MarketSim.category_demand(s, str(p.category)), 0.5)
		"maximize_margin": return snappedf(base * 1.12, 0.5)
		"clear_expiring": return snappedf(base * 0.7, 0.5)
		_: return base


static func unit_cost(product_id: String) -> float:
	var p: Dictionary = DataRegistry.products.get(product_id, {})
	return float(p.get("base_cost", 0.0))


static func gross_margin(s: Dictionary, product_id: String) -> float:
	var price := effective_price(s, product_id)
	if price <= 0.0:
		return 0.0
	return (price - unit_cost(product_id)) / price


## Company valuation: cash + inventory + equipment + store goodwill - debt.
static func valuation(s: Dictionary) -> float:
	var v := float(s.cash)
	for lot: Dictionary in s.lots:
		v += float(lot.qty) * unit_cost(str(lot.product_id)) * 1.4
	for m: Dictionary in s.machines.values():
		var def: Dictionary = DataRegistry.machines.get(str(m.def_id), {})
		var tiers: Array = def.get("tiers", [])
		var t: int = clampi(int(m.tier) - 1, 0, tiers.size() - 1)
		if t < tiers.size():
			v += float(tiers[t].get("cost", 0.0)) * 0.55 * (float(m.condition) / 100.0)
	for st: Dictionary in s.stores.values():
		if bool(st.owned):
			v += DataRegistry.bal("store_goodwill", 90000.0) * (0.5 + float(st.appeal) / 200.0)
			var hist: Array = st.get("profit_history", [])
			var recent := 0.0
			for h in hist.slice(maxi(0, hist.size() - 7)):
				recent += float(h)
			v += maxf(0.0, recent) * 30.0
	v += float(s.reputation) * 2500.0
	v -= float(s.loan_balance)
	return maxf(0.0, v)


## End-of-day books: rent, payroll, utilities, loan, taxes; failure counters.
static func close_day(s: Dictionary, finished_day: int) -> Dictionary:
	var d := DataRegistry
	var report: Dictionary = {
		"day": finished_day,
		"revenue": float(s.daily.revenue),
		"units_sold": int(s.daily.units_sold),
		"customers": int(s.daily.customers),
		"customers_happy": int(s.daily.customers_happy),
		"wasted_units": int(s.daily.wasted_units),
	}
	# Rent for every owned store + facility.
	var rent := d.bal("facility_rent", 220.0)
	for st: Dictionary in s.stores.values():
		if bool(st.owned) and str(st.id) != "store_old_market":
			rent += float(DataRegistry.districts[str(st.district)].get("rent", 300.0))
	spend(s, rent, "Rent", "reporting")
	# Utilities scale with machinery and tier.
	var power := 0.0
	for m: Dictionary in s.machines.values():
		power += 6.0 + 4.0 * float(m.tier) * (1.0 + (100.0 - float(m.condition)) / 150.0)
	power *= MarketSim.utility_multiplier(s)
	spend(s, power, "Utilities", "reporting")
	# Payroll.
	var payroll := 0.0
	for e: Dictionary in s.staff:
		payroll += float(e.wage)
	if payroll > 0.0:
		if not spend(s, payroll, "Payroll", "reporting"):
			s.payroll_missed = int(s.payroll_missed) + 1
			StaffSim.payroll_missed(s)
			report["payroll_missed"] = true
	# Loan payment every 7 days.
	if float(s.loan_balance) > 0.0 and finished_day % 7 == 0:
		var pay: float = minf(float(s.loan_payment), float(s.loan_balance))
		if spend(s, pay, "Loan payment", "reporting"):
			s.loan_balance = float(s.loan_balance) - pay
			if float(s.loan_balance) <= 0.0:
				s.loan_balance = 0.0
				Game.milestone("Startup loan fully repaid")
				EventBus.notify("Startup loan fully repaid!", "success")
		else:
			s.loan_missed = int(s.loan_missed) + 1
			report["loan_missed"] = true
	# Simple daily tax accrual on profit.
	var profit := float(s.daily.revenue) - float(s.daily.expenses)
	if profit > 0.0:
		spend(s, profit * d.bal("tax_rate", 0.12), "Taxes", "reporting")
	# Overdraft tracking.
	if float(s.cash) < 0.0:
		s.overdraft_days = int(s.overdraft_days) + 1
	else:
		s.overdraft_days = 0
	profit = float(s.daily.revenue) - float(s.daily.expenses)
	report["expenses"] = float(s.daily.expenses)
	report["profit"] = profit
	report["cash"] = float(s.cash)
	report["valuation"] = valuation(s)
	if profit > float(s.stats.best_day_profit):
		s.stats.best_day_profit = profit
	# Store profit history for valuation + qualification.
	for st: Dictionary in s.stores.values():
		if bool(st.owned):
			var ph: Array = st.get("profit_history", [])
			ph.append(float(st.get("daily_profit", 0.0)))
			if ph.size() > 30:
				ph.pop_front()
			st["profit_history"] = ph
			st["daily_profit"] = 0.0
			st["daily_sales"] = 0.0
	# Research points from profitable operation.
	if profit > d.bal("rp_profit_threshold", 400.0):
		s.research_points = int(s.research_points) + 1
	var day_record := report.duplicate()
	s.stats.daily.append(day_record)
	if (s.stats.daily as Array).size() > 200:
		s.stats.daily.pop_front()
	return report
