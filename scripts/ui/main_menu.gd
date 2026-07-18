extends Control
## Main menu: New Game, Continue, Load, Settings, Credits, Quit.


func _ready() -> void:
	theme = UIKit.theme()
	AudioService.play_music("music_menu")
	AudioService.play_ambience("")
	var bg := ColorRect.new()
	bg.color = UIKit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := UIKit.vbox(10)
	center.add_child(v)
	var title := UIKit.title("GREEN EMPIRE", 52)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var sub := UIKit.label("INDUSTRIAL CANNABIS TYCOON", UIKit.TEXT_DIM, 18)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)
	var note := UIKit.label("A fictional business simulation set in the city of Verdantia.", UIKit.TEXT_DIM, 13)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(note)
	v.add_child(UIKit.separator())
	var buttons := UIKit.vbox(6)
	v.add_child(buttons)
	buttons.add_child(_menu_button("New Game", func(): SceneRouter.goto("company_setup")))
	var has_auto := not SaveService.read_metadata("autosave").is_empty()
	if has_auto:
		buttons.add_child(_menu_button("Continue (autosave)", func():
			if SaveService.load_game("autosave"):
				SceneRouter.start_loaded_game()))
	buttons.add_child(_menu_button("Load Game", func():
		var dlg := load("res://scripts/ui/save_load_dialog.gd").new()
		dlg.mode = "load"
		add_child(dlg)))
	buttons.add_child(_menu_button("Settings", func():
		add_child(load("res://scripts/ui/settings_panel.gd").new())))
	buttons.add_child(_menu_button("Credits", func(): SceneRouter.goto("credits")))
	buttons.add_child(_menu_button("Quit", func(): get_tree().quit()))
	var version := UIKit.label("v%s" % str(ProjectSettings.get_setting("application/config/version")),
		UIKit.TEXT_DIM, 12)
	version.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version.position -= Vector2(60, 30)
	add_child(version)


func _menu_button(text: String, cb: Callable) -> Button:
	var b := UIKit.button(text, cb)
	b.custom_minimum_size = Vector2(280, 42)
	return b
