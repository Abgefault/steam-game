class_name ResearchSim
## Research tree: prerequisites, RP costs, unlock effects.
## Node definitions live in data/research.json.


static func can_start(s: Dictionary, node_id: String) -> String:
	var def: Dictionary = DataRegistry.research.get(node_id, {})
	if def.is_empty():
		return "Unknown research."
	if node_id in (s.research_done as Array):
		return "Already researched."
	for pre: Variant in def.get("requires", []):
		if not str(pre) in (s.research_done as Array):
			var pre_def: Dictionary = DataRegistry.research.get(str(pre), {})
			return "Requires: %s" % str(pre_def.get("name", pre))
	if int(def.get("stage", 1)) > int(s.stage):
		return "Requires company stage %d." % int(def.get("stage", 1))
	if int(s.research_points) < int(def.get("cost_rp", 1)):
		return "Needs %d Research Points (have %d)." % [int(def.get("cost_rp", 1)), int(s.research_points)]
	if float(def.get("cost_cash", 0.0)) > float(s.cash):
		return "Needs $%d cash." % int(def.get("cost_cash", 0.0))
	return ""


static func unlock(s: Dictionary, node_id: String) -> bool:
	var why := can_start(s, node_id)
	if why != "":
		EventBus.notify(why, "warning")
		return false
	var def: Dictionary = DataRegistry.research[node_id]
	s.research_points = int(s.research_points) - int(def.get("cost_rp", 1))
	var cash_cost := float(def.get("cost_cash", 0.0))
	if cash_cost > 0.0 and not EconomySim.spend(s, cash_cost, "Research: %s" % str(def.name), "planning"):
		s.research_points = int(s.research_points) + int(def.get("cost_rp", 1))
		return false
	s.research_done.append(node_id)
	# Some research grants licenses or enables policy toggles.
	match node_id:
		"auto_purchasing": s.auto.purchasing = true
		"auto_replenishment": s.auto.restock = true
		"maintenance_scheduling": s.auto.maintenance = true
		"central_scheduling": s.auto.scheduling = true
		"advanced_analytics": s.auto.reporting = true
		"wholesale_license":
			if not "logistics_license" in (s.licenses as Array):
				s.licenses.append("logistics_license")
		"lab_protocols":
			if not "testing_license" in (s.licenses as Array):
				s.licenses.append("testing_license")
	Game.milestone("Researched %s" % str(def.name))
	EventBus.research_completed.emit(def)
	EventBus.notify("Research complete: %s!" % str(def.name), "success")
	return true


static func by_branch(branch: String) -> Array:
	var out: Array = []
	for def: Dictionary in DataRegistry.research.values():
		if str(def.get("branch", "")) == branch:
			out.append(def)
	out.sort_custom(func(a, b): return int(a.get("cost_rp", 0)) < int(b.get("cost_rp", 0)))
	return out
