extends CharacterBody3D

@onready var owner_id := 0
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var outline_mesh: MeshInstance3D = $mesh/outline
@onready var outline_material := preload("res://assets/shader/targeting/outline.tres")

enum UnitState { IDLE, ATTACKING, RETREATING }
var state: UnitState = UnitState.IDLE

# Movement
var current_outline: ShaderMaterial = null
var squad_ref: Node = null
var formation_index: int = -1
var target_velocity: Vector3 = Vector3.ZERO
var speed := 2.0

# Repulsion
const REPULSION_RADIUS := 0.3
const REPULSION_STRENGTH := 10.0

# Combat stats
@export var max_health := 100
var current_health := max_health
@export var attack_damage := 2
@export var attack_range := 3.0
@export var attack_cooldown := 0.2
@export var hardness := 0.0

# Targeting
var target: Node = null
var target_hardness : float
var attack_timer := 0.1

# Timers
@onready var top_level_timer := Timer.new()
@onready var scan_timer := Timer.new()

# General
func get_owner_id() -> int:
	return owner_id

# Setup
func _ready():
	top_level_timer.one_shot = true
	top_level_timer.wait_time = 0.1
	top_level_timer.timeout.connect(_on_top_level_timeout)
	add_child(top_level_timer)
	top_level_timer.start()
	
	scan_timer.wait_time = 0.4
	scan_timer.one_shot = false
	scan_timer.timeout.connect(_on_scan_timer_timeout)
	add_child(scan_timer)
	scan_timer.start()

func _on_top_level_timeout():
	set_as_top_level(true)

func _on_scan_timer_timeout():
	find_target()

# Selection
func set_selected(selected: bool, color: Color = Color.WHITE):
	if selected:
		if current_outline == null:
			current_outline = outline_material.duplicate()
			outline_mesh.set_surface_override_material(0, current_outline)
		current_outline.set_shader_parameter("outline_color", color)
		outline_mesh.visible = true
	else:
		outline_mesh.set_surface_override_material(0, null)
		outline_mesh.visible = false
		current_outline = null

# General
func set_squad(squad: Node):
	squad_ref = squad

func get_squad():
	return squad_ref

func move_to(destination: Vector3):
	var nav_map = agent.get_navigation_map()
	var safe_target = NavigationServer3D.map_get_closest_point(nav_map, destination)
	agent.target_position = safe_target

func _physics_process(delta):
	if state == UnitState.RETREATING:
		if agent.is_navigation_finished():
			state = UnitState.IDLE
		var next = agent.get_next_path_position()
		var dir = (next - global_position).normalized()
		velocity = dir * speed
		move_and_slide()
		return
	
	# Repulsion
	var repulsion := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("selectable"):
		if other == self or not other is CharacterBody3D:
			continue
		var offset = global_position - other.global_position
		var dist = offset.length()
		if dist > 0 and dist < REPULSION_RADIUS:
			repulsion += offset.normalized() * ((REPULSION_RADIUS - dist) / REPULSION_RADIUS)
	if repulsion.length() > 0.01:
		target_velocity += repulsion.normalized() * REPULSION_STRENGTH * delta
	
	# Navigation
	if target and is_instance_valid(target) and not agent.is_navigation_finished():
		if global_position.distance_to(target.global_position) <= attack_range:
			agent.set_target_position(global_position)
	
	if not agent.is_navigation_finished():
		var next = agent.get_next_path_position()
		var direction = (next - global_position).normalized()
		target_velocity = target_velocity.lerp(direction * speed, delta * 5.0)
		if direction.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), delta * 8.0)
	else:
		target_velocity = Vector3.ZERO
	
	# Combat
	attack_timer -= delta
	if target and is_instance_valid(target) and state != UnitState.RETREATING:
		# 1) measure nav and distance to the *closest* point
		var nav_done := agent.is_navigation_finished()
		var hit_pos = target.global_transform.origin
		if target.has_method("get_closest_point_to"):
			hit_pos = target.get_closest_point_to(global_position)
		var dist := global_position.distance_to(hit_pos)

		# 2) if still moving, but *in range* of center, clamp to stop there
		if not nav_done:
			var center_dist := global_position.distance_to(target.global_transform.origin)
			if center_dist <= attack_range:
				agent.set_target_position(global_position)

		# 3) fire when stopped, in range, timer expired
		if nav_done and dist <= attack_range and attack_timer <= 0.0:
			state = UnitState.ATTACKING
			var th = target.hardness if "hardness" in target else 0.0
			var dmg = attack_damage * (1.0 - th)
			target.take_damage(dmg)
			attack_timer = attack_cooldown
	
	velocity = target_velocity
	move_and_slide()

# Targeting
func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		if squad_ref and squad_ref.has_method("unit_died"):
			squad_ref.unit_died(self)
		queue_free()
	else:
		if not target or not is_instance_valid(target):
			find_target()

func set_target(t: Node):
	if t and t.has_method("take_damage") and t.owner_id != owner_id:
		target = t

func find_target():
	var closest_unit: Node = null
	var closest_building: Node = null
	var min_unit_dist := INF
	var min_building_dist := INF

	var any_units_left := false
	var units_in_range := []

	for node in get_tree().get_nodes_in_group("targetable"):
		if not node is Node3D or node == self:
			continue
		if node.owner_id == owner_id:
			continue
		if not is_target_visible(node):
			continue

		# classify
		if "move_to" in node:
			var d = global_position.distance_to(node.global_transform.origin)
			if d <= attack_range:
				any_units_left = true
				units_in_range.append("%s (%.2f)" % [node.name, d])
				if d < min_unit_dist:
					min_unit_dist = d
					closest_unit = node
		elif node.has_method("get_closest_point_to"):
			var pt = node.get_closest_point_to(global_position)
			var d = global_position.distance_to(pt)
			if d <= attack_range and d < min_building_dist:
				min_building_dist = d
				closest_building = node

	if any_units_left:
		target = closest_unit
	elif closest_building:
		target = closest_building
	else:
		target = null

func retreat_from_enemy(enemy: Node3D, retreat_distance := 5.0, gap_angle_deg := 45.0):
	state = UnitState.RETREATING
	if not enemy:
		return
	# 1) Compute the direction the enemy is facing
	#    (in Godot forward is -Z)
	var enemy_forward = -enemy.global_transform.basis.z.normalized()
	# 2) Compute the “backward” vector and apply a random ±gap_angle/2
	var backward = -enemy_forward
	var half_gap = gap_angle_deg * 0.5
	var random_offset = randf_range(-half_gap, half_gap)
	var retreat_dir = backward.rotated(Vector3.UP, deg_to_rad(random_offset))
	# 3) Send the agent to that spot
	var retreat_pos = global_position + retreat_dir * retreat_distance
	agent.target_position = retreat_pos
	# 4) drop current target & reset timer so they can re-fire if cancelled
	target = null
	attack_timer = attack_cooldown

func is_target_visible(target: Node) -> bool:
	var fog = get_node("/root/main/fog_viewport/fog_canvas/fog_draw")
	return fog.sample_visibility(target.global_transform.origin, owner_id) > 0.5
