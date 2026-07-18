extends PanelContainer
## Settings dialog: audio, controls, display, graphics, accessibility.


func _ready() -> void:
	theme = UIKit.theme()
	set_anchors_preset(Control.PRESET_CENTER)
	custom_minimum_size = Vector2(620, 520)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(600, 500)
	add_child(scroll)
	var v := UIKit.vbox(8)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(v)
	v.add_child(UIKit.title("Settings"))
	v.add_child(UIKit.title("Audio", 16))
	_slider(v, "Master volume", "master_volume", 0.0, 1.0)
	_slider(v, "Music volume", "music_volume", 0.0, 1.0)
	_slider(v, "Ambience volume", "ambience_volume", 0.0, 1.0)
	_slider(v, "SFX volume", "sfx_volume", 0.0, 1.0)
	v.add_child(UIKit.title("Controls", 16))
	_slider(v, "Mouse sensitivity", "mouse_sensitivity", 0.05, 1.0)
	_toggle(v, "Invert Y axis", "invert_y")
	_slider(v, "Field of view", "fov", 60.0, 110.0)
	v.add_child(UIKit.label("Bindings: WASD move · Shift sprint · Ctrl crouch · E interact · G drop · TAB tablet · 1-4 speed · F5/F9 quick save/load", UIKit.TEXT_DIM, 13))
	v.add_child(UIKit.title("Display", 16))
	_options(v, "Window mode", "window_mode", ["windowed", "borderless", "fullscreen"])
	_options(v, "Resolution", "resolution", ["1280x720", "1600x900", "1920x1080", "2560x1440"])
	_options(v, "Graphics quality", "quality", ["low", "medium", "high", "ultra"])
	_slider(v, "UI scale", "ui_scale", 0.8, 1.4)
	v.add_child(UIKit.title("Accessibility & Gameplay", 16))
	_toggle(v, "Reduced motion", "reduced_motion")
	_toggle(v, "Head bob", "head_bob")
	_toggle(v, "Screen shake", "screen_shake")
	_toggle(v, "Large tooltips", "large_tooltips")
	_toggle(v, "Pause when window loses focus", "pause_on_focus_loss")
	_toggle(v, "Tutorial hints", "tutorial_enabled")
	_slider(v, "Notification duration (s)", "notification_seconds", 2.0, 10.0)
	_slider(v, "Autosave every N days (0 = off)", "autosave_days", 0.0, 7.0, true)
	v.add_child(UIKit.separator())
	v.add_child(UIKit.button("Close", queue_free))


func _slider(v: VBoxContainer, label_text: String, key: String, minv: float, maxv: float,
		integer: bool = false) -> void:
	var row := UIKit.hbox(10)
	v.add_child(row)
	var lbl := UIKit.label(label_text + ":")
	lbl.custom_minimum_size.x = 260
	row.add_child(lbl)
	var slider := HSlider.new()
	slider.min_value = minv
	slider.max_value = maxv
	slider.step = 1.0 if integer else 0.01
	slider.value = float(SettingsService.get_v(key))
	slider.custom_minimum_size.x = 200
	var val_lbl := UIKit.label("%.2f" % slider.value if not integer else str(int(slider.value)))
	slider.value_changed.connect(func(val: float):
		SettingsService.set_v(key, int(val) if integer else val)
		val_lbl.text = "%.2f" % val if not integer else str(int(val)))
	row.add_child(slider)
	row.add_child(val_lbl)


func _toggle(v: VBoxContainer, label_text: String, key: String) -> void:
	var cb := CheckBox.new()
	cb.text = label_text
	cb.button_pressed = bool(SettingsService.get_v(key))
	cb.toggled.connect(func(on: bool): SettingsService.set_v(key, on))
	v.add_child(cb)


func _options(v: VBoxContainer, label_text: String, key: String, values: Array) -> void:
	var row := UIKit.hbox(10)
	v.add_child(row)
	var lbl := UIKit.label(label_text + ":")
	lbl.custom_minimum_size.x = 260
	row.add_child(lbl)
	var opt := OptionButton.new()
	for val in values:
		opt.add_item(str(val))
	var current := str(SettingsService.get_v(key))
	for i in values.size():
		if str(values[i]) == current:
			opt.selected = i
	opt.item_selected.connect(func(idx: int): SettingsService.set_v(key, str(values[idx])))
	row.add_child(opt)
