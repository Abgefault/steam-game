class_name EmployeeAgent
extends PersonAgent
## Visible employee. The actual work is simulated in StaffSim; this agent
## walks believable routes between work anchors matching its role.

var emp_id: int = 0
var _anchors: Array[Vector3] = []
var _idle_time := 0.0


static func create(emp: Dictionary, anchors: Array[Vector3]) -> EmployeeAgent:
	var node := EmployeeAgent.new()
	node.emp_id = int(emp.id)
	node._anchors = anchors
	node.walk_speed = 1.6
	return node


func _ready() -> void:
	var emp := _emp()
	# Uniform color by role.
	var role_colors := {
		"sales": Color(0.24, 0.5, 0.36), "store_manager": Color(0.2, 0.42, 0.3),
		"production": Color(0.35, 0.38, 0.42), "logistics": Color(0.55, 0.42, 0.2),
		"maintenance": Color(0.5, 0.3, 0.2), "quality": Color(0.8, 0.82, 0.85),
		"marketing": Color(0.45, 0.3, 0.5), "compliance": Color(0.25, 0.3, 0.45),
	}
	build_visual(role_colors.get(str(emp.get("role", "production")), Color(0.4, 0.4, 0.4)))
	set_title(str(emp.get("name", "Employee")))
	if not _anchors.is_empty():
		global_position = _anchors[0]


func _emp() -> Dictionary:
	for e: Dictionary in Game.state.staff:
		if int(e.id) == emp_id:
			return e
	return {}


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if _emp().is_empty():
		queue_free()
		return
	if at_destination():
		_idle_time += delta
		if _idle_time > randf_range(3.0, 7.0) and not _anchors.is_empty():
			_idle_time = 0.0
			var target: Vector3 = _anchors.pick_random()
			walk_to([target + Vector3(randf_range(-0.8, 0.8), 0, randf_range(-0.8, 0.8))])
