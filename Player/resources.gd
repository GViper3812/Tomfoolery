extends VBoxContainer

@onready var req_label = $requisition/current as Label
@onready var power_label = $power/current as Label
@onready var resource_manager = get_node("/root/rootGrid/Player1/resource_manager")

func _ready():
	if resource_manager:
		resource_manager.resources_updated.connect(_on_resources_updated)
		_on_resources_updated(resource_manager.requisition_points, resource_manager.power)

func _on_resources_updated(requisition, power):
	req_label.text = "Requisition: %d (+%.1f/s)" % [requisition, resource_manager.requisition_gain]
	power_label.text = "Power: %d (+%.1f/s)" % [power, resource_manager.power_gain]
