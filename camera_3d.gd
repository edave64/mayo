extends Camera3D

@export var tracking: Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var offset = Vector3(-0.3, 300, 10)
	position = tracking.get_position() + offset
	look_at(tracking.get_position())
	pass
