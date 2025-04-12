extends Button

@onready var select_manager = get_node("/root/rootGrid/Player1/select_manager")
@onready var resource_manager = get_node("/root/rootGrid/Player1/resource_manager")

@onready var selected = select_manager.get_selected()

@onready var manager = selected.get_node("fob_manager")
@onready var queue = selected.get_node("fob_queue")

const r_cost := 350
const p_cost := 200

# Executed on Instantiation
func _ready():
	resource_manager.resource_totals.connect(check)
	var res = resource_manager.get_resources()
	
	check(res["requisition"], res["power"])

# Resource Comparison Check
func check(requisition, power):
	if r_cost <= requisition and p_cost <= power and manager.is_upgradeable():
		disabled = false
		return true
	else:
		disabled = true
		return false

# Queue the upgrade action
func _on_pressed():
	if resource_manager.deduct_resources(r_cost, p_cost):
		var action = {
		"label": "upgrade fob",
		"callable": func():
			await get_tree().create_timer(10).timeout
			manager.upgrade()
		}
		
		disabled = true
		
		queue.call("add_action", action)
