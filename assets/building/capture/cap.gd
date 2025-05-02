extends Node3D

class_name CapturePoint

var capture_time := 1.0
var owner_id := -1

@onready var flag := $flag
@onready var area: Area3D = $Area3D
@onready var timer: Timer = $Timer

var capturing_units := {}
var capturing_team := -1

signal capture_started(team_id)
signal capture_completed(team_id)

func _ready():
	timer.wait_time = capture_time
	timer.timeout.connect(_on_capture_complete)
	update_visuals()

func _on_body_entered(body):
	if body.has_method("get_owner_id"):
		var team_id = body.get_owner_id()
		capturing_units[body] = team_id
		_update_capture_team()

func _on_body_exited(body):
	capturing_units.erase(body)
	_update_capture_team()

func _update_capture_team():
	var teams = capturing_units.values()
	if teams.size() == 0:
		if not timer.is_stopped():
			timer.stop()
		capturing_team = -1
		return
	
	var first_team = teams[0]
	for t in teams:
		if t != first_team:
			timer.stop()
			capturing_team = -1
			return
	
	if owner_id == first_team:
		return
	
	if capturing_team != first_team:
		capturing_team = first_team
		timer.start()
		emit_signal("capture_started", capturing_team)
	
	if capturing_team != first_team:
		capturing_team = first_team
		timer.start()
		emit_signal("capture_started", capturing_team)

func _on_capture_complete():
	timer.stop()
	
	var previous_owner := owner_id
	owner_id = capturing_team
	update_visuals()
	
	if previous_owner != -1:
		var prev_ps = find_services(previous_owner)
		if prev_ps and "rm" in prev_ps:
			prev_ps.rm.decrease_req_gain(10)
			print("[CapturePoint] Removed gain from team", previous_owner)
	
	var new_ps = find_services(owner_id)
	if new_ps and "rm" in new_ps:
		new_ps.rm.increase_req_gain(10)
		print("[CapturePoint] Added gain to team", owner_id)
	
	emit_signal("capture_completed", owner_id)

func is_targetable() -> bool:
	return true

func update_visuals():
	if not flag:
		return
	
	if flag.material_override == null:
		flag.material_override = StandardMaterial3D.new()
	
	var mat := flag.material_override as StandardMaterial3D
	
	match owner_id:
		-1:
			mat.albedo_color = Color.DIM_GRAY
		1:
			mat.albedo_color = Color.GREEN
		2:
			mat.albedo_color = Color.RED

func find_services(id : int) -> Node:
	for node in get_tree().get_nodes_in_group("ps"):
		if "player_id" in node and node.player_id == owner_id:
			return node
	return null
