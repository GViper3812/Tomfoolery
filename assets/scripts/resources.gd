extends VBoxContainer

@onready var req : Label = $PanelContainer/requisition/current
@onready var req_gain : Label = $PanelContainer/requisition/gain
@onready var pow : Label = $PanelContainer2/power/current
@onready var pow_gain : Label = $PanelContainer2/power/gain

@onready var resource_manager = get_node("/root/rootGrid/Player1/resource_manager")

func _ready():
	if resource_manager:
		resource_manager.resources_updated.connect(_on_resources_updated)
		_on_resources_updated(resource_manager.requisition, resource_manager.requisition_gain, resource_manager.power, resource_manager.power_gain)

func _on_resources_updated(requisition, requisition_gain, power, power_gain):
	req.text = "%d" % [requisition]
	req_gain.text = "+%.1f/s" % [requisition_gain]
	pow.text = "%d" % [power]
	pow_gain.text = "+%.1f/s" % [power_gain]
