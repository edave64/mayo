extends VehicleBody3D

var preferred_angle := Vector3(-10, 0, 0)
var lift_off_speed := 20
var tail_lift_speed := 10

var throttle := 0.0
@export var max_throttle := 100.0
@export var throttle_accel := 1.0
@export var throttle_multiplier := 100.0

@onready
var wheels: Array[VehicleWheel3D] = [
	$WheelR,
	$WheelL,
	$WheelH,
]

func _ready() -> void:
	pass # Replace with function body.

func _process(delta: float) -> void:
	%DebugPanel.add_debug_property('Throttle input', "%.2f" % Input.get_axis("vehicle_break", "vehicle_gas"))
	var throttle_delta := Input.get_axis("vehicle_break", "vehicle_gas") * throttle_accel * delta
	%DebugPanel.add_debug_property('Throttle delta', "%.2f" % throttle_delta)
	throttle = clamp(throttle + throttle_delta, -max_throttle, max_throttle)

	%DebugPanel.add_debug_property('Throttle', "%.2f" % throttle)
	var force = get_global_transform_interpolated().basis * Vector3.FORWARD * throttle * throttle_multiplier
	apply_central_force(force)

	# Air velocity = Part of the velocity vector perpendicular to where the plane is pointingvar forward_dir = -global_transform.basis.z.normalized()
	var forward_dir = -global_transform.basis.z.normalized()
	var v = linear_velocity

	# projection of linear velocity onto forward direction
	var air_velocity = forward_dir * v.dot(forward_dir)

	var corrective_strength := clampf((air_velocity.length() - tail_lift_speed) / (lift_off_speed - tail_lift_speed), 0, 1)

	if corrective_strength > 0:
		var torque = global_transform.basis.x * corrective_strength * 5
		apply_torque(torque)
