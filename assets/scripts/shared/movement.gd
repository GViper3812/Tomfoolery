extends CharacterBody3D

const SPEED := 10.0
const MOVEMENT_SMOOTH_SPEED = 5.0

var target_velocity = Vector3.ZERO
var smoothed_velocity = Vector3.ZERO

@onready var cam_control: Node3D = $cam_control

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("Move_Left", "Move_Right", "Move_Back", "Move_Forward")
	
	if input_dir != Vector2.ZERO:
		var camera_basis = cam_control.get_camera_basis()
		var forward = -camera_basis.z
		forward.y = 0
		forward = forward.normalized()
		
		var right = camera_basis.x
		right.y = 0
		right = right.normalized()
		
		var direction = (forward * input_dir.y + right * input_dir.x).normalized()
		target_velocity = direction * SPEED
	else:
		target_velocity = Vector3.ZERO
		
	smoothed_velocity = lerp(smoothed_velocity, target_velocity, MOVEMENT_SMOOTH_SPEED * delta)
	
	velocity.x = smoothed_velocity.x
	velocity.z = smoothed_velocity.z
	
	move_and_slide()
