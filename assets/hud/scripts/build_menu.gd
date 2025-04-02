extends Control

@onready var build_menu := $".."
@onready var menu_toggle := $"../HSplitContainer/MarginContainer/menutoggle"
@onready var margin := $"../HSplitContainer/MarginContainer"

var menu_visible := false
var menu_open : float
var menu_closed : float

func _ready():
	update_menu_positions()
	build_menu.position.x = menu_closed

func update_menu_positions():
	var screen_width = get_viewport().size.x
	menu_open = screen_width - build_menu.size.x
	menu_closed = screen_width - margin.size.x

func toggle_menu():
	menu_visible = !menu_visible
	var tween = get_tree().create_tween()
	tween.tween_property(build_menu, "position:x", menu_open if menu_visible else menu_closed, 0.5).set_trans(Tween.TRANS_SINE)

func _input(event):
	if menu_toggle.button_pressed or event.is_action_pressed("Toggle_Menu"):
		toggle_menu()
