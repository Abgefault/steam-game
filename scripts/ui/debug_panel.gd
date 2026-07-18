extends PanelContainer
## Debug-only developer panel. Never shown in release builds (guarded by
## OS.is_debug_build() at the call site and here).


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	theme = UIKit.theme()
	set_anchors_preset(Control.PRESET_CENTER_LEFT)
	position.x += 20
	custom_minimum_size = Vector2(300, 400)
	var v := UIKit.vbox(6)
	add_child(v)
	v.add_child(UIKit.title("Developer Panel", 17))
	v.add_child(UIKit.button("+$10,000", func(): EconomySim.earn(Game.state, 10000, "DEBUG")))
	v.add_child(UIKit.button("+$1,000,000", func(): EconomySim.earn(Game.state, 1000000, "DEBUG")))
	v.add_child(UIKit.button("+10 Research Points", func():
		Game.state.research_points = int(Game.state.research_points) + 10))
	v.add_child(UIKit.button("Advance 1 day", func(): SimClock.end_day_early()))
	v.add_child(UIKit.button("Reputation 85", func():
		Game.state.reputation = 85.0))
	v.add_child(UIKit.button("Compliance 95", func():
		Game.state.compliance = 95.0))
	v.add_child(UIKit.button("Automation 90%", func():
		Game.state.automation_score = 90.0))
	v.add_child(UIKit.button("Unlock all research", func():
		for id: String in DataRegistry.research.keys():
			if not Game.has_research(id):
				Game.state.research_done.append(id)
		Game.state.auto.purchasing = true
		Game.state.auto.restock = true
		Game.state.auto.maintenance = true
		Game.state.auto.scheduling = true
		Game.state.auto.reporting = true))
	v.add_child(UIKit.button("Complete running production", func():
		for m: Dictionary in Game.state.machines.values():
			if str(m.state) == "running":
				m.progress = float(m.duration)))
	v.add_child(UIKit.button("Spawn stocked warehouse", func():
		for pid: String in DataRegistry.products.keys():
			InventorySim.make_lot(Game.state, pid, 40, 2, true, "warehouse")))
	v.add_child(UIKit.button("Customer rush (×20)", func():
		for i in 20:
			ActiveStoreProxy.request_visible_customer("store_old_market")))
	v.add_child(UIKit.button("Damage random machine", func():
		var m: Dictionary = Game.state.machines.values().pick_random()
		m.condition = 10.0))
	v.add_child(UIKit.button("Trigger random event", func():
		EventsSim.fire_event(Game.state, DataRegistry.events.values().pick_random())))
	v.add_child(UIKit.button("Run audit now", func(): ComplianceSim.run_audit(Game.state)))
	v.add_child(UIKit.button("Start final trial (force)", func():
		Game.state.trial = {"active": true, "day": 1, "delivered": 0, "rejected": 0,
			"on_time": 0, "scheduled": 0, "quality_sum": 0, "profit": 0.0,
			"failed": false, "violations": 0, "start_cash": Game.cash()}
		EventBus.trial_started.emit()))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.button("Close", queue_free))
