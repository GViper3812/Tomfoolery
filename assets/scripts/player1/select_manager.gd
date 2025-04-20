extends Node

@onready var pm := get_node("../player_manager")
@onready var bm := get_node("../build_manager")
@onready var hud : Control = get_node("../Player1HUD/HUD")

@onready var current_parent := get_node("../Player1HUD/HUD/selected_functions/MarginContainer2/Panel/MarginContainer")
@onready var base := preload("res://assets/hud/buildingselect/base.tscn")

var selected

func _ready():
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if get_viewport().gui_get_hovered_control() != null:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT and pm.get_state() == pm.States.play:
			var area = pm.get_first_area_hit($"../Cam")
			var current = get_current_selection()
			
			if area == null:
				var base_instance = base.instantiate()
				if current:
					current.queue_free()
				current_parent.add_child(base_instance)
				
				selected = null
				return
			
			var area_parent = area.get_parent().name
			
			if area.is_in_group("building"):
				selected = area.get_parent()
				select_building(area_parent)
			elif area.is_in_group("infantry"):
				selected = area.get_parent()
			elif area.is_in_group("vehicle"):
				print("vehicle")
		
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if selected and selected is CharacterBody3D and selected.has_method("move_to_position"):
				var world_pos = pm.get_mouse_world_position($"../Cam")
				var nav_map_rid = get_viewport().get_camera_3d().get_world_3d().navigation_map
				
				var snapped_target = NavigationServer3D.map_get_closest_point(nav_map_rid, world_pos)
				
				selected.move_to_position(snapped_target)

func get_current_selection():
	return current_parent.get_child(current_parent.get_child_count() - 1) if current_parent.get_child_count() > 0 else null

func select_building(select):
	var select_path = "res://assets/hud/buildingselect/" + select + ".tscn"
	
	if ResourceLoader.exists(select_path):
		var select_scene = load(select_path) as PackedScene
		if select_scene:
			var instance = select_scene.instantiate()
			var current = get_current_selection()
			
			if current:
				current.queue_free()
			
			current_parent.add_child(instance)

func get_selected() -> Node:
	return selected
