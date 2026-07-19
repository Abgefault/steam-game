class_name ContainerNode
extends StaticBody3D
## A physical, carryable production container holding a deferred machine
## output (harvest, conditioned, processed or packaged goods). Deposit it
## at the matching machine, warehouse rack or store shelf.

var payload: Dictionary = {}
var held := false


static func create(out: Dictionary) -> ContainerNode:
	var node := ContainerNode.new()
	node.payload = out
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.44, 0.34, 0.44)
	mesh.mesh = box
	mesh.position.y = 0.17
	var tint := Color(1, 1, 1)
	match str(out.get("kind", "")):
		"cultivation": tint = Color(0.6, 0.85, 0.6)
		"conditioning": tint = Color(0.95, 0.85, 0.6)
		"processing": tint = Color(0.65, 0.75, 0.95)
		"packaged": tint = Color(1.0, 0.98, 0.92)
	var mat := MaterialLib.pbr("Cardboard004", 1.4, tint, false)
	mesh.material_override = mat
	node.add_child(mesh)
	var lid := MeshInstance3D.new()
	var lid_mesh := BoxMesh.new()
	lid_mesh.size = Vector3(0.46, 0.05, 0.46)
	lid.mesh = lid_mesh
	lid.position.y = 0.36
	var lid_mat := MaterialLib.pbr("Cardboard004", 2.0, tint.darkened(0.25), false)
	lid.material_override = lid_mat
	node.add_child(lid)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.46, 0.42, 0.46)
	col.shape = shape
	col.position.y = 0.2
	node.add_child(col)
	var label := Label3D.new()
	label.text = node.describe()
	label.position.y = 0.62
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 40
	label.pixel_size = 0.004
	label.modulate = Color(0.9, 0.95, 0.9)
	node.add_child(label)
	return node


func describe() -> String:
	var kind := str(payload.get("kind", "?"))
	match kind:
		"cultivation":
			return "Harvest: %s ×%d" % [_strain_name(), int(payload.qty)]
		"conditioning":
			return "Conditioned: %s ×%d" % [_strain_name(), int(payload.qty)]
		"processing":
			return "Refined: %s ×%d" % [_strain_name(), int(payload.qty)]
		"packaged":
			var p: Dictionary = DataRegistry.products.get(str(payload.get("product_id", "")), {})
			return "Packaged: %s ×%d" % [str(p.get("name", "?")), int(payload.qty)]
	return "Container"


func _strain_name() -> String:
	return str(DataRegistry.strains.get(str(payload.get("strain_id", "")), {}).get("name", "?"))


func get_prompt() -> String:
	return "Pick up %s" % describe()


func interact(player: Player) -> void:
	if held:
		return
	if player.pick_up(self):
		held = true


func on_picked_up() -> void:
	set_collision_layer_value(1, false)


func on_dropped() -> void:
	held = false
	set_collision_layer_value(1, true)
	# Settle onto the floor.
	global_position.y = 0.0
