extends StaticBody3D

var owner_id
@onready var manager = get_node("fob_manager")

func _ready() -> void:
	owner_id = manager.owner_id
	print(owner_id)

@export var max_health := 200
var current_health := max_health
@export var hardness := 0.0

func take_damage(amount: float):
	current_health -= amount
	print("FOB %s.take_damage(): now at %f hp" % [name, current_health])
	if current_health <= 0:
		print("FOB %s destroyed!" % name)
		queue_free()

func get_closest_point_to(pos: Vector3) -> Vector3:
	var shape = $col.shape
	if shape and shape is BoxShape3D:
		var extents = shape.extents
		var local_point = to_local(pos).clamp(-extents, extents)
		return to_global(local_point)
	return global_position
