class_name Target
extends StaticBody3D
## USPSA paper targets (scored zones) and steel (popper, plate, spinner). Targets can slide, turn,
## tumble or orbit in space. Floating (tumble / orbit) targets have no stand.

enum Kind { CLASSIC, MINI, NOSHOOT, POPPER, PLATE, SPINNER }
enum Motion { NONE, SLIDE, ROTATE, TUMBLE, ORBIT, POPUP }

const LIFT := 0.12
const PTS := {"A": 5, "C": 3, "D": 1}
const STEEL := Color(0.75, 0.77, 0.80)
const HIT_GREEN := Color(0.3, 0.85, 0.35)
const SLIDE_AMP := 2.0
const SLIDE_SPEED := 0.9
const SPIN_SPEED_DEG := 140.0
const PRESETS := [
	{"name": "USPSA", "kind": 0, "motion": 0},
	{"name": "Mini USPSA", "kind": 1, "motion": 0},
	{"name": "No-Shoot", "kind": 2, "motion": 0},
	{"name": "Popper (steel)", "kind": 3, "motion": 0},
	{"name": "Plate (steel)", "kind": 4, "motion": 0},
	{"name": "Spinner (steel)", "kind": 5, "motion": 0},
	{"name": "Sliding USPSA", "kind": 0, "motion": 1},
	{"name": "Sliding Plate", "kind": 4, "motion": 1},
	{"name": "Sliding Popper", "kind": 3, "motion": 1},
	{"name": "Sliding Spinner", "kind": 5, "motion": 1},
	{"name": "Turning USPSA", "kind": 0, "motion": 2},
	{"name": "Tumbling Plate (air)", "kind": 4, "motion": 3},
	{"name": "Orbiting Plate (air)", "kind": 4, "motion": 4},
	{"name": "Orbiting USPSA (air)", "kind": 0, "motion": 4},
	{"name": "Orbiting Spinner (air)", "kind": 5, "motion": 4},
	{"name": "Pop-up USPSA", "kind": 0, "motion": 5},
]

var kind: int = Kind.CLASSIC
var motion: int = Motion.NONE
var hits: Array = []
var knocked := false
var active := true
var floating := false
var home := Vector3.ZERO
var yaw0 := 0.0
var lift := LIFT
var sc := 1.0
var pivot: Node3D
var holes: Node3D
var plate_mat: StandardMaterial3D
var spin_cs: CollisionShape3D
var plate_cs: CollisionShape3D
var spin := 0.0
var phase := 0.0
var rot_t := 0.0
var tumble := 0.0
var popup_t := 0.0
var _tw: Tween

func _ready() -> void:
	home = position
	yaw0 = rotation.y

func set_home(p: Vector3) -> void:
	position = p
	home = p
	yaw0 = rotation.y

func grab() -> void:
	collision_layer = 0
	active = false

func release() -> void:
	set_home(position)
	if not (kind == Kind.POPPER and knocked):
		collision_layer = 4
	active = true

func is_steel() -> bool:
	return kind == Kind.POPPER or kind == Kind.PLATE or kind == Kind.SPINNER

func setup(k: int, m: int = 0) -> void:
	kind = k
	motion = m
	floating = (m == Motion.TUMBLE or m == Motion.ORBIT)
	lift = -0.38 if floating else LIFT
	collision_layer = 4
	collision_mask = 0
	holes = Node3D.new()
	add_child(holes)
	match kind:
		Kind.CLASSIC, Kind.MINI, Kind.NOSHOOT:
			_build_paper()
		Kind.POPPER:
			_build_popper()
		Kind.PLATE:
			_build_plate()
		Kind.SPINNER:
			_build_spinner()
	phase = randf() * TAU

func _physics_process(delta: float) -> void:
	if not active:
		return
	if kind == Kind.SPINNER:
		spin += deg_to_rad(SPIN_SPEED_DEG) * delta
		pivot.rotation.z = spin
		spin_cs.rotation.z = spin
	match motion:
		Motion.SLIDE:
			if not (kind == Kind.POPPER and knocked):
				phase += delta * SLIDE_SPEED
				position = home + basis.x * (sin(phase) * SLIDE_AMP)
		Motion.ROTATE:
			rot_t += deg_to_rad(90.0) * delta
			rotation.y = yaw0 + rot_t
		Motion.TUMBLE:
			tumble += deg_to_rad(120.0) * delta
			if pivot != null:
				pivot.rotation.x = tumble
			if plate_cs != null:
				plate_cs.rotation.x = deg_to_rad(90.0) + tumble
		Motion.POPUP:
			popup_t += delta
			var up := fmod(popup_t, 4.0) < 2.5
			if up != visible:
				visible = up
				collision_layer = 4 if up else 0
		Motion.ORBIT:
			phase += delta * 0.8
			position = home + basis.x * (cos(phase) * 1.2) + Vector3.UP * (sin(phase) * 0.8)

func _add_box(size: Vector3, pos: Vector3, c: Color, collide: bool) -> void:
	Defs.box(self, size * sc, pos * sc, c)
	if collide:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size * sc
		cs.shape = sh
		cs.position = pos * sc
		add_child(cs)

func _build_paper() -> void:
	sc = 0.6 if kind == Kind.MINI else 1.0
	var d_col := Color(0.75, 0.60, 0.40)
	var c_col := Color(0.68, 0.53, 0.34)
	var a_col := Color(0.56, 0.42, 0.26)
	if kind == Kind.NOSHOOT:
		d_col = Color(0.93, 0.93, 0.93)
		c_col = d_col
		a_col = d_col
	var dp := 0.012
	var l := lift
	if not floating:
		Defs.box(self, Vector3(0.04, 0.5, 0.03) * sc, Vector3(0.0, 0.25, -0.03) * sc, Color(0.5, 0.4, 0.3))
	_add_box(Vector3(0.46, 0.50, dp), Vector3(0.0, l + 0.25, 0.0), d_col, true)
	_add_box(Vector3(0.24, 0.26, dp), Vector3(0.0, l + 0.63, 0.0), d_col, true)
	if kind != Kind.NOSHOOT:
		_add_box(Vector3(0.278, 0.40, dp), Vector3(0.0, l + 0.30, 0.002), c_col, false)
		_add_box(Vector3(0.152, 0.28, dp), Vector3(0.0, l + 0.36, 0.004), a_col, false)
		_add_box(Vector3(0.10, 0.14, dp), Vector3(0.0, l + 0.62, 0.002), a_col, false)

func _new_steel_mat() -> void:
	plate_mat = StandardMaterial3D.new()
	plate_mat.albedo_color = STEEL
	plate_mat.metallic = 0.3
	plate_mat.roughness = 0.5

func _build_popper() -> void:
	Defs.box(self, Vector3(0.34, 0.03, 0.22), Vector3(0.0, 0.015, 0.0), Color(0.2, 0.2, 0.22))
	pivot = Node3D.new()
	pivot.position = Vector3(0.0, 0.03, -0.05)
	add_child(pivot)
	_new_steel_mat()
	var body := Defs.box(pivot, Vector3(0.26, 0.30, 0.014), Vector3(0.0, 0.15, 0.0), STEEL)
	body.material_override = plate_mat
	var head := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.13
	cm.bottom_radius = 0.13
	cm.height = 0.014
	head.mesh = cm
	head.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	head.position = Vector3(0.0, 0.30, 0.0)
	head.material_override = plate_mat
	pivot.add_child(head)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.26, 0.43, 0.03)
	cs.shape = sh
	cs.position = Vector3(0.0, 0.24, -0.05)
	add_child(cs)

func _build_plate() -> void:
	var py := 1.1
	if floating:
		py = 0.0
	else:
		Defs.box(self, Vector3(0.04, 1.2, 0.04), Vector3(0.0, 0.6, -0.05), Color(0.3, 0.3, 0.32))
	pivot = Node3D.new()
	pivot.position = Vector3(0.0, py, 0.0 if floating else -0.02)
	add_child(pivot)
	_new_steel_mat()
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.1
	cm.bottom_radius = 0.1
	cm.height = 0.012
	mi.mesh = cm
	mi.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	mi.material_override = plate_mat
	pivot.add_child(mi)
	plate_cs = CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.1
	sh.height = 0.02
	plate_cs.shape = sh
	plate_cs.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	plate_cs.position = pivot.position
	add_child(plate_cs)

func _build_spinner() -> void:
	var py := 1.3
	if floating:
		py = 0.0
	else:
		Defs.box(self, Vector3(0.05, 1.3, 0.05), Vector3(0.0, 0.65, -0.06), Color(0.3, 0.3, 0.32))
	pivot = Node3D.new()
	pivot.position = Vector3(0.0, py, 0.0 if floating else -0.03)
	add_child(pivot)
	_new_steel_mat()
	var bar := Defs.box(pivot, Vector3(0.6, 0.10, 0.012), Vector3.ZERO, STEEL)
	bar.material_override = plate_mat
	spin_cs = CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.6, 0.10, 0.03)
	spin_cs.shape = sh
	spin_cs.position = pivot.position
	add_child(spin_cs)

func zone_of(wp: Vector3) -> String:
	if kind == Kind.NOSHOOT:
		return "NS"
	var lp := to_local(wp)
	var x := absf(lp.x) / sc
	var y := (lp.y - lift * sc) / sc
	if y <= 0.50:
		if x <= 0.076 and y >= 0.22:
			return "A"
		if x <= 0.139 and y >= 0.10:
			return "C"
		return "D"
	if x <= 0.05 and y >= 0.55 and y <= 0.69:
		return "A"
	return "D"

func register_hit(wp: Vector3, scoring: bool) -> String:
	if is_steel():
		if not knocked:
			knocked = true
			if scoring:
				hits.append("S")
			if _tw:
				_tw.kill()
			_tw = create_tween()
			if kind == Kind.POPPER:
				collision_layer = 0
				_tw.tween_property(pivot, "rotation_degrees:x", -85.0, 0.35).set_ease(Tween.EASE_IN)
			else:
				plate_mat.albedo_color = HIT_GREEN
				if kind == Kind.PLATE and not floating:
					_tw.tween_property(pivot, "rotation_degrees:x", -25.0, 0.08)
					_tw.tween_property(pivot, "rotation_degrees:x", 0.0, 0.5).set_trans(Tween.TRANS_ELASTIC)
		return "S"
	var z := zone_of(wp)
	_add_hole(wp)
	if scoring:
		hits.append(z)
	return z

func _add_hole(wp: Vector3) -> void:
	if holes.get_child_count() >= 50:
		holes.get_child(0).queue_free()
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.008
	sm.height = 0.016
	mi.mesh = sm
	mi.material_override = Defs.mat(Color(0.02, 0.02, 0.02))
	holes.add_child(mi)
	var lp := to_local(wp)
	lp.z = 0.013 if lp.z >= 0.0 else -0.009
	mi.position = lp
	mi.scale = Vector3(1.0, 1.0, 0.3)

func reset_state() -> void:
	hits.clear()
	knocked = false
	popup_t = 0.0
	if _tw:
		_tw.kill()
	for h in holes.get_children():
		h.queue_free()
	if pivot != null and motion != Motion.TUMBLE and kind != Kind.SPINNER:
		pivot.rotation_degrees.x = 0.0
	if kind == Kind.POPPER:
		collision_layer = 4
	if plate_mat != null:
		plate_mat.albedo_color = STEEL

func tally() -> Dictionary:
	var d := {"A": 0, "C": 0, "D": 0, "NS": 0, "M": 0, "S": 0, "pts": 0}
	if kind == Kind.NOSHOOT:
		d["NS"] = hits.size()
		d["pts"] = -10 * hits.size()
	elif is_steel():
		if hits.size() > 0:
			d["S"] = 1
			d["pts"] = 5
		else:
			d["M"] = 1
			d["pts"] = -10
	else:
		var got := 0
		for z in ["A", "C", "D"]:
			var n := mini(int(hits.count(z)), 2 - got)
			d[z] = n
			d["pts"] += n * int(PTS[z])
			got += n
		d["M"] = 2 - got
		d["pts"] -= 10 * int(d["M"])
	return d

func to_dict() -> Dictionary:
	return {"kind": kind, "motion": motion, "pos": [home.x, home.y, home.z], "yaw": yaw0}
