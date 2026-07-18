class_name MarketSim
## City demand by category and district, trends, competitor pressure,
## supplier conditions and event modifiers.

const CATEGORIES: PackedStringArray = ["flower", "preroll", "oil", "edible",
	"wellness", "beverage", "limited"]


static func new_market() -> Dictionary:
	var cat_demand: Dictionary = {}
	for c in CATEGORIES:
		cat_demand[c] = 1.0
	return {
		"category_demand": cat_demand,
		"category_history": {},
		"trend_product": "",
		"trend_days": 0,
		"competitor_pressure": 0.2,
		"supplier_price_mult": 1.0,
		"utility_mult": 1.0,
	}


static func category_demand(s: Dictionary, category: String) -> float:
	return float(s.market.category_demand.get(category, 1.0))


static func district_demand(s: Dictionary, district_id: String) -> float:
	var d: Dictionary = DataRegistry.districts.get(district_id, {})
	var seasonal := 1.0 + 0.12 * sin(float(s.day) * TAU / 28.0 + float(d.get("season_phase", 0.0)))
	return seasonal * (1.0 - float(s.market.competitor_pressure) * 0.35)


static func trend_factor(s: Dictionary, product_id: String) -> float:
	return 2.0 if str(s.market.trend_product) == product_id else 1.0


static func utility_multiplier(s: Dictionary) -> float:
	return float(s.market.get("utility_mult", 1.0))


static func supplier_price(s: Dictionary, base: float) -> float:
	return base * float(s.market.supplier_price_mult)


## Daily market drift: random walk on category demand, occasional trends.
static func advance_day(s: Dictionary) -> void:
	var m: Dictionary = s.market
	for c in CATEGORIES:
		var v := float(m.category_demand[c])
		v = clampf(v + randf_range(-0.06, 0.06), 0.6, 1.6)
		m.category_demand[c] = v
		var hist: Array = m.category_history.get(c, [])
		hist.append(v)
		if hist.size() > 7:
			hist.pop_front()
		m.category_history[c] = hist
	# Trends flip every few days.
	if int(m.trend_days) > 0:
		m.trend_days = int(m.trend_days) - 1
		if int(m.trend_days) == 0:
			m.trend_product = ""
	elif randf() < 0.18:
		m.trend_product = DataRegistry.products.keys().pick_random()
		m.trend_days = 2 + randi() % 4
		EventBus.notify("Trending now: %s!" % str(DataRegistry.products[m.trend_product].name), "info")
	# Competitor pressure follows player reputation inversely.
	m.competitor_pressure = clampf(float(m.competitor_pressure) + randf_range(-0.03, 0.035)
		- (float(s.reputation) - 50.0) * 0.0004, 0.05, 0.6)
	# Supplier / utility multipliers decay back toward 1.0 after events.
	m.supplier_price_mult = lerpf(float(m.supplier_price_mult), 1.0, 0.25)
	m.utility_mult = lerpf(float(m.utility_mult), 1.0, 0.25)


## Buy production supplies. kind: seed_units | packaging_units | spare_parts.
static func buy_supplies(s: Dictionary, kind: String, qty: int, automated: bool = false) -> bool:
	var unit_prices := {
		"seed_units": DataRegistry.bal("price_seed_unit", 120.0),
		"packaging_units": DataRegistry.bal("price_packaging_unit", 1.2),
		"spare_parts": DataRegistry.bal("price_spare_part", 160.0),
	}
	if not unit_prices.has(kind):
		return false
	var cost: float = supplier_price(s, float(unit_prices[kind])) * qty
	if not EconomySim.spend(s, cost, "Supplies: %s x%d" % [kind, qty], "purchasing"):
		return false
	s.supplies[kind] = int(s.supplies[kind]) + qty
	Game.log_action("purchasing", automated)
	return true
