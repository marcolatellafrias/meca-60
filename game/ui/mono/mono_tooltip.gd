class_name MonoTooltip
extends Control

## EL CARTEL DEL MOUSE DEL ESTILO MONOCROMO (ver Mono): superpuesto (fondo negro, borde doble, sombra de puntos), con
## renglones de texto. Lo devuelve `_make_custom_tooltip` de quien lo muestra; el panel gris de Godot lo saca el tema
## (TerminalScreen).

const PAD := 18.0
const WIDTH := 340.0

## Renglones: [texto, alto]. Los largos se parten.
var _lines: Array = []


static func make(lines: Array) -> MonoTooltip:
	var made := MonoTooltip.new()
	for line: Array in lines:
		for piece in Mono.wrap(str(line[0]), WIDTH - PAD * 2.0, float(line[1])):
			made._lines.append([piece, float(line[1])])
	var tall := PAD * 2.0
	for line: Array in made._lines:
		tall += float(line[1]) * 1.8
	made.custom_minimum_size = Vector2(WIDTH + 10.0, tall + 10.0)
	return made


func _init() -> void:
	Mono.prepare(self)


func _draw() -> void:
	Mono.overlay(self, Rect2(Vector2.ZERO, custom_minimum_size - Vector2(10, 10)))
	var y := PAD
	for line: Array in _lines:
		Mono.text(self, Vector2(PAD, y), line[0], line[1])
		y += float(line[1]) * 1.8
