extends Button

@onready var unit_scene := preload("res://assets/infantry/gruntsquad.tscn")

@onready var select_manager = get_node("/root/rootGrid/Player1/select_manager")
@onready var resource_manager = get_node("/root/rootGrid/Player1/resource_manager")
@onready var player_manager = get_node("/root/rootGrid/Player1/player_manager")

@onready var selected = select_manager.get_selected()
@onready var manager = selected.get_node("lp_manager")
@onready var queue = selected.get_node("lp_queue")

const r_cost := 300
const p_cost := 100
const cap_cost := 3
const cap_type := "infantry"
const delay := 5.0
const label := "spawn grunt squad"

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
	if resource_manager.deduct_resources(r_cost, p_cost):
		manager.queue_action(label, delay, unit_scene)
	else:
		disabled = true
