class_name MaterialLib
## Cached PBR materials built from the CC0 texture library under
## assets/textures/ (ambientCG, see THIRD_PARTY_LICENSES.md).
## World-space triplanar mapping keeps procedural box geometry seam-free.

static var _cache: Dictionary = {}


static func pbr(id: String, uv_scale: float = 0.35, tint: Color = Color.WHITE,
		triplanar: bool = true, metallic: float = 0.0, rough: float = 1.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%s|%s|%.2f|%.2f" % [id, uv_scale, tint.to_html(), triplanar, metallic, rough]
	if _cache.has(key):
		return _cache[key]
	var m := StandardMaterial3D.new()
	var base := "res://assets/textures/%s/" % id
	var color_tex: Texture2D = load(base + "color.jpg") if ResourceLoader.exists(base + "color.jpg") else null
	if color_tex != null:
		m.albedo_texture = color_tex
	m.albedo_color = tint
	if ResourceLoader.exists(base + "normal.jpg"):
		m.normal_enabled = true
		m.normal_texture = load(base + "normal.jpg")
		m.normal_scale = 1.0
	if ResourceLoader.exists(base + "rough.jpg"):
		m.roughness_texture = load(base + "rough.jpg")
	m.roughness = rough
	m.metallic = metallic
	m.uv1_scale = Vector3(uv_scale, uv_scale, uv_scale)
	if triplanar:
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	_cache[key] = m
	return m


# Convenience wrappers for the game's recurring surfaces.

static func concrete_floor(tint: Color = Color(0.85, 0.85, 0.86)) -> StandardMaterial3D:
	return pbr("Concrete034", 0.3, tint)


static func wood_floor(tint: Color = Color(1, 1, 1)) -> StandardMaterial3D:
	return pbr("WoodFloor051", 0.4, tint)


static func carpet(tint: Color = Color(0.75, 0.8, 0.78)) -> StandardMaterial3D:
	return pbr("Carpet016", 0.5, tint)


static func plaster_wall(tint: Color = Color(0.82, 0.83, 0.8)) -> StandardMaterial3D:
	return pbr("Plaster001", 0.35, tint)


## Neutral gray metal (Metal030) — the workhorse for machinery and fixtures.
## Tint it for accent colors; the red PaintedMetal004 is reserved for the
## classic red-orange pallet racks.
static func painted_metal(tint: Color = Color(1.0, 1.0, 1.0), metallic: float = 0.6) -> StandardMaterial3D:
	return pbr("Metal030", 0.6, tint, true, metallic)


static func red_rack_steel() -> StandardMaterial3D:
	return pbr("PaintedMetal004", 0.6, Color(1, 1, 1), true, 0.5)


static func diamond_plate(tint: Color = Color(0.8, 0.8, 0.82)) -> StandardMaterial3D:
	return pbr("DiamondPlate006C", 0.7, tint, true, 0.75)


static func corrugated(tint: Color = Color(0.55, 0.57, 0.6)) -> StandardMaterial3D:
	return pbr("CorrugatedSteel007A", 0.55, tint, true, 0.05, 1.0)


static func asphalt() -> StandardMaterial3D:
	return pbr("Road007", 0.1, Color(0.9, 0.9, 0.9))


static func sidewalk() -> StandardMaterial3D:
	return pbr("PavingStones128", 0.3, Color(0.95, 0.93, 0.9))


static func bricks(tint: Color = Color(0.85, 0.8, 0.78)) -> StandardMaterial3D:
	return pbr("Bricks097", 0.4, tint)


static func cardboard(tint: Color = Color(1, 1, 1)) -> StandardMaterial3D:
	return pbr("Cardboard004", 1.2, tint)


static func rubber_belt() -> StandardMaterial3D:
	return pbr("Rubber004", 1.0, Color(0.35, 0.35, 0.37))
