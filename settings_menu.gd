extends GridContainer

signal terrain_detail_change(new_value: int)

var config = ConfigFile.new()
const configFilePath = "user://mayo.cfg"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$VSync.button_pressed = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	var err = config.load(configFilePath)
	
	if err != OK:
		return
	
	var vsync = config.get_value("mayo", "vsync", true)
	$VSync.button_pressed = !!vsync
	
	var terrain_detail = config.get_value("mayo", "terrain_detail", 1)
	$TerrainDetail.selected = terrain_detail

func _exit_tree() -> void:
	config.save(configFilePath)

func _on_v_sync_toggled(toggled_on: bool) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if toggled_on else DisplayServer.VSYNC_DISABLED)
	config.set_value("mayo", "vsync", toggled_on)

func _on_terrain_detail_item_selected(index: int) -> void:
	config.set_value("mayo", "terrain_detail", index)
	terrain_detail_change.emit(index)

func _on_visibility_changed() -> void:
	if visible:
		$Back.grab_focus()
