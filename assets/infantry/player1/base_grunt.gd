extends CharacterBody3D

@export var owner_id := 0
@onready var agent: NavigationAgent3D = $NavigationAgent3D
@onready var outline_mesh: MeshInstance3D = $mesh/outline
@onready var outline_material := preload("res://assets/shader/targeting/outline.tres")

var squad_ref: Node = null
var current_outline: ShaderMaterial = null
var target_velocity: Vector3 = Vector3.ZERO
var speed := 2.0

const REPULSION_RADIUS := 0.3
const REPULSION_STRENGTH := 10.0

func set_squad(squad: Node):
	squad_ref = squad

func get_squad():
	return squad_ref

func move_to(destination: Vector3):
	var nav_map = agent.get_navigation_map()
	var safe_target = NavigationServer3D.map_get_closest_point(nav_map, destination)
	agent.target_position = safe_target

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

func _physics_process(delta):
	var repulsion := Vector3.ZERO
	
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
	
	for other in get_tree().get_nodes_in_group("selectable"):
		if other == self or not other is CharacterBody3D:
			continue
		var offset = global_position - other.global_position
		var dist = offset.length()
		if dist > 0 and dist < REPULSION_RADIUS:
			repulsion += offset.normalized() * ((REPULSION_RADIUS - dist) / REPULSION_RADIUS)
	
	if repulsion.length() > 0.01:
		target_velocity += repulsion.normalized() * REPULSION_STRENGTH * delta
	
	velocity = target_velocity
	
	move_and_slide()
