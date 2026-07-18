extends Node
## Persists player settings to user://settings.cfg and applies them.

const PATH := "user://settings.cfg"

var data: Dictionary = {
	"master_volume": 0.8,
	"music_volume": 0.6,
	"ambience_volume": 0.7,
	"sfx_volume": 0.8,
	"mouse_sensitivity": 0.35,
	"invert_y": false,
	"fov": 80.0,
	"window_mode": "windowed",   # windowed | borderless | fullscreen
	"resolution": "1920x1080",
	"quality": "high",           # low | medium | high | ultra
	"ui_scale": 1.0,
	"reduced_motion": false,
	"head_bob": true,
	"screen_shake": true,
	"large_tooltips": false,
	"notification_seconds": 4.0,
	"autosave_days": 1,
	"pause_on_focus_loss": true,
	"tutorial_enabled": true,
}


func _ready() -> void:
	load_settings()
	apply_all()


func get_v(key: String) -> Variant:
	return data.get(key)


func set_v(key: String, value: Variant) -> void:
	data[key] = value
	apply_all()
	save_settings()


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for key: String in data.keys():
		if cfg.has_section_key("settings", key):
			data[key] = cfg.get_value("settings", key)


func save_settings() -> void:
	var cfg := ConfigFile.new()
	for key: String in data.keys():
		cfg.set_value("settings", key, data[key])
	cfg.save(PATH)


func apply_all() -> void:
	AudioService.apply_volumes(
		float(data.master_volume), float(data.music_volume),
		float(data.ambience_volume), float(data.sfx_volume))
	_apply_window()
	_apply_quality()


func _apply_window() -> void:
	if DisplayServer.get_name() == "headless":
		return
	match str(data.window_mode):
		"fullscreen":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"borderless":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
			DisplayServer.window_set_size(DisplayServer.screen_get_size())
		_:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
			var parts: PackedStringArray = str(data.resolution).split("x")
			if parts.size() == 2:
				DisplayServer.window_set_size(Vector2i(int(parts[0]), int(parts[1])))


func _apply_quality() -> void:
	var vp := get_viewport()
	if vp == null:
		return
	match str(data.quality):
		"low":
			vp.msaa_3d = Viewport.MSAA_DISABLED
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		"medium":
			vp.msaa_3d = Viewport.MSAA_2X
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		"high":
			vp.msaa_3d = Viewport.MSAA_2X
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA
		"ultra":
			vp.msaa_3d = Viewport.MSAA_4X
			vp.screen_space_aa = Viewport.SCREEN_SPACE_AA_FXAA


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and bool(data.pause_on_focus_loss):
		if SimClock.running and not SimClock.paused:
			SimClock.set_paused(true)
