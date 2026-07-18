class_name EventsSim
## Authored city/business events with prerequisites, cooldowns, choices
## and mechanical consequences. Definitions live in data/events.json.


static func roll_daily(s: Dictionary) -> void:
	# Expire active events.
	for ev: Dictionary in (s.events_active as Array).duplicate():
		ev.days_left = int(ev.days_left) - 1
		if int(ev.days_left) <= 0:
			s.events_active.erase(ev)
	# Tick cooldowns.
	for k in (s.event_cooldowns as Dictionary).keys():
		s.event_cooldowns[k] = int(s.event_cooldowns[k]) - 1
		if int(s.event_cooldowns[k]) <= 0:
			s.event_cooldowns.erase(k)
	# At most one new event per day; ~40% of days have one.
	if randf() > DataRegistry.bal("event_daily_chance", 0.4):
		return
	var candidates: Array = []
	for def: Dictionary in DataRegistry.events.values():
		if _eligible(s, def):
			candidates.append(def)
	if candidates.is_empty():
		return
	fire_event(s, candidates.pick_random())


static func _eligible(s: Dictionary, def: Dictionary) -> bool:
	var id := str(def.id)
	if s.event_cooldowns.has(id):
		return false
	for ev: Dictionary in s.events_active:
		if str(ev.id) == id:
			return false
	var req: Dictionary = def.get("requires", {})
	if int(req.get("min_stage", 1)) > int(s.stage):
		return false
	if int(req.get("min_day", 0)) > int(s.day):
		return false
	if int(req.get("min_stores", 0)) > RetailSim.count_profitable_stores(s):
		return false
	if int(req.get("min_staff", 0)) > (s.staff as Array).size():
		return false
	return true


static func fire_event(s: Dictionary, def: Dictionary) -> void:
	var ev := {
		"id": str(def.id), "title": str(def.title), "text": str(def.text),
		"days_left": int(def.get("duration", 1)),
		"effects": def.get("effects", {}),
		"choices": def.get("choices", []),
		"resolved": (def.get("choices", []) as Array).is_empty(),
		"day": int(s.day),
	}
	s.events_active.append(ev)
	s.events_history.append({"id": ev.id, "day": s.day})
	if (s.events_history as Array).size() > 100:
		s.events_history.pop_front()
	s.event_cooldowns[str(def.id)] = int(def.get("cooldown", 20))
	if ev.resolved:
		_apply_effects(s, ev.effects)
	EventBus.game_event_fired.emit(ev)
	EventBus.notify("Event: %s" % ev.title, "info")


## Player picked a choice on an event card.
static func choose(s: Dictionary, event_id: String, choice_idx: int) -> void:
	for ev: Dictionary in s.events_active:
		if str(ev.id) != event_id or bool(ev.resolved):
			continue
		var choices: Array = ev.choices
		if choice_idx < 0 or choice_idx >= choices.size():
			return
		var choice: Dictionary = choices[choice_idx]
		var cost := float(choice.get("cost", 0.0))
		if cost > 0.0 and not EconomySim.spend(s, cost, "Event: %s" % str(ev.title), "planning"):
			return
		_apply_effects(s, choice.get("effects", {}))
		ev.resolved = true
		EventBus.notify("Decision made: %s" % str(choice.get("label", "")), "info")
		return


static func _apply_effects(s: Dictionary, fx: Dictionary) -> void:
	if fx.has("cash"):
		var v := float(fx.cash)
		if v >= 0.0:
			EconomySim.earn(s, v, "Event effect")
		else:
			EconomySim.spend(s, -v, "Event effect", "planning")
	if fx.has("reputation"):
		s.reputation = clampf(float(s.reputation) + float(fx.reputation), 0.0, 100.0)
		EventBus.reputation_changed.emit(float(s.reputation))
	if fx.has("compliance"):
		s.compliance = clampf(float(s.compliance) + float(fx.compliance), 0.0, 100.0)
		EventBus.compliance_changed.emit(float(s.compliance))
	if fx.has("research_points"):
		s.research_points = int(s.research_points) + int(fx.research_points)
	if fx.has("supplier_price_mult"):
		s.market.supplier_price_mult = float(fx.supplier_price_mult)
	if fx.has("utility_mult"):
		s.market.utility_mult = float(fx.utility_mult)
	if fx.has("category_demand"):
		for c in (fx.category_demand as Dictionary).keys():
			s.market.category_demand[c] = clampf(
				float(s.market.category_demand.get(c, 1.0)) * float(fx.category_demand[c]), 0.4, 2.2)
	if fx.has("damage_machine") and not (s.machines as Dictionary).is_empty():
		var m: Dictionary = s.machines.values().pick_random()
		m.condition = maxf(5.0, float(m.condition) - float(fx.damage_machine))
	if fx.has("staff_morale"):
		for e: Dictionary in s.staff:
			e.morale = clampf(float(e.morale) + float(fx.staff_morale), 5.0, 100.0)
	if fx.has("audit") and bool(fx.audit):
		ComplianceSim.run_audit(s)
