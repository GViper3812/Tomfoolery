extends Button

@onready var select_manager = get_node("/root/rootGrid/Player1/select_manager")
@onready var resource_manager = get_node("/root/rootGrid/Player1/resource_manager")
@onready var fob := get_node("/root/rootGrid/forwardoperatingbase/fob_manager")

@onready var selected = select_manager.get_selected()
@onready var manager = selected.get_node("lp_manager")
@onready var queue = selected.get_node("lp_queue")

const r_cost := 300
const p_cost := 175
const delay := 5.0
const label := "upgrade lp"

# Executed on Instantiation
func _ready():
	resource_manager.resource_totals.connect(check)

	manager.upgrade_status_changed.connect(_on_upgrade_status_changed)

	var res = resource_manager.get_resources()
	check(res["requisition"], res["power"])

func _on_upgrade_status_changed():
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
	var selected = select_manager.get_selected()
	var manager = selected.get_node("lp_manager")

	if resource_manager.deduct_resources(r_cost, p_cost):
		manager.queue_action(label, delay)
		disabled = true
