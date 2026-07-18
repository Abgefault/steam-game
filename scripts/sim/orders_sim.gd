class_name OrdersSim
## Wholesale orders: rotating daily offers, acceptance, automatic hourly
## dispatch from real warehouse inventory, payment, penalties, reputation.


static func ensure_state(s: Dictionary) -> void:
	if not s.has("wholesale"):
		s["wholesale"] = {"offers": [], "active": [], "seq": 1, "completed": 0}


static func roll_offers(s: Dictionary) -> void:
	ensure_state(s)
	if not "logistics_license" in (s.licenses as Array):
		s.wholesale.offers = []
		return
	var offers: Array = []
	var count := 2 + randi() % 2
	var pids := DataRegistry.products.keys()
	for i in count:
		var pid: String = pids.pick_random()
		var p: Dictionary = DataRegistry.products[pid]
		if int(p.stage_required) > int(s.stage):
			continue
		var qty := (3 + randi() % 8) * 10
		var min_q := randi() % 2
		var unit := float(p.retail_price) * randf_range(0.55, 0.7) * (1.0 + 0.15 * min_q)
		offers.append({
			"id": int(s.wholesale.seq), "product_id": pid, "qty": qty,
			"min_quality": min_q, "deadline_day": int(s.day) + 4 + randi() % 5,
			"payment": snappedf(unit * qty, 1.0),
			"penalty": snappedf(unit * qty * 0.25, 1.0),
			"customer": ["Verdantia Wellness Group", "Harbor Hotels", "Cityline Kiosks",
				"Northside Collective", "Festival Supply Co."].pick_random(),
		})
		s.wholesale.seq = int(s.wholesale.seq) + 1
	s.wholesale.offers = offers


static func accept(s: Dictionary, offer_id: int) -> bool:
	ensure_state(s)
	for o: Dictionary in s.wholesale.offers:
		if int(o.id) == offer_id:
			s.wholesale.offers.erase(o)
			o["delivered"] = 0
			s.wholesale.active.append(o)
			EventBus.notify("Order accepted: %d× %s for %s." % [int(o.qty),
				str(DataRegistry.products[str(o.product_id)].name), str(o.customer)], "success")
			return true
	return false


## Hourly: dispatch pulls matching stock from the warehouse automatically.
static func tick_hour(s: Dictionary, hour: int) -> void:
	ensure_state(s)
	if hour < 8 or hour > 18:
		return
	for o: Dictionary in (s.wholesale.active as Array).duplicate():
		var need := int(o.qty) - int(o.delivered)
		if need <= 0:
			continue
		var res := InventorySim.consume(s, "warehouse", str(o.product_id),
			mini(need, 20), true, int(o.min_quality))
		if int(res.taken) > 0:
			o.delivered = int(o.delivered) + int(res.taken)
			Game.log_action("fulfillment", true)
			if int(o.delivered) >= int(o.qty):
				_complete(s, o)


static func daily_update(s: Dictionary) -> void:
	ensure_state(s)
	for o: Dictionary in (s.wholesale.active as Array).duplicate():
		if int(s.day) > int(o.deadline_day) and int(o.delivered) < int(o.qty):
			s.wholesale.active.erase(o)
			EconomySim.spend(s, float(o.penalty), "Late penalty: %s" % str(o.customer), "fulfillment")
			s.reputation = maxf(0.0, float(s.reputation) - 4.0)
			EventBus.notify("Wholesale order for %s missed its deadline! Penalty paid." % str(o.customer), "error")
	roll_offers(s)


static func _complete(s: Dictionary, o: Dictionary) -> void:
	s.wholesale.active.erase(o)
	s.wholesale.completed = int(s.wholesale.completed) + 1
	EconomySim.earn(s, float(o.payment), "Wholesale: %s" % str(o.customer))
	s.reputation = minf(100.0, float(s.reputation) + 1.5)
	EventBus.notify("Wholesale order for %s completed! +$%d." % [str(o.customer), int(o.payment)], "success")
