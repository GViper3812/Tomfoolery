extends Node

@onready var fob_1 := $"../navmesh/fob1/fob_manager"
@onready var fob_2 := $"../navmesh/fob2/fob_manager"

func _ready() -> void:
	fob_1.owner_id = 1
	fob_2.owner_id = 2
