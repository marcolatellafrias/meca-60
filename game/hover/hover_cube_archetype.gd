class_name HoverCubeArchetype
extends SeededArchetype

## LA PARCELA DEL CUBO FLOTANTE (ver HoverCube): el cubo flotando en el medio, para tirarle bolas (J tira, K pasa por las
## tres fuerzas, ver TestBall) y mirar cómo rebota, cómo se cae y cómo se recupera con sus propulsores. F1 abre su panel
## (HoverPanel). R lo vuelve a poner, flotando.

## Grande: el cubo rueda al caerse (el usuario: «aumentar el tamaño de la parcela de la caja»).
const FOOTPRINT := 60.0


func _init() -> void:
	display_name = "Cubo flotante"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"flota con un resorte de altura y un torque que lo endereza",
		"(el cuerpo de character-parametric antes del 13/03/2026)",
		"se cae con física y se recupera con propulsores",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Cubo flotante"
	parent.add_child(root)
	var cube := HoverCube.new()
	# Nace donde flota, mirando hacia donde uno llega (−X).
	cube.transform = Transform3D(Basis(Vector3.UP, PI * 0.5),
		Vector3(0.0, HoverCubeSettings.current.hover_height + HoverCube.SIZE * 0.5, 0.0))
	root.add_child(cube)
	return root


func parcel_options() -> Array[Dictionary]:
	return TestBall.parcel_options(self)


## LOS CUATRO TIROS DEL CUBO (lo pidió el usuario: «lento que no voltee, lento que voltee, rápido que no voltee y rápido
## que voltee»; «son demasiado lentas, y no tan secas»): lentas a `SLOW` (empujan), rápidas a `FAST` (golpean secas); las
## que no lo voltean lo llevan a la mitad de su inclinación de caerse, las que sí, bastante más allá (ver
## HoverCube.push_for_tilt).
const SLOW := 30.0
const FAST := 100.0


func ball_shots() -> Array[Dictionary]:
	return [
		TestBall.shot("lenta, no lo voltea", HoverCube.push_for_tilt(0.55, SLOW), SLOW),
		# La lenta que lo voltea, con más margen: tan pesada como el cubo, lo empuja más de lo que lo gira (medido).
		TestBall.shot("lenta, lo voltea", HoverCube.push_for_tilt(2.4, SLOW), SLOW),
		TestBall.shot("rápida, no lo voltea", HoverCube.push_for_tilt(0.55, FAST), FAST),
		TestBall.shot("rápida, lo voltea", HoverCube.push_for_tilt(1.6, FAST), FAST),
	]
