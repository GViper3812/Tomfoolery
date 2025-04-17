extends Button

@onready var select_manager = get_node("/root/grid/Player1/select_manager")
@onready var resource_manager = get_node("/root/grid/Player1/resource_manager")

@onready var selected = select_manager.get_selected()
@onready var manager = selected.get_node("fob_manager")

const r_cost := 350
const p_cost := 200
const delay := 2.0
const label := "upgrade fob"

func _ready():
	resource_manager.resource_totals.connect(check)
	var res = resource_manager.get_resources()
	check(res["requisition"], res["power"])

func check(requisition, power):
	var selected = select_manager.get_selected()
	var manager = selected.get_node("fob_manager")

	if r_cost <= requisition and p_cost <= power and manager.is_upgradeable():
		disabled = false
	else:
		disabled = true

func _on_pressed():
	if resource_manager.deduct_resources(r_cost, p_cost):
		manager.add_action(label, delay)
		disabled = true
