extends Control

func _ready() -> void:
	$Settings/VSync.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED

func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit(0)

func _on_v_sync_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED)

func _on_back_pressed() -> void:
	$Main.visible = true
	$Settings.visible = false

func _on_settings_pressed() -> void:
	$Main.visible = false
	$Settings.visible = true
