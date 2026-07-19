extends Control
## Credits screen.


func _ready() -> void:
	theme = UIKit.theme()
	var bg := ColorRect.new()
	bg.color = UIKit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := UIKit.vbox(10)
	center.add_child(v)
	var title := UIKit.title("GREEN EMPIRE", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	for line in [
		"Industrial Cannabis Tycoon",
		"",
		"A fictional business simulation.",
		"All products, processes, districts and regulations are invented.",
		"",
		"Design, code, art direction & audio synthesis:",
		"The Green Empire development team",
		"",
		"Built with Godot Engine 4 (godotengine.org, MIT license)",
		"All audio procedurally synthesized in-house.",
		"PBR textures: ambientCG.com (CC0 public domain).",
	]:
		var l := UIKit.label(line, UIKit.TEXT_DIM if line != "Industrial Cannabis Tycoon" else UIKit.TEXT)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	v.add_child(UIKit.separator())
	var b := UIKit.button("Back", func(): SceneRouter.goto("main_menu"))
	v.add_child(b)
