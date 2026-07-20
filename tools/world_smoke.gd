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
	# Exercise the tablet (the machine dialog is opened later, after the
	# clean world screenshots).
	var hud: CanvasLayer = facility.get("hud")
	if hud != null:
		hud.call("toggle_tablet")
		await get_tree().process_frame
		hud.call("toggle_tablet")
	else:
		failed = true
	print("[WSMOKE] UI exercised")
	var want_shots := "--screenshot" in OS.get_cmdline_user_args() and DisplayServer.get_name() != "headless"
	var dir := OS.get_environment("GE_SHOT_DIR")
	if want_shots and dir != "":
		# Farm view: park the player in front of the cultivation zone.
		var player: Player = facility.get("player")
		if player != null:
			player.global_position = Vector3(-6.0, 0.1, -3.2)
			player.rotation.y = deg_to_rad(60.0)
			player.camera.rotation.x = -0.06
			await get_tree().create_timer(0.3).timeout
			await _shot(dir + "/farm.png")
			# Machine row view.
			player.global_position = Vector3(-1.5, 0.1, -3.0)
			player.rotation.y = deg_to_rad(76.0)
			await get_tree().create_timer(0.3).timeout
			await _shot(dir + "/machines.png")
			# Store view.
			player.global_position = Vector3(11.5, 0.1, 5.8)
			player.rotation.y = deg_to_rad(73.0)
			player.camera.rotation.x = -0.04
			await get_tree().create_timer(0.3).timeout
			await _shot(dir + "/store.png")
		# Facility with the machine dialog open.
		if hud != null:
			hud.call("open_machine_dialog", "m_product_1")
			await get_tree().process_frame
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
