extends VehicleBody3D

var max_throttle := 5000.0
var thrust_force := 0.0

var pitch_speed := 50000.0
var roll_speed  := 50000.0

var pitch_auto_level_strength := 1000.0
var roll_auto_level_strength  := 1000.0

var min_stable_speed := 5.0

var lift_curve := 2000.0
var lift_pitch_factor := 1.0

func _physics_process(delta: float) -> void:
	_update_throttle(delta)
	_apply_thrust()
	_apply_controls(delta)
	_apply_lift()
	_auto_level()

func _update_throttle(delta: float) -> void:
	thrust_force += Input.get_axis("vehicle_break", "vehicle_gas") * delta
	thrust_force = clamp(thrust_force, 0.0, 1.0)

func _apply_thrust() -> void:
	var forward := -global_transform.basis.z
	apply_central_force(forward * (thrust_force * max_throttle))

func _apply_controls(delta: float) -> void:
	var pitch_input := Input.get_axis("plane_up", "plane_down")
	var roll_input  := Input.get_axis("vehicle_right", "vehicle_left")

	$plane/AeleronL.rotation.x = 0.1 * roll_input
	$plane/AeleronR.rotation.x = -0.1 * roll_input
	# Does not influence yaw yet
	#$plane/Rudder.rotation.y = -0.01 * Input.get_axis('vehicle_left', 'vehicle_right')
	$plane/Elevator.rotation.x = -0.02 * pitch_input

	if pitch_input != 0.0:
		var pitch_axis := global_transform.basis.x
		apply_torque(pitch_axis * (pitch_input * pitch_speed) * delta)

	if roll_input != 0.0:
		var roll_axis := global_transform.basis.z
		apply_torque(roll_axis * (roll_input * roll_speed) * delta)

func _apply_lift() -> void:
	var forward := -global_transform.basis.z
	var forward_speed := linear_velocity.dot(forward)
	%DebugPanel.add_debug_property('Speed', "%.2f m/s" % (forward_speed))

	if forward_speed <= 0.0:
		return

	var up := global_transform.basis.y
	var pitch_angle := rotation.x
	print(pitch_angle)
	var lift_strength := forward_speed * lift_curve * (0.1 + pitch_angle * lift_pitch_factor)
	print(lift_strength)

	lift_strength = max(lift_strength, 0.0)

	apply_central_force(up * lift_strength)

func _auto_level() -> void:
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x

	var forward_speed := linear_velocity.dot(forward)
	if forward_speed < min_stable_speed:
		return

	var level := Vector3(forward.x, 0, forward.z)

	if level.length() > 0.001:
		level = level.normalized()
		var pitch_error := level.angle_to(forward)
		pitch_error *= sign(forward.y)
	
		if abs(pitch_error) > 0.01:
			var torque := basis.x * (-pitch_error * pitch_auto_level_strength)
			apply_torque(torque)

	var roll_error := right.dot(Vector3.UP)

	if abs(roll_error) > 0.01:
		var torque := basis.z * (-roll_error * roll_auto_level_strength)
		apply_torque(torque)
