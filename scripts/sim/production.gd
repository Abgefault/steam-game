class_name ProductionSim
## Batch pipeline through the abstract production chain:
## cultivation -> conditioning -> processing -> lab -> product -> packaging.
## Machines hold at most one running batch. All quantities/qualities are
## fictional gameplay values; no real-world process data exists anywhere.

const CHAIN: PackedStringArray = ["cultivation", "conditioning", "processing", "lab", "product", "packaging"]


static func tick_minute(s: Dictionary) -> void:
	for m: Dictionary in s.machines.values():
		if str(m.state) != "running":
			continue
		var speed := MachineSim.speed_factor(s, m)
		m.progress = float(m.progress) + speed
		if float(m.progress) >= float(m.duration):
			m.state = "done"
			m.progress = float(m.duration)
			EventBus.machine_state_changed.emit(str(m.id))
			AudioService.play_sfx("machine_done")
			MachineSim.try_auto_unload(s, str(m.id))


## Quality roll for a finished product batch (0..3).
static func roll_quality(s: Dictionary, product: Dictionary, machine: Dictionary) -> int:
	var potential := int(product.quality_potential)
	var tier := float(machine.tier)
	var condition := float(machine.condition) / 100.0
	var skill := StaffSim.best_skill_at(s, "production") / 10.0
	var lab_bonus := 0.15 if Game.has_research("lab_protocols") else 0.0
	var score := 0.35 * (tier / 3.0) + 0.25 * condition + 0.25 * skill + lab_bonus
	score += randf_range(-0.12, 0.12)
	if Game.has_research("quality_consistency"):
		score += 0.08
	var q := int(floorf(score * (potential + 1)))
	return clampi(q, 0, potential)


## Rejection probability at packaging, driven by machine condition and research.
static func reject_rate(s: Dictionary, machine: Dictionary) -> float:
	var base := 0.02 + (100.0 - float(machine.condition)) * 0.0012
	if Game.has_research("quality_sensors"):
		base *= 0.5
	return clampf(base, 0.0, 0.35)
