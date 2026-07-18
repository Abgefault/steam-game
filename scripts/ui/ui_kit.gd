class_name UIKit
## Shared UI theme and widget factory so every screen looks consistent.

const BG := Color(0.075, 0.1, 0.085)
const PANEL := Color(0.11, 0.145, 0.125)
const PANEL_LIGHT := Color(0.15, 0.19, 0.165)
const ACCENT := Color(0.35, 0.75, 0.45)
const ACCENT_DIM := Color(0.24, 0.45, 0.3)
const TEXT := Color(0.88, 0.92, 0.88)
const TEXT_DIM := Color(0.6, 0.68, 0.62)
const WARN := Color(0.95, 0.75, 0.3)
const ERR := Color(0.9, 0.35, 0.3)
const OK := Color(0.45, 0.85, 0.5)

static var _theme: Theme = null


static func theme() -> Theme:
	if _theme != null:
		return _theme
	_theme = Theme.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = PANEL
	panel_style.corner_radius_top_left = 6
	panel_style.corner_radius_top_right = 6
	panel_style.corner_radius_bottom_left = 6
	panel_style.corner_radius_bottom_right = 6
	panel_style.content_margin_left = 12.0
	panel_style.content_margin_right = 12.0
	panel_style.content_margin_top = 10.0
	panel_style.content_margin_bottom = 10.0
	_theme.set_stylebox("panel", "PanelContainer", panel_style)
	var btn := StyleBoxFlat.new()
	btn.bg_color = ACCENT_DIM
	btn.corner_radius_top_left = 4
	btn.corner_radius_top_right = 4
	btn.corner_radius_bottom_left = 4
	btn.corner_radius_bottom_right = 4
	btn.content_margin_left = 12.0
	btn.content_margin_right = 12.0
	btn.content_margin_top = 6.0
	btn.content_margin_bottom = 6.0
	var btn_hover := btn.duplicate()
	btn_hover.bg_color = ACCENT_DIM.lightened(0.15)
	var btn_pressed := btn.duplicate()
	btn_pressed.bg_color = ACCENT
	var btn_disabled := btn.duplicate()
	btn_disabled.bg_color = Color(0.18, 0.2, 0.19)
	_theme.set_stylebox("normal", "Button", btn)
	_theme.set_stylebox("hover", "Button", btn_hover)
	_theme.set_stylebox("pressed", "Button", btn_pressed)
	_theme.set_stylebox("disabled", "Button", btn_disabled)
	_theme.set_stylebox("focus", "Button", btn_hover.duplicate())
	_theme.set_color("font_color", "Button", TEXT)
	_theme.set_color("font_hover_color", "Button", Color.WHITE)
	_theme.set_color("font_disabled_color", "Button", TEXT_DIM)
	_theme.set_color("font_color", "Label", TEXT)
	_theme.set_color("font_color", "CheckBox", TEXT)
	_theme.set_color("font_color", "LineEdit", TEXT)
	_theme.set_color("font_color", "OptionButton", TEXT)
	var scale := float(SettingsService.get_v("ui_scale")) if Engine.get_main_loop() != null else 1.0
	_theme.default_font_size = int(15 * clampf(scale, 0.8, 1.4))
	return _theme


static func title(text: String, size: int = 22) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", ACCENT)
	return l


## Autowrap is OFF by default so labels never collapse to one-char columns
## inside width-starved grids/HBoxes. Pass wrap=true for real paragraphs;
## those should also live in a width-constrained parent.
static func label(text: String, color: Color = TEXT, size: int = 15, wrap: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", size)
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 360
	return l


## A wrapping paragraph label with an explicit width.
static func paragraph(text: String, color: Color = TEXT_DIM, size: int = 14, width: float = 640.0) -> Label:
	var l := label(text, color, size, true)
	l.custom_minimum_size.x = width
	return l


static func button(text: String, cb: Callable, tooltip: String = "") -> Button:
	var b := Button.new()
	b.text = text
	if tooltip != "":
		b.tooltip_text = tooltip
	b.pressed.connect(cb)
	b.pressed.connect(func(): AudioService.play_sfx("ui_click"))
	b.mouse_entered.connect(func(): AudioService.play_sfx("ui_hover", 0.02))
	return b


static func panel(child: Control) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_child(child)
	return p


static func hbox(sep: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h


static func vbox(sep: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v


static func progress(value: float, max_value: float = 1.0, color: Color = ACCENT) -> ProgressBar:
	var p := ProgressBar.new()
	p.max_value = max_value
	p.value = value
	p.show_percentage = false
	p.custom_minimum_size = Vector2(120, 14)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.1, 0.09)
	bg.corner_radius_top_left = 3
	bg.corner_radius_top_right = 3
	bg.corner_radius_bottom_left = 3
	bg.corner_radius_bottom_right = 3
	var fill := StyleBoxFlat.new()
	fill.bg_color = color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	p.add_theme_stylebox_override("background", bg)
	p.add_theme_stylebox_override("fill", fill)
	return p


static func separator() -> HSeparator:
	return HSeparator.new()


static func money(v: float) -> String:
	var neg := v < 0.0
	var i := absi(int(v))
	var out := ""
	while i >= 1000:
		out = ",%03d%s" % [i % 1000, out]
		@warning_ignore("integer_division")
		i = i / 1000
	return "%s$%d%s" % ["-" if neg else "", i, out]


static func grid(cols: int) -> GridContainer:
	var g := GridContainer.new()
	g.columns = cols
	g.add_theme_constant_override("h_separation", 14)
	g.add_theme_constant_override("v_separation", 6)
	return g


## Reliably center a popup regardless of when its content grows or how big
## its parent currently is. Anchors top-left, then positions against the
## viewport once the content size is known (deferred one frame).
static func center_popup(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_center_deferred.call_deferred(c)


static func _center_deferred(c: Control) -> void:
	if not is_instance_valid(c) or not c.is_inside_tree():
		return
	await c.get_tree().process_frame
	if not is_instance_valid(c) or not c.is_inside_tree():
		return
	var vp := c.get_viewport_rect().size
	c.position = ((vp - c.size) / 2.0).round().max(Vector2.ZERO)


static func confirm(parent: Node, text: String, on_yes: Callable) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.dialog_text = text
	dialog.theme = theme()
	dialog.confirmed.connect(on_yes)
	dialog.canceled.connect(dialog.queue_free)
	dialog.confirmed.connect(dialog.queue_free)
	parent.add_child(dialog)
	dialog.popup_centered()
