extends Node

var queue: Array[Dictionary] = []
var processing := false
var current_action: Dictionary = {}

# Called when adding to queue
func add_action(action: Dictionary) -> void:
	queue.append(action)
	print_queue()
	process_queue()

# Queue Manager
func process_queue():
	if processing or queue.is_empty():
		return
	
	processing = true
	current_action = queue.pop_front()
	print_queue()
	
	if current_action.has("callable"):
		await current_action["callable"].call()
	
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

# Prints queue head
func get_current_action() -> Dictionary:
	return current_action

# Prints queue, not head
func get_queue() -> Array:
	return queue
