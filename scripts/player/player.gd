class_name Player
extends CharacterBody3D
## First-person controller: walk/sprint/crouch, mouse look, interaction
## raycast, carrying one container, optional head bob, surface footsteps.

const WALK_SPEED := 3.6
const SPRINT_SPEED := 6.0
const CROUCH_SPEED := 1.8
const JUMP_VELOCITY := 4.2
const REACH := 2.6

var camera: Camera3D
var _pitch := 0.0
var _bob_time := 0.0
var _footstep_accum := 0.0
var carried: Node3D = null            # ContainerNode being carried
var ui_locked: bool = false           # true while tablet/menus are open

@onready var _collider: CollisionShape3D = $Collider


func _ready() -> void:
	camera = Camera3D.new()
	camera.position = Vector3(0, 1.62, 0)
	camera.fov = float(SettingsService.get_v("fov"))
	add_child(camera)
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if ui_locked:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var sens := float(SettingsService.get_v("mouse_sensitivity")) * 0.006
		rotate_y(-event.relative.x * sens)
		var dy := event.relative.y * sens * (-1.0 if bool(SettingsService.get_v("invert_y")) else 1.0)
		_pitch = clampf(_pitch - dy, -1.5, 1.5)
		camera.rotation.x = _pitch
	elif event.is_action_pressed("interact"):
		_try_interact()
	elif event.is_action_pressed("drop_item"):
		drop_carried()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 9.8 * delta
	var speed := WALK_SPEED
	var crouching := Input.is_action_pressed("crouch") and not ui_locked
	if crouching:
		speed = CROUCH_SPEED
	elif Input.is_action_pressed("sprint") and not ui_locked:
		speed = SPRINT_SPEED
	camera.position.y = lerpf(camera.position.y, 1.1 if crouching else 1.62, 12.0 * delta)
	var input_dir := Vector2.ZERO
	if not ui_locked:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = JUMP_VELOCITY
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	move_and_slide()
	_head_bob(delta, direction.length() > 0.1 and is_on_floor(), speed)
	_footsteps(delta, direction.length() > 0.1 and is_on_floor(), speed)
	if carried != null:
		var target := camera.global_transform * Vector3(0.42, -0.42, -0.9)
		carried.global_position = carried.global_position.lerp(target, 18.0 * delta)
		carried.global_rotation = Vector3(0, global_rotation.y, 0)


func _head_bob(delta: float, moving: bool, speed: float) -> void:
	if not bool(SettingsService.get_v("head_bob")) or bool(SettingsService.get_v("reduced_motion")):
		return
	if moving:
		_bob_time += delta * speed * 1.8
		camera.position.x = sin(_bob_time) * 0.03
		camera.position.y += absf(cos(_bob_time)) * 0.035 - 0.017
	else:
		camera.position.x = lerpf(camera.position.x, 0.0, 8.0 * delta)


func _footsteps(delta: float, moving: bool, speed: float) -> void:
	if not moving:
		return
	_footstep_accum += delta * speed
	if _footstep_accum >= 2.6:
		_footstep_accum = 0.0
		var soft := global_position.z > 6.0   # storefront area has softer floor
		AudioService.play_sfx("footstep_%s_%d" % ["soft" if soft else "hard", 1 + randi() % 2], 0.15)


func current_target() -> Node:
	var from := camera.global_position
	var to := from + camera.global_transform.basis * Vector3(0, 0, -REACH)
	var query := PhysicsRayQueryParameters3D.create(from, to, 0xFFFFFFFF, [get_rid()])
	query.collide_with_areas = true
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return null
	var n: Node = hit.collider
	while n != null:
		if n.has_method("interact"):
			return n
		n = n.get_parent()
	return null


func _try_interact() -> void:
	var target := current_target()
	if target != null:
		target.call("interact", self)


func pick_up(container: Node3D) -> bool:
	if carried != null:
		EventBus.notify("Hands full — deposit or drop the container first (G).", "warning")
		return false
	carried = container
	if container.has_method("on_picked_up"):
		container.call("on_picked_up")
	AudioService.play_sfx("pickup")
	return true


func drop_carried() -> void:
	if carried == null:
		return
	var c := carried
	carried = null
	if c.has_method("on_dropped"):
		c.call("on_dropped")
	AudioService.play_sfx("putdown")


func consume_carried() -> void:
	if carried == null:
		return
	carried.queue_free()
	carried = null
	AudioService.play_sfx("putdown")
