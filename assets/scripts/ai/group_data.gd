extends Resource

class_name GroupData

var group_id: int
var group_owner: int

var frontline_ids: Array[int] = []
var backline_ids: Array[int] = []

var frontline_positions: Dictionary = {}
var backline_positions: Dictionary = {}

var frontline_dps_total: float = 0.0
var backline_dps_total: float = 0.0

var frontline_total_hp: float = 0.0
var backline_total_hp: float = 0.0

var frontline_avg_hardness: float = 0.0
var backline_avg_hardness: float = 0.0
