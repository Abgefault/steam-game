extends Node
## Authoritative company / campaign state and top-level simulation API.
## All mutable game data lives in `state` (a plain Dictionary) so that
## save/load, tests and background simulation share one source of truth.
## Heavy domain logic lives in scripts/sim/*.gd static helpers.

const QUALITY_NAMES: PackedStringArray = ["Standard", "Select", "Premium", "Exceptional"]
const STAGE_NAMES: PackedStringArray = [
	"Garage Operation", "Small Business", "Local Supplier",
	"Industrial Operation", "Citywide Company", "Contract Contender"]

var state: Dictionary = {}
var in_session: bool = false


func _ready() -> void:
	EventBus.hour_passed.connect(_on_hour)
	EventBus.minute_passed.connect(_on_minute)


## Fresh campaign state. Company identity comes from the setup screen.
func new_state(company_name: String = "Green Empire", brand: String = "Affordable",
		color_primary: String = "3fa34d", color_secondary: String = "1f2d24",
		logo: int = 0, seed_value: int = 0) -> Dictionary:
	var d := DataRegistry
	var s: Dictionary = {
		"version": 1,
		"company": {
			"name": company_name, "brand": brand,
			"color_primary": color_primary, "color_secondary": color_secondary,
			"logo": logo,
		},
		"seed": seed_value if seed_value != 0 else randi(),
		"day": 1,
		"stage": 1,
		"cash": d.bal("start_cash", 12000.0),
		"loan_balance": d.bal("loan_principal", 45000.0),
		"loan_payment": d.bal("loan_payment", 750.0),
		"loan_missed": 0,
		"payroll_missed": 0,
		"overdraft_days": 0,
		"reputation": d.bal("start_reputation", 35.0),
		"compliance": d.bal("start_compliance", 60.0),
		"research_points": 0,
		"research_done": [],
		"licenses": ["retail_basic", "production_basic"],
		"playtime_seconds": 0.0,
		# Raw material inventory (abstract input chain).
		"supplies": {"seed_units": 4, "packaging_units": 60, "spare_parts": 2},
		"raw": {},              # strain_id -> harvested container count
		"conditioned": {},      # strain_id -> conditioned units
		"processed": {},        # category -> processed material units
		"lots": [],             # finished packaged lots (see InventorySim.make_lot)
		"lot_seq": 1,
		"batch_seq": 1,
		"batches": [],          # active production batches
		"machines": {},         # machine_instance_id -> {def_id, tier, condition, room, state,...}
		"conveyors": [],        # connections [{from, to}]
		"stores": {},           # store_id -> store dict
		"staff": [],
		"staff_seq": 1,
		"prices": {},           # product_id -> price override
		"price_policy": "recommended",
		"auto": {               # unlocked automation policies toggled on
			"restock": false, "purchasing": false, "maintenance": false,
			"scheduling": false, "reporting": false,
		},
		"actions": {},          # dept -> {"manual": int, "auto": int} (rolling day)
		"actions_prev": {},     # previous finished day (used for score)
		"automation_score": 0.0,
		"market": MarketSim.new_market(),
		"events_active": [],
		"events_history": [],
		"event_cooldowns": {},
		"objectives": {},       # id -> {"done": bool, "progress": float}
		"achievements": [],
		"tutorial_step": 0,
		"tutorial_done": false,
		"trial": {"active": false, "day": 0, "delivered": 0, "rejected": 0,
			"on_time": 0, "scheduled": 0, "quality_sum": 0, "profit": 0.0,
			"failed": false, "violations": 0},
		"campaign_over": false,
		"campaign_result": {},
		"stats": {"daily": [], "total_revenue": 0.0, "total_units_sold": 0,
			"customers_served": 0, "batches_completed": 0, "best_day_profit": 0.0,
			"milestones": []},
		"pending_report": {},
		"daily": _fresh_daily(),
	}
	# Starting store in Old Market with the attached storefront.
	s.stores["store_old_market"] = RetailSim.new_store("store_old_market", "old_market", true)
	# Starting machinery: one primitive unit of each core step, tier 1, worn.
	var start_machines := ["cultivation", "conditioning", "processing", "lab", "product", "packaging"]
	for m in start_machines:
		s.machines["m_%s_1" % m] = {
			"id": "m_%s_1" % m, "def_id": m, "tier": 1,
			"condition": 62.0 + randf() * 8.0,
			"state": "idle", "batch": -1, "progress": 0.0, "auto_feed": false,
		}
	for o: Dictionary in DataRegistry.objectives.values():
		s.objectives[o["id"]] = {"done": false, "progress": 0.0}
	return s


func _fresh_daily() -> Dictionary:
	return {"revenue": 0.0, "expenses": 0.0, "units_sold": 0, "customers": 0,
		"customers_happy": 0, "wasted_units": 0, "transactions": [],
		"manual_actions": 0, "auto_actions": 0}


func start_new_game(company_name: String, brand: String, cp: String, cs: String, logo: int) -> void:
	state = new_state(company_name, brand, cp, cs, logo)
	seed(int(state.seed))
	SimClock.day = 1
	SimClock.minute_of_day = SimClock.DAY_START_MINUTE
	in_session = true


# ---------------------------------------------------------------- time hooks

func _on_minute(_day: int, minute: int) -> void:
	if not in_session:
		return
	ProductionSim.tick_minute(state)
	RetailSim.tick_minute(state, minute)


func _on_hour(_day: int, hour: int) -> void:
	if not in_session:
		return
	MachineSim.tick_hour(state)
	StaffSim.tick_hour(state, hour)
	AutomationSim.run_policies(state)
	OrdersSim.tick_hour(state, hour)
	if state.trial.active:
		CampaignSim.trial_tick_hour(state, hour)
	ObjectivesSim.check_all(state)


## Called by SimClock when a day finishes. Returns the daily report.
func close_day(finished_day: int) -> Dictionary:
	if not in_session:
		return {}
	var report: Dictionary = EconomySim.close_day(state, finished_day)
	InventorySim.expire_lots(state, finished_day + 1)
	MarketSim.advance_day(state)
	EventsSim.roll_daily(state)
	OrdersSim.daily_update(state)
	ComplianceSim.daily_update(state)
	StaffSim.daily_update(state)
	AutomationSim.finish_day(state)
	if state.trial.active:
		CampaignSim.trial_close_day(state, report)
	CampaignSim.check_stage_advance(state)
	CampaignSim.check_failure(state)
	ObjectivesSim.check_all(state)
	state.day = finished_day + 1
	state.daily = _fresh_daily()
	state.pending_report = report
	if not state.campaign_over and int(SettingsService.get_v("autosave_days")) > 0:
		if finished_day % int(SettingsService.get_v("autosave_days")) == 0:
			SaveService.autosave()
	return report


# ---------------------------------------------------------------- helpers

func cash() -> float:
	return float(state.cash)


func spend(amount: float, reason: String, dept: String = "") -> bool:
	return EconomySim.spend(state, amount, reason, dept)


func earn(amount: float, reason: String) -> void:
	EconomySim.earn(state, amount, reason)


func product(id: String) -> Dictionary:
	return DataRegistry.products.get(id, {})


func price_for(product_id: String) -> float:
	return EconomySim.effective_price(state, product_id)


func has_research(id: String) -> bool:
	return id in (state.research_done as Array)


func stage_name() -> String:
	return STAGE_NAMES[clampi(int(state.stage) - 1, 0, 5)]


func quality_name(q: int) -> String:
	return QUALITY_NAMES[clampi(q, 0, 3)]


## Record an action for the automation score: dept in
## production, quality, packaging, warehouse, planning, restock,
## purchasing, maintenance, scheduling, fulfillment, reporting.
func log_action(dept: String, automated: bool) -> void:
	if not state.actions.has(dept):
		state.actions[dept] = {"manual": 0, "auto": 0}
	if automated:
		state.actions[dept]["auto"] += 1
		state.daily.auto_actions += 1
	else:
		state.actions[dept]["manual"] += 1
		state.daily.manual_actions += 1


func milestone(text: String) -> void:
	state.stats.milestones.append({"day": state.day, "text": text})
	if state.stats.milestones.size() > 60:
		state.stats.milestones.pop_front()


# ---------------------------------------------------------------- save/load

func serialize() -> Dictionary:
	var out: Dictionary = state.duplicate(true)
	out["clock"] = SimClock.serialize()
	return out


func deserialize(d: Dictionary) -> void:
	state = d.duplicate(true)
	state.erase("clock")
	SimClock.deserialize(d.get("clock", {}))
	in_session = true
	EventBus.game_loaded.emit()
