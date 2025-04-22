extends Button

@onready var unit_scene := preload("res://assets/infantry/player1/constructionbot.tscn")

var owner_id := 1

var sm : Node
var rm : Node
var manager : Node

const r_cost := 100
const p_cost := 0
const label := "spawn construction bot"
const delay := 2.0

# Executed on Instantiation
func _ready():
	var services = find_services(owner_id)
	
	sm = services.sm
	rm = services.rm
	
	var selected = sm.get_selected()
	
	manager = selected.get_node_or_null("fob_manager")
	
	if rm:
		rm.resource_totals.connect(check)
		var res = rm.get_resources()
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
	if rm.deduct_resources(r_cost, p_cost) and manager.can_spawn_bot():
		manager.queue_action(label, delay, unit_scene)
	else:
		disabled = true

func find_services(id : int) -> Node:
	for node in get_tree().get_nodes_in_group("ps"):
		if "player_id" in node and node.player_id == id:
			return node
	return null
