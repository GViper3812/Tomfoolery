extends Node

@onready var fob := get_node("/root/grid/navmesh/forwardoperatingbase/fob_manager")

signal upgrade_status_changed

var lp_level := 1

func queue_action(label: String, delay: float, unit_scene: PackedScene = null):
	var queue = get_node("../lp_queue")
	queue.add_action(label, delay, unit_scene)

func _on_fob_upgraded():
	emit_signal("upgrade_status_changed")

# Upgrade Management
func upgrade():
	lp_level += 1

func is_upgradeable() -> bool:
	var queue_node = get_node("../lp_queue")
	var current_action = queue_node.get_current_action()
	var queue = queue_node.get_queue()
	
	if not fob.get_level_2():
		return false
	
	if lp_level != 1:
		return false
	
	if current_action.has("label") and current_action["label"] == "upgrade lp":
		return false
	
	for action in queue:
		if action.has("label") and action["label"] == "upgrade lp":
			return false
	
	return true
