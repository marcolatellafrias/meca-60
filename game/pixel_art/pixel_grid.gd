class_name PixelGrid
extends Control

## LA CARA APLANADA Y GRANDE del panel de pintar (PixelPaintPanel): su grilla de píxeles, como un editor de pixel art.
## Clic izquierdo (y arrastrar) pinta con `brush`; clic derecho toma el color del píxel; con `erasing` vuelve al color
## del material. Los píxeles que la cara no toca (una cara que no es un rectángulo) van rayados. Cada trazo se guarda al
## soltar y se puede deshacer.

signal painted

const SIDE := 520.0
const MAX_CELL := 40.0

var brush := Color(0.09, 0.085, 0.08)
var erasing := false
var _model: PixelModel = null
var _face: PixelFace = null
var _cell := 8.0
var _stroke: Dictionary = {}
var _undo: Array[Dictionary] = []


func edit(model: PixelModel, face: PixelFace) -> void:
	_model = model
	_face = face
	_undo.clear()
	if face != null:
		_cell = minf(MAX_CELL, floorf(minf(SIDE / face.width, SIDE / face.height)))
		custom_minimum_size = Vector2(face.width, face.height) * _cell
	else:
		custom_minimum_size = Vector2(SIDE, 60)
	queue_redraw()


func fill() -> void:
	if _face == null:
		return
	_stroke = {}
	for y in _face.height:
		for x in _face.width:
			_put(x, y)
	_finish()


func undo() -> void:
	if _undo.is_empty() or _face == null:
		return
	var last: Dictionary = _undo.pop_back()
	for spot: Vector2i in last:
		var before: Variant = last[spot]
		_model.paint(_face, spot.x, spot.y, before if before != null else Color.BLACK, before == null)
	_model.refresh()
	_model.save()
	queue_redraw()
	painted.emit()


func _draw() -> void:
	if _face == null:
		draw_string(get_theme_default_font(), Vector2(8, 30), "(ninguna cara elegida)")
		return
	for y in _face.height:
		for x in _face.width:
			var square := Rect2(Vector2(x, y) * _cell, Vector2.ONE * _cell)
			if _face.inside(x, y):
				draw_rect(square, _model.color_at(_face, x, y))
			else:
				draw_rect(square, Color(0.15, 0.15, 0.15))
				draw_line(square.position, square.end, Color(0.3, 0.3, 0.3))
	if _cell >= 6.0:
		var line := Color(0, 0, 0, 0.25)
		for x in _face.width + 1:
			draw_line(Vector2(x * _cell, 0), Vector2(x * _cell, _face.height * _cell), line)
		for y in _face.height + 1:
			draw_line(Vector2(0, y * _cell), Vector2(_face.width * _cell, y * _cell), line)


func _gui_input(event: InputEvent) -> void:
	if _face == null:
		return
	var button := event as InputEventMouseButton
	if button != null:
		var spot := Vector2i((button.position / _cell).floor())
		if button.button_index == MOUSE_BUTTON_RIGHT and button.pressed and _face.inside(spot.x, spot.y):
			brush = _model.color_at(_face, spot.x, spot.y)
			erasing = false
		elif button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
			_stroke = {}
			_put(spot.x, spot.y)
			_model.refresh()
		elif button.button_index == MOUSE_BUTTON_LEFT and not button.pressed:
			_finish()
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		var spot := Vector2i((motion.position / _cell).floor())
		_put(spot.x, spot.y)
		_model.refresh()
		accept_event()


## Pinta un píxel del trazo, anotando cómo estaba (para deshacer).
func _put(x: int, y: int) -> void:
	if not _face.inside(x, y):
		return
	var spot := Vector2i(x, y)
	if not _stroke.has(spot):
		var key := _model.anchor(_face, x, y)
		_stroke[spot] = _model.painted[key] if _model.painted.has(key) else null
	_model.paint(_face, x, y, brush, erasing)
	queue_redraw()


func _finish() -> void:
	if _stroke.is_empty():
		return
	_undo.append(_stroke)
	_stroke = {}
	_model.refresh()
	_model.save()
	queue_redraw()
	painted.emit()
