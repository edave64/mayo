extends AeroBody3D

@onready
var wheels: Array[VehicleWheel3D] = [
	$WheelR,
	$WheelL,
	$WheelH,
]

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		show_debug = !show_debug

func _process(_delta: float) -> void:
	$plane/AeleronL.rotation.x = 0.1 * Input.get_axis('vehicle_left', 'vehicle_right')
	$plane/AeleronR.rotation.x = -0.1 * Input.get_axis('vehicle_left', 'vehicle_right')
	$plane/Rudder.rotation.y = -0.01 * Input.get_axis('vehicle_left', 'vehicle_right')
	$plane/Elevator.rotation.x = -0.02 * Input.get_axis('vehicle_up', 'vehicle_down')
	
	if Input.is_action_just_pressed("vehicle_reset"):
		var terrain: TerrainGenerator = %TerrainGenerator
		var max_height: float = wheels.map(func(x): return terrain.get_height(x.global_position)).max()
		rotation = Vector3(
			0,
			rotation.y,
			0
		)
		angular_velocity = Vector3.ZERO
		linear_velocity = Vector3.ZERO
		position = Vector3(
			position.x,
			max_height,
			position.z
		)
