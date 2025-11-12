extends Node3D

@export var tracking: Node3D

var grid_x = 0
var grid_y = 0

const size = Terrain.size

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not tracking: return
	
	var current_x = int(round(tracking.position.x / size))
	var current_y = int(round(tracking.position.z / size))
	
	if current_x == grid_x && current_y == grid_y:
		return
	
	grid_x = current_x
	grid_y = current_y
	
	var needed = {
		str(current_x - 1, '_', current_y - 1): [current_x - 1, current_y - 1],
		str(current_x - 1, '_', current_y    ): [current_x - 1, current_y    ],
		str(current_x - 1, '_', current_y + 1): [current_x - 1, current_y + 1],
		str(current_x    , '_', current_y - 1): [current_x    , current_y - 1],
		str(current_x    , '_', current_y    ): [current_x    , current_y    ],
		str(current_x    , '_', current_y + 1): [current_x    , current_y + 1],
		str(current_x + 1, '_', current_y - 1): [current_x + 1, current_y - 1],
		str(current_x + 1, '_', current_y    ): [current_x + 1, current_y    ],
		str(current_x + 1, '_', current_y + 1): [current_x + 1, current_y + 1],
	}
	
	var free: Array[Terrain] = []
	
	var terrains = get_children() as Array[Terrain]
	
	for terrain in terrains:
		var terrain_loc_id = str(terrain.grid_x, '_', terrain.grid_y)
		if needed.has(terrain_loc_id):
			needed.erase(terrain_loc_id)
		else:
			free.append(terrain)
			
	for key in needed:
		var loc = needed[key]
		var free_terrain = free.pop_back()
		
		free_terrain.set_grid_pos(loc[0], loc[1])
	
