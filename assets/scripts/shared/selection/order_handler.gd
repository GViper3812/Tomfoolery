extends Node

class_name OrderHandler

var manager : SelectManager

func setup(mgr):
	manager = mgr

func handle_right_click():
	for unit in manager.selected_units:
		if unit and unit is CharacterBody3D and unit.has_method("move_to_position"):
			var world_pos = manager.pm.get_mouse_world_position(manager.cam)
			var nav_map_rid = manager.cam.get_world_3d().navigation_map
			var snapped = NavigationServer3D.map_get_closest_point(nav_map_rid, world_pos)
			unit.move_to_position(snapped)
