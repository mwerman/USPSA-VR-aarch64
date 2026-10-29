extends Node3D
## USPSA VR Range: XR rig, locomotion, controls, in-world menu, target editor, timer + scoring.

enum T { IDLE, ARMED, RUNNING, DONE }

const SETTINGS_PATH := "user://settings.json"
const GRIP_PITCHES := [0, 10, 20, 30, -10, -20]
const MENU_ITEMS := ["range", "drills", "gunpage", "layoutpage", "settings", "controls", "stats", "tutorial", "recenter", "close"]
const GUN_ITEMS := ["gun", "optic", "ret_style", "ret_color", "ret_bright", "muzzle", "grip", "holster", "belt", "malf", "hand", "back"]
const LAYOUT_ITEMS := ["edit", "slot", "save", "load", "clear", "back"]
const SETTINGS_ITEMS := ["loco", "turn", "quality", "fov", "fov_str", "fps", "ammo", "volume", "haptics", "markers", "board", "par", "back"]
const STATS_ITEMS := ["clear_hist", "back"]
const PAGE_TITLES := ["USPSA VR RANGE", "CONTROLS (press a button to bind)", "DRILLS / STAGES", "STATS", "GUN / OPTIC", "TARGET LAYOUT", "SETTINGS"]
const RET_STYLES := ["Dot", "Circle-Dot"]
const RET_COLORS := [["Red", Color(1.0, 0.1, 0.05)], ["Green", Color(0.1, 1.0, 0.2)], ["Yellow", Color(1.0, 0.9, 0.1)], ["Cyan", Color(0.1, 0.9, 1.0)]]
const RET_BRIGHT := [0.2, 0.4, 0.6, 0.8, 1.0]
const MALF_RATES := [0.0, 0.03, 0.08]
const MALF_NAMES := ["Off", "Rare", "Common"]
const BELTS := [0.50, 0.55, 0.60, 0.62, 0.65, 0.70, 0.75]
const VOLUMES := [1.0, 0.6, 0.3]
const FOV_NAMES := ["Off", "Fixed", "Eye-tracked"]
const FOV_STR := ["Low", "Medium", "High"]
const FOV_RADII := [[0.34, 0.60], [0.24, 0.44], [0.17, 0.32]]
const FOV_RES := 40
const GAZE_POSES := ["gaze", "gaze_pose", "default"]
const PARS := [0.0, 2.0, 3.0, 5.0, 8.0, 10.0, 15.0]
const HOLSTERS := ["Hip", "Appendix"]
const REMAP_ITEMS := ["b_fire", "b_drop_mag", "b_slide_release", "b_holster", "b_timer", "b_menu", "b_grab", "swap", "reset_binds", "back"]
const ACTION_NAMES := {"fire": "Fire/click", "drop_mag": "Drop mag", "slide_release": "Slide rel", "holster": "Draw/holster", "timer": "Timer", "menu": "Menu", "grab": "Mag/rack"}
const BTN_NAMES := {"trigger_click": "Trigger", "grip_click": "Grip", "ax_button": "A/X", "by_button": "B/Y", "primary_click": "Stick click"}
const FIXED_HAND := {"fire": "gun", "drop_mag": "gun", "slide_release": "gun", "holster": "gun", "grab": "off"}
const DEFAULT_BINDS := {
	"fire": {"hand": "gun", "btn": "trigger_click"},
	"drop_mag": {"hand": "gun", "btn": "ax_button"},
	"slide_release": {"hand": "gun", "btn": "by_button"},
	"holster": {"hand": "gun", "btn": "grip_click"},
	"timer": {"hand": "off", "btn": "ax_button"},
	"menu": {"hand": "off", "btn": "by_button"},
	"grab": {"hand": "off", "btn": "grip_click"},
}
const QUALITY := [
	{"name": "Low", "scale": 0.8, "msaa": 0},
	{"name": "Medium", "scale": 1.0, "msaa": 1},
	{"name": "High", "scale": 1.2, "msaa": 2},
]

var S := {
	"range": "indoor", "gun": "Glock 17", "optic": "Holosun 507C",
	"smooth_loco": false, "smooth_turn": false, "dominant": "right",
	"show_ammo": true, "slot": 1, "grip_pitch": 0, "quality": 1, "muzzle": "None", "holster": "Hip", "swap_sticks": false, "binds": {},
	"ret_style": 0, "ret_color": 0, "ret_bright": 4, "malf": 0, "belt": 3, "volume": 0,
	"haptics": true, "markers": true, "board": true, "par": 0, "seen_tutorial": false, "fov": 1, "fov_str": 1, "fps": false,
}

var origin: XROrigin3D
var cam: XRCamera3D
var hands := {}
var gun_hand: XRController3D
var off_hand: XRController3D
var gun: Gun
var world: Node3D
var range_root: Node3D
var targets_root: Node3D
var bounds := Rect2(-5, -20, 10, 25)
var body_fwd := Vector3(0, 0, -1)
var held_mag: Mag = null
var pouch: MeshInstance3D
var wrist: Label3D
var pointer: MeshInstance3D
var arc: MeshInstance3D
var marker: MeshInstance3D
var ui_player: AudioStreamPlayer
var hold_xf: Transform3D
var tele_aiming := false
var tele_valid := false
var tele_target := Vector3.ZERO
var snap_ready := true
var menu: Node3D
var menu_open := false
var menu_bg := {}
var menu_lbl := {}
var hover := ""
var edit_mode := false
var edit_kind := 0
var ghost: Node3D
var ghost_yaw := 0.0
var ghost_ok := false
var carried: Node3D = null
var tstate := T.IDLE
var arm_left := 0.0
var t_start := 0
var shots: Array = []
var result := ""
var flash_msg := ""
var flash_until := 0.0
var hud_acc := 0.0
var holster: Node3D
var menu_page := 0
var drill_items: Array = []
var drill_idx := 0
var history := {"runs": []}
var run_zones := {"A": 0, "C": 0, "D": 0, "NS": 0, "S": 0}
var menu_stats: Label3D
var tutorial: Label3D
var board: Label3D
var tutorial_wait := 1.5
var fov_img: Image
var fov_tex: ImageTexture
var fov_acc := 0.0
var gaze_uv := Vector2(0.5, 0.5)
var gaze_ok := false
var gaze_lost := 0.0
var eye_active := false
var listening := ""
var menu_body := {}
var menu_title: Label3D
var holstered := true
var edit_height := 1.5
var edit_tex := 0

# ------------------------------------------------------------------ setup

func _ready() -> void:
	hold_xf = Transform3D(Basis(Vector3.RIGHT, deg_to_rad(-60.0)), Vector3(0.0, 0.0, -0.04))
	Defs.warm()
	_load_settings()
	_setup_xr()
	world = Node3D.new()
	add_child(world)
	targets_root = Node3D.new()
	world.add_child(targets_root)
	ui_player = AudioStreamPlayer.new()
	add_child(ui_player)
	_build_rig()
	_build_ui_bits()
	_build_menu()
	gun = Gun.new()
	gun.head = cam
	gun.world = world
	origin.add_child(gun)
	gun.build(S["gun"], S["optic"], S["muzzle"])
	gun.shot.connect(_on_shot)
	gun.sfx.connect(play)
	_apply_hands()
	_apply_quality()
	_apply_foveation()
	_apply_gun_opts()
	_apply_volume()
	_load_history()
	for i in Drills.LIST.size():
		drill_items.append("d_%d" % i)
	drill_items.append("back")
	_load_range()
	_refresh_menu()

func _setup_xr() -> void:
	var xr := XRServer.find_interface("OpenXR")
	if xr != null and xr.is_initialized():
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		get_viewport().use_xr = true
		xr.set("foveation_level", 2)
		xr.set("foveation_dynamic", true)
	else:
		push_error("OpenXR did not initialise - launch via Steam / with the VR runtime running.")

func _apply_quality() -> void:
	var q: Dictionary = QUALITY[int(S["quality"])]
	get_viewport().msaa_3d = q["msaa"]
	var xr := XRServer.find_interface("OpenXR")
	if xr != null:
		xr.set("render_target_size_multiplier", float(q["scale"]))

func _load_settings() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		var d = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if d is Dictionary:
			for k in d:
				if S.has(k):
					S[k] = d[k]
	if not Defs.GUNS.has(S["gun"]):
		S["gun"] = "Glock 17"
	if not Defs.OPTICS.has(S["optic"]):
		S["optic"] = "Holosun 507C"
	if not (S["range"] in ["indoor", "outdoor"]):
		S["range"] = "indoor"
	if not (S["dominant"] in ["left", "right"]):
		S["dominant"] = "right"
	S["slot"] = clampi(int(S["slot"]), 1, 5)
	S["grip_pitch"] = int(S["grip_pitch"])
	S["quality"] = clampi(int(S["quality"]), 0, QUALITY.size() - 1)
	if not Defs.MUZZLES.has(S["muzzle"]):
		S["muzzle"] = "None"
	if not (S["holster"] in HOLSTERS):
		S["holster"] = "Hip"
	S["swap_sticks"] = bool(S["swap_sticks"])
	S["ret_style"] = clampi(int(S["ret_style"]), 0, RET_STYLES.size() - 1)
	S["ret_color"] = clampi(int(S["ret_color"]), 0, RET_COLORS.size() - 1)
	S["ret_bright"] = clampi(int(S["ret_bright"]), 0, RET_BRIGHT.size() - 1)
	S["malf"] = clampi(int(S["malf"]), 0, MALF_RATES.size() - 1)
	S["belt"] = clampi(int(S["belt"]), 0, BELTS.size() - 1)
	S["volume"] = clampi(int(S["volume"]), 0, VOLUMES.size() - 1)
	S["par"] = clampi(int(S["par"]), 0, PARS.size() - 1)
	S["fov"] = clampi(int(S["fov"]), 0, FOV_NAMES.size() - 1)
	S["fov_str"] = clampi(int(S["fov_str"]), 0, FOV_STR.size() - 1)
	S["fps"] = bool(S["fps"])
	_fix_binds()

func _fix_binds() -> void:
	var out := {}
	var cur = S["binds"]
	for a in DEFAULT_BINDS:
		var d: Dictionary = DEFAULT_BINDS[a].duplicate()
		if cur is Dictionary and cur.has(a):
			var c = cur[a]
			if c is Dictionary and str(c.get("btn", "")) in BTN_NAMES and str(c.get("hand", "")) in ["gun", "off"]:
				d = {"hand": str(c["hand"]), "btn": str(c["btn"])}
		out[a] = d
	S["binds"] = out

func _save_settings() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(S))

func _unshaded(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = c
	return m

func _build_rig() -> void:
	origin = XROrigin3D.new()
	add_child(origin)
	cam = XRCamera3D.new()
	origin.add_child(cam)
	for side in ["left", "right"]:
		var c := XRController3D.new()
		c.tracker = "%s_hand" % side
		origin.add_child(c)
		c.button_pressed.connect(_on_pressed.bind(c))
		c.button_released.connect(_on_released.bind(c))
		hands[side] = c

func _build_ui_bits() -> void:
	pouch = Defs.box(self, Vector3(0.05, 0.11, 0.035), Vector3.ZERO, Color(0.25, 0.25, 0.3))
	wrist = Label3D.new()
	wrist.pixel_size = 0.0005
	wrist.font_size = 30
	wrist.outline_size = 8
	wrist.modulate = Color(0.7, 1.0, 0.7)
	wrist.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	add_child(wrist)
	pointer = MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.002
	cm.bottom_radius = 0.002
	cm.height = 5.0
	pointer.mesh = cm
	pointer.material_override = _unshaded(Color(0.2, 1.0, 1.0))
	pointer.visible = false
	add_child(pointer)
	arc = MeshInstance3D.new()
	arc.mesh = ImmediateMesh.new()
	arc.material_override = _unshaded(Color(0.3, 0.9, 0.3))
	arc.visible = false
	add_child(arc)
	marker = MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.3
	rm.bottom_radius = 0.3
	rm.height = 0.01
	marker.mesh = rm
	marker.material_override = _unshaded(Color(0.3, 0.9, 0.3))
	marker.visible = false
	add_child(marker)
	tutorial = Label3D.new()
	tutorial.text = "WELCOME TO USPSA VR RANGE\n\n1  Gun hand grip at your hip: draw (grip again to holster)\n2  Off hand grip at your belt: grab a mag, push it into the grip\n3  Off hand grip at the slide, pull back: rack\n4  Off hand X/A: start the timer, shoot, press again to stop\n5  Off hand Y/B: menu - drills, guns, red dots, settings\n\nPress any button to close"
	tutorial.pixel_size = 0.0012
	tutorial.font_size = 40
	tutorial.outline_size = 10
	tutorial.visible = false
	add_child(tutorial)
	board = Label3D.new()
	board.pixel_size = 0.0025
	board.font_size = 40
	board.outline_size = 12
	board.modulate = Color(1.0, 0.9, 0.4)
	board.visible = false
	add_child(board)
	holster = Node3D.new()
	add_child(holster)
	Defs.box(holster, Vector3(0.045, 0.16, 0.07), Vector3(0.0, -0.05, 0.0), Color(0.1, 0.1, 0.1))

func _apply_hands() -> void:
	var dom: String = S["dominant"]
	gun_hand = hands[dom]
	off_hand = hands["left" if dom == "right" else "right"]
	gun_hand.pose = "aim"
	off_hand.pose = "aim"
	_attach_gun()
	wrist.reparent(off_hand, false)
	wrist.position = Vector3(0.0, 0.06, 0.03)
	wrist.rotation_degrees = Vector3(-60.0, 0.0, 0.0)
	pointer.reparent(gun_hand, false)
	pointer.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	pointer.position = Vector3(0.0, 0.0, -2.5)

# ------------------------------------------------------------------ holster

func _attach_gun() -> void:
	if holstered:
		gun.reparent(holster, false)
		gun.position = Vector3.ZERO
		gun.rotation_degrees = Vector3(-90.0, 0.0, 0.0)
	else:
		gun.reparent(gun_hand, false)
		gun.position = Vector3.ZERO
		gun.rotation_degrees = Vector3(float(S["grip_pitch"]), 0.0, 0.0)
	_update_gun_state()

func _holster_toggle() -> void:
	if menu_open or edit_mode:
		return
	var near := gun_hand.global_position.distance_to(holster.global_position) < 0.22
	if not near:
		return
	if gun.slide_grabbed:
		gun.end_rack()
	holstered = not holstered
	_attach_gun()
	_haptic(gun_hand, 0.6, 0.06)
	play("insert" if holstered else "slide", holster.global_position)

# ------------------------------------------------------------------ menu

func _build_menu() -> void:
	menu = Node3D.new()
	menu.visible = false
	add_child(menu)
	var rows := 9
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(1.22, 0.95, 0.02)
	panel.mesh = pm
	panel.material_override = _unshaded(Color(0.05, 0.06, 0.08))
	panel.position = Vector3(0.0, 0.03, -0.02)
	menu.add_child(panel)
	var title := Label3D.new()
	title.text = "USPSA VR RANGE"
	title.pixel_size = 0.001
	title.font_size = 44
	title.position = Vector3(0.0, 0.47, 0.01)
	menu.add_child(title)
	menu_title = title
	menu_stats = Label3D.new()
	menu_stats.pixel_size = 0.0009
	menu_stats.font_size = 34
	menu_stats.position = Vector3(0.0, -0.08, 0.012)
	menu_stats.visible = false
	menu.add_child(menu_stats)
	for i in 18:
		var id: String = "s%d" % i
		var col := 0 if i < rows else 1
		var row := i - col * rows
		var sb := StaticBody3D.new()
		sb.collision_layer = 2
		sb.collision_mask = 0
		sb.set_meta("id", id)
		sb.position = Vector3(-0.3 + col * 0.6, 0.37 - row * 0.085, 0.0)
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(0.56, 0.075, 0.03)
		cs.shape = sh
		sb.add_child(cs)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.56, 0.075, 0.01)
		mi.mesh = bm
		var m := _unshaded(Color(0.18, 0.2, 0.26))
		mi.material_override = m
		sb.add_child(mi)
		var lb := Label3D.new()
		lb.pixel_size = 0.0009
		lb.font_size = 40
		lb.position = Vector3(0.0, 0.0, 0.008)
		sb.add_child(lb)
		menu.add_child(sb)
		menu_body[id] = sb
		menu_bg[id] = m
		menu_lbl[id] = lb

func _next(arr: Array, cur) -> Variant:
	var i := arr.find(cur)
	return arr[(i + 1) % arr.size()]

func _menu_label(id: String) -> String:
	if id.begins_with("d_"):
		var di := int(id.substr(2))
		var dd: Dictionary = Drills.LIST[di]
		var pr := float(dd["par"])
		return str(dd["name"]) + ("  par %.1f" % pr if pr > 0.0 else "")
	if id.begins_with("b_"):
		var a := id.substr(2)
		var b: Dictionary = S["binds"][a]
		if listening == a:
			return str(ACTION_NAMES[a]) + ": press..."
		return "%s: %s %s" % [ACTION_NAMES[a], "Gun" if b["hand"] == "gun" else "Off", BTN_NAMES[b["btn"]]]
	match id:
		"range": return "Range: " + str(S["range"]).capitalize()
		"gun": return "Gun: " + str(S["gun"])
		"optic": return "Optic: " + str(S["optic"])
		"loco": return "Move: " + ("Smooth" if S["smooth_loco"] else "Teleport")
		"turn": return "Turn: " + ("Smooth" if S["smooth_turn"] else "Snap")
		"grip": return "Grip angle: %d deg" % int(S["grip_pitch"])
		"hand": return "Gun hand: " + str(S["dominant"]).capitalize()
		"quality":
			var q: Dictionary = QUALITY[int(S["quality"])]
			return "Quality: " + str(q["name"])
		"muzzle": return "Muzzle: " + str(S["muzzle"])
		"holster": return "Holster: " + str(S["holster"])
		"ammo": return "Show ammo: " + ("ON" if S["show_ammo"] else "OFF")
		"edit": return "Target editor: " + ("ON" if edit_mode else "OFF")
		"slot": return "Layout slot: %d" % int(S["slot"])
		"save": return "Save layout"
		"load": return "Load layout"
		"clear": return "Clear targets"
		"controls": return "Controls / remap..."
		"drills": return "Drills / stages..."
		"gunpage": return "Gun, optic, belt..."
		"layoutpage": return "Target layout..."
		"settings": return "Settings..."
		"stats": return "Stats / history..."
		"tutorial": return "Show tutorial"
		"recenter": return "Recenter to start"
		"ret_style": return "Reticle: " + str(RET_STYLES[int(S["ret_style"])])
		"ret_color": return "Reticle color: " + str(RET_COLORS[int(S["ret_color"])][0])
		"ret_bright": return "Reticle bright: %d%%" % int(float(RET_BRIGHT[int(S["ret_bright"])]) * 100.0)
		"malf": return "Malfunctions: " + str(MALF_NAMES[int(S["malf"])])
		"belt": return "Belt: %d cm below eyes" % int(float(BELTS[int(S["belt"])]) * 100.0)
		"volume": return "Volume: %d%%" % int(float(VOLUMES[int(S["volume"])]) * 100.0)
		"haptics": return "Haptics: " + ("ON" if S["haptics"] else "OFF")
		"markers": return "Hit markers: " + ("ON" if S["markers"] else "OFF")
		"board": return "Scoreboard: " + ("ON" if S["board"] else "OFF")
		"par": return "Par timer: " + ("Off" if float(PARS[int(S["par"])]) <= 0.0 else "%.1f s" % float(PARS[int(S["par"])]))
		"clear_hist": return "Clear history"
		"fov": return "Foveation: " + str(FOV_NAMES[int(S["fov"])])
		"fov_str": return "Fov strength: " + str(FOV_STR[int(S["fov_str"])])
		"fps": return "Show FPS: " + ("ON" if S["fps"] else "OFF")
		"back": return "< Back"
		"swap": return "Swap sticks: " + ("ON" if S["swap_sticks"] else "OFF")
		"reset_binds": return "Reset controls"
		"close": return "Close menu"
	return id

func _page_items() -> Array:
	match menu_page:
		1:
			return REMAP_ITEMS
		2:
			return drill_items
		3:
			return STATS_ITEMS
		4:
			return GUN_ITEMS
		5:
			return LAYOUT_ITEMS
		6:
			return SETTINGS_ITEMS
	return MENU_ITEMS

func _refresh_menu() -> void:
	var items := _page_items()
	for i in 18:
		var sid := "s%d" % i
		var body: StaticBody3D = menu_body[sid]
		var on := i < items.size()
		body.visible = on
		body.collision_layer = 2 if on else 0
		if on:
			body.set_meta("id", items[i])
			(menu_lbl[sid] as Label3D).text = _menu_label(items[i])
	menu_title.text = PAGE_TITLES[menu_page]
	menu_stats.visible = menu_page == 3
	if menu_page == 3:
		menu_stats.text = _stats_text()

func _toggle_menu() -> void:
	if menu_open:
		_close_menu()
	else:
		_open_menu()

func _open_menu() -> void:
	menu_open = true
	menu_page = 0
	listening = ""
	menu.visible = true
	menu.global_transform = Transform3D(Basis.looking_at(body_fwd, Vector3.UP), cam.global_position + body_fwd * 0.95 + Vector3(0.0, -0.1, 0.0))
	_refresh_menu()
	_update_gun_state()

func _close_menu() -> void:
	menu_open = false
	listening = ""
	menu.visible = false
	_update_gun_state()

func _update_gun_state() -> void:
	gun.enabled = not (menu_open or edit_mode or holstered)
	gun.visible = not (menu_open or edit_mode)

func _menu_click() -> void:
	if hover != "":
		_do_menu(hover)

func _do_menu(id: String) -> void:
	if id.begins_with("d_"):
		_load_drill(int(id.substr(2)))
		_close_menu()
		return
	if id.begins_with("b_"):
		listening = "" if listening == id.substr(2) else id.substr(2)
		_refresh_menu()
		play("menu", Vector3.INF)
		return
	match id:
		"range":
			S["range"] = "outdoor" if S["range"] == "indoor" else "indoor"
			_load_range()
		"gun":
			S["gun"] = _next(Defs.GUNS.keys(), S["gun"])
			_rebuild_gun()
		"optic":
			S["optic"] = _next(Defs.OPTICS.keys(), S["optic"])
			_rebuild_gun()
		"loco":
			S["smooth_loco"] = not S["smooth_loco"]
		"turn":
			S["smooth_turn"] = not S["smooth_turn"]
		"grip":
			S["grip_pitch"] = _next(GRIP_PITCHES, S["grip_pitch"])
			_attach_gun()
		"hand":
			S["dominant"] = "left" if S["dominant"] == "right" else "right"
			_apply_hands()
		"quality":
			S["quality"] = (int(S["quality"]) + 1) % QUALITY.size()
			_apply_quality()
		"muzzle":
			S["muzzle"] = _next(Defs.MUZZLES.keys(), S["muzzle"])
			_rebuild_gun()
		"holster":
			S["holster"] = _next(HOLSTERS, S["holster"])
		"ammo":
			S["show_ammo"] = not S["show_ammo"]
		"edit":
			_close_menu()
			_set_edit(not edit_mode)
		"slot":
			S["slot"] = int(S["slot"]) % 5 + 1
		"save":
			_save_layout()
		"load":
			_load_layout(false)
		"clear":
			_clear_targets()
		"controls":
			menu_page = 1
		"drills":
			menu_page = 2
		"stats":
			menu_page = 3
		"gunpage":
			menu_page = 4
		"layoutpage":
			menu_page = 5
		"settings":
			menu_page = 6
		"tutorial":
			_close_menu()
			_show_tutorial()
		"recenter":
			origin.global_transform = Transform3D(Basis.IDENTITY, Vector3.ZERO)
			_teleport_to(Vector3.ZERO)
		"ret_style":
			S["ret_style"] = (int(S["ret_style"]) + 1) % RET_STYLES.size()
			_apply_gun_opts()
		"ret_color":
			S["ret_color"] = (int(S["ret_color"]) + 1) % RET_COLORS.size()
			_apply_gun_opts()
		"ret_bright":
			S["ret_bright"] = (int(S["ret_bright"]) + 1) % RET_BRIGHT.size()
			_apply_gun_opts()
		"malf":
			S["malf"] = (int(S["malf"]) + 1) % MALF_RATES.size()
			_apply_gun_opts()
		"belt":
			S["belt"] = (int(S["belt"]) + 1) % BELTS.size()
		"volume":
			S["volume"] = (int(S["volume"]) + 1) % VOLUMES.size()
			_apply_volume()
		"haptics":
			S["haptics"] = not S["haptics"]
		"markers":
			S["markers"] = not S["markers"]
		"board":
			S["board"] = not S["board"]
			board.visible = board.visible and S["board"]
		"par":
			S["par"] = (int(S["par"]) + 1) % PARS.size()
		"clear_hist":
			history = {"runs": []}
			_save_history()
		"fov":
			S["fov"] = (int(S["fov"]) + 1) % FOV_NAMES.size()
			_apply_foveation()
		"fov_str":
			S["fov_str"] = (int(S["fov_str"]) + 1) % FOV_STR.size()
			_apply_foveation()
		"fps":
			S["fps"] = not S["fps"]
		"back":
			menu_page = 0
			listening = ""
		"swap":
			S["swap_sticks"] = not S["swap_sticks"]
		"reset_binds":
			S["binds"] = {}
			S["swap_sticks"] = false
			_fix_binds()
		"close":
			_close_menu()
	_save_settings()
	_refresh_menu()
	play("menu", Vector3.INF)

func _rebuild_gun() -> void:
	if held_mag != null:
		held_mag.queue_free()
		held_mag = null
	gun.build(S["gun"], S["optic"], S["muzzle"])
	_attach_gun()
	_apply_gun_opts()

# ------------------------------------------------------------------ range + targets

func _load_range() -> void:
	if range_root != null:
		world.remove_child(range_root)
		range_root.queue_free()
	range_root = Node3D.new()
	world.add_child(range_root)
	bounds = RangeBuilder.build(S["range"], range_root)
	origin.global_transform = Transform3D(Basis.IDENTITY, Vector3.ZERO)
	_teleport_to(Vector3.ZERO)
	_load_layout(true)

func _layout_path() -> String:
	return "user://layout_%s_%d.json" % [S["range"], int(S["slot"])]

func spawn(kind: int, motion: int, pos: Vector3, yaw: float) -> void:
	var t := Target.new()
	t.setup(kind, motion)
	t.position = pos
	t.rotation.y = yaw
	targets_root.add_child(t)

func spawn_barricade(model: int, tex: int, pos: Vector3, yaw: float) -> void:
	var b := Barricade.new()
	b.setup(model, tex)
	b.position = pos
	b.rotation.y = yaw
	targets_root.add_child(b)

func _spawn_preset(idx: int, pos: Vector3, yaw: float) -> void:
	var p: Dictionary = Target.PRESETS[idx]
	spawn(int(p["kind"]), int(p["motion"]), pos, yaw)

func _clear_targets() -> void:
	carried = null
	for c in targets_root.get_children():
		targets_root.remove_child(c)
		c.queue_free()

func _save_layout() -> void:
	var arr := []
	var barr := []
	for c in targets_root.get_children():
		if c is Target:
			arr.append((c as Target).to_dict())
		elif c is Barricade:
			barr.append((c as Barricade).to_dict())
	var f := FileAccess.open(_layout_path(), FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"targets": arr, "barricades": barr}))
		_flash("Saved slot %d (%d targets)" % [int(S["slot"]), arr.size()])

func _load_layout(use_default: bool) -> void:
	drill_idx = 0
	var path := _layout_path()
	if not FileAccess.file_exists(path):
		if use_default:
			_clear_targets()
			_default_layout()
		else:
			_flash("Slot %d is empty" % int(S["slot"]))
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if data is Dictionary and data.has("targets"):
		_clear_targets()
		for e in data["targets"]:
			var p: Array = e["pos"]
			spawn(int(e["kind"]), int(e.get("motion", 0)), Vector3(p[0], p[1], p[2]), float(e["yaw"]))
		for e in data.get("barricades", []):
			var bp: Array = e["pos"]
			spawn_barricade(int(e["model"]), int(e["tex"]), Vector3(bp[0], bp[1], bp[2]), float(e["yaw"]))
		_flash("Loaded slot %d" % int(S["slot"]))

func _default_layout() -> void:
	if S["range"] == "indoor":
		spawn(0, 0, Vector3(-2.5, 0, -8), 0.0)
		spawn(0, 0, Vector3(0, 0, -9), 0.0)
		spawn(0, 0, Vector3(2.5, 0, -8), 0.0)
		spawn(1, 0, Vector3(-3, 0, -14), 0.0)
		spawn(2, 0, Vector3(0.5, 0, -12), 0.0)
		spawn(3, 0, Vector3(0, 0, -18), 0.0)
		spawn(4, 0, Vector3(-3, 0, -20), 0.0)
		spawn(5, 0, Vector3(3, 0, -20), 0.0)
		spawn(4, 1, Vector3(0, 0, -23), 0.0)
		_spawn_preset(11, Vector3(-4, 1.5, -15), 0.0)
		_spawn_preset(12, Vector3(4, 1.5, -16), 0.0)
		spawn_barricade(0, 0, Vector3(-1.5, 0, -4), 0.0)
		spawn_barricade(1, 1, Vector3(2.0, 0, -5), 0.0)
	else:
		spawn(0, 0, Vector3(-4, 0, -10), 0.0)
		spawn(0, 0, Vector3(4, 0, -10), 0.0)
		spawn(1, 0, Vector3(0, 0, -16), 0.0)
		spawn(2, 0, Vector3(-2, 0, -16), 0.0)
		spawn(3, 0, Vector3(5, 0, -22), 0.0)
		spawn(4, 0, Vector3(-5, 0, -26), 0.0)
		spawn(5, 0, Vector3(0, 0, -30), 0.0)
		spawn(4, 1, Vector3(0, 0, -34), 0.0)
		spawn(0, 1, Vector3(0, 0, -20), 0.0)
		_spawn_preset(10, Vector3(8, 0, -24), 0.0)
		_spawn_preset(13, Vector3(-8, 1.5, -30), 0.0)
		spawn_barricade(2, 4, Vector3(0, 0, -6), 0.0)
		spawn_barricade(4, 2, Vector3(-6, 0, -9), 0.0)

# ------------------------------------------------------------------ editor

func _floats(n: Node3D) -> bool:
	return n is Target and (n as Target).floating

func _edit_name() -> String:
	var np := Target.PRESETS.size()
	if edit_kind < np:
		var p: Dictionary = Target.PRESETS[edit_kind]
		return str(p["name"])
	var m: Dictionary = Barricade.MODELS[edit_kind - np]
	return "%s [%s]" % [m["name"], Defs.TEXTURES[edit_tex]]

func _set_edit(on: bool) -> void:
	if not on:
		_drop_carried()
		if ghost != null:
			ghost.queue_free()
			ghost = null
	edit_mode = on
	if on:
		_rebuild_ghost()
	_update_gun_state()

func _rebuild_ghost() -> void:
	if ghost != null:
		ghost.queue_free()
	var np := Target.PRESETS.size()
	if edit_kind < np:
		var p: Dictionary = Target.PRESETS[edit_kind]
		var t := Target.new()
		t.setup(int(p["kind"]), int(p["motion"]))
		t.collision_layer = 0
		t.active = false
		ghost = t
	else:
		var bb := Barricade.new()
		bb.setup(edit_kind - np, edit_tex)
		bb.collision_layer = 0
		ghost = bb
	add_child(ghost)
	ghost.visible = false

func _cycle_kind() -> void:
	edit_kind = (edit_kind + 1) % (Target.PRESETS.size() + Barricade.MODELS.size())
	_rebuild_ghost()

func _cycle_tex() -> void:
	edit_tex = (edit_tex + 1) % Defs.TEXTURES.size()
	if carried != null and is_instance_valid(carried) and carried is Barricade:
		(carried as Barricade).set_tex(edit_tex)
	elif ghost is Barricade:
		(ghost as Barricade).set_tex(edit_tex)

func _edit_trigger() -> void:
	if carried != null:
		_drop_carried()
		return
	var h := aim_ray(20)
	if not h.is_empty() and (h["collider"] is Target or h["collider"] is Barricade):
		carried = h["collider"] as Node3D
		carried.call("grab")
		return
	if ghost_ok:
		var np := Target.PRESETS.size()
		if edit_kind < np:
			_spawn_preset(edit_kind, ghost.position, ghost.rotation.y)
		else:
			spawn_barricade(edit_kind - np, edit_tex, ghost.position, ghost.rotation.y)
		play("insert", ghost.global_position)

func _drop_carried() -> void:
	if carried != null and is_instance_valid(carried):
		carried.call("release")
	carried = null

func _delete_target() -> void:
	if carried != null and is_instance_valid(carried):
		carried.queue_free()
		carried = null
		return
	var h := aim_ray(20)
	if not h.is_empty() and (h["collider"] is Target or h["collider"] is Barricade):
		(h["collider"] as Node3D).queue_free()

func aim_ray(mask: int) -> Dictionary:
	var from := gun_hand.global_position
	var to := from - gun_hand.global_basis.z * 60.0
	var q := PhysicsRayQueryParameters3D.create(from, to, mask)
	return get_world_3d().direct_space_state.intersect_ray(q)

# ------------------------------------------------------------------ input

func _on_pressed(btn: String, hand: XRController3D) -> void:
	if gun_hand == null:
		return
	if tutorial.visible:
		tutorial.visible = false
		S["seen_tutorial"] = true
		_save_settings()
		return
	var role := "gun" if hand == gun_hand else "off"
	if listening != "":
		_capture(role, btn)
		return
	if btn == "menu_button" or btn == "select_button":
		_toggle_menu()
		return
	if menu_open and btn == "trigger_click":
		_menu_click()
		return
	for a in S["binds"]:
		var b: Dictionary = S["binds"][a]
		if b["hand"] == role and b["btn"] == btn:
			_do_action(a)

func _on_released(btn: String, hand: XRController3D) -> void:
	var role := "gun" if hand == gun_hand else "off"
	var b: Dictionary = S["binds"]["grab"]
	if b["hand"] == role and b["btn"] == btn:
		_grip_up()

func _capture(role: String, btn: String) -> void:
	if btn == "menu_button" or btn == "select_button":
		listening = ""
	elif BTN_NAMES.has(btn):
		var a := listening
		if FIXED_HAND.has(a) and FIXED_HAND[a] != role:
			_flash("%s must use the %s hand controller" % [ACTION_NAMES[a], "gun" if FIXED_HAND[a] == "gun" else "off"])
			return
		var old: Dictionary = S["binds"][a]
		for o in S["binds"]:
			var ob: Dictionary = S["binds"][o]
			if o != a and ob["hand"] == role and ob["btn"] == btn:
				if FIXED_HAND.has(o) and FIXED_HAND[o] != old["hand"]:
					_flash("Already used by " + str(ACTION_NAMES[o]))
					return
				S["binds"][o] = {"hand": old["hand"], "btn": old["btn"]}
		S["binds"][a] = {"hand": role, "btn": btn}
		listening = ""
		_save_settings()
	else:
		return
	_refresh_menu()
	play("menu", Vector3.INF)

func _do_action(a: String) -> void:
	match a:
		"fire":
			if menu_open:
				_menu_click()
			elif edit_mode:
				_edit_trigger()
			else:
				gun.pull_trigger()
		"drop_mag":
			if edit_mode:
				_delete_target()
			elif not menu_open:
				gun.drop_mag()
		"slide_release":
			if edit_mode:
				_cycle_kind()
			elif not menu_open:
				gun.slide_release()
		"holster":
			_holster_toggle()
		"timer":
			if edit_mode:
				_cycle_tex()
			else:
				_timer_button()
		"menu":
			_toggle_menu()
		"grab":
			_grip_down()

func _held(a: String) -> bool:
	var b: Dictionary = S["binds"][a]
	var h := gun_hand if b["hand"] == "gun" else off_hand
	return h.is_button_pressed(str(b["btn"]))

func _move_hand() -> XRController3D:
	return gun_hand if S["swap_sticks"] else off_hand

func _turn_hand() -> XRController3D:
	return off_hand if S["swap_sticks"] else gun_hand

func _grip_down() -> void:
	if menu_open or edit_mode:
		return
	var p := off_hand.global_position
	if held_mag == null and gun.can_grab_slide(p):
		gun.begin_rack(p)
	elif held_mag == null and not gun.slide_grabbed and p.distance_to(pouch.global_position) < 0.16:
		held_mag = Mag.new()
		var cap: int = gun.cfg["cap"]
		var ml: float = gun.cfg["mag_len"]
		held_mag.setup(cap, ml)
		world.add_child(held_mag)
		held_mag.hold()
		held_mag.global_transform = off_hand.global_transform * hold_xf
		_haptic(off_hand, 0.5, 0.05)
		play("insert", p)

func _grip_up() -> void:
	if gun.slide_grabbed:
		gun.end_rack()
	if held_mag != null:
		held_mag.drop(Vector3.ZERO)
		held_mag = null

func _on_shot(xf: Transform3D) -> void:
	var from := xf.origin
	var dir := -xf.basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 300.0, 5)
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var running := tstate == T.RUNNING
	if running:
		shots.append(elapsed())
	if not hit.is_empty() and hit["collider"] is Target:
		var tg := hit["collider"] as Target
		var z := tg.register_hit(hit["position"], running)
		if z != "":
			play("ping" if tg.is_steel() else "thud", hit["position"])
			_hit_marker(hit["position"], z)
			if running and run_zones.has(z):
				run_zones[z] += 1
	elif not hit.is_empty() and hit["collider"] is Barricade:
		play("thud", hit["position"])
	_haptic(gun_hand, 1.0, 0.08)

func play(key: String, pos: Vector3) -> void:
	var stream := Defs.sfx(key)
	if pos == Vector3.INF:
		ui_player.stream = stream
		ui_player.play()
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.unit_size = 8.0
	add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()

# ------------------------------------------------------------------ timer + scoring

func elapsed() -> float:
	return float(Time.get_ticks_usec() - t_start) / 1000000.0

func _timer_button() -> void:
	match tstate:
		T.IDLE, T.DONE:
			_reset_run()
			tstate = T.ARMED
			arm_left = randf_range(2.0, 4.0)
			play("standby", Vector3.INF)
			_place_board()
		T.ARMED:
			tstate = T.IDLE
		T.RUNNING:
			_stop_run()

func _reset_run() -> void:
	shots.clear()
	result = ""
	run_zones = {"A": 0, "C": 0, "D": 0, "NS": 0, "S": 0}
	for c in targets_root.get_children():
		if c is Target:
			(c as Target).reset_state()

func _par() -> float:
	if drill_idx > 0:
		return float(Drills.LIST[drill_idx]["par"])
	return float(PARS[int(S["par"])])

func _stop_run() -> void:
	tstate = T.DONE
	var tot := {"A": 0, "C": 0, "D": 0, "NS": 0, "M": 0, "S": 0, "pts": 0}
	for c in targets_root.get_children():
		if c is Target:
			var d: Dictionary = (c as Target).tally()
			for k in tot:
				tot[k] += d[k]
	var tt := elapsed()
	if shots.size() > 0:
		tt = shots[shots.size() - 1]
	var pts: int = tot["pts"]
	var hf := maxf(float(pts), 0.0) / maxf(tt, 0.01)
	var hits_n := int(run_zones["A"]) + int(run_zones["C"]) + int(run_zones["D"]) + int(run_zones["S"])
	var acc := 0.0
	if shots.size() > 0:
		acc = 100.0 * float(hits_n) / float(shots.size())
	result = "TIME %.2f   PTS %d   HF %.3f\nA %d  C %d  D %d  M %d  NS %d  Steel %d\nShots %d  Hits %d  Acc %d%%" % [tt, pts, hf, tot["A"], tot["C"], tot["D"], tot["M"], tot["NS"], tot["S"], shots.size(), hits_n, int(acc)]
	if shots.size() > 0:
		result += "\nDraw %.2f" % float(shots[0])
	if shots.size() > 1:
		var sp := ""
		for i in range(1, mini(shots.size(), 9)):
			sp += "%.2f " % (float(shots[i]) - float(shots[i - 1]))
		result += "  Splits: " + sp
	if drill_idx > 0:
		var dd: Dictionary = Drills.LIST[drill_idx]
		var ok: bool = int(run_zones["A"]) >= int(dd["goal_a"]) and int(run_zones["S"]) >= int(dd["goal_s"]) and int(run_zones["NS"]) == 0
		result = "%s: %s  (A %d/%d  Steel %d/%d)\n" % [dd["name"], "PASS" if ok else "FAIL", int(run_zones["A"]), int(dd["goal_a"]), int(run_zones["S"]), int(dd["goal_s"])] + result
	if _record_run(tt, pts, hf, acc):
		result = "NEW PERSONAL BEST!\n" + result
		play("beep", Vector3.INF)

func _flash(msg: String) -> void:
	flash_msg = msg
	flash_until = Time.get_ticks_msec() / 1000.0 + 2.5

func _refresh_wrist() -> void:
	var lines := PackedStringArray()
	if drill_idx > 0:
		var dd: Dictionary = Drills.LIST[drill_idx]
		lines.append("DRILL: %s  par %.1f" % [dd["name"], float(dd["par"])])
	elif _par() > 0.0:
		lines.append("PAR %.1f s" % _par())
	var btn: String = BTN_NAMES[S["binds"]["timer"]["btn"]]
	match tstate:
		T.IDLE:
			lines.append("TIMER READY  [%s]" % btn)
		T.ARMED:
			lines.append("STANDBY...")
		T.RUNNING:
			lines.append("%.2f s   shots %d   [%s] stop" % [elapsed(), shots.size(), btn])
		T.DONE:
			lines.append(result)
	if edit_mode:
		lines.append("EDIT: " + _edit_name())
		lines.append("Trig place/grab+drop  A del  B type")
		lines.append("OffX texture  Stick Y height  Grip+stick rotate")
	elif S["show_ammo"]:
		var mr := 0
		if gun.mag != null:
			mr = gun.mag.rounds
		lines.append("Mag %d  Chamber %d" % [mr, 1 if gun.chambered else 0])
	if holstered and not edit_mode:
		lines.append("HOLSTERED - grip at hip to draw")
	if gun.jammed:
		lines.append("MALFUNCTION - rack the slide")
	if S["fps"]:
		lines.append("FPS %d   %s" % [int(Engine.get_frames_per_second()), _fov_status()])
	if Time.get_ticks_msec() / 1000.0 < flash_until:
		lines.append(flash_msg)
	wrist.text = "\n".join(lines)
	_update_board()

# ------------------------------------------------------------------ per-frame

func _process(delta: float) -> void:
	if gun_hand == null:
		return
	_update_body()
	if tutorial_wait > 0.0:
		tutorial_wait -= delta
		if tutorial_wait <= 0.0 and not S["seen_tutorial"]:
			_show_tutorial()
	_locomotion(delta)
	_hand_logic()
	_update_foveation(delta)
	_pointer_logic()
	if tstate == T.ARMED:
		arm_left -= delta
		if arm_left <= 0.0:
			tstate = T.RUNNING
			t_start = Time.get_ticks_usec()
			play("beep", Vector3.INF)
	elif tstate == T.RUNNING and _par() > 0.0 and elapsed() >= _par():
		play("beep", Vector3.INF)
		_stop_run()
	hud_acc += delta
	if hud_acc > 0.12:
		hud_acc = 0.0
		_refresh_wrist()

func _update_body() -> void:
	var f := -cam.global_basis.z
	f.y = 0.0
	if f.length() > 0.25:
		body_fwd = f.normalized()
	var right := body_fwd.cross(Vector3.UP)
	var side := 1.0 if off_hand == hands["right"] else -1.0
	pouch.global_transform = Transform3D(Basis.looking_at(body_fwd, Vector3.UP), cam.global_position + Vector3(0.0, -float(BELTS[int(S["belt"])]), 0.0) + right * side * 0.17 + body_fwd * 0.12)
	var dom_side := 1.0 if S["dominant"] == "right" else -1.0
	var hp := cam.global_position + Vector3(0.0, -float(BELTS[int(S["belt"])]), 0.0) + right * dom_side * 0.2
	if S["holster"] == "Appendix":
		hp = cam.global_position + Vector3(0.0, -(float(BELTS[int(S["belt"])]) - 0.04), 0.0) + right * dom_side * 0.07 + body_fwd * 0.16
	holster.global_transform = Transform3D(Basis.looking_at(body_fwd, Vector3.UP), hp)

func _hand_logic() -> void:
	if held_mag != null:
		held_mag.global_transform = off_hand.global_transform * hold_xf
		if gun.can_accept(held_mag):
			gun.seat_mag(held_mag)
			held_mag = null
			_haptic(off_hand, 0.6, 0.06)
	if gun.slide_grabbed:
		gun.update_rack(off_hand.global_position)

func _set_pointer_len(h: Dictionary) -> void:
	var dist := 6.0
	if not h.is_empty():
		dist = gun_hand.global_position.distance_to(h["position"])
	(pointer.mesh as CylinderMesh).height = dist
	pointer.position.z = -dist * 0.5

func _pointer_logic() -> void:
	pointer.visible = menu_open or edit_mode
	hover = ""
	if menu_open:
		var h := aim_ray(2)
		_set_pointer_len(h)
		if not h.is_empty():
			var col := h["collider"] as Node
			if col != null and col.has_meta("id"):
				hover = str(col.get_meta("id"))
		for id in menu_bg:
			var m: StandardMaterial3D = menu_bg[id]
			var sel := hover != "" and str((menu_body[id] as Node).get_meta("id", "")) == hover
			m.albedo_color = Color(0.3, 0.5, 0.85) if sel else Color(0.18, 0.2, 0.26)
	elif edit_mode and ghost != null:
		var h := aim_ray(1)
		_set_pointer_len(h)
		ghost_ok = false
		var have_carry := carried != null and is_instance_valid(carried)
		if not h.is_empty():
			var n: Vector3 = h["normal"]
			var pt: Vector3 = h["position"]
			if n.y > 0.7:
				ghost_ok = true
				var subj: Node3D = ghost
				if have_carry:
					subj = carried
				var hp := pt
				if _floats(subj):
					hp += Vector3(0.0, edit_height, 0.0)
				if have_carry:
					carried.position = hp
				else:
					var d := cam.global_position - pt
					ghost.position = hp
					ghost.rotation.y = atan2(d.x, d.z) + ghost_yaw
		ghost.visible = ghost_ok and not have_carry

# ------------------------------------------------------------------ locomotion

func _turn(rad: float) -> void:
	var pivot := Vector3(cam.global_position.x, origin.global_position.y, cam.global_position.z)
	var xf := origin.global_transform
	xf.origin -= pivot
	xf = Transform3D(Basis(Vector3.UP, rad), Vector3.ZERO) * xf
	xf.origin += pivot
	origin.global_transform = xf

func _teleport_to(target: Vector3) -> void:
	var h := cam.global_position
	origin.global_position += Vector3(target.x - h.x, 0.0, target.z - h.z)
	_keep_in_bounds()

func _keep_in_bounds() -> void:
	var h := cam.global_position
	var c := Vector3(clampf(h.x, bounds.position.x, bounds.end.x), h.y, clampf(h.z, bounds.position.y, bounds.end.y))
	origin.global_position += c - h

func _locomotion(delta: float) -> void:
	var ms := _move_hand().get_vector2("primary")
	var ts := _turn_hand().get_vector2("primary")
	if edit_mode and not _held("holster"):
		edit_height = clampf(edit_height + ts.y * delta * 1.2, 0.3, 4.0)
	if edit_mode and _held("holster"):
		var r := -ts.x * deg_to_rad(90.0) * delta
		if carried != null and is_instance_valid(carried):
			carried.rotation.y += r
		else:
			ghost_yaw += r
	elif S["smooth_turn"]:
		if absf(ts.x) > 0.2:
			_turn(-ts.x * deg_to_rad(100.0) * delta)
	else:
		if absf(ts.x) < 0.4:
			snap_ready = true
		elif snap_ready and absf(ts.x) > 0.7:
			snap_ready = false
			_turn(-signf(ts.x) * deg_to_rad(30.0))
	if S["smooth_loco"]:
		if ms.length() > 0.15:
			var right := body_fwd.cross(Vector3.UP)
			origin.global_position += (right * ms.x + body_fwd * ms.y) * 2.2 * delta
	else:
		_teleport(ms)
	_keep_in_bounds()

func _teleport(ms: Vector2) -> void:
	if ms.y > 0.5:
		tele_aiming = true
		var p0 := _move_hand().global_position
		var v0 := -_move_hand().global_basis.z * 7.0
		var im := arc.mesh as ImmediateMesh
		im.clear_surfaces()
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		im.surface_add_vertex(p0)
		var prev := p0
		tele_valid = false
		for i in range(1, 70):
			var t := i * 0.045
			var p := p0 + v0 * t + Vector3(0.0, -4.9 * t * t, 0.0)
			if p.y <= 0.0 and prev.y > 0.0:
				var k := prev.y / (prev.y - p.y)
				tele_target = prev.lerp(p, k)
				im.surface_add_vertex(tele_target)
				tele_valid = true
				break
			im.surface_add_vertex(p)
			prev = p
		im.surface_end()
		arc.visible = true
		marker.visible = tele_valid
		marker.global_position = tele_target + Vector3(0.0, 0.01, 0.0)
	elif tele_aiming:
		tele_aiming = false
		arc.visible = false
		marker.visible = false
		if tele_valid:
			_teleport_to(tele_target)

# ------------------------------------------------------------------ drills, history, extras

func _drill_name() -> String:
	return str(Drills.LIST[drill_idx]["name"])

func _load_drill(i: int) -> void:
	if i <= 0:
		_load_layout(true)
		_flash("Free practice")
		return
	var d: Dictionary = Drills.LIST[i]
	_clear_targets()
	for t in d["t"]:
		spawn(int(t[0]), int(t[1]), Vector3(float(t[2]), float(t[3]), float(t[4])), 0.0)
	for b in d["b"]:
		spawn_barricade(int(b[0]), int(b[1]), Vector3(float(b[2]), 0.0, float(b[3])), 0.0)
	drill_idx = i
	tstate = T.IDLE
	_flash("%s: %s" % [d["name"], d["info"]])

func _load_history() -> void:
	var path := "user://history.json"
	if FileAccess.file_exists(path):
		var d = JSON.parse_string(FileAccess.get_file_as_string(path))
		if d is Dictionary and d.has("runs") and d["runs"] is Array:
			history = d

func _save_history() -> void:
	var f := FileAccess.open("user://history.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(history))

func _record_run(tt: float, pts: int, hf: float, acc: float) -> bool:
	var dn := _drill_name()
	var best := 0.0
	var seen := false
	var runs: Array = history["runs"]
	for r in runs:
		if r["drill"] == dn:
			seen = true
			best = maxf(best, float(r["hf"]))
	runs.append({"drill": dn, "t": tt, "pts": pts, "hf": hf, "acc": acc, "gun": S["gun"], "range": S["range"], "when": Time.get_datetime_string_from_system()})
	while runs.size() > 200:
		runs.pop_front()
	_save_history()
	return seen and hf > best and hf > 0.0

func _stats_text() -> String:
	var dn := _drill_name()
	var mine := []
	var runs: Array = history["runs"]
	for r in runs:
		if r["drill"] == dn:
			mine.append(r)
	var lines := PackedStringArray()
	lines.append("Drill: %s   runs: %d" % [dn, mine.size()])
	if mine.size() > 0:
		var best := 0.0
		var sum := 0.0
		for r in mine:
			best = maxf(best, float(r["hf"]))
			sum += float(r["hf"])
		lines.append("Best HF %.3f    Avg HF %.3f" % [best, sum / mine.size()])
		lines.append("Last runs: time / points / HF / accuracy")
		var start := maxi(0, mine.size() - 6)
		for i in range(mine.size() - 1, start - 1, -1):
			var m = mine[i]
			lines.append("%.2fs   %d   %.3f   %d%%" % [float(m["t"]), int(m["pts"]), float(m["hf"]), int(m["acc"])])
	lines.append("")
	lines.append("All-time runs: %d  (pick a drill to see its stats)" % runs.size())
	return "\n".join(lines)

func _apply_gun_opts() -> void:
	var rc: Array = RET_COLORS[int(S["ret_color"])]
	gun.set_reticle(int(S["ret_style"]), rc[1], float(RET_BRIGHT[int(S["ret_bright"])]))
	gun.malf_rate = float(MALF_RATES[int(S["malf"])])

func _apply_volume() -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(float(VOLUMES[int(S["volume"])])))

func _haptic(hand: XRController3D, amp: float, dur: float) -> void:
	if S["haptics"]:
		hand.trigger_haptic_pulse("haptic", 0.0, amp, dur, 0.0)

func _show_tutorial() -> void:
	tutorial.global_transform = Transform3D(Basis.looking_at(body_fwd, Vector3.UP), cam.global_position + body_fwd * 1.3 + Vector3(0.0, -0.05, 0.0))
	tutorial.visible = true

func _place_board() -> void:
	if not S["board"]:
		return
	board.global_transform = Transform3D(Basis.looking_at(body_fwd, Vector3.UP), cam.global_position + body_fwd * 3.0 + Vector3(0.0, 0.4, 0.0))
	board.visible = true

func _update_board() -> void:
	if not S["board"] or not board.visible:
		return
	match tstate:
		T.IDLE:
			board.text = ""
		T.ARMED:
			board.text = "STANDBY"
		T.RUNNING:
			board.text = "%.2f\nShots %d" % [elapsed(), shots.size()]
		T.DONE:
			board.text = result

func _hit_marker(p: Vector3, z: String) -> void:
	if not S["markers"]:
		return
	var l := Label3D.new()
	l.text = z
	l.font_size = 64
	l.pixel_size = 0.0015
	l.outline_size = 10
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	match z:
		"A":
			l.modulate = Color(0.3, 1.0, 0.3)
		"C":
			l.modulate = Color(1.0, 0.9, 0.2)
		"D":
			l.modulate = Color(1.0, 0.6, 0.2)
		"NS":
			l.modulate = Color(1.0, 0.2, 0.2)
		_:
			l.modulate = Color(0.4, 0.9, 1.0)
	add_child(l)
	l.global_position = p + Vector3(0.0, 0.12, 0.0)
	var tw := l.create_tween()
	tw.tween_property(l, "position:y", l.position.y + 0.25, 1.0)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 1.0)
	tw.tween_callback(l.queue_free)

# ------------------------------------------------------------------ foveated rendering
# Off: no foveation. Fixed: runtime foveation via XR VRS (fixed centre, level from strength).
# Eye-tracked: a density map is built every ~50 ms around the gaze point from the Frame's eye tracking
# (XR_EXT_eye_gaze_interaction) and applied with the viewport's VRS texture. If no gaze data arrives for
# 3 s it falls back to Fixed until gaze data returns.

func _fov_status() -> String:
	match int(S["fov"]):
		0:
			return "FOV off"
		1:
			return "FOV fixed " + str(FOV_STR[int(S["fov_str"])])
	if eye_active:
		return "FOV eye " + str(FOV_STR[int(S["fov_str"])])
	return "FOV eye: no gaze, fixed"

func _set_fixed_vrs() -> void:
	var xr := XRServer.find_interface("OpenXR")
	var st := int(S["fov_str"])
	get_viewport().vrs_mode = Viewport.VRS_XR
	if xr != null:
		xr.set("foveation_level", st + 1)
		xr.set("foveation_dynamic", st >= 1)

func _apply_foveation() -> void:
	var vp := get_viewport()
	var xr := XRServer.find_interface("OpenXR")
	var mode := int(S["fov"])
	eye_active = false
	gaze_lost = 0.0
	if mode == 0:
		vp.vrs_mode = Viewport.VRS_DISABLED
		if xr != null:
			xr.set("foveation_level", 0)
	elif mode == 1:
		_set_fixed_vrs()
	else:
		if fov_img == null:
			fov_img = Image.create(FOV_RES, FOV_RES, false, Image.FORMAT_RGB8)
			fov_img.fill(Color8(0, 0, 0))
			fov_tex = ImageTexture.create_from_image(fov_img)
		vp.vrs_update_mode = Viewport.VRS_UPDATE_ALWAYS
		_set_fixed_vrs() # until gaze data shows up
	if mode != 0:
		_flash("Foveation: %s %s" % [FOV_NAMES[mode], FOV_STR[int(S["fov_str"])]])

func _gaze_dir() -> Variant:
	var tr := XRServer.get_tracker("/user/eyes_ext") as XRPositionalTracker
	if tr == null:
		return null
	for pn in GAZE_POSES:
		var pose := tr.get_pose(pn)
		if pose != null and pose.has_tracking_data:
			var gt: Transform3D = pose.get_adjusted_transform()
			return (cam.transform.affine_inverse().basis * (gt.basis * Vector3(0.0, 0.0, -1.0))).normalized()
	return null

func _gaze_to_uv(d: Vector3) -> Vector2:
	var xr := XRServer.primary_interface
	if xr == null:
		return Vector2(0.5, 0.5)
	var size := xr.get_render_target_size()
	var aspect := size.x / maxf(size.y, 1.0)
	var acc := Vector2.ZERO
	var n := 0
	for v in 2:
		var proj := xr.get_projection_for_view(v, aspect, 0.05, 4000.0)
		var p := proj * Vector4(d.x * 10.0, d.y * 10.0, d.z * 10.0, 1.0)
		if absf(p.w) > 0.0001:
			acc += Vector2(p.x / p.w * 0.5 + 0.5, 0.5 - p.y / p.w * 0.5)
			n += 1
	if n == 0:
		return Vector2(0.5, 0.5)
	return (acc / float(n)).clamp(Vector2(0.0, 0.0), Vector2(1.0, 1.0))

func _fill_disc(c: Vector2, r: float, col: Color) -> void:
	var cx := c.x * FOV_RES
	var cy := c.y * FOV_RES
	var rp := r * FOV_RES
	var y0 := maxi(0, int(floor(cy - rp)))
	var y1 := mini(FOV_RES - 1, int(ceil(cy + rp)))
	for y in range(y0, y1 + 1):
		var dy := (y + 0.5) - cy
		if absf(dy) > rp:
			continue
		var half := sqrt(rp * rp - dy * dy)
		var x0 := maxi(0, int(floor(cx - half)))
		var x1 := mini(FOV_RES - 1, int(ceil(cx + half)))
		if x1 >= x0:
			fov_img.fill_rect(Rect2i(x0, y, x1 - x0 + 1, 1), col)

func _update_foveation(delta: float) -> void:
	if int(S["fov"]) != 2 or fov_img == null:
		return
	fov_acc += delta
	if fov_acc < 0.05:
		return
	var dt := fov_acc
	fov_acc = 0.0
	var d = _gaze_dir()
	gaze_ok = d != null
	if not gaze_ok:
		gaze_lost += dt
		if gaze_lost > 3.0 and eye_active:
			eye_active = false
			_set_fixed_vrs()
		return
	gaze_lost = 0.0
	gaze_uv = gaze_uv.lerp(_gaze_to_uv(d), 0.6)
	var r: Array = FOV_RADII[int(S["fov_str"])]
	fov_img.fill(Color8(170, 170, 0))
	_fill_disc(gaze_uv, float(r[1]), Color8(85, 85, 0))
	_fill_disc(gaze_uv, float(r[0]), Color8(0, 0, 0))
	fov_tex.update(fov_img)
	if not eye_active:
		eye_active = true
		var vp := get_viewport()
		vp.vrs_texture = fov_tex
		vp.vrs_mode = Viewport.VRS_TEXTURE
