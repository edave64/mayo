extends Marker3D

@export_group("Plane surface")
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var width: int = 5
@export_custom(PROPERTY_HINT_NONE, "suffix:m²") var area: int = 2


@export_range(-180, 180, 0.001, "radians_as_degrees") var low_stall_angle: int = -30
@export_range(-180, 180, 0.001, "radians_as_degrees") var high_stall_angle: int = 30
@export var maximum_lift: int = 1
const airDensity = 1.205

@onready
var debugPanel = $/root/Main/UI/DebugPanel

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var plane = get_parent() as RigidBody3D

	var rel_pos = position - plane.center_of_mass

	var worldFlowVelocity = plane.linear_velocity - plane.angular_velocity.cross(rel_pos) # + wind
	if worldFlowVelocity.is_zero_approx():
		return
		
	var localFlowVelocity = transform.basis * worldFlowVelocity
	
	var dynamicPressure = 0.5 * airDensity * localFlowVelocity.length_squared()
	var angleOfAttack = atan2(localFlowVelocity.y, -localFlowVelocity.x)
	
	var dragDirection = transform * localFlowVelocity.normalized()
	var forward = transform * Vector3.FORWARD
	var liftDirection = dragDirection.cross(forward)
	
	var lift = liftDirection * lift_coefficient(angleOfAttack) * dynamicPressure * area;
	
	debugPanel.add_debug_property(name + " lift", "%.2f" % lift.length())
	debugPanel.add_debug_property(name + ' velocity', "%.2f, %.2f, %.2f" % [localFlowVelocity.x, localFlowVelocity.y, localFlowVelocity.z])
	
	if lift.length() > 30000:
		return
	
	debugPanel.add_debug_property(name + ' velocity', "%.2f, %.2f, %.2f" % [localFlowVelocity.x, localFlowVelocity.y, localFlowVelocity.z])
	debugPanel.add_debug_property(name + ' ldir', "%.2f, %.2f, %.2f" % [liftDirection.x, liftDirection.y, liftDirection.z])
	plane.apply_force(lift * delta, Vector3.UP * transform)

func lift_coefficient(angle_of_attack: float) -> float:
	return maximum_lift
