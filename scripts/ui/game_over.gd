extends Control
## Failure screen: explains why the company failed and offers recovery paths.


func _ready() -> void:
	theme = UIKit.theme()
	AudioService.play_sfx("defeat")
	AudioService.play_music("music_menu")
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.06, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := UIKit.vbox(12)
	center.add_child(v)
	var r: Dictionary = Game.state.campaign_result
	var title := UIKit.title("LICENSE REVOKED", 44)
	title.add_theme_color_override("font_color", UIKit.ERR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	v.add_child(UIKit.label(str(r.get("reason", "The company failed.")), UIKit.TEXT, 17))
	v.add_child(UIKit.separator())
	var summary: Dictionary = r.get("summary", {})
	var g := UIKit.grid(2)
	v.add_child(g)
	for row: Array in [
		["Days survived", str(int(r.get("day", 0)))],
		["Final valuation", UIKit.money(float(summary.get("valuation", 0)))],
		["Cash", UIKit.money(float(summary.get("cash", 0)))],
		["Total revenue", UIKit.money(float(summary.get("revenue", 0)))],
		["Units sold", str(int(summary.get("units_sold", 0)))],
		["Profitable stores", str(int(summary.get("stores", 0)))],
		["Automation", "%.0f%%" % float(summary.get("automation", 0))],
	]:
		g.add_child(UIKit.label(str(row[0]) + ":", UIKit.TEXT_DIM))
		g.add_child(UIKit.label(str(row[1])))
	v.add_child(UIKit.separator())
	var actions := UIKit.hbox(10)
	v.add_child(actions)
	actions.add_child(UIKit.button("Load Save", func():
		var dlg := load("res://scripts/ui/save_load_dialog.gd").new()
		dlg.mode = "load"
		add_child(dlg)))
	actions.add_child(UIKit.button("Restart Campaign", func(): SceneRouter.goto("company_setup")))
	actions.add_child(UIKit.button("Main Menu", func(): SceneRouter.goto("main_menu")))
	actions.add_child(UIKit.button("Quit", func(): get_tree().quit()))
