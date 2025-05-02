extends Node

class_name OrderHandler

var manager : SelectManager

func setup(mgr):
	manager = mgr

func handle_right_click():
	var world_pos = manager.pm.get_mouse_world_position(manager.cam)
	var area = manager.pm.get_first_area_hit(manager.cam)
	var nav_map_rid = manager.cam.get_world_3d().navigation_map
	var snapped = NavigationServer3D.map_get_closest_point(nav_map_rid, world_pos)
	
	if manager.selected_units.is_empty():
		return
	
	var is_hostile = area and area.is_in_group("targetable") and (
		"owner_id" in area and area.owner_id != manager.player_id
	)
	
	var root
	if area:
		root = area.get_parent()
	
	var is_capture_point = root and root.has_method("is_targetable") and root is CapturePoint
	
	for unit in manager.selected_units:
		if not unit or not is_instance_valid(unit):
			continue
		
		if is_hostile and unit.has_method("attack_target"):
			unit.attack_target(area)
		
		elif is_capture_point and unit.has_method("issue_capture_order"):
			unit.issue_capture_order(root)
		
		elif unit.has_method("move_to"):
			unit.move_to(snapped)
