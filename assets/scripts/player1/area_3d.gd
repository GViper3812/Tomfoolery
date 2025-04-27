extends Area3D

@onready var pm = get_node("/root/main/Player1/player_manager")

func _on_area_entered(_area: Area3D) -> void:
	pm.set_state(pm.States.blocked)

func _on_area_exited(_area: Area3D) -> void:
	pm.set_state(pm.States.building)
	if get_overlapping_areas().size() > 0:
		pm.set_state(pm.States.blocked)
	else:
		pm.set_state(pm.States.building)
