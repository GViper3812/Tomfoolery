extends Node

enum States {
	play,
	building,
	blocked,
	destroying
}

static var state := States.play
static var can_place := true

signal state_changed()

static func get_mouse_world_position(camera: Camera3D) -> Vector3:
	var mouse_pos = camera.get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	var ray_length = 1000
	var space_state = camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
	
	var result = space_state.intersect_ray(query)
	return result.position if result else Vector3.ZERO

func set_state(new_state: States):
	state = new_state
	emit_signal("state_changed")

func get_state() -> States:
	return state
