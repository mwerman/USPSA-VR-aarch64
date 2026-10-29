class_name Barricade
extends StaticBody3D
## Placeable wall / barricade built from boxes (so port holes are real gaps bullets pass through).
## 8 models x 6 procedural textures. Layer 17 = world (1) + editor-pickable (16).

const THICK := 0.15
const MODELS := [
	{"name": "Window Wall", "w": 2.0, "h": 2.0, "holes": [[-0.45, 1.1, 0.45, 1.7]]},
	{"name": "Port Slit Wall", "w": 2.0, "h": 1.8, "holes": [[-0.7, 1.25, 0.7, 1.4]]},
	{"name": "Double Port Wall", "w": 3.0, "h": 2.0, "holes": [[-1.1, 1.0, -0.4, 1.5], [0.4, 1.3, 1.1, 1.6]]},
	{"name": "Low Wall", "w": 2.0, "h": 1.0, "holes": []},
	{"name": "Tall Wall", "w": 3.0, "h": 2.2, "holes": []},
	{"name": "Doorway", "w": 2.4, "h": 2.2, "holes": [[-0.45, 0.0, 0.45, 1.9]]},
	{"name": "Slat Fence", "w": 3.0, "h": 1.8, "holes": [], "slats": true},
	{"name": "Barrel Stack", "w": 1.8, "h": 1.8, "holes": [], "barrels": true},
]

var model := 0
var tex := 0
var mat: StandardMaterial3D
var parts: Array = []

func setup(m: int, t: int) -> void:
	model = m
	tex = t % Defs.TEXTURES.size()
	collision_layer = 17
	collision_mask = 0
	mat = Defs.tex_mat(Defs.TEXTURES[tex])
	_build()

func set_tex(t: int) -> void:
	tex = t % Defs.TEXTURES.size()
	mat = Defs.tex_mat(Defs.TEXTURES[tex])
	for p in parts:
		(p as MeshInstance3D).material_override = mat

func grab() -> void:
	collision_layer = 0

func release() -> void:
	collision_layer = 17

func reset_state() -> void:
	pass

func to_dict() -> Dictionary:
	return {"model": model, "tex": tex, "pos": [position.x, position.y, position.z], "yaw": rotation.y}

func _part(size: Vector3, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)
	parts.append(mi)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	add_child(cs)

func _barrel(p: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.28
	cm.bottom_radius = 0.28
	cm.height = 0.9
	mi.mesh = cm
	mi.material_override = mat
	mi.position = p + Vector3(0.0, 0.45, 0.0)
	add_child(mi)
	parts.append(mi)
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.28
	sh.height = 0.9
	cs.shape = sh
	cs.position = mi.position
	add_child(cs)

func _subtract(ivs: Array, y0: float, y1: float) -> Array:
	var out := []
	for iv in ivs:
		if y1 <= iv[0] or y0 >= iv[1]:
			out.append(iv)
		else:
			if y0 > iv[0]:
				out.append([iv[0], y0])
			if y1 < iv[1]:
				out.append([y1, iv[1]])
	return out

func _build() -> void:
	var d: Dictionary = MODELS[model]
	var w: float = d["w"]
	var h: float = d["h"]
	if d.get("barrels", false):
		for i in 3:
			_barrel(Vector3(-0.6 + i * 0.6, 0.0, 0.0))
		for i in 2:
			_barrel(Vector3(-0.3 + i * 0.6, 0.9, 0.0))
		return
	if d.get("slats", false):
		var n := int(w / 0.22)
		for i in n:
			_part(Vector3(0.12, h, 0.05), Vector3(-w * 0.5 + 0.06 + i * 0.22, h * 0.5, 0.0))
		_part(Vector3(w, 0.1, 0.04), Vector3(0.0, 0.35, -0.045))
		_part(Vector3(w, 0.1, 0.04), Vector3(0.0, h - 0.35, -0.045))
		return
	var holes: Array = d["holes"]
	var xs := [-w * 0.5, w * 0.5]
	for hh in holes:
		xs.append(hh[0])
		xs.append(hh[2])
	xs.sort()
	for i in xs.size() - 1:
		var xa: float = xs[i]
		var xb: float = xs[i + 1]
		if xb - xa < 0.001:
			continue
		var ivs := [[0.0, h]]
		for hh in holes:
			if hh[0] <= xa + 0.0005 and hh[2] >= xb - 0.0005:
				ivs = _subtract(ivs, float(hh[1]), float(hh[3]))
		for iv in ivs:
			_part(Vector3(xb - xa, float(iv[1]) - float(iv[0]), THICK), Vector3((xa + xb) * 0.5, (float(iv[0]) + float(iv[1])) * 0.5, 0.0))
