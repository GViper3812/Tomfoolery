extends Node

class_name HUDController

var manager : SelectManager

func setup(mgr):
	manager = mgr

func select_building(name: String):
	var scene = load_hud_scene(name)
	if scene:
		var current = get_current_selection()
		if current:
			current.queue_free()
		manager.current_parent.add_child(scene)

func get_current_selection():
	return manager.current_parent.get_child(manager.current_parent.get_child_count() - 1) if manager.current_parent.get_child_count() > 0 else null

func load_hud_scene(name: String) -> Node:
	var path = "res://assets/hud/buildingselect/player%d/%s.tscn" % [manager.player_id, name]
	if ResourceLoader.exists(path):
		var scene = load(path) as PackedScene
		return scene.instantiate()
	else:
		return null
