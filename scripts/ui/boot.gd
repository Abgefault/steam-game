extends Control
## Boot scene: shows a short loading screen, validates data, then routes to
## the main menu. Supports --smoke-test for automated export verification:
## boots, starts a game, advances time, saves, loads and quits with exit
## code 0 only when everything worked.

@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	status_label.text = "Loading Verdantia…"
	await get_tree().process_frame
	await get_tree().process_frame
	var args := OS.get_cmdline_user_args()
	if "--smoke-test" in args:
		await _smoke_test()
		return
	if not DataRegistry.validation_errors.is_empty() and OS.is_debug_build():
		status_label.text = "DATA ERRORS — see log."
		for e in DataRegistry.validation_errors:
			printerr("[DATA] " + e)
		await get_tree().create_timer(2.0).timeout
	SceneRouter.goto("main_menu")


func _smoke_test() -> void:
	print("[SMOKE] boot ok, data errors: %d" % DataRegistry.validation_errors.size())
	var failed := not DataRegistry.validation_errors.is_empty()
	Game.start_new_game("Smoke Test Co", "Affordable", "3fa34d", "1f2d24", 0)
	print("[SMOKE] new game started, cash=%.0f" % Game.cash())
	# Drive the sim quickly without the 3D world.
	SimClock.running = true
	SimClock.paused = false
	RetailSim.set_open(Game.state, "store_old_market", true)
	MachineSim.load_and_start(Game.state, "m_cultivation_1", {"strain_id": "verdant_dawn"})
	for i in 2000:
		SimClock._advance_minute(true)
	print("[SMOKE] advanced to day %d %s" % [SimClock.day, SimClock.time_string()])
	if SimClock.day < 2:
		failed = true
	if not SaveService.save_game("smoketest"):
		failed = true
	print("[SMOKE] saved")
	if not SaveService.load_game("smoketest"):
		failed = true
	print("[SMOKE] loaded, day=%d cash=%.0f" % [Game.state.day, Game.cash()])
	SaveService.delete_save("smoketest")
	print("[SMOKE] %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)
