class_name FacilityBuilder
## Procedurally constructs the facility building: floors, walls, ceiling,
## lights, storefront, warehouse, office, exterior, and stage-dependent
## decoration. Returns a dictionary of important anchor positions.
##
## Building footprint: x -14..14, z -10..8. Storefront occupies the
## south-east quadrant; production hall the west half; warehouse north-east.

const WALL_H := 4.0

static var machine_positions := {
	"m_cultivation_1": Vector3(-11.5, 0, -6.0),
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
	env.ambient_light_energy = 0.85
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
	glass.albedo_color = Color(0.6, 0.75, 0.8, 0.25)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.roughness = 0.05
	glass.metallic = 0.2
	_box(root, Vector3(5.5, 1.6, 0.1), Vector3(11.0, 2.0, 8.0), glass, false)
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
