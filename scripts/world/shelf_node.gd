class_name ShelfNode
extends StaticBody3D
## Store display shelf. Shows real stock as stacked product boxes and lets
## the player deposit packaged containers or restock from the warehouse.

var store_id: String = "store_old_market"
var _stock_root: Node3D
var _label: Label3D


static func create(p_store_id: String) -> ShelfNode:
	var node := ShelfNode.new()
	node.store_id = p_store_id
	node._build()
	return node


func _build() -> void:
	var wood := MaterialLib.pbr("WoodFloor051", 0.8, Color(0.62, 0.5, 0.4), false)
	_mesh_box(Vector3(2.4, 0.05, 0.6), Vector3(0, 0.5, 0), wood)
	_mesh_box(Vector3(2.4, 0.05, 0.6), Vector3(0, 1.0, 0), wood)
	_mesh_box(Vector3(2.4, 0.05, 0.6), Vector3(0, 1.5, 0), wood)
	_mesh_box(Vector3(0.06, 1.7, 0.6), Vector3(-1.18, 0.85, 0), wood)
	_mesh_box(Vector3(0.06, 1.7, 0.6), Vector3(1.18, 0.85, 0), wood)
	_mesh_box(Vector3(2.4, 0.1, 0.62), Vector3(0, 0.05, 0), wood)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(2.4, 1.8, 0.7)
	col.shape = shape
	col.position.y = 0.9
	add_child(col)
	_stock_root = Node3D.new()
	add_child(_stock_root)
	_label = Label3D.new()
	_label.position = Vector3(0, 1.95, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 40
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
	var by_product: Dictionary = {}
	var total := 0
	for lot: Dictionary in InventorySim.lots_at(Game.state, "display:%s" % store_id):
		by_product[str(lot.product_id)] = int(by_product.get(str(lot.product_id), 0)) + int(lot.qty)
		total += int(lot.qty)
	_label.text = "DISPLAY — %d units" % total
	var slot := 0
	for pid: String in by_product.keys():
		if slot >= 12:
			break
		var count: int = mini(int(by_product[pid]), 4)
		for i in count:
			var box := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.16, 0.2, 0.16)
			box.mesh = mesh
			var h := float(hash(pid) % 360) / 360.0
			box.material_override = MaterialLib.pbr("Cardboard004", 3.0,
				Color.from_hsv(h, 0.4, 0.9), false)
			@warning_ignore("integer_division")
			var level := slot / 4
			box.position = Vector3(-0.95 + (slot % 4) * 0.55 + i * 0.11,
				0.63 + level * 0.5, 0.05)
			_stock_root.add_child(box)
		slot += 1


func get_prompt() -> String:
	return "Stock shelf (deposit packaged container, or restock from warehouse)"


func interact(player: Player) -> void:
	if player.carried is ContainerNode:
		var c: ContainerNode = player.carried
		if str(c.payload.get("kind", "")) == "packaged":
			if not bool(c.payload.get("tested", false)):
				EventBus.notify("Untested products cannot legally be displayed!", "error")
				return
			MachineSim.apply_output(Game.state, c.payload, "display:%s" % store_id)
			player.consume_carried()
			Game.log_action("restock", false)
			EventBus.notify("Shelf stocked.", "success")
			return
		EventBus.notify("Only packaged products belong on the shelf.", "warning")
		return
	# No container: pull stock from the warehouse manually.
	var moved_any := false
	for pid: String in DataRegistry.products.keys():
		if InventorySim.sellable_qty(Game.state, store_id, pid) < 6:
			if RetailSim.restock(Game.state, store_id, pid, 6, false) > 0:
				moved_any = true
	if moved_any:
		EventBus.notify("Restocked from warehouse.", "success")
	else:
		EventBus.notify("Nothing in the warehouse to restock with.", "info")
