class_name PersonAgent
extends CharacterBody3D
## Base for simple visible people (customers, employees): capsule body,
## head, waypoint walking, name/feedback label.

var walk_speed := 1.7
var _path: Array[Vector3] = []
var _label: Label3D
var _bubble: Label3D
var _bubble_timer := 0.0


## Builds a clothed human figure (pants, shirt, arms, head, hair) onto any
## parent node. Reused by store/staff agents and by roaming city pedestrians.
static func build_figure(parent: Node3D, body_color: Color, height: float = 1.7) -> void:
	# Pants (lower body).
	var pants := MeshInstance3D.new()
	var pants_mesh := CylinderMesh.new()
	pants_mesh.top_radius = 0.21
	pants_mesh.bottom_radius = 0.17
	pants_mesh.height = height * 0.42
	pants.mesh = pants_mesh
	pants.position.y = height * 0.24
	var pants_mat := StandardMaterial3D.new()
	pants_mat.albedo_color = [Color(0.16, 0.17, 0.2), Color(0.22, 0.2, 0.18),
		Color(0.15, 0.2, 0.26)].pick_random()
	pants_mat.roughness = 0.95
	pants.material_override = pants_mat
	parent.add_child(pants)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.24
	capsule.height = height * 0.62
	body.mesh = capsule
	body.position.y = height * 0.62
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.9
	body.material_override = mat
	parent.add_child(body)
	var arm_mesh := CapsuleMesh.new()
	arm_mesh.radius = 0.055
	arm_mesh.height = height * 0.42
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 0.29, height * 0.62, 0)
		arm.rotation_degrees.z = side * -8.0
		arm.material_override = mat
		parent.add_child(arm)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	head.mesh = sphere
	head.position.y = height - 0.04
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.87, 0.72, 0.6).lerp(Color(0.42, 0.3, 0.22), randf())
	skin.roughness = 0.95
	head.material_override = skin
	parent.add_child(head)
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.155
	hair_mesh.height = 0.2
	hair.mesh = hair_mesh
	hair.position.y = height + 0.05
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = [Color(0.12, 0.1, 0.08), Color(0.3, 0.2, 0.1),
		Color(0.5, 0.42, 0.3), Color(0.25, 0.25, 0.28), Color(0.55, 0.3, 0.15)].pick_random()
	hair_mat.roughness = 0.95
	hair.material_override = hair_mat
	parent.add_child(hair)


func build_visual(body_color: Color, height: float = 1.7) -> void:
	# Pants (lower body).
	var pants := MeshInstance3D.new()
	var pants_mesh := CylinderMesh.new()
	pants_mesh.top_radius = 0.21
	pants_mesh.bottom_radius = 0.17
	pants_mesh.height = height * 0.42
	pants.mesh = pants_mesh
	pants.position.y = height * 0.24
	var pants_mat := StandardMaterial3D.new()
	pants_mat.albedo_color = [Color(0.16, 0.17, 0.2), Color(0.22, 0.2, 0.18),
		Color(0.15, 0.2, 0.26)].pick_random()
	pants_mat.roughness = 0.95
	pants.material_override = pants_mat
	add_child(pants)
	# Shirt/torso.
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.24
	capsule.height = height * 0.62
	body.mesh = capsule
	body.position.y = height * 0.62
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.9
	body.material_override = mat
	add_child(body)
	# Arms.
	var arm_mesh := CapsuleMesh.new()
	arm_mesh.radius = 0.055
	arm_mesh.height = height * 0.42
	for side in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.mesh = arm_mesh
		arm.position = Vector3(side * 0.29, height * 0.62, 0)
		arm.rotation_degrees.z = side * -8.0
		arm.material_override = mat
		add_child(arm)
	# Head + hair.
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	head.mesh = sphere
	head.position.y = height - 0.04
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.87, 0.72, 0.6).lerp(Color(0.42, 0.3, 0.22), randf())
	skin.roughness = 0.95
	head.material_override = skin
	add_child(head)
	var hair := MeshInstance3D.new()
	var hair_mesh := SphereMesh.new()
	hair_mesh.radius = 0.155
	hair_mesh.height = 0.2
	hair.mesh = hair_mesh
	hair.position.y = height + 0.05
	var hair_mat := StandardMaterial3D.new()
	hair_mat.albedo_color = [Color(0.12, 0.1, 0.08), Color(0.3, 0.2, 0.1),
		Color(0.5, 0.42, 0.3), Color(0.25, 0.25, 0.28), Color(0.55, 0.3, 0.15)].pick_random()
	hair_mat.roughness = 0.95
	hair.material_override = hair_mat
	add_child(hair)
	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.26
	shape.height = height - 0.2
	col.shape = shape
	col.position.y = height / 2.0
	add_child(col)
	collision_layer = 4
	collision_mask = 1
	_label = Label3D.new()
	_label.position.y = height + 0.25
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 34
	_label.pixel_size = 0.004
	_label.outline_size = 8
	add_child(_label)
	_bubble = Label3D.new()
	_bubble.position.y = height + 0.55
	_bubble.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_bubble.font_size = 38
	_bubble.pixel_size = 0.0042
	_bubble.outline_size = 10
	_bubble.modulate = Color(1, 1, 0.85)
	add_child(_bubble)


func set_title(text: String) -> void:
	if _label != null:
		_label.text = text


func say(text: String, seconds: float = 3.0) -> void:
	if _bubble == null:
		return
	_bubble.text = "“%s”" % text
	_bubble_timer = seconds


func walk_to(points: Array[Vector3]) -> void:
	_path = points.duplicate()


func at_destination() -> bool:
	return _path.is_empty()


func _physics_process(delta: float) -> void:
	if _bubble_timer > 0.0:
		_bubble_timer -= delta
		if _bubble_timer <= 0.0:
			_bubble.text = ""
	if _path.is_empty():
		velocity = Vector3.ZERO
		return
	var target := _path[0]
	var flat := Vector3(target.x - global_position.x, 0, target.z - global_position.z)
	if flat.length() < 0.25:
		_path.pop_front()
		return
	var dir := flat.normalized()
	velocity = dir * walk_speed
	if not is_on_floor():
		velocity.y = -3.0
	move_and_slide()
	var yaw := atan2(-dir.x, -dir.z)
	rotation.y = lerp_angle(rotation.y, yaw, 8.0 * delta)
