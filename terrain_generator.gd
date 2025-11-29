@tool
extends Node3D

class_name TerrainGenerator

signal view_distance_changed (view_distance: int)

# Based on a YT tutorial by DevPoodle
# https://www.youtube.com/watch?v=6qim01M1Yp0

# Generates a world in chunks based off a given noise, with mesh and collision.
# The world is generated in chunks and tracks a given Node3D object. If the
# object moves towards unloaded chunks, they will be loaded automatically.
# 
# Termininology:
# - Chunk: A square piece of the world, with the size `size`
# - Chunk mesh: A child node of this generator. It's expected to be a
#   `MeshInstance3D` with a `StaticBody3D` with a `CollisionShape3D` child.
# - Chunk mesh idx: The chunk meshes are stored in a flat array. This is the
#   index of the mesh in that array.
# - X and Y: An absolute position in the world
# - Grid X and Grid Y: The integer position of the chunk in the world grid.
#   Essentially, the integer division of the absolute position by `size`
#
# Chunks are generated as needed by a thread pool. The main thread is blocked
# only if the chunk the tracked object is currently in is not yet loaded.

const size := 256.0

# The object that is tracked by the generator. The world will be generated
# around this object, and if it moves, the chunks will be loaded automatically.
@export var tracking: Node3D

# The resolution of the world. Determines the amount of vertices in each chunk
# mesh and the precision of the height map.
@export_range(4, 256, 4) var resolution := 32:
	set(new_resolution):
		resolution = new_resolution
		invalidate_all_chunks()

# The noise generator used to generate the height map.
@export var noise: FastNoiseLite:
	set(new_noise):
		if noise:
			noise.changed.disconnect(invalidate_all_chunks)
		noise = new_noise
		invalidate_all_chunks()
		if noise:
			noise.changed.connect(invalidate_all_chunks)

# The maximum height of the world.
@export_range(4, 128, 4) var height = 64:
	set(new_height):
		height = new_height
		invalidate_all_chunks()
		if material is ShaderMaterial:
			material.set_shader_parameter("height", new_height * 2.0)

@export var material: Material = null:
	set(new_material):
		material = new_material
		if material is ShaderMaterial:
			material.set_shader_parameter("height", height * 2.0)
		for mesh in chunk_meshes:
			mesh.material_override = new_material

@export_range(1, 10, 1) var view_distance := 3:
	set(new_view_distance):
		view_distance = new_view_distance
		recreate_chunk_meshes()
		view_distance_changed.emit(new_view_distance)

func get_height(pos: Vector3) -> float:
	return noise.get_noise_2d(pos.x, pos.z) * height

var single_thread_mode = false
var single_tread_task: WorldGenTask

func _ready() -> void:
	recreate_chunk_meshes()
	
	var thread_started = false
	
	for thread in thread_pool:
		thread_started = thread_started || (thread.start(worker) == 0)
	
	single_thread_mode = not thread_started
	
	if material:
		if material is ShaderMaterial:
			material.set_shader_parameter("height", height * 2.0)
		for mesh in chunk_meshes:
			mesh.material_override = material

func recreate_chunk_meshes() -> void:
	# First, invalidate all current tasks. Optimally, we might want to stop
	# threads from working on things that will be discarded. For now, they'll
	# just cancel themselves.
	task_by_chunk_mesh = [null]
	for mesh in chunk_meshes:
		remove_child(mesh)
		mesh.queue_free()
	chunk_meshes = []
	
	# view_distance to the left and right, plus the center chunk
	var chunks_per_direction = view_distance * 2 + 1
	
	for x in chunks_per_direction:
		for y in chunks_per_direction:
			var mesh = MeshInstance3D.new()
			var body = StaticBody3D.new()
			var collision = CollisionShape3D.new()
			var shape = HeightMapShape3D.new()
			body.name = "StaticBody3D"
			collision.name = "Collision"
			mesh.material_override = material
			mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			collision.shape = shape
			mesh.add_child(body)
			body.add_child(collision)
			add_child(mesh)
			chunk_meshes.push_back(mesh)
	
	finished_tasks_mutex.lock()
	finished_tasks = []
	finished_tasks_mutex.unlock()
	invalidate_all_chunks()

func _process(_delta: float) -> void:
	if not tracking: return
	
	var current_x = int(round(tracking.position.x / size))
	var current_y = int(round(tracking.position.z / size))
	
	if single_thread_mode:
		# In single thread mode: Render each chunk across 3 frames
		if not single_tread_task:
			# Step 1: Find an open task to work on
			for x in range(current_x - view_distance, current_x + view_distance + 1):
				for y in range(current_y - view_distance, current_y + view_distance + 1):
					if x == current_x && y == current_y: continue
					
					if not is_chunk_active(x, y):
						single_tread_task = WorldGenTask.new(self, x, y)
						task_by_chunk_mesh[get_chunk_mesh_idx(x, y)] = single_tread_task
						break
				# Break both loops if a task is ready
				if single_tread_task: break
		else:
			# Step 2: Generate the chunk spread across 3 frames.
			if not single_tread_task.height_data:
				single_tread_task.generate_height_data()
			elif not single_tread_task.array_mesh:
				single_tread_task.generate_mesh()
			elif single_tread_task.height_map_data.size() == 0:
				single_tread_task.generate_height_map()
				single_tread_task.completed = true
			else:
				single_tread_task.realize_in_main()
				single_tread_task = null
	else:
		# Step 1: Realize finished tasks
		if finished_tasks_mutex.try_lock():
			while finished_tasks.size() > 0:
				finished_tasks.pop_back().realize_in_main()
			finished_tasks_mutex.unlock()
			
		# Step 2: Find the chunks that need to be generated
		for x in range(-view_distance, view_distance + 1):
			for y in range(-view_distance, view_distance + 1):
				if x == 0 && y == 0: continue
				
				queue_chunk_load_if_needed(current_x + x, current_y + y)
	
	# Step 3: IF the current chunk is not yet finished, block until it is
	block_until_loaded(current_x, current_y)

# The thread pool used to generate the chunks
var thread_pool: Array[Thread] = [
	Thread.new(),
	Thread.new(),
	Thread.new(),
]

# Since what we can render is limited by the amount of chunk meshes, we only
# need to track up to one task per chunk mesh. So this array needs to be the
# same size as the number of chunk meshes.
var task_by_chunk_mesh: Array[WorldGenTask] = [null]

var chunk_meshes: Array[MeshInstance3D] = []

# Every chunk position maps to one chunk mesh that will render it.
# And since godot doesn't like nested collections, we address each of those
# with a single number
func get_chunk_mesh_idx(x: int, y: int) -> int:
	if task_by_chunk_mesh.size() == 1: return 1
	
	var chunks_per_direction = view_distance * 2 + 1
	var g_x = imod(x + 1, chunks_per_direction)
	var g_y = imod(y + 1, chunks_per_direction)
	return g_y * chunks_per_direction + g_x

# Returns true if a given chunk is already generated or being generated
func is_chunk_active(x: int, y: int) -> bool:
	# Ensure only the main thread interacts with loaded_chunks, so we don't need
	# mutexes
	assert(OS.get_thread_caller_id() == OS.get_main_thread_id())
	var chunk_mesh_idx = get_chunk_mesh_idx(x, y)
	var task = task_by_chunk_mesh[chunk_mesh_idx]
	return task && task.grid_x == x && task.grid_y == y

func invalidate_all_chunks() -> void:
	assert(OS.get_thread_caller_id() == OS.get_main_thread_id())
	task_by_chunk_mesh = [null]
	task_by_chunk_mesh.resize(chunk_meshes.size())
	task_by_chunk_mesh.fill(null)

# True integer modulo
func imod(a: int, b: int) -> int:
	return (a % b + b) % b

func queue_chunk_load_if_needed(x: int, y: int) -> void:
	if is_chunk_active(x, y): return
	
	task_queue_mutex.lock()
	var task = WorldGenTask.new(self, x, y)
	task_by_chunk_mesh[get_chunk_mesh_idx(x, y)] = task
	task_queue.push_back(task)
	task_queue_mutex.unlock()
	task_queue_semaphore.post()

func block_until_loaded(x: int, y: int) -> void:
	assert(OS.get_thread_caller_id() == OS.get_main_thread_id())
	var chunk_mesh_idx = get_chunk_mesh_idx(x, y)
	var task = task_by_chunk_mesh[chunk_mesh_idx]
	
	if task && task.grid_x == x && task.grid_y == y && task.realized:
		# Happy case, chunk is ready
		return
	
	# Chunk hasn't even started loading
	# -> Just load it on the main thread at this point
	task = WorldGenTask.new(self, x, y)
	task_by_chunk_mesh[get_chunk_mesh_idx(x, y)] = task
	task.work_in_thread()
	task.realize_in_main()

	# It's possible that the chunk we are generating here was already being
	# generated by another thread. But trying to block this thread until some
	# other thread finishes seemed more effort than it's worth. Instead, the
	# other thread will just realize at the end that its place in the
	# task_by_chunk_mesh array is taken.

# The list of finished tasks
# Has a mutex, since the worker threads can push onto it and the main thread
# can pop from it
var finished_tasks = []
var finished_tasks_mutex = Mutex.new()

# The queue of tasks that need to be worked on
# Has a mutex, since the main thread can push onto it and the worker threads
# can pop from it
# Also has a semaphore, which is used to wake the worker threads when there
# are new tasks to be worked on
var task_queue = []
var task_queue_mutex = Mutex.new();
var task_queue_semaphore = Semaphore.new()

class WorldGenTask:
	var completed = false
	var realized = false
	var grid_x: int
	var grid_y: int
	var parent: TerrainGenerator

	# Values copied from the parent
	var noise: FastNoiseLite
	var height: float
	var resolution: int

	# Results
	var height_data: PackedFloat32Array
	var array_mesh: ArrayMesh
	var height_map_data: PackedFloat32Array
	
	func _init(parent_: TerrainGenerator, x: int, y: int) -> void:
		grid_x = x
		grid_y = y
		parent = parent_
		noise = parent.noise
		height = parent.height
		resolution = parent.resolution
	
	func work_in_thread() -> void:
		generate_height_data()
		generate_mesh()
		generate_height_map()
		completed = true

	func generate_height_data() -> void:
		var height_map_scale: float = size / resolution
		
		var offset_x = grid_x * size
		var offset_y = grid_y * size
		
		var map_resolution = resolution + 4
		
		var data = PackedFloat32Array()
		data.resize((map_resolution) * (map_resolution))
		
		@warning_ignore("integer_division")
		var half_res = map_resolution / 2
		
		for i:int in data.size():
			var x = (i % map_resolution - half_res) * height_map_scale
			@warning_ignore("integer_division")
			var y = (i / map_resolution - half_res) * height_map_scale
			
			data[i] = get_height(offset_x + x, offset_y + y)
		
		height_data = data
	
	func get_height_data(x: int, y: int) -> float:
		return height_data[(x + 2) + (y + 2) * (resolution + 4)]
		
	func generate_mesh() -> void:
		var plane = PlaneMesh.new()
		plane.subdivide_depth = resolution - 1
		plane.subdivide_width = resolution - 1
		plane.size = Vector2(size, size)
		
		var plane_arrays = plane.get_mesh_arrays()
		var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
		var normal_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
		var tangent_array: PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
		var half_size := (size / 2.0)
		var step_size := size / resolution
		
		for i:int in vertex_array.size():
			var vertex := vertex_array[i]
			
			var x := int((vertex.x + half_size) / step_size)
			var z := int((vertex.z + half_size) / step_size)
			
			vertex.y = get_height_data(x, z)
			var normal := Vector3(
				(get_height_data(x + 1, z) - get_height_data(x - 1, z) / 2),
				1,
				(get_height_data(x, z + 1) - get_height_data(x, z - 1) / 2)
			).normalized()
			var tangent = normal.cross(Vector3.UP)
			
			vertex_array[i] = vertex
			normal_array[i] = normal
			tangent_array[4 * i] = tangent.x
			tangent_array[4 * i + 1] = tangent.y
			tangent_array[4 * i + 2] = tangent.z
		
		array_mesh = ArrayMesh.new()
		array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)

	func generate_height_map():
		var height_map_scale: float = size / resolution
		
		var map_resolution = resolution + 1
		
		var data = PackedFloat32Array()
		data.resize(map_resolution * map_resolution)
		
		for i:int in data.size():
			var x = (i % map_resolution)
			@warning_ignore("integer_division")
			var y = (i / map_resolution)
			
			data[i] = get_height_data(x, y) / (height_map_scale)
		
		height_map_data = data
	
	func realize_in_main() -> void:
		# Editing the node tree should only be done in the main thread
		assert(OS.get_thread_caller_id() == OS.get_main_thread_id())
		assert(completed)
		
		var idx = parent.get_chunk_mesh_idx(grid_x, grid_y)
		
		# The task has been replaced in the mean-time
		if parent.task_by_chunk_mesh[idx] != self: return;
		
		var child = parent.chunk_meshes[idx]
		var collision: CollisionShape3D = child.get_node('StaticBody3D/Collision')
		
		var offset_x = grid_x * size
		var offset_y = grid_y * size
		
		child.position.x = offset_x
		child.position.z = offset_y
		child.position.y = 0
		
		var map_resolution = resolution + 1
		
		child.mesh = array_mesh
		
		var height_map_scale: float = size / resolution
		
		collision.scale = Vector3.ONE * height_map_scale
		
		var height_map_shape: HeightMapShape3D = collision.shape
		
		height_map_shape.map_depth = map_resolution
		height_map_shape.map_width = map_resolution
		height_map_shape.map_data = height_map_data
		
		realized = true
	
	func get_height(x: float, y: float) -> float:
		return parent.get_height(Vector3(x, 0, y))

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
