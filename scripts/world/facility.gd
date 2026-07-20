extends Node3D
## Root of the playable 3D facility. Builds the world, spawns the player,
## machines, store fixtures and agents, hosts the HUD/tablet UI layer and
## bridges visible gameplay to the authoritative simulation.

var player: Player
var anchors: Dictionary = {}
var hud: CanvasLayer
var _conveyor_root: Node3D
var _agents_root: Node3D
var _customer_count := 0


func _ready() -> void:
	if not Game.in_session:
		# Direct scene run in editor: create a session for testing.
		Game.start_new_game("Dev Co", "Affordable", "3fa34d", "1f2d24", 0)
	anchors = FacilityBuilder.build(self)
	_conveyor_root = Node3D.new()
	add_child(_conveyor_root)
	_agents_root = Node3D.new()
	add_child(_agents_root)
	# Machines.
	for machine_id: String in Game.state.machines.keys():
		var pos: Vector3 = FacilityBuilder.machine_positions.get(machine_id,
			Vector3(-2, 0, -3))
		var node := MachineNode.create(machine_id)
		node.position = pos
		add_child(node)
	# The visible cultivation farm (plants mirror the machine's progress).
	var farm := FarmZone.new()
	farm.position = Vector3(-11.6, 0, -6.0)
	farm.rotation_degrees.y = 90
	add_child(farm)
	# Living city: moving traffic and pedestrians.
	add_child(CityLife.new())
	# Store fixtures.
	var shelf := ShelfNode.create("store_old_market")
	shelf.position = Vector3(6.0, 0, 3.0)
	add_child(shelf)
	var shelf2 := ShelfNode.create("store_old_market")
	shelf2.position = Vector3(9.5, 0, 3.0)
	add_child(shelf2)
	var checkout := CheckoutNode.create("store_old_market")
	checkout.position = Vector3(3.5, 0, 4.8)
	checkout.rotation_degrees.y = 90
	add_child(checkout)
	anchors["checkout_node"] = checkout
	# Warehouse racks.
	for i in 2:
		var rack := RackNode.create()
		rack.position = Vector3(5.5 + i * 4.5, 0, -8.0)
		add_child(rack)
	# Player.
	player = Player.new()
	var col := CollisionShape3D.new()
	col.name = "Collider"
	var shape := CapsuleShape3D.new()
	shape.radius = 0.32
	shape.height = 1.75
	col.shape = shape
	col.position.y = 0.9
	player.add_child(col)
	player.position = anchors.player_spawn
	add_child(player)
	# UI layer.
	hud = load("res://scenes/HUD.tscn").instantiate()
	add_child(hud)
	# Wire visible-customer spawning for the active store.
	ActiveStoreProxy.active_store_id = "store_old_market"
	ActiveStoreProxy.spawn_callback = _spawn_customer
	# Signals.
	EventBus.stage_advanced.connect(_on_stage)
	EventBus.employee_hired.connect(func(_e): _refresh_employees())
	EventBus.employee_quit.connect(func(_e): _refresh_employees())
	EventBus.research_completed.connect(func(_d): _rebuild_conveyors())
	FacilityBuilder.apply_stage(self, int(Game.state.stage))
	_rebuild_conveyors()
	_refresh_employees()
	# Clock + audio.
	SimClock.start_campaign_clock()
	AudioService.play_music("music_calm")
	AudioService.play_ambience("amb_workshop")
	EventBus.day_started.connect(func(_d): AudioService.play_music(
		"music_tension" if CampaignSim.days_remaining(Game.state) < 40 else "music_calm"))


func _exit_tree() -> void:
	ActiveStoreProxy.spawn_callback = Callable()
	ActiveStoreProxy.active_store_id = ""


func _process(_delta: float) -> void:
	if Game.in_session:
		Game.state.playtime_seconds = float(Game.state.playtime_seconds) + _delta


# ------------------------------------------------------------- world hooks

func spawn_container(container: ContainerNode, pos: Vector3) -> void:
	container.position = Vector3(pos.x, 0, pos.z)
	add_child(container)


func open_machine_dialog(machine_id: String) -> void:
	hud.call("open_machine_dialog", machine_id)


func _spawn_customer(store_id: String) -> void:
	if _customer_count >= 10:
		# Bounded agent count: resolve overflow arrivals instantly.
		var archetype := RetailSim.pick_archetype(Game.state,
			str(Game.state.stores[store_id].district))
		RetailSim.decide_and_buy(Game.state, store_id, archetype, true)
		return
	var c := CustomerAgent.create(store_id, {
		"entrance": anchors.entrance, "shelf": anchors.shelf,
		"checkout": anchors.checkout, "exit": anchors.exit,
		"checkout_node": anchors.checkout_node,
	})
	_customer_count += 1
	c.tree_exited.connect(func(): _customer_count = maxi(0, _customer_count - 1))
	_agents_root.add_child(c)


func _refresh_employees() -> void:
	for child in _agents_root.get_children():
		if child is EmployeeAgent:
			child.queue_free()
	for e: Dictionary in Game.state.staff:
		var role := str(e.role)
		var route: Array[Vector3] = []
		match role:
			"sales", "store_manager", "marketing":
				route.assign([anchors.checkout, anchors.shelf])
			"logistics":
				route.assign((anchors.warehouse as Array) + [anchors.shelf])
			"maintenance", "compliance":
				route.assign((anchors.production as Array) + (anchors.warehouse as Array))
			_:
				route.assign(anchors.production as Array)
		var agent := EmployeeAgent.create(e, route)
		_agents_root.add_child(agent)


func _rebuild_conveyors() -> void:
	for child in _conveyor_root.get_children():
		child.queue_free()
	for c: Dictionary in Game.state.conveyors:
		var from_pos: Vector3 = FacilityBuilder.machine_positions.get(str(c.from), Vector3.ZERO)
		var to_pos: Vector3 = FacilityBuilder.machine_positions.get(str(c.to), Vector3.ZERO)
		if from_pos == Vector3.ZERO and to_pos == Vector3.ZERO:
			continue
		_conveyor_root.add_child(ConveyorNode.create(str(c.from), str(c.to), from_pos, to_pos))


func rebuild_conveyors() -> void:
	_rebuild_conveyors()


func _on_stage(stage: int) -> void:
	FacilityBuilder.apply_stage(self, stage)
	AudioService.play_sfx("stage_up")
