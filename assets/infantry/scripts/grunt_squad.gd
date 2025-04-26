extends Node3D

@export var squad_size := 9
@export var formation_spacing := 0.6
@export var owner_id := 0
@export var grunt_scene: PackedScene

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var container: Node = $grunt_container

var soldiers: Array = []
var follow_enabled := false

func get_formation_offsets() -> Array:
	return [
		Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(-1, 0, 0),
		Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(1, 0, -1),
		Vector3(-1, 0, -1), Vector3(1, 0, 1), Vector3(-1, 0, 1)
	]

func _ready():
	if grunt_scene == null:
		grunt_scene = preload("res://assets/infantry/player1/grunt.tscn")
	spawn_squad()
	
	var timer := Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(func():
		follow_enabled = true
	)
	add_child(timer)
	timer.start()

func _process(delta: float):
	if follow_enabled:
		update_squad_position()

func spawn_squad():
	var offsets = get_formation_offsets()
	for i in squad_size:
		var grunt = grunt_scene.instantiate()
		container.add_child(grunt)
		
		var offset := Vector3.ZERO
		if i < offsets.size():
			offset = offsets[i] * formation_spacing
		
		var spawn_pos = global_position + offset
		grunt.global_position = NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), spawn_pos)
		
		grunt.set_squad(self)
		grunt.owner_id = owner_id
		grunt.formation_index = i
		grunt.add_to_group("selectable")
		if i == 0:
			grunt.add_to_group("owner_1")
		soldiers.append(grunt)

func move_to(target: Vector3):
	var center = NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), target)
	agent.target_position = center
	
	var direction = (center - global_position).normalized()
	var angle = atan2(direction.x, direction.z)
	
	var offsets = get_formation_offsets()
	for i in soldiers.size():
		if i >= offsets.size():
			continue
		
		var offset = offsets[i] * formation_spacing
		offset = offset.rotated(Vector3.UP, angle)
		var unit_target = center + offset
		
		soldiers[i].move_to(unit_target)

func set_selected(state: bool, color: Color = Color.GREEN):
	for soldier in soldiers:
		soldier.set_selected(state, color)

func on_squad_selected():
	var sm_path = "/root/root/Player%d/select_manager" % owner_id
	if has_node(sm_path):
		get_node(sm_path).select_squad(self)

func update_squad_position():
	if soldiers.is_empty():
		return

	var total := Vector3.ZERO
	for soldier in soldiers:
		total += soldier.global_position

	var avg := total / soldiers.size()
	global_position = Vector3(avg.x, 0.25, avg.z)
