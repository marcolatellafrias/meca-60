class_name PendulumCubeArchetype
extends HoverCubeArchetype

## LA PARCELA DEL CUBO PÉNDULO (ver PendulumCube): la del cubo (J/K los cuatro tiros, F2 pegarle arriba, O manejarlo)
## con el cubo péndulo y sus perillas. F1 abre su panel (PendulumCubePanel). Sus tiros van por el golpe (m/s que le
## cambiaría la velocidad suelto), MEDIDOS (ver tests/pendulum_check).

const SMALL := 5.0
const BIG := 14.0


func _init() -> void:
	display_name = "Cubo péndulo"


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"el torso es un péndulo sobre su apoyo en el piso; los pies lo siguen",
		"una piña lo saca de arriba de los pies: se inclina y, si no lo alcanzan, cae",
		"una pared lo frena y los pies se plantan: no cae, a ninguna velocidad",
		"O manejarlo: W/S y A/D, el mouse gira el torso",
	])


func _make_cube() -> HoverCube:
	return PendulumCube.new()


func _knobs() -> HoverCubeSettings:
	return PendulumCubeSettings.shared


func ball_shots() -> Array[Dictionary]:
	return [
		TestBall.shot("lenta, no lo voltea", TestBall.push_for(HoverCube.CUBE_MASS, SMALL, SLOW), SLOW),
		TestBall.shot("lenta, lo voltea", TestBall.push_for(HoverCube.CUBE_MASS, BIG, SLOW), SLOW),
		TestBall.shot("rápida, no lo voltea", TestBall.push_for(HoverCube.CUBE_MASS, SMALL, FAST), FAST),
		TestBall.shot("rápida, lo voltea", TestBall.push_for(HoverCube.CUBE_MASS, BIG, FAST), FAST),
	]
