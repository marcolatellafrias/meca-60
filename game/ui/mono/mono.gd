class_name Mono
extends RefCounted

## EL ESTILO DE LOS MENÚS (ver docs/conceptual/interfaz.md; el usuario, 18/11/2026): MONOCROMO, un solo verde sobre
## negro; la letra de trazos rectos (StrokeFont) dibujada en vector; lo que en color serían grises o degradés, TRAMAS
## DE PUNTOS (orden de Bayer), como el ASCII con sus ░ ▒ ▓; lo elegido o con el mouse encima, INVERTIDO; lo
## superpuesto, con su fondo negro, un borde doble y una sombra de puntos. Todo se dibuja desde el `_draw` de un
## CanvasItem con estas funciones (el que trama necesita `texture_repeat` prendido: ver `prepare`).

const GREEN := Color(0.078, 0.784, 0.353)
const BLACK := Color(0.016, 0.039, 0.024)
## Las densidades de trama que se usan: casi nada, un cuarto, a cuadros.
const FAINT := 0.12
const QUARTER := 0.25
const HALF := 0.5
## Los tamaños de letra (alto de una mayúscula, en píxeles): ayuda, texto, título.
const SMALL := 11.0
const TEXT := 15.0
const TITLE := 28.0
const WEIGHT := 0.12
const BAYER := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]

static var _dots := {}


## Lo que tiene que tener un CanvasItem para tramar: la trama se repite.
static func prepare(item: CanvasItem) -> void:
	item.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	item.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Una trama de `density` (0 a 1) del color dado, en una textura de 4 × 4 que se repite.
static func dots_texture(density: float, color := GREEN) -> ImageTexture:
	var key := "%.3f %s" % [density, color.to_html()]
	if _dots.has(key):
		return _dots[key]
	var image := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	for y in 4:
		for x in 4:
			image.set_pixel(x, y, color if BAYER[y][x] < density * 16.0 else Color(0, 0, 0, 0))
	var texture := ImageTexture.create_from_image(image)
	_dots[key] = texture
	return texture


static func dots(item: CanvasItem, rect: Rect2, density: float, color := GREEN) -> void:
	item.draw_texture_rect(dots_texture(density, color), rect, true)


static func frame(item: CanvasItem, rect: Rect2, width := 1.0, color := GREEN) -> void:
	item.draw_rect(rect.grow(-width * 0.5), color, false, width)


## LO SUPERPUESTO: la sombra de puntos corrida abajo a la derecha, el fondo negro y el borde doble.
static func overlay(item: CanvasItem, rect: Rect2) -> void:
	dots(item, Rect2(rect.position + Vector2(10, 10), rect.size), HALF)
	item.draw_rect(rect, BLACK)
	frame(item, rect, 2.0)
	frame(item, rect.grow(-5.0), 1.0)


## EL TEXTO con la letra de trazos: `at` es la esquina de arriba a la izquierda de una mayúscula (o el medio, o la
## derecha, según `align`). Devuelve el ancho.
static func text(item: CanvasItem, at: Vector2, words: String, height := TEXT, color := GREEN,
		align := HORIZONTAL_ALIGNMENT_LEFT) -> float:
	var width := measure(words, height)
	var x := at.x
	if align == HORIZONTAL_ALIGNMENT_CENTER:
		x -= width * 0.5
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		x -= width
	var segments := StrokeFont.segments(words, height, StrokeFont.Align.LEFT)
	if segments.is_empty():
		return width
	var points := PackedVector2Array()
	points.resize(segments.size())
	for i in segments.size():
		var p := segments[i]
		points[i] = Vector2(x + p.x, at.y + height * 0.5 - p.y)
	item.draw_multiline(points, color, maxf(1.0, height * WEIGHT))
	return width


static func measure(words: String, height := TEXT) -> float:
	return StrokeFont.measure(words, height).x


## Parte `words` en renglones que entren en `width`.
static func wrap(words: String, width: float, height := TEXT) -> PackedStringArray:
	var lines := PackedStringArray()
	var line := ""
	for word in words.split(" "):
		var tried := word if line.is_empty() else line + " " + word
		if not line.is_empty() and measure(tried, height) > width:
			lines.append(line)
			line = word
		else:
			line = tried
	if not line.is_empty():
		lines.append(line)
	return lines


## UN ÍCONO de un bit (MonoIcons), con cada píxel de `scale` de lado.
static func icon(item: CanvasItem, id: String, at: Vector2, scale := 3.0, color := GREEN) -> void:
	var rows: Array = MonoIcons.ICONS.get(id, [])
	for j in rows.size():
		var row: String = rows[j]
		for i in row.length():
			if row[i] == "#":
				item.draw_rect(Rect2(at + Vector2(i, j) * scale, Vector2(scale, scale)), color)


## LA CRUZ DE CERRAR, en un cuadrado de `rect`.
static func cross(item: CanvasItem, rect: Rect2, color := GREEN) -> void:
	var inner := rect.grow(-8.0)
	item.draw_line(inner.position, inner.end, color, 3.0)
	item.draw_line(Vector2(inner.end.x, inner.position.y), Vector2(inner.position.x, inner.end.y), color, 3.0)
