class_name CityBuilder
## Builds a believable city block around the Green Empire storefront: a main
## avenue with a crosswalk, textured buildings (offices, brick blocks, glass
## towers) lining both sides, street furniture, parked cars, trees and
## planters. Everything is static background scenery (distance-culled).
##
## Coordinate frame matches FacilityBuilder: the shop front faces +Z (south),
## the sidewalk sits at ~z=9.6 and the avenue runs east-west at z≈15.

const FACADES := ["Facade006", "Facade018A", "Facade019A", "Facade012"]


static func build(root: Node3D) -> void:
	_ground(root)
	_buildings(root)
	_street_furniture(root)
	_vehicles(root)
	_greenery(root)


static func _mat(color: Color, rough := 0.9, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m


static func _box(root: Node3D, size: Vector3, pos: Vector3, mat: Material,
		collide := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	root.add_child(mi)
	if collide:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		mi.add_child(body)
	return mi


static func _cyl(root: Node3D, r: float, h: float, pos: Vector3, mat: Material,
		horizontal := false) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = r
	mesh.bottom_radius = r
	mesh.height = h
	mi.mesh = mesh
	mi.position = pos
	if horizontal:
		mi.rotation_degrees.x = 90
	mi.material_override = mat
	root.add_child(mi)


# ------------------------------------------------------------------ ground

static func _ground(root: Node3D) -> void:
	# Large asphalt ground plane already exists from FacilityBuilder; add the
	# avenue, opposite sidewalk, road markings and a crosswalk in front.
	_box(root, Vector3(140, 0.04, 12), Vector3(0, 0.04, 18), MaterialLib.asphalt())
	# Far sidewalk across the avenue.
	_box(root, Vector3(140, 0.12, 5), Vector3(0, 0.06, 26.5), MaterialLib.sidewalk())
	# Curbs.
	var curb := MaterialLib.city_concrete(Color(0.7, 0.7, 0.68))
	_box(root, Vector3(140, 0.22, 0.4), Vector3(0, 0.11, 11.9), curb)
	_box(root, Vector3(140, 0.22, 0.4), Vector3(0, 0.11, 24.0), curb)
	# Centre lane dashes.
	var paint := _mat(Color(0.85, 0.82, 0.4), 0.7)
	for x in range(-60, 61, 6):
		_box(root, Vector3(2.2, 0.01, 0.16), Vector3(x, 0.07, 18.0), paint, false)
	# Zebra crossing in front of the store.
	for i in 7:
		_box(root, Vector3(0.55, 0.012, 11.0), Vector3(4.0 + i * 0.9, 0.075, 18.0),
			_mat(Color(0.9, 0.9, 0.88), 0.6), false)


# ---------------------------------------------------------------- buildings

static func _building(root: Node3D, footprint: Vector2, height: float, pos: Vector3,
		facade_id: String, tint: Color, lit: bool) -> void:
	var mat := MaterialLib.facade(facade_id, tint, 13.0, lit)
	_box(root, Vector3(footprint.x, height, footprint.y),
		Vector3(pos.x, height / 2.0, pos.z), mat, true)
	# Parapet + roof cap.
	var cap := MaterialLib.city_concrete(tint.darkened(0.2))
	_box(root, Vector3(footprint.x + 0.4, 0.5, footprint.y + 0.4),
		Vector3(pos.x, height + 0.2, pos.z), cap)
	# A little rooftop clutter (HVAC boxes, a vent).
	var hvac := MaterialLib.painted_metal(Color(0.85, 0.86, 0.88))
	for i in (2 if footprint.x > 8 else 1):
		_box(root, Vector3(1.6, 0.9, 1.4),
			Vector3(pos.x - footprint.x * 0.25 + i * footprint.x * 0.4,
				height + 0.9, pos.z), hvac)
	_cyl(root, 0.3, 0.8, Vector3(pos.x + footprint.x * 0.3, height + 0.85, pos.z),
		MaterialLib.dark_steel())
	# Ground-floor entrance canopy for street presence.
	if footprint.y > 6.0:
		_box(root, Vector3(3.0, 0.15, 1.2), Vector3(pos.x, 2.8, pos.z + footprint.y / 2.0 + 0.5),
			MaterialLib.painted_metal(Color(0.3, 0.32, 0.35)))


static func _buildings(root: Node3D) -> void:
	# Row across the avenue (facing the shop), varied heights and facades.
	var across := [
		[Vector2(12, 10), 26.0, "Facade006", Color(0.9, 0.95, 1.0)],
		[Vector2(9, 9), 34.0, "Facade019A", Color(0.85, 0.88, 0.92)],
		[Vector2(11, 10), 20.0, "Facade018A", Color(0.95, 0.85, 0.8)],
		[Vector2(10, 9), 28.0, "Facade006", Color(0.88, 0.92, 0.96)],
		[Vector2(8, 9), 40.0, "Facade019A", Color(0.8, 0.82, 0.85)],
		[Vector2(12, 10), 22.0, "Facade018A", Color(0.9, 0.82, 0.76)],
	]
	var x := -34.0
	for b: Array in across:
		var fp: Vector2 = b[0]
		_building(root, fp, b[1], Vector3(x, 0, 31.0 + randf_range(-1.0, 1.0)),
			b[2], b[3], false)
		x += fp.x + randf_range(1.5, 3.0)
	# Buildings flanking the shop on the same side (left and right of it).
	_building(root, Vector2(14, 12), 24.0, Vector3(-26, 0, 2.0), "Facade018A",
		Color(0.92, 0.84, 0.78), false)
	_building(root, Vector2(13, 14), 30.0, Vector3(28, 0, 1.0), "Facade006",
		Color(0.88, 0.92, 0.97), false)
	_building(root, Vector2(16, 16), 18.0, Vector3(-30, 0, -22.0), "Facade019A",
		Color(0.85, 0.87, 0.9), false)
	_building(root, Vector2(18, 14), 26.0, Vector3(30, 0, -20.0), "Facade018A",
		Color(0.9, 0.82, 0.77), false)
	# Distant skyline behind, windows lit, to give the city depth.
	var sky := -60.0
	for i in 9:
		var h := randf_range(30.0, 70.0)
		var w := randf_range(10.0, 18.0)
		_building(root, Vector2(w, 12), h, Vector3(-55.0 + i * 14.0, 0, sky - randf_range(0, 20)),
			FACADES.pick_random(), Color(0.7, 0.74, 0.8), true)
	for i in 6:
		var h := randf_range(26.0, 55.0)
		_building(root, Vector2(12, 12), h, Vector3(-70.0 + i * 3.0, 0, 55.0 + randf_range(0, 25)),
			"Facade012", Color(0.75, 0.75, 0.82), true)


# ----------------------------------------------------------- street furniture

static func _street_furniture(root: Node3D) -> void:
	var pole_mat := MaterialLib.dark_steel(Color(0.24, 0.25, 0.27))
	# Street lamps along both sidewalks.
	for x in range(-40, 41, 12):
		_lamp(root, Vector3(x, 0, 11.2), pole_mat, 1.0)
		_lamp(root, Vector3(x, 0, 24.4), pole_mat, -1.0)
	# Bench + bins + a bus shelter near the shop.
	_bench(root, Vector3(-3.5, 0, 10.6))
	_bench(root, Vector3(14.0, 0, 10.6))
	_bin(root, Vector3(-6.0, 0, 10.8), pole_mat)
	_bin(root, Vector3(10.0, 0, 10.8), pole_mat)
	_bus_stop(root, Vector3(-14.0, 0, 10.7))
	# Traffic light at the crossing.
	_traffic_light(root, Vector3(2.5, 0, 11.4), pole_mat)
	# Fire hydrant.
	var hy := MaterialLib.painted_metal(Color(1.5, 0.3, 0.25), 0.4)
	_cyl(root, 0.14, 0.5, Vector3(-8.5, 0.25, 10.9), hy)
	_box(root, Vector3(0.34, 0.12, 0.14), Vector3(-8.5, 0.5, 10.9), hy)


static func _lamp(root: Node3D, base: Vector3, mat: Material, dir: float) -> void:
	_cyl(root, 0.08, 5.0, base + Vector3(0, 2.5, 0), mat)
	_box(root, Vector3(0.1, 0.1, 1.4), base + Vector3(0, 5.0, dir * 0.7), mat)
	var head := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.4, 0.16, 0.5)
	head.mesh = hm
	head.position = base + Vector3(0, 4.95, dir * 1.3)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.92, 0.75)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.88, 0.65)
	glow.emission_energy_multiplier = 3.0
	head.material_override = glow
	root.add_child(head)
	var l := OmniLight3D.new()
	l.position = base + Vector3(0, 4.7, dir * 1.3)
	l.light_color = Color(1.0, 0.9, 0.72)
	l.light_energy = 2.5
	l.omni_range = 8.0
	l.shadow_enabled = false
	root.add_child(l)


static func _bench(root: Node3D, pos: Vector3) -> void:
	var wood := MaterialLib.wood_floor(Color(0.55, 0.42, 0.3))
	var steel := MaterialLib.dark_steel()
	_box(root, Vector3(1.8, 0.08, 0.5), pos + Vector3(0, 0.45, 0), wood)
	_box(root, Vector3(1.8, 0.5, 0.08), pos + Vector3(0, 0.7, -0.21), wood)
	for sx in [-0.75, 0.75]:
		_box(root, Vector3(0.08, 0.45, 0.5), pos + Vector3(sx, 0.22, 0), steel)


static func _bin(root: Node3D, pos: Vector3, mat: Material) -> void:
	_cyl(root, 0.22, 0.7, pos + Vector3(0, 0.35, 0), mat)
	_cyl(root, 0.24, 0.06, pos + Vector3(0, 0.72, 0), MaterialLib.dark_steel(Color(0.15, 0.16, 0.18)))


static func _bus_stop(root: Node3D, pos: Vector3) -> void:
	var steel := MaterialLib.dark_steel(Color(0.3, 0.31, 0.33))
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.7, 0.82, 0.9, 0.25)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic = 0.3
	for sx in [-1.6, 1.6]:
		_cyl(root, 0.05, 2.4, pos + Vector3(sx, 1.2, -0.6), steel)
	_box(root, Vector3(3.6, 0.1, 1.4), pos + Vector3(0, 2.45, 0), steel)          # roof
	_box(root, Vector3(3.4, 1.9, 0.05), pos + Vector3(0, 1.2, -1.2), glass, false) # back glass
	_box(root, Vector3(1.6, 0.08, 0.35), pos + Vector3(0, 0.5, -0.9), steel)       # bench
	var sign := Label3D.new()
	sign.text = "VERDANTIA TRANSIT"
	sign.position = pos + Vector3(0, 2.75, 0)
	sign.font_size = 40
	sign.pixel_size = 0.006
	sign.modulate = Color(0.7, 0.85, 0.7)
	root.add_child(sign)


static func _traffic_light(root: Node3D, pos: Vector3, mat: Material) -> void:
	_cyl(root, 0.08, 5.5, pos + Vector3(0, 2.75, 0), mat)
	_box(root, Vector3(2.6, 0.1, 0.1), pos + Vector3(1.3, 5.4, 0), mat)
	var housing := MaterialLib.dark_steel(Color(0.12, 0.12, 0.13))
	_box(root, Vector3(0.24, 0.7, 0.24), pos + Vector3(2.4, 5.0, 0), housing)
	var colors := [Color(0.9, 0.15, 0.1), Color(0.95, 0.75, 0.15), Color(0.2, 0.85, 0.3)]
	for i in 3:
		var lens := MeshInstance3D.new()
		var lm := SphereMesh.new()
		lm.radius = 0.08
		lm.height = 0.16
		lens.mesh = lm
		lens.position = pos + Vector3(2.4, 5.2 - i * 0.22, 0.12)
		var gm := StandardMaterial3D.new()
		gm.albedo_color = colors[i]
		gm.emission_enabled = i == 2
		gm.emission = colors[i]
		gm.emission_energy_multiplier = 2.0 if i == 2 else 0.0
		lens.material_override = gm
		root.add_child(lens)


# ----------------------------------------------------------------- vehicles

static func _vehicles(root: Node3D) -> void:
	var palette := [Color(0.7, 0.1, 0.1), Color(0.1, 0.2, 0.5), Color(0.9, 0.9, 0.92),
		Color(0.1, 0.1, 0.12), Color(0.3, 0.5, 0.3), Color(0.6, 0.6, 0.62)]
	# Cars parked along the near curb (facing east), spaced out.
	var spots := [-38.0, -30.0, -22.0, 20.0, 27.0, 34.0]
	for i in spots.size():
		_car(root, Vector3(spots[i], 0, 12.9), palette[i % palette.size()],
			i % 2 == 0)
	# A couple across the avenue.
	_car(root, Vector3(-6.0, 0, 23.2), palette.pick_random(), false)
	_car(root, Vector3(8.0, 0, 23.2), palette.pick_random(), true)


static func _car(root: Node3D, pos: Vector3, color: Color, flip: bool) -> void:
	var car := Node3D.new()
	car.position = pos
	car.rotation_degrees.y = 90 if not flip else -90
	root.add_child(car)
	var body := MaterialLib.pbr("Metal009", 1.2, color * 1.4, true, 0.35, 1.0)
	body.clearcoat_enabled = true
	body.clearcoat = 0.7
	_box(car, Vector3(1.8, 0.7, 4.2), Vector3(0, 0.55, 0), body, true)      # lower body
	_box(car, Vector3(1.7, 0.6, 2.2), Vector3(0, 1.05, -0.1), body)         # cabin
	# Windows.
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.1, 0.13, 0.18)
	glass.metallic = 0.5
	glass.roughness = 0.1
	_box(car, Vector3(1.72, 0.5, 2.0), Vector3(0, 1.08, -0.1), glass)
	# Wheels.
	var tyre := _mat(Color(0.06, 0.06, 0.07), 0.9)
	for wz in [-1.3, 1.3]:
		for wx in [-0.9, 0.9]:
			var w := MeshInstance3D.new()
			var wm := CylinderMesh.new()
			wm.top_radius = 0.34
			wm.bottom_radius = 0.34
			wm.height = 0.22
			w.mesh = wm
			w.rotation_degrees.z = 90
			w.position = Vector3(wx, 0.34, wz)
			w.material_override = tyre
			car.add_child(w)
	# Head/tail lights.
	var head := StandardMaterial3D.new()
	head.albedo_color = Color(1, 1, 0.9)
	head.emission_enabled = true
	head.emission = Color(1, 1, 0.85)
	head.emission_energy_multiplier = 0.6
	for hx in [-0.6, 0.6]:
		_box(car, Vector3(0.3, 0.16, 0.06), Vector3(hx, 0.6, 2.12), head)
	var tail := StandardMaterial3D.new()
	tail.albedo_color = Color(0.6, 0.05, 0.05)
	tail.emission_enabled = true
	tail.emission = Color(0.7, 0.05, 0.05)
	tail.emission_energy_multiplier = 0.5
	for hx in [-0.6, 0.6]:
		_box(car, Vector3(0.3, 0.16, 0.06), Vector3(hx, 0.6, -2.12), tail)


# ------------------------------------------------------------------ greenery

static func _greenery(root: Node3D) -> void:
	# Street trees in planters along both sidewalks.
	for x in range(-36, 41, 12):
		_tree(root, Vector3(x + 6, 0, 10.9))
		_tree(root, Vector3(x + 6, 0, 24.7))
	# Planters flanking the store entrance.
	for px in [4.0, 10.0]:
		_planter(root, Vector3(px, 0, 9.9))


static func _tree(root: Node3D, pos: Vector3) -> void:
	var bark := MaterialLib.pbr("WoodFloor051", 1.5, Color(0.4, 0.3, 0.22), true)
	_cyl(root, 0.16, 2.6, pos + Vector3(0, 1.3, 0), bark)
	var leaf := StandardMaterial3D.new()
	leaf.albedo_color = Color(0.24, 0.4, 0.2).lerp(Color(0.35, 0.5, 0.24), randf())
	leaf.roughness = 0.95
	for i in 4:
		var blob := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = randf_range(0.9, 1.3)
		sm.height = sm.radius * 2.0
		blob.mesh = sm
		blob.position = pos + Vector3(randf_range(-0.5, 0.5), 2.7 + randf_range(0, 0.8),
			randf_range(-0.5, 0.5))
		blob.material_override = leaf
		root.add_child(blob)
	# Small square planter base.
	_box(root, Vector3(1.0, 0.3, 1.0), pos + Vector3(0, 0.15, 0),
		MaterialLib.city_concrete(Color(0.6, 0.6, 0.58)))


static func _planter(root: Node3D, pos: Vector3) -> void:
	_box(root, Vector3(0.8, 0.45, 0.8), pos + Vector3(0, 0.22, 0),
		MaterialLib.city_concrete(Color(0.7, 0.68, 0.64)))
	var plant := PlantNode.create(false)
	plant.position = pos + Vector3(0, 0.45, 0)
	plant.scale = Vector3(1.3, 1.3, 1.3)
	root.add_child(plant)
