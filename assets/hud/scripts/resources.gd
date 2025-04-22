extends VBoxContainer

@onready var req : Label = $PanelContainer/requisition/current
@onready var req_gain : Label = $PanelContainer/requisition/gain
@onready var pow : Label = $PanelContainer2/power/current
@onready var pow_gain : Label = $PanelContainer2/power/gain

@onready var rm := get_node("../../../../../resource_manager")

func _ready():
	if rm:
		rm.resources_updated.connect(_on_resources_updated)
		_on_resources_updated(rm.requisition, rm.requisition_gain, rm.power, rm.power_gain)

func _on_resources_updated(requisition, requisition_gain, power, power_gain):
	req.text = "%d" % [requisition]
	req_gain.text = "+%.1f/s" % [requisition_gain]
	pow.text = "%d" % [power]
	pow_gain.text = "+%.1f/s" % [power_gain]
