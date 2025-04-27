extends Node

@onready var services : Node = get_node("../player_services")
@onready var pm = services.pm
@onready var rm = services.rm
@onready var sm = services.sm
@onready var hud : Control = services.get_hud()
@onready var root_grid := get_node("../../grid")
@onready var navmesh = get_node("/root/main/navmesh")

var editmat: ShaderMaterial = preload("res://assets/shader/building/editmat.tres")
var mainmat: Material = preload("res://assets/shader/building/mainmat.tres")

static var current_building
var mat: ShaderMaterial

@onready var player_id = services.player_id
@onready var path_prefix = "res://assets/building/player%d/scene/" % player_id

func _ready():
	var vbox1 = hud.get_node("building/HSplitContainer/VBox1")
	var vbox2 = hud.get_node("building/HSplitContainer/VBox2")
	
	for vbox in [vbox1, vbox2]:
		if vbox:
			for button in vbox.get_children():
				if button is Button:
					button.pressed.connect(_on_button_pressed.bind(button))

func _on_button_pressed(button: Button):
	var building_path = path_prefix + button.name + ".tscn"
	if ResourceLoader.exists(building_path):
		var building_scene = load(building_path) as PackedScene
		if building_scene:
			spawn_building(building_scene)
			pm.set_state(pm.States.building)

func _process(_delta):
	if current_building and (pm.get_state() == pm.States.building or pm.get_state() == pm.States.blocked):
		update_building_position()
	
	if mat:
		var color = Color.GREEN if pm.get_state() == pm.States.building else Color.RED
		color.a = 0.5
		mat.set_shader_parameter("base_color", color)
		
		if Input.is_action_just_pressed("Place_Building"):
			lock_building()
		
		if Input.is_action_just_pressed("Cancel_Building") and pm.get_state() == pm.States.building:
			cancel_building()

func spawn_building(building_scene: PackedScene):
	if pm.get_state() == pm.States.building or current_building != null:
		return
	
	var building_instance = building_scene.instantiate() as StaticBody3D
	var mesh_node = building_instance.get_node_or_null("mesh")
	var col = building_instance.get_node_or_null("col")
	
	for child in building_instance.get_children():
		if "owner_id" in child:
			child.owner_id = services.player_id
	
	if col:
		col.disabled = true
	
	mesh_node.set_surface_override_material(0, editmat)
	mat = editmat
	
	current_building = building_instance
	navmesh.add_child(current_building)

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
	
	if pm.get_state() == pm.States.blocked:
		return
	
	var mesh_node = current_building.get_node_or_null("mesh")
	if mesh_node:
		mesh_node.set_surface_override_material(0, mainmat)
	
	var col = current_building.get_node_or_null("col")
	if col:
		col.disabled = false
	
	current_building.set_process(false)
	pm.set_state(pm.States.play)
	
	if navmesh.navigation_mesh:
		navmesh.bake_navigation_mesh()
	
	current_building = null

func cancel_building():
	if current_building:
		current_building.queue_free()
		current_building = null
	pm.set_state(pm.States.play)
