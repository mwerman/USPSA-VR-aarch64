class_name Gun
extends Node3D
## Procedural pistol: slide, mag, chamber state, slide lock, rack, collimated-style red dot.
## Local frame: origin at grip, barrel points -Z, up is +Y.

signal shot(muzzle_xf: Transform3D)
signal sfx(key: String, pos: Vector3)

const RACK_THRESHOLD := 0.85
const SLIDE_Y := 0.032

var cfg: Dictionary = {}
var enabled := true
var head: Node3D
var world: Node3D
var mag: Mag = null
var chambered := false
var slide_locked := false
var slide_t := 0.0
var slide_grabbed := false

var kick: Node3D
var frame_node: Node3D
var slide_node: Node3D
var muzzle: Marker3D
var flash: Node3D
var optic: Node3D
var dot: MeshInstance3D
var win := Vector2.ZERO
var win_z := 0.0
var _slide_rest := Vector3.ZERO
var _tween: Tween
var _rack_ref := 0.0
var _rack_max := 0.0
var muz: Dictionary = {}
var ring: MeshInstance3D
var ring_ok := false
var dot_mat: StandardMaterial3D
var ret_style := 0
var ret_color := Color(1.0, 0.1, 0.05)
var ret_bright := 1.0
var malf_rate := 0.0
var jammed := false
var _brass: Array = []

func build(gun_name: String, optic_name: String, muzzle_name: String = "None") -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	mag = null
	chambered = false
	slide_locked = false
	slide_t = 0.0
	slide_grabbed = false
	jammed = false
	optic = null
	dot = null
	ring = null
	dot_mat = null
	cfg = Defs.GUNS[gun_name]
	var oc: Dictionary = Defs.OPTICS[optic_name]
	var s: Vector3 = cfg["slide"]
	var g: Vector3 = cfg["grip"]
	var col: Color = cfg["color"]
	var fcol: Color = cfg["frame_color"]
	kick = Node3D.new()
	add_child(kick)
	frame_node = Node3D.new()
	kick.add_child(frame_node)
	Defs.box(frame_node, g, Vector3(0.0, -g.y * 0.5 + 0.0025, 0.005), fcol)
	var dc := s.z - 0.04
	Defs.box(frame_node, Vector3(0.028, 0.026, dc), Vector3(0.0, 0.014, 0.01 - dc * 0.5), fcol)
	Defs.box(frame_node, Vector3(0.008, 0.004, 0.045), Vector3(0.0, -0.018, -0.042), fcol)
	Defs.box(frame_node, Vector3(0.008, 0.022, 0.004), Vector3(0.0, -0.008, -0.064), fcol)
	Defs.box(frame_node, Vector3(0.006, 0.020, 0.006), Vector3(0.0, -0.008, -0.022), Color(0.05, 0.05, 0.05))
	muzzle = Marker3D.new()
	muzzle.position = Vector3(0.0, SLIDE_Y, 0.027 - s.z)
	frame_node.add_child(muzzle)
	flash = Node3D.new()
	flash.visible = false
	muzzle.add_child(flash)
	var fm := MeshInstance3D.new()
	var fs := SphereMesh.new()
	fs.radius = 0.03
	fs.height = 0.06
	fm.mesh = fs
	var fmat := StandardMaterial3D.new()
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.albedo_color = Color(1.0, 0.85, 0.4)
	fm.material_override = fmat
	flash.add_child(fm)
	var fl := OmniLight3D.new()
	fl.light_energy = 3.0
	fl.omni_range = 5.0
	flash.add_child(fl)
	slide_node = Node3D.new()
	slide_node.position = Vector3(0.0, SLIDE_Y, 0.03 - s.z * 0.5)
	_slide_rest = slide_node.position
	kick.add_child(slide_node)
	Defs.box(slide_node, s, Vector3.ZERO, col)
	for i in 3:
		Defs.box(slide_node, Vector3(s.x + 0.001, s.y * 0.7, 0.002), Vector3(0.0, 0.0, s.z * 0.5 - 0.012 - i * 0.006), Color(0.03, 0.03, 0.03))
	muz = Defs.MUZZLES[muzzle_name]
	var mlen: float = muz["len"]
	if mlen > 0.0:
		var mr: float = muz["r"]
		var mcol: Color = muz["color"]
		var cyl := MeshInstance3D.new()
		var ccm := CylinderMesh.new()
		ccm.top_radius = mr
		ccm.bottom_radius = mr
		ccm.height = mlen
		cyl.mesh = ccm
		cyl.material_override = Defs.mat(mcol)
		cyl.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		cyl.position = Vector3(0.0, SLIDE_Y, 0.031 - s.z - mlen * 0.5)
		frame_node.add_child(cyl)
		var nports: int = muz["ports"]
		for i in nports:
			Defs.box(frame_node, Vector3(mr * 1.3, 0.004, 0.006), Vector3(0.0, SLIDE_Y + mr, 0.027 - s.z - 0.012 - i * 0.012), Color(0.0, 0.0, 0.0))
		flash.position = Vector3(0.0, 0.0, -mlen)
		flash.scale = Vector3.ONE * float(muz["flash"])
	var moa: float = oc["moa"]
	if moa <= 0.0:
		Defs.box(slide_node, Vector3(0.004, 0.008, 0.005), Vector3(0.0, s.y * 0.5 + 0.004, -s.z * 0.5 + 0.012), Color(0.05, 0.05, 0.05))
		Defs.box(slide_node, Vector3(0.005, 0.008, 0.006), Vector3(-0.007, s.y * 0.5 + 0.004, s.z * 0.5 - 0.008), Color(0.05, 0.05, 0.05))
		Defs.box(slide_node, Vector3(0.005, 0.008, 0.006), Vector3(0.007, s.y * 0.5 + 0.004, s.z * 0.5 - 0.008), Color(0.05, 0.05, 0.05))
	else:
		_build_optic(oc, s)
	_apply_reticle()

func _build_optic(oc: Dictionary, s: Vector3) -> void:
	var b: Vector3 = oc["body"]
	win = oc["win"]
	var dcol: Color = oc["color"]
	optic = Node3D.new()
	optic.position = Vector3(0.0, s.y * 0.5 + b.y * 0.5 - 0.001, s.z * 0.5 - b.z * 0.5 - 0.004)
	slide_node.add_child(optic)
	var bc := Color(0.12, 0.12, 0.13)
	Defs.box(optic, Vector3(b.x, 0.006, b.z), Vector3(0.0, -b.y * 0.5 + 0.003, 0.0), bc)
	Defs.box(optic, Vector3(0.004, b.y, b.z), Vector3(-b.x * 0.5 + 0.002, 0.0, 0.0), bc)
	Defs.box(optic, Vector3(0.004, b.y, b.z), Vector3(b.x * 0.5 - 0.002, 0.0, 0.0), bc)
	Defs.box(optic, Vector3(b.x, 0.005, b.z), Vector3(0.0, b.y * 0.5 - 0.0025, 0.0), bc)
	win_z = -b.z * 0.5 + 0.006
	var glass := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = win
	glass.mesh = q
	var gm := StandardMaterial3D.new()
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.albedo_color = Color(0.6, 0.85, 1.0, 0.12)
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.material_override = gm
	glass.position = Vector3(0.0, 0.0, win_z)
	optic.add_child(glass)
	# The dot sits 50 m down the optic axis (so it has no stereo disparity / parallax) and is only
	# shown while the eye's line to it passes through the window.
	dot = MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radial_segments = 12
	sm.rings = 6
	dot.mesh = sm
	var dm := StandardMaterial3D.new()
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.albedo_color = dcol
	dm.no_depth_test = true
	dm.render_priority = 100
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dot.material_override = dm
	dot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dot.scale = Vector3.ONE * (float(oc["moa"]) * 0.01454)
	dot.position = Vector3(0.0, 0.0, -50.0)
	dot.visible = false
	optic.add_child(dot)
	dot_mat = dm
	ring_ok = bool(oc.get("ring", false))
	if ring_ok:
		ring = MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.225
		tm.outer_radius = 0.240
		tm.rings = 24
		tm.ring_segments = 6
		ring.mesh = tm
		ring.rotation_degrees = Vector3(90.0, 0.0, 0.0)
		ring.material_override = dm
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.position = Vector3(0.0, 0.0, -50.0)
		ring.visible = false
		optic.add_child(ring)

func _process(_delta: float) -> void:
	if dot == null or head == null:
		return
	var vis := false
	if enabled and is_visible_in_tree():
		var e := optic.to_local(head.global_position)
		if e.z > win_z + 0.02:
			var far := Vector3(0.0, 0.0, -50.0)
			var k := (win_z - e.z) / (far.z - e.z)
			var p := e + (far - e) * k
			vis = absf(p.x) < win.x * 0.5 and absf(p.y) < win.y * 0.5
	dot.visible = vis
	if ring != null:
		ring.visible = vis and ret_style == 1

# ---------------------------------------------------------------- firing / slide

func pull_trigger() -> void:
	if not enabled or (slide_grabbed and slide_t > 0.1):
		return
	if slide_locked or jammed or not chambered:
		sfx.emit("click", global_position)
		return
	chambered = false
	shot.emit(muzzle.global_transform)
	sfx.emit(str(muz.get("sound", "shot")), muzzle.global_position)
	_flash()
	_eject(false)
	_recoil()
	if malf_rate > 0.0 and randf() < malf_rate:
		jammed = true # stovepipe: tap/rack to clear
		_slide_to(0.55, 0.05)
		return
	if mag != null and mag.rounds > 0:
		mag.rounds -= 1
		chambered = true
		_cycle_anim(false)
	elif mag != null:
		slide_locked = true # slide locks back on an empty magazine
		_cycle_anim(true)
	else:
		_cycle_anim(false)

func slide_release() -> void:
	if not enabled or not slide_locked or slide_grabbed:
		return
	slide_locked = false
	if mag != null and mag.rounds > 0:
		mag.rounds -= 1
		chambered = true
	sfx.emit("slide", global_position)
	_slide_to(0.0, 0.05)

func rack() -> void:
	jammed = false
	slide_locked = false
	if chambered:
		_eject(true) # live round is ejected
	chambered = false
	if mag != null and mag.rounds > 0:
		mag.rounds -= 1
		chambered = true
	elif mag != null:
		slide_locked = true
	sfx.emit("slide", global_position)
	if slide_locked:
		_slide_to(1.0, 0.05)
	else:
		_slide_to(0.0, 0.06)

func _set_slide(t: float) -> void:
	slide_t = t
	slide_node.position = _slide_rest + Vector3(0.0, 0.0, t * float(cfg["travel"]))

func _slide_to(target: float, dur: float) -> void:
	if slide_grabbed:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_slide, slide_t, target, dur)

func _cycle_anim(lock: bool) -> void:
	if slide_grabbed:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_method(_set_slide, slide_t, 1.0, 0.03)
	if not lock:
		_tween.tween_method(_set_slide, 1.0, 0.0, 0.05)

func _recoil() -> void:
	var r: float = float(cfg["recoil"]) * float(muz.get("recoil", 1.0))
	kick.rotation.x = deg_to_rad(5.0 * r)
	kick.position.z = 0.012 * r
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(kick, "rotation:x", 0.0, 0.14).set_ease(Tween.EASE_OUT)
	tw.tween_property(kick, "position:z", 0.0, 0.14)

func _flash() -> void:
	flash.visible = true
	get_tree().create_timer(0.04).timeout.connect(_flash_off)

func _flash_off() -> void:
	if is_instance_valid(flash):
		flash.visible = false

# ---------------------------------------------------------------- rack by hand

func can_grab_slide(p: Vector3) -> bool:
	if not enabled or slide_grabbed or not is_visible_in_tree():
		return false
	var s: Vector3 = cfg["slide"]
	return p.distance_to(slide_node.to_global(Vector3(0.0, 0.015, s.z * 0.3))) < 0.06

func begin_rack(p: Vector3) -> void:
	if _tween:
		_tween.kill()
	slide_grabbed = true
	var travel: float = cfg["travel"]
	_rack_ref = frame_node.to_local(p).z - slide_t * travel
	_rack_max = slide_t

func update_rack(p: Vector3) -> void:
	var travel: float = cfg["travel"]
	var t := clampf((frame_node.to_local(p).z - _rack_ref) / travel, 0.0, 1.0)
	_rack_max = maxf(_rack_max, t)
	_set_slide(t)

func end_rack() -> void:
	if not slide_grabbed:
		return
	slide_grabbed = false
	if _rack_max >= RACK_THRESHOLD:
		rack()
	elif slide_locked:
		_slide_to(1.0, 0.03)
	else:
		_slide_to(0.55 if jammed else 0.0, 0.05)

# ---------------------------------------------------------------- magazine

func magwell_point() -> Vector3:
	var g: Vector3 = cfg["grip"]
	return frame_node.to_global(Vector3(0.0, -g.y + 0.0025, 0.005))

func can_accept(m: Mag) -> bool:
	if mag != null or not enabled or not is_visible_in_tree():
		return false
	var top := m.global_position + m.global_basis.y * m.length
	var aligned := m.global_basis.y.dot(frame_node.global_basis.y)
	return top.distance_to(magwell_point()) < 0.05 and aligned > 0.7

func seat_mag(m: Mag) -> void:
	var g: Vector3 = cfg["grip"]
	mag = m
	m.hold()
	m.in_gun = true
	m.reparent(frame_node, false)
	m.transform = Transform3D(Basis.IDENTITY, Vector3(0.0, -g.y + 0.0025 - 0.006, 0.005))
	sfx.emit("insert", global_position)

func drop_mag() -> void:
	if mag == null or not enabled:
		return
	var m := mag
	mag = null
	m.reparent(world, true)
	m.drop(-global_basis.y * 1.2)
	sfx.emit("drop", global_position)

# ---------------------------------------------------------------- brass

func _eject(live: bool) -> void:
	if world == null or slide_node == null:
		return
	var s: Vector3 = cfg["slide"]
	var b := RigidBody3D.new()
	b.collision_layer = 32
	b.collision_mask = 1
	b.mass = 0.01
	b.continuous_cd = true
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.0048
	cm.bottom_radius = 0.0048
	cm.height = 0.03 if live else 0.019
	mi.mesh = cm
	mi.material_override = Defs.mat(Color(0.8, 0.45, 0.2) if live else Color(0.85, 0.65, 0.2))
	b.add_child(mi)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.0048
	sh.height = cm.height
	cs.shape = sh
	b.add_child(cs)
	world.add_child(b)
	var gb := slide_node.global_basis
	b.global_position = slide_node.to_global(Vector3(s.x * 0.5 + 0.005, 0.006, s.z * 0.2))
	b.global_basis = Basis.from_euler(Vector3(randf() * TAU, randf() * TAU, randf() * TAU))
	b.linear_velocity = gb.x * (2.0 + randf() * 1.2) + gb.y * (1.2 + randf() * 0.8) + gb.z * (0.8 + randf() * 0.8)
	b.angular_velocity = Vector3(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
	_brass.append(b)
	if _brass.size() > 24:
		_free_if_valid(_brass.pop_front())
	get_tree().create_timer(6.0).timeout.connect(_free_if_valid.bind(b))
	get_tree().create_timer(0.35).timeout.connect(_brass_sound.bind(b.global_position))

func _free_if_valid(n) -> void:
	if is_instance_valid(n):
		n.queue_free()

func _brass_sound(p: Vector3) -> void:
	sfx.emit("brass", p)

func set_reticle(style: int, c: Color, bright: float) -> void:
	ret_style = style
	ret_color = c
	ret_bright = bright
	_apply_reticle()

func _apply_reticle() -> void:
	if dot_mat != null:
		dot_mat.albedo_color = Color(ret_color.r, ret_color.g, ret_color.b, clampf(ret_bright, 0.1, 1.0))
