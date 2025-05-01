extends CharacterBody3D

@export var owner_id := 1
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var outline_mesh: MeshInstance3D = $mesh/outline
@onready var outline_material := preload("res://assets/shader/targeting/outline.tres")

# Movement
var current_outline: ShaderMaterial = null
var target_velocity: Vector3 = Vector3.ZERO
@export var speed := 2.5

# Combat stats
@export var max_health := 60
var current_health := max_health
@export var attack_damage := 5
@export var attack_range := 9.0
@export var attack_cooldown := 1.2
@export var hardness := 0.95

# Targeting
var target: Node = null
var target_hardness := 0.0
var attack_timer := 0.0
@onready var scan_timer := Timer.new()

# Repulsion
const REPULSION_RADIUS := 0.3
const REPULSION_STRENGTH := 10.0

# Setup
func _ready():
	scan_timer.wait_time = 1.0
	scan_timer.one_shot = false
	scan_timer.timeout.connect(_on_scan_timer_timeout)
	add_child(scan_timer)
	scan_timer.start()

func _on_scan_timer_timeout():
	if not target or not is_instance_valid(target):
		find_target()

func move_to(destination: Vector3):
	var nav_map = agent.get_navigation_map()
	var safe_target = NavigationServer3D.map_get_closest_point(nav_map, destination)
	agent.target_position = safe_target

func set_selected(selected: bool, color: Color = Color.GREEN):
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

func _physics_process(delta):
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
	if not agent.is_navigation_finished():
		var next = agent.get_next_path_position()
		var direction = (next - global_position).normalized()
		var desired = direction * speed
		target_velocity = target_velocity.lerp(desired, delta * 5.0)
		if direction.length() > 0.1:
			var target_yaw = atan2(direction.x, direction.z)
			rotation.y = lerp_angle(rotation.y, target_yaw, delta * 8.0)
	else:
		target_velocity = Vector3.ZERO
	
	# Combat
	attack_timer -= delta
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		if global_position.distance_to(target.global_position) <= attack_range:
			if attack_timer <= 0:
				if "hardness" in target:
					target_hardness = target.hardness
				var effective_damage := attack_damage * (1.0 - target_hardness)
				print("%s is attacking %s (hardness: %.2f) for %.2f effective damage" % [name, target.name, target_hardness, effective_damage])
				target.take_damage(effective_damage)
				attack_timer = attack_cooldown
	
	velocity = target_velocity
	move_and_slide()

# Targeting
func take_damage(amount: float):
	current_health -= amount
	if current_health <= 0:
		queue_free()

func set_target(t: Node):
	if t and t.has_method("take_damage") and t.owner_id != owner_id:
		target = t

func find_target():
	var closest = null
	var min_dist = 9999.0
	for node in get_tree().get_nodes_in_group("targetable"):
		if not node is Node3D or node == self:
			continue
		if node.owner_id == owner_id:
			continue
		if is_target_visible(node):
			continue
		var dist = global_position.distance_to(node.global_position)
		if dist < attack_range and dist < min_dist:
			min_dist = dist
			closest = node
	target = closest

func is_target_visible(target: Node) -> bool:
	var fog = get_node("/root/main/fog_viewport/fog_canvas/fog_draw")
	return fog.sample_visibility(target.global_transform.origin, owner_id) > 0.5
