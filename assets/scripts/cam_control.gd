extends Node3D

const CAMERA_SMOOTH_SPEED = 10.0
const MAX_LOOK_UP = 75.0
const MAX_LOOK_DOWN = 15.0
const ZOOM_SPEED = 0.5
const MIN_ZOOM = 3.0
const MAX_ZOOM = 17.0
const CAMERA_ROTATION_SENSITIVITY = 0.3
const CAMERA_SMOOTH_ROTATION_SPEED = 16.0

@onready var camera: Camera3D = $"../Cam"

var yaw = 45.0
var pitch = 30.0
var smooth_yaw = 45.0
var smooth_pitch = 30.0
var zoom_distance = 10.0
var target_zoom_distance = 10.0

func _ready():
	zoom_distance = target_zoom_distance
	
func _input(event):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
		if event is InputEventMouseMotion:
			yaw -= event.relative.x * CAMERA_ROTATION_SENSITIVITY
			pitch -= event.relative.y * CAMERA_ROTATION_SENSITIVITY
			
			pitch = clamp(pitch, MAX_LOOK_DOWN, MAX_LOOK_UP)
			
			
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom_distance = max(MIN_ZOOM, target_zoom_distance - ZOOM_SPEED)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom_distance = min(MAX_ZOOM, target_zoom_distance + ZOOM_SPEED)

func _process(delta):
	zoom_distance = lerp(zoom_distance, target_zoom_distance, CAMERA_SMOOTH_SPEED * delta)
	
	smooth_yaw = lerp(smooth_yaw, yaw, CAMERA_SMOOTH_ROTATION_SPEED * delta)
	smooth_pitch = lerp(smooth_pitch, pitch, CAMERA_SMOOTH_ROTATION_SPEED * delta)
	
	var offset = Vector3(
		cos(deg_to_rad(smooth_yaw)) * cos(deg_to_rad(smooth_pitch)),
		sin(deg_to_rad(smooth_pitch)),
		sin(deg_to_rad(smooth_yaw)) * cos(deg_to_rad(smooth_pitch))
		).normalized() * zoom_distance
	
	camera.global_transform.origin = global_transform.origin + offset
	camera.look_at(global_transform.origin, Vector3.UP)
	
func get_camera_basis() -> Basis:
	return camera.global_transform.basis
