extends Node3D

# Squad Properties
@export var squad_size := 9
@export var formation_spacing := 0.6
@export var grunt_scene: PackedScene
var owner_id: int
@export var unit_type := "Grunt"

@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var container: Node = $grunt_container
@onready var fog_manager = get_node("/root/main/fog_manager")

var soldiers: Array = []
var follow_enabled := false
var capture_target: CapturePoint = null
var capture_registered_units := {}
var suppress_reset := false

# General
func get_owner_id() -> int:
	return owner_id

func initialize(p_owner_id: int):
	owner_id = p_owner_id

# Formation
func get_formation_offsets() -> Array:
	return [
		Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(-1, 0, 0),
		Vector3(0, 0, -1), Vector3(0, 0, 1), Vector3(1, 0, -1),
		Vector3(-1, 0, -1), Vector3(1, 0, 1), Vector3(-1, 0, 1)
	]

func unit_died(unit: Node):
	soldiers.erase(unit)
	reform_formation()

func reform_formation():
	var center = self.global_position
	var direction = (center - global_position).normalized()
	var angle := atan2(direction.x, direction.z)
	
	var offsets := get_formation_offsets()
	var i := 0
	
	for soldier in soldiers:
		if not soldier or not is_instance_valid(soldier):
			continue
		if i >= offsets.size():
			break
		
		var offset = offsets[i] * formation_spacing
		offset = offset.rotated(Vector3.UP, angle)
		var unit_target = center + offset
		
		soldier.formation_index = i
		soldier.move_to(unit_target)
		i += 1

# Setup
func _ready():
	if grunt_scene == null:
		grunt_scene = preload("res://assets/infantry/ai/grunt.tscn")
	spawn_squad()
	
	var timer := Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	timer.timeout.connect(func(): follow_enabled = true)
	add_child(timer)
	timer.start()

func _process(_delta):
	if follow_enabled:
		update_squad_position()
	
	fog_manager.reveal_to_ai(global_position, 8, 4, 0.2)
	
	if capture_target and is_instance_valid(capture_target):
		var distance = global_position.distance_to(capture_target.global_position)
		if distance < 2.0:
			for soldier in soldiers:
				if not soldier or not is_instance_valid(soldier):
					continue
				if not capture_registered_units.has(soldier):
					capture_registered_units[soldier] = true
			
			if capture_registered_units.size() >= soldiers.size():
				capture_target = null
				capture_registered_units.clear()

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
		grunt.add_to_group("targetable")
		soldiers.append(grunt)

# Command Control
func move_to(target: Vector3):
	reset_capture()
	var center = NavigationServer3D.map_get_closest_point(agent.get_navigation_map(), target)
	agent.target_position = center
	
	var direction = (center - global_position).normalized()
	var angle = atan2(direction.x, direction.z)
	var offsets = get_formation_offsets()
	
	var i := 0
	for soldier in soldiers:
		if not soldier or not is_instance_valid(soldier):
			continue
		if i >= offsets.size():
			break
		var offset = offsets[i] * formation_spacing
		offset = offset.rotated(Vector3.UP, angle)
		soldier.move_to(center + offset)
		i += 1

func assign_squad_target(target: Node):
	reset_capture()
	for soldier in soldiers:
		if soldier and is_instance_valid(soldier):
			soldier.set_target(target)

func attack_target(target: Node):
	reset_capture()
	if not target or not is_instance_valid(target):
		return
	
	var target_pos = target.global_transform.origin
	var offsets := get_formation_offsets()
	var i := 0
	
	for soldier in soldiers:
		if not soldier or not is_instance_valid(soldier):
			continue
		if i >= offsets.size():
			break
		
		var to_target = (target_pos - soldier.global_transform.origin).normalized()
		
		var stop_distance = clamp(soldier.attack_range - 0.5, 0.5, soldier.attack_range)
		var unit_target = target_pos - (to_target * stop_distance)
		
		soldier.move_to(unit_target)
		soldier.set_target(target)
		i += 1

func issue_capture_order(target: Node):
	suppress_reset = true
	
	if target is CapturePoint:
		reset_capture()
		capture_target = target
		move_to(target.global_position)
	
	suppress_reset = false

func reset_capture():
	if suppress_reset:
		return
	capture_target = null
	capture_registered_units.clear()

# Selection
func set_selected(state: bool, color: Color = Color.GREEN):
	for soldier in soldiers:
		if soldier and is_instance_valid(soldier):
			soldier.set_selected(state, color)

func on_squad_selected():
	var sm_path = "/root/main/Player%d/select_manager" % owner_id
	if has_node(sm_path):
		get_node(sm_path).select_squad(self)

func update_squad_position():
	if soldiers.is_empty():
		return
	
	var total := Vector3.ZERO
	var valid_count := 0
	for soldier in soldiers:
		if soldier and is_instance_valid(soldier):
			total += soldier.global_position
			valid_count += 1
	if valid_count > 0:
		var avg := total / valid_count
		global_position = Vector3(avg.x, 0.25, avg.z)

func capture_nearest_objective():
	var my_position = global_transform.origin
	var nearest_obj = null
	var nearest_dist = INF

	for obj in get_tree().get_nodes_in_group("cap"):
		if obj.owner_id == 2:
			continue
		var dist = my_position.distance_to(obj.global_transform.origin)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_obj = obj

	if nearest_obj:
		agent.target_position = nearest_obj.global_transform.origin
		print("[AI][Squad] Capturing: ", nearest_obj.name)
	else:
		print("[AI][Squad] No valid objectives found.")
