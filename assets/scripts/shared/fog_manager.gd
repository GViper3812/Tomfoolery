extends Node3D
class_name FogController

@export var world_size := Vector2(256, 256)

@onready var viewport := $"../fog_viewport"
@onready var fog_layer := $"../fog_layer"
@onready var fog_draw := viewport.get_node("fog_canvas/fog_draw")

func _ready():
	var mat = fog_layer.get_active_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("fog_view", viewport.get_texture())
		mat.set_shader_parameter("world_size", world_size)
		mat.set_shader_parameter("fog_origin", Vector2(0, 0))

func _process(_delta):
	update_visibility_for_units()

func update_visibility_for_units():
	var visibility_image: Image = viewport.get_texture().get_image().duplicate()
	visibility_image.convert(Image.FORMAT_RGBA8)
	
	var unit_groups := ["infantry", "vehicles", "building"]
	for group_name in unit_groups:
		for unit in get_tree().get_nodes_in_group(group_name):
			if not unit is Node3D:
				continue
			
			if unit.is_in_group("owner_1"):
				unit.visible = true
			elif group_name == "building":
				unit.visible = is_building_visible(unit, visibility_image)
			else:
				var pos = unit.global_transform.origin
				var fog_pixel = fog_draw.world_to_fog_viewport(pos).floor() + Vector2(128, 128)
				var fx = int(clamp(fog_pixel.x, 0, fog_draw.fog_resolution.x - 1))
				var fy = int(clamp(fog_pixel.y, 0, fog_draw.fog_resolution.y - 1))
				var visible_value = visibility_image.get_pixel(fx, fy).a
				unit.visible = visible_value > 0.9

func is_building_visible(unit: Node3D, visibility_image: Image) -> bool:
	var build_col = unit.get_node_or_null("build_col")
	if not build_col or not (build_col is CollisionShape3D):
		return false
	
	if not (build_col.shape is BoxShape3D):
		return false
		
	var scale = build_col.global_transform.basis.get_scale()
	var size = build_col.shape.extents * 2.0 * Vector3(scale.x, 1.0, scale.z)
	
	var origin = unit.global_transform.origin
	
	var offsets = [
		Vector3(-size.x/2, 0, -size.z/2),
		Vector3(0, 0, -size.z/2),
		Vector3(size.x/2, 0, -size.z/2),
		Vector3(-size.x/2, 0, 0),
		Vector3(0, 0, 0),
		Vector3(size.x/2, 0, 0),
		Vector3(-size.x/2, 0, size.z/2),
		Vector3(0, 0, size.z/2),
		Vector3(size.x/2, 0, size.z/2)
	]
	
	for offset in offsets:
		var sample_pos = origin + offset
		
		var fog_pixel = fog_draw.world_to_fog_viewport(sample_pos).floor() + Vector2(128, 128)
		var fx = int(clamp(fog_pixel.x, 0, fog_draw.fog_resolution.x - 1))
		var fy = int(clamp(fog_pixel.y, 0, fog_draw.fog_resolution.y - 1))
		var visible_value = visibility_image.get_pixel(fx, fy).a
		
		if visible_value > 0.9:
			return true
	
	return false
