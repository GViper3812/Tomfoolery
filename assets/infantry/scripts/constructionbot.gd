extends CharacterBody3D

var owner_id := 0

@onready var agent: NavigationAgent3D = $NavigationAgent3D

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
