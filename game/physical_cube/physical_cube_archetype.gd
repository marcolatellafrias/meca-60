class_name PhysicalCubeArchetype
extends HoverCubeArchetype

## LA PARCELA DEL CUBO FÍSICO (ver PhysicalCube): la del cubo (J/K los cuatro tiros, F2 empujarlo arriba, O manejarlo)
## con el cubo físico y sus perillas. F1 abre su panel (PhysicalCubePanel). Sus tiros van por cambio de velocidad
## medido, no por la línea (no tiene).

## Los cambios de velocidad de los tiros que no lo voltean y que sí (m/s, en el centro): MEDIDOS (ver
## tests/physical_check).
const SMALL := 1.0
const BIG := 5.0


func _init() -> void:
	display_name = "Cubo físico"


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"sin línea: gira de costado y de frente con la física, en Y no",
		"flota sobre cuatro resortes y los pies agarran el piso: un golpe arriba lo vuelca",
		"pasada cierta inclinación cae, y se recupera con propulsores",
	])


func _make_cube() -> HoverCube:
	return PhysicalCube.new()


func _knobs() -> HoverCubeSettings:
	return PhysicalCubeSettings.shared


func ball_shots() -> Array[Dictionary]:
	return [
		TestBall.shot("lenta, no lo voltea", TestBall.push_for(HoverCube.CUBE_MASS, SMALL, SLOW), SLOW),
		TestBall.shot("lenta, lo voltea", TestBall.push_for(HoverCube.CUBE_MASS, BIG, SLOW), SLOW),
		TestBall.shot("rápida, no lo voltea", TestBall.push_for(HoverCube.CUBE_MASS, SMALL, FAST), FAST),
		TestBall.shot("rápida, lo voltea", TestBall.push_for(HoverCube.CUBE_MASS, BIG, FAST), FAST),
	]
