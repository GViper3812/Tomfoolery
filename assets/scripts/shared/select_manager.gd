extends Node

@onready var services := get_node("../player_services")
@onready var pm = services.pm
@onready var bm = services.bm
@onready var hud : Control = services.get_hud()
@onready var current_parent = services.get_current_parent_panel()
@onready var cam : Camera3D = $"../Cam"
@onready var selection_rect : Control = $"../Player1HUD/HUD/selectionrect"

@onready var player_id = services.player_id
@onready var player_path = "res://assets/hud/buildingselect/player%d/" % player_id

var selected
var selected_units : Array[Node] = []

var selected_hostile : Node = null
var hostile_recent := false

var selecting : bool = false
var start_mouse_pos : Vector2

func _ready():
	set_process_input(true)

func _input(event: InputEvent) -> void:
	if get_viewport().gui_get_hovered_control() != null:
		return
	
	if hostile_recent:
		hostile_recent = false
	elif selected_hostile and event is InputEventMouseButton:
		if selected_hostile.has_method("set_selected"):
			selected_hostile.set_selected(false)
		selected_hostile = null
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if pm.get_state() == pm.States.play:
			selecting = true
			start_mouse_pos = event.position
			selection_rect.global_position = start_mouse_pos
			selection_rect.size = Vector2.ZERO
			selection_rect.visible = true
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		if selecting:
			selecting = false
			selection_rect.visible = false
			
			var was_click := start_mouse_pos.distance_to(event.position) < 8.0
			if was_click:
				var area = pm.get_first_area_hit(cam)
				if area:
					_select_single_target(area)
				else:
					_unselect_all_units()
					var base_instance = load_hud_scene("base")
					if base_instance:
						var current = get_current_selection()
						if current:
							current.queue_free()
						current_parent.add_child(base_instance)
					selected = null
			else:
				select_units_in_rect()
	
	if event is InputEventMouseMotion and selecting:
		var end_mouse_pos = event.position
		var top_left = Vector2(
			min(start_mouse_pos.x, end_mouse_pos.x),
			min(start_mouse_pos.y, end_mouse_pos.y)
		)
		var size = (end_mouse_pos - start_mouse_pos).abs()
		selection_rect.global_position = top_left
		selection_rect.size = size
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		for unit in selected_units:
			if unit and unit is CharacterBody3D and unit.has_method("move_to_position"):
				var world_pos = pm.get_mouse_world_position(cam)
				var nav_map_rid = cam.get_world_3d().navigation_map
				var snapped = NavigationServer3D.map_get_closest_point(nav_map_rid, world_pos)
				unit.move_to_position(snapped)

func _process(_delta):
	if selecting and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		selecting = false
		selection_rect.visible = false
		
		var mouse_pos = get_viewport().get_mouse_position()
		var was_click := start_mouse_pos.distance_to(mouse_pos) < 8.0
		
		if was_click:
			var area = pm.get_first_area_hit(cam)
			if area:
				_select_single_target(area)
			else:
				_unselect_all_units()
				var base_instance = load_hud_scene("base")
				if base_instance:
					var current = get_current_selection()
					if current:
						current.queue_free()
					current_parent.add_child(base_instance)
				selected = null
		else:
			select_units_in_rect()

func _select_single_target(area: Node):
	var area_parent = area.get_parent()
	var owner_node : Node = null
	
	if "owner_id" in area_parent:
		owner_node = area_parent
	else:
		for child in area_parent.get_children():
			if "owner_id" in child:
				owner_node = child
				break
	
	var current = get_current_selection()
	if owner_node == null or owner_node == current:
		return
	
	var is_friendly: bool = "owner_id" in owner_node and owner_node.owner_id == player_id
	
	if area.is_in_group("building"):
		if not is_friendly:
			print("Cannot select enemy building.")
			return
		
		selected = area_parent
		var building_type := "base"
		for child in area_parent.get_children():
			if "building_type" in child:
				building_type = child.building_type
				break
		select_building(building_type)
	elif area.is_in_group("infantry") or area.is_in_group("vehicle"):
		_unselect_all_units()
		
		if is_friendly:
			selected = area_parent
			selected_units = [selected]
			
			if selected.has_method("set_selected"):
				selected.set_selected(true, Color.GREEN)
		else:
			if area_parent.has_method("set_selected"):
				area_parent.set_selected(true, Color.RED)
				selected_hostile = area_parent
				hostile_recent = true

func select_units_in_rect():
	_unselect_all_units()
	selected_units.clear()
	
	var rect = Rect2(selection_rect.global_position, selection_rect.size)
	
	for unit in get_tree().get_nodes_in_group("selectable"):
		if not unit is Node3D:
			continue
		
		if not "owner_id" in unit or unit.owner_id != player_id:
			continue
		
		var screen_pos = cam.unproject_position(unit.global_transform.origin)
		if rect.has_point(screen_pos):
			selected_units.append(unit)
			if unit.has_method("set_selected"):
				unit.set_selected(true, Color.GREEN)
	
	selected = null
	print_selected_units()

func _unselect_all_units():
	for unit in selected_units:
		if unit and unit.has_method("set_selected"):
			unit.set_selected(false)
	selected_units.clear()

func get_current_selection():
	return current_parent.get_child(current_parent.get_child_count() - 1) if current_parent.get_child_count() > 0 else null

func select_building(select : String):
	var scene = load_hud_scene(select)
	if scene:
		var current = get_current_selection()
		if current:
			current.queue_free()
		current_parent.add_child(scene)

func get_selected() -> Node:
	return selected

func load_hud_scene(name : String) -> Node:
	var path = "%s%s.tscn" % [player_path, name]
	if ResourceLoader.exists(path):
		var scene = load(path) as PackedScene
		return scene.instantiate()
	else:
		return null

func print_selected_units():
	if selected_units.is_empty():
		print("No units selected.")
	else:
		print("Selected Units:")
		for unit in selected_units:
			print("- %s (%s)" % [unit.name, unit.get_class()])
