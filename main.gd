extends Node3D

var config = ConfigFile.new()
const configFilePath = "user://mayo.cfg"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var err = config.load(configFilePath)
	
	if err:
		return
	
	apply_resolution(config.get_value("mayo", "terrain_detail", 1))

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("ui_cancel"):
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
