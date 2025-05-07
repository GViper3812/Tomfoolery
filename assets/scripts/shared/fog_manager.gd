extends Node3D

class_name FogController

@export var world_size := Vector2(256, 256)

@onready var viewport := $"../fog_viewport"
@onready var fog_layer := $"../fog_layer"
@onready var fog_draw := $"../fog_viewport/fog_canvas/fog_draw"
var ai_visibility_image: Image = Image.create(int(world_size.x), int(world_size.y), false, Image.FORMAT_RGBA8)

func _ready():
	var mat = fog_layer.get_active_material(0)
	if mat is ShaderMaterial:
		mat.set_shader_parameter("fog_view", viewport.get_texture())
		mat.set_shader_parameter("world_size", world_size)
		mat.set_shader_parameter("fog_origin", Vector2(0, 0))

func _process(_delta):
	update_visibility_for_units()
	update_ai_visibility()

func update_visibility_for_units():
	var visibility_image: Image = viewport.get_texture().get_image().duplicate()
	visibility_image.convert(Image.FORMAT_RGBA8)

	var units := []
	for group_name in ["infantry", "vehicles", "building", "vis_control"]:
		for u in get_tree().get_nodes_in_group(group_name):
			if u is Node3D and not units.has(u):
				units.append(u)
	
	for unit in units:
		var visible := false
		
		if unit.is_in_group("owner_1"):
			visible = true
		
		elif unit.is_in_group("building"):
			visible = is_building_visible(unit, visibility_image)
		
		else:
			var pos = unit.global_transform.origin
			var uvp = fog_draw.world_to_fog_viewport(pos).floor() + fog_draw.fog_resolution/2
			var fx = int(clamp(uvp.x, 0, fog_draw.fog_resolution.x - 1))
			var fy = int(clamp(uvp.y, 0, fog_draw.fog_resolution.y - 1))
			var alpha = visibility_image.get_pixel(fx, fy).a
			visible = alpha > 0.9
		
		_set_visible_recursive(unit, visible)


func is_building_visible(unit: Node3D, visibility_image: Image) -> bool:
	var build_col = unit.get_node_or_null("col")
	if not build_col or not (build_col is CollisionShape3D):
		return false
	var box = build_col.shape
	if not (box is BoxShape3D):
		return false
	
	var t = build_col.global_transform
	var e = box.extents
	
	for off in [
		Vector3(-1,0,-1), Vector3(0,0,-1), Vector3(1,0,-1),
		Vector3(-1,0,0),  Vector3(0,0,0),  Vector3(1,0,0),
		Vector3(-1,0,1),  Vector3(0,0,1),  Vector3(1,0,1)
	]:
		var sample_pos = t.origin + t.basis * Vector3(off.x*e.x, 0, off.z*e.z)
		var uvp = fog_draw.world_to_fog_viewport(sample_pos).floor() + fog_draw.fog_resolution/2
		var fx = int(clamp(uvp.x, 0, fog_draw.fog_resolution.x - 1))
		var fy = int(clamp(uvp.y, 0, fog_draw.fog_resolution.y - 1))
		if visibility_image.get_pixel(fx, fy).a >= 1.0:
			return true
	return false

func _set_visible_recursive(node: Node, on: bool) -> void:
	if node is VisualInstance3D:
		node.visible = on
	for c in node.get_children():
		_set_visible_recursive(c, on)

func update_ai_visibility():
	ai_visibility_image.fill(Color(0, 0, 0, 1))

func reveal_to_ai(world_pos: Vector3, solid_radius := 8, ring_radius := 4, ring_alpha := 0.2):
	var center = fog_draw.world_to_fog_viewport(world_pos).floor() + Vector2(128, 128)
	var width := ai_visibility_image.get_width()
	var height := ai_visibility_image.get_height()
	
	for y in range(-solid_radius - ring_radius, solid_radius + ring_radius + 1):
		for x in range(-solid_radius - ring_radius, solid_radius + ring_radius + 1):
			var px = int(center.x + x)
			var py = int(center.y + y)
			
			if px < 0 or py < 0 or px >= width or py >= height:
				continue
			
			var dist = Vector2(x, y).length()
			if dist <= solid_radius:
				ai_visibility_image.set_pixel(px, py, Color(1, 1, 1, 1))
			elif dist <= solid_radius + ring_radius:
				var blend = lerp(0.0, ring_alpha, 1.0 - (dist - solid_radius) / ring_radius)
				var current = ai_visibility_image.get_pixel(px, py).r
				var value = max(current, blend)
				ai_visibility_image.set_pixel(px, py, Color(value, value, value, 1))
