class_name CustomerAgent
extends PersonAgent
## Visible store customer: enters, browses the shelf, queues at checkout,
## purchases through the SAME RetailSim decision logic as background sim,
## reacts and leaves.

enum Phase { ENTER, BROWSE, QUEUE, PAY, LEAVE, GONE }

var store_id: String = ""
var archetype: Dictionary = {}
var phase: Phase = Phase.ENTER
var _phase_time := 0.0
var _wp: Dictionary = {}   # waypoints: entrance, shelf, checkout, exit
var _result: Dictionary = {}


static func create(p_store_id: String, wp: Dictionary) -> CustomerAgent:
	var node := CustomerAgent.new()
	node.store_id = p_store_id
	node._wp = wp
	node.archetype = RetailSim.pick_archetype(Game.state,
		str(Game.state.stores[p_store_id].district))
	node.walk_speed = randf_range(1.3, 1.9)
	return node


func _ready() -> void:
	build_visual(Color.from_hsv(randf(), 0.35, randf_range(0.35, 0.7)))
	set_title(str(archetype.get("name", "Customer")))
	global_position = _wp.entrance
	walk_to([_offset(_wp.shelf)])
	AudioService.play_sfx("doorbell", 0.1)


func _offset(p: Vector3) -> Vector3:
	return p + Vector3(randf_range(-0.7, 0.7), 0, randf_range(-0.4, 0.4))


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_phase_time += delta
	match phase:
		Phase.ENTER:
			if at_destination():
				_set_phase(Phase.BROWSE)
		Phase.BROWSE:
			# Browse for a few seconds, glancing along the shelf.
			if _phase_time > randf_range(2.5, 5.0):
				walk_to([_offset(_wp.checkout)])
				_set_phase(Phase.QUEUE)
		Phase.QUEUE:
			if at_destination():
				_set_phase(Phase.PAY)
		Phase.PAY:
			var patience := 4.0 + float(archetype.get("queue_tolerance", 0.5)) * 8.0
			var checkout: CheckoutNode = _wp.get("checkout_node")
			var player: Player = get_tree().current_scene.get("player")
			if checkout != null and checkout.is_staffed(player):
				_result = RetailSim.decide_and_buy(Game.state, store_id, archetype, true)
				if bool(_result.get("bought", false)):
					AudioService.play_sfx("purchase")
					say(["Exactly what I wanted!", "Thanks!", "Great store.",
						"I trust this brand."].pick_random())
				else:
					say(str(_result.get("feedback", "Nothing for me today.")))
				_leave()
			elif _phase_time > patience:
				say("No one at the register?!")
				RetailSim._after_visit(Game.state, Game.state.stores[store_id],
					false, "No one at the register!")
				_leave()
		Phase.LEAVE:
			if at_destination():
				phase = Phase.GONE
				queue_free()
		_:
			pass


func _set_phase(p: Phase) -> void:
	phase = p
	_phase_time = 0.0


func _leave() -> void:
	walk_to([_wp.entrance, _wp.exit])
	_set_phase(Phase.LEAVE)
