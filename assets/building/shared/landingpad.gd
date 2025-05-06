extends StaticBody3D

var owner_id
@onready var manager = get_node("lp_manager")

const r_cost := 300
const p_cost := 0

func _ready() -> void:
	owner_id = manager.owner_id
