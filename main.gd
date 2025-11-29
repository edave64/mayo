extends Node3D

var config = ConfigFile.new()
const configFilePath = "user://mayo.cfg"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var err = config.load(configFilePath)
	
	if err:
		return
	
	apply_resolution(config.get_value("mayo", "terrain_detail", 1))
	_on_terrain_generator_view_distance_changed($TerrainGenerator.view_distance)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		$MainMenu.process_mode = Node.PROCESS_MODE_ALWAYS
		$MainMenu.visible = true
		get_tree().paused = true

func _on_base_area_body_entered(body: Node3D) -> void:
	if body == $Car:
		$UI/MissionLabel.text = "Deliver the pizza"
		$Pointer.pointTowards = $Client

func _on_client_area_body_entered(body: Node3D) -> void:
	if body == $Car:
		$UI/MissionLabel.text = "Pick up the pizza"
		$Pointer.pointTowards = $Base

func _on_main_menu_continue_game() -> void:
	$MainMenu.process_mode = Node.PROCESS_MODE_DISABLED
	$MainMenu.visible = false
	get_tree().paused = false

func _on_main_menu_terrain_detail_change(new_value: int) -> void:
	apply_resolution(new_value)

func apply_resolution(new_value: int) -> void:
	var res := 128
	
	if new_value == 0:
		res = 64
	elif new_value == 2:
		res = 256
	else:
		res = 128
	
	$TerrainGenerator.resolution = res
	
	if $Car.process_mode == ProcessMode.PROCESS_MODE_INHERIT:
		$Car/VehicleReset.reset()


func _on_terrain_generator_view_distance_changed(view_distance: int) -> void:
	if ($WorldEnvironment):
		$WorldEnvironment.environment.fog_depth_begin = 150 + ($TerrainGenerator.size / 2.0) * view_distance
		$WorldEnvironment.environment.fog_depth_end = 200 + TerrainGenerator.size * view_distance
