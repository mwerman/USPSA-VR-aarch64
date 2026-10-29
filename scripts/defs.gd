class_name Defs
extends RefCounted
## Shared data (guns, optics), cached procedural materials/boxes, generated sound effects.

const GUNS := {
	"Glock 17": {
		"slide": Vector3(0.027, 0.036, 0.190), "grip": Vector3(0.032, 0.100, 0.052),
		"cap": 17, "recoil": 1.0, "travel": 0.035, "mag_len": 0.090,
		"color": Color(0.08, 0.08, 0.09), "frame_color": Color(0.13, 0.13, 0.14),
	},
	"CZ Shadow 2": {
		"slide": Vector3(0.029, 0.038, 0.215), "grip": Vector3(0.034, 0.105, 0.054),
		"cap": 19, "recoil": 0.7, "travel": 0.036, "mag_len": 0.100,
		"color": Color(0.10, 0.10, 0.11), "frame_color": Color(0.60, 0.60, 0.62),
	},
	"S&W M&P9 2.0": {
		"slide": Vector3(0.028, 0.037, 0.195), "grip": Vector3(0.033, 0.102, 0.053),
		"cap": 17, "recoil": 0.95, "travel": 0.035, "mag_len": 0.092,
		"color": Color(0.20, 0.20, 0.22), "frame_color": Color(0.15, 0.15, 0.16),
	},
	"1911 .45": {
		"slide": Vector3(0.024, 0.032, 0.200), "grip": Vector3(0.030, 0.095, 0.050),
		"cap": 8, "recoil": 1.4, "travel": 0.040, "mag_len": 0.075,
		"color": Color(0.55, 0.55, 0.58), "frame_color": Color(0.50, 0.50, 0.53),
	},
}

const OPTICS := {
	"Iron Sights": {"moa": 0.0},
	"Holosun 507C": {"moa": 2.0, "ring": true, "body": Vector3(0.026, 0.024, 0.034), "win": Vector2(0.017, 0.014), "color": Color(1.0, 0.1, 0.05)},
	"Trijicon RMR": {"moa": 3.25, "body": Vector3(0.024, 0.022, 0.032), "win": Vector2(0.016, 0.013), "color": Color(1.0, 0.15, 0.0)},
	"Shield RMSc": {"moa": 4.0, "body": Vector3(0.021, 0.019, 0.027), "win": Vector2(0.013, 0.011), "color": Color(1.0, 0.1, 0.05)},
	"Aimpoint ACRO P-2": {"moa": 3.5, "body": Vector3(0.030, 0.034, 0.046), "win": Vector2(0.022, 0.022), "color": Color(1.0, 0.1, 0.0)},
}

const MUZZLES := {
	"None": {"len": 0.0},
	"Compensator": {"len": 0.045, "r": 0.0125, "recoil": 0.65, "flash": 1.3, "sound": "shot", "color": Color(0.1, 0.1, 0.11), "ports": 2},
	"Muzzle Brake": {"len": 0.055, "r": 0.013, "recoil": 0.7, "flash": 1.7, "sound": "shot", "color": Color(0.08, 0.08, 0.09), "ports": 3},
	"Suppressor": {"len": 0.18, "r": 0.021, "recoil": 0.85, "flash": 0.15, "sound": "shot_supp", "color": Color(0.12, 0.12, 0.13), "ports": 0},
}

const TEXTURES := ["Plywood", "Brick", "Concrete", "Metal", "Camo", "Sandbags"]

static var _texmats: Dictionary = {}
static var _mats: Dictionary = {}
static var _sfx: Dictionary = {}

static func mat(c: Color) -> StandardMaterial3D:
	var k := c.to_html()
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.85
		_mats[k] = m
	return _mats[k]

static func box(parent: Node, size: Vector3, pos: Vector3, c: Color, collide := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(c)
	mi.position = pos
	parent.add_child(mi)
	if collide:
		var sb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi

static func synth(dur: float, freq: float, noise: float, decay: float, vol: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		var t := float(i) / rate
		var env := exp(-t * decay)
		var s := 0.0
		if freq > 0.0:
			s += sin(TAU * freq * t) * (1.0 - noise)
		s += randf_range(-1.0, 1.0) * noise
		var v := clampi(int(s * env * vol * 32767.0), -32768, 32767)
		data.encode_s16(i * 2, v)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w

static func sfx(key: String) -> AudioStreamWAV:
	if not _sfx.has(key):
		match key:
			"shot": _sfx[key] = synth(0.30, 80.0, 0.8, 16.0, 0.95)
			"click": _sfx[key] = synth(0.03, 0.0, 1.0, 100.0, 0.5)
			"beep": _sfx[key] = synth(0.35, 2000.0, 0.0, 0.0, 0.6)
			"standby": _sfx[key] = synth(0.08, 900.0, 0.0, 0.0, 0.4)
			"drop": _sfx[key] = synth(0.08, 200.0, 0.6, 40.0, 0.6)
			"insert": _sfx[key] = synth(0.06, 0.0, 1.0, 60.0, 0.6)
			"slide": _sfx[key] = synth(0.09, 0.0, 0.9, 35.0, 0.6)
			"ping": _sfx[key] = synth(0.45, 1400.0, 0.05, 9.0, 0.7)
			"thud": _sfx[key] = synth(0.06, 150.0, 0.5, 60.0, 0.5)
			"menu": _sfx[key] = synth(0.03, 1200.0, 0.0, 80.0, 0.3)
			"shot_supp": _sfx[key] = synth(0.20, 300.0, 0.7, 30.0, 0.35)
			"brass": _sfx[key] = synth(0.15, 4200.0, 0.2, 30.0, 0.25)
			_: _sfx[key] = synth(0.03, 0.0, 1.0, 100.0, 0.3)
	return _sfx[key]

static func warm() -> void:
	for k in ["shot", "click", "beep", "standby", "drop", "insert", "slide", "ping", "thud", "menu", "shot_supp", "brass"]:
		sfx(k)

static func _shade(c: Color, k: float) -> Color:
	return Color(c.r * k, c.g * k, c.b * k)

static func tex_mat(tname: String) -> StandardMaterial3D:
	if not _texmats.has(tname):
		var m := StandardMaterial3D.new()
		m.albedo_texture = _make_tex(tname)
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(1.2, 1.2, 1.2)
		m.roughness = 0.9
		m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_texmats[tname] = m
	return _texmats[tname]

static func _make_tex(tname: String) -> ImageTexture:
	var n := 64
	var img := Image.create(n, n, true, Image.FORMAT_RGB8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(tname)
	var blobs := []
	if tname == "Camo":
		for i in 14:
			blobs.append([rng.randi_range(0, n), rng.randi_range(0, n), rng.randf_range(8.0, 16.0), rng.randi_range(0, 2)])
	var camo_cols := [Color(0.18, 0.22, 0.12), Color(0.42, 0.36, 0.22), Color(0.3, 0.4, 0.2)]
	for y in n:
		for x in n:
			var c := Color(0.5, 0.5, 0.5)
			var k := rng.randf_range(0.9, 1.1)
			match tname:
				"Plywood":
					var band := 0.5 + 0.5 * sin(float(y) * 0.9 + sin(float(x) * 0.15) * 2.0)
					c = _shade(Color(0.72, 0.55, 0.34).lerp(Color(0.55, 0.4, 0.22), band), k)
					if x % 32 < 1 or y % 32 < 1:
						c = Color(0.3, 0.22, 0.12)
				"Brick":
					var row := int(y / 16)
					var bx := (x + (16 if row % 2 == 1 else 0)) % 32
					if y % 16 < 2 or bx < 2:
						c = _shade(Color(0.72, 0.72, 0.68), k)
					else:
						c = _shade(Color(0.58, 0.25, 0.2), k)
				"Concrete":
					c = _shade(Color(0.6, 0.6, 0.62), rng.randf_range(0.85, 1.12))
				"Metal":
					var rib := 0.8 + 0.2 * sin(float(x) * TAU / 8.0)
					c = _shade(Color(0.55, 0.58, 0.62), rib * k)
				"Camo":
					c = Color(0.25, 0.32, 0.18)
					for b in blobs:
						if Vector2(x, y).distance_to(Vector2(b[0], b[1])) < float(b[2]):
							c = camo_cols[int(b[3])]
					c = _shade(c, k)
				"Sandbags":
					var srow := int(y / 12)
					var sbx := (x + (10 if srow % 2 == 1 else 0)) % 20
					if y % 12 < 2 or sbx < 2:
						c = _shade(Color(0.35, 0.3, 0.2), k)
					else:
						c = _shade(Color(0.55, 0.48, 0.35), k)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
