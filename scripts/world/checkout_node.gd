class_name CheckoutNode
extends StaticBody3D
## Checkout counter. Customers pay here; someone (player nearby or a sales
## employee) must staff it. Also toggles the store open/closed.

var store_id: String = "store_old_market"


static func create(p_store_id: String) -> CheckoutNode:
	var node := CheckoutNode.new()
	node.store_id = p_store_id
	node._build()
	return node


func _build() -> void:
	var counter := MaterialLib.pbr("WoodFloor051", 0.7, Color(0.5, 0.4, 0.32), false)
	var top := MaterialLib.painted_metal(Color(1.4, 1.38, 1.32), 0.3)
	_mesh_box(Vector3(1.8, 0.95, 0.7), Vector3(0, 0.475, 0), counter)
	_mesh_box(Vector3(1.9, 0.06, 0.8), Vector3(0, 0.98, 0), top)
	var register := StandardMaterial3D.new()
	register.albedo_color = Color(0.2, 0.22, 0.24)
	register.metallic = 0.4
	_mesh_box(Vector3(0.35, 0.3, 0.35), Vector3(-0.5, 1.16, 0), register)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.9, 1.1, 0.8)
	col.shape = shape
	col.position.y = 0.55
	add_child(col)
	var label := Label3D.new()
	label.position = Vector3(0, 1.6, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.pixel_size = 0.0045
	label.outline_size = 8
	label.text = "CHECKOUT"
	add_child(label)


func _mesh_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	add_child(mi)


func is_staffed(player: Player) -> bool:
	if player != null and player.global_position.distance_to(global_position) < 3.5:
		return true
	return StaffSim.best_skill_at_store(Game.state, store_id, "sales") > 0.0


func get_prompt() -> String:
	var st: Dictionary = Game.state.stores.get(store_id, {})
	return "Close store" if bool(st.get("open", false)) else "Open store"


func interact(_player: Player) -> void:
	var st: Dictionary = Game.state.stores.get(store_id, {})
	if st.is_empty():
		return
	var minute := SimClock.minute_of_day
	if not bool(st.open) and (minute < RetailSim.OPEN_MINUTE or minute >= RetailSim.CLOSE_MINUTE):
		EventBus.notify("Store hours are 09:00–21:00.", "info")
		return
	RetailSim.set_open(Game.state, store_id, not bool(st.open))
	AudioService.play_sfx("doorbell")
	EventBus.notify("Store is now %s." % ("OPEN" if bool(st.open) else "CLOSED"),
		"success" if bool(st.open) else "info")
