extends CharacterBody3D


const SPEED = 0.5
const SPEED_DECAY = 20
const TURN_SPEED = 1

@onready
var hindWheel = $"./HindWheel"

@onready
var initPos = Vector3(position)

func _physics_process(delta: float) -> void:
	if position.y < -10:
		position = Vector3(initPos)
		velocity = Vector3.ZERO
		rotation = Vector3.ZERO

	var vy = velocity.y
	velocity = velocity.move_toward(Vector3.ZERO, delta * SPEED_DECAY)
	var move = Input.get_axis("ui_down", "ui_up")
	var turn = Input.get_axis("ui_right", "ui_left")
	velocity += -transform.basis.z * move * SPEED
	rotate_y(TURN_SPEED * turn * delta)
	velocity.y = vy

	#orient_hind_wheel()
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()

# Should orient the hind wheel in the direction of the velocity, rather than the
# current orientation.
func orient_hind_wheel() -> void:
	if !velocity.is_zero_approx():
		var dir = Vector3.FORWARD
		
		dir = dir.rotated(Vector3.UP, rotation.y)
		print("dir", dir)
		
		hindWheel.rotation.y = -dir.angle_to(velocity)
