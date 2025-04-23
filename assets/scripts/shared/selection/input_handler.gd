extends Node

class_name InputHandler

var manager : SelectManager

func setup(mgr):
	manager = mgr

func process_input(event):
	if get_viewport().gui_get_hovered_control() != null:
		return
	
	if manager.hostile_recent:
		manager.hostile_recent = false
	elif manager.selected_hostile and event is InputEventMouseButton:
		if manager.selected_hostile.has_method("set_selected"):
			manager.selected_hostile.set_selected(false)
		manager.selected_hostile = null
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if manager.pm.get_state() == manager.pm.States.play:
			manager.selecting = true
			manager.start_mouse_pos = event.position
			manager.selection_rect.global_position = manager.start_mouse_pos
			manager.selection_rect.size = Vector2.ZERO
			manager.selection_rect.visible = true
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if manager.selecting:
			manager.selecting = false
			manager.selection_rect.visible = false
			var was_click = manager.start_mouse_pos.distance_to(event.position) < 8.0
			if was_click:
				var area = manager.pm.get_first_area_hit(manager.cam)
				if area:
					manager.selection_logic.select_single_target(area)
				else:
					manager.selection_logic.clear_selection()
			else:
				manager.selection_logic.select_units_in_rect()
	
	if event is InputEventMouseMotion and manager.selecting:
		var end_mouse_pos = event.position
		var top_left = Vector2(
			min(manager.start_mouse_pos.x, end_mouse_pos.x),
			min(manager.start_mouse_pos.y, end_mouse_pos.y)
		)
		var size = (end_mouse_pos - manager.start_mouse_pos).abs()
		manager.selection_rect.global_position = top_left
		manager.selection_rect.size = size
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		manager.order_handler.handle_right_click()

func process_frame():
	if manager.selecting and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		manager.selecting = false
		manager.selection_rect.visible = false
		var mouse_pos = get_viewport().get_mouse_position()
		var was_click: bool = manager.start_mouse_pos.distance_to(mouse_pos) < 8.0
		if was_click:
			var area = manager.pm.get_first_area_hit(manager.cam)
			if area:
				manager.selection_logic.select_single_target(area)
			else:
				manager.selection_logic.clear_selection()
		else:
			manager.selection_logic.select_units_in_rect()
