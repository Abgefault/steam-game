extends PanelContainer
## In-game pause menu: continue, save/load, settings, main menu, quit.


func _ready() -> void:
	theme = UIKit.theme()
	UIKit.center_popup(self)
	custom_minimum_size = Vector2(340, 300)
	var v := UIKit.vbox(8)
	add_child(v)
	v.add_child(UIKit.title("Paused"))
	v.add_child(UIKit.button("Continue", queue_free))
	v.add_child(UIKit.button("Save game", func():
		var dlg: Control = load("res://scripts/ui/save_load_dialog.gd").new()
		dlg.mode = "save"
		get_parent().add_child(dlg)))
	v.add_child(UIKit.button("Load game", func():
		var dlg: Control = load("res://scripts/ui/save_load_dialog.gd").new()
		dlg.mode = "load"
		get_parent().add_child(dlg)))
	v.add_child(UIKit.button("Settings", func():
		get_parent().add_child(load("res://scripts/ui/settings_panel.gd").new())))
	if OS.is_debug_build():
		v.add_child(UIKit.button("Developer panel", func():
			get_parent().add_child(load("res://scripts/ui/debug_panel.gd").new())))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.button("Save & exit to main menu", func():
		SaveService.autosave()
		SceneRouter.goto("main_menu")))
	v.add_child(UIKit.button("Quit game", func():
		UIKit.confirm(self, "Quit to desktop? Unsaved progress is lost.", func():
			get_tree().quit())))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		queue_free()
		get_viewport().set_input_as_handled()
