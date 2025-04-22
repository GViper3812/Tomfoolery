extends Node

@export var player_id := 0

var rm : Node = get_node_or_null("../resource_manager")
var pm : Node = get_node_or_null("../player_manager")
var sm : Node = get_node_or_null("../select_manager")
var bm : Node = get_node_or_null("../build_manager")

func _ready():
	pm = get_node_or_null("../player_manager")
	rm = get_node_or_null("../resource_manager")
	sm = get_node_or_null("../select_manager")
	bm = get_node_or_null("../build_manager")

func get_hud() -> Control:
	var player_hud_name = "Player%dHUD" % player_id
	var hud_root = get_node_or_null("../" + player_hud_name)
	if hud_root == null:
		push_error("HUD root not found: ../" + player_hud_name)
		return null
	
	var hud = hud_root.get_node_or_null("HUD")
	if hud == null:
		push_error("HUD node not found in: " + player_hud_name + "/HUD")
	return hud

func get_current_parent_panel() -> Control:
	var path = "../Player%dHUD/HUD/selected_functions/MarginContainer2/Panel/MarginContainer" % player_id
	return get_node_or_null(path)
