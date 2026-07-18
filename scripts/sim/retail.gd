class_name RetailSim
## Stores, customers and purchase decisions. The SAME decision function
## drives visible 3D customers in the active store and the deterministic
## background simulation of non-active stores.

const OPEN_MINUTE := 9 * 60
const CLOSE_MINUTE := 21 * 60


static func new_store(id: String, district: String, owned: bool) -> Dictionary:
	return {
		"id": id, "district": district, "owned": owned, "open": false,
		"appeal": 30.0, "security": 20.0, "queue_capacity": 5,
		"satisfaction": 60.0, "regulars": 0,
		"daily_sales": 0.0, "daily_profit": 0.0, "profit_history": [],
		"staff_ids": [], "manager": false,
		"minute_accum": 0.0,
	}


static func store_purchase_cost(district_id: String) -> float:
	var d: Dictionary = DataRegistry.districts.get(district_id, {})
	return float(d.get("store_cost", 60000.0))


static func buy_store(s: Dictionary, district_id: String) -> bool:
	var id := "store_%s" % district_id
	if s.stores.has(id) and bool(s.stores[id].owned):
		EventBus.notify("You already own a store in this district.", "info")
		return false
	var cost := store_purchase_cost(district_id)
	if not EconomySim.spend(s, cost, "New store: %s" % district_id, "planning"):
		return false
	s.stores[id] = new_store(id, district_id, true)
	Game.milestone("Opened a store in %s" % str(DataRegistry.districts[district_id].get("name", district_id)))
	EventBus.notify("New store acquired in %s!" % str(DataRegistry.districts[district_id].get("name", district_id)), "success")
	return true


static func set_open(s: Dictionary, store_id: String, open_it: bool) -> void:
	var st: Dictionary = s.stores.get(store_id, {})
	if st.is_empty():
		return
	st.open = open_it
	if open_it:
		EventBus.store_opened.emit(store_id)
	else:
		EventBus.store_closed.emit(store_id)


## Per-minute customer arrivals for every open owned store.
## The active (visible) store spawns real customer agents via the world;
## background stores resolve arrivals immediately through decide_and_buy.
static func tick_minute(s: Dictionary, minute: int) -> void:
	if minute < OPEN_MINUTE or minute >= CLOSE_MINUTE:
		for st: Dictionary in s.stores.values():
			if bool(st.open) and minute >= CLOSE_MINUTE:
				set_open(s, str(st.id), false)
		return
	for st: Dictionary in s.stores.values():
		if not bool(st.owned) or not bool(st.open):
			continue
		var rate := arrival_rate_per_minute(s, st)
		st.minute_accum = float(st.minute_accum) + rate
		while float(st.minute_accum) >= 1.0:
			st.minute_accum = float(st.minute_accum) - 1.0
			if str(st.id) == str(ActiveStoreProxy.active_store_id):
				ActiveStoreProxy.request_visible_customer(str(st.id))
			else:
				var archetype := pick_archetype(s, str(st.district))
				decide_and_buy(s, str(st.id), archetype, true)


static func arrival_rate_per_minute(s: Dictionary, st: Dictionary) -> float:
	var district: Dictionary = DataRegistry.districts.get(str(st.district), {})
	var base := float(district.get("traffic", 0.5)) * DataRegistry.bal("customer_base_rate", 0.09)
	base *= 0.5 + float(s.reputation) / 100.0
	base *= 0.6 + float(st.appeal) / 120.0
	base *= MarketSim.district_demand(s, str(st.district))
	base *= 1.0 + float(st.regulars) * 0.004
	for ev: Dictionary in s.events_active:
		base *= float(ev.get("effects", {}).get("traffic_mult", 1.0))
	return base


static func pick_archetype(s: Dictionary, district_id: String) -> Dictionary:
	var district: Dictionary = DataRegistry.districts.get(district_id, {})
	var weights: Dictionary = district.get("archetype_weights", {})
	var total := 0.0
	for v in weights.values():
		total += float(v)
	var r := randf() * maxf(total, 0.001)
	for k in weights.keys():
		r -= float(weights[k])
		if r <= 0.0:
			return DataRegistry.archetypes.get(str(k), {})
	return DataRegistry.archetypes.values()[0] if not DataRegistry.archetypes.is_empty() else {}


## Core purchase decision. Returns a result dict used both by background
## sim (applied instantly) and by visible customers (as their script).
## When `apply` is true the sale is executed against real inventory.
static func decide_and_buy(s: Dictionary, store_id: String, archetype: Dictionary,
		apply: bool) -> Dictionary:
	var st: Dictionary = s.stores.get(store_id, {})
	if st.is_empty() or archetype.is_empty():
		return {"bought": false, "reason": "closed"}
	s.daily.customers += 1
	s.stats.customers_served = int(s.stats.customers_served) + 1
	# Score every available product for this archetype.
	var best_pid := ""
	var best_score := 0.0
	var best_price := 0.0
	var budget := float(archetype.get("budget", 40.0)) * randf_range(0.7, 1.3)
	var pref_cats: Array = archetype.get("categories", [])
	for pid: String in DataRegistry.products.keys():
		var qty := InventorySim.sellable_qty(s, store_id, pid)
		if qty <= 0:
			continue
		var p: Dictionary = DataRegistry.products[pid]
		var price := EconomySim.effective_price(s, pid)
		if price > budget:
			continue
		var score := 1.0
		if str(p.category) in pref_cats:
			score += 1.4
		score += float(p.trend) * MarketSim.trend_factor(s, pid) * float(archetype.get("trend_sensitivity", 0.3))
		score += float(p.wellness) * float(archetype.get("wellness_focus", 0.2))
		var value_ratio := float(p.retail_price) / maxf(price, 0.01)
		score += (value_ratio - 1.0) * float(archetype.get("price_sensitivity", 0.5)) * 2.0
		score += randf_range(0.0, 0.4)
		if score > best_score:
			best_score = score
			best_pid = pid
			best_price = price
	var quality_expect := float(archetype.get("quality_expectation", 1.0))
	if best_pid == "":
		if apply:
			_after_visit(s, st, false, "Nothing I want in stock…")
		return {"bought": false, "reason": "no_product", "feedback": "Nothing I want in stock…"}
	# Service and queue check.
	var service := StaffSim.best_skill_at_store(s, store_id, "sales") / 10.0
	var happy_chance := 0.45 + service * 0.35 + float(st.appeal) / 300.0
	var result := {"bought": true, "product_id": best_pid, "price": best_price}
	if apply:
		var consumed := InventorySim.consume(s, "display:%s" % store_id, best_pid, 1)
		if int(consumed.taken) < 1:
			_after_visit(s, st, false, "It was sold out right in front of me!")
			return {"bought": false, "reason": "sold_out"}
		var quality := float(consumed.quality_sum)
		EconomySim.earn(s, best_price, "Sale: %s" % str(DataRegistry.products[best_pid].name))
		st.daily_sales = float(st.daily_sales) + best_price
		st.daily_profit = float(st.daily_profit) + best_price - float(consumed.cost)
		s.daily.units_sold += 1
		s.stats.total_units_sold = int(s.stats.total_units_sold) + 1
		var happy := quality >= quality_expect - 0.5 and randf() < happy_chance
		_after_visit(s, st, happy, _feedback_for(happy, quality, quality_expect, best_price))
		Game.log_action("fulfillment", true)
		result["quality"] = int(quality)
		result["happy"] = happy
		EventBus.sale_made.emit(store_id, best_pid, best_price, int(quality))
	return result


static func _feedback_for(happy: bool, quality: float, expect: float, _price: float) -> String:
	if happy:
		return ["Exactly what I wanted!", "Great quality.", "I trust this brand.",
			"Nice store!", "I'll be back."].pick_random()
	if quality < expect:
		return ["Too expensive for this quality.", "Expected better quality.",
			"Not up to my standards."].pick_random()
	return ["The wait was too long.", "Service could be better.",
		"Hmm, not impressed today."].pick_random()


static func _after_visit(s: Dictionary, st: Dictionary, happy: bool, feedback: String) -> void:
	if happy:
		s.daily.customers_happy += 1
		st.satisfaction = minf(100.0, float(st.satisfaction) + 0.25)
		if randf() < 0.15:
			st.regulars = int(st.regulars) + 1
		s.reputation = minf(100.0, float(s.reputation) + 0.03)
	else:
		st.satisfaction = maxf(0.0, float(st.satisfaction) - 0.4)
		if randf() < 0.1 and int(st.regulars) > 0:
			st.regulars = int(st.regulars) - 1
		s.reputation = maxf(0.0, float(s.reputation) - 0.02)
	EventBus.customer_feedback.emit(str(st.id), feedback, happy)
	EventBus.reputation_changed.emit(float(s.reputation))


## Restock a store display from warehouse stock (player action or policy).
static func restock(s: Dictionary, store_id: String, product_id: String, qty: int,
		automated: bool = false) -> int:
	var via_backroom := InventorySim.transfer(s, "warehouse", "display:%s" % store_id, product_id, qty)
	if via_backroom > 0:
		Game.log_action("restock", automated)
	return via_backroom


static func count_profitable_stores(s: Dictionary) -> int:
	var n := 0
	for st: Dictionary in s.stores.values():
		if not bool(st.owned):
			continue
		var hist: Array = st.get("profit_history", [])
		var recent := 0.0
		for h in hist.slice(maxi(0, hist.size() - 7)):
			recent += float(h)
		if recent > 0.0:
			n += 1
	return n
