extends Node

@onready var rm := get_node("../resource_manager")
@onready var pm := get_node("../player_manager")
@onready var root_grid : GridMap = get_node("../..")
@onready var hud : Control = get_node_or_null("../Player1HUD/HUD")

@onready var invalid = preload("res://assets/building/shader/invalid.gdshader")
@onready var valid = preload("res://assets/building/shader/valid.gdshader")

var mainmat : Material = preload("res://assets/building/shader/mainmat.tres")
var editmat : Material = preload("res://assets/building/shader/editmat.tres")

static var current_building
var mat

func _ready():
	var vbox1 = hud.get_node("building/HSplitContainer/VBox1")
	var vbox2 = hud.get_node("building/HSplitContainer/VBox2")
	
	for vbox in [vbox1, vbox2]:
		if vbox:
			for button in vbox.get_children():
				if button is Button:
					button.pressed.connect(_on_button_pressed.bind(button))

func _on_button_pressed(button: Button):
	var building_path = "res://assets/building/scene/" + button.name + ".tscn"
	
	if ResourceLoader.exists(building_path):
		var building_scene = load(building_path) as PackedScene
		if building_scene:
			spawn_building(building_scene)
			pm.set_state(pm.States.building)



func _process(_delta):
	if pm.get_state() == pm.States.building and current_building:
		update_building_position()
		
		if mat.shader != valid:
			mat.shader = valid
		
		if Input.is_action_just_pressed("Place_Building"):
			lock_building()
		
	elif pm.get_state() == pm.States.blocked and current_building:
		update_building_position()
		mat.shader = invalid
		
		if Input.is_action_just_pressed("Place_Building"):
			pass

func spawn_building(building_scene: PackedScene):
	if pm.get_state() == pm.States.building or current_building != null:
		return
		
	var building_instance = building_scene.instantiate() as StaticBody3D
	var mesh_node = building_instance.get_node_or_null("mesh")
	
	if not mesh_node:
		push_error("Building scene is missing a MeshInstance3D child.")
		return
	
	mesh_node.set_surface_override_material(0, editmat)
	
	mat = mesh_node.get_active_material(0)
	
	current_building = building_instance
	root_grid.add_child(current_building)


func update_building_position():
	var world_pos = pm.get_mouse_world_position($"../Cam")
	if world_pos == Vector3.ZERO or not current_building:
		return
	
	var snapped_pos = root_grid.map_to_local(root_grid.local_to_map(world_pos))
	snapped_pos.y = 0
	current_building.global_transform.origin = snapped_pos


func lock_building():
	if not current_building:
		return
	
	var mesh_node = current_building.get_node_or_null("mesh")
	if mesh_node:
		mesh_node.set_surface_override_material(0, mainmat)
	
	current_building.reparent(get_node("/root/rootGrid"))
	current_building.set_process(false)
	pm.set_state(pm.States.play)
	current_building = null
