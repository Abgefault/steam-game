extends Node
## Owns top-level scene switching (menu <-> game world <-> end screens).

const SCENES := {
	"main_menu": "res://scenes/MainMenu.tscn",
	"company_setup": "res://scenes/CompanySetup.tscn",
	"facility": "res://scenes/Facility.tscn",
	"victory": "res://scenes/Victory.tscn",
	"game_over": "res://scenes/GameOver.tscn",
	"credits": "res://scenes/Credits.tscn",
}

var current: String = ""
var suppressed: bool = false   # used by headless tests/simulations


func _ready() -> void:
	EventBus.campaign_won.connect(func(_r): goto.call_deferred("victory"))
	EventBus.campaign_lost.connect(func(_r, _s): goto.call_deferred("game_over"))


func goto(key: String) -> void:
	if suppressed:
		return
	if not SCENES.has(key):
		push_error("Unknown scene key: %s" % key)
		return
	current = key
	if key != "facility":
		SimClock.stop()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(SCENES[key])


func start_loaded_game() -> void:
	goto("facility")
	SimClock.running = true
	SimClock.set_paused(true)
