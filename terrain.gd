@tool
extends MeshInstance3D

class_name Terrain

const size := 256.0

@export var grid_x := 0:
	set(new_x):
		grid_x = new_x
		update_mesh()

@export var grid_y := 0:
	set(new_y):
		grid_y = new_y
		update_mesh()

@export_range(4, 256, 4) var resolution := 32:
	set(new_resolution):
		resolution = new_resolution
		update_mesh()

@export var noise: FastNoiseLite:
	set(new_noise):
		if noise:
			noise.changed.disconnect(update_mesh)
		noise = new_noise
		update_mesh()
		if noise:
			noise.changed.connect(update_mesh)

@export_range(4, 128, 4) var height = 64:
	set(new_height):
		height = new_height
		material_override.set_shader_parameter("height", height * 2.0)
		update_mesh()

var update_lock = true

func set_grid_pos(x: int, y: int) -> void:
	update_lock = true
	grid_x = x
	grid_y = y
	update_lock = false
	update_mesh()

func get_height(x: float, y: float) -> float:
	return noise.get_noise_2d(x, y) * height

func get_normal(x: float, y: float) -> Vector3:
	var epsilon = size / resolution
	var normal = Vector3(
		(get_height(x + epsilon, y) - get_height(x - epsilon, y) / (2 * epsilon)),
		1,
		(get_height(x, y + epsilon) - get_height(x, y - epsilon) / (2 * epsilon))
	)
	return normal.normalized()

func _ready() -> void:
	update_lock = false
	update_mesh()

func update_mesh() -> void:
	if update_lock: return
	
	var plane = PlaneMesh.new()
	plane.subdivide_depth = resolution
	plane.subdivide_width = resolution
	plane.size = Vector2(size, size)
	
	var plane_arrays = plane.get_mesh_arrays()
	var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	var normal_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
	var tangent_array: PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
	
	var offset_x = grid_x * size
	var offset_y = grid_y * size
	
	position.x = offset_x
	position.z = offset_y
	
	for i:int in vertex_array.size():
		var vertex := vertex_array[i]
		var normal = Vector3.UP
		var tangent = Vector3.RIGHT
		
		if noise:
			vertex.y = get_height(vertex.x + offset_x, vertex.z + offset_y)
			normal = get_normal(vertex.x + offset_x, vertex.z + offset_y)
			tangent = normal.cross(Vector3.UP)
		
		vertex_array[i] = vertex
		normal_array[i] = normal
		tangent_array[4 * i] = tangent.x
		tangent_array[4 * i + 1] = tangent.y
		tangent_array[4 * i + 2] = tangent.z
	
	var array_mash = ArrayMesh.new()
	array_mash.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)
	mesh = array_mash
	update_collision()

func update_collision():
	var collision_shape: CollisionShape3D = get_node("StaticBody3D/Collision")
	
	if not collision_shape: return

	var height_map_scale: float = size / resolution
	
	# We don't want to scale y, but the collision shape wants a uniform scale
	collision_shape.scale.x = height_map_scale
	collision_shape.scale.y = height_map_scale
	collision_shape.scale.z = height_map_scale
	
	var offset_x = grid_x * size
	var offset_y = grid_y * size
	
	var map_resolution = resolution + 1
	
	var height_map_shape: HeightMapShape3D = collision_shape.shape
	height_map_shape.map_depth = map_resolution
	height_map_shape.map_width = map_resolution
	var data = height_map_shape.map_data
	
	var half_res = (map_resolution) / 2
	
	for i:int in data.size():
		var x = (i % map_resolution - half_res) * height_map_scale
		var y = (i / map_resolution - half_res) * height_map_scale
		
		data[i] = get_height(offset_x + x, offset_y + y) / (height_map_scale)
	
	height_map_shape.map_data = data
