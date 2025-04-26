extends Node3D
class_name FogController

@export var world_size := Vector2(256, 256)
@onready var viewport := $"../fog_viewport"
@onready var fog_layer := $"../fog_layer"

func _ready():
	var mat = fog_layer.get_active_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("fog_view", viewport.get_texture())
		mat.set_shader_parameter("world_size", world_size)
		mat.set_shader_parameter("fog_origin", Vector2(0, 0))
