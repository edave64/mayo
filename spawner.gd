@tool
extends Node3D

class_name MapObjSpawner

enum Type { Base, Client }

const MODEL_ABOVE_GROUND = 6
const MODEL_HEIGHT = 8
const AREA_HEIGHT = 12
const AREA_RADIUS = 8

const MATERIAL_COLORS := {
	Type.Base: 0x2b4cc8ff,
	Type.Client: 0x1e6d3aff
}

@export var locations: PackedVector2Array
@export var names: PackedStringArray
@export var type: Type

var mesh := BoxMesh.new()
var collision_shape := BoxShape3D.new()
var area_shape := CylinderShape3D.new()

var did_spawn := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.hex(MATERIAL_COLORS[type])
	mesh.material = material
	mesh.size = Vector3(4, MODEL_HEIGHT, 4)
	
	collision_shape.size = mesh.size
	area_shape.radius = AREA_RADIUS
	area_shape.height = AREA_HEIGHT
	
	if %TerrainGenerator:
		do_spawn(%TerrainGenerator)

func do_spawn(terrain: TerrainGenerator) -> void:
	if did_spawn: return
	did_spawn = true
	
	for location in locations:
		var height_at := terrain.get_height(Vector3(location.x, 0, location.y))
		var instance := MeshInstance3D.new()
		instance.position = Vector3(
			location.x,
			height_at - (MODEL_HEIGHT / 2.0) + MODEL_ABOVE_GROUND,
			location.y
		)
		instance.mesh = mesh
		var body := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		collision.shape = collision_shape;
		body.add_child(collision)
		instance.add_child(body)
		
		var area := Area3D.new()
		var area_collision := CollisionShape3D.new()
		area_collision.shape = area_shape
		area.add_child(area_collision)
		instance.add_child(area)
		
		add_child(instance)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
