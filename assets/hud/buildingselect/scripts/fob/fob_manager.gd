extends Node

var fob_level = 1
var constructionbot = 0

# Upgrade Management
func upgrade():
	fob_level += 1

func is_upgradeable() -> bool:
	var queue_node = get_node("../fob_queue")
	var current_action = queue_node.get_current_action()
	var queue = queue_node.get_queue()
	
	if fob_level != 1:
		return false
	
	if current_action.has("label") and current_action["label"] == "upgrade fob":
		return false
	
	for action in queue:
		if action.has("label") and action["label"] == "upgrade fob":
			return false
	
	return true

# Construction Bot Management
func can_spawn_bot() -> bool:
	var constructionbot := 0
	
	var queue_node = get_node("../fob_queue")
	var current_action = queue_node.get_current_action()
	var queue = queue_node.get_queue()
	
	if current_action.has("label") and current_action["label"] == "spawn construction bot":
		constructionbot += 1
	
	for action in queue:
		if action.has("label") and action["label"] == "spawn construction bot":
			constructionbot += 1
	
	var spawned_bots = get_tree().get_nodes_in_group("p1constructionbot")
	constructionbot += spawned_bots.size()
	
	return constructionbot < 4
