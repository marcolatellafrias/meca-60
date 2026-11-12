class_name PendulumMechArchetype
extends PendulumCubeArchetype

## LA PARCELA DE LA MECA PÉNDULO (ver PendulumMech): la del cubo péndulo (J/K los tiros, F2 pegarle arriba) con la meca
## péndulo y sus perillas. F1 abre su panel (PendulumMechPanel). Mirándola, O la posee.

## Grande: corre y salta.
const MECH_FOOTPRINT := 120.0


func _init() -> void:
	display_name = "Meca péndulo"


func max_footprint() -> Vector2:
	return Vector2(MECH_FOOTPRINT, MECH_FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"el cubo péndulo con tres pisos, puertas y brazos",
		"mirándola, O la posee (T cambia la vista) · U subirse (adentro se camina)",
		"Shift corre · Ctrl se agacha",
		"espacio: mantener carga el salto, soltar salta; en el aire, propulsor",
	])


func parcel_options() -> Array[Dictionary]:
	var options := super()
	options.append({"key": KEY_U, "label": "subirse a la meca (al piso del medio)",
		"apply": func(parcel: SandboxParcel) -> void:
			for mech: PendulumMech in parcel.find_children("*", "PendulumMech", true, false):
				mech.board()})
	return options


func _make_cube() -> HoverCube:
	return PendulumMech.new()


func _knobs() -> HoverCubeSettings:
	return PendulumMechSettings.tuned
