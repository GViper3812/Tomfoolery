extends Node

class_name GATDataStore

var army_units: Dictionary = {}
var groups: Dictionary = {}
var buildings: Dictionary = {}

func add_army_unit(unit: ArmyUnit):
	army_units[unit.name] = unit

func get_army_unit(unit_name: String) -> ArmyUnit:
	return army_units.get(unit_name, null)

func add_group(group: GroupData):
	groups[group.group_id] = group

func get_groups_for_owner(owner_id: int) -> Array:
	return groups.values().filter(func(g): return g.group_owner == owner_id)

func add_building(b: BuildingData):
	buildings[b.id] = b

func get_buildings_for_owner(owner_id: int) -> Array:
	return buildings.values().filter(func(b): return b.owner_id == owner_id)
