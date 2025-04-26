extends Node2D

@export var world_size := Vector2(256, 256)
@export var fog_resolution := Vector2(256, 256)
@export var solid_radius := 4.0
@export var ring_radius := 8.0
@export var ring_alpha := 0.2

func _process(_delta):
	queue_redraw()

func _draw():
	for unit in get_tree().get_nodes_in_group("owner_1"):
		if not unit is Node3D:
			continue
		
		var world_pos = unit.global_position
		var pos_2d = world_to_fog_viewport(world_pos)
		var offset_pos = pos_2d + Vector2(128, 128)
		
		draw_circle_alpha_blend(offset_pos, solid_radius, ring_radius, ring_alpha)

func draw_circle_alpha_blend(center: Vector2, solid_radius: float, ring_radius: float, ring_alpha: float = 0.2):
	draw_circle(center, solid_radius, Color(1, 1, 1, 1.0))
	for r in range(int(solid_radius) + 1, int(ring_radius)):
		draw_circle(center, r, Color(1, 1, 1, ring_alpha))

func world_to_fog_viewport(world_pos: Vector3) -> Vector2:
	var uv := Vector2(world_pos.x, world_pos.z) / world_size
	return uv * fog_resolution
