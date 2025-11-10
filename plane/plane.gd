extends AeroBody3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		show_debug = !show_debug

func _process(delta: float) -> void:
	$plane/AeleronL.rotation.x = 0.1 * Input.get_axis('vehicle_left', 'vehicle_right')
	$plane/AeleronR.rotation.x = -0.1 * Input.get_axis('vehicle_left', 'vehicle_right')
	$plane/Rudder.rotation.y = -0.01 * Input.get_axis('vehicle_left', 'vehicle_right')
	$plane/Elevator.rotation.x = -0.02 * Input.get_axis('vehicle_up', 'vehicle_down')
