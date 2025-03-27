extends Control

@onready var panel := $"."  
@onready var button := $Control/MenuToggle  

var menu_visible := false
var menu_open_x : float = 0
var menu_closed_x : float = 0

func _ready():
	update_menu_positions()
	panel.position.x = menu_closed_x  

func update_menu_positions():
	var screen_width = get_viewport_rect().size.x
	menu_open_x = screen_width - panel.size.x + 3
	menu_closed_x = screen_width - 60
	if not menu_visible:
		panel.position.x = menu_closed_x  

func toggle_menu():
	menu_visible = !menu_visible
	get_tree().create_tween().tween_property(panel, "position:x", menu_open_x if menu_visible else menu_closed_x, 0.5).set_trans(Tween.TRANS_SINE)

func _input(event):
	if event.is_action_pressed("Toggle_Menu") or button.button_pressed:
		toggle_menu()

func _on_button_pressed():
	toggle_menu()

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		update_menu_positions()
