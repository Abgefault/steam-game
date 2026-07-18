extends Node
## Loads and validates every data-driven content file at startup.
## All game content (products, machines, districts, events, research,
## objectives, achievements, balance) lives in res://data/*.json.
## Fails loudly with actionable messages when data is malformed.

var products: Dictionary = {}          # id -> product def
var strains: Dictionary = {}           # id -> strain def
var machines: Dictionary = {}          # id -> machine def (per tier entries)
var districts: Dictionary = {}         # id -> district def
var archetypes: Dictionary = {}        # id -> customer archetype
var events: Dictionary = {}            # id -> authored event
var research: Dictionary = {}          # id -> research node
var objectives: Dictionary = {}        # id -> objective def
var achievements: Dictionary = {}      # id -> achievement def
var balance: Dictionary = {}           # flat tuning values
var names_data: Dictionary = {}        # first/last names for people

var validation_errors: PackedStringArray = []


func _ready() -> void:
	load_all()
	if not validation_errors.is_empty():
		for e in validation_errors:
			push_error("[DataRegistry] %s" % e)
		if OS.is_debug_build():
			printerr("DataRegistry found %d data errors." % validation_errors.size())


func load_all() -> void:
	validation_errors.clear()
	products = _load_json_map("res://data/products.json", "products")
	strains = _load_json_map("res://data/strains.json", "strains")
	machines = _load_json_map("res://data/machines.json", "machines")
	districts = _load_json_map("res://data/districts.json", "districts")
	archetypes = _load_json_map("res://data/customers.json", "archetypes")
	events = _load_json_map("res://data/events.json", "events")
	research = _load_json_map("res://data/research.json", "research")
	objectives = _load_json_map("res://data/objectives.json", "objectives")
	achievements = _load_json_map("res://data/achievements.json", "achievements")
	balance = _load_json_raw("res://data/balance.json")
	names_data = _load_json_raw("res://data/names.json")
	_validate()


func bal(key: String, def: float = 0.0) -> float:
	if balance.has(key):
		return float(balance[key])
	validation_errors.append("Missing balance key: %s" % key)
	return def


func bal_i(key: String, def: int = 0) -> int:
	return int(bal(key, float(def)))


func _load_json_raw(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		validation_errors.append("Missing data file: %s" % path)
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		validation_errors.append("Data file is not a JSON object: %s" % path)
		return {}
	return parsed


func _load_json_map(path: String, list_key: String) -> Dictionary:
	var raw := _load_json_raw(path)
	var out: Dictionary = {}
	if not raw.has(list_key) or typeof(raw[list_key]) != TYPE_ARRAY:
		validation_errors.append("%s must contain array '%s'" % [path, list_key])
		return out
	for entry: Variant in raw[list_key]:
		if typeof(entry) != TYPE_DICTIONARY or not entry.has("id"):
			validation_errors.append("%s: entry without 'id': %s" % [path, str(entry).left(80)])
			continue
		var id: String = str(entry["id"])
		if out.has(id):
			validation_errors.append("%s: duplicate id '%s'" % [path, id])
		out[id] = entry
	return out


func _require(cond: bool, msg: String) -> void:
	if not cond:
		validation_errors.append(msg)


func _validate() -> void:
	_require(products.size() >= 24, "Need at least 24 products, found %d" % products.size())
	_require(districts.size() >= 5, "Need at least 5 districts, found %d" % districts.size())
	_require(archetypes.size() >= 8, "Need at least 8 customer archetypes, found %d" % archetypes.size())
	_require(events.size() >= 40, "Need at least 40 events, found %d" % events.size())
	_require(research.size() >= 32, "Need at least 32 research nodes, found %d" % research.size())
	_require(achievements.size() >= 25, "Need at least 25 achievements, found %d" % achievements.size())
	var regular := 0
	var challenge := 0
	var tutorial := 0
	for o: Dictionary in objectives.values():
		match str(o.get("kind", "regular")):
			"tutorial": tutorial += 1
			"challenge": challenge += 1
			_: regular += 1
	_require(regular >= 30, "Need >=30 regular objectives, found %d" % regular)
	_require(challenge >= 15, "Need >=15 challenge objectives, found %d" % challenge)
	_require(tutorial >= 10, "Need a tutorial objective chain, found %d" % tutorial)

	for p: Dictionary in products.values():
		var pid: String = str(p["id"])
		for key in ["name", "category", "desc", "strain", "base_cost", "retail_price",
				"prod_minutes", "batch_size", "quality_potential", "intensity", "wellness",
				"trend", "shelf_life_days", "compliance_risk", "stage_required", "machine",
				"segments", "tradeoff"]:
			_require(p.has(key), "Product %s missing '%s'" % [pid, key])
		if p.has("strain"):
			_require(strains.has(str(p["strain"])), "Product %s references unknown strain '%s'" % [pid, p.get("strain")])
	for r: Dictionary in research.values():
		for pre: Variant in r.get("requires", []):
			_require(research.has(str(pre)), "Research %s requires unknown node '%s'" % [r["id"], pre])
	for e: Dictionary in events.values():
		_require(e.has("title") and e.has("text"), "Event %s missing title/text" % e["id"])
