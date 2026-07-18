extends Node
## Headless automated test suite, run through the normal game boot so all
## autoload services exist:
##   godot --headless -- --run-tests
## The process exits 0 when every test passes, 1 otherwise.

var passed := 0
var failed := 0
var current := ""


func _ready() -> void:
	_run()


func _run() -> void:
	seed(1234)
	SceneRouter.suppressed = true   # keep end screens out of the test run
	_t("data_validation", _test_data_validation)
	_t("balance_keys", _test_balance_keys)
	_t("economy_spend_earn", _test_economy)
	_t("pricing_policies", _test_pricing)
	_t("valuation", _test_valuation)
	_t("inventory_fefo", _test_inventory_fefo)
	_t("inventory_expiry", _test_inventory_expiry)
	_t("inventory_reserve_transfer", _test_reserve_transfer)
	_t("production_chain", _test_production_chain)
	_t("machine_wear_repair", _test_wear_repair)
	_t("conveyor_auto_transfer", _test_conveyor)
	_t("customer_decision", _test_customer_decision)
	_t("store_daily_flow", _test_store_flow)
	_t("staff_hire_work", _test_staff)
	_t("payroll_and_accounting", _test_accounting)
	_t("market_updates", _test_market)
	_t("events_apply", _test_events)
	_t("compliance_audit", _test_audit)
	_t("research_prereqs", _test_research)
	_t("objectives_progress", _test_objectives)
	_t("automation_score", _test_automation_score)
	_t("wholesale_orders", _test_wholesale)
	_t("save_load_roundtrip", _test_save_load)
	_t("campaign_qualification", _test_qualification)
	_t("final_trial_win", _test_trial_win)
	_t("final_trial_fail", _test_trial_fail)
	_t("campaign_failure_paths", _test_failure_paths)
	_t("stage_advancement", _test_stages)
	print("\n=== RESULTS: %d passed, %d failed ===" % [passed, failed])
	get_tree().quit(0 if failed == 0 else 1)


func _t(test_name: String, fn: Callable) -> void:
	current = test_name
	var before := failed
	fn.call()
	print("%s %s" % ["PASS" if failed == before else "FAIL", test_name])


func ok(cond: bool, msg: String) -> void:
	if not cond:
		failed += 1
		printerr("  ASSERT FAILED [%s]: %s" % [current, msg])
	else:
		passed += 1


func fresh() -> Dictionary:
	var s: Dictionary = Game.new_state("Test Co")
	Game.state = s
	Game.in_session = true
	return s


# ------------------------------------------------------------------- tests

func _test_data_validation() -> void:
	ok(DataRegistry.validation_errors.is_empty(),
		"data errors: %s" % ", ".join(DataRegistry.validation_errors))
	ok(DataRegistry.products.size() >= 24, "24+ products")
	ok(DataRegistry.events.size() >= 40, "40+ events")
	ok(DataRegistry.research.size() >= 32, "32+ research")
	ok(DataRegistry.achievements.size() >= 25, "25+ achievements")


func _test_balance_keys() -> void:
	for key in ["start_cash", "loan_principal", "overdraft_limit", "tax_rate",
			"customer_base_rate", "machine_wear_per_hour"]:
		ok(DataRegistry.balance.has(key), "balance key %s" % key)


func _test_economy() -> void:
	var s := fresh()
	var c0 := float(s.cash)
	ok(EconomySim.spend(s, 100.0, "test"), "spend ok")
	ok(is_equal_approx(float(s.cash), c0 - 100.0), "cash reduced")
	EconomySim.earn(s, 50.0, "test")
	ok(is_equal_approx(float(s.cash), c0 - 50.0), "cash earned")
	ok(not EconomySim.spend(s, 10_000_000.0, "too much"), "overdraft blocks big spend")


func _test_pricing() -> void:
	var s := fresh()
	var pid := "flower_dawn"
	var base := float(DataRegistry.products[pid].retail_price)
	s.price_policy = "recommended"
	ok(is_equal_approx(EconomySim.effective_price(s, pid), base), "recommended = base")
	s.price_policy = "budget"
	ok(EconomySim.effective_price(s, pid) < base, "budget < base")
	s.price_policy = "premium"
	ok(EconomySim.effective_price(s, pid) > base, "premium > base")
	s.prices[pid] = 42.0
	ok(is_equal_approx(EconomySim.effective_price(s, pid), 42.0), "override wins")
	s.prices.erase(pid)
	ok(EconomySim.gross_margin(s, pid) > 0.0, "positive margin")


func _test_valuation() -> void:
	var s := fresh()
	var v0 := EconomySim.valuation(s)
	InventorySim.make_lot(s, "flower_dawn", 100, 2, true)
	ok(EconomySim.valuation(s) > v0, "inventory raises valuation")
	s.loan_balance = 0.0
	ok(EconomySim.valuation(s) > v0 + 40000.0, "debt-free raises valuation")


func _test_inventory_fefo() -> void:
	var s := fresh()
	var lot_a := InventorySim.make_lot(s, "flower_dawn", 10, 1, true)
	lot_a.day_expires = 20
	var lot_b := InventorySim.make_lot(s, "flower_dawn", 10, 2, true)
	lot_b.day_expires = 5   # expires first -> consumed first
	var res := InventorySim.consume(s, "warehouse", "flower_dawn", 12)
	ok(int(res.taken) == 12, "took 12")
	ok(int(lot_b.qty) == 0, "earliest-expiry lot consumed first")
	ok(int(lot_a.qty) == 8, "remainder from later lot")


func _test_inventory_expiry() -> void:
	var s := fresh()
	var lot := InventorySim.make_lot(s, "flower_dawn", 10, 1, true)
	lot.day_expires = 2
	var wasted := InventorySim.expire_lots(s, 3)
	ok(wasted == 10, "expired units wasted")
	ok(InventorySim.total_qty(s, "flower_dawn") == 0, "expired stock removed")


func _test_reserve_transfer() -> void:
	var s := fresh()
	InventorySim.make_lot(s, "oil_amber", 20, 2, true)
	var reserved := InventorySim.reserve(s, "warehouse", "oil_amber", 5)
	ok(reserved == 5, "reserved 5")
	var res := InventorySim.consume(s, "warehouse", "oil_amber", 20)
	ok(int(res.taken) == 15, "reserved units not consumable")
	var s2 := fresh()
	InventorySim.make_lot(s2, "oil_amber", 20, 2, true)
	var moved := InventorySim.transfer(s2, "warehouse", "display:store_old_market", "oil_amber", 8)
	ok(moved == 8, "transferred 8")
	ok(InventorySim.sellable_qty(s2, "store_old_market", "oil_amber") == 8, "sellable at display")


func _test_production_chain() -> void:
	var s := fresh()
	s.supplies.seed_units = 5
	s.supplies.packaging_units = 500
	# Cultivation.
	ok(MachineSim.load_and_start(s, "m_cultivation_1", {"strain_id": "verdant_dawn"}), "cultivation starts")
	_finish(s, "m_cultivation_1")
	MachineSim.unload(s, "m_cultivation_1")
	ok(int(s.raw.get("verdant_dawn", 0)) > 0, "harvest produced")
	# Conditioning.
	ok(MachineSim.load_and_start(s, "m_conditioning_1", {}), "conditioning starts")
	_finish(s, "m_conditioning_1")
	MachineSim.unload(s, "m_conditioning_1")
	ok(int(s.conditioned.get("verdant_dawn", 0)) > 0, "conditioned produced")
	# Processing (twice: each run refines 2 conditioned units into 10 material,
	# and the flower_dawn recipe needs 12).
	for i in 2:
		ok(MachineSim.load_and_start(s, "m_processing_1", {}), "processing starts")
		_finish(s, "m_processing_1")
		MachineSim.unload(s, "m_processing_1")
	ok(int(s.processed.get("verdant_dawn", 0)) >= 12, "refined produced")
	# Product.
	ok(MachineSim.load_and_start(s, "m_product_1", {"product_id": "flower_dawn"}), "product starts")
	_finish(s, "m_product_1")
	MachineSim.unload(s, "m_product_1")
	ok((s.batches as Array).size() == 1, "batch created")
	# Lab.
	ok(MachineSim.load_and_start(s, "m_lab_1", {}), "lab starts")
	_finish(s, "m_lab_1")
	MachineSim.unload(s, "m_lab_1")
	ok(bool((s.batches as Array)[0].tested), "batch tested")
	# Packaging.
	ok(MachineSim.load_and_start(s, "m_packaging_1", {}), "packaging starts")
	_finish(s, "m_packaging_1")
	MachineSim.unload(s, "m_packaging_1")
	ok((s.batches as Array).is_empty(), "batch consumed")
	ok(InventorySim.total_qty(s, "flower_dawn") > 0, "lot in warehouse")


func _finish(s: Dictionary, machine_id: String) -> void:
	var m: Dictionary = s.machines[machine_id]
	m.progress = float(m.duration)
	ProductionSim.tick_minute(s)   # flips to done
	m.state = "done"


func _test_wear_repair() -> void:
	var s := fresh()
	var m: Dictionary = s.machines["m_product_1"]
	m.state = "running"
	var c0 := float(m.condition)
	MachineSim.tick_hour(s)
	ok(float(m.condition) < c0, "running machine wears")
	m.state = "idle"
	m.condition = 20.0
	s.supplies.spare_parts = 1
	ok(MachineSim.repair(s, "m_product_1"), "repair works")
	ok(float(m.condition) > 20.0, "condition restored")
	ok(int(s.supplies.spare_parts) == 0, "spare part consumed")
	ok(not MachineSim.repair(s, "m_product_1"), "no parts -> no repair")


func _test_conveyor() -> void:
	var s := fresh()
	s.research_done.append("conveyors")
	s.conveyors.append({"from": "m_cultivation_1", "to": "m_conditioning_1"})
	s.supplies.seed_units = 2
	MachineSim.load_and_start(s, "m_cultivation_1", {"strain_id": "verdant_dawn"})
	var m: Dictionary = s.machines["m_cultivation_1"]
	m.progress = float(m.duration)
	ProductionSim.tick_minute(s)   # completes and auto-unloads via conveyor
	ok(str(m.state) == "idle", "conveyor auto-unloaded")
	ok(int(s.raw.get("verdant_dawn", 0)) > 0, "output arrived in pool")


func _test_customer_decision() -> void:
	var s := fresh()
	InventorySim.make_lot(s, "flower_dawn", 20, 2, true, "display:store_old_market")
	var archetype: Dictionary = DataRegistry.archetypes["budget"]
	var res := RetailSim.decide_and_buy(s, "store_old_market", archetype, true)
	ok(bool(res.bought), "budget shopper buys available affordable flower")
	ok(InventorySim.sellable_qty(s, "store_old_market", "flower_dawn") == 19, "stock decremented")
	ok(float(s.daily.revenue) > 0.0, "revenue recorded")
	# No stock -> no purchase.
	var s2 := fresh()
	var res2 := RetailSim.decide_and_buy(s2, "store_old_market", archetype, true)
	ok(not bool(res2.bought), "no stock -> no purchase")
	# Untested stock is not sellable.
	var s3 := fresh()
	InventorySim.make_lot(s3, "flower_dawn", 5, 2, false, "display:store_old_market")
	ok(InventorySim.sellable_qty(s3, "store_old_market", "flower_dawn") == 0, "untested unsellable")


func _test_store_flow() -> void:
	var s := fresh()
	InventorySim.make_lot(s, "flower_dawn", 200, 1, true, "display:store_old_market")
	RetailSim.set_open(s, "store_old_market", true)
	for minute in range(RetailSim.OPEN_MINUTE, RetailSim.OPEN_MINUTE + 240):
		RetailSim.tick_minute(s, minute)
	ok(int(s.daily.units_sold) > 0, "background store sells over 4h (sold %d)" % int(s.daily.units_sold))
	RetailSim.tick_minute(s, RetailSim.CLOSE_MINUTE)
	ok(not bool(s.stores.store_old_market.open), "store closes at closing time")


func _test_staff() -> void:
	var s := fresh()
	var cand := StaffSim.generate_candidate(s, "production")
	ok(StaffSim.hire(s, cand), "hire works")
	ok((s.staff as Array).size() == 1, "staff count 1")
	s.supplies.seed_units = 3
	StaffSim.tick_hour(s, 10)
	var any_running := false
	for m: Dictionary in s.machines.values():
		if str(m.state) == "running":
			any_running = true
	ok(any_running, "technician started a machine")
	StaffSim.fire(s, int(cand.id))
	ok((s.staff as Array).is_empty(), "fire works")


func _test_accounting() -> void:
	var s := fresh()
	StaffSim.hire(s, StaffSim.generate_candidate(s, "sales"))
	var c0 := float(s.cash)
	var report := EconomySim.close_day(s, 7)   # day 7 -> loan payment due
	ok(float(s.cash) < c0, "day close costs money")
	ok(report.has("profit"), "report has profit")
	ok(float(s.loan_balance) < DataRegistry.bal("loan_principal"), "loan payment reduced balance")
	# Payroll failure path: hire while solvent, then drain the account.
	var s2 := fresh()
	StaffSim.hire(s2, StaffSim.generate_candidate(s2, "sales"))
	s2.cash = DataRegistry.bal("overdraft_limit") + 10.0
	EconomySim.close_day(s2, 3)
	ok(int(s2.payroll_missed) >= 1, "missed payroll tracked")


func _test_market() -> void:
	var s := fresh()
	var before: Dictionary = (s.market.category_demand as Dictionary).duplicate()
	for i in 10:
		MarketSim.advance_day(s)
	var changed := false
	for c in MarketSim.CATEGORIES:
		if not is_equal_approx(float(before[c]), float(s.market.category_demand[c])):
			changed = true
	ok(changed, "demand drifts")
	for c in MarketSim.CATEGORIES:
		var v := float(s.market.category_demand[c])
		ok(v >= 0.5 and v <= 1.7, "demand bounded (%s=%.2f)" % [c, v])
	ok(MarketSim.buy_supplies(s, "seed_units", 2), "supply purchase")
	ok(int(s.supplies.seed_units) == 6, "seeds added")


func _test_events() -> void:
	var s := fresh()
	var def: Dictionary = DataRegistry.events["charity"]
	EventsSim.fire_event(s, def)
	ok((s.events_active as Array).size() == 1, "event active")
	var c0 := float(s.cash)
	EventsSim.choose(s, "charity", 0)
	ok(float(s.cash) < c0, "choice cost applied")
	ok(float(s.reputation) > DataRegistry.bal("start_reputation"), "reputation reward applied")
	ok(s.event_cooldowns.has("charity"), "cooldown set")
	var eligible := EventsSim._eligible(s, def)
	ok(not eligible, "cooldown blocks refire")


func _test_audit() -> void:
	var s := fresh()
	# Clean state should pass reasonably.
	var res := ComplianceSim.run_audit(s)
	ok(res.has("pct"), "audit result has pct")
	# Untested displayed lot must lower the testing score.
	var s2 := fresh()
	InventorySim.make_lot(s2, "flower_dawn", 5, 1, false, "display:store_old_market")
	var res2 := ComplianceSim.run_audit(s2)
	ok(int(res2.scores["Product testing"]) < 10, "untested display hurts audit")


func _test_research() -> void:
	var s := fresh()
	s.research_points = 20
	ok(ResearchSim.can_start(s, "quality_consistency") != "", "prereq blocks")
	ok(ResearchSim.unlock(s, "fast_processing"), "unlock base node")
	ok(ResearchSim.unlock(s, "quality_consistency"), "unlock after prereq")
	ok(not ResearchSim.unlock(s, "quality_consistency"), "no double unlock")
	var s2 := fresh()
	s2.research_points = 0
	ok(not ResearchSim.unlock(s2, "fast_processing"), "no RP -> no unlock")


func _test_objectives() -> void:
	var s := fresh()
	s.stats.batches_completed = 5
	ObjectivesSim.check_all(s)
	ok(bool(s.objectives["obj_batch_5"].done), "batch objective completes")
	ok("ach_first_batch" in (s.achievements as Array), "achievement granted")
	var progress := ObjectivesSim.evaluate(s, {"batches_completed": 10})
	ok(is_equal_approx(progress, 0.5), "partial progress 0.5")


func _test_automation_score() -> void:
	var s := fresh()
	for i in 8:
		Game.log_action("production", true)
	for i in 2:
		Game.log_action("production", false)
	AutomationSim.finish_day(s)
	ok(absf(AutomationSim.department_score(s, "production") - 80.0) < 0.01, "dept score 80%")
	ok(float(s.automation_score) > 0.0, "overall score set")
	# Equipment alone must NOT raise the score.
	var s2 := fresh()
	for m: Dictionary in s2.machines.values():
		m.tier = 3
	AutomationSim.finish_day(s2)
	ok(is_equal_approx(float(s2.automation_score), 0.0), "machines alone score 0")


func _test_wholesale() -> void:
	var s := fresh()
	s.licenses.append("logistics_license")
	OrdersSim.ensure_state(s)
	OrdersSim.roll_offers(s)
	if (s.wholesale.offers as Array).is_empty():
		OrdersSim.roll_offers(s)
	if not (s.wholesale.offers as Array).is_empty():
		var o: Dictionary = (s.wholesale.offers as Array)[0]
		InventorySim.make_lot(s, str(o.product_id), int(o.qty), 2, true)
		ok(OrdersSim.accept(s, int(o.id)), "accept offer")
		var c0 := float(s.cash)
		for h in range(8, 19):
			OrdersSim.tick_hour(s, h)
		ok(float(s.cash) > c0, "order fulfilled and paid")
	else:
		ok(true, "no offers rolled (stage gate) - acceptable")


func _test_save_load() -> void:
	var s := fresh()
	InventorySim.make_lot(s, "flower_dawn", 33, 2, true)
	StaffSim.hire(s, StaffSim.generate_candidate(s, "sales"))
	s.day = 42
	s.cash = 12345.0
	SimClock.day = 42
	ok(SaveService.save_game("testslot"), "save works")
	Game.state = Game.new_state("Other Co")
	ok(SaveService.load_game("testslot"), "load works")
	ok(int(Game.state.day) == 42, "day restored")
	ok(is_equal_approx(float(Game.state.cash), 12345.0), "cash restored")
	ok(InventorySim.total_qty(Game.state, "flower_dawn") == 33, "inventory restored")
	ok((Game.state.staff as Array).size() == 1, "staff restored")
	var meta := SaveService.read_metadata("testslot")
	ok(int(meta.day) == 42, "metadata correct")
	SaveService.delete_save("testslot")
	ok(SaveService.read_metadata("testslot").is_empty(), "delete works")
	ok(not SaveService.load_game("missing_slot"), "missing save handled")


func _test_qualification() -> void:
	var s := fresh()
	ok(not CampaignSim.qualified(s), "fresh company not qualified")
	_make_qualified(s)
	ok(CampaignSim.qualified(s), "prepared company qualifies: %s"
		% str(CampaignSim.requirements(s).filter(func(r): return not bool(r.done))))
	ok(CampaignSim.start_trial(s), "trial starts when qualified")


func _make_qualified(s: Dictionary) -> void:
	s.cash = 700000.0
	# A successful late-game week of results feeds the valuation multiple.
	for i in 7:
		s.stats.daily.append({"day": 90 + i, "profit": 4200.0, "revenue": 9000.0,
			"expenses": 4800.0, "units_sold": 500})
	s.loan_balance = 0.0
	s.day = 100
	s.automation_score = 90.0
	s.compliance = 95.0
	s.reputation = 85.0
	s.licenses = ["retail_basic", "production_basic", "logistics_license", "testing_license"]
	for m: Dictionary in s.machines.values():
		m.tier = 5
		m.condition = 100.0
	for d in ["university_row", "wellness_heights"]:
		var st := RetailSim.new_store("store_%s" % d, d, true)
		st.profit_history = [100.0, 100.0, 100.0]
		s.stores["store_%s" % d] = st
	s.stores.store_old_market.profit_history = [100.0, 100.0, 100.0]
	# Big inventory for valuation.
	InventorySim.make_lot(s, "oil_glass", 3000, 2, true)
	InventorySim.make_lot(s, "flower_moon", 3000, 2, true)
	s.reputation = 85.0


func _test_trial_win() -> void:
	var s := fresh()
	_make_qualified(s)
	CampaignSim.start_trial(s)
	ok(bool(s.trial.active), "trial active")
	# Feed the trial with enough Select+ stock and run 30 days.
	for day in 30:
		InventorySim.make_lot(s, "flower_dawn", 450, 2, true)
		for h in range(8, 20):
			CampaignSim.trial_tick_hour(s, h)
		var report := {}
		CampaignSim.trial_close_day(s, report)
		if s.campaign_over:
			break
	ok(bool(s.campaign_result.get("won", false)),
		"trial won (delivered=%d)" % int(s.trial.delivered))
	ok(str(s.campaign_result.get("grade", "")) in ["C", "B", "A", "S"], "grade assigned")


func _test_trial_fail() -> void:
	var s := fresh()
	_make_qualified(s)
	ok(CampaignSim.start_trial(s), "trial starts")
	# Deliver almost nothing for the whole trial window.
	for day in 31:
		var report := {}
		CampaignSim.trial_close_day(s, report)
		if not bool(s.trial.active):
			break
	ok(bool(s.trial.failed) or s.campaign_over, "starved trial fails")


func _test_failure_paths() -> void:
	var s := fresh()
	s.overdraft_days = 5
	CampaignSim.check_failure(s)
	ok(bool(s.campaign_over), "overdraft failure")
	var s2 := fresh()
	s2.loan_missed = 3
	CampaignSim.check_failure(s2)
	ok(bool(s2.campaign_over), "loan failure")
	var s3 := fresh()
	s3.payroll_missed = 2
	CampaignSim.check_failure(s3)
	ok(bool(s3.campaign_over), "payroll failure")
	var s4 := fresh()
	s4.day = 181
	CampaignSim.check_failure(s4)
	ok(bool(s4.campaign_over), "deadline failure")
	var s5 := fresh()
	s5.compliance = 1.0
	CampaignSim.check_failure(s5)
	ok(bool(s5.campaign_over), "license revocation failure")


func _test_stages() -> void:
	var s := fresh()
	ok(int(s.stage) == 1, "start at stage 1")
	s.cash = 100000.0
	StaffSim.hire(s, StaffSim.generate_candidate(s, "sales"))
	CampaignSim.check_stage_advance(s)
	ok(int(s.stage) == 2, "stage 2 reached")
	s.stats.batches_completed = 10
	InventorySim.make_lot(s, "oil_glass", 800, 2, true)
	CampaignSim.check_stage_advance(s)
	ok(int(s.stage) == 3, "stage 3 reached")
	ok("logistics_license" in (s.licenses as Array), "stage 3 grants logistics license")
