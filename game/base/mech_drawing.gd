class_name MechDrawing
extends Control

## EL DIBUJO SIMPLE DE LA MECA, debajo de los huecos de la armería (ver ArmoryScreen): vista de atrás, en el estilo
## monocromo (Mono): el cuerpo, los brazos y las piernas TRAMADOS, con su borde fino. Las medidas van con
## ArmoryScreen.SLOT_AT y ArmoryScreen.DRAWING_SIZE.

const PARTS := [
	Rect2(140, 130, 120, 150),          # la caja
	Rect2(84, 140, 50, 220), Rect2(266, 140, 50, 220),        # los brazos
	Rect2(150, 280, 42, 210), Rect2(208, 280, 42, 210),       # las piernas
]


func _init() -> void:
	Mono.prepare(self)


func _draw() -> void:
	for part: Rect2 in PARTS:
		Mono.dots(self, part, Mono.QUARTER)
		Mono.frame(self, part)
