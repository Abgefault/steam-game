extends CanvasLayer
## In-game HUD: persistent top bar, crosshair, interact prompt, toasts,
## alerts, tracked objective, speed controls, and hosts for the tablet,
## machine dialog, daily report, event popups and pause menu.

var _top_bar: HBoxContainer
var _stat_labels: Dictionary = {}
var _crosshair: Label
var _prompt: Label
var _toast_box: VBoxContainer
var _alert_box: VBoxContainer
var _objective_label: Label
var _speed_buttons: Dictionary = {}
var _tablet: Control = null
var _pause_menu: Control = null
var _dialog_host: Control
var _alerts: Dictionary = {}
var _tutorial_label: Label


func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.theme = UIKit.theme()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	_build_top_bar(root)
	_build_center(root)
	_build_side(root)
	_dialog_host = Control.new()
	_dialog_host.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dialog_host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_dialog_host)
	EventBus.toast.connect(_on_toast)
	EventBus.alert_raised.connect(_on_alert)
	EventBus.alert_cleared.connect(_on_alert_cleared)
	EventBus.day_ended.connect(_on_day_ended)
	EventBus.game_event_fired.connect(_on_game_event)
	EventBus.speed_changed.connect(func(_s, _p): _refresh_speed())
	EventBus.objective_completed.connect(func(_o): AudioService.play_sfx("objective"))
	EventBus.achievement_unlocked.connect(func(_a): AudioService.play_sfx("achievement"))
	EventBus.audit_finished.connect(_on_audit)
	EventBus.trial_started.connect(func(): _refresh_stats())
	_refresh_speed()
	var timer := Timer.new()
	timer.wait_time = 0.25
	timer.timeout.connect(_refresh_stats)
	add_child(timer)
	timer.start()
	_refresh_stats()


func _build_top_bar(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)
	_top_bar = UIKit.hbox(18)
	panel.add_child(_top_bar)
	for key in ["cash", "day", "left", "rep", "comp", "auto", "rp", "stage"]:
		var l := UIKit.label("", UIKit.TEXT, 15)
		_stat_labels[key] = l
		_top_bar.add_child(l)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_top_bar.add_child(spacer)
	for entry in [["⏸", 0.0, "speed_pause"], ["1×", 1.0, ""], ["2×", 2.0, ""], ["4×", 4.0, ""]]:
		var b := UIKit.button(entry[0], func():
			if float(entry[1]) == 0.0:
				SimClock.toggle_pause()
			else:
				SimClock.set_speed(float(entry[1])))
		_speed_buttons[entry[0]] = b
		_top_bar.add_child(b)
	_top_bar.add_child(UIKit.button("End Day", _confirm_end_day, "Skip to the end of the day"))
	_top_bar.add_child(UIKit.button("Tablet (TAB)", toggle_tablet))
	_top_bar.add_child(UIKit.button("Menu (ESC)", open_pause))


func _build_center(root: Control) -> void:
	_crosshair = UIKit.label("+", UIKit.TEXT_DIM, 22)
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_crosshair)
	_prompt = UIKit.label("", UIKit.TEXT, 17)
	_prompt.set_anchors_preset(Control.PRESET_CENTER)
	_prompt.position.y += 40
	_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_prompt)
	_tutorial_label = UIKit.label("", UIKit.WARN, 16)
	_tutorial_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_tutorial_label.position.y -= 90
	_tutorial_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tutorial_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_tutorial_label)


func _build_side(root: Control) -> void:
	_toast_box = UIKit.vbox(6)
	_toast_box.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_toast_box.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_toast_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_toast_box.position -= Vector2(16, 16)
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_toast_box)
	var left := UIKit.vbox(8)
	left.set_anchors_preset(Control.PRESET_TOP_LEFT)
	left.position = Vector2(14, 52)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(left)
	_objective_label = UIKit.label("", UIKit.TEXT_DIM, 14)
	_objective_label.custom_minimum_size.x = 340
	left.add_child(_objective_label)
	_alert_box = UIKit.vbox(4)
	left.add_child(_alert_box)


# ------------------------------------------------------------------ refresh

func _refresh_stats() -> void:
	if not Game.in_session:
		return
	var s := Game.state
	_stat_labels.cash.text = UIKit.money(Game.cash())
	_stat_labels.cash.add_theme_color_override("font_color",
		UIKit.OK if Game.cash() >= 0 else UIKit.ERR)
	_stat_labels.day.text = "Day %d  %s" % [SimClock.day, SimClock.time_string()]
	_stat_labels.left.text = "%d days left" % CampaignSim.days_remaining(s)
	_stat_labels.rep.text = "Rep %.0f" % float(s.reputation)
	_stat_labels.comp.text = "Comp %.0f" % float(s.compliance)
	_stat_labels.auto.text = "Auto %.0f%%" % float(s.automation_score)
	_stat_labels.rp.text = "RP %d" % int(s.research_points)
	_stat_labels.stage.text = Game.stage_name()
	_stat_labels.stage.add_theme_color_override("font_color", UIKit.ACCENT)
	# Tracked objective: first unfinished tutorial step, else first regular.
	var tracked := _tracked_objective()
	if not tracked.is_empty():
		_objective_label.text = "▸ %s\n   %s" % [str(tracked.name), str(tracked.desc)]
	else:
		_objective_label.text = ""
	_tutorial_label.text = _tutorial_hint()
	# Interact prompt from player raycast.
	var scene := get_tree().current_scene
	if scene != null and scene.get("player") != null:
		var player: Player = scene.player
		var target: Node = player.current_target() if not player.ui_locked else null
		if target != null and target.has_method("get_prompt"):
			_prompt.text = "[E] " + str(target.call("get_prompt"))
			if player.carried != null:
				_prompt.text += "\n[G] Drop carried container"
		elif player.carried != null:
			_prompt.text = "Carrying: %s\n[G] Drop" % player.carried.call("describe")
		else:
			_prompt.text = ""


func _tracked_objective() -> Dictionary:
	var s := Game.state
	if bool(SettingsService.get_v("tutorial_enabled")):
		for def: Dictionary in DataRegistry.objectives.values():
			if str(def.get("kind", "")) == "tutorial" \
					and not bool(s.objectives.get(str(def.id), {}).get("done", false)):
				return def
	for def: Dictionary in DataRegistry.objectives.values():
		if str(def.get("kind", "")) == "regular" \
				and not bool(s.objectives.get(str(def.id), {}).get("done", false)):
			return def
	return {}


func _tutorial_hint() -> String:
	if not bool(SettingsService.get_v("tutorial_enabled")) or bool(Game.state.tutorial_done):
		return ""
	var s := Game.state
	if int(s.stats.batches_completed) == 0:
		if MachineSim._pool_total(s.raw) == 0 and str(s.machines.m_cultivation_1.state) == "idle":
			return "Walk to the CULTIVATION MODULE (west hall) and press E to start your first batch."
		if str(s.machines.m_cultivation_1.state) == "running":
			return "Cultivation is running. Meanwhile, explore the tablet (TAB)."
		if str(s.machines.m_cultivation_1.state) == "done":
			return "Unload the harvest (E) and carry the container to the CONDITIONING UNIT."
	if InventorySim.total_qty(s) == 0 and not (s.batches as Array).is_empty():
		return "Batches flow: Conditioning → Processing → Product Machine → Lab → Packaging."
	if InventorySim.total_qty(s) > 0 and int(s.stats.total_units_sold) == 0:
		return "Stock the store shelf from the warehouse (E on shelf), open the store at the checkout, and stay near the register."
	if int(s.stats.total_units_sold) > 0 and (s.staff as Array).is_empty():
		return "Nice, first sales! Hire staff on the tablet (TAB → Staff) so work continues without you."
	if not (s.staff as Array).is_empty():
		s.tutorial_done = true
	return ""


func _refresh_speed() -> void:
	for key: String in _speed_buttons.keys():
		var b: Button = _speed_buttons[key]
		var active: bool = (key == "⏸" and SimClock.paused) \
			or (key == "1×" and not SimClock.paused and SimClock.speed == 1.0) \
			or (key == "2×" and not SimClock.paused and SimClock.speed == 2.0) \
			or (key == "4×" and not SimClock.paused and SimClock.speed == 4.0)
		b.modulate = Color(1, 1, 1) if active else Color(0.6, 0.6, 0.6)


# ------------------------------------------------------------------- events

func _on_toast(text: String, kind: String) -> void:
	var color := UIKit.TEXT
	match kind:
		"success": color = UIKit.OK
		"warning": color = UIKit.WARN
		"error":
			color = UIKit.ERR
			AudioService.play_sfx("warning")
		_: AudioService.play_sfx("toast", 0.03)
	var l := UIKit.label(text, color, 15)
	l.custom_minimum_size.x = 320
	var p := UIKit.panel(l)
	_toast_box.add_child(p)
	if _toast_box.get_child_count() > 5:
		_toast_box.get_child(0).queue_free()
	var tween := create_tween()
	tween.tween_interval(float(SettingsService.get_v("notification_seconds")))
	tween.tween_property(p, "modulate:a", 0.0, 0.5)
	tween.tween_callback(p.queue_free)


func _on_alert(id: String, text: String, severity: int) -> void:
	if _alerts.has(id):
		return
	var color := UIKit.WARN if severity < 2 else UIKit.ERR
	var l := UIKit.label("⚠ " + text, color, 14)
	_alerts[id] = l
	_alert_box.add_child(l)


func _on_alert_cleared(id: String) -> void:
	if _alerts.has(id):
		(_alerts[id] as Node).queue_free()
		_alerts.erase(id)


func _on_day_ended(day: int, report: Dictionary) -> void:
	var dlg: Control = load("res://scripts/ui/daily_report.gd").new()
	dlg.report = report
	dlg.day = day
	_show_dialog(dlg)


func _on_game_event(ev: Dictionary) -> void:
	if bool(ev.resolved):
		return
	var dlg: Control = load("res://scripts/ui/event_popup.gd").new()
	dlg.event_data = ev
	_show_dialog(dlg)


func _on_audit(result: Dictionary) -> void:
	AudioService.play_sfx("audit_stamp")


# ------------------------------------------------------------------ dialogs

func _show_dialog(dlg: Control) -> void:
	_dialog_host.add_child(dlg)
	_lock_player(true)
	dlg.tree_exited.connect(func(): _maybe_unlock())


func _maybe_unlock() -> void:
	if _dialog_host.get_child_count() <= 1 and _tablet == null and _pause_menu == null:
		_lock_player(false)


func _lock_player(locked: bool) -> void:
	var scene := get_tree().current_scene
	if scene != null and scene.get("player") != null:
		(scene.player as Player).ui_locked = locked
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if locked else Input.MOUSE_MODE_CAPTURED
	if locked:
		SimClock.set_paused(true)


func open_machine_dialog(machine_id: String) -> void:
	var dlg: Control = load("res://scripts/ui/machine_dialog.gd").new()
	dlg.machine_id = machine_id
	_show_dialog(dlg)


func toggle_tablet() -> void:
	if _tablet != null:
		_tablet.queue_free()
		_tablet = null
		_maybe_unlock()
		return
	_tablet = load("res://scripts/ui/tablet.gd").new()
	_dialog_host.add_child(_tablet)
	_lock_player(true)
	_tablet.tree_exited.connect(func():
		_tablet = null
		_maybe_unlock())


func open_pause() -> void:
	if _pause_menu != null:
		return
	_pause_menu = load("res://scripts/ui/pause_menu.gd").new()
	_dialog_host.add_child(_pause_menu)
	_lock_player(true)
	_pause_menu.tree_exited.connect(func():
		_pause_menu = null
		_maybe_unlock())


func _confirm_end_day() -> void:
	var open_store := false
	for st: Dictionary in Game.state.stores.values():
		if bool(st.get("open", false)):
			open_store = true
	if open_store:
		UIKit.confirm(self, "A store is still open. End the day anyway?", SimClock.end_day_early)
	else:
		SimClock.end_day_early()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_tablet"):
		toggle_tablet()
	elif event.is_action_pressed("pause_menu"):
		if _tablet != null:
			toggle_tablet()
		else:
			open_pause()
	elif event.is_action_pressed("speed_pause"):
		SimClock.toggle_pause()
	elif event.is_action_pressed("speed_1"):
		SimClock.set_speed(1.0)
	elif event.is_action_pressed("speed_2"):
		SimClock.set_speed(2.0)
	elif event.is_action_pressed("speed_4"):
		SimClock.set_speed(4.0)
	elif event.is_action_pressed("quicksave"):
		SaveService.quicksave()
	elif event.is_action_pressed("quickload"):
		SaveService.quickload()
