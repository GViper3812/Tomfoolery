extends Node

class_name SelectionLogic

var manager : SelectManager

func setup(mgr):
	manager = mgr

func select_single_target(area: Node):
	var area_parent = area.get_parent()
	var owner_node : Node = null
	
	if "owner_id" in area_parent:
		owner_node = area_parent
	else:
		for child in area_parent.get_children():
			if "owner_id" in child:
				owner_node = child
				break
	
	var current = manager.hud_controller.get_current_selection()
	if owner_node == null or owner_node == current:
		return
	
	var is_friendly: bool = "owner_id" in owner_node and owner_node.owner_id == manager.player_id
	
	if area.is_in_group("building"):
		if not is_friendly:
			print("Cannot select enemy building.")
			return
		manager.selected = area_parent
		var building_type := "base"
		for child in area_parent.get_children():
			if "building_type" in child:
				building_type = child.building_type
				break
		manager.hud_controller.select_building(building_type)
	elif area.is_in_group("infantry") or area.is_in_group("vehicle"):
		clear_selection()
		if is_friendly:
			manager.selected = area_parent
			manager.selected_units = [manager.selected]
			if manager.selected.has_method("set_selected"):
				manager.selected.set_selected(true, Color.GREEN)
		else:
			if area_parent.has_method("set_selected"):
				area_parent.set_selected(true, Color.RED)
				manager.selected_hostile = area_parent
				manager.hostile_recent = true

func select_units_in_rect():
	clear_selection()
	var rect = Rect2(manager.selection_rect.global_position, manager.selection_rect.size)
	for unit in get_tree().get_nodes_in_group("selectable"):
		if not unit is Node3D:
			continue
		if not "owner_id" in unit or unit.owner_id != manager.player_id:
			continue
		var screen_pos = manager.cam.unproject_position(unit.global_transform.origin)
		if rect.has_point(screen_pos):
			manager.selected_units.append(unit)
			if unit.has_method("set_selected"):
				unit.set_selected(true, Color.GREEN)
	manager.selected = null
	print_selected_units()

func clear_selection():
	for unit in manager.selected_units:
		if unit and unit.has_method("set_selected"):
			unit.set_selected(false)
	manager.selected_units.clear()
	manager.selected = null
	manager.hud_controller.select_building("base")

func print_selected_units():
	if manager.selected_units.is_empty():
		print("No units selected.")
	else:
		print("Selected Units:")
		for unit in manager.selected_units:
			print("- %s (%s)" % [unit.name, unit.get_class()])
