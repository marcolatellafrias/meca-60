class_name ModulesMaquetteArchetype
extends SeededArchetype

## LA MECA POR MÓDULOS en su parcela (ver ModulesMaquette): quieta, a escala real, para recorrerla por dentro.


func _init() -> void:
	display_name = "Meca por módulos"


func max_footprint() -> Vector2:
	return ModulesMaquette.footprint()


func far_height() -> float:
	return 12.0


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"naranja: artillería (dos sillas) · gris: vestíbulo · verde: brazos · amarillo: munición",
		"azul: la cabeza (cerrada) · violeta: el succionador, continuo con el vestíbulo",
		"maqueta quieta: se entra volando (modo creativo)",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	return ModulesMaquette.build(parent)
