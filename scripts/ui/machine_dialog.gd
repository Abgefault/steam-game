extends PanelContainer
## Context dialog for operating a machine: start with chosen inputs,
## select product recipes, upgrade tier, repair, toggle auto-feed.

var machine_id: String = ""


func _ready() -> void:
	theme = UIKit.theme()
	UIKit.center_popup(self)
	custom_minimum_size = Vector2(520, 300)
	var m: Dictionary = Game.state.machines.get(machine_id, {})
	if m.is_empty():
		queue_free()
		return
	var v := UIKit.vbox(10)
	add_child(v)
	v.add_child(UIKit.title("%s — Tier %d" % [MachineSim.display_name(m), int(m.tier)]))
	var info: Dictionary = MachineSim.tier_info(m)
	v.add_child(UIKit.label(str(info.get("desc", "")), UIKit.TEXT_DIM))
	v.add_child(UIKit.label("Condition: %.0f%%   State: %s" % [float(m.condition), str(m.state).to_upper()]))
	v.add_child(UIKit.separator())
	match str(m.def_id):
		"cultivation":
			v.add_child(UIKit.label("Start a cultivation run (1 seed kit → harvest containers):"))
			var row := UIKit.hbox()
			v.add_child(row)
			for sid: String in DataRegistry.strains.keys():
				var strain: Dictionary = DataRegistry.strains[sid]
				row.add_child(UIKit.button(str(strain.name), func():
					if MachineSim.load_and_start(Game.state, machine_id, {"strain_id": sid}):
						queue_free(),
					"Yield %d, %d min" % [int(strain.get("yield", 3)), int(strain.get("grow_minutes", 240))]))
			v.add_child(UIKit.label("Seed kits in stock: %d" % int(Game.state.supplies.seed_units), UIKit.TEXT_DIM))
		"product":
			v.add_child(UIKit.label("Select a recipe to produce:"))
			var scroll := ScrollContainer.new()
			scroll.custom_minimum_size = Vector2(480, 220)
			v.add_child(scroll)
			var list := UIKit.vbox(4)
			scroll.add_child(list)
			for pid: String in DataRegistry.products.keys():
				var p: Dictionary = DataRegistry.products[pid]
				if int(p.stage_required) > int(Game.state.stage):
					continue
				var need := int(ceilf(float(p.batch_size) / 2.0))
				var have := int(Game.state.processed.get(str(p.strain), 0))
				var row2 := UIKit.hbox()
				list.add_child(row2)
				var b := UIKit.button("%s  (needs %d refined %s, have %d)" % [str(p.name), need,
					str(DataRegistry.strains[str(p.strain)].name), have], func():
					Game.state.machines[machine_id]["recipe"] = pid
					if MachineSim.load_and_start(Game.state, machine_id, {"product_id": pid}):
						queue_free())
				b.disabled = have < need or int(m.tier) < int(p.get("machine_tier", 1))
				row2.add_child(b)
		_:
			var blocker := MachineSim.load_blocker(Game.state, machine_id, {})
			if blocker == "":
				v.add_child(UIKit.button("Load & start", func():
					if MachineSim.load_and_start(Game.state, machine_id, {}):
						queue_free()))
			else:
				v.add_child(UIKit.label(blocker, UIKit.WARN))
	v.add_child(UIKit.separator())
	var actions := UIKit.hbox()
	v.add_child(actions)
	var up_cost := MachineSim.upgrade_cost(m)
	if up_cost >= 0.0:
		actions.add_child(UIKit.button("Upgrade to Tier %d (%s)" % [int(m.tier) + 1, UIKit.money(up_cost)],
			func():
				MachineSim.upgrade(Game.state, machine_id)
				queue_free()))
	if float(m.condition) < 80.0:
		actions.add_child(UIKit.button("Maintain (1 spare part)", func():
			MachineSim.repair(Game.state, machine_id)
			queue_free()))
	if Game.has_research("robotic_arms"):
		var auto_btn := CheckBox.new()
		auto_btn.text = "Auto-feed (robotic arm)"
		auto_btn.button_pressed = bool(m.get("auto_feed", false))
		auto_btn.toggled.connect(func(on: bool): Game.state.machines[machine_id]["auto_feed"] = on)
		actions.add_child(auto_btn)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(spacer)
	actions.add_child(UIKit.button("Close", queue_free))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu") or event.is_action_pressed("interact"):
		queue_free()
		get_viewport().set_input_as_handled()
