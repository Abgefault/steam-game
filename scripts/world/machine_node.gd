class_name MachineNode
extends StaticBody3D
## 3D representation of a machine instance: distinct silhouette per type,
## state light, progress readout, hum audio while running, interaction.
## Depositing a matching carried container feeds the machine.

var machine_id: String = ""
var _body_mat: StandardMaterial3D
var _light_mat: StandardMaterial3D
var _status: Label3D
var _hum: AudioStreamPlayer3D
var _rotor: Node3D


static func create(id: String) -> MachineNode:
	var node := MachineNode.new()
	node.machine_id = id
	node._build()
	return node


func _build() -> void:
	var m: Dictionary = Game.state.machines.get(machine_id, {})
	var def_id := str(m.get("def_id", "product"))
	_body_mat = MaterialLib.pbr("Metal030", 0.6, Color(2.1, 2.14, 2.16), false, 0.45)
	var accent_base := _accent_color(def_id)
	var accent := MaterialLib.pbr("Metal030", 0.8,
		Color(accent_base.r * 2.6, accent_base.g * 2.6, accent_base.b * 2.6), false, 0.3)
	# Industrial diamond-plate service platform under every machine.
	_box(Vector3(2.4, 0.06, 1.5), Vector3(0, 0.03, 0), MaterialLib.diamond_plate())
	# Shared industrial dressing: slim hazard-stripe skirt and machine feet.
	_box(Vector3(1.7, 0.05, 1.2), Vector3(0, 0.028, 0),
		MaterialLib.pbr("hazard", 2.2, Color(0.72, 0.72, 0.72), false))
	var foot_mat := MaterialLib.pbr("Metal030", 1.0, Color(0.9, 0.92, 0.94), false, 0.7)
	for fx in [-0.75, 0.75]:
		for fz in [-0.45, 0.45]:
			_cyl(0.05, 0.14, Vector3(fx, 0.07, fz), foot_mat)
	# Distinct silhouettes per machine type, assembled from primitives.
	match def_id:
		"cultivation":
			# Farm control cabinet + nutrient tank; the plants themselves grow
			# on the FarmZone tables next to it.
			_box(Vector3(1.2, 1.8, 0.7), Vector3(-0.35, 0.9, 0), _body_mat)
			_screen(Vector3(-0.35, 1.35, 0.37), Vector2(0.7, 0.5), Color(0.4, 0.9, 0.5))
			_box(Vector3(0.9, 0.35, 0.62), Vector3(-0.35, 0.35, 0.02), accent)  # drawer
			_cyl(0.34, 1.3, Vector3(0.75, 0.65, 0), MaterialLib.pbr("Metal030", 0.8,
				Color(1.6, 1.7, 1.75), false, 0.3))                              # tank
			_cyl(0.05, 0.9, Vector3(0.75, 1.75, 0), foot_mat)                    # tank pipe
			_pipe(Vector3(0.75, 2.1, 0), Vector3(-1.6, 2.1, 0), foot_mat)        # feed line
		"conditioning":
			_box(Vector3(1.3, 1.7, 1.0), Vector3(0, 0.85, 0), _body_mat)
			_box(Vector3(1.1, 1.1, 0.06), Vector3(0, 0.9, 0.5), accent)          # door
			for i in 5:
				_box(Vector3(0.9, 0.03, 0.08), Vector3(0, 0.55 + i * 0.18, 0.54),
					foot_mat)                                                     # louvers
			_cyl(0.1, 0.5, Vector3(0.5, 1.85, 0), _body_mat)                     # vent stack
			_cyl(0.16, 0.1, Vector3(0.5, 2.12, 0), accent)                       # vent cap
			_screen(Vector3(-0.45, 1.5, 0.51), Vector2(0.35, 0.25), Color(0.95, 0.75, 0.3))
		"processing":
			_box(Vector3(1.9, 1.2, 1.1), Vector3(0, 0.6, 0), _body_mat)
			var hopper := MeshInstance3D.new()
			var hop_mesh := CylinderMesh.new()
			hop_mesh.top_radius = 0.45
			hop_mesh.bottom_radius = 0.16
			hop_mesh.height = 0.7
			hopper.mesh = hop_mesh
			hopper.position = Vector3(-0.5, 1.65, 0)
			hopper.material_override = accent
			add_child(hopper)
			_box(Vector3(0.6, 0.5, 0.7), Vector3(0.65, 1.4, 0), _body_mat)
			_screen(Vector3(0.65, 1.45, 0.36), Vector2(0.4, 0.28), Color(0.5, 0.8, 1.0))
			_pipe(Vector3(-0.5, 1.2, 0.4), Vector3(0.65, 1.2, 0.4), foot_mat)
			_rotor = Node3D.new()
			_rotor.position = Vector3(-0.5, 1.35, 0)
			add_child(_rotor)
			var blade := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = Vector3(0.55, 0.05, 0.12)
			blade.mesh = bm
			blade.material_override = accent
			_rotor.add_child(blade)
		"lab":
			_box(Vector3(1.6, 0.9, 0.9), Vector3(0, 0.45, 0),
				MaterialLib.pbr("Metal030", 0.7, Color(2.4, 2.45, 2.5), false, 0.2))  # white bench
			_box(Vector3(0.5, 0.7, 0.5), Vector3(-0.4, 1.25, 0),
				MaterialLib.pbr("Metal030", 0.9, Color(2.2, 2.25, 2.3), false, 0.2))  # analyzer
			_screen(Vector3(-0.4, 1.35, 0.26), Vector2(0.34, 0.24), Color(0.4, 0.95, 0.6))
			_cyl(0.08, 0.4, Vector3(0.3, 1.1, 0.15), accent)                          # sample tubes
			_cyl(0.08, 0.3, Vector3(0.55, 1.05, -0.1), accent)
			_cyl(0.06, 0.24, Vector3(0.72, 1.02, 0.18), accent)
			_box(Vector3(0.4, 0.02, 0.3), Vector3(0.15, 0.92, -0.25),
				MaterialLib.cardboard())                                              # clipboard
		"product":
			_box(Vector3(2.2, 1.4, 1.1), Vector3(0, 0.7, 0), _body_mat)
			# Gantry frame over the forming head.
			for gx in [-1.35, 0.05]:
				_box(Vector3(0.08, 1.1, 0.08), Vector3(gx, 1.95, -0.35), foot_mat)
				_box(Vector3(0.08, 1.1, 0.08), Vector3(gx, 1.95, 0.35), foot_mat)
			_box(Vector3(1.5, 0.08, 0.9), Vector3(-0.65, 2.5, 0), foot_mat)
			_box(Vector3(0.7, 0.7, 0.9), Vector3(-0.65, 1.75, 0), accent)   # forming head
			_box(Vector3(1.2, 0.1, 0.8), Vector3(0.4, 1.45, 0), _body_mat)  # out tray
			_screen(Vector3(0.85, 1.0, 0.56), Vector2(0.5, 0.35), Color(0.85, 0.55, 0.95))
		"packaging":
			_box(Vector3(2.0, 1.1, 1.0), Vector3(0, 0.55, 0), _body_mat)
			_box(Vector3(0.5, 0.9, 0.9), Vector3(0.8, 1.55, 0), accent)     # label arm
			_cyl(0.18, 0.3, Vector3(0.8, 2.1, 0), foot_mat)                 # label roll
			_box(Vector3(1.0, 0.05, 0.8), Vector3(-0.5, 1.15, 0),
				MaterialLib.rubber_belt())                                  # feed belt
			for rx in [-0.9, -0.5, -0.1]:
				_cyl(0.04, 0.8, Vector3(rx, 1.12, 0), foot_mat, true)       # rollers
			_screen(Vector3(0.35, 1.0, 0.51), Vector2(0.4, 0.3), Color(0.95, 0.85, 0.4))
	# State light on a small mast.
	_light_mat = StandardMaterial3D.new()
	_light_mat.albedo_color = Color(0.3, 0.9, 0.3)
	_light_mat.emission_enabled = true
	_light_mat.emission_energy_multiplier = 1.6
	var mast := MeshInstance3D.new()
	var mast_mesh := CylinderMesh.new()
	mast_mesh.top_radius = 0.03
	mast_mesh.bottom_radius = 0.03
	mast_mesh.height = 0.5
	mast.mesh = mast_mesh
	mast.position = Vector3(0.75, 2.1, 0.35)
	mast.material_override = _body_mat
	add_child(mast)
	var bulb := MeshInstance3D.new()
	var bulb_mesh := SphereMesh.new()
	bulb_mesh.radius = 0.07
	bulb_mesh.height = 0.14
	bulb.mesh = bulb_mesh
	bulb.position = Vector3(0.75, 2.4, 0.35)
	bulb.material_override = _light_mat
	add_child(bulb)
	# Status readout.
	_status = Label3D.new()
	_status.position = Vector3(0, 2.7, 0)
	_status.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status.font_size = 44
	_status.pixel_size = 0.005
	_status.outline_size = 8
	add_child(_status)
	# Collision.
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.2, 2.2, 1.2)
	col.shape = shape
	col.position.y = 1.1
	add_child(col)
	# Hum audio.
	_hum = AudioStreamPlayer3D.new()
	_hum.unit_size = 4.0
	_hum.max_db = -6.0
	add_child(_hum)
	AudioService.attach_stream(_hum, _hum_track(def_id), true)
	EventBus.machine_state_changed.connect(_on_state_changed)
	_refresh()


func _box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	add_child(mi)


func _cyl(radius: float, height: float, pos: Vector3, mat: Material,
		horizontal: bool = false) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos
	if horizontal:
		mi.rotation_degrees.x = 90
	mi.material_override = mat
	add_child(mi)


## Emissive control screen with a dark bezel.
func _screen(pos: Vector3, size: Vector2, glow_color: Color) -> void:
	var bezel := MeshInstance3D.new()
	var bezel_mesh := BoxMesh.new()
	bezel_mesh.size = Vector3(size.x + 0.06, size.y + 0.06, 0.03)
	bezel.mesh = bezel_mesh
	bezel.position = pos
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.albedo_color = Color(0.12, 0.12, 0.14)
	bezel_mat.roughness = 0.4
	bezel.material_override = bezel_mat
	add_child(bezel)
	var screen := MeshInstance3D.new()
	var screen_mesh := BoxMesh.new()
	screen_mesh.size = Vector3(size.x, size.y, 0.035)
	screen.mesh = screen_mesh
	screen.position = pos
	var glow := StandardMaterial3D.new()
	glow.albedo_color = glow_color * 0.4
	glow.emission_enabled = true
	glow.emission = glow_color
	glow.emission_energy_multiplier = 0.9
	screen.material_override = glow
	add_child(screen)


## A straight pipe between two points.
func _pipe(from: Vector3, to: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.045
	mesh.bottom_radius = 0.045
	mesh.height = from.distance_to(to)
	mi.mesh = mesh
	mi.position = (from + to) / 2.0
	var dir := (to - from).normalized()
	if absf(dir.y) < 0.99:
		var axis := Vector3.UP.cross(dir).normalized()
		mi.rotate(axis, Vector3.UP.angle_to(dir))
	mi.material_override = mat
	add_child(mi)


func _accent_color(def_id: String) -> Color:
	match def_id:
		"cultivation": return Color(0.3, 0.55, 0.35)
		"conditioning": return Color(0.6, 0.5, 0.3)
		"processing": return Color(0.35, 0.45, 0.6)
		"lab": return Color(0.8, 0.85, 0.9)
		"product": return Color(0.55, 0.4, 0.55)
		"packaging": return Color(0.7, 0.6, 0.35)
	return Color(0.5, 0.5, 0.5)


func _hum_track(def_id: String) -> String:
	match def_id:
		"cultivation", "conditioning": return "machine_hum_low"
		"processing", "product": return "machine_hum_mid"
	return "machine_hum_high"


func _on_state_changed(id: String) -> void:
	if id == machine_id:
		_refresh()


func _process(delta: float) -> void:
	var m: Dictionary = Game.state.machines.get(machine_id, {})
	if m.is_empty():
		return
	if str(m.state) == "running":
		if not _hum.playing:
			_hum.play()
		if _rotor != null:
			_rotor.rotate_y(delta * 6.0)
		if Engine.get_process_frames() % 20 == 0:
			_status.text = "%s\n%d%%" % [MachineSim.display_name(m).to_upper(),
				int(float(m.progress) / maxf(1.0, float(m.duration)) * 100.0)]
	elif _hum.playing:
		_hum.stop()


func _refresh() -> void:
	var m: Dictionary = Game.state.machines.get(machine_id, {})
	if m.is_empty():
		return
	var tier_txt := "T%d" % int(m.tier)
	match str(m.state):
		"idle":
			_light_mat.albedo_color = Color(0.35, 0.75, 0.4)
			_light_mat.emission = Color(0.2, 0.7, 0.3)
			_status.text = "%s %s\nIDLE" % [MachineSim.display_name(m).to_upper(), tier_txt]
			_status.modulate = Color(0.75, 0.85, 0.78)
		"running":
			_light_mat.albedo_color = Color(1.0, 0.75, 0.2)
			_light_mat.emission = Color(1.0, 0.65, 0.1)
			_status.modulate = Color(1.0, 0.85, 0.5)
			_status.text = "%s %s\nRUNNING" % [MachineSim.display_name(m).to_upper(), tier_txt]
		"done":
			_light_mat.albedo_color = Color(0.3, 0.7, 1.0)
			_light_mat.emission = Color(0.2, 0.6, 1.0)
			_status.text = "%s %s\nOUTPUT READY" % [MachineSim.display_name(m).to_upper(), tier_txt]
			_status.modulate = Color(0.6, 0.85, 1.0)
		"broken":
			_light_mat.albedo_color = Color(1.0, 0.2, 0.2)
			_light_mat.emission = Color(1.0, 0.1, 0.1)
			_status.text = "%s %s\nBROKEN" % [MachineSim.display_name(m).to_upper(), tier_txt]
			_status.modulate = Color(1.0, 0.5, 0.5)


func get_prompt() -> String:
	var m: Dictionary = Game.state.machines.get(machine_id, {})
	if m.is_empty():
		return ""
	match str(m.state):
		"idle": return "Operate %s" % MachineSim.display_name(m)
		"running": return "%s is running (%d%%)" % [MachineSim.display_name(m),
			int(float(m.progress) / maxf(1.0, float(m.duration)) * 100.0)]
		"done": return "Unload %s" % MachineSim.display_name(m)
		"broken": return "Repair %s (needs spare part)" % MachineSim.display_name(m)
	return ""


func interact(player: Player) -> void:
	var m: Dictionary = Game.state.machines.get(machine_id, {})
	if m.is_empty():
		return
	# Feeding a carried container into a matching machine.
	if player.carried is ContainerNode and str(m.state) == "idle":
		var c: ContainerNode = player.carried
		var accepted := _accepts(str(m.def_id), str(c.payload.get("kind", "")))
		if accepted:
			MachineSim.apply_output(Game.state, c.payload)
			player.consume_carried()
			EventBus.notify("Container deposited into %s supply." % MachineSim.display_name(m), "info")
			MachineSim.load_and_start(Game.state, machine_id, _default_payload(m), false)
			return
	match str(m.state):
		"idle":
			get_tree().current_scene.call("open_machine_dialog", machine_id)
		"running":
			pass
		"done":
			var out := MachineSim.unload_deferred(Game.state, machine_id)
			if out.get("deferred", false):
				var container := ContainerNode.create(out)
				get_tree().current_scene.call("spawn_container", container,
					global_position + global_transform.basis.z * 1.3)
				EventBus.notify("Output unloaded — carry the container onward (E to pick up).", "info")
			else:
				EventBus.notify("Done: results recorded.", "success")
		"broken":
			MachineSim.repair(Game.state, machine_id, false)
			AudioService.play_sfx("repair")


func _accepts(def_id: String, kind: String) -> bool:
	match def_id:
		"conditioning": return kind == "cultivation"
		"processing": return kind == "conditioning"
	return false


func _default_payload(m: Dictionary) -> Dictionary:
	if str(m.def_id) == "cultivation":
		return {"strain_id": StaffSim._preferred_strain(Game.state)}
	if str(m.def_id) == "product":
		return {"product_id": str(m.get("recipe", ""))}
	return {}
