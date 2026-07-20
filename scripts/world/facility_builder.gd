class_name FacilityBuilder
## Procedurally constructs the facility building: floors, walls, ceiling,
## lights, storefront, warehouse, office, exterior, and stage-dependent
## decoration. Returns a dictionary of important anchor positions.
##
## Building footprint: x -14..14, z -10..8. Storefront occupies the
## south-east quadrant; production hall the west half; warehouse north-east.

const WALL_H := 4.0

static var machine_positions := {
	"m_cultivation_1": Vector3(-8.6, 0, -8.3),
	"m_conditioning_1": Vector3(-8.0, 0, -6.0),
	"m_processing_1": Vector3(-4.5, 0, -6.0),
	"m_lab_1": Vector3(-11.5, 0, -0.5),
	"m_product_1": Vector3(-8.0, 0, -0.5),
	"m_packaging_1": Vector3(-4.5, 0, -0.5),
}


static func build(root: Node3D) -> Dictionary:
	var anchors: Dictionary = {}
	_environment(root)
	_exterior(root)
	_shell(root)
	_interior(root)
	_props(root)
	_lights(root)
	anchors["entrance"] = Vector3(7.0, 0, 9.5)
	anchors["door"] = Vector3(7.0, 0, 6.5)
	anchors["shelf"] = Vector3(6.0, 0, 3.8)
	anchors["checkout"] = Vector3(4.0, 0, 2.6)
	anchors["exit"] = Vector3(7.0, 0, 12.0)
	anchors["player_spawn"] = Vector3(0.0, 0.1, 1.0)
	anchors["production"] = [Vector3(-8, 0, -3.5), Vector3(-11, 0, -3.5), Vector3(-4.5, 0, -3.5)]
	anchors["warehouse"] = [Vector3(7, 0, -5), Vector3(10, 0, -5)]
	anchors["office"] = [Vector3(11.5, 0, 0.5)]
	return anchors


static func _mat(color: Color, rough: float = 0.9, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m


static func _box(root: Node3D, size: Vector3, pos: Vector3, mat: Material,
		with_collision: bool = true, group: String = "") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	root.add_child(mi)
	if with_collision:
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		col.shape = shape
		body.add_child(col)
		mi.add_child(body)
	if group != "":
		mi.add_to_group(group)
	return mi


static func _environment(root: Node3D) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.3, 0.45, 0.65)
	sky_mat.sky_horizon_color = Color(0.72, 0.74, 0.72)
	sky_mat.ground_bottom_color = Color(0.2, 0.19, 0.17)
	sky_mat.ground_horizon_color = Color(0.58, 0.57, 0.53)
	sky_mat.sun_angle_max = 20.0
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	# SSAO grounds objects in Forward+; ignored gracefully in compatibility.
	env.ssao_enabled = true
	env.ssao_intensity = 1.6
	env.ssao_radius = 1.5
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.04
	env.adjustment_saturation = 1.06
	env.fog_enabled = true
	env.fog_light_color = Color(0.68, 0.71, 0.7)
	env.fog_density = 0.0025
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.04
	var we := WorldEnvironment.new()
	we.environment = env
	root.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-44, 38, 0)
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.95, 0.85)
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 60.0
	root.add_child(sun)


static func _exterior(root: Node3D) -> void:
	# Ground / street.
	_box(root, Vector3(120, 0.2, 120), Vector3(0, -0.1, 0), MaterialLib.asphalt())
	_box(root, Vector3(40, 0.05, 8), Vector3(0, 0.02, 13), MaterialLib.pbr("Road007", 0.09, Color(0.75, 0.75, 0.77)))
	# Sidewalk in front of the store.
	_box(root, Vector3(30, 0.08, 3), Vector3(0, 0.04, 9.6), MaterialLib.sidewalk())
	# Neighboring building silhouettes.
	for i in 3:
		var h := 6.0 + i * 2.0
		_box(root, Vector3(10, h, 8), Vector3(-28.0 + i * 1.5, h / 2.0, -18.0 - i * 6.0),
			MaterialLib.bricks(Color(0.8 + 0.06 * i, 0.72, 0.68)))
	_box(root, Vector3(12, 9, 9), Vector3(26, 4.5, -14), MaterialLib.bricks(Color(0.7, 0.68, 0.66)))
	# Delivery van parked at the dispatch side.
	var van := Node3D.new()
	van.position = Vector3(17.5, 0, 2.0)
	root.add_child(van)
	var van_body := MaterialLib.painted_metal(Color(1.9, 1.92, 1.94), 0.35)
	_box(van, Vector3(2.2, 1.9, 4.6), Vector3(0, 1.15, 0), van_body, true)
	_box(van, Vector3(2.1, 1.1, 1.4), Vector3(0, 0.75, 2.9), van_body, true)
	var wheel_mat := _mat(Color(0.1, 0.1, 0.1), 0.95)
	for wz in [-1.6, 1.4, 2.9]:
		for wx in [-1.0, 1.0]:
			var w := MeshInstance3D.new()
			var wm := CylinderMesh.new()
			wm.top_radius = 0.35
			wm.bottom_radius = 0.35
			wm.height = 0.25
			w.mesh = wm
			w.rotation_degrees.z = 90
			w.position = Vector3(wx, 0.35, wz)
			w.material_override = wheel_mat
			van.add_child(w)
	var sign := Label3D.new()
	sign.text = "GREEN EMPIRE"
	sign.position = Vector3(-1.15, 1.3, 0.2)
	sign.rotation_degrees.y = 90
	sign.font_size = 60
	sign.pixel_size = 0.008
	sign.modulate = Color(0.2, 0.55, 0.3)
	van.add_child(sign)


static func _shell(root: Node3D) -> void:
	# Interior floors per zone.
	_box(root, Vector3(15.6, 0.12, 17.6), Vector3(-6.2, 0.06, -1.2),
		MaterialLib.concrete_floor(), true)                                          # production concrete
	_box(root, Vector3(12.4, 0.12, 6.4), Vector3(7.8, 0.06, 4.6),
		MaterialLib.wood_floor(), true, "stage_floor_store")                         # store wood
	_box(root, Vector3(12.4, 0.12, 8.4), Vector3(7.8, 0.06, -5.0),
		MaterialLib.concrete_floor(Color(0.7, 0.71, 0.73)), true)                    # warehouse
	_box(root, Vector3(12.4, 0.12, 2.8), Vector3(7.8, 0.06, 0.2),
		MaterialLib.carpet(), true)                                                  # office corridor
	# Grime patches that disappear from stage 2 (renovation).
	var grime := MaterialLib.pbr("Concrete034", 0.5, Color(0.32, 0.31, 0.28))
	for pos in [Vector3(-3, 0.13, -4), Vector3(-9, 0.13, 2), Vector3(0, 0.13, -7), Vector3(4, 0.13, 5.5)]:
		_box(root, Vector3(2.5, 0.01, 2.0), pos, grime, false, "stage_grime")
	var wall := MaterialLib.plaster_wall()
	var wall_hi := MaterialLib.plaster_wall(Color(0.9, 0.91, 0.88))
	# Perimeter walls (south wall has door gap at x 5.9..8.1).
	_box(root, Vector3(28.6, WALL_H, 0.3), Vector3(0, WALL_H / 2, -10.0), wall)      # north
	_box(root, Vector3(0.3, WALL_H, 18.3), Vector3(-14.15, WALL_H / 2, -0.95), wall) # west
	_box(root, Vector3(0.3, WALL_H, 18.3), Vector3(14.15, WALL_H / 2, -0.95), wall)  # east
	_box(root, Vector3(19.6, WALL_H, 0.3), Vector3(-4.1, WALL_H / 2, 8.0), wall)     # south left of door
	_box(root, Vector3(6.0, WALL_H, 0.3), Vector3(11.1, WALL_H / 2, 8.0), wall)      # south right of door
	_box(root, Vector3(2.2, WALL_H - 2.4, 0.3), Vector3(7.0, WALL_H - 1.2 + 0.0, 8.0), wall) # door lintel
	# Storefront window band on the south wall (non-colliding glass).
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.7, 0.85, 0.95, 0.22)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic = 0.2
	glass.emission_enabled = true
	glass.emission = Color(0.75, 0.85, 0.95)
	glass.emission_energy_multiplier = 0.35
	_box(root, Vector3(5.5, 1.6, 0.1), Vector3(11.0, 2.0, 8.0), glass, false)
	# Daylight spilling in through the storefront window.
	var window_light := OmniLight3D.new()
	window_light.position = Vector3(11.0, 2.2, 6.5)
	window_light.light_color = Color(0.85, 0.9, 1.0)
	window_light.light_energy = 1.6
	window_light.omni_range = 6.0
	window_light.shadow_enabled = false
	root.add_child(window_light)
	# Interior dividers: store/warehouse vs production (x=1.6), with door gaps.
	_box(root, Vector3(0.3, WALL_H, 6.0), Vector3(1.6, WALL_H / 2, 5.0), wall_hi)
	_box(root, Vector3(0.3, WALL_H, 7.0), Vector3(1.6, WALL_H / 2, -6.5), wall_hi)
	_box(root, Vector3(0.3, WALL_H - 2.4, 3.0), Vector3(1.6, WALL_H - 1.2, 0.5), wall_hi)
	# Store vs warehouse divider (z=1.6) with door gap near x=3.
	_box(root, Vector3(9.0, WALL_H, 0.3), Vector3(9.6, WALL_H / 2, 1.6), wall_hi)
	# Ceiling.
	_box(root, Vector3(28.6, 0.3, 18.3), Vector3(0, WALL_H + 0.15, -0.95),
		MaterialLib.corrugated(Color(0.5, 0.52, 0.55)))
	# Exterior facade sign above the entrance.
	var facade_sign := Label3D.new()
	facade_sign.text = "GREEN EMPIRE"
	facade_sign.position = Vector3(7.0, 4.6, 8.25)
	facade_sign.font_size = 120
	facade_sign.pixel_size = 0.01
	facade_sign.outline_size = 16
	facade_sign.modulate = Color(0.35, 0.8, 0.45)
	root.add_child(facade_sign)


static func _interior(root: Node3D) -> void:
	# Office desk + screen.
	var desk := MaterialLib.wood_floor(Color(0.55, 0.45, 0.36))
	_box(root, Vector3(2.0, 0.06, 0.9), Vector3(11.5, 0.78, 0.4), desk)
	_box(root, Vector3(0.08, 0.78, 0.08), Vector3(10.6, 0.39, 0.1), desk)
	_box(root, Vector3(0.08, 0.78, 0.08), Vector3(12.4, 0.39, 0.1), desk)
	_box(root, Vector3(0.08, 0.78, 0.08), Vector3(10.6, 0.39, 0.7), desk)
	_box(root, Vector3(0.08, 0.78, 0.08), Vector3(12.4, 0.39, 0.7), desk)
	var screen := StandardMaterial3D.new()
	screen.albedo_color = Color(0.1, 0.2, 0.15)
	screen.emission_enabled = true
	screen.emission = Color(0.15, 0.5, 0.3)
	screen.emission_energy_multiplier = 0.8
	_box(root, Vector3(0.7, 0.45, 0.05), Vector3(11.5, 1.15, 0.15), screen, false)
	# Staff room bench (north-east corner of office strip).
	_box(root, Vector3(1.6, 0.45, 0.5), Vector3(13.0, 0.22, 0.9),
		MaterialLib.wood_floor(Color(0.5, 0.55, 0.5)))
	# Waiting bench + plant in store.
	_box(root, Vector3(1.6, 0.45, 0.5), Vector3(12.5, 0.22, 6.8),
		MaterialLib.wood_floor(Color(0.5, 0.42, 0.32)))
	var pot := MeshInstance3D.new()
	var pot_mesh := CylinderMesh.new()
	pot_mesh.top_radius = 0.25
	pot_mesh.bottom_radius = 0.2
	pot_mesh.height = 0.4
	pot.mesh = pot_mesh
	pot.position = Vector3(13.4, 0.2, 5.6)
	pot.material_override = _mat(Color(0.5, 0.3, 0.2), 0.9)
	root.add_child(pot)
	var plant := MeshInstance3D.new()
	var plant_mesh := SphereMesh.new()
	plant_mesh.radius = 0.4
	plant_mesh.height = 0.8
	plant.mesh = plant_mesh
	plant.position = Vector3(13.4, 0.75, 5.6)
	plant.material_override = _mat(Color(0.2, 0.45, 0.22), 0.95)
	root.add_child(plant)
	# Posters (stage >= 3 branding), hidden initially via group toggle.
	for px in [3.0, 9.5]:
		var poster := _box(root, Vector3(1.2, 1.6, 0.05), Vector3(px, 2.2, 7.85),
			_mat(Color(0.25, 0.5, 0.32), 0.6), false, "stage_brand")
		poster.visible = false
	# Boarded-up expansion area hint (west production wall).
	_box(root, Vector3(0.2, 2.6, 3.2), Vector3(-13.9, 1.3, 3.0),
		_mat(Color(0.36, 0.3, 0.22), 1.0), false, "stage_locked")
	var locked_sign := Label3D.new()
	locked_sign.text = "EXPANSION AREA\n(unlocks with company stage)"
	locked_sign.position = Vector3(-13.7, 2.9, 3.0)
	locked_sign.rotation_degrees.y = 90
	locked_sign.font_size = 40
	locked_sign.pixel_size = 0.005
	locked_sign.modulate = Color(0.8, 0.75, 0.6)
	root.add_child(locked_sign)


## Clutter and dressing that makes the halls feel worked-in.
static func _props(root: Node3D) -> void:
	# Painted floor lanes framing the production aisle.
	var lane := _mat(Color(0.85, 0.75, 0.2), 0.9)
	for z in [-7.9, -3.9, 1.2]:
		_box(root, Vector3(11.5, 0.012, 0.09), Vector3(-7.4, 0.13, z), lane, false)
	_box(root, Vector3(0.09, 0.012, 9.0), Vector3(-1.8, 0.13, -3.4), lane, false)
	# Painted zone names on the floor.
	for zone in [["PRODUCTION", Vector3(-5.5, 0.14, -2.6), 0.0],
			["WAREHOUSE", Vector3(7.5, 0.14, -3.0), 0.0],
			["DISPATCH", Vector3(11.5, 0.14, -7.5), 90.0]]:
		var t := Label3D.new()
		t.text = str(zone[0])
		t.position = zone[1]
		t.rotation_degrees = Vector3(-90, zone[2], 0)
		t.font_size = 96
		t.pixel_size = 0.005
		t.modulate = Color(0.9, 0.85, 0.5, 0.32)
		root.add_child(t)
	# Wooden pallets with cardboard stacks (warehouse + dispatch).
	for pos in [Vector3(4.2, 0, -6.8), Vector3(12.2, 0, -6.2), Vector3(3.6, 0, -3.2)]:
		_pallet(root, pos, randf() > 0.3)
	# Blue supply barrels near processing.
	var barrel_mat := MaterialLib.painted_metal(Color(0.35, 0.55, 1.4), 0.45)
	for i in 3:
		var b := MeshInstance3D.new()
		var bm := CylinderMesh.new()
		bm.top_radius = 0.3
		bm.bottom_radius = 0.3
		bm.height = 0.85
		b.mesh = bm
		b.position = Vector3(-2.6 + (i % 2) * 0.7, 0.425, -8.6 + (i >> 1) * 0.7)
		b.material_override = barrel_mat
		root.add_child(b)
		var body := StaticBody3D.new()
		var col := CollisionShape3D.new()
		var shape := CylinderShape3D.new()
		shape.radius = 0.3
		shape.height = 0.85
		col.shape = shape
		body.add_child(col)
		b.add_child(body)
	# Wall conduit run + cable tray along the production north wall.
	var conduit := MaterialLib.painted_metal(Color(1.3, 1.32, 1.35))
	for cy in [2.6, 2.75]:
		_box(root, Vector3(11.0, 0.05, 0.05), Vector3(-7.5, cy, -9.85), conduit, false)
	_box(root, Vector3(11.0, 0.02, 0.3), Vector3(-7.5, 3.3, -9.8), conduit, false)
	# Fire extinguisher by the store door.
	var ext := MeshInstance3D.new()
	var ext_mesh := CylinderMesh.new()
	ext_mesh.top_radius = 0.09
	ext_mesh.bottom_radius = 0.09
	ext_mesh.height = 0.5
	ext.mesh = ext_mesh
	ext.position = Vector3(1.9, 1.1, 6.6)
	ext.material_override = MaterialLib.painted_metal(Color(1.6, 0.25, 0.2), 0.4)
	root.add_child(ext)
	# Store dressing: doormat, pendant lamps, decor plants, leaf posters.
	_box(root, Vector3(1.8, 0.02, 1.0), Vector3(7.0, 0.13, 6.9),
		MaterialLib.pbr("Carpet016", 0.8, Color(0.35, 0.4, 0.38)), false)
	for px in [6.0, 9.5]:
		_pendant(root, Vector3(px, 0, 3.0))
	for pos in [Vector3(3.2, 0, 6.9), Vector3(12.9, 0, 2.3)]:
		var plant := PlantNode.create(true)
		plant.position = pos
		plant.scale = Vector3(1.5, 1.5, 1.5)
		root.add_child(plant)
	var leaf_tex: Texture2D = load("res://assets/textures/plant/leaf.png")
	for poster in [[Vector3(4.6, 2.3, 7.83), 0.0], [Vector3(11.2, 2.3, 7.83), 0.0]]:
		_box(root, Vector3(1.0, 1.4, 0.04), poster[0], _mat(Color(0.16, 0.24, 0.19), 0.7), false)
		var quad := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.8, 0.8)
		quad.mesh = qm
		quad.position = (poster[0] as Vector3) + Vector3(0, 0.15, -0.03)
		quad.rotation_degrees.y = 180.0
		var pm := StandardMaterial3D.new()
		pm.albedo_texture = leaf_tex
		pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		pm.alpha_scissor_threshold = 0.4
		root.add_child(quad)
		quad.material_override = pm
		var caption := Label3D.new()
		caption.text = "GREEN EMPIRE"
		caption.position = (poster[0] as Vector3) + Vector3(0, -0.5, -0.03)
		caption.rotation_degrees.y = 180.0
		caption.font_size = 40
		caption.pixel_size = 0.005
		caption.modulate = Color(0.6, 0.85, 0.65)
		root.add_child(caption)
	# Office: task chair + binder shelf.
	var chair_mat := _mat(Color(0.15, 0.16, 0.18), 0.7)
	_box(root, Vector3(0.45, 0.06, 0.45), Vector3(11.5, 0.48, 1.1), chair_mat)
	_box(root, Vector3(0.45, 0.5, 0.06), Vector3(11.5, 0.78, 1.32), chair_mat, false)
	_cyl_prop(root, 0.04, 0.42, Vector3(11.5, 0.24, 1.1), chair_mat)
	_box(root, Vector3(1.4, 0.04, 0.3), Vector3(13.2, 1.6, 0.2), MaterialLib.wood_floor(Color(0.5, 0.42, 0.34)), false)
	for i in 6:
		_box(root, Vector3(0.12, 0.3, 0.24), Vector3(12.7 + i * 0.16, 1.78, 0.2),
			_mat([Color(0.5, 0.25, 0.2), Color(0.2, 0.35, 0.5), Color(0.25, 0.45, 0.3),
				Color(0.6, 0.5, 0.25)].pick_random(), 0.7), false)
	# Steel I-beam trusses under the ceiling carry the industrial look.
	var beam := MaterialLib.dark_steel(Color(0.3, 0.31, 0.34))
	for bz in [-8.0, -5.0, -2.0, 1.0, 4.0]:
		_box(root, Vector3(28.2, 0.05, 0.3), Vector3(0, WALL_H - 0.42, bz), beam, false)  # bottom flange
		_box(root, Vector3(28.2, 0.34, 0.06), Vector3(0, WALL_H - 0.22, bz), beam, false) # web
		_box(root, Vector3(28.2, 0.05, 0.3), Vector3(0, WALL_H - 0.05, bz), beam, false)  # top flange
	# Baseboards along the perimeter ground the walls.
	var base_mat := MaterialLib.dark_steel(Color(0.25, 0.26, 0.28))
	_box(root, Vector3(28.4, 0.16, 0.06), Vector3(0, 0.2, -9.8), base_mat, false)
	_box(root, Vector3(0.06, 0.16, 18.0), Vector3(-13.95, 0.2, -0.95), base_mat, false)
	_box(root, Vector3(0.06, 0.16, 18.0), Vector3(13.95, 0.2, -0.95), base_mat, false)
	_box(root, Vector3(19.4, 0.16, 0.06), Vector3(-4.1, 0.2, 7.82), base_mat, false)
	# Reflection probes make metals and floors mirror the room (Forward+).
	for probe_conf in [[Vector3(-6, 2, -3), Vector3(16, 4.4, 18)],
			[Vector3(7.8, 2, 4.6), Vector3(13, 4.4, 7)]]:
		var probe := ReflectionProbe.new()
		probe.position = probe_conf[0]
		probe.size = probe_conf[1]
		probe.intensity = 0.6
		probe.update_mode = ReflectionProbe.UPDATE_ONCE
		root.add_child(probe)
	# Fake skylight strips brighten the production hall naturally.
	var sky_mat := StandardMaterial3D.new()
	sky_mat.albedo_color = Color(0.9, 0.95, 1.0)
	sky_mat.emission_enabled = true
	sky_mat.emission = Color(0.85, 0.9, 1.0)
	sky_mat.emission_energy_multiplier = 2.0
	for sx in [-9.0, -4.0]:
		_box(root, Vector3(3.0, 0.04, 1.2), Vector3(sx, WALL_H - 0.02, -4.0), sky_mat, false)


static func _pallet(root: Node3D, pos: Vector3, with_boxes: bool) -> void:
	var wood := MaterialLib.wood_floor(Color(0.75, 0.65, 0.5))
	for i in 5:
		_box(root, Vector3(1.1, 0.04, 0.16), pos + Vector3(0, 0.13, -0.44 + i * 0.22), wood)
	for zoff in [-0.45, 0.0, 0.45]:
		_box(root, Vector3(1.1, 0.09, 0.1), pos + Vector3(0, 0.06, zoff), wood)
	if with_boxes:
		var card := MaterialLib.cardboard()
		_box(root, Vector3(0.5, 0.42, 0.5), pos + Vector3(-0.25, 0.38, -0.1), card)
		_box(root, Vector3(0.45, 0.36, 0.45), pos + Vector3(0.28, 0.35, 0.12), card)
		_box(root, Vector3(0.42, 0.34, 0.42), pos + Vector3(0.0, 0.75, 0.0), card)


static func _pendant(root: Node3D, pos: Vector3) -> void:
	var metal := MaterialLib.painted_metal(Color(0.3, 0.32, 0.34))
	_cyl_prop(root, 0.015, 1.0, pos + Vector3(0, WALL_H - 0.55, 0), metal)
	var shade := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.06
	sm.bottom_radius = 0.22
	sm.height = 0.22
	shade.mesh = sm
	shade.position = pos + Vector3(0, WALL_H - 1.1, 0)
	shade.material_override = metal
	root.add_child(shade)
	var bulb := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.07
	bm.height = 0.14
	bulb.mesh = bm
	bulb.position = pos + Vector3(0, WALL_H - 1.2, 0)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.9, 0.7)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.85, 0.6)
	glow.emission_energy_multiplier = 2.5
	bulb.material_override = glow
	root.add_child(bulb)
	var l := OmniLight3D.new()
	l.position = pos + Vector3(0, WALL_H - 1.3, 0)
	l.light_color = Color(1.0, 0.88, 0.7)
	l.light_energy = 2.0
	l.omni_range = 5.0
	l.shadow_enabled = false
	root.add_child(l)


static func _cyl_prop(root: Node3D, radius: float, height: float, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = mat
	root.add_child(mi)


static func _lights(root: Node3D) -> void:
	# Cool industrial lights in production/warehouse, warm in store/office.
	var spots := [
		[Vector3(-9, 3.8, -5), Color(0.85, 0.9, 1.0)],
		[Vector3(-4, 3.8, -5), Color(0.85, 0.9, 1.0)],
		[Vector3(-9, 3.8, 1), Color(0.85, 0.9, 1.0)],
		[Vector3(-4, 3.8, 1), Color(0.85, 0.9, 1.0)],
		[Vector3(7, 3.8, -5), Color(0.85, 0.9, 1.0)],
		[Vector3(5, 3.8, 4.5), Color(1.0, 0.9, 0.75)],
		[Vector3(9, 3.8, 4.5), Color(1.0, 0.9, 0.75)],
		[Vector3(11.5, 3.8, 0.3), Color(1.0, 0.92, 0.8)],
	]
	for s: Array in spots:
		var l := OmniLight3D.new()
		l.position = s[0]
		l.light_color = s[1]
		l.light_energy = 3.2
		l.omni_range = 10.0
		l.shadow_enabled = false
		root.add_child(l)
		var fixture := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.8, 0.08, 0.25)
		fixture.mesh = fm
		fixture.position = (s[0] as Vector3) + Vector3(0, 0.15, 0)
		var fmat := StandardMaterial3D.new()
		fmat.albedo_color = Color(0.9, 0.9, 0.9)
		fmat.emission_enabled = true
		fmat.emission = s[1]
		fmat.emission_energy_multiplier = 1.5
		fixture.material_override = fmat
		root.add_child(fixture)


## Stage-dependent facility transformation.
static func apply_stage(root: Node3D, stage: int) -> void:
	for n: Node in root.get_tree().get_nodes_in_group("stage_grime"):
		(n as MeshInstance3D).visible = stage < 2
	for n: Node in root.get_tree().get_nodes_in_group("stage_brand"):
		(n as MeshInstance3D).visible = stage >= 3
	for n: Node in root.get_tree().get_nodes_in_group("stage_locked"):
		(n as MeshInstance3D).visible = stage < 4
