class_name MonoText
extends Control

## UN TEXTO CON LA LETRA DE TRAZOS (ver Mono), como un Label: mide lo que escribe. Con `wrap_width`, en renglones.

var words := "":
	set(value):
		words = value
		_measure()
var height := Mono.TEXT:
	set(value):
		height = value
		_measure()
var color := Mono.GREEN:
	set(value):
		color = value
		queue_redraw()
var align := HORIZONTAL_ALIGNMENT_LEFT
## Si no es 0, el ancho donde se parte en renglones.
var wrap_width := 0.0:
	set(value):
		wrap_width = value
		_measure()
## Tramado (lo que no se puede): se dibuja y después se le pasa una trama negra encima.
var dimmed := false:
	set(value):
		dimmed = value
		queue_redraw()

var _lines := PackedStringArray()


static func make(p_words: String, p_height := Mono.TEXT, p_color := Mono.GREEN) -> MonoText:
	var made := MonoText.new()
	made.height = p_height
	made.color = p_color
	made.words = p_words
	return made


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Mono.prepare(self)


func _measure() -> void:
	_lines = Mono.wrap(words, wrap_width, height) if wrap_width > 0.0 else PackedStringArray([words])
	var widest := 0.0
	for line in _lines:
		widest = maxf(widest, Mono.measure(line, height))
	custom_minimum_size = Vector2(maxf(widest, wrap_width), _lines.size() * height * 1.7 - height * 0.7 + 2.0)
	queue_redraw()


func _draw() -> void:
	for i in _lines.size():
		var x := 0.0
		if align == HORIZONTAL_ALIGNMENT_CENTER:
			x = size.x * 0.5
		elif align == HORIZONTAL_ALIGNMENT_RIGHT:
			x = size.x
		Mono.text(self, Vector2(x, i * height * 1.7 + 1.0), _lines[i], height, color, align)
	if dimmed:
		Mono.dots(self, Rect2(Vector2.ZERO, size), 0.75, Mono.BLACK)
