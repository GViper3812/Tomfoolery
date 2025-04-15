extends Node

signal resources_updated(requisition, power)

signal resource_totals(requisition, power)

var requisition : float = 5000
var power : float = 1500
var requisition_gain : float = 20
var power_gain : float = 5

@onready var update_timer: Timer = get_node("../Timer")

func _ready():
	update_timer.wait_time = 2.5
	update_timer.timeout.connect(_on_timer_timeout)
	update_timer.start()

func _on_timer_timeout():
	requisition += requisition_gain
	power += power_gain
	emit_signal("resources_updated", requisition, requisition_gain, power, power_gain)
	emit_signal("resource_totals", requisition, power)

func deduct_resources(requisition_cost: int, power_cost: int) -> bool:
	if requisition >= requisition_cost and power >= power_cost:
		requisition -= requisition_cost
		power -= power_cost
		emit_signal("resources_updated", requisition, requisition_gain, power, power_gain)
		emit_signal("resource_totals", requisition, power)
		return true
	return false

func get_resources() -> Dictionary:
	return {"requisition": requisition, "power": power}
