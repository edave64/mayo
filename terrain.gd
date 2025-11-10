@tool
extends MeshInstance3D

const size := 256.0

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
	update_mesh()

func update_mesh() -> void:
	var plane = PlaneMesh.new()
	plane.subdivide_depth = resolution
	plane.subdivide_width = resolution
	plane.size = Vector2(size, size)
	
	var plane_arrays = plane.get_mesh_arrays()
	var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	var normal_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
	var tangent_array: PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
	
	var collision_shape: CollisionShape3D = get_node("StaticBody3D/Collision")
	
	if not collision_shape: return

	var height_map_scale: float = size / resolution
	
	collision_shape.position.y = -height
	# We don't want to scale y, but the collision shape wants a uniform scale
	collision_shape.scale.x = height_map_scale
	collision_shape.scale.y = height_map_scale
	collision_shape.scale.z = height_map_scale
	
	var height_map_shape: HeightMapShape3D = collision_shape.shape
	# I don't understand where these "+ 2" come from, but without them, the
	# number of verticies does not match the number of height map data-points
	height_map_shape.map_depth = resolution + 2
	height_map_shape.map_width = resolution + 2
	var map_data = height_map_shape.map_data
	
	for i:int in vertex_array.size():
		var vertex := vertex_array[i]
		var normal = Vector3.UP
		var tangent = Vector3.RIGHT
		
		if noise:
			vertex.y = get_height(vertex.x, vertex.z)
			normal = get_normal(vertex.x, vertex.z)
			tangent = normal.cross(Vector3.UP)
		
		vertex_array[i] = vertex
		normal_array[i] = normal
		tangent_array[4 * i] = tangent.x
		tangent_array[4 * i + 1] = tangent.y
		tangent_array[4 * i + 2] = tangent.z
		# Counteract the y scaling of the shape
		map_data[i] = vertex.y / height_map_scale
	
	height_map_shape.map_data = map_data
	
	var array_mash = ArrayMesh.new()
	array_mash.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)
	mesh = array_mash
