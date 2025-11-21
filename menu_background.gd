extends MeshInstance2D

var color_corners: Array[CornerColor]

func _ready() -> void:
	_on_main_menu_resized()
	color_corners = [
		CornerColor.new($R),
		CornerColor.new($G),
		CornerColor.new($B),
		CornerColor.new($O),
	]

func _process(delta: float) -> void:
	for color_corner in color_corners:
		color_corner.update(delta)


func _on_main_menu_resized() -> void:
	var parent := get_parent() as Control
	mesh.set('size', parent.size)
	mesh.set('center_offset', parent.size / 2)

class CornerColor:
	enum State { BLANKING, FADEIN, HOLDING, FADEOUT }
	const MAX_WAIT := {
		State.BLANKING: 20,
		State.FADEIN: 30,
		State.HOLDING: 5,
		State.FADEOUT: 30
	}
	
	var mesh: MeshInstance2D
	var progress_max: float
	var progress := 0.0
	var intensity: float
	var state := State.BLANKING
	
	func _init(mesh_: MeshInstance2D) -> void:
		mesh = mesh_
		progress_max = randf() * MAX_WAIT[state]
		intensity = 1 + (randf())
	
	func update(delta: float) -> void:
		progress += delta
		
		if progress > progress_max:
			state = (state + 1) % 4 as State
			progress = 0
			progress_max = randf() * MAX_WAIT[state]
			if state == State.BLANKING:
				intensity = 1 + (randf())
		
		var value: float
		match state:
			State.BLANKING:
				value = 0
			State.HOLDING:
				value = 1
			State.FADEIN:
				value = max(0.0, min(1.0, progress / progress_max))
			State.FADEOUT:
				value = 1 - max(0.0, min(1.0, progress / progress_max))
		
		mesh.modulate = Color(value * intensity, value * intensity, value * intensity)
