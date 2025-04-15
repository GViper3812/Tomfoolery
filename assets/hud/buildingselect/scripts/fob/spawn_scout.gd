extends Button

@onready var unit_scene := preload("res://assets/infantry/scout.tscn")

@onready var select_manager = get_node("/root/rootGrid/Player1/select_manager")
@onready var resource_manager = get_node("/root/rootGrid/Player1/resource_manager")

@onready var selected = select_manager.get_selected()
@onready var manager = selected.get_node("fob_manager")

const r_cost := 75
const p_cost := 50
const label := "spawn scout"
const delay := 2.0

# Executed on Instantiation
func _ready():
	resource_manager.resource_totals.connect(check)
	var res = resource_manager.get_resources()
	
	check(res["requisition"], res["power"])

# Resource Comparison Check
func check(requisition, power):
	if r_cost <= requisition and p_cost <= power:
		disabled = false
		return true
	else:
		disabled = true
		return false

# Queue the spawn action
func _on_pressed():
	if resource_manager.deduct_resources(r_cost, p_cost):
		manager.queue_action(label, delay, unit_scene)
	else:
		disabled = true
