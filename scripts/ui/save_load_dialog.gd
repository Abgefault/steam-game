extends PanelContainer
## Save/Load dialog with 5 manual slots + autosave/quicksave metadata.

var mode: String = "save"   # save | load


func _ready() -> void:
	theme = UIKit.theme()
	UIKit.center_popup(self)
	custom_minimum_size = Vector2(560, 380)
	_render()


func _render() -> void:
	for c in get_children():
		c.queue_free()
	var v := UIKit.vbox(8)
	add_child(v)
	v.add_child(UIKit.title("Save Game" if mode == "save" else "Load Game"))
	var slots: Array[String] = []
	for i in SaveService.MANUAL_SLOTS:
		slots.append("slot%d" % (i + 1))
	if mode == "load":
		slots.append("autosave")
		slots.append("quicksave")
	for slot in slots:
		var meta := SaveService.read_metadata(slot)
		var row := UIKit.hbox(10)
		v.add_child(row)
		var desc := "(empty)"
		if meta.has("corrupt"):
			desc = "(corrupt save)"
		elif not meta.is_empty():
			desc = "%s — Day %d — %s — %s — %s" % [str(meta.get("company", "?")),
				int(meta.get("day", 0)), UIKit.money(float(meta.get("cash", 0))),
				str(meta.get("stage_name", "")), str(meta.get("date", ""))]
		var lbl := UIKit.label("%s: %s" % [slot.capitalize(), desc],
			UIKit.TEXT if not meta.is_empty() else UIKit.TEXT_DIM, 14)
		lbl.custom_minimum_size.x = 380
		row.add_child(lbl)
		if mode == "save":
			row.add_child(UIKit.button("Save", func():
				if meta.is_empty():
					SaveService.save_game(slot)
					_render()
				else:
					UIKit.confirm(self, "Overwrite %s?" % slot, func():
						SaveService.save_game(slot)
						_render())))
		elif not meta.is_empty() and not meta.has("corrupt"):
			row.add_child(UIKit.button("Load", func():
				if SaveService.load_game(slot):
					SceneRouter.start_loaded_game()))
			row.add_child(UIKit.button("Delete", func():
				UIKit.confirm(self, "Delete %s?" % slot, func():
					SaveService.delete_save(slot)
					_render())))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.button("Close", queue_free))
