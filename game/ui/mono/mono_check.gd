class_name MonoCheck
extends Control

## UNA CASILLA PARA TILDAR DEL ESTILO MONOCROMO (ver Mono): el cuadrado con borde, lleno por dentro si está prendida, y
## su texto. Avisa con `toggled`.

signal toggled(on: bool)

var words := ""
var on := false:
	set(v):
		on = v
		queue_redraw()


static func make(p_words: String, p_on: bool) -> MonoCheck:
	var made := MonoCheck.new()
	made.words = p_words
	made.on = p_on
	made.custom_minimum_size = Vector2(Mono.measure(p_words) + 50, 30)
	return made


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var box := Rect2(0, 2, 26, 26)
	Mono.frame(self, box, 2.0)
	if on:
		draw_rect(box.grow(-6.0), Mono.GREEN)
	Mono.text(self, Vector2(42, 8), words)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		on = not on
		toggled.emit(on)
