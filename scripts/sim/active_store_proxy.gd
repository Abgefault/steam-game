class_name ActiveStoreProxy
## Bridge between the retail simulation and the 3D world. The world
## registers which store the player can currently see; arrival events for
## that store spawn visible customer agents instead of resolving instantly.

static var active_store_id: String = ""
static var spawn_callback: Callable = Callable()


static func request_visible_customer(store_id: String) -> void:
	if spawn_callback.is_valid():
		spawn_callback.call(store_id)
	else:
		# No world attached (headless/background): resolve instantly.
		var archetype := RetailSim.pick_archetype(Game.state,
			str(Game.state.stores[store_id].district))
		RetailSim.decide_and_buy(Game.state, store_id, archetype, true)
