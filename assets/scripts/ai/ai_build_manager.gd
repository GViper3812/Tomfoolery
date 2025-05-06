extends Node

class_name AIBuildManager

@onready var services : Node = get_node("../ai_services")
@onready var pm = services.pm
@onready var rm = services.rm
@onready var root_grid = get_node("/root/main/grid")
@onready var navmesh = get_node("/root/main/navmesh")

var editmat: ShaderMaterial = preload("res://assets/shader/building/editmat.tres")
var mainmat: Material = preload("res://assets/shader/building/mainmat.tres")
var player_id: int

func place_building(building_scene: PackedScene, world_position: Vector3) -> bool:
	print("[AI][BuildManager] Called with scene: ", building_scene, " at: ", world_position)
	
	if not building_scene:
		print("[AI][BuildManager] No scene provided")
		return false
	
	var building_instance = building_scene.instantiate()
	if not building_instance:
		print("[AI][BuildManager] Failed to instantiate scene")
		return false
	
	for child in building_instance.get_children():
		if "owner_id" in child:
			child.owner_id = player_id
	print("[AI][BuildManager] Owner assigned")
	
	var snapped_pos = root_grid.map_to_local(root_grid.local_to_map(world_position))
	snapped_pos.y = 0
	navmesh.add_child(building_instance)
	building_instance.global_transform.origin = snapped_pos
	
	var col = building_instance.get_node_or_null("col")
	if col:
		col.disabled = false
	
	var mesh_node = building_instance.get_node_or_null("mesh")
	if mesh_node:
		mesh_node.set_surface_override_material(0, mainmat)
	
	print("[AI][BuildManager] Building added to navmesh")
	
	if navmesh.navigation_mesh:
		print("[AI][BuildManager] Baking navmesh...")
		navmesh.bake_navigation_mesh()
	
	print("[AI][BuildManager] Placed building at ", snapped_pos)
	return true
