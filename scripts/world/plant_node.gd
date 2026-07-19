class_name PlantNode
extends Node3D
## A stylized potted plant built from crossed leaf-sprite quads. Growth is
## driven externally (0..1) so farm rows can mirror cultivation progress.
## Purely decorative/abstract — no real-world cultivation detail exists.

static var _leaf_mat: StandardMaterial3D = null

var _leaf_root: Node3D
var _sway_phase := 0.0


static func leaf_material() -> StandardMaterial3D:
	if _leaf_mat != null:
		return _leaf_mat
	var m := StandardMaterial3D.new()
	m.albedo_texture = load("res://assets/textures/plant/leaf.png")
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.4
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.85
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_leaf_mat = m
	return m


static func create(with_pot: bool = true) -> PlantNode:
	var node := PlantNode.new()
	node._sway_phase = randf() * TAU
	if with_pot:
		var pot := MeshInstance3D.new()
		var pot_mesh := CylinderMesh.new()
		pot_mesh.top_radius = 0.16
		pot_mesh.bottom_radius = 0.12
		pot_mesh.height = 0.22
		pot.mesh = pot_mesh
		pot.position.y = 0.11
		pot.material_override = MaterialLib.pbr("Metal030", 1.5, Color(0.5, 0.52, 0.55), false, 0.2)
		node.add_child(pot)
		var soil := MeshInstance3D.new()
		var soil_mesh := CylinderMesh.new()
		soil_mesh.top_radius = 0.14
		soil_mesh.bottom_radius = 0.14
		soil_mesh.height = 0.03
		soil.mesh = soil_mesh
		soil.position.y = 0.22
		soil.material_override = MaterialLib.pbr("Concrete034", 2.0, Color(0.25, 0.19, 0.14), false)
		node.add_child(soil)
	node._leaf_root = Node3D.new()
	node._leaf_root.position.y = 0.22 if with_pot else 0.0
	node.add_child(node._leaf_root)
	# Stem.
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.012
	stem_mesh.bottom_radius = 0.02
	stem_mesh.height = 0.5
	stem.mesh = stem_mesh
	stem.position.y = 0.25
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.24, 0.4, 0.22)
	stem_mat.roughness = 0.9
	stem.material_override = stem_mat
	node._leaf_root.add_child(stem)
	# Leaf fans at three heights, each 3 crossed quads.
	for level in 3:
		var y := 0.18 + level * 0.16
		var s := 0.55 - level * 0.12
		for i in 3:
			var quad := MeshInstance3D.new()
			var qm := QuadMesh.new()
			qm.size = Vector2(s, s)
			quad.mesh = qm
			quad.material_override = leaf_material()
			quad.position.y = y
			quad.rotation_degrees = Vector3(
				randf_range(-24.0, -8.0), i * 60.0 + randf_range(-15.0, 15.0), 0)
			node._leaf_root.add_child(quad)
	node.set_growth(1.0)
	return node


## 0 = seedling, 1 = full size. Slight per-plant variance keeps rows organic.
func set_growth(t: float) -> void:
	var s := clampf(0.15 + 0.85 * t, 0.15, 1.0) * randf_range(0.96, 1.04)
	_leaf_root.scale = Vector3(s, s, s)


func _process(delta: float) -> void:
	# Subtle ventilation sway; respects reduced-motion.
	if bool(SettingsService.get_v("reduced_motion")):
		return
	_sway_phase += delta * 0.9
	_leaf_root.rotation.z = sin(_sway_phase) * 0.02
