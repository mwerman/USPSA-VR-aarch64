class_name Drills
extends RefCounted
## Built-in drills and stages. Targets: [kind, motion, x, y, z] (see Target.PRESETS / enums).
## Barricades: [model, texture, x, z]. All positions are relative to the start line (0,0,0, facing -Z).
## PASS needs: A-zone hits >= goal_a, steel hits >= goal_s, and zero no-shoot hits, inside the par time.

const LIST := [
	{"name": "Free Practice", "par": 0.0, "goal_a": 0, "goal_s": 0, "info": "Your own layout and timer", "t": [], "b": []},
	{"name": "Bill Drill", "par": 3.0, "goal_a": 6, "goal_s": 0, "info": "6 shots on one target at 7 m",
		"t": [[0, 0, 0.0, 0.0, -7.0]], "b": []},
	{"name": "Failure to Stop", "par": 2.5, "goal_a": 3, "goal_s": 0, "info": "2 to the body, 1 to the head at 5 m",
		"t": [[0, 0, 0.0, 0.0, -5.0]], "b": []},
	{"name": "El Presidente", "par": 10.0, "goal_a": 6, "goal_s": 0, "info": "2 each on 3 targets, reload, 2 each again",
		"t": [[0, 0, -1.5, 0.0, -10.0], [0, 0, 0.0, 0.0, -10.0], [0, 0, 1.5, 0.0, -10.0]], "b": []},
	{"name": "Transitions", "par": 4.0, "goal_a": 8, "goal_s": 0, "info": "2 on each of 4 targets at 7 m",
		"t": [[0, 0, -3.0, 0.0, -7.0], [0, 0, -1.0, 0.0, -7.0], [0, 0, 1.0, 0.0, -7.0], [0, 0, 3.0, 0.0, -7.0]], "b": []},
	{"name": "Steel Plates", "par": 5.0, "goal_a": 0, "goal_s": 5, "info": "5 plates at 10 m",
		"t": [[4, 0, -2.0, 0.0, -10.0], [4, 0, -1.0, 0.0, -10.0], [4, 0, 0.0, 0.0, -10.0], [4, 0, 1.0, 0.0, -10.0], [4, 0, 2.0, 0.0, -10.0]], "b": []},
	{"name": "Hostage Rescue", "par": 4.0, "goal_a": 4, "goal_s": 0, "info": "Shoot the target, not the no-shoot",
		"t": [[0, 0, 0.0, 0.0, -8.0], [2, 0, -0.35, 0.0, -7.8]], "b": []},
	{"name": "Moving Target", "par": 8.0, "goal_a": 4, "goal_s": 0, "info": "Sliding target at 10 m",
		"t": [[0, 1, 0.0, 0.0, -10.0]], "b": []},
	{"name": "Pop-ups", "par": 8.0, "goal_a": 4, "goal_s": 0, "info": "Targets appear and disappear",
		"t": [[0, 5, -2.5, 0.0, -8.0], [0, 5, 0.0, 0.0, -8.0], [0, 5, 2.5, 0.0, -8.0]], "b": []},
	{"name": "Barricade Stage", "par": 12.0, "goal_a": 4, "goal_s": 2, "info": "Shoot through the window and port",
		"t": [[0, 0, -1.5, 0.0, -11.0], [0, 0, 1.5, 0.0, -11.0], [4, 0, -2.0, 0.0, -15.0], [4, 0, 2.0, 0.0, -15.0]],
		"b": [[0, 0, 0.0, -4.0], [3, 1, 3.5, -7.0]]},
	{"name": "Air Targets", "par": 12.0, "goal_a": 0, "goal_s": 3, "info": "Tumbling, orbiting and spinning steel",
		"t": [[4, 3, 0.0, 1.5, -12.0], [4, 4, 3.0, 1.5, -14.0], [5, 0, -3.0, 0.0, -12.0]], "b": []},
]
