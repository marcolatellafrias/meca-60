class_name MonoField
extends Control

## UN CAMPO PARA ESCRIBIR DEL ESTILO MONOCROMO (ver Mono): un LineEdit invisible que recibe las teclas y, encima, lo
## escrito con la letra de trazos, grande, y un cursor lleno. Avisa con `submitted`.

signal submitted(words: String)

var edit: LineEdit
var placeholder := ""


func _init() -> void:
	custom_minimum_size = Vector2(320, 60)
	edit = LineEdit.new()
	edit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	edit.flat = true
	edit.add_theme_color_override("font_color", Color(0, 0, 0, 0))
	edit.add_theme_color_override("caret_color", Color(0, 0, 0, 0))
	edit.add_theme_color_override("selection_color", Color(0, 0, 0, 0))
	edit.add_theme_color_override("font_placeholder_color", Color(0, 0, 0, 0))
	edit.text_changed.connect(func(_t: String) -> void: queue_redraw())
	edit.text_submitted.connect(func(t: String) -> void: submitted.emit(t))
	add_child(edit)


func text() -> String:
	return edit.text


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	Mono.frame(self, rect, 2.0)
	var height := size.y * 0.45
	var shown := edit.text.to_upper()
	var top := (size.y - height) * 0.5
	if shown.is_empty():
		Mono.text(self, Vector2(18, top), placeholder, height, Mono.GREEN)
		Mono.dots(self, rect.grow(-3.0), 0.75, Mono.BLACK)
		return
	var width := Mono.text(self, Vector2(18, top), shown, height)
	draw_rect(Rect2(18 + width + 8, top, height * 0.6, height), Mono.GREEN)
