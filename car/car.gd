extends VehicleBody3D

@export var max_steer := 0.9
@export var engine_power := 300

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	steering = move_toward(steering, Input.get_axis("vehicle_right", "vehicle_left") * max_steer, delta)
	engine_force = Input.get_axis("vehicle_break","vehicle_gas") * engine_power
	%DebugPanel.add_debug_property('Velocity', "%.2f km/h" % (linear_velocity.length() * 60 * 60 / 1000))
	%DebugPanel.add_debug_property('Velocity2', "%.2f m/s" % (linear_velocity.length()))
