extends Button

var owner_id = 2

var services: Node
var sm: Node
var rm: Node
var manager: Node

const r_cost := 300
const p_cost := 175
const delay := 5.0
const label := "upgrade lp"

func _ready():
	services = find_services(owner_id)
	
	sm = services.sm
	rm = services.rm
	
	var selected = sm.get_selected()
	
	manager = selected.get_node_or_null("lp_manager")
	
	if rm:
		rm.resource_totals.connect(check)
		var res = rm.get_resources()
		check(res["requisition"], res["power"])

func check(requisition, power):
	if r_cost <= requisition and p_cost <= power and manager.is_upgradeable():
		disabled = false
	else:
		disabled = true

func _on_pressed():
	if rm.deduct_resources(r_cost, p_cost):
		manager.queue_action(label, delay)
		disabled = true

func find_services(id: int) -> Node:
	for node in get_tree().get_nodes_in_group("ps"):
		if "player_id" in node and node.player_id == id:
			return node
	return null
