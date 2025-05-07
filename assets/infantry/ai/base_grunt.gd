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
@export var attack_cooldown := 0.1    # ← match player’s 0.1s cooldown
var attack_timer := attack_cooldown   # ← start ready to shoot on first target

@export var hardness := 0.0

# Targeting
var target: Node = null

# Timers
@onready var top_level_timer := Timer.new()
@onready var scan_timer := Timer.new()

# General
func get_owner_id() -> int:
	return owner_id

func _ready():
	
	
	# identical to player version
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

# Selection (same as before)
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

# Squad linkage
func set_squad(squad: Node):
	squad_ref = squad

func get_squad():
	return squad_ref

func move_to(destination: Vector3):
	var nav_map = agent.get_navigation_map()
	var safe_target = NavigationServer3D.map_get_closest_point(nav_map, destination)
	agent.target_position = safe_target

func _physics_process(delta):
	# — Repulsion (unchanged) —
	var repulsion := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("selectable"):
		if other == self or not other is CharacterBody3D:
			continue
		var offset = global_position - other.global_position
		var d = offset.length()
		if d > 0 and d < REPULSION_RADIUS:
			repulsion += offset.normalized() * ((REPULSION_RADIUS - d) / REPULSION_RADIUS)
	if repulsion.length() > 0.01:
		target_velocity += repulsion.normalized() * REPULSION_STRENGTH * delta

	# — Navigation (unchanged) —
	if target and is_instance_valid(target) and not agent.is_navigation_finished():
		if global_position.distance_to(target.global_transform.origin) <= attack_range:
			agent.set_target_position(global_position)

	if not agent.is_navigation_finished():
		var next = agent.get_next_path_position()
		var direction = (next - global_position).normalized()
		target_velocity = target_velocity.lerp(direction * speed, delta * 5.0)
		if direction.length() > 0.1:
			rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), delta * 8.0)
	else:
		target_velocity = Vector3.ZERO

	attack_timer -= delta
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		var hit_pos = target.global_transform.origin
		if target.has_method("get_closest_point_to"):
			hit_pos = target.get_closest_point_to(global_position)

		var dist = global_position.distance_to(hit_pos)
		var nav_done = agent.is_navigation_finished()

		if nav_done and dist <= attack_range and attack_timer <= 0.0:
			# ← corrected ternary here:
			var th = target.hardness if "hardness" in target else 0.0
			var dmg = attack_damage * (1.0 - th)
			target.take_damage(dmg)
			attack_timer = attack_cooldown

	# — Movement application —
	velocity = target_velocity
	move_and_slide()

# Take damage (unchanged)
func take_damage(amount: int):
	current_health -= amount
	if current_health <= 0:
		if squad_ref and squad_ref.has_method("unit_died"):
			squad_ref.unit_died(self)
		queue_free()
	else:
		if not target or not is_instance_valid(target):
			find_target()

# Override set_target() to reset timer on new target
func set_target(t: Node):
	if t != target:
		attack_timer = 0.0
	target = t

func find_target():
	var closest_unit: Node = null
	var closest_building: Node = null
	var min_unit_dist := INF
	var min_building_dist := INF

	var any_units_left := false

	for node in get_tree().get_nodes_in_group("targetable"):
		if not node is Node3D or node == self:
			continue
		if node.owner_id == owner_id:
			continue
		if not is_target_visible(node):
			continue

		# classify units vs buildings
		if "move_to" in node:
			var d = global_position.distance_to(node.global_transform.origin)
			if d <= attack_range:
				any_units_left = true
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

# Visibility check unchanged
func is_target_visible(target: Node) -> bool:
	var fog = get_node("/root/main/fog_viewport/fog_canvas/fog_draw")
	return fog.sample_visibility(target.global_transform.origin, owner_id) > 0.5
