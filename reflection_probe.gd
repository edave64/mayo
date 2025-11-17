@tool

extends ReflectionProbe

@export var tracking: Node3D:
	set(new_tracking):
		tracking = new_tracking
		reposition()

@export var offset: Vector3:
	set(new_offset):
		offset = new_offset
		reposition()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	reposition()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	reposition()

func reposition() -> void:
	if not tracking: return
	position = tracking.position + offset
