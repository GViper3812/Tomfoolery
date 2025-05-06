extends Node2D

class_name FogDraw

@export var world_size := Vector2(256, 256)
@export var fog_resolution := Vector2(256, 256)

@export var default_solid_radius := 8.0
@export var default_ring_radius := 4.0
@export var default_ring_alpha := 0.2

var draw_requests: Array = []

var memory_image: Image
var memory_texture: ImageTexture = ImageTexture.new()

func _ready():
	memory_image = Image.create(int(fog_resolution.x), int(fog_resolution.y), false, Image.FORMAT_RGBA8)
	memory_image.fill(Color(0.0, 0.0, 0.0, 1.0))
	memory_texture.set_image(memory_image)

func _process(_delta):
	queue_redraw()

func _draw():
	draw_texture(memory_texture, Vector2.ZERO, Color(1.0, 1.0, 1.0, 0.3))
	
	for request in draw_requests:
		var world_pos = request.position
		var solid_radius = request.solid_radius
		var ring_radius = request.ring_radius
		var ring_alpha = request.ring_alpha
		
		var pos_2d = world_to_fog_viewport(world_pos)
		var offset_pos = pos_2d + Vector2(128, 128)
		draw_circle_alpha_blend(offset_pos, solid_radius, ring_radius, ring_alpha)
	
	draw_requests.clear()
	
	var img = get_viewport().get_texture().get_image().duplicate()
	img.convert(Image.FORMAT_RGBA8)
	
	for y in fog_resolution.y:
		for x in fog_resolution.x:
			var visible = img.get_pixel(x, y).r
			var mem = memory_image.get_pixel(x, y).r
			if visible > mem:
				memory_image.set_pixel(x, y, Color(visible, visible, visible, 1.0))
	
	memory_texture.update(memory_image)

func draw_circle_alpha_blend(center: Vector2, solid_radius: float, ring_radius: float, ring_alpha: float = 0.2):
	draw_circle(center, solid_radius, Color(1, 1, 1, 1.0))
	for r in range(int(solid_radius) + 1, int(ring_radius)):
		draw_circle(center, r, Color(1, 1, 1, ring_alpha))

func world_to_fog_viewport(world_pos: Vector3) -> Vector2:
	var uv := Vector2(world_pos.x, world_pos.z) / world_size
	return uv * fog_resolution

func draw_fog(world_pos: Vector3, solid_radius := -1.0, ring_radius := -1.0, ring_alpha := -1.0) -> void:
	var final_solid = solid_radius if solid_radius > 0.0 else default_solid_radius
	var final_ring = ring_radius if ring_radius > 0.0 else default_ring_radius
	var final_alpha = ring_alpha if ring_alpha > 0.0 else default_ring_alpha
	
	draw_requests.append({
		"position": world_pos,
		"solid_radius": final_solid,
		"ring_radius": final_ring,
		"ring_alpha": final_alpha
	})

func sample_visibility(world_pos: Vector3, owner_id: int) -> float:
	var uv = world_to_fog_viewport(world_pos).floor() + Vector2(128, 128)
	var image : Image = memory_image
	var fx = int(clamp(uv.x, 0, fog_resolution.x - 1))
	var fy = int(clamp(uv.y, 0, fog_resolution.y - 1))
	return image.get_pixel(fx, fy).a
