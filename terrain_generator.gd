@tool
extends Node3D

class_name TerrainGenerator

const size := 256.0

@export var tracking: Node3D

@export_range(4, 256, 4) var resolution := 32:
	set(new_resolution):
		resolution = new_resolution
		invalidate_all_chunks()

@export var noise: FastNoiseLite:
	set(new_noise):
		if noise:
			noise.changed.disconnect(invalidate_all_chunks)
		noise = new_noise
		invalidate_all_chunks()
		if noise:
			noise.changed.connect(invalidate_all_chunks)

@export_range(4, 128, 4) var height = 64:
	set(new_height):
		height = new_height
		invalidate_all_chunks()

var thread_pool: Array[Thread] = [
	Thread.new(),
	Thread.new(),
	Thread.new(),
]

var grid_children

func _ready() -> void:
	grid_children = [
		[
			get_node('TerrainTL'),
			get_node('TerrainCL'),
			get_node('TerrainBL')
		],
		[
			get_node('TerrainTC'),
			get_node('TerrainCC'),
			get_node('TerrainBC')
		],
		[
			get_node('TerrainTR'),
			get_node('TerrainCR'),
			get_node('TerrainBR')
		]
	]
	
	for thread in thread_pool:
		thread.start(worker)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not tracking: return
	
	var current_x = int(round(tracking.position.x / size))
	var current_y = int(round(tracking.position.z / size))
	
	# Step 1: Realize finished tasks
	if finished_tasks_mutex.try_lock():
		while finished_tasks.size() > 0:
			finished_tasks.pop_back().realize_in_main()
		finished_tasks_mutex.unlock()
	
	# Step 2: Find the chunks that need to be generated
	for x in range(-1, 2):
		for y in range(-1, 2):
			if x == 0 && y == 0: continue
			queue_chunk_load_if_needed(current_x + x, current_y + y)
	
	# Step 3: IF the current chunk is not yet finished, block until it is
	
	block_until_loaded(current_x, current_y)

var loaded_chunks: Array[String] = []

func is_chunk_loaded(x: int, y: int) -> bool:
	# Ensure only the main thread interacts with loaded_chunks, so we don't need
	# mutexes
	assert(OS.get_thread_caller_id() == OS.get_main_thread_id())
	return loaded_chunks.has(str(x, '_', y))

func set_chunk_loaded(x: int, y: int) -> void:
	assert(OS.get_thread_caller_id() == OS.get_main_thread_id())
	loaded_chunks.push_back(str(x, '_', y))

func invalidate_all_chunks() -> void:
	assert(OS.get_thread_caller_id() == OS.get_main_thread_id())
	loaded_chunks = []

func get_child_for_chunk(x: int, y: int) -> MeshInstance3D:
	var x_slice = grid_children[imod(x + 1, grid_children.size())];
	return x_slice[imod(y + 1, x_slice.size())]

func imod(a: int, b: int) -> int:
	return (a % b + b) % b

func queue_chunk_load_if_needed(x: int, y: int) -> void:
	if is_chunk_loaded(x, y): return
	set_chunk_loaded(x, y)
	
	task_queue_mutex.lock()
	var task = WorldGenTask.new(self, x, y)
	task_queue.push_back(task)
	task_queue_mutex.unlock()
	task_queue_semaphore.post()

func block_until_loaded(x: int, y: int) -> void:
	if is_chunk_loaded(x, y): return
	set_chunk_loaded(x, y)
	
	var task = WorldGenTask.new(self, x, y)
	task.work_in_thread()
	task.realize_in_main()

var finished_tasks = []
var finished_tasks_mutex = Mutex.new()
var task_queue = []
var task_queue_mutex = Mutex.new();
var task_queue_semaphore = Semaphore.new()

class WorldGenTask:
	var completed = false
	var grid_x: int
	var grid_y: int
	var parent: TerrainGenerator
	
	var height_map_data: PackedFloat32Array
	var array_mesh: ArrayMesh
	var noise: FastNoiseLite
	var height: float
	var resolution: int
	
	func _init(parent_: TerrainGenerator, x: int, y: int) -> void:
		print("init ", x, ' ', y)
		grid_x = x
		grid_y = y
		parent = parent_
		noise = parent.noise
		height = parent.height
		resolution = parent.resolution
	
	func work_in_thread() -> void:
		print("starting ", grid_x, ' ', grid_y)
		generate_mesh()
		generate_height_map()
		completed = true
		print("finished ", grid_x, ' ', grid_y)
	
	func generate_mesh() -> void:
		var plane = PlaneMesh.new()
		plane.subdivide_depth = parent.resolution
		plane.subdivide_width = parent.resolution
		plane.size = Vector2(size, size)
		
		var plane_arrays = plane.get_mesh_arrays()
		var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
		var normal_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
		var tangent_array: PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
		
		var offset_x = grid_x * size
		var offset_y = grid_y * size
		
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
		
		array_mesh = ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)

	func generate_height_map():
		var height_map_scale: float = size / resolution
		
		# We don't want to scale y, but the collision shape wants a uniform scale
		
		var offset_x = grid_x * size
		var offset_y = grid_y * size
		
		var map_resolution = resolution + 1
		
		var data = PackedFloat32Array()
		data.resize(map_resolution * map_resolution)
		
		var half_res = (map_resolution) / 2
		
		for i:int in data.size():
			var x = (i % map_resolution - half_res) * height_map_scale
			var y = (i / map_resolution - half_res) * height_map_scale
			
			data[i] = get_height(offset_x + x, offset_y + y) / (height_map_scale)
		
		height_map_data = data
	
	func realize_in_main() -> void:
		# Editing the node tree should only be done in the main thread
		assert(OS.get_thread_caller_id() == OS.get_main_thread_id())
		assert(completed)
		print("realizing ", grid_x, ' ', grid_y)
		
		var child = parent.get_child_for_chunk(grid_x, grid_y)
		var collision: CollisionShape3D = child.get_node('StaticBody3D/Collision')
		
		var offset_x = grid_x * size
		var offset_y = grid_y * size
		
		child.position.x = offset_x
		child.position.z = offset_y
		child.position.y = 0
		
		var map_resolution = parent.resolution + 1
		
		child.mesh = array_mesh
		child.material_override.set_shader_parameter("height", parent.height * 2.0)
		
		var height_map_scale: float = size / resolution
		
		collision.scale.x = height_map_scale
		collision.scale.y = height_map_scale
		collision.scale.z = height_map_scale
		
		var height_map_shape: HeightMapShape3D = collision.shape
		
		height_map_shape.map_depth = map_resolution
		height_map_shape.map_width = map_resolution
		height_map_shape.map_data = height_map_data
		
		print("loaded ", grid_x, ' ', grid_y)
	
	func get_height(x: float, y: float) -> float:
		return noise.get_noise_2d(x, y) * height

	func get_normal(x: float, y: float) -> Vector3:
		var epsilon = size / resolution
		var epsilon2 = 2 * epsilon
		var normal = Vector3(
			(get_height(x + epsilon, y) - get_height(x - epsilon, y) / epsilon2),
			1,
			(get_height(x, y + epsilon) - get_height(x, y - epsilon) / epsilon2)
		)
		return normal.normalized()

func worker() -> void:
	while true:
		task_queue_semaphore.wait()
		
		task_queue_mutex.lock()
		var task = task_queue.pop_back()
		task_queue_mutex.unlock()
		
		task.work_in_thread()
		
		finished_tasks_mutex.lock()
		finished_tasks.push_back(task)
		finished_tasks_mutex.unlock()
