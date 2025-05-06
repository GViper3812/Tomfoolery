extends Node

var owner_id := 1
var fob_level := 1

@export var building_type := "forwardoperatingbase"

@onready var fog_manager = get_node("/root/main/fog_manager")

signal fob_upgraded(level)

func _process(delta):
	fog_manager.reveal_to_ai(get_parent().global_position, 16, 8, 0.7)

func queue_action(label: String, delay: float, unit_scene: PackedScene = null):
	var queue = get_node("../fob_queue")
	queue.add_action(label, delay, unit_scene)

# Upgrade Management
func upgrade():
	fob_level += 1
	emit_signal("fob_upgraded", fob_level)

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
	var constructionbot = 0
	
	var queue_node = get_node("../fob_queue")
	var current_action = queue_node.get_current_action()
	var queue = queue_node.get_queue()
	
	if current_action.has("label") and current_action["label"] == "spawn construction bot":
		constructionbot += 1
	
	for action in queue:
		if action.has("label") and action["label"] == "spawn construction bot":
			constructionbot += 1
	
	var spawned_bots = get_tree().get_nodes_in_group("aiconstructionbot")
	constructionbot += spawned_bots.size()
	
	return constructionbot < 4

func get_level_2() -> bool:
	return fob_level == 2
