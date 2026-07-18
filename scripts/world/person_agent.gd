class_name PersonAgent
extends CharacterBody3D
## Base for simple visible people (customers, employees): capsule body,
## head, waypoint walking, name/feedback label.

var walk_speed := 1.7
var _path: Array[Vector3] = []
var _label: Label3D
var _bubble: Label3D
var _bubble_timer := 0.0


func build_visual(body_color: Color, height: float = 1.7) -> void:
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.26
	capsule.height = height - 0.3
	body.mesh = capsule
	body.position.y = (height - 0.3) / 2.0 + 0.15
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.9
	body.material_override = mat
	add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.16
	sphere.height = 0.32
	head.mesh = sphere
	head.position.y = height - 0.05
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.85, 0.7, 0.58).lerp(Color(0.45, 0.32, 0.24), randf())
	skin.roughness = 0.95
	head.material_override = skin
	add_child(head)
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
