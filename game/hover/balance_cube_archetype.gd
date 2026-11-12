class_name BalanceCubeArchetype
extends SeededArchetype

## LA PARCELA DEL CUBO CON EQUILIBRIO (ver BalanceCube): el cubo en el medio, para tirarle bolas (J tira, K pasa por los
## cuatro tiros: lenta o rápida, que lo voltea o no) y volcarlo con el panel chico (F2). F1 abre su panel
## (BalanceCubePanel). R lo vuelve a poner, flotando.

const FOOTPRINT := 60.0
const SLOW := 30.0
const FAST := 100.0
## Lo que la bola le deja de su empuje (rebota y sigue un poco): MEDIDO (ver tests/hover_check).
const TRANSFER := {30.0: 0.9, 100.0: 0.9}


func _init() -> void:
	display_name = "Cubo con equilibrio"


func max_footprint() -> Vector2:
	return Vector2(FOOTPRINT, FOOTPRINT)


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"el golpe lo corre y aparte lo inclina (la línea de equilibrio)",
		"al pasarla tropieza para el lado del golpe y cae con física",
		"se recupera con propulsores, como el cubo flotante",
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Cubo con equilibrio"
	parent.add_child(root)
	var cube := BalanceCube.new()
	# Nace donde flota, mirando hacia donde uno llega (−X).
	cube.transform = Transform3D(Basis(Vector3.UP, PI * 0.5),
		Vector3(0.0, BalanceCube.hover_knobs.hover_height + HoverCube.SIZE * 0.5, 0.0))
	root.add_child(cube)
	return root


func parcel_options() -> Array[Dictionary]:
	return TestBall.parcel_options(self)


## LOS CUATRO TIROS: los que no lo voltean lo llevan a la mitad de donde se cae, los que sí, bastante más allá.
func ball_shots() -> Array[Dictionary]:
	var fall := BalanceCubeSettings.current.fall_at
	return [
		TestBall.shot("lenta, no lo voltea", _push(fall * 0.55, SLOW), SLOW),
		TestBall.shot("lenta, lo voltea", _push(fall * 1.5, SLOW), SLOW),
		TestBall.shot("rápida, no lo voltea", _push(fall * 0.55, FAST), FAST),
		TestBall.shot("rápida, lo voltea", _push(fall * 1.5, FAST), FAST),
	]


func _push(lean_wanted: float, speed: float) -> float:
	var transfer := float(TRANSFER[speed]) if TRANSFER.has(speed) else 0.9
	return TestBall.push_for(HoverCube.CUBE_MASS, BalanceCube.delta_v_for_lean(lean_wanted) / transfer, speed)
