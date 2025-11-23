extends Camera3D

@export var tracking: Node3D
@export var mouse_movement := true

const default_pitch := 1.0

var twist := PI
var pitch := default_pitch

var mouse_sensitivity := 0.01
var twist_input := 0.0
var pitch_input := 0.0

const max_pitch = PI
const min_pitch = PI / 4
const distance = 10


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if mouse_movement:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	#pitch = min(max_pitch, max(min_pitch, twist + twist_input))
	twist = fmod(twist + twist_input + PI, PI * 2) - PI
	twist_input = 0
	
	pitch = move_toward(pitch, default_pitch, delta / 3)
	twist = move_toward(twist, 0, delta / 3)
	
	var transform = Basis.from_euler(
		Vector3(
			0, #pitch,
			-tracking.rotation.y + PI + twist,
			0,
		)
	)
	var offset = Vector3.BACK * transform * distance
	
	position = tracking.get_position() + offset
	position.y = max(position.y, %TerrainGenerator.get_height(position) + 3)
	look_at(tracking.get_position())
	
	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _unhandled_input(event: InputEvent) -> void:
	if mouse_movement:
		if event is InputEventMouseMotion && Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			twist_input = -event.relative.x * mouse_sensitivity
			pitch_input = -event.relative.y * mouse_sensitivity
		elif event is InputEventMouseButton && Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
