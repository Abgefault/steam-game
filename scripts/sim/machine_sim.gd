class_name MachineSim
## Machine instances: loading, starting, unloading, wear, maintenance,
## conveyor auto-transfer. The 3D world visualizes these states; employees
## and automation policies drive the same functions with automated=true.


static func get_machine(s: Dictionary, id: String) -> Dictionary:
	return s.machines.get(id, {})


static func def_of(m: Dictionary) -> Dictionary:
	return DataRegistry.machines.get(str(m.def_id), {})


static func tier_info(m: Dictionary) -> Dictionary:
	var tiers: Array = def_of(m).get("tiers", [])
	var idx := clampi(int(m.tier) - 1, 0, maxi(0, tiers.size() - 1))
	return tiers[idx] if idx < tiers.size() else {}


static func speed_factor(s: Dictionary, m: Dictionary) -> float:
	var f := 1.0 + 0.25 * (float(m.tier) - 1.0)
	f *= lerpf(0.55, 1.0, float(m.condition) / 100.0)
	if Game.has_research("fast_processing"):
		f *= 1.15
	return f


## Human-readable reason why loading is impossible, or "" when it is possible.
static func load_blocker(s: Dictionary, machine_id: String, payload: Dictionary) -> String:
	var m := get_machine(s, machine_id)
	if m.is_empty():
		return "Unknown machine."
	if str(m.state) == "running":
		return "Machine is running."
	if str(m.state) == "done":
		return "Output must be unloaded first."
	if str(m.state) == "broken":
		return "Machine is broken. Repair it with a spare part."
	match str(m.def_id):
		"cultivation":
			if int(s.supplies.seed_units) < 1:
				return "No cultivation seed kits in stock. Buy supplies on the tablet."
		"conditioning":
			if _pool_total(s.raw) < 1:
				return "No harvest containers to condition."
		"processing":
			if _pool_total(s.conditioned) < 1:
				return "No conditioned containers available."
		"lab":
			if _find_batch_for_lab(s) == null:
				return "No untested batch is waiting for lab testing."
		"product":
			var pid := str(payload.get("product_id", ""))
			if pid == "":
				return "Select a product recipe first."
			var p: Dictionary = DataRegistry.products.get(pid, {})
			var need := int(ceilf(float(p.batch_size) / 2.0))
			if int(s.processed.get(str(p.strain), 0)) < need:
				return "Needs %d refined %s material (have %d)." % [
					need, DataRegistry.strains.get(str(p.strain), {}).get("name", "?"),
					int(s.processed.get(str(p.strain), 0))]
			if int(p.stage_required) > int(s.stage):
				return "Requires company stage %d." % int(p.stage_required)
			if int(m.tier) < int(p.get("machine_tier", 1)):
				return "Requires a Tier %d product machine." % int(p.get("machine_tier", 1))
		"packaging":
			var b: Variant = _find_batch_for_packaging(s)
			if b == null:
				return "No tested batch is ready for packaging."
			if int(s.supplies.packaging_units) < int(b.qty):
				return "Not enough packaging supplies (%d needed)." % int(b.qty)
	return ""


## Load inputs and start the machine. Consumes inputs from stock pools.
static func load_and_start(s: Dictionary, machine_id: String, payload: Dictionary,
		automated: bool = false) -> bool:
	var blocker := load_blocker(s, machine_id, payload)
	if blocker != "":
		if not automated:
			EventBus.notify(blocker, "warning")
		return false
	var m := get_machine(s, machine_id)
	var minutes := 60.0
	match str(m.def_id):
		"cultivation":
			var strain_id := str(payload.get("strain_id", DataRegistry.strains.keys()[0]))
			var strain: Dictionary = DataRegistry.strains.get(strain_id, {})
			s.supplies.seed_units = int(s.supplies.seed_units) - 1
			m["payload"] = {"strain_id": strain_id, "qty": int(strain.get("yield", 4))}
			minutes = float(strain.get("grow_minutes", 240))
		"conditioning":
			var sid := _pool_first(s.raw)
			var take: int = mini(int(s.raw[sid]), 4)
			s.raw[sid] = int(s.raw[sid]) - take
			if int(s.raw[sid]) <= 0: s.raw.erase(sid)
			m["payload"] = {"strain_id": sid, "qty": take}
			minutes = 100.0
		"processing":
			var sid2 := _pool_first(s.conditioned)
			var take2: int = mini(int(s.conditioned[sid2]), 2)
			s.conditioned[sid2] = int(s.conditioned[sid2]) - take2
			if int(s.conditioned[sid2]) <= 0: s.conditioned.erase(sid2)
			m["payload"] = {"strain_id": sid2, "qty": take2 * 5}
			minutes = 90.0
		"lab":
			var b: Variant = _find_batch_for_lab(s)
			b["in_lab"] = true
			m["payload"] = {"batch_id": int(b.id)}
			minutes = 70.0 if not Game.has_research("lab_protocols") else 45.0
		"product":
			var pid := str(payload.product_id)
			var p: Dictionary = DataRegistry.products[pid]
			var need := int(ceilf(float(p.batch_size) / 2.0))
			s.processed[str(p.strain)] = int(s.processed[str(p.strain)]) - need
			if int(s.processed[str(p.strain)]) <= 0: s.processed.erase(str(p.strain))
			var quality := ProductionSim.roll_quality(s, p, m)
			var batch := {"id": int(s.batch_seq), "product_id": pid, "qty": int(p.batch_size),
				"quality": quality, "tested": false, "in_lab": false, "packaged": false}
			s.batch_seq = int(s.batch_seq) + 1
			s.batches.append(batch)
			m["payload"] = {"batch_id": int(batch.id)}
			minutes = float(p.prod_minutes)
		"packaging":
			var b2: Variant = _find_batch_for_packaging(s)
			b2["packaged"] = true   # claimed by this machine
			s.supplies.packaging_units = int(s.supplies.packaging_units) - int(b2.qty)
			m["payload"] = {"batch_id": int(b2.id)}
			minutes = 40.0 + float(b2.qty) * 1.5
	m.state = "running"
	m.progress = 0.0
	m.duration = minutes
	Game.log_action("production", automated)
	EventBus.machine_state_changed.emit(machine_id)
	if not automated:
		AudioService.play_sfx("machine_start")
	return true


## Collect the finished output. Returns a description of what was produced.
static func unload(s: Dictionary, machine_id: String, automated: bool = false) -> Dictionary:
	var m := get_machine(s, machine_id)
	if m.is_empty() or str(m.state) != "done":
		return {}
	var out: Dictionary = {}
	var payload: Dictionary = m.get("payload", {})
	match str(m.def_id):
		"cultivation":
			var sid := str(payload.strain_id)
			s.raw[sid] = int(s.raw.get(sid, 0)) + int(payload.qty)
			out = {"kind": "raw", "strain_id": sid, "qty": int(payload.qty)}
		"conditioning":
			var sid := str(payload.strain_id)
			s.conditioned[sid] = int(s.conditioned.get(sid, 0)) + int(payload.qty)
			out = {"kind": "conditioned", "strain_id": sid, "qty": int(payload.qty)}
		"processing":
			var sid := str(payload.strain_id)
			s.processed[sid] = int(s.processed.get(sid, 0)) + int(payload.qty)
			out = {"kind": "processed", "strain_id": sid, "qty": int(payload.qty)}
		"lab":
			var b: Variant = _batch_by_id(s, int(payload.batch_id))
			if b != null:
				b["tested"] = true
				b["in_lab"] = false
				out = {"kind": "tested_batch", "batch_id": int(b.id)}
			Game.log_action("quality", automated)
		"product":
			# Batch already exists; unloading frees the machine.
			out = {"kind": "product_batch", "batch_id": int(payload.batch_id)}
		"packaging":
			var b2: Variant = _batch_by_id(s, int(payload.batch_id))
			if b2 != null:
				var rejects := 0
				for i in int(b2.qty):
					if randf() < ProductionSim.reject_rate(s, m):
						rejects += 1
				var good := int(b2.qty) - rejects
				if good > 0:
					var lot := InventorySim.make_lot(s, str(b2.product_id), good,
						int(b2.quality), bool(b2.tested), "warehouse")
					out = {"kind": "lot", "lot_id": int(lot.id), "qty": good, "rejects": rejects}
					if int(b2.quality) >= 2:
						s.stats["had_quality_%d" % int(b2.quality)] = true
				s.batches.erase(b2)
				s.stats.batches_completed = int(s.stats.batches_completed) + 1
				if rejects > 0:
					s.daily.wasted_units += rejects
				EventBus.batch_completed.emit(b2)
			Game.log_action("packaging", automated)
	m.state = "idle"
	m.progress = 0.0
	m.erase("payload")
	Game.log_action("warehouse" if str(m.def_id) == "packaging" else "production", automated)
	EventBus.machine_state_changed.emit(machine_id)
	return out


## Manual unload path: frees the machine but returns the output payload
## WITHOUT applying it, so the player physically carries a container to its
## destination. Lab/product outputs apply instantly (digital results).
static func unload_deferred(s: Dictionary, machine_id: String) -> Dictionary:
	var m := get_machine(s, machine_id)
	if m.is_empty() or str(m.state) != "done":
		return {}
	if str(m.def_id) in ["lab", "product"]:
		return unload(s, machine_id, false)
	var payload: Dictionary = m.get("payload", {})
	var out: Dictionary = {"deferred": true, "def_id": str(m.def_id)}
	match str(m.def_id):
		"cultivation", "conditioning", "processing":
			out["kind"] = str(m.def_id)
			out["strain_id"] = str(payload.strain_id)
			out["qty"] = int(payload.qty)
		"packaging":
			var b: Variant = _batch_by_id(s, int(payload.batch_id))
			if b == null:
				return unload(s, machine_id, false)
			out["kind"] = "packaged"
			out["product_id"] = str(b.product_id)
			out["qty"] = int(b.qty)
			out["quality"] = int(b.quality)
			out["tested"] = bool(b.tested)
			out["reject_rate"] = ProductionSim.reject_rate(s, m)
			s.batches.erase(b)
			s.stats.batches_completed = int(s.stats.batches_completed) + 1
			EventBus.batch_completed.emit(b)
	m.state = "idle"
	m.progress = 0.0
	m.erase("payload")
	Game.log_action("production", false)
	EventBus.machine_state_changed.emit(machine_id)
	return out


## Apply a deferred (carried) output at its destination.
## dest: "" = stock pools/warehouse, or "display:<store_id>" for packaged lots.
static func apply_output(s: Dictionary, out: Dictionary, dest: String = "") -> void:
	match str(out.get("kind", "")):
		"cultivation":
			s.raw[str(out.strain_id)] = int(s.raw.get(str(out.strain_id), 0)) + int(out.qty)
		"conditioning":
			s.conditioned[str(out.strain_id)] = int(s.conditioned.get(str(out.strain_id), 0)) + int(out.qty)
		"processing":
			s.processed[str(out.strain_id)] = int(s.processed.get(str(out.strain_id), 0)) + int(out.qty)
		"packaged":
			var rejects := 0
			for i in int(out.qty):
				if randf() < float(out.get("reject_rate", 0.02)):
					rejects += 1
			var good := int(out.qty) - rejects
			if rejects > 0:
				s.daily.wasted_units += rejects
			if good > 0:
				var loc := dest if dest != "" else "warehouse"
				InventorySim.make_lot(s, str(out.product_id), good, int(out.quality),
					bool(out.tested), loc)
				if int(out.quality) >= 2:
					s.stats["had_quality_%d" % int(out.quality)] = true
	Game.log_action("warehouse", false)
	EventBus.inventory_changed.emit()


## Conveyor + auto-feed: when a machine finishes and a conveyor connects it
## to the next machine, output moves automatically (counts as automated).
static func try_auto_unload(s: Dictionary, machine_id: String) -> void:
	if not Game.has_research("conveyors"):
		return
	var target := ""
	for c: Dictionary in s.conveyors:
		if str(c.from) == machine_id:
			target = str(c.to)
			break
	if target == "":
		return
	var m := get_machine(s, machine_id)
	if str(m.state) != "done":
		return
	unload(s, machine_id, true)
	var t := get_machine(s, target)
	if not t.is_empty() and bool(t.get("auto_feed", false)) and str(t.state) == "idle":
		var payload: Dictionary = {}
		if str(t.def_id) == "product":
			payload = {"product_id": str(t.get("recipe", ""))}
		load_and_start(s, target, payload, true)


## Hourly wear on running machines; breakdown chance at low condition.
static func tick_hour(s: Dictionary) -> void:
	for m: Dictionary in s.machines.values():
		if str(m.state) == "running":
			var wear := DataRegistry.bal("machine_wear_per_hour", 1.1)
			if Game.has_research("durable_parts"):
				wear *= 0.6
			m.condition = maxf(0.0, float(m.condition) - wear)
			if float(m.condition) < 25.0 and randf() < 0.06:
				m.state = "broken"
				m.progress = 0.0
				m.erase("payload")
				EventBus.machine_state_changed.emit(str(m.id))
				EventBus.notify("%s broke down! Repair it with a spare part." % display_name(m), "error")
				EventBus.alert_raised.emit("broken_%s" % m.id, "%s is broken" % display_name(m), 2)


static func repair(s: Dictionary, machine_id: String, automated: bool = false) -> bool:
	var m := get_machine(s, machine_id)
	if m.is_empty():
		return false
	if int(s.supplies.spare_parts) < 1:
		if not automated:
			EventBus.notify("No spare parts available. Buy supplies on the tablet.", "warning")
		return false
	s.supplies.spare_parts = int(s.supplies.spare_parts) - 1
	m.condition = minf(100.0, float(m.condition) + 45.0)
	if str(m.state) == "broken":
		m.state = "idle"
	Game.log_action("maintenance", automated)
	EventBus.alert_cleared.emit("broken_%s" % machine_id)
	EventBus.machine_state_changed.emit(machine_id)
	return true


static func upgrade_cost(m: Dictionary) -> float:
	var tiers: Array = def_of(m).get("tiers", [])
	var next := int(m.tier)  # tiers are 1-based; index of next tier = current tier
	if next >= tiers.size():
		return -1.0
	return float(tiers[next].get("cost", 0.0))


static func upgrade(s: Dictionary, machine_id: String) -> bool:
	var m := get_machine(s, machine_id)
	var cost := upgrade_cost(m)
	if cost < 0.0:
		EventBus.notify("Already at maximum tier.", "info")
		return false
	if str(m.state) == "running":
		EventBus.notify("Cannot upgrade while running.", "warning")
		return false
	if not EconomySim.spend(s, cost, "Upgrade %s" % display_name(m), "production"):
		return false
	m.tier = int(m.tier) + 1
	m.condition = 100.0
	EventBus.machine_state_changed.emit(machine_id)
	EventBus.notify("%s upgraded to Tier %d." % [display_name(m), int(m.tier)], "success")
	return true


static func display_name(m: Dictionary) -> String:
	return str(def_of(m).get("name", str(m.get("def_id", "Machine"))))


static func facility_tier(s: Dictionary) -> int:
	# Facility tier = average machine tier rounded down, min of chain presence.
	var total := 0
	var count := 0
	for m: Dictionary in s.machines.values():
		total += int(m.tier)
		count += 1
	if count == 0:
		return 1
	@warning_ignore("integer_division")
	return clampi(int(float(total) / float(count) * 5.0 / 3.0), 1, 5)


static func _pool_total(pool: Dictionary) -> int:
	var t := 0
	for v in pool.values():
		t += int(v)
	return t


static func _pool_first(pool: Dictionary) -> String:
	for k in pool.keys():
		if int(pool[k]) > 0:
			return str(k)
	return ""


static func _find_batch_for_lab(s: Dictionary) -> Variant:
	for b: Dictionary in s.batches:
		if not bool(b.tested) and not bool(b.in_lab) and not bool(b.packaged):
			return b
	return null


static func _find_batch_for_packaging(s: Dictionary) -> Variant:
	for b: Dictionary in s.batches:
		if bool(b.tested) and not bool(b.packaged):
			return b
	return null


static func _batch_by_id(s: Dictionary, id: int) -> Variant:
	for b: Dictionary in s.batches:
		if int(b.id) == id:
			return b
	return null
