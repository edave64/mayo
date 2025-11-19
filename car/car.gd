extends VehicleBody3D

@export var max_steer = 0.9
@export var engine_power = 300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("vehicle_reset"):
		var terrain = %TerrainGenerator
		var max_height = max(
			terrain.get_height(position + $WheelBL.position),
			terrain.get_height(position + $WheelBL.position),
			terrain.get_height(position + $WheelBL.position),
			terrain.get_height(position + $WheelBL.position),
		)
		rotation = Vector3(
			0,
			PI,
			0
		)
		angular_velocity = Vector3.ZERO
		linear_velocity = Vector3.ZERO
		position = Vector3(
			position.x,
			max_height,
			position.z
		)


func _physics_process(delta: float) -> void:
	steering = move_toward(steering, Input.get_axis("vehicle_right", "vehicle_left") * max_steer, delta)
	engine_force = Input.get_axis("vehicle_down","vehicle_up") * engine_power
	%DebugPanel.add_debug_property('Velocity', "%.2f km/h" % (linear_velocity.length() * 60 * 60 / 1000))
	%DebugPanel.add_debug_property('Velocity2', "%.2f m/s" % (linear_velocity.length()))
	
