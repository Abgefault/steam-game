extends Control
## Victory screen: contract award, final grade, category scores, milestones,
## Endless Mode continuation.


func _ready() -> void:
	theme = UIKit.theme()
	AudioService.play_sfx("victory")
	AudioService.play_music("music_menu")
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.1, 0.07)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(center)
	var v := UIKit.vbox(10)
	center.add_child(v)
	var r: Dictionary = Game.state.campaign_result
	var title := UIKit.title("CONTRACT AWARDED", 44)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	v.add_child(UIKit.label("%s is Verdantia's exclusive supplier for the next ten years."
		% str(Game.state.company.name), UIKit.TEXT, 18))
	var grade := UIKit.title("FINAL GRADE: %s" % str(r.get("grade", "C")), 64)
	grade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grade.add_theme_color_override("font_color", UIKit.WARN)
	v.add_child(grade)
	v.add_child(UIKit.label("Overall score: %.0f / 100" % float(r.get("total", 0.0)), UIKit.TEXT_DIM))
	v.add_child(UIKit.separator())
	var g := UIKit.grid(2)
	v.add_child(g)
	var scores: Dictionary = r.get("scores", {})
	for key: String in scores.keys():
		g.add_child(UIKit.label(key.capitalize() + ":", UIKit.TEXT_DIM))
		var row := UIKit.hbox(8)
		g.add_child(row)
		row.add_child(UIKit.progress(float(scores[key]), 100.0))
		row.add_child(UIKit.label("%.0f" % float(scores[key])))
	v.add_child(UIKit.separator())
	var trial: Dictionary = r.get("trial", {})
	v.add_child(UIKit.label("Trial: %d units delivered, %.0f%% on-time, %.1f%% rejected, %s profit." % [
		int(trial.get("delivered", 0)), float(trial.get("on_time_pct", 0)),
		float(trial.get("reject_pct", 0)), UIKit.money(float(trial.get("profit", 0)))]))
	v.add_child(UIKit.label("Final audit: %s (%.0f%%)" % [
		"PASSED" if bool(r.get("audit", {}).get("passed", false)) else "flagged",
		float(r.get("audit", {}).get("pct", 0.0))]))
	v.add_child(UIKit.separator())
	v.add_child(UIKit.label("Company milestones:", UIKit.ACCENT))
	for m: Dictionary in (r.get("milestones", []) as Array).slice(-12):
		v.add_child(UIKit.label("Day %d — %s" % [int(m.day), str(m.text)], UIKit.TEXT_DIM, 13))
	v.add_child(UIKit.separator())
	var actions := UIKit.hbox(10)
	v.add_child(actions)
	actions.add_child(UIKit.button("Continue in Endless Mode", func():
		Game.state.campaign_over = false
		Game.state.trial.active = false
		SceneRouter.goto("facility")))
	actions.add_child(UIKit.button("Credits", func(): SceneRouter.goto("credits")))
	actions.add_child(UIKit.button("Main Menu", func(): SceneRouter.goto("main_menu")))
	actions.add_child(UIKit.button("Quit", func(): get_tree().quit()))
