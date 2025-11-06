extends RigidBody3D

const SPEED = 80
const SPEED_DECAY = 20
const TURN_SPEED = 1
const PROP_ACCELERATION = 10
const MASS = 500

const V1 = 10

@onready
var hindWheel = $HindWheel

@onready
var debugPanel = %DebugPanel

@onready
var prop = $prop

@onready
var initPos = Vector3(position)

var propSpeed = 0;

func resetToBase() -> void:
	position = Vector3(initPos)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	rotation = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if position.y < -10:
		resetToBase()

	#velocity = velocity.move_toward(Vector3.ZERO, delta * SPEED_DECAY)
	
	var propInput = Input.get_axis("ui_text_backspace", "ui_accept")
	
	propSpeed += PROP_ACCELERATION * propInput * delta
	
	var abs_prop_speed = abs(propSpeed)
	propSpeed = move_toward(propSpeed, 0, (abs_prop_speed / 10 if abs_prop_speed >= PROP_ACCELERATION else abs_prop_speed / 2) * delta)
	if (propSpeed > 0 && propSpeed < 0.01) || (propSpeed < 0 && propSpeed > -0.01):
		propSpeed = 0
	
	prop.rotation.z = fmod(prop.rotation.z + propSpeed * delta, PI);
	
	var targetForwardVelocity = propSpeed;
	print(Vector3.FORWARD * targetForwardVelocity* MASS)
	apply_central_force(get_global_transform_interpolated().basis * Vector3.FORWARD * targetForwardVelocity* 200)
	#velocity = lerp(velocity, -transform.basis.z * targetForwardVelocity * SPEED, delta)
	
	var elevatorInput = Input.get_axis("ui_up", "ui_down")
	
	var aleronInput = Input.get_axis("ui_right", "ui_left")
	rotate_object_local(Vector3.UP, aleronInput * delta)
	rotate_object_local(Vector3.BACK, aleronInput * delta * 1.5)
	#rotate_y(TURN_SPEED * aleronInput * delta)

	orient_hind_wheel()
	
	var horizontal_vel = Vector3(linear_velocity.x, 0, linear_velocity.z).length();
	
	var CL = get_coefficient_of_lift(rotation.x)
	
	
	# Area of the wing. Randomly guessed
	const A = 2
	
	# Density of air. Maybe decrese with height
	const r = 1.205
	
	var lift = CL * r * (horizontal_vel * horizontal_vel / 2) * A
	var weight = MASS * 9.80665
		
	apply_central_force(Vector3.MODEL_TOP * lift)
	
	rotate_object_local(Vector3.RIGHT, elevatorInput * delta)
	#rotation.x = fmod(rotation.x + PI + elevatorInput * delta, 2 * PI) - PI
	
	if debugPanel.visible:
		debugPanel.add_debug_property('Position', "%.2f, %.2f, %.2f" % [position.x, position.y, position.z])
		debugPanel.add_debug_property('Linear Velocity', "%.2f, %.2f, %.2f" % [linear_velocity.x, linear_velocity.y, linear_velocity.z])
		debugPanel.add_debug_property('Rotation', "%.2f, %.2f, %.2f" % [rotation.x, rotation.y, rotation.z])
		debugPanel.add_debug_property('H-speed', "%.2f" % horizontal_vel)
		debugPanel.add_debug_property('Prop speed', "%.2f" % propSpeed)
		debugPanel.add_debug_property('Lift coefficient', "%.2f" % CL)
		debugPanel.add_debug_property('Lift', "%.2f N" % lift)
		#debugPanel.add_debug_property('Lift Accell', "%.2f N" % liftAccel)
		debugPanel.add_debug_property('Weight', "%.2f N" % weight)
	
	# Add the gravity.
	#if not is_on_floor():
	#	velocity += get_gravity() * delta
	#	debugPanel.add_debug_property('Gravity', "%.2f, %.2f, %.2f" % [velocity.x, velocity.y, velocity.z])
	
	#move_and_slide()

func get_coefficient_of_lift(angle_of_attack: float) -> float:
	if angle_of_attack < -0.02:
		return 0
	
	if angle_of_attack > 0.14:
		return 0
	
	# Formula with degrees: y = 0.5583 + 0.1081x - 0.0013x2
	# Which I extrapolated from some random graph I found.
	
	var deg = angle_of_attack / PI * 180
	
	return 0.5583 + 0.1081 * deg - 0.0013 * deg * deg
	

# Should orient the hind wheel in the direction of the velocity, rather than the
# current orientation.
func orient_hind_wheel() -> void:
	if !linear_velocity.is_zero_approx():
		var vel = linear_velocity
		# Convert world velocity to the plane's local space
		var local_vel = global_transform.basis.inverse() * vel
		# Flatten to XZ plane
		local_vel.y = 0
		if local_vel.length() > 0.001:
			# Compute rotation around Y axis in local space
			var angle = atan2(local_vel.x, local_vel.z)
			hindWheel.transform.basis = Basis(Vector3.UP, angle)
