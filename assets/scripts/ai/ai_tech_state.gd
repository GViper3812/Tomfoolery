extends Node

class_name AITechState

var fob_level := 1
var lp_level := 1

func upgrade_fob():
	fob_level += 1
	print("[AI][Tech] FOB upgraded to level ", fob_level)

func upgrade_lp():
	if can_upgrade_lp():
		lp_level += 1
		print("[AI][Tech] LP upgraded to level ", lp_level)
	else:
		print("[AI][Tech] ❌ Cannot upgrade LP until FOB is level 2")

func can_spawn_grunt() -> bool:
	return fob_level >= 1 and lp_level >= 1

func can_spawn_heavy_infantry() -> bool:
	return fob_level >= 2 and lp_level >= 2

func can_upgrade_lp() -> bool:
	return fob_level >= 2
