extends Node

@onready var owner_id := 2
var lp_level := 1
var fob : Node
var visible = false

@export var building_type := "landingpad"

@onready var fog_manager = get_node("/root/main/fog_manager")

func _ready() -> void:
	var fob := get_fob(owner_id)

func _process(delta):
	if visible == true:
		fog_manager.reveal_to_ai(get_parent().global_position, 12, 8, 0.7)

func queue_action(label: String, delay: float, unit_scene: PackedScene = null):
	var queue = get_node("../lp_queue")
	queue.add_action(label, delay, unit_scene)

# Upgrade Management
func upgrade():
	lp_level += 1

func is_upgradeable() -> bool:
	var queue_node = get_node_or_null("../lp_queue")
	if not queue_node:
		return false
	
	var current_action = queue_node.get_current_action()
	var queue = queue_node.get_queue()
	
	if not fob or not fob.get_level_2():
		return false
	
	if lp_level != 1:
		return false
	
	if current_action.has("label") and current_action["label"] == "upgrade lp":
		return false
	
	for action in queue:
		if action.has("label") and action["label"] == "upgrade lp":
			return false
	
	return true

func get_fob(id: int) -> Node:
	for fob_node in get_tree().get_nodes_in_group("fob"):
		var fob_manager = fob_node.get_node_or_null("fob_manager")
		if fob_manager and fob_manager.owner_id == id:
			return fob_manager
	return null
