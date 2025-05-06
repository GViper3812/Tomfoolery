extends Node
class_name GATCommander

@onready var services : Node = get_node("../ai_services")
@onready var ts = services.ts
@onready var rbs = services.rbs
@onready var gd = services.gd
@onready var fog = get_node("/root/main/fog_manager")
@onready var fog_draw = get_node("/root/main/fog_viewport/fog_canvas/fog_draw")

func _ready():
	init_army_units()

func _process(delta: float) -> void:
	if randi() % 1000 < 10:
		thinking_cycle()

func thinking_cycle():
	print("\n[AI][GAT] Thinking cycle...")
	
	update_battlefield_knowledge()
	print_visible_enemies()
	
	request_lp_if_none()
	
	if ts.can_spawn_grunt():
		request_grunt_spawn()

func request_lp_if_none():
	var lp_found := false
	print("[AI][GAT] 🔎 Scanning for existing LPs...")

	for b in get_tree().get_nodes_in_group("building"):
		print("Checking building: ", b.name)
		
		if not b.has_node("lp_manager"):
			print("  • No lp_manager node found in ", b.name)
			continue

		var manager = b.get_node("lp_manager")
		if manager and "owner_id" in manager:
			if manager.owner_id == services.player_id:
				print("[AI][GAT] Found owned LP — skipping build.")
				lp_found = true
				break
		else:
			print("  • lp_manager exists, but no valid owner_id found!")

	if not lp_found:
		print("[AI][GAT] No LP found — requesting build.")
		var desired_position := pick_base_position()
		rbs.request_build("lp", desired_position)

func request_grunt_spawn():
	rbs.request_unit("grunt")

func pick_base_position() -> Vector3:
	return Vector3(randf() * 20.0, 0, randf() * 20.0)

func init_army_units():
	var unit = ArmyUnit.new()
	unit.name = "Grunt"
	unit.hp = 100
	unit.damage = 10
	unit.hardness = 0.0
	unit.requisition_cost = 50
	unit.power_cost = 0
	unit.cap_cost = { "infantry": 2 }
	unit.frontline_frequency = 0.0
	unit.backline_frequency = 0.0
	gd.add_army_unit(unit)
	
	var heavy = ArmyUnit.new()
	heavy.name = "HeavyInfantry"
	heavy.hp = 160
	heavy.damage = 18
	heavy.hardness = 0.15
	heavy.requisition_cost = 90
	heavy.power_cost = 30
	heavy.cap_cost = { "infantry": 4 }
	heavy.frontline_frequency = 0.0
	heavy.backline_frequency = 0.0
	gd.add_army_unit(heavy)
	
	print("[AI][GAT] Initialized army unit database.")

func update_battlefield_knowledge():
	gd.groups.clear()
	gd.buildings.clear()
	
	var group := GroupData.new()
	group.group_id = 1
	group.group_owner = 1
	
	var ai_image: Image = fog.ai_visibility_image
	
	var enemy_units := get_tree().get_nodes_in_group("infantry") + get_tree().get_nodes_in_group("vehicles")
	for unit in enemy_units:
		if not unit.has_method("get_owner_id") or unit.owner_id == services.player_id:
			continue
		
		var pos = unit.global_position
		var fog_pixel = fog_draw.world_to_fog_viewport(pos).floor() + Vector2(128, 128)
		var fx = int(clamp(fog_pixel.x, 0, ai_image.get_width() - 1))
		var fy = int(clamp(fog_pixel.y, 0, ai_image.get_height() - 1))
		
		var visibility = ai_image.get_pixel(fx, fy).r
		if visibility <= 0.9:
			continue
		
		var id = unit.get_instance_id()
		var hp = unit.hp if "hp" in unit else 100
		var dps = unit.dps if "dps" in unit else 10
		var hardness = unit.hardness if "hardness" in unit else 0.0
		var is_frontline = hardness > 0.3
		var pos2d = Vector2(pos.x, pos.z)
		
		if is_frontline:
			group.frontline_ids.append(id)
			group.frontline_positions[id] = pos2d
			group.frontline_total_hp += hp
			group.frontline_dps_total += dps
			group.frontline_avg_hardness += hardness
		else:
			group.backline_ids.append(id)
			group.backline_positions[id] = pos2d
			group.backline_total_hp += hp
			group.backline_dps_total += dps
			group.backline_avg_hardness += hardness
	
	if group.frontline_ids.size() > 0:
		group.frontline_avg_hardness /= group.frontline_ids.size()
	if group.backline_ids.size() > 0:
		group.backline_avg_hardness /= group.backline_ids.size()
	
	gd.add_group(group)

func print_visible_enemies():
	var ai_image = fog.ai_visibility_image
	print("[AI][GAT] Visible Enemy Units:")
	for unit in get_tree().get_nodes_in_group("infantry") + get_tree().get_nodes_in_group("vehicles"):
		if not "owner_id" in unit or unit.owner_id == services.player_id:
			continue
		var pos = unit.global_position
		var fog_pixel = fog_draw.world_to_fog_viewport(pos).floor() + Vector2(128, 128)
		var fx = int(clamp(fog_pixel.x, 0, ai_image.get_width() - 1))
		var fy = int(clamp(fog_pixel.y, 0, ai_image.get_height() - 1))
		if ai_image.get_pixel(fx, fy).r > 0.9:
			print("  • ", unit.name, " at ", Vector2(pos.x, pos.z))
