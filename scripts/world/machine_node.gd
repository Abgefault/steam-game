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
	_body_mat = StandardMaterial3D.new()
	_body_mat.albedo_color = Color(0.58, 0.6, 0.62)
	_body_mat.metallic = 0.55
	_body_mat.roughness = 0.45
	var accent := StandardMaterial3D.new()
	accent.albedo_color = _accent_color(def_id)
	accent.metallic = 0.3
	accent.roughness = 0.5
	# Distinct silhouettes per machine type, assembled from primitives.
	match def_id:
		"cultivation":
			_box(Vector3(1.7, 2.0, 1.0), Vector3(0, 1.0, 0), _body_mat)
			for i in 3:
				_box(Vector3(1.5, 0.06, 0.85), Vector3(0, 0.55 + i * 0.55, 0), accent)
			var glow := StandardMaterial3D.new()
			glow.albedo_color = Color(0.85, 0.6, 0.9)
			glow.emission_enabled = true
			glow.emission = Color(0.75, 0.4, 0.85)
			glow.emission_energy_multiplier = 0.8
			_box(Vector3(1.4, 0.04, 0.8), Vector3(0, 1.85, 0), glow)
		"conditioning":
			_box(Vector3(1.3, 1.7, 1.0), Vector3(0, 0.85, 0), _body_mat)
			_box(Vector3(1.1, 1.1, 0.06), Vector3(0, 0.9, 0.5), accent)  # door
			_cyl(0.1, 0.5, Vector3(0.5, 1.85, 0), _body_mat)             # vent stack
		"processing":
			_box(Vector3(1.9, 1.2, 1.1), Vector3(0, 0.6, 0), _body_mat)
			_cyl(0.35, 0.9, Vector3(-0.5, 1.6, 0), accent)               # hopper
			_box(Vector3(0.6, 0.5, 0.7), Vector3(0.65, 1.4, 0), _body_mat)
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
			_box(Vector3(1.6, 0.9, 0.9), Vector3(0, 0.45, 0), _body_mat)   # bench
			var white := StandardMaterial3D.new()
			white.albedo_color = Color(0.92, 0.94, 0.95)
			white.roughness = 0.3
			_box(Vector3(0.5, 0.7, 0.5), Vector3(-0.4, 1.25, 0), white)    # analyzer
			_cyl(0.08, 0.4, Vector3(0.3, 1.1, 0.15), accent)               # sample tube
			_cyl(0.08, 0.3, Vector3(0.5, 1.05, -0.1), accent)
		"product":
			_box(Vector3(2.2, 1.4, 1.1), Vector3(0, 0.7, 0), _body_mat)
			_box(Vector3(0.7, 0.7, 0.9), Vector3(-0.9, 1.75, 0), accent)   # forming head
			_box(Vector3(1.2, 0.1, 0.8), Vector3(0.3, 1.45, 0), _body_mat) # out tray
		"packaging":
			_box(Vector3(2.0, 1.1, 1.0), Vector3(0, 0.55, 0), _body_mat)
			_box(Vector3(0.5, 0.9, 0.9), Vector3(0.8, 1.55, 0), accent)    # label arm
			_box(Vector3(1.0, 0.05, 0.8), Vector3(-0.5, 1.15, 0), accent)  # belt tray
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


func _cyl(radius: float, height: float, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos
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
