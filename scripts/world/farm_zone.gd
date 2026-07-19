class_name FarmZone
extends Node3D
## The visible cultivation farm: grow tables with plant rows under magenta
## grow lights, foil-lined walls and a drip line. Plant size mirrors the
## cultivation machine's real progress; after harvest the tables reset to
## seedlings. All values are abstract game-play fiction.

var machine_id := "m_cultivation_1"
var _plants: Array[PlantNode] = []
var _grow_light_mat: StandardMaterial3D


func _ready() -> void:
	_build()
	EventBus.machine_state_changed.connect(func(id: String):
		if id == machine_id:
			_refresh_growth())
	_refresh_growth()


func _build() -> void:
	var frame_mat := MaterialLib.painted_metal(Color(1.2, 1.22, 1.25))
	var top_mat := MaterialLib.diamond_plate(Color(0.85, 0.86, 0.9))
	# Reflective foil wall panels behind the tables.
	var foil := MaterialLib.pbr("Metal030", 0.9, Color(1.9, 1.92, 1.95), true, 0.85, 0.5)
	_box(Vector3(5.6, 2.6, 0.08), Vector3(0, 1.3, -1.55), foil)
	# Two grow tables with plant rows.
	for tz in [0.0, 1.9]:
		_box(Vector3(5.4, 0.08, 1.1), Vector3(0, 0.75, tz - 0.6), top_mat)
		for lx in [-2.5, -0.85, 0.85, 2.5]:
			_box(Vector3(0.07, 0.75, 0.07), Vector3(lx, 0.37, tz - 0.6), frame_mat)
		# Drip line along the table.
		_box(Vector3(5.4, 0.03, 0.03), Vector3(0, 1.75, tz - 0.6), frame_mat)
		for px in 6:
			var plant := PlantNode.create(true)
			plant.position = Vector3(-2.25 + px * 0.9, 0.79, tz - 0.6 + randf_range(-0.1, 0.1))
			plant.rotation.y = randf() * TAU
			add_child(plant)
			_plants.append(plant)
	# Grow-light bars with magenta emission above each table.
	_grow_light_mat = StandardMaterial3D.new()
	_grow_light_mat.albedo_color = Color(0.9, 0.6, 0.95)
	_grow_light_mat.emission_enabled = true
	_grow_light_mat.emission = Color(0.85, 0.35, 0.9)
	_grow_light_mat.emission_energy_multiplier = 2.2
	for tz in [0.0, 1.9]:
		for lx in [-1.6, 0.0, 1.6]:
			var bar := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(1.4, 0.05, 0.18)
			bar.mesh = bm
			bar.position = Vector3(lx, 2.05, tz - 0.6)
			bar.material_override = _grow_light_mat
			add_child(bar)
			var hanger_mat := MaterialLib.painted_metal(Color(0.8, 0.82, 0.85))
			for hx in [-0.55, 0.55]:
				var wire := MeshInstance3D.new()
				var wm := CylinderMesh.new()
				wm.top_radius = 0.012
				wm.bottom_radius = 0.012
				wm.height = 1.4
				wire.mesh = wm
				wire.position = Vector3(lx + hx, 2.75, tz - 0.6)
				wire.material_override = hanger_mat
				add_child(wire)
		var light := OmniLight3D.new()
		light.position = Vector3(0, 2.0, tz - 0.6)
		light.light_color = Color(0.95, 0.55, 0.95)
		light.light_energy = 2.4
		light.omni_range = 4.5
		light.shadow_enabled = false
		add_child(light)
	# Zone sign.
	var sign := Label3D.new()
	sign.text = "CULTIVATION FARM"
	sign.position = Vector3(0, 2.75, -1.4)
	sign.font_size = 52
	sign.pixel_size = 0.006
	sign.outline_size = 10
	sign.modulate = Color(0.75, 0.9, 0.78)
	add_child(sign)


func _box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	add_child(mi)
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)
	mi.add_child(body)


func _process(_delta: float) -> void:
	# While the cultivation run is active, plants visibly grow with progress.
	if Engine.get_process_frames() % 30 != 0:
		return
	_refresh_growth()


func _refresh_growth() -> void:
	if not Game.in_session:
		return
	var m: Dictionary = Game.state.machines.get(machine_id, {})
	if m.is_empty():
		return
	var t := 0.2
	match str(m.state):
		"running":
			t = float(m.progress) / maxf(1.0, float(m.duration))
		"done":
			t = 1.0
		_:
			t = 0.2
	for p in _plants:
		p.set_growth(t)
