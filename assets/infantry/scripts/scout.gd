extends CharacterBody3D

@export var owner_id := 0

@onready var agent: NavigationAgent3D = $NavigationAgent3D

@onready var mesh : MeshInstance3D = $mesh/mesh
@onready var outline_material := preload("res://assets/shader/targeting/outline.tres")
var current_outline : ShaderMaterial = null

var move_speed := 2.0
var new_velocity := Vector3.ZERO

func move_to_position(target: Vector3):
	var nav_map = agent.get_navigation_map()
	var safe_target = NavigationServer3D.map_get_closest_point(nav_map, target)
	agent.target_position = safe_target
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

func _physics_process(delta):
	if agent.is_navigation_finished():
		new_velocity = Vector3.ZERO
	else:
		var next_pos = agent.get_next_path_position()
		var direction = (next_pos - global_position).normalized()
		var desired_velocity = direction * move_speed
		
		agent.velocity = desired_velocity
		
		if direction.length() > 0.01:
			var target_rotation = transform.looking_at(global_position + direction, Vector3.UP).basis.get_euler()
			rotation.y = lerp_angle(rotation.y, target_rotation.y, delta * 10.0)
	
	velocity = new_velocity
	move_and_slide()

func _on_velocity_computed(safe_velocity: Vector3) -> void:
	new_velocity = safe_velocity

func set_selected(selected: bool, outline_color: Color = Color.WHITE): 
	if selected:
		if current_outline == null:
			current_outline = outline_material.duplicate() as ShaderMaterial
			mesh.set_surface_override_material(0, current_outline)
		
		current_outline.set_shader_parameter("outline_color", outline_color)
		mesh.visible = true
	else:
		mesh.set_surface_override_material(0, null)
		mesh.visible = false
		current_outline = null
