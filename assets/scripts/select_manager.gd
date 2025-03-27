extends Node

@onready var pm := get_node("../player_manager")
@onready var bm := get_node("../build_manager")

func _ready():
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and pm.get_state() == pm.States.play:
		var area = pm.get_first_area_hit($"../Cam")
		
		if area != null:
			print(area)
