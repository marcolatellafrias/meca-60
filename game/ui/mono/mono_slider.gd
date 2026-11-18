class_name MonoSlider
extends Control

## UN DESLIZADOR DEL ESTILO MONOCROMO (ver Mono): la barra con borde fino, lo lleno tramado y la manija llena. Se
## arrastra o se hace clic donde se quiere. Avisa con `value_changed`.

signal value_changed(value: float)

var min_value := 0.0
var max_value := 1.0
var value := 0.0:
	set(v):
		value = clampf(v, min_value, max_value)
		queue_redraw()

var _dragging := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(300, 30)
	Mono.prepare(self)


func _draw() -> void:
	var track := Rect2(0, size.y * 0.5 - 9, size.x, 18)
	var share := 0.0 if is_equal_approx(max_value, min_value) else (value - min_value) / (max_value - min_value)
	Mono.dots(self, Rect2(track.position + Vector2(2, 2), Vector2((track.size.x - 4) * share, track.size.y - 4)), Mono.HALF)
	Mono.frame(self, track)
	var x := track.size.x * share
	draw_rect(Rect2(x - 6, 0, 12, size.y), Mono.GREEN)


func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.button_index == MOUSE_BUTTON_LEFT:
		_dragging = click.pressed
		if click.pressed:
			_set_from(click.position.x)
		accept_event()
	var motion := event as InputEventMouseMotion
	if motion and _dragging:
		_set_from(motion.position.x)
		accept_event()


func _set_from(x: float) -> void:
	value = lerpf(min_value, max_value, clampf(x / size.x, 0.0, 1.0))
	value_changed.emit(value)
