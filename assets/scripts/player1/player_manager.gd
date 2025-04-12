extends Node

# State Management
enum States {
	play,
	building,
	blocked,
	destroying
}

static var state := States.play
static var can_place := true

signal state_changed()

func set_state(new_state: States):
	state = new_state
	emit_signal("state_changed")

func get_state() -> States:
	return state

# Mouse Ray Management
static func get_mouse_world_position(camera: Camera3D) -> Vector3:
	if camera.get_viewport().gui_get_hovered_control() != null:
		return Vector3.ZERO
	
	var ray_length = 1000
	var mouse_pos = camera.get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	var space_state = camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
	
	var result = space_state.intersect_ray(query)
	return result.position if result else Vector3.ZERO

static func get_first_area_hit(camera: Camera3D) -> Area3D:
	if camera.get_viewport().gui_get_hovered_control() != null:
		return null
	
	var ray_length = 1000
	var mouse_pos = camera.get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_direction = camera.project_ray_normal(mouse_pos)
	var space_state = camera.get_world_3d().direct_space_state
	
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_origin + ray_direction * ray_length)
	query.collide_with_bodies = false
	query.collide_with_areas = true
	
	var result = space_state.intersect_ray(query)
	
	if result and result.collider is Area3D:
		return result.collider
	
	return null

# Cap Management
signal cap_updated

var infantry_cap_max := 20
var infantry_cap_used := 0

var vehicle_cap_max := 10
var vehicle_cap_used := 0

func can_spawn_unit(unit_type: String, cap_cost: int) -> bool:
	match unit_type:
		"infantry":
			return infantry_cap_used + cap_cost <= infantry_cap_max
		"vehicle":
			return vehicle_cap_used + cap_cost <= vehicle_cap_max
		_:
			return true

func register_unit(unit_type: String, cap_cost: int):
	match unit_type:
		"infantry":
			infantry_cap_used += cap_cost
		"vehicle":
			vehicle_cap_used += cap_cost
	
	emit_signal("cap_updated")

func release_unit(unit_type: String, cap_cost: int):
	match unit_type:
		"infantry":
			infantry_cap_used -= cap_cost
		"vehicle":
			vehicle_cap_used -= cap_cost
	
	emit_signal("cap_updated")

func get_unit_cap_status() -> Dictionary:
	return {
		"infantry": { "used": infantry_cap_used, "max": infantry_cap_max },
		"vehicle": { "used": vehicle_cap_used, "max": vehicle_cap_max }
	}
