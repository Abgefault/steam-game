extends Control
## New-game company setup: name, logo, brand colors, brand personality.

const LOGOS := ["Leaf & Gear", "Comet Tin", "Hex Garden", "Signal Sprout"]
const PERSONALITIES := {
	"Affordable": "Slightly better margins on budget products.",
	"Premium": "Premium customers respond better to your brand.",
	"Wellness": "Wellness products gain extra appeal.",
	"Bold": "Trend swings hit you harder — both ways.",
}
const COLOR_CHOICES := ["3fa34d", "2e7dd1", "d1892e", "8e44ad", "c0392b", "16a085"]

var _name_edit: LineEdit
var _brand: String = "Affordable"
var _color_primary: String = "3fa34d"
var _color_secondary: String = "1f2d24"
var _logo: int = 0
var _brand_buttons: Dictionary = {}
var _color_buttons: Dictionary = {}
var _logo_buttons: Dictionary = {}


func _ready() -> void:
	theme = UIKit.theme()
	var bg := ColorRect.new()
	bg.color = UIKit.BG
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var v := UIKit.vbox(12)
	center.add_child(v)
	v.add_child(UIKit.title("Found Your Company", 32))
	v.add_child(UIKit.label("You inherit a nearly bankrupt licensed operation in Verdantia's Old Market.\nWin the exclusive city supply contract within 180 days.", UIKit.TEXT_DIM))
	v.add_child(UIKit.separator())
	var name_row := UIKit.hbox(10)
	v.add_child(name_row)
	name_row.add_child(UIKit.label("Company name:"))
	_name_edit = LineEdit.new()
	_name_edit.text = "Green Empire"
	_name_edit.custom_minimum_size.x = 280
	_name_edit.max_length = 28
	name_row.add_child(_name_edit)
	# Logo pick.
	var logo_row := UIKit.hbox(8)
	v.add_child(logo_row)
	logo_row.add_child(UIKit.label("Logo:"))
	for i in LOGOS.size():
		var b := UIKit.button(LOGOS[i], func():
			_logo = i
			_refresh())
		_logo_buttons[i] = b
		logo_row.add_child(b)
	# Brand colors.
	var color_row := UIKit.hbox(8)
	v.add_child(color_row)
	color_row.add_child(UIKit.label("Primary color:"))
	for c in COLOR_CHOICES:
		var b := Button.new()
		b.custom_minimum_size = Vector2(36, 28)
		var style := StyleBoxFlat.new()
		style.bg_color = Color.html(c)
		style.corner_radius_top_left = 4
		style.corner_radius_top_right = 4
		style.corner_radius_bottom_left = 4
		style.corner_radius_bottom_right = 4
		b.add_theme_stylebox_override("normal", style)
		b.add_theme_stylebox_override("hover", style)
		b.add_theme_stylebox_override("pressed", style)
		b.pressed.connect(func():
			_color_primary = c
			_refresh())
		_color_buttons[c] = b
		color_row.add_child(b)
	# Personality.
	v.add_child(UIKit.label("Brand personality:"))
	var pers_row := UIKit.hbox(8)
	v.add_child(pers_row)
	for p: String in PERSONALITIES.keys():
		var b := UIKit.button(p, func():
			_brand = p
			_refresh(), str(PERSONALITIES[p]))
		_brand_buttons[p] = b
		pers_row.add_child(b)
	v.add_child(UIKit.separator())
	var actions := UIKit.hbox(10)
	v.add_child(actions)
	actions.add_child(UIKit.button("START — Day 1 in Verdantia", _start))
	actions.add_child(UIKit.button("Back", func(): SceneRouter.goto("main_menu")))
	_refresh()


func _refresh() -> void:
	for i: int in _logo_buttons.keys():
		(_logo_buttons[i] as Button).modulate = Color(1, 1, 0.7) if i == _logo else Color(0.7, 0.7, 0.7)
	for p: String in _brand_buttons.keys():
		(_brand_buttons[p] as Button).modulate = Color(1, 1, 0.7) if p == _brand else Color(0.7, 0.7, 0.7)
	for c: String in _color_buttons.keys():
		(_color_buttons[c] as Button).modulate = Color(1, 1, 1) if c == _color_primary else Color(0.55, 0.55, 0.55)


func _start() -> void:
	var company_name := _name_edit.text.strip_edges()
	if company_name.is_empty():
		company_name = "Green Empire"
	Game.start_new_game(company_name, _brand, _color_primary, _color_secondary, _logo)
	SceneRouter.goto("facility")
