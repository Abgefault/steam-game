class_name ObjectivesSim
## Objectives (tutorial chain, regular, challenge) and achievements.
## Conditions are declarative in data/objectives.json / achievements.json
## and evaluated against real state here.


static func check_all(s: Dictionary) -> void:
	for def: Dictionary in DataRegistry.objectives.values():
		var id := str(def.id)
		var st: Dictionary = s.objectives.get(id, {"done": false, "progress": 0.0})
		if bool(st.done):
			continue
		var progress := evaluate(s, def.get("condition", {}))
		st.progress = progress
		if progress >= 1.0:
			st.done = true
			_grant_rewards(s, def)
			EventBus.objective_completed.emit(def)
			EventBus.notify("Objective complete: %s" % str(def.name), "success")
		s.objectives[id] = st
	for def: Dictionary in DataRegistry.achievements.values():
		var id := str(def.id)
		if id in (s.achievements as Array):
			continue
		if evaluate(s, def.get("condition", {})) >= 1.0:
			grant_achievement(s, id)


static func grant_achievement(s: Dictionary, id: String) -> void:
	if id in (s.achievements as Array):
		return
	var def: Dictionary = DataRegistry.achievements.get(id, {})
	if def.is_empty():
		return
	s.achievements.append(id)
	EventBus.achievement_unlocked.emit(def)
	EventBus.notify("Achievement unlocked: %s!" % str(def.get("name", id)), "success")
	SteamFacade.unlock_achievement(id)


## Declarative condition -> progress 0..1. Supported keys mirror the stat
## they read; a condition passes when every key reaches its target.
static func evaluate(s: Dictionary, cond: Dictionary) -> float:
	if cond.is_empty():
		return 0.0
	var progress := 1.0
	for key: String in cond.keys():
		var target := float(cond[key])
		var current := _stat(s, key)
		if target <= 0.0:
			progress = minf(progress, 1.0 if current <= target else 0.0)
		else:
			progress = minf(progress, clampf(current / target, 0.0, 1.0))
	return progress


static func _stat(s: Dictionary, key: String) -> float:
	match key:
		"batches_completed": return float(s.stats.batches_completed)
		"units_sold": return float(s.stats.total_units_sold)
		"total_revenue": return float(s.stats.total_revenue)
		"cash": return float(s.cash)
		"day": return float(s.day)
		"stage": return float(s.stage)
		"reputation": return float(s.reputation)
		"compliance": return float(s.compliance)
		"automation": return float(s.automation_score)
		"valuation": return EconomySim.valuation(s)
		"staff_count": return float((s.staff as Array).size())
		"stores_profitable": return float(RetailSim.count_profitable_stores(s))
		"stores_owned": return float(_owned_stores(s))
		"research_count": return float((s.research_done as Array).size())
		"conveyor_count": return float((s.conveyors as Array).size())
		"lot_count": return float((s.lots as Array).size())
		"best_day_profit": return float(s.stats.best_day_profit)
		"customers_served": return float(s.stats.customers_served)
		"loan_repaid": return 1.0 if float(s.loan_balance) <= 0.0 else 0.0
		"trial_won": return 1.0 if bool(s.campaign_result.get("won", false)) else 0.0
		"exceptional_batch": return 1.0 if _has_quality_lot(s, 3) else 0.0
		"premium_batch": return 1.0 if _has_quality_lot(s, 2) else 0.0
		"machines_tier3": return float(_machines_at_tier(s, 3))
		"facility_tier": return float(MachineSim.facility_tier(s))
		"tutorial_done": return 1.0 if bool(s.tutorial_done) else 0.0
		_:
			return 0.0


static func _owned_stores(s: Dictionary) -> int:
	var n := 0
	for st: Dictionary in s.stores.values():
		if bool(st.owned):
			n += 1
	return n


static func _has_quality_lot(s: Dictionary, q: int) -> bool:
	for lot: Dictionary in s.lots:
		if int(lot.quality) >= q:
			return true
	# Also check historical stats flag set on batch completion.
	return bool(s.stats.get("had_quality_%d" % q, false))


static func _machines_at_tier(s: Dictionary, tier: int) -> int:
	var n := 0
	for m: Dictionary in s.machines.values():
		if int(m.tier) >= tier:
			n += 1
	return n


static func _grant_rewards(s: Dictionary, def: Dictionary) -> void:
	var rew: Dictionary = def.get("rewards", {})
	if rew.has("cash"):
		EconomySim.earn(s, float(rew.cash), "Objective reward")
	if rew.has("research_points"):
		s.research_points = int(s.research_points) + int(rew.research_points)
	if rew.has("reputation"):
		s.reputation = clampf(float(s.reputation) + float(rew.reputation), 0.0, 100.0)


## Fraction of tutorial chain finished (for HUD checklist).
static func tutorial_progress(s: Dictionary) -> float:
	var total := 0
	var done := 0
	for def: Dictionary in DataRegistry.objectives.values():
		if str(def.get("kind", "")) != "tutorial":
			continue
		total += 1
		if bool(s.objectives.get(str(def.id), {}).get("done", false)):
			done += 1
	return float(done) / maxf(1.0, float(total))
