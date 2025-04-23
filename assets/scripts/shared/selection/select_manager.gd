extends Node

class_name SelectManager

@onready var input_handler: InputHandler = $input_handler
@onready var selection_logic: SelectionLogic = $selection_logic
@onready var order_handler: OrderHandler = $order_handler
@onready var hud_controller: HUDController = $hud_controller

@onready var services := get_node("../player_services")
@onready var player_id = services.player_id
@onready var pm = services.pm
@onready var bm = services.bm
@onready var cam : Camera3D = $"../Cam"
@onready var selection_rect : Control = get_node("../Player%dHUD/HUD/selectionrect" % player_id)
@onready var hud : Control = services.get_hud()
@onready var current_parent = services.get_current_parent_panel()

var selected_units : Array[Node] = []
var selected : Node = null
var selected_hostile : Node = null
var hostile_recent := false
var selecting := false
var start_mouse_pos := Vector2.ZERO

func _ready():
	input_handler.setup(self)
	selection_logic.setup(self)
	order_handler.setup(self)
	hud_controller.setup(self)
	set_process_input(true)

func _input(event):
	input_handler.process_input(event)

func _process(delta):
	input_handler.process_frame()

func get_selected() -> Node:
	return selected
