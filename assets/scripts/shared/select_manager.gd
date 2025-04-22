extends Node

@onready var services := get_node("../player_services")
@onready var pm = services.pm
@onready var bm = services.bm
@onready var hud : Control = services.get_hud()
@onready var current_parent = services.get_current_parent_panel()

@onready var player_id = services.player_id
@onready var player_path = "res://assets/hud/buildingselect/player%d/" % player_id

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
				var base_instance = load_hud_scene("base")
				if current:
					current.queue_free()
				current_parent.add_child(base_instance)
				
				selected = null
				return
			
			var area_parent = area.get_parent()
			var owner_node: Node = null
			
			if "owner_id" in area_parent:
				owner_node = area_parent
			else:
				for child in area_parent.get_children():
					if "owner_id" in child:
						owner_node = child
						break
			
			if owner_node == null or owner_node == current:
				return
			
			if owner_node.owner_id != player_id:
				print("Cannot select: not owned by this player")
				
				var base_instance = load_hud_scene("base")
				if current:
					current.queue_free()
				current_parent.add_child(base_instance)
				
				selected = null
				return
			
			if area.is_in_group("building"):
				selected = area_parent
				
				var building_type := "base"
				for child in area_parent.get_children():
					if "building_type" in child:
						building_type = child.building_type
						break
				
				select_building(building_type)
			elif area.is_in_group("infantry"):
				selected = area_parent
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

func select_building(select: String):
	var scene = load_hud_scene(select)
	if scene:
		var current = get_current_selection()
		if current:
			current.queue_free()
		current_parent.add_child(scene)

func get_selected() -> Node:
	return selected

func load_hud_scene(name: String) -> Node:
	var path = "%s%s.tscn" % [player_path, name]
	if ResourceLoader.exists(path):
		var scene = load(path) as PackedScene
		return scene.instantiate()
	else:
		push_error("HUD scene not found: ", path)
		return null
