extends MeshInstance3D

@export var tracking: Node3D
@export var pointTowards: Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not tracking: return
	position = tracking.position + Vector3(0, 2.5, 0)
	var dir = position - pointTowards.position
	rotation = Vector3(
		-PI / 2 - PI / 16,
		atan2(dir.x, dir.z),
		0
	)
