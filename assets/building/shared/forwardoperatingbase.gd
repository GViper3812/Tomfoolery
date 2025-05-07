extends StaticBody3D

var owner_id
@onready var manager = get_node("fob_manager")

func _ready() -> void:
	owner_id = manager.owner_id
	print(owner_id)

@export var max_health := 20000
var current_health := max_health
@export var hardness := 0.0

func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		queue_free()

func get_closest_point_to(pos: Vector3) -> Vector3:
	var shape = $col.shape
	if shape and shape is BoxShape3D:
		var extents = shape.extents
		var local_point = to_local(pos).clamp(-extents, extents)
		return to_global(local_point)
	return global_position
