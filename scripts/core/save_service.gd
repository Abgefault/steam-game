extends Node
## Versioned JSON save system with atomic writes, 5 manual slots,
## autosave and quicksave. Saves live in user://saves/.

const SAVE_DIR := "user://saves"
const SAVE_VERSION := 1
const MANUAL_SLOTS := 5


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func slot_path(slot: String) -> String:
	return "%s/%s.json" % [SAVE_DIR, slot]


## Returns metadata for every existing save file, newest first.
func list_saves() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dir := DirAccess.open(SAVE_DIR)
	if dir == null:
		return out
	for fname in dir.get_files():
		if not fname.ends_with(".json") or fname.ends_with(".tmp.json"):
			continue
		var meta := read_metadata(fname.get_basename())
		if not meta.is_empty():
			out.append(meta)
	out.sort_custom(func(a, b): return float(a.get("timestamp", 0)) > float(b.get("timestamp", 0)))
	return out


func read_metadata(slot: String) -> Dictionary:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("meta"):
		return {"slot": slot, "corrupt": true}
	var meta: Dictionary = parsed["meta"]
	meta["slot"] = slot
	return meta


func save_game(slot: String) -> bool:
	if not Game.in_session:
		return false
	var payload: Dictionary = {
		"save_version": SAVE_VERSION,
		"engine": Engine.get_version_info().string,
		"meta": {
			"company": Game.state.company.name,
			"day": Game.state.day,
			"cash": Game.state.cash,
			"stage": Game.state.stage,
			"stage_name": Game.stage_name(),
			"automation": Game.state.automation_score,
			"playtime": Game.state.playtime_seconds,
			"timestamp": Time.get_unix_time_from_system(),
			"date": Time.get_datetime_string_from_system(false, true),
		},
		"state": Game.serialize(),
	}
	var path := slot_path(slot)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_error("Cannot write save: %s" % tmp)
		return false
	f.store_string(JSON.stringify(payload))
	f.close()
	# Atomic-ish: keep one backup generation, then move tmp into place.
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path),
			ProjectSettings.globalize_path(path + ".bak"))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp),
		ProjectSettings.globalize_path(path))
	EventBus.game_saved.emit(slot)
	EventBus.notify("Game saved (%s)." % slot, "success")
	return true


## Loads a save. Runs migration hooks when the stored version is older.
func load_game(slot: String) -> bool:
	var path := slot_path(slot)
	if not FileAccess.file_exists(path):
		EventBus.notify("Save '%s' not found." % slot, "error")
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("state"):
		EventBus.notify("Save '%s' is invalid or corrupt." % slot, "error")
		return false
	var version := int(parsed.get("save_version", 0))
	var s: Dictionary = parsed["state"]
	s = _migrate(s, version)
	if s.is_empty():
		EventBus.notify("Save '%s' uses an unsupported version." % slot, "error")
		return false
	Game.deserialize(s)
	return true


func autosave() -> void:
	save_game("autosave")


func quicksave() -> void:
	save_game("quicksave")


func quickload() -> bool:
	return load_game("quicksave")


func delete_save(slot: String) -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))


## Migration hooks: transform older save formats into the current one.
func _migrate(s: Dictionary, version: int) -> Dictionary:
	if version > SAVE_VERSION:
		return {}
	# Version 1 is current; earlier development formats are not supported.
	if version < 1:
		return {}
	return s
