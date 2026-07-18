extends PanelContainer
## Popup for events that require a player decision.

var event_data: Dictionary = {}


func _ready() -> void:
	theme = UIKit.theme()
	UIKit.center_popup(self)
	custom_minimum_size = Vector2(480, 200)
	var v := UIKit.vbox(10)
	add_child(v)
	v.add_child(UIKit.title(str(event_data.get("title", "Event"))))
	v.add_child(UIKit.label(str(event_data.get("text", ""))))
	v.add_child(UIKit.separator())
	var choices: Array = event_data.get("choices", [])
	for i in choices.size():
		var choice: Dictionary = choices[i]
		v.add_child(UIKit.button(str(choice.label), func():
			EventsSim.choose(Game.state, str(event_data.id), i)
			queue_free()))
	v.add_child(UIKit.button("Decide later (Events tab)", queue_free))
