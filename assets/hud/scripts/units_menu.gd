extends Node

@onready var units_list := $".."

var menu_visible := false
var menu_open : float
var menu_closed : float

func _ready():
	update_menu_positions()
	units_list.position.y = menu_closed

func update_menu_positions():
	var screen_height = get_viewport().size.y
	menu_open = screen_height - units_list.size.y
	menu_closed = screen_height + units_list.size.y

func toggle_menu():
	menu_visible = !menu_visible
	var tween = get_tree().create_tween()
	tween.tween_property(units_list, "position:y", menu_open if menu_visible else menu_closed, 0.4).set_trans(Tween.TRANS_SINE)

func _input(_event):
	return
