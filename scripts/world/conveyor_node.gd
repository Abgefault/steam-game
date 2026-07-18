class_name ConveyorNode
extends Node3D
## Visible conveyor belt between two machines. Small container meshes
## travel along it while the connection is actively transferring.

var from_id: String = ""
var to_id: String = ""
var _from_pos: Vector3
var _to_pos: Vector3
var _movers: Array[Dictionary] = []
var _mover_root: Node3D
var _audio: AudioStreamPlayer3D
var _spawn_accum := 0.0


static func create(p_from: String, p_to: String, from_pos: Vector3, to_pos: Vector3) -> ConveyorNode:
	var node := ConveyorNode.new()
	node.from_id = p_from
	node.to_id = p_to
	node._from_pos = from_pos
	node._to_pos = to_pos
	return node


func _ready() -> void:
	var dir := _to_pos - _from_pos
	var length := Vector3(dir.x, 0, dir.z).length()
	var mid := (_from_pos + _to_pos) / 2.0
	# Belt bed.
	var bed := MeshInstance3D.new()
	var bed_mesh := BoxMesh.new()
	bed_mesh.size = Vector3(length - 1.2, 0.08, 0.5)
	bed.mesh = bed_mesh
	var belt_mat := StandardMaterial3D.new()
	belt_mat.albedo_color = Color(0.15, 0.16, 0.18)
	belt_mat.roughness = 0.9
	bed.material_override = belt_mat
	position = Vector3(mid.x, 0.85, mid.z)
	rotation.y = atan2(-dir.z, dir.x)
	add_child(bed)
	# Side rails + legs.
	var rail_mat := StandardMaterial3D.new()
	rail_mat.albedo_color = Color(0.6, 0.62, 0.65)
	rail_mat.metallic = 0.6
	rail_mat.roughness = 0.4
	for zoff in [-0.28, 0.28]:
		var rail := MeshInstance3D.new()
		var rail_mesh := BoxMesh.new()
		rail_mesh.size = Vector3(length - 1.2, 0.06, 0.05)
		rail.mesh = rail_mesh
		rail.position = Vector3(0, 0.08, zoff)
		rail.material_override = rail_mat
		add_child(rail)
	var legs := int(length / 1.5)
	for i in maxi(legs, 2):
		var leg := MeshInstance3D.new()
		var leg_mesh := CylinderMesh.new()
		leg_mesh.top_radius = 0.04
		leg_mesh.bottom_radius = 0.04
		leg_mesh.height = 0.85
		leg.mesh = leg_mesh
		leg.position = Vector3(-(length - 1.4) / 2.0 + i * ((length - 1.4) / maxf(1.0, legs - 1)), -0.45, 0)
		leg.material_override = rail_mat
		add_child(leg)
	_mover_root = Node3D.new()
	add_child(_mover_root)
	_audio = AudioStreamPlayer3D.new()
	_audio.unit_size = 3.0
	_audio.max_db = -10.0
	add_child(_audio)
	AudioService.attach_stream(_audio, "conveyor_loop", true)


func _process(delta: float) -> void:
	var from_m: Dictionary = Game.state.machines.get(from_id, {})
	var active := not from_m.is_empty() and str(from_m.state) in ["running", "done"]
	if active:
		if not _audio.playing:
			_audio.play()
		_spawn_accum += delta
		if _spawn_accum > 2.2 and _movers.size() < 4:
			_spawn_accum = 0.0
			_spawn_mover()
	elif _audio.playing and _movers.is_empty():
		_audio.stop()
	var length := (_to_pos - _from_pos).length() - 1.2
	for m in _movers.duplicate():
		m.t += delta * 0.55 / maxf(length, 0.1) * 2.0
		if float(m.t) >= 1.0:
			(m.node as Node3D).queue_free()
			_movers.erase(m)
		else:
			(m.node as Node3D).position.x = -length / 2.0 + float(m.t) * length


func _spawn_mover() -> void:
	var box := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.3, 0.24, 0.3)
	box.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.5, 0.4)
	mat.roughness = 0.8
	box.material_override = mat
	box.position = Vector3(-((_to_pos - _from_pos).length() - 1.2) / 2.0, 0.18, 0)
	_mover_root.add_child(box)
	_movers.append({"node": box, "t": 0.0})
