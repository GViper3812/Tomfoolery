extends Node
class_name RBSExecutor

@onready var services : Node = get_node("../ai_services")
@onready var rm = services.rm
@onready var pm = services.pm
@onready var bm = services.bm
@onready var player_id = services.player_id
@onready var ts = services.ts

class BuildRequest:
	var scene: PackedScene
	var position: Vector3
	var requisition_cost: int
	var power_cost: int

class UnitRequest:
	var scene: PackedScene
	var unit_type: String
	var cap_cost: int
	var requisition_cost: int
	var power_cost: int
	var spawn_func: Callable

func request_build(building_type: String, position := Vector3.ZERO):
	var scene_path = "res://assets/building/AI/scene/"
	var building_files := {
		"lp": "landingpad.tscn"
	}

	if not building_files.has(building_type):
		print("[AI][RBS] Unknown building type: ", building_type)
		return
	
	# Avoid duplicate LPs
	if building_type == "lp":
		var lp_exists := false
		for b in get_tree().get_nodes_in_group("building"):
			var manager = b.get_node_or_null("lp_manager")
			if manager and "owner_id" in manager and manager.owner_id == player_id:
				lp_exists = true
				break
		
		if lp_exists:
			print("[AI][RBS] LP already exists — skipping build request.")
			return
		
		var fob = null
		for b in get_tree().get_nodes_in_group("building"):
			var manager = b.get_node_or_null("fob_manager")
			if manager and manager.owner_id == player_id and b.name.to_lower().contains("fob"):
				fob = b
				break
		
		if fob:
			position = fob.global_transform.origin + Vector3(6, 0, 6)
		else:
			print("[AI][RBS] No FOB found — cannot determine LP build location.")
			return
	
	var scene = load(scene_path + building_files[building_type])
	var temp = scene.instantiate()
	var req_cost = temp.r_cost
	var pow_cost = temp.p_cost
	temp.queue_free()
	
	var req = BuildRequest.new()
	req.scene = scene
	req.position = position
	req.requisition_cost = req_cost
	req.power_cost = pow_cost
	try_place_building(req)

func request_unit(unit_type: String):
	match unit_type:
		"grunt":
			var lp = get_available_lp()
			if not lp:
				print("[AI][RBS] No LP available — cannot spawn grunt.")
				return
			
			var scene = preload("res://assets/infantry/ai/gruntsquad.tscn")
			var req = UnitRequest.new()
			req.scene = scene
			req.unit_type = "infantry"
			req.cap_cost = 3
			req.requisition_cost = 300
			req.power_cost = 100
			req.spawn_func = func():
				lp.get_node("lp_manager").queue_action("spawn grunt squad", 5.0, scene)
			
			try_spawn_unit(req)
		_:
			print("[AI][RBS] Unknown unit type: ", unit_type)

func try_place_building(req: BuildRequest) -> bool:
	print("[AI][RBS] Attempting to place building at: ", req.position)
	if not rm.deduct_resources(req.requisition_cost, req.power_cost):
		print("[AI][RBS] Not enough resources!")
		return false
	if not bm.place_building(req.scene, req.position):
		print("[AI][RBS] Build placement failed!")
		return false
	print("[AI][RBS] Building placed!")
	return true

func try_spawn_unit(req: UnitRequest) -> bool:
	print("[AI][RBS] Attempting to spawn: ", req.unit_type)
	if not ts.can_spawn_grunt():
		print("[AI][RBS] Tech restricts spawning this unit.")
		return false
	if not pm.can_spawn_unit(req.unit_type, req.cap_cost):
		print("[AI][RBS] Cap limit hit.")
		return false
	if not rm.deduct_resources(req.requisition_cost, req.power_cost):
		print("[AI][RBS] Insufficient resources.")
		return false
	pm.register_unit(req.unit_type, req.cap_cost)
	if req.spawn_func:
		req.spawn_func.call()
	print("[AI][RBS] Unit spawned.")
	return true

func get_available_lp() -> Node:
	for b in get_tree().get_nodes_in_group("building"):
		var manager = b.get_node_or_null("lp_manager")
		if manager and manager.owner_id == player_id:
			return b
	return null
