extends Button

@onready var unit_scene := preload("res://assets/infantry/constructionbot.tscn")

@onready var select_manager = get_node("/root/rootGrid/Player1/select_manager")
@onready var resource_manager = get_node("/root/rootGrid/Player1/resource_manager")

@onready var selected = select_manager.get_selected()

@onready var manager = selected.get_node("fob_manager")
@onready var queue_node = selected.get_node("fob_queue")
@onready var marker = selected.get_node("fobmarker")

const r_cost := 100
const p_cost := 0

# Executed on Instantiation
func _ready():
	resource_manager.resource_totals.connect(check)
	var res = resource_manager.get_resources()
	
	check(res["requisition"], res["power"])

# Resource Comparison Check
func check(requisition, power):
	if not manager.can_spawn_bot():
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
	if manager.can_spawn_bot() and resource_manager.deduct_resources(r_cost, p_cost):
		var action = {
			"label": "spawn construction bot",
			"callable": func():
				await get_tree().create_timer(2).timeout
				var unit = unit_scene.instantiate()
				get_tree().current_scene.add_child(unit)
				unit.global_transform.origin = marker.global_transform.origin
				check(resource_manager.requisition, resource_manager.power)
		}
		
		queue_node.add_action(action)
		
		var updated_res = resource_manager.get_resources()
		check(updated_res["requisition"], updated_res["power"])
