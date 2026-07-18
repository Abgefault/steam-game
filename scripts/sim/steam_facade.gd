class_name SteamFacade
## Abstraction over platform achievement/stat services so a Steam SDK can
## later be connected without touching gameplay code. The local build has
## no Steam dependency and fails gracefully into a no-op.

static var _backend: Object = null


static func set_backend(backend: Object) -> void:
	_backend = backend


static func available() -> bool:
	return _backend != null


static func unlock_achievement(id: String) -> void:
	if _backend != null and _backend.has_method("unlock_achievement"):
		_backend.call("unlock_achievement", id)


static func set_stat(id: String, value: float) -> void:
	if _backend != null and _backend.has_method("set_stat"):
		_backend.call("set_stat", id, value)
