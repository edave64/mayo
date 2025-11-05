extends PanelContainer

var fpsProp: Label

func _ready() -> void:
	visible = false
	
	fpsProp = add_debug_property("fps", "fps")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		visible = !visible

func _process(delta: float) -> void:
	if !visible:
		return
	
	fpsProp.text = 'FPS: ' + "%.2f" % (1.0 / delta);

@onready
var property_container = $MarginContainer/VBoxContainer
var properties: Dictionary[String, Label] = {}

func add_debug_property(title: String, value: String) -> Label:
	var property: Label = properties.get(title)
	
	if !property:
		property = Label.new()
		property_container.add_child(property)
		property.name = title
		properties[title] = property
	
	property.text = property.name + ': ' + value
	return property
