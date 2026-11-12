class_name LeggedCubeArchetype
extends HoverCubeArchetype

## LA PARCELA DEL CUBO CON PIERNAS (ver LeggedCube): la del cubo (los cuatro tiros con J/K, volcarlo con F2, manejarlo
## con la O) con el cubo con piernas y sus perillas. F1 abre su panel (LeggedCubePanel). Manejándolo, el mouse gira el
## torso aparte de las piernas.


func _init() -> void:
	display_name = "Cubo con piernas"


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"el cubo con pelvis y dos piernas (las de la meca)",
		"O manejarlo: W/S y A/D las piernas, el mouse el torso",
		"los pies pisan por radio: lo siguen caminando, girando o corrido por un golpe",
	])


func _make_cube() -> HoverCube:
	return LeggedCube.new()


func _knobs() -> HoverCubeSettings:
	return LeggedCubeSettings.shared
