class_name RangeBuilder
extends RefCounted
## Builds the indoor / outdoor range from primitives (no external assets). Returns walkable bounds
## as Rect2(x, z, width, depth).

static func build(kind: String, root: Node3D) -> Rect2:
	if kind == "outdoor":
		return _outdoor(root)
	return _indoor(root)

static func _env(root: Node3D, outdoor: bool) -> void:
	var e := Environment.new()
	if outdoor:
		var sky := Sky.new()
		sky.sky_material = ProceduralSkyMaterial.new()
		e.background_mode = Environment.BG_SKY
		e.sky = sky
		e.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
		e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
		var sun := DirectionalLight3D.new()
		sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
		sun.light_energy = 1.2
		sun.shadow_enabled = false
		root.add_child(sun)
	else:
		e.background_mode = Environment.BG_COLOR
		e.background_color = Color(0.04, 0.04, 0.05)
		e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		e.ambient_light_color = Color(0.7, 0.72, 0.78)
		e.ambient_light_energy = 0.55
	var we := WorldEnvironment.new()
	we.environment = e
	root.add_child(we)

static func _barrel(root: Node3D, p: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.28
	cm.bottom_radius = 0.28
	cm.height = 0.9
	mi.mesh = cm
	mi.material_override = Defs.mat(Color(0.15, 0.3, 0.6))
	mi.position = p + Vector3(0.0, 0.45, 0.0)
	root.add_child(mi)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.28
	sh.height = 0.9
	cs.shape = sh
	sb.add_child(cs)
	mi.add_child(sb)

static func _indoor(root: Node3D) -> Rect2:
	_env(root, false)
	var w := 12.0
	var l := 34.0
	var h := 4.5
	var zc := 4.0 - l * 0.5
	var wall := Color(0.62, 0.62, 0.65)
	var wood := Color(0.45, 0.35, 0.25)
	Defs.box(root, Vector3(w, 0.2, l), Vector3(0.0, -0.1, zc), Color(0.33, 0.33, 0.35), true)
	Defs.box(root, Vector3(w, 0.2, l), Vector3(0.0, h + 0.1, zc), Color(0.8, 0.8, 0.82), true)
	Defs.box(root, Vector3(0.3, h, l), Vector3(-w * 0.5 - 0.15, h * 0.5, zc), wall, true)
	Defs.box(root, Vector3(0.3, h, l), Vector3(w * 0.5 + 0.15, h * 0.5, zc), wall, true)
	Defs.box(root, Vector3(w + 0.6, h, 0.3), Vector3(0.0, h * 0.5, 4.15), wall, true)
	Defs.box(root, Vector3(w + 0.6, h, 0.3), Vector3(0.0, h * 0.5, 4.0 - l - 0.15), Color(0.2, 0.2, 0.22), true)
	Defs.box(root, Vector3(w, 1.6, 1.5), Vector3(0.0, 0.8, 4.0 - l + 0.75), Color(0.55, 0.45, 0.3), true)
	Defs.box(root, Vector3(1.8, 1.2, 0.1), Vector3(-2.5, 0.6, -6.0), wood, true)
	Defs.box(root, Vector3(0.1, 2.0, 3.0), Vector3(3.5, 1.0, -11.0), wood, true)
	Defs.box(root, Vector3(2.0, 1.0, 0.1), Vector3(-1.0, 0.5, -16.0), wood, true)
	Defs.box(root, Vector3(w, 0.01, 0.05), Vector3(0.0, 0.005, 0.0), Color(0.9, 0.8, 0.1))
	for z in [-1.0, -9.0, -17.0, -25.0]:
		var o := OmniLight3D.new()
		o.position = Vector3(0.0, h - 0.4, z)
		o.omni_range = 13.0
		o.light_energy = 1.2
		root.add_child(o)
		Defs.box(root, Vector3(1.5, 0.05, 0.2), Vector3(0.0, h - 0.03, z), Color(1.0, 1.0, 0.9))
	return Rect2(-5.4, -28.0, 10.8, 31.5)

static func _outdoor(root: Node3D) -> Rect2:
	_env(root, true)
	var earth := Color(0.42, 0.32, 0.22)
	var wood := Color(0.45, 0.35, 0.25)
	Defs.box(root, Vector3(160.0, 0.4, 160.0), Vector3(0.0, -0.2, -45.0), Color(0.28, 0.42, 0.22), true)
	Defs.box(root, Vector3(70.0, 7.0, 8.0), Vector3(0.0, 3.5, -62.0), earth, true)
	Defs.box(root, Vector3(6.0, 4.0, 60.0), Vector3(-24.0, 2.0, -32.0), earth, true)
	Defs.box(root, Vector3(6.0, 4.0, 60.0), Vector3(24.0, 2.0, -32.0), earth, true)
	Defs.box(root, Vector3(2.0, 1.2, 0.1), Vector3(-5.0, 0.6, -8.0), wood, true)
	Defs.box(root, Vector3(0.1, 2.0, 3.0), Vector3(6.0, 1.0, -14.0), wood, true)
	Defs.box(root, Vector3(2.5, 1.0, 0.1), Vector3(-2.0, 0.5, -22.0), wood, true)
	Defs.box(root, Vector3(40.0, 0.01, 0.05), Vector3(0.0, 0.005, 0.0), Color(0.9, 0.8, 0.1))
	_barrel(root, Vector3(-3.0, 0.0, -7.0))
	_barrel(root, Vector3(4.0, 0.0, -12.0))
	_barrel(root, Vector3(-8.0, 0.0, -18.0))
	return Rect2(-20.0, -48.0, 40.0, 52.0)
