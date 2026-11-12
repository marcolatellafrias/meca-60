class_name PendulumMechArchetype
extends PendulumCubeArchetype

## LA PARCELA DE LA MECA PÉNDULO (ver PendulumMech): la del cubo péndulo (J/K los tiros, F2 pegarle arriba) con la meca
## péndulo y sus perillas. F1 abre su panel (PendulumMechPanel). Mirándola, O la posee. DOS FILAS LA USAN, una por camino
## (`physical`): la Meca física, con brazos de músculos, y la Meca discreta, con brazos de pose. Adelante, UN CUBO
## PÉNDULO para pegarle.

## Grande: corre y salta.
const MECH_FOOTPRINT := 120.0


## A cuánto de la meca va el cubo para pegarle, adelante de ella (m, de centro a centro).
const SPARRING := 16.0

## El camino: brazos físicos, o discretos.
var physical := true


func _init(physical_arms := true) -> void:
	physical = physical_arms
	display_name = "Meca física" if physical else "Meca discreta"


func build(seed_value: int, parent: Node3D) -> Node3D:
	var root := super(seed_value, parent)
	# El cubo para pegarle: adelante de la meca (que mira a −X), mirándola.
	var target := PendulumCube.new()
	target.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5),
		Vector3(-SPARRING, PendulumCubeSettings.shared.hover_height + HoverCube.SIZE * 0.5, 0.0))
	root.add_child(target)
	return root


func max_footprint() -> Vector2:
	return Vector2(MECH_FOOTPRINT, MECH_FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"el cubo péndulo con tres pisos, puertas y brazos %s" % ("físicos: chocan y se traban" if physical
			else "discretos: atraviesan, y al conectar empujan"),
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
	var mech := PendulumMech.new()
	mech.physical_arms = physical
	return mech


func _knobs() -> HoverCubeSettings:
	return PendulumMechSettings.tuned
