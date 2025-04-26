extends Node

class_name OrderHandler

var manager : SelectManager

func setup(mgr):
	manager = mgr

func handle_right_click():
	var world_pos = manager.pm.get_mouse_world_position(manager.cam)
	var nav_map_rid = manager.cam.get_world_3d().navigation_map
	var snapped = NavigationServer3D.map_get_closest_point(nav_map_rid, world_pos)
	
	for unit in manager.selected_units:
		if unit and unit.has_method("move_to"):
			unit.move_to(snapped)
