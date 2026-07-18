extends Node
## World smoke test runner. Lives directly under the tree root so it
## survives the scene change into the facility. Started by boot.gd via
## `--smoke-world`.


func _ready() -> void:
	_run()


func _run() -> void:
	Game.start_new_game("World Smoke Co", "Premium", "2e7dd1", "1f2d24", 1)
	SceneRouter.goto("facility")
	await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	var facility := get_tree().current_scene
	var failed := facility == null or facility.get("player") == null
	print("[WSMOKE] facility loaded with player: %s" % (not failed))
	# Open the store and let visible customers spawn while time runs.
	RetailSim.set_open(Game.state, "store_old_market", true)
	SimClock.minute_of_day = 10 * 60
	SimClock.set_speed(4.0)
	MachineSim.load_and_start(Game.state, "m_cultivation_1", {"strain_id": "citrus_static"})
	StaffSim.hire(Game.state, StaffSim.generate_candidate(Game.state, "production"))
	await get_tree().create_timer(6.0).timeout
	print("[WSMOKE] sim time now %s, customers today: %d" % [SimClock.time_string(),
		int(Game.state.daily.customers)])
	# Exercise the tablet and a machine dialog.
	var hud: CanvasLayer = facility.get("hud")
	if hud != null:
		hud.call("toggle_tablet")
		await get_tree().process_frame
		hud.call("toggle_tablet")
		hud.call("open_machine_dialog", "m_product_1")
		await get_tree().process_frame
	else:
		failed = true
	print("[WSMOKE] UI exercised")
	var want_shots := "--screenshot" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var dir := OS.get_environment("GE_SHOT_DIR")
	if want_shots and dir != "":
		# Facility with the machine dialog already open.
		await _shot(dir + "/facility.png")
		# Tablet (full-rect, drawn over everything).
		if hud != null:
			hud.call("toggle_tablet")
			await get_tree().create_timer(0.4).timeout
			await _shot(dir + "/tablet.png")
			# A couple of extra pages to verify grid/description layouts.
			var tablet: Node = null
			for n in get_tree().get_nodes_in_group("@") + hud.get_children():
				pass
			tablet = _find_tablet(hud)
			if tablet != null and tablet.has_method("_goto"):
				tablet.call("_goto", "Research")
				await get_tree().create_timer(0.3).timeout
				await _shot(dir + "/tablet_research.png")
				tablet.call("_goto", "Stores")
				await get_tree().create_timer(0.3).timeout
				await _shot(dir + "/tablet_stores.png")
				tablet.call("_goto", "Staff")
				await get_tree().create_timer(0.3).timeout
				await _shot(dir + "/tablet_staff.png")
			hud.call("toggle_tablet")
		# Main menu.
		SceneRouter.suppressed = false
		SceneRouter.goto("main_menu")
		await get_tree().create_timer(0.5).timeout
		await _shot(dir + "/main_menu.png")
	if not SaveService.save_game("wsmoke"):
		failed = true
	SaveService.delete_save("wsmoke")
	print("[WSMOKE] %s" % ("FAIL" if failed else "PASS"))
	get_tree().quit(1 if failed else 0)


func _find_tablet(node: Node) -> Node:
	for child in node.get_children():
		if child.get_script() != null and str(child.get_script().resource_path).ends_with("tablet.gd"):
			return child
		var found := _find_tablet(child)
		if found != null:
			return found
	return null


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(path)
	print("[WSMOKE] screenshot: %s" % path)
