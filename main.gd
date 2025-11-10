extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var force = Vector3(
		Input.get_axis("vehicle_left", "vehicle_right"),
		Input.get_axis("plane_break", "plane_throttle") * 50,
		Input.get_axis("vehicle_up", "vehicle_down"),
	)  * delta * 500

	$Camera3D.tracking.apply_force(force)
