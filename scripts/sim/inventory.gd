class_name InventorySim
## Finished-goods lot tracking: lot numbers, expiry, testing status,
## reservations, transfers, FEFO consumption.


## location: "warehouse", "store:<store_id>" (backroom) or "display:<store_id>".
static func make_lot(s: Dictionary, product_id: String, qty: int, quality: int,
		tested: bool, location: String = "warehouse") -> Dictionary:
	var p: Dictionary = DataRegistry.products.get(product_id, {})
	var lot := {
		"id": int(s.lot_seq),
		"lot_number": "VG-%s-%04d" % [str(s.day).pad_zeros(3), int(s.lot_seq)],
		"product_id": product_id,
		"qty": qty,
		"quality": quality,
		"day_created": int(s.day),
		"day_expires": int(s.day) + int(p.get("shelf_life_days", 14)),
		"tested": tested,
		"unit_cost": float(p.get("base_cost", 1.0)),
		"location": location,
		"reserved": 0,
		"history": [{"day": s.day, "what": "created", "where": location}],
	}
	s.lot_seq = int(s.lot_seq) + 1
	s.lots.append(lot)
	EventBus.lot_created.emit(lot)
	EventBus.inventory_changed.emit()
	return lot


static func lots_at(s: Dictionary, location: String, product_id: String = "") -> Array:
	var out: Array = []
	for lot: Dictionary in s.lots:
		if str(lot.location) != location:
			continue
		if product_id != "" and str(lot.product_id) != product_id:
			continue
		out.append(lot)
	return out


## Sellable units of a product on a store's display (tested + not expired).
static func sellable_qty(s: Dictionary, store_id: String, product_id: String) -> int:
	var total := 0
	for lot: Dictionary in lots_at(s, "display:%s" % store_id, product_id):
		if bool(lot.tested) and int(lot.day_expires) > int(s.day):
			total += int(lot.qty) - int(lot.reserved)
	return total


## Consume units FEFO (first expiring first out). Returns
## {"taken": int, "quality_sum": int, "cost": float}.
static func consume(s: Dictionary, location: String, product_id: String, qty: int,
		require_tested: bool = true, min_quality: int = 0) -> Dictionary:
	var candidates: Array = []
	for lot: Dictionary in lots_at(s, location, product_id):
		if require_tested and not bool(lot.tested):
			continue
		if int(lot.day_expires) <= int(s.day):
			continue
		if int(lot.quality) < min_quality:
			continue
		candidates.append(lot)
	candidates.sort_custom(func(a, b): return int(a.day_expires) < int(b.day_expires))
	var taken := 0
	var quality_sum := 0
	var cost := 0.0
	for lot: Dictionary in candidates:
		if taken >= qty:
			break
		var avail := int(lot.qty) - int(lot.reserved)
		var take := mini(avail, qty - taken)
		if take <= 0:
			continue
		lot.qty = int(lot.qty) - take
		taken += take
		quality_sum += int(lot.quality) * take
		cost += float(lot.unit_cost) * take
		lot.history.append({"day": s.day, "what": "consumed", "qty": take})
	_prune(s)
	if taken > 0:
		EventBus.inventory_changed.emit()
	return {"taken": taken, "quality_sum": quality_sum, "cost": cost}


## Move up to qty units of a product between locations (FEFO order).
## Creates a child lot at the destination preserving lot identity fields.
static func transfer(s: Dictionary, from_loc: String, to_loc: String,
		product_id: String, qty: int) -> int:
	var candidates: Array = lots_at(s, from_loc, product_id)
	candidates.sort_custom(func(a, b): return int(a.day_expires) < int(b.day_expires))
	var moved := 0
	for lot: Dictionary in candidates:
		if moved >= qty:
			break
		var avail := int(lot.qty) - int(lot.reserved)
		var take := mini(avail, qty - moved)
		if take <= 0:
			continue
		if take == int(lot.qty):
			lot.location = to_loc
			lot.history.append({"day": s.day, "what": "moved", "where": to_loc})
		else:
			lot.qty = int(lot.qty) - take
			var child: Dictionary = lot.duplicate(true)
			child.id = int(s.lot_seq)
			s.lot_seq = int(s.lot_seq) + 1
			child.qty = take
			child.reserved = 0
			child.location = to_loc
			child.history.append({"day": s.day, "what": "split-moved", "where": to_loc})
			s.lots.append(child)
		moved += take
	_prune(s)
	if moved > 0:
		EventBus.inventory_changed.emit()
	return moved


static func reserve(s: Dictionary, location: String, product_id: String, qty: int,
		min_quality: int = 0) -> int:
	var candidates: Array = []
	for lot: Dictionary in lots_at(s, location, product_id):
		if bool(lot.tested) and int(lot.day_expires) > int(s.day) and int(lot.quality) >= min_quality:
			candidates.append(lot)
	candidates.sort_custom(func(a, b): return int(a.day_expires) < int(b.day_expires))
	var reserved := 0
	for lot: Dictionary in candidates:
		if reserved >= qty:
			break
		var avail := int(lot.qty) - int(lot.reserved)
		var take := mini(avail, qty - reserved)
		lot.reserved = int(lot.reserved) + take
		reserved += take
	return reserved


static func total_qty(s: Dictionary, product_id: String = "") -> int:
	var total := 0
	for lot: Dictionary in s.lots:
		if product_id == "" or str(lot.product_id) == product_id:
			total += int(lot.qty)
	return total


## Remove expired lots; returns units wasted. Called at day rollover.
static func expire_lots(s: Dictionary, new_day: int) -> int:
	var wasted := 0
	for lot: Dictionary in s.lots:
		if int(lot.day_expires) <= new_day and int(lot.qty) > 0:
			wasted += int(lot.qty)
			lot.qty = 0
			lot.reserved = 0
			lot.history.append({"day": new_day, "what": "expired"})
	if wasted > 0:
		s.daily.wasted_units += wasted
		s.compliance = maxf(0.0, float(s.compliance) - minf(4.0, wasted * 0.05))
		EventBus.notify("%d units expired and were disposed." % wasted, "warning")
		EventBus.inventory_changed.emit()
	_prune(s)
	return wasted


static func _prune(s: Dictionary) -> void:
	s.lots = s.lots.filter(func(l): return int(l.qty) > 0)
