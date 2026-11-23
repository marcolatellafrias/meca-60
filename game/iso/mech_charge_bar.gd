class_name MechChargeBar
extends Control

## LA BARRITA DE CARGA DE UN BRAZO, POR SEGMENTOS (22/11/2026; el usuario: «que no sean líneas continuas si no segmentos»):
## cada tramo es un golpe. Se llena de a poco en blanco y, completo, queda azul: soltando ahí sale ese golpe.

const GAP := 2.0
const BACK := Color(0.0, 0.0, 0.0, 0.55)
const FILLING := Color.WHITE
const READY := Color(0.25, 0.7, 1.0)

## Dónde termina cada segmento (partes de la barra, en orden, el último 1). Vacío: no se dibuja.
var marks := PackedFloat32Array()
var share := 0.0


func show_charge(fresh_marks: PackedFloat32Array, value: float) -> void:
	if fresh_marks == marks and is_equal_approx(value, share):
		return
	marks = fresh_marks
	share = value
	queue_redraw()


func _draw() -> void:
	var start := 0.0
	for end in marks:
		var left := size.x * start + (GAP * 0.5 if start > 0.0 else 0.0)
		var right := size.x * end - (GAP * 0.5 if end < 1.0 else 0.0)
		draw_rect(Rect2(left, 0.0, right - left, size.y), BACK)
		var part := clampf((share - start) / maxf(end - start, 0.001), 0.0, 1.0)
		if part > 0.0:
			draw_rect(Rect2(left, 0.0, (right - left) * part, size.y), READY if part >= 1.0 else FILLING)
		start = end
