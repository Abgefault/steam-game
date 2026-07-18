class_name RackNode
extends StaticBody3D
## Warehouse rack: deposit target for packaged containers and a live
## visualization of warehouse stock levels.

var _stock_root: Node3D
var _label: Label3D


static func create() -> RackNode:
	var node := RackNode.new()
	node._build()
	return node


func _build() -> void:
	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.85, 0.45, 0.15)
	steel.metallic = 0.5
	steel.roughness = 0.5
	var shelf_mat := StandardMaterial3D.new()
	shelf_mat.albedo_color = Color(0.5, 0.52, 0.55)
	shelf_mat.metallic = 0.4
	for x in [-1.4, 1.4]:
		_mesh_box(Vector3(0.1, 3.0, 0.1), Vector3(x, 1.5, -0.5), steel)
		_mesh_box(Vector3(0.1, 3.0, 0.1), Vector3(x, 1.5, 0.5), steel)
	for y in [0.4, 1.4, 2.4]:
		_mesh_box(Vector3(2.9, 0.07, 1.1), Vector3(0, y, 0), shelf_mat)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(3.0, 3.0, 1.2)
	col.shape = shape
	col.position.y = 1.5
	add_child(col)
	_stock_root = Node3D.new()
	add_child(_stock_root)
	_label = Label3D.new()
	_label.position = Vector3(0, 3.3, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 42
	_label.pixel_size = 0.0045
	_label.outline_size = 8
	add_child(_label)
	EventBus.inventory_changed.connect(_refresh)
	_refresh()


func _mesh_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	add_child(mi)


func _refresh() -> void:
	for c in _stock_root.get_children():
		c.queue_free()
	var total := 0
	for lot: Dictionary in InventorySim.lots_at(Game.state, "warehouse"):
		total += int(lot.qty)
	_label.text = "WAREHOUSE — %d units" % total
	var boxes: int = clampi(total / 8, 0, 18)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.72, 0.66, 0.55)
	mat.roughness = 0.85
	for i in boxes:
		var box := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.38, 0.32, 0.38)
		box.mesh = mesh
		box.material_override = mat
		@warning_ignore("integer_division")
		box.position = Vector3(-1.25 + (i % 6) * 0.5, 0.62 + (i / 6) * 1.0, 0.0)
		_stock_root.add_child(box)


func get_prompt() -> String:
	return "Warehouse rack (deposit packaged goods)"


func interact(player: Player) -> void:
	if player.carried is ContainerNode:
		var c: ContainerNode = player.carried
		if str(c.payload.get("kind", "")) == "packaged":
			MachineSim.apply_output(Game.state, c.payload, "warehouse")
			player.consume_carried()
			EventBus.notify("Lot stored in the warehouse.", "success")
			return
		EventBus.notify("Only packaged goods are stored here — feed raw containers to machines.", "warning")
		return
	EventBus.notify("Warehouse stock: %d units. Use the tablet (TAB) for details."
		% InventorySim.total_qty(Game.state), "info")
