extends Node
## Central simulation clock. A campaign day runs from 06:00 to 24:00
## (1080 game minutes). One game minute lasts `real_seconds_per_game_minute`
## real seconds at speed 1. Speeds: pause, 1x, 2x, 4x.

const DAY_START_MINUTE: int = 6 * 60
const DAY_END_MINUTE: int = 24 * 60

var day: int = 1
var minute_of_day: int = DAY_START_MINUTE   # absolute minute within the 24h day
var speed: float = 1.0
var paused: bool = true
var running: bool = false                    # false in menus
var real_seconds_per_game_minute: float = 0.5

var _accum: float = 0.0


func _process(delta: float) -> void:
	if not running or paused:
		return
	_accum += delta * speed
	while _accum >= real_seconds_per_game_minute:
		_accum -= real_seconds_per_game_minute
		_advance_minute()


func start_campaign_clock() -> void:
	running = true
	paused = false
	set_speed(1.0)


func stop() -> void:
	running = false


func set_speed(v: float) -> void:
	speed = clampf(v, 1.0, 4.0)
	paused = false
	EventBus.speed_changed.emit(speed, paused)


func toggle_pause() -> void:
	paused = not paused
	EventBus.speed_changed.emit(speed, paused)


func set_paused(v: bool) -> void:
	paused = v
	EventBus.speed_changed.emit(speed, paused)


func time_string() -> String:
	return "%02d:%02d" % [minute_of_day / 60, minute_of_day % 60]


func minutes_left_today() -> int:
	return DAY_END_MINUTE - minute_of_day


func is_night() -> bool:
	return minute_of_day >= 21 * 60 or minute_of_day < 8 * 60


## Skip the rest of the day instantly (used by "End Day" button).
func end_day_early() -> void:
	if not running:
		return
	while minute_of_day < DAY_END_MINUTE:
		_advance_minute(true)


func _advance_minute(fast: bool = false) -> void:
	minute_of_day += 1
	EventBus.minute_passed.emit(day, minute_of_day)
	if minute_of_day % 60 == 0:
		EventBus.hour_passed.emit(day, minute_of_day / 60)
	if minute_of_day >= DAY_END_MINUTE:
		var finished_day := day
		day += 1
		minute_of_day = DAY_START_MINUTE
		paused = true
		EventBus.speed_changed.emit(speed, paused)
		# Game closes the books; the report is shown by the UI.
		var report: Dictionary = Game.close_day(finished_day)
		EventBus.day_ended.emit(finished_day, report)
		EventBus.day_started.emit(day)


func serialize() -> Dictionary:
	return {"day": day, "minute": minute_of_day, "speed": speed}


func deserialize(d: Dictionary) -> void:
	day = int(d.get("day", 1))
	minute_of_day = int(d.get("minute", DAY_START_MINUTE))
	speed = float(d.get("speed", 1.0))
	paused = true
	_accum = 0.0
