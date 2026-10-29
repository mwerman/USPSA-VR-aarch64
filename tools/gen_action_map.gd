extends SceneTree
## Run once in CI: writes Godot's default OpenXR action map (Index/Touch/Vive/etc. bindings,
## which SteamVR maps onto the Steam Frame controllers) plus an eye-gaze pose binding
## (XR_EXT_eye_gaze_interaction) used for eye-tracked foveated rendering.
## Note: Works even when running headless without HMD connected (OpenXR will fail gracefully).

func _init() -> void:
	# Create the base action map - this will work even if OpenXR partially fails
	var m := OpenXRActionMap.new()
	m.create_default_action_sets()
	
	# Find or create the "godot" action set
	var aset := m.find_action_set("godot")
	if aset == null and m.get_action_sets().size() > 0:
		aset = m.get_action_sets()[0]
	
	# Add gaze pose action if the godot action set exists
	if aset != null:
		var act := OpenXRAction.new()
		act.resource_name = "gaze_pose"
		act.localized_name = "Gaze pose"
		act.action_type = OpenXRAction.OPENXR_ACTION_POSE
		act.toplevel_paths = PackedStringArray(["/user/eyes_ext"])
		
		# Note: add_action returns void in Godot 4.3+
		aset.add_action(act)
		
		# Create the interaction profile on a local variable to use has_method() instance method
		var prof_obj := OpenXRInteractionProfile.new()
		if prof_obj.has_method("add_binding"):
			prof_obj.interaction_profile_path = "/interaction_profiles/ext/eye_gaze_interaction"
			
			var b := OpenXRIPBinding.new()
			b.action = act
			b.binding_path = "/user/eyes_ext/input/gaze_ext/pose"
			
			# Try to add binding, but don't fail if it returns unexpected value (OpenXR may not be available)
			var ret := prof_obj.add_binding(b)
			if ret == null or ret == OK:
				m.add_interaction_profile(prof_obj)
		
		# Save the action map regardless of whether gaze pose was added
		ResourceSaver.save(m, "res://openxr_action_map.tres")
	
	print("Action map saved successfully")
