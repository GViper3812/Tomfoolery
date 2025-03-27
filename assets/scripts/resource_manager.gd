extends Node

signal resources_updated(requisition, power)

var requisition_points := 500.0
var power := 200.0
var requisition_gain := 5.0
var power_gain := 2.5

@onready var update_timer: Timer = get_node("../Timer")

func _ready():
	update_timer.wait_time = 1.0
	update_timer.timeout.connect(_on_timer_timeout)
	update_timer.start()

func _on_timer_timeout():
	requisition_points += requisition_gain
	power += power_gain
	emit_signal("resources_updated", requisition_points, power)

func deduct_resources(requisition_cost: int, power_cost: int) -> bool:
	if requisition_points >= requisition_cost and power >= power_cost:
		requisition_points -= requisition_cost
		power -= power_cost
		emit_signal("resources_updated", requisition_points, power)
		return true
	return false

func get_resources() -> Dictionary:
	return {"requisition": requisition_points, "power": power}
