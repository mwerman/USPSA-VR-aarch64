class_name Mag
extends RigidBody3D
## A magazine. Origin = floor plate centre, body extends +Y. Frozen while held / seated.

var rounds := 0
var cap := 17
var length := 0.09
var in_gun := false

func setup(mag_cap: int, mag_len: float) -> void:
	cap = mag_cap
	length = mag_len
	rounds = cap
	collision_layer = 8
	collision_mask = 1
	mass = 0.3
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.025, length, 0.04)
	cs.shape = sh
	cs.position = Vector3(0.0, length * 0.5, 0.0)
	add_child(cs)
	Defs.box(self, Vector3(0.024, length, 0.036), Vector3(0.0, length * 0.5, 0.0), Color(0.12, 0.12, 0.13))
	Defs.box(self, Vector3(0.028, 0.008, 0.042), Vector3(0.0, -0.002, 0.0), Color(0.25, 0.25, 0.28))
	Defs.box(self, Vector3(0.018, 0.010, 0.030), Vector3(0.0, length + 0.004, 0.0), Color(0.75, 0.6, 0.2))

func hold() -> void:
	freeze = true

func drop(vel: Vector3) -> void:
	in_gun = false
	freeze = false
	linear_velocity = vel
	get_tree().create_timer(6.0).timeout.connect(_expire)

func _expire() -> void:
	if is_instance_valid(self) and not freeze:
		queue_free()
