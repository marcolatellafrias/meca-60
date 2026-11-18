extends Node

## UN BLANCO DE PRUEBA para los tests de red: cuenta los golpes que le llegan (lo que dice EnergyBolt.lands a quien
## lleva `take_hit`). Ver tests/gunner_net_check.

var hits := 0


func take_hit(_strength: float, _at: Vector3, _source: String) -> void:
	hits += 1
