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
	var is_shift := Input.is_key_pressed(KEY_SHIFT)
	
	if owner_node == null:
		if not is_shift:
			clear_selection()
		return
	
	var is_friendly: bool = "owner_id" in owner_node and owner_node.owner_id == manager.player_id
	
	if area.is_in_group("building"):
		if not is_friendly:
			print("Cannot select enemy building.")
			return
		
		if not is_shift:
			clear_selection()
		
		manager.selected = area_parent
		var building_type := "base"
		for child in area_parent.get_children():
			if "building_type" in child:
				building_type = child.building_type
				break
		manager.hud_controller.select_building(building_type)
	
	elif area.is_in_group("infantry") or area.is_in_group("vehicle"):
		var squad = null
		if area.get_parent().has_method("get_squad"):
			squad = area.get_parent().get_squad()
		
		if squad != null:
			if is_shift:
				toggle_selection(squad, true)
			else:
				clear_selection()
				toggle_selection(squad, false)
			return
		
		if is_friendly:
			if not is_shift:
				clear_selection()
			toggle_selection(owner_node, is_shift)
		else:
			if not is_shift:
				clear_selection()
			
			if owner_node.has_method("set_selected"):
				owner_node.set_selected(true, Color.RED)
				manager.selected_hostile = owner_node
				manager.hostile_recent = true

func select_units_in_rect():
	var is_shift := Input.is_key_pressed(KEY_SHIFT)
	var rect = Rect2(manager.selection_rect.global_position, manager.selection_rect.size)
	
	if not is_shift:
		clear_selection()
	
	var squads_selected := {}
	
	for unit in get_tree().get_nodes_in_group("selectable"):
		if not unit is Node3D:
			continue
		if not "owner_id" in unit or unit.owner_id != manager.player_id:
			continue
		
		var screen_pos = manager.cam.unproject_position(unit.global_transform.origin)
		if rect.has_point(screen_pos):
			var squad = null
			if unit.has_method("get_squad"):
				squad = unit.get_squad()
			
			if squad != null:
				if not squads_selected.has(squad) and not manager.selected_units.has(squad):
					manager.select_squad(squad)
					squads_selected[squad] = true
			else:
				toggle_selection(unit, is_shift)
	
	manager.selected = null
	print_selected_units()

func toggle_selection(unit: Node, is_shift: bool):
	if manager.selected_units.has(unit):
		if is_shift:
			manager.selected_units.erase(unit)
			if unit.has_method("set_selected"):
				unit.set_selected(false)
	else:
		manager.selected_units.append(unit)
		if unit.has_method("set_selected"):
			unit.set_selected(true, Color.GREEN)

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
