class_name BossMaquetteArchetype
extends SeededArchetype

## UNA MAQUETA DE JEFE en su parcela (ver BossMaquettes): sus dos estados, quietos, para mirar caminando alrededor.

var index := 0


func _init(which: int) -> void:
	index = which
	display_name = str(BossMaquettes.entry(which)["name"])


func max_footprint() -> Vector2:
	return Vector2(BossMaquettes.APART * 2.0 + 90.0, 130.0)


func far_height() -> float:
	return 50.0


func describe(_seed_value: int) -> PackedStringArray:
	var lines := PackedStringArray(BossMaquettes.entry(index)["lines"])
	lines.append("izquierda: %s · derecha: %s" % BossMaquettes.entry(index)["states"])
	lines.append("naranja que brilla: punto débil · rojo en el piso: ataque de área · bloque rojo: la meca (18 m)")
	return lines


func build(_seed_value: int, parent: Node3D) -> Node3D:
	return BossMaquettes.build(index, parent)
