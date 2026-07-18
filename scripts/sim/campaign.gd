class_name CampaignSim
## The fixed 180-day campaign: qualification requirements, the 30-day
## final supply trial (driven by real inventory/dispatch), victory scoring
## and every failure path.

const CAMPAIGN_DAYS := 180
const QUALIFY_BY_DAY := 150
const TRIAL_DAYS := 30
const TRIAL_UNITS := 12000
const TRIAL_MIN_QUALITY := 1          # Select or better on average
const TRIAL_MAX_REJECT_PCT := 3.0
const TRIAL_ON_TIME_PCT := 98.0


static func days_remaining(s: Dictionary) -> int:
	return maxi(0, CAMPAIGN_DAYS - int(s.day) + 1)


## The qualification checklist shown permanently in the UI.
static func requirements(s: Dictionary) -> Array[Dictionary]:
	var val := EconomySim.valuation(s)
	var stores := RetailSim.count_profitable_stores(s)
	var tier := MachineSim.facility_tier(s)
	var no_debt := int(s.loan_missed) == 0 and int(s.payroll_missed) == 0 and float(s.cash) >= 0.0
	var out: Array[Dictionary] = [
		{"label": "Company valuation ≥ $2,500,000", "value": "$%s" % _fmt(val),
			"done": val >= 2_500_000.0, "progress": clampf(val / 2_500_000.0, 0.0, 1.0)},
		{"label": "Startup loan fully repaid", "value": "$%s left" % _fmt(float(s.loan_balance)),
			"done": float(s.loan_balance) <= 0.0,
			"progress": 1.0 - clampf(float(s.loan_balance) / DataRegistry.bal("loan_principal", 45000.0), 0.0, 1.0)},
		{"label": "3 owned & profitable stores", "value": "%d / 3" % stores,
			"done": stores >= 3, "progress": stores / 3.0},
		{"label": "Tier 5 main facility", "value": "Tier %d" % tier,
			"done": tier >= 5, "progress": tier / 5.0},
		{"label": "Automation score ≥ 85%", "value": "%.0f%%" % float(s.automation_score),
			"done": float(s.automation_score) >= 85.0, "progress": float(s.automation_score) / 85.0},
		{"label": "Compliance ≥ 90", "value": "%.0f" % float(s.compliance),
			"done": float(s.compliance) >= 90.0, "progress": float(s.compliance) / 90.0},
		{"label": "Reputation ≥ 80", "value": "%.0f" % float(s.reputation),
			"done": float(s.reputation) >= 80.0, "progress": float(s.reputation) / 80.0},
		{"label": "All licenses unlocked", "value": "%d / 4" % s.licenses.size(),
			"done": s.licenses.size() >= 4, "progress": s.licenses.size() / 4.0},
		{"label": "No overdue debt/taxes/payroll", "value": "OK" if no_debt else "Overdue!",
			"done": no_debt, "progress": 1.0 if no_debt else 0.0},
		{"label": "≥ 30 days left for the trial", "value": "%d days left" % days_remaining(s),
			"done": days_remaining(s) >= TRIAL_DAYS, "progress": 1.0 if days_remaining(s) >= TRIAL_DAYS else 0.0},
	]
	return out


static func qualified(s: Dictionary) -> bool:
	for r in requirements(s):
		if not bool(r.done):
			return false
	return true


static func start_trial(s: Dictionary) -> bool:
	if s.trial.active:
		return false
	if not qualified(s):
		EventBus.notify("Qualification requirements are not yet met.", "warning")
		return false
	s.trial = {"active": true, "day": 1, "delivered": 0, "rejected": 0,
		"on_time": 0, "scheduled": 0, "quality_sum": 0, "profit": 0.0,
		"failed": false, "violations": 0, "start_cash": float(s.cash)}
	Game.milestone("Entered the Verdantia City Supply Contract trial")
	EventBus.trial_started.emit()
	EventBus.notify("FINAL TRIAL: deliver %d units in %d days!" % [TRIAL_UNITS, TRIAL_DAYS], "info")
	return true


## Hourly dispatch during the trial: pulls REAL packaged inventory
## (Select+ quality, tested, unexpired) from the warehouse.
static func trial_tick_hour(s: Dictionary, hour: int) -> void:
	if hour < 8 or hour > 19:
		return
	@warning_ignore("integer_division")
	var per_hour := TRIAL_UNITS / TRIAL_DAYS / 12 + 1   # ~34/hour
	var remaining := per_hour
	for pid: String in DataRegistry.products.keys():
		if remaining <= 0:
			break
		var res := InventorySim.consume(s, "warehouse", pid, remaining, true, TRIAL_MIN_QUALITY)
		var taken := int(res.taken)
		if taken > 0:
			remaining -= taken
			s.trial.delivered = int(s.trial.delivered) + taken
			s.trial.quality_sum = int(s.trial.quality_sum) + int(res.quality_sum)
			var pay: float = DataRegistry.bal("trial_unit_price", 9.5) * taken
			EconomySim.earn(s, pay, "City contract delivery")
			s.trial.profit = float(s.trial.profit) + pay - float(res.cost)
			Game.log_action("fulfillment", true)
	# Also accept Standard-quality units but count them as rejected units.
	if remaining > 0:
		for pid: String in DataRegistry.products.keys():
			if remaining <= 0:
				break
			var res2 := InventorySim.consume(s, "warehouse", pid, remaining, true, 0)
			if int(res2.taken) > 0:
				remaining -= int(res2.taken)
				s.trial.rejected = int(s.trial.rejected) + int(res2.taken)


static func trial_close_day(s: Dictionary, report: Dictionary) -> void:
	@warning_ignore("integer_division")
	var daily_target := TRIAL_UNITS / TRIAL_DAYS
	s.trial.scheduled = int(s.trial.scheduled) + daily_target
	var so_far := int(s.trial.delivered)
	var expected := int(s.trial.scheduled)
	if so_far >= expected - daily_target / 5:  # small grace per day
		s.trial.on_time = int(s.trial.on_time) + 1
	report["trial_day"] = int(s.trial.day)
	report["trial_delivered"] = so_far
	report["trial_target"] = expected
	EventBus.trial_day_result.emit({"day": s.trial.day, "delivered": so_far, "target": expected})
	s.trial.day = int(s.trial.day) + 1
	if int(s.trial.day) > TRIAL_DAYS:
		_finish_trial(s)


static func trial_status(s: Dictionary) -> Dictionary:
	var t: Dictionary = s.trial
	var delivered := int(t.delivered)
	var reject_pct := 0.0
	if delivered + int(t.rejected) > 0:
		reject_pct = float(t.rejected) / float(delivered + int(t.rejected)) * 100.0
	var avg_q := 0.0
	if delivered > 0:
		avg_q = float(t.quality_sum) / float(delivered)
	var on_time_pct := 100.0
	if int(t.day) > 1:
		on_time_pct = float(t.on_time) / float(int(t.day) - 1) * 100.0
	return {"delivered": delivered, "target": TRIAL_UNITS, "reject_pct": reject_pct,
		"avg_quality": avg_q, "on_time_pct": on_time_pct,
		"profit": float(t.profit), "violations": int(t.violations), "day": int(t.day)}


static func _finish_trial(s: Dictionary) -> void:
	var st := trial_status(s)
	var ok: bool = int(st.delivered) >= TRIAL_UNITS \
		and float(st.avg_quality) >= TRIAL_MIN_QUALITY \
		and float(st.reject_pct) < TRIAL_MAX_REJECT_PCT \
		and float(st.on_time_pct) >= TRIAL_ON_TIME_PCT \
		and int(st.violations) == 0 \
		and float(st.profit) > 0.0
	s.trial.active = false
	if ok:
		_win(s, st)
	else:
		s.trial.failed = true
		if days_remaining(s) >= TRIAL_DAYS:
			EventBus.notify("Trial failed — but there is still time to try again.", "error")
		else:
			_lose(s, "The final supply trial failed with no time left to repeat it.")


static func _win(s: Dictionary, trial_stats: Dictionary) -> void:
	var audit := ComplianceSim.run_audit(s)
	var scores := {
		"efficiency": clampf(float(s.automation_score), 0.0, 100.0),
		"profitability": clampf(EconomySim.valuation(s) / 40000.0, 0.0, 100.0),
		"quality": clampf(float(trial_stats.avg_quality) / 3.0 * 100.0, 0.0, 100.0),
		"reliability": clampf(float(trial_stats.on_time_pct), 0.0, 100.0),
		"staff_welfare": StaffSim.average_morale(s),
		"sustainability": clampf(100.0 - float(s.daily.wasted_units), 40.0, 100.0),
		"customer_satisfaction": _avg_satisfaction(s),
		"reputation": float(s.reputation),
		"compliance": float(s.compliance),
	}
	var total := 0.0
	for v in scores.values():
		total += float(v)
	total /= scores.size()
	var grade := "C"
	if total >= 92.0: grade = "S"
	elif total >= 84.0: grade = "A"
	elif total >= 72.0: grade = "B"
	s.campaign_over = true
	s.campaign_result = {"won": true, "grade": grade, "total": total, "scores": scores,
		"audit": audit, "trial": trial_stats, "day": s.day,
		"milestones": (s.stats.milestones as Array).duplicate()}
	Game.milestone("WON the Verdantia City Supply Contract")
	ObjectivesSim.grant_achievement(s, "ach_win_campaign")
	EventBus.campaign_won.emit(s.campaign_result)


static func _lose(s: Dictionary, reason: String) -> void:
	if s.campaign_over:
		return
	s.campaign_over = true
	s.campaign_result = {"won": false, "reason": reason, "day": s.day,
		"summary": {
			"valuation": EconomySim.valuation(s),
			"cash": float(s.cash),
			"revenue": float(s.stats.total_revenue),
			"units_sold": int(s.stats.total_units_sold),
			"stores": RetailSim.count_profitable_stores(s),
			"automation": float(s.automation_score),
		},
		"milestones": (s.stats.milestones as Array).duplicate()}
	EventBus.campaign_lost.emit(reason, s.campaign_result)


## All campaign failure paths, checked at day close.
static func check_failure(s: Dictionary) -> void:
	if s.campaign_over:
		return
	if int(s.day) > CAMPAIGN_DAYS and not s.trial.active:
		_lose(s, "Day 180 ended without winning the city contract.")
	elif int(s.overdraft_days) >= 5:
		_lose(s, "Cash stayed below the overdraft limit for five consecutive days.")
	elif int(s.loan_missed) >= 3:
		_lose(s, "Three scheduled loan payments were missed. The bank called in the loan.")
	elif int(s.payroll_missed) >= 2:
		_lose(s, "Payroll was missed twice. Your staff walked out and your license was suspended.")
	elif float(s.compliance) <= 2.0:
		_lose(s, "The operating license was permanently revoked after repeated serious violations.")


## Company stage progression (visible facility transformation elsewhere).
static func check_stage_advance(s: Dictionary) -> void:
	var stage := int(s.stage)
	var val := EconomySim.valuation(s)
	var next_stage := stage
	match stage:
		1: if val >= 40000.0 and s.staff.size() >= 1: next_stage = 2
		2: if val >= 120000.0 and int(s.stats.batches_completed) >= 8: next_stage = 3
		3: if val >= 350000.0 and Game.has_research("conveyors"): next_stage = 4
		4: if val >= 800000.0 and RetailSim.count_profitable_stores(s) >= 2: next_stage = 5
		5: if val >= 1_600_000.0 and float(s.automation_score) >= 60.0: next_stage = 6
	if next_stage != stage:
		s.stage = next_stage
		s.research_points = int(s.research_points) + 3
		Game.milestone("Reached stage: %s" % Game.STAGE_NAMES[next_stage - 1])
		# New licenses unlock with stages.
		if next_stage >= 3 and not "logistics_license" in (s.licenses as Array):
			s.licenses.append("logistics_license")
		if next_stage >= 5 and not "testing_license" in (s.licenses as Array):
			s.licenses.append("testing_license")
		EventBus.stage_advanced.emit(next_stage)
		EventBus.notify("Company stage up: %s!" % Game.STAGE_NAMES[next_stage - 1], "success")


static func _avg_satisfaction(s: Dictionary) -> float:
	var t := 0.0
	var n := 0
	for st: Dictionary in s.stores.values():
		if bool(st.owned):
			t += float(st.satisfaction)
			n += 1
	return t / maxf(1.0, float(n))


static func _fmt(v: float) -> String:
	var i := int(v)
	var out := ""
	var neg := i < 0
	i = absi(i)
	while i >= 1000:
		out = ",%03d%s" % [i % 1000, out]
		i /= 1000
	return ("-" if neg else "") + str(i) + out
