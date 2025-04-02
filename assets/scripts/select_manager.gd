extends Node

@onready var pm := get_node("../player_manager")
@onready var bm := get_node("../build_manager")
@onready var hud : Control = get_node("../Player1HUD/HUD")

@onready var current_parent := get_node("../Player1HUD/HUD/selected_functions/MarginContainer2/Panel/MarginContainer/HSplitContainer")
@onready var base := preload("res://assets/hud/buildingselect/base.tscn")

func _ready():
	set_process_input(true)
	var base_instance = base.instantiate()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT and pm.get_state() == pm.States.play:
		var area = pm.get_first_area_hit($"../Cam")
		
		var current = get_current_selection()
		
		if area == null:
			var base_instance = base.instantiate()
			if current:
				current.queue_free()
			current_parent.add_child(base_instance)
			return
		
		var area_parent = area.get_parent().name
		
		if area != null and area.is_in_group("building"):
			select_building(area_parent)
		elif area.is_in_group("infantry"):
			print("infantry")
		elif area.is_in_group("vehicle"):
			print("vehicle")
		else:
			return

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
		else:
			print("Failed to load scene: " + select_path)
	else:
		print("Scene path does not exist: " + select_path)
