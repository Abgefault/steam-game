class_name StaffSim
## Employee generation, hiring, hourly work simulation, morale, leveling.
## Employees perform machine loading/unloading and store restocking as
## automated actions, which is the main early automation lever.

const ROLES: PackedStringArray = ["sales", "store_manager", "production", "logistics",
	"maintenance", "quality", "marketing", "compliance"]
const ROLE_NAMES := {
	"sales": "Sales Associate", "store_manager": "Store Manager",
	"production": "Production Technician", "logistics": "Logistics Worker",
	"maintenance": "Maintenance Technician", "quality": "Quality Specialist",
	"marketing": "Marketer", "compliance": "Compliance Officer"}
const TRAITS: PackedStringArray = ["Charismatic", "Meticulous", "Fast Learner", "Wasteful",
	"Reliable", "Trend Savvy", "Easily Stressed", "Night Owl", "Perfectionist",
	"Calm Under Pressure", "Team Player"]


static func generate_candidate(s: Dictionary, role: String) -> Dictionary:
	var names: Dictionary = DataRegistry.names_data
	var first: Array = names.get("first", ["Alex"])
	var last: Array = names.get("last", ["Miller"])
	var skill := 2 + randi() % 5
	var wage := DataRegistry.bal("base_wage", 45.0) + skill * 13.0 + randf_range(-6.0, 8.0)
	var emp := {
		"id": int(s.staff_seq),
		"name": "%s %s" % [first.pick_random(), last.pick_random()],
		"role": role, "skill": skill, "xp": 0, "level": 1,
		"wage": snappedf(wage, 1.0),
		"morale": 70.0, "energy": 100.0,
		"traits": [TRAITS[randi() % TRAITS.size()]],
		"location": "facility", "perk": "",
	}
	s.staff_seq = int(s.staff_seq) + 1
	return emp


static func hire(s: Dictionary, candidate: Dictionary) -> bool:
	if not EconomySim.spend(s, DataRegistry.bal("hiring_fee", 150.0),
			"Hiring %s" % str(candidate.name), "scheduling"):
		return false
	s.staff.append(candidate)
	EventBus.employee_hired.emit(candidate)
	EventBus.notify("%s joined as %s." % [candidate.name, ROLE_NAMES.get(str(candidate.role), "?")], "success")
	return true


static func fire(s: Dictionary, emp_id: int) -> void:
	for e: Dictionary in s.staff:
		if int(e.id) == emp_id:
			s.staff.erase(e)
			EventBus.employee_quit.emit(e)
			return


static func by_role(s: Dictionary, role: String) -> Array:
	return s.staff.filter(func(e): return str(e.role) == role)


static func best_skill_at(s: Dictionary, role: String) -> float:
	var best := 0.0
	for e: Dictionary in by_role(s, role):
		best = maxf(best, float(e.skill) * (0.5 + float(e.morale) / 200.0))
	return best


static func best_skill_at_store(s: Dictionary, store_id: String, role: String) -> float:
	var best := 0.0
	for e: Dictionary in by_role(s, role):
		if str(e.location) == store_id or str(e.location) == "facility":
			best = maxf(best, float(e.skill) * (0.5 + float(e.morale) / 200.0))
	return best


## Hourly work pass: technicians run machines, logistics restocks,
## maintenance repairs — all logged as automated actions.
static func tick_hour(s: Dictionary, hour: int) -> void:
	if hour < 8 or hour > 20:
		return
	for e: Dictionary in s.staff:
		e.energy = maxf(20.0, float(e.energy) - 4.0)
		if randf() < 0.3:
			_gain_xp(s, e, 1)
		match str(e.role):
			"production":
				_work_machines(s, e)
			"logistics":
				_work_restock(s, e)
			"maintenance":
				_work_maintenance(s, e)
			"quality":
				_work_lab(s, e)
			"compliance":
				s.compliance = minf(100.0, float(s.compliance) + 0.08 * float(e.skill))
			"marketing":
				s.reputation = minf(100.0, float(s.reputation) + 0.04 * float(e.skill))


static func _work_machines(s: Dictionary, e: Dictionary) -> void:
	var ops := 1 + int(float(e.skill) / 3.0)
	for m: Dictionary in s.machines.values():
		if ops <= 0:
			break
		if str(m.state) == "done":
			MachineSim.unload(s, str(m.id), true)
			ops -= 1
		elif str(m.state) == "idle" and str(m.def_id) in ["conditioning", "processing", "packaging", "cultivation"]:
			var payload := {}
			if str(m.def_id) == "cultivation":
				payload = {"strain_id": _preferred_strain(s)}
			if MachineSim.load_and_start(s, str(m.id), payload, true):
				ops -= 1


static func _work_lab(s: Dictionary, e: Dictionary) -> void:
	for m: Dictionary in s.machines.values():
		if str(m.def_id) != "lab":
			continue
		if str(m.state) == "done":
			MachineSim.unload(s, str(m.id), true)
		elif str(m.state) == "idle":
			MachineSim.load_and_start(s, str(m.id), {}, true)
		if float(e.skill) >= 5.0 and str(m.state) == "done":
			MachineSim.unload(s, str(m.id), true)


static func _work_restock(s: Dictionary, _e: Dictionary) -> void:
	for st: Dictionary in s.stores.values():
		if not bool(st.owned):
			continue
		for pid: String in DataRegistry.products.keys():
			var on_display := InventorySim.sellable_qty(s, str(st.id), pid)
			if on_display < 4:
				RetailSim.restock(s, str(st.id), pid, 8 - on_display, true)


static func _work_maintenance(s: Dictionary, _e: Dictionary) -> void:
	for m: Dictionary in s.machines.values():
		if str(m.state) == "broken" or float(m.condition) < 45.0:
			if MachineSim.repair(s, str(m.id), true):
				return


static func _preferred_strain(s: Dictionary) -> String:
	# Pick the strain most demanded by planned products; fallback: first strain.
	var counts: Dictionary = {}
	for pid: String in DataRegistry.products.keys():
		var p: Dictionary = DataRegistry.products[pid]
		if int(p.stage_required) <= int(s.stage):
			counts[str(p.strain)] = int(counts.get(str(p.strain), 0)) + 1
	var best := ""
	var best_n := -1
	for k in counts.keys():
		if int(counts[k]) > best_n:
			best_n = int(counts[k])
			best = str(k)
	return best if best != "" else str(DataRegistry.strains.keys()[0])


static func _gain_xp(s: Dictionary, e: Dictionary, amount: int) -> void:
	e.xp = int(e.xp) + amount
	var needed := int(e.level) * 25
	if int(e.xp) >= needed:
		e.xp = 0
		e.level = int(e.level) + 1
		e.skill = mini(10, int(e.skill) + 1)
		e.wage = snappedf(float(e.wage) * 1.04, 1.0)
		EventBus.employee_leveled.emit(e)
		EventBus.notify("%s reached level %d!" % [e.name, int(e.level)], "success")


## Daily morale drift; staff welfare feeds the final score.
static func daily_update(s: Dictionary) -> void:
	for e: Dictionary in s.staff:
		e.energy = 100.0
		var drift := 0.0
		drift += 0.5 if float(s.cash) > 0.0 else -1.5
		if "Reliable" in (e.traits as Array):
			drift += 0.2
		if "Easily Stressed" in (e.traits as Array) and s.staff.size() < 3:
			drift -= 0.5
		e.morale = clampf(float(e.morale) + drift, 5.0, 100.0)
		if float(e.morale) < 20.0 and randf() < 0.15:
			EventBus.notify("%s quit due to low morale!" % e.name, "error")
			s.staff.erase(e)
			EventBus.employee_quit.emit(e)


static func payroll_missed(s: Dictionary) -> void:
	for e: Dictionary in s.staff:
		e.morale = maxf(5.0, float(e.morale) - 25.0)
	EventBus.notify("Payroll missed! Staff morale plummets.", "error")


static func give_bonus(s: Dictionary, emp_id: int, amount: float) -> bool:
	for e: Dictionary in s.staff:
		if int(e.id) == emp_id:
			if not EconomySim.spend(s, amount, "Bonus for %s" % e.name, "scheduling"):
				return false
			e.morale = minf(100.0, float(e.morale) + 15.0)
			return true
	return false


static func average_morale(s: Dictionary) -> float:
	if s.staff.is_empty():
		return 70.0
	var t := 0.0
	for e: Dictionary in s.staff:
		t += float(e.morale)
	return t / s.staff.size()
