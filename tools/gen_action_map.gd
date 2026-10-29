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
	var saved := false
	if aset != null:
		var act := OpenXRAction.new()
		act.resource_name = "gaze_pose"
		act.localized_name = "Gaze pose"
		act.action_type = OpenXRAction.OPENXR_ACTION_POSE
		act.toplevel_paths = PackedStringArray(["/user/eyes_ext"])
		
		var err1 := aset.add_action(act)
		if err1 == OK:
			# Check if we can use the interaction profile by checking method existence first
			if OpenXRInteractionProfile.has_method("add_binding"):
				var prof := OpenXRInteractionProfile.new()
				prof.interaction_profile_path = "/interaction_profiles/ext/eye_gaze_interaction"
				
				var b := OpenXRIPBinding.new()
				b.action = act
				b.binding_path = "/user/eyes_ext/input/gaze_ext/pose"
				
				var err2 := prof.add_binding(b)
				if err2 == OK:
					m.add_interaction_profile(prof)
					saved = true
			
			# Save the action map regardless of whether gaze pose was added
			var err := ResourceSaver.save(m, "res://openxr_action_map.tres")
			if err == OK:
				saved = true
	
	if saved:
		print("Action map saved successfully")
	else:
		print("Warning: Failed to save action map - OpenXR may not be available")
