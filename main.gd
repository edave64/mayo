extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_base_area_body_entered(body: Node3D) -> void:
	if body == $Car:
		$UI/MissionLabel.text = "Deliver the pizza"
		$Pointer.pointTowards = $Client


func _on_client_area_body_entered(body: Node3D) -> void:
	if body == $Car:
		$UI/MissionLabel.text = "Pick up the pizza"
		$Pointer.pointTowards = $Base
