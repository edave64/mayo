extends CharacterBody3D


const SPEED = 0.5

func _physics_process(delta: float) -> void:

	# Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
	#	velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	if Input.is_action_pressed("ui_up"):
		velocity += rotation * SPEED
	elif Input.is_action_pressed("ui_down"):
		velocity -= rotation * SPEED
	else:
		velocity.z = move_toward(velocity.z, 0, SPEED)
	
	if Input.is_action_pressed("ui_left"):
		rotate(Vector3.UP, 0.1)
	elif Input.is_action_pressed("ui_right"):
		rotate(Vector3.DOWN, 0.1)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	move_and_slide()
