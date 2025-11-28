@tool
extends Node
class_name VehicleReset

func _process(_delta: float) -> void:
	if not Engine.is_editor_hint() && Input.is_action_just_pressed("vehicle_reset"):
		reset()

func reset() -> void:
	var terrain: TerrainGenerator = get_tree().get_first_node_in_group("terrain_gen")
	assert(terrain, "Terrain for vehicle reset not found!")
	
	var parent = get_parent() as VehicleBody3D
	var wheels = parent.get_children().filter(func(x): return x is VehicleWheel3D)
	var max_height: float = wheels.map(func(x: VehicleWheel3D): return terrain.get_height(x.global_position) + x.wheel_radius - x.position.y).max()
	parent.rotation = Vector3(
		0,
		parent.rotation.y,
		0
	)
	parent.angular_velocity = Vector3.ZERO
	parent.linear_velocity = Vector3.ZERO
	parent.position = Vector3(
		parent.position.x,
		max_height,
		parent.position.z
	)

func _get_configuration_warnings() -> PackedStringArray:
	var arr : PackedStringArray = PackedStringArray()
	if not get_parent() is VehicleBody3D:
		arr.append("Vehicle reset must be a child of a VehicleBody3D.")
	elif not get_parent().get_children().any(func(x): return x is VehicleWheel3D):
		arr.append("Vehicle must have at least one VehicleWheel3D for Vehicle reset to function.")
	
	return arr
