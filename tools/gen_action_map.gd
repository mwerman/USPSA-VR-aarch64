extends SceneTree
## Run once in CI: writes Godot's default OpenXR action map (Index/Touch/Vive/etc. bindings,
## which SteamVR maps onto the Steam Frame controllers) plus an eye-gaze pose binding
## (XR_EXT_eye_gaze_interaction) used for eye-tracked foveated rendering.

func _init() -> void:
	var m := OpenXRActionMap.new()
	m.create_default_action_sets()
	var aset: OpenXRActionSet = m.find_action_set("godot")
	if aset == null and m.get_action_sets().size() > 0:
		aset = m.get_action_sets()[0]
	if aset != null:
		var act := OpenXRAction.new()
		act.resource_name = "gaze_pose"
		act.localized_name = "Gaze pose"
		act.action_type = OpenXRAction.OPENXR_ACTION_POSE
		act.toplevel_paths = PackedStringArray(["/user/eyes_ext"])
		aset.add_action(act)
		var prof := OpenXRInteractionProfile.new()
		prof.interaction_profile_path = "/interaction_profiles/ext/eye_gaze_interaction"
		var b := OpenXRIPBinding.new()
		b.action = act
		b.binding_path = "/user/eyes_ext/input/gaze_ext/pose"
		prof.add_binding(b)
		m.add_interaction_profile(prof)
	var err := ResourceSaver.save(m, "res://openxr_action_map.tres")
	print("action map saved, err=", err)
	quit()
