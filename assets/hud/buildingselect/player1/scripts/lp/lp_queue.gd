extends Node

var navmesh : NavigationRegion3D
var manager : Node
var marker : Marker3D

var queue : Array[Dictionary] = []
var processing : bool = false
var current_action : Dictionary = {}

func _ready():
	navmesh = get_node("/root/grid/navmesh")
	manager = get_parent().get_node_or_null("lp_manager")
	marker = get_parent().get_node_or_null("lpmarker")

func add_action(label : String, delay : float, unit_scene : PackedScene = null) -> void:
	var action = {
		"label": label,
		"delay": delay,
		"unit_scene": unit_scene
	}
	
	queue.append(action)
	print_queue()
	process_queue()

func process_queue():
	if processing or queue.is_empty():
		return
	
	processing = true
	current_action = queue.pop_front()
	print_queue()
	
	var label = current_action.get("label", "unknown")
	var delay = current_action.get("delay", 0.0)
	var unit_scene = current_action.get("unit_scene", null)
	
	await get_tree().create_timer(delay).timeout
	
	if unit_scene:
		var unit = unit_scene.instantiate()
		navmesh.add_child(unit)

		if marker:
			unit.global_transform.origin = marker.global_transform.origin
		
		if "owner_id" in unit:
			unit.owner_id = manager.owner_id

	else:
		if manager:
			match label:
				"upgrade lp":
					manager.upgrade()

	processing = false
	current_action = {}
	process_queue()

func print_queue():
	print("Current Queue:")
	if queue.is_empty():
		print("  (empty)")
	else:
		for i in queue.size():
			var label = queue[i].get("label", "unknown action")
			print("  item %d: %s" % [i + 1, label])

func get_current_action() -> Dictionary:
	return current_action

func get_queue() -> Array:
	return queue
