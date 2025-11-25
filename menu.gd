extends Control

const MAIN_PATH = "res://main.tscn"

func _ready() -> void:
	ResourceLoader.load_threaded_request(MAIN_PATH)

func _on_start_pressed() -> void:
	get_tree().change_scene_to_packed(ResourceLoader.load_threaded_get(MAIN_PATH))

func _on_exit_pressed() -> void:
	get_tree().quit(0)

func _on_back_pressed() -> void:
	$Main.visible = true
	$Settings.visible = false

func _on_settings_pressed() -> void:
	$Main.visible = false
	$Settings.visible = true
