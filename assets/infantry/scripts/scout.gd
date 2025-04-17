extends CharacterBody3D

@onready var agent: NavigationAgent3D = $NavigationAgent3D

var move_speed := 2.0

func move_to_position(target: Vector3):
	agent.target_position = target
	
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	var path = agent.get_current_navigation_path()

func _physics_process(delta):
	if agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return
	
	var next_pos = agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()
	
	if direction.length() > 0.01:
		var target_rotation = transform.looking_at(global_position + direction, Vector3.UP).basis.get_euler()
		rotation.y = lerp_angle(rotation.y, target_rotation.y, delta * 10.0)
