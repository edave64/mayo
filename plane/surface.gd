extends Marker3D

@export_group("Plane surface")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var width: int = 5
@export_custom(PROPERTY_HINT_NONE, "suffix:m²") var area: int = 2

@export_range(-180, 180, 0.001, "radians_as_degrees") var low_stall_angle: float
@export_range(-180, 180, 0.001, "radians_as_degrees") var max_lift_angle: float
@export_range(-180, 180, 0.001, "radians_as_degrees") var high_stall_angle: float
@export var maximum_lift: int = 1
const AirDensity = 1.205

@onready
var debugPanel = $/root/Main/UI/DebugPanel

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var plane = get_parent() as MayoPlane

	var worldFlowVelocity = plane.lastLinearVelocity
	if worldFlowVelocity.is_zero_approx():
		return
	
	var relative_air_velocity = transform.basis * worldFlowVelocity

	var pressure = 0.5 * AirDensity * relative_air_velocity.length_squared()
	var angle_of_attack = plane.rotation.x
	
	print(angle_of_attack)

	#var dragDirection = transform.basis * localFlowVelocity.normalized()
	var lift_direction = transform.basis * Vector3.UP
	
	var lift = lift_direction * lift_coefficient(angle_of_attack) * pressure * area;

	if lift.length() > 300000:
		return

	var force = lift * delta * 30
	print(lift_coefficient(angle_of_attack))
	plane.apply_force(force, position)

func lift_coefficient(angle_of_attack: float) -> float:
	if angle_of_attack > high_stall_angle:
		return 0
	
	if angle_of_attack < low_stall_angle:
		return 0
	
	return -pow(angle_of_attack - max_lift_angle, 2) + maximum_lift
	
