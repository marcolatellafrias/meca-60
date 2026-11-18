class_name MonoWindow
extends Control

## UNA VENTANA SUPERPUESTA DEL ESTILO MONOCROMO (ver Mono): atenúa todo lo de atrás con una trama negra (no se puede
## tocar) y, en el medio, el recuadro superpuesto (fondo negro, borde doble, sombra de puntos) con su contenido en
## `content`, una columna. La usan la pausa, las opciones y «unirse con código».

const PAD := 30.0

var content: VBoxContainer
var _box: Control


func _init() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	Mono.prepare(self)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_box = _Box.new()
	center.add_child(_box)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, int(PAD))
	margin.add_theme_constant_override("margin_right", int(PAD) + 10)
	margin.add_theme_constant_override("margin_bottom", int(PAD) + 10)
	_box.add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margin.add_child(content)
	margin.resized.connect(func() -> void: _box.custom_minimum_size = margin.size)


func _draw() -> void:
	Mono.dots(self, Rect2(Vector2.ZERO, size), 0.75, Mono.BLACK)


## El recuadro: lo superpuesto, dejando lugar abajo a la derecha para la sombra.
class _Box extends Control:
	func _init() -> void:
		Mono.prepare(self)

	func _draw() -> void:
		Mono.overlay(self, Rect2(Vector2.ZERO, size - Vector2(10, 10)))
