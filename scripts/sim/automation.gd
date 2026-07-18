class_name AutomationSim
## Formal automation score (0-100%): the share of daily work performed
## without direct player interaction, measured per department from real
## logged actions — never from equipment owned.

const DEPARTMENTS: PackedStringArray = ["production", "quality", "packaging",
	"warehouse", "planning", "restock", "purchasing", "maintenance",
	"scheduling", "fulfillment", "reporting"]


static func department_score(s: Dictionary, dept: String) -> float:
	var a: Dictionary = s.actions_prev.get(dept, s.actions.get(dept, {}))
	var manual := int(a.get("manual", 0))
	var auto := int(a.get("auto", 0))
	if manual + auto == 0:
		return 0.0
	return float(auto) / float(manual + auto) * 100.0


static func overall_score(s: Dictionary) -> float:
	var total_manual := 0
	var total_auto := 0
	var src: Dictionary = s.actions_prev if not (s.actions_prev as Dictionary).is_empty() else s.actions
	for dept in DEPARTMENTS:
		var a: Dictionary = src.get(dept, {})
		total_manual += int(a.get("manual", 0))
		total_auto += int(a.get("auto", 0))
	if total_manual + total_auto == 0:
		return 0.0
	return float(total_auto) / float(total_manual + total_auto) * 100.0


## Day rollover: freeze today's action log as the scoring basis.
static func finish_day(s: Dictionary) -> void:
	# Passive policies count as automated planning/reporting work.
	if bool(s.auto.reporting):
		Game.log_action("reporting", true)
	if bool(s.auto.scheduling):
		Game.log_action("scheduling", true)
	s.actions_prev = (s.actions as Dictionary).duplicate(true)
	s.actions = {}
	var score := overall_score(s)
	# Smooth over two days so one odd day doesn't spike the score.
	s.automation_score = snappedf(lerpf(float(s.automation_score), score, 0.5), 0.1)
	EventBus.automation_changed.emit(float(s.automation_score))


## Hourly automation policies unlocked through research.
static func run_policies(s: Dictionary) -> void:
	if bool(s.auto.purchasing) and Game.has_research("auto_purchasing"):
		if int(s.supplies.seed_units) < 2:
			MarketSim.buy_supplies(s, "seed_units", 4, true)
		if int(s.supplies.packaging_units) < 40:
			MarketSim.buy_supplies(s, "packaging_units", 120, true)
		if int(s.supplies.spare_parts) < 1:
			MarketSim.buy_supplies(s, "spare_parts", 2, true)
	if bool(s.auto.restock) and Game.has_research("auto_replenishment"):
		for st: Dictionary in s.stores.values():
			if not bool(st.owned):
				continue
			for pid: String in DataRegistry.products.keys():
				if InventorySim.sellable_qty(s, str(st.id), pid) < 3:
					RetailSim.restock(s, str(st.id), pid, 6, true)
	if bool(s.auto.maintenance) and Game.has_research("maintenance_scheduling"):
		for m: Dictionary in s.machines.values():
			if float(m.condition) < 50.0 or str(m.state) == "broken":
				MachineSim.repair(s, str(m.id), true)


## Analysis for the automation dashboard.
static func dashboard(s: Dictionary) -> Dictionary:
	var idle: Array[String] = []
	var blocked: Array[String] = []
	var starved: Array[String] = []
	for m: Dictionary in s.machines.values():
		match str(m.state):
			"idle":
				var why := MachineSim.load_blocker(s, str(m.id), {"product_id": str(m.get("recipe", ""))})
				if why.begins_with("No ") or why.begins_with("Needs") or why.begins_with("Not enough"):
					starved.append("%s: %s" % [MachineSim.display_name(m), why])
				else:
					idle.append(MachineSim.display_name(m))
			"done":
				blocked.append("%s: output waiting" % MachineSim.display_name(m))
			"broken":
				blocked.append("%s: broken" % MachineSim.display_name(m))
	var manual_today := int(s.daily.manual_actions)
	var auto_today := int(s.daily.auto_actions)
	var recommendation := _recommend(s, idle, blocked, starved)
	var dept_scores: Dictionary = {}
	for d in DEPARTMENTS:
		dept_scores[d] = department_score(s, d)
	return {
		"overall": float(s.automation_score),
		"departments": dept_scores,
		"manual_today": manual_today,
		"auto_today": auto_today,
		"labor_hours_saved": snappedf(auto_today * 0.05, 0.1),
		"idle_machines": idle,
		"blocked": blocked,
		"starved": starved,
		"recommendation": recommendation,
	}


static func _recommend(s: Dictionary, idle: Array[String], blocked: Array[String],
		starved: Array[String]) -> String:
	if not Game.has_research("conveyors"):
		return "Research Conveyor Systems to connect machines automatically."
	if s.conveyors.is_empty():
		return "Build conveyor connections between your machines (Automation tab)."
	if not blocked.is_empty():
		return "Clear blocked output: %s" % blocked[0]
	if not starved.is_empty():
		return "Feed starved machines: %s" % starved[0]
	if StaffSim.by_role(s, "production").is_empty():
		return "Hire a Production Technician to run machines without you."
	if not bool(s.auto.purchasing):
		return "Enable automatic supplier purchasing (needs research)."
	if not bool(s.auto.restock):
		return "Enable automatic store replenishment (needs research)."
	if not idle.is_empty():
		return "Increase input flow — %s is idle." % idle[0]
	return "Solid. Push remaining manual tasks toward staff and policies."
