extends Button

@onready var unit_scene := preload("res://assets/infantry/scout.tscn")
@onready var select_manager = get_node("/root/rootGrid/Player1/select_manager")
@onready var resource_manager = get_node("/root/rootGrid/Player1/resource_manager")
@onready var player_manager = get_node("/root/rootGrid/Player1/player_manager")

@onready var selected = select_manager.get_selected()
@onready var queue_node = selected.get_node("fob_queue")
@onready var marker = selected.get_node("fobmarker")

const r_cost := 75
const p_cost := 0
const cap_cost := 1
const cap_type := "infantry"

# Executed on Instantiation
func _ready():
	resource_manager.resource_totals.connect(check)
	var res = resource_manager.get_resources()
	check(res["requisition"], res["power"])

# Resource and Unit Cap Comparison Check
func check(requisition, power):
	if not player_manager.can_spawn_unit(cap_type, cap_cost):
		disabled = true
		return false
	
	if r_cost <= requisition and p_cost <= power:
		disabled = false
		return true
	else:
		disabled = true
		return false

# Queue the spawn action
func _on_pressed():
	if not player_manager.can_spawn_unit(cap_type, cap_cost):
		disabled = true
		return
	
	if not resource_manager.deduct_resources(r_cost, p_cost):
		disabled = true
		return
	
	player_manager.register_unit(cap_type, cap_cost)
	
	var action = {
		"label": "spawn scout",
		"callable": func():
			await get_tree().create_timer(2).timeout
			var unit = unit_scene.instantiate()
			get_tree().current_scene.add_child(unit)
			unit.global_transform.origin = marker.global_transform.origin
	}
	
	queue_node.add_action(action)
	
	var updated_res = resource_manager.get_resources()
	check(updated_res["requisition"], updated_res["power"])
