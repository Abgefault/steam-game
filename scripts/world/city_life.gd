class_name CityLife
extends Node3D
## Brings the city to life with lightweight, non-physics traffic and
## pedestrians that loop along the streets and sidewalks. Everything is pure
## transform animation (no collisions/navmesh) so it stays cheap even with the
## bigger city, and it respects the reduced-motion accessibility setting.

const CAR_COLORS := [Color(0.7, 0.1, 0.1), Color(0.1, 0.2, 0.5), Color(0.9, 0.9, 0.92),
	Color(0.1, 0.1, 0.12), Color(0.3, 0.5, 0.3), Color(0.6, 0.6, 0.62),
	Color(0.2, 0.4, 0.6), Color(0.8, 0.7, 0.2)]

# Each traffic lane: fixed z + y, a travel direction and a speed.
var _cars: Array[Dictionary] = []
var _peds: Array[Dictionary] = []
var _enabled := true
var _x_min := -110.0
var _x_max := 110.0


func _ready() -> void:
	_enabled = not bool(SettingsService.get_v("reduced_motion"))
	_spawn_traffic()
	_spawn_pedestrians()


func _spawn_traffic() -> void:
	# Near + far avenues, each with an east- and a west-bound lane.
	var lanes := [
		{"z": 15.6, "dir": 1.0},   # near avenue eastbound
		{"z": 20.4, "dir": -1.0},  # near avenue westbound
		{"z": 47.6, "dir": 1.0},   # far avenue eastbound
		{"z": 52.4, "dir": -1.0},  # far avenue westbound
	]
	for lane: Dictionary in lanes:
		var count := 4
		for i in count:
			var car := CityBuilder.make_car(CAR_COLORS.pick_random())
			car.rotation_degrees.y = 90.0 if float(lane.dir) > 0 else -90.0
			var x := _x_min + (i + randf()) * (_x_max - _x_min) / count
			car.position = Vector3(x, 0, float(lane.z))
			add_child(car)
			_cars.append({"node": car, "z": float(lane.z), "dir": float(lane.dir),
				"speed": randf_range(7.0, 11.0)})


func _spawn_pedestrians() -> void:
	# Walkers pacing the near sidewalks (both sides of the shop's avenue).
	var lanes := [11.0, 24.6]
	for z in lanes:
		for i in 5:
			var ped := Node3D.new()
			PersonAgent.build_figure(ped, Color.from_hsv(randf(), 0.35, randf_range(0.4, 0.75)))
			var dir := 1.0 if i % 2 == 0 else -1.0
			var x := randf_range(_x_min * 0.5, _x_max * 0.5)
			ped.position = Vector3(x, 0, z + randf_range(-0.5, 0.5))
			ped.rotation.y = deg_to_rad(90.0 if dir > 0 else -90.0)
			add_child(ped)
			_peds.append({"node": ped, "z": ped.position.z, "dir": dir,
				"speed": randf_range(1.1, 1.8), "bob": randf() * TAU})


func _process(delta: float) -> void:
	if not _enabled:
		return
	for c in _cars:
		var node: Node3D = c.node
		node.position.x += float(c.dir) * float(c.speed) * delta
		if float(c.dir) > 0 and node.position.x > _x_max:
			node.position.x = _x_min
		elif float(c.dir) < 0 and node.position.x < _x_min:
			node.position.x = _x_max
	var half := (_x_max - _x_min) * 0.5
	for p in _peds:
		var node: Node3D = p.node
		node.position.x += float(p.dir) * float(p.speed) * delta
		# Gentle walk bob.
		p.bob = float(p.bob) + delta * float(p.speed) * 3.0
		node.position.y = absf(sin(float(p.bob))) * 0.04
		if absf(node.position.x) > half:
			p.dir = -float(p.dir)
			node.rotation.y = deg_to_rad(90.0 if float(p.dir) > 0 else -90.0)
