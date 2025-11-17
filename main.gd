extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#var force = Vector3(
	#	Input.get_axis("vehicle_left", "vehicle_right"),
	#	Input.get_axis("plane_break", "plane_throttle") * 50,
	#	Input.get_axis("vehicle_up", "vehicle_down"),
	#)  * delta * 20000
	#
	#$Camera3D.tracking.apply_force(force)
	pass


func _on_base_area_body_entered(body: Node3D) -> void:
	print(body.get_path())
	if body == $Car:
		$UI/MissionLabel.text = "Deliver the pizza"
		$Pointer.pointTowards = $Client


func _on_client_area_body_entered(body: Node3D) -> void:
	if body == $Car:
		$UI/MissionLabel.text = "Pick up the pizza"
		$Pointer.pointTowards = $Base
