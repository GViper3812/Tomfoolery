extends Node

@export var player_id := 2

var rm : Node = get_node_or_null("../ai_resource_manager")
var pm : Node = get_node_or_null("../ai_manager")
var bm : Node = get_node_or_null("../ai_build_manager")
var ts : Node = get_node_or_null("../ai_tech_state")
var gd : Node = get_node_or_null("../get_data")
var rbs : Node = get_node_or_null("../rbs_process")

func _ready():
	pm = get_node_or_null("../ai_manager")
	rm = get_node_or_null("../ai_resource_manager")
	bm = get_node_or_null("../ai_build_manager")
	ts = get_node_or_null("../ai_tech_state")
	gd = get_node_or_null("../get_data")
	rbs = get_node_or_null("../rbs_process")
