extends Node

class_name AIPlayerManager

enum States {
	play,
	building,
	blocked,
	destroying
}

var state := States.play
var can_place := true
var player_id := 2

signal state_changed
signal cap_updated

# Cap Management
var infantry_cap_max := 20
var infantry_cap_used := 0

var vehicle_cap_max := 10
var vehicle_cap_used := 0

func set_state(new_state: States):
	state = new_state
	emit_signal("state_changed")

func get_state() -> States:
	return state

func can_spawn_unit(unit_type: String, cap_cost: int) -> bool:
	match unit_type:
		"infantry":
			return infantry_cap_used + cap_cost <= infantry_cap_max
		"vehicle":
			return vehicle_cap_used + cap_cost <= vehicle_cap_max
		_:
			return true

func register_unit(unit_type: String, cap_cost: int):
	match unit_type:
		"infantry":
			infantry_cap_used += cap_cost
		"vehicle":
			vehicle_cap_used += cap_cost
	emit_signal("cap_updated")

func release_unit(unit_type: String, cap_cost: int):
	match unit_type:
		"infantry":
			infantry_cap_used = max(0, infantry_cap_used - cap_cost)
		"vehicle":
			vehicle_cap_used = max(0, vehicle_cap_used - cap_cost)
	emit_signal("cap_updated")

func get_unit_cap_status() -> Dictionary:
	return {
		"infantry": { "used": infantry_cap_used, "max": infantry_cap_max },
		"vehicle": { "used": vehicle_cap_used, "max": vehicle_cap_max }
	}
