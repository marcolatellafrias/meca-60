class_name MechDrawing
extends Control

## EL DIBUJO SIMPLE DE LA MECA, debajo de los huecos de la armería (ver ArmoryScreen): vista de atrás, en grises. Las
## medidas van con ArmoryScreen.SLOT_AT y ArmoryScreen.DRAWING_SIZE.

const BODY := Color(0.32, 0.34, 0.37)
const EDGE := Color(0.5, 0.52, 0.55)


func _draw() -> void:
	# las piernas
	_part(Rect2(122, 230, 56, 200))
	_part(Rect2(242, 230, 56, 200))
	_part(Rect2(108, 410, 84, 24))
	_part(Rect2(228, 410, 84, 24))
	# la cadera y la caja
	_part(Rect2(118, 210, 184, 40))
	_part(Rect2(140, 70, 140, 150))
	# los hombros y los brazos
	_part(Rect2(96, 80, 46, 40))
	_part(Rect2(278, 80, 46, 40))
	_part(Rect2(40, 90, 52, 200))
	_part(Rect2(328, 90, 52, 200))
	draw_line(Vector2(92, 100), Vector2(140, 100), EDGE, 3.0)
	draw_line(Vector2(280, 100), Vector2(328, 100), EDGE, 3.0)
	# las dos armas de la espalda, sobre los hombros
	_part(Rect2(92, 14, 52, 56))
	_part(Rect2(276, 14, 52, 56))


func _part(rect: Rect2) -> void:
	draw_rect(rect, BODY)
	draw_rect(rect, EDGE, false, 2.0)
