extends Control

signal terrain_detail_change(new_value: int)

const MAIN_PATH = "res://main.tscn"

signal continue_game

func _ready() -> void:
	$Main/Start.grab_focus()
	if is_root():
		ResourceLoader.load_threaded_request(MAIN_PATH)
	else:
		$Main/Start.text = "Continue"

func _on_start_pressed() -> void:
	if is_root():
		get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(MAIN_PATH))
	else:
		continue_game.emit()

func _on_exit_pressed() -> void:
	get_tree().quit(0)

func is_root() -> bool:
	return get_parent() is Window

func _on_back_pressed() -> void:
	$Main.visible = true
	$Settings.visible = false

func _on_settings_pressed() -> void:
	$Main.visible = false
	$Settings.visible = true

func _on_visibility_changed() -> void:
	$Main/Start.grab_focus()

func _on_settings_terrain_detail_change(new_value: int) -> void:
	terrain_detail_change.emit(new_value)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		continue_game.emit()


func _on_settings_visibility_changed() -> void:
	if not $Settings.visible:
		$Main/Settings.grab_focus()
