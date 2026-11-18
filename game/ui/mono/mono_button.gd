class_name MonoButton
extends Control

## UN BOTÓN DEL ESTILO MONOCROMO (ver Mono): un recuadro con su texto; la acción principal, LLENA (invertida); con el
## mouse encima se invierte; el que no se puede, tramado. Avisa con `pressed`.

signal pressed()

var words := "":
	set(value):
		words = value
		queue_redraw()
var primary := false:
	set(value):
		primary = value
		queue_redraw()
var disabled := false:
	set(value):
		disabled = value
		queue_redraw()
## La cruz de cerrar en vez de un texto.
var is_close := false

var _hover := false


static func make(p_words: String, p_size := Vector2(200, 46), p_primary := false) -> MonoButton:
	var made := MonoButton.new()
	made.words = p_words
	made.primary = p_primary
	made.custom_minimum_size = p_size
	return made


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	Mono.prepare(self)
	mouse_entered.connect(func() -> void: _hover = true; queue_redraw())
	mouse_exited.connect(func() -> void: _hover = false; queue_redraw())


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	var full := (primary or _hover) and not disabled
	if full:
		draw_rect(rect, Mono.GREEN)
	else:
		Mono.frame(self, rect, 2.0 if is_close else 1.0)
	var ink := Mono.BLACK if full else Mono.GREEN
	if is_close:
		Mono.cross(self, rect, ink)
	else:
		Mono.text(self, Vector2(size.x * 0.5, (size.y - Mono.TEXT) * 0.5), words, Mono.TEXT, ink,
			HORIZONTAL_ALIGNMENT_CENTER)
	if disabled:
		Mono.dots(self, rect, 0.75, Mono.BLACK)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT and click.pressed and not disabled:
		accept_event()
		pressed.emit()
