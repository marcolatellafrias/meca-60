class_name StrokeFont
extends RefCounted

## ── LA LETRA DIEGÉTICA DEL JUEGO ─────────────────────────────────────────────────────────────────
## TODO LO QUE ESTÁ ESCRITO EN EL MUNDO —el carácter de una tecla, los números de un nixie, la palabra de una
## placa, el rótulo grabado en un tablero— SE ESCRIBE CON ESTO. No con Label3D: un Label3D es un cartel que flota
## de cara a la cámara, que está bien para depurar y para subtítulos, pero no es algo que esté ahí. Esto sí: cada
## letra es geometría de verdad, iluminada como el resto, que se puede hundir, extruir o hacer brillar.
##
## Es una FUENTE DE TRAZOS: cada carácter son unas pocas líneas rectas en una grilla de 4 de ancho por 6 de alto
## (la altura de una mayúscula), con las curvas resueltas en chaflanes. Pocas líneas y ninguna curva, así que se
## lleva a 3D con muy pocos triángulos —dos por trazo si es plana, doce si tiene espesor— y se lee igual de lejos
## que de cerca. Es una sola letra para todo el juego a propósito: un mundo de 1910 con una sola tipografía de
## chapa estampada se ve coherente, y hay una sola cosa que mantener.
##
## Hay mayúsculas, números, las vocales acentuadas y la Ñ, y los signos de uso común. Las MINÚSCULAS SE ESCRIBEN
## COMO VERSALITAS —la mayúscula más chica—, que es lo que se veía en las chapas de la época. Un carácter que no
## está se deja en blanco.
##
## Quien dibuja: `mesh` (un texto entero, en metros, centrado o alineado) o `polyline_mesh` (trazos sueltos, para
## lo que no es texto pero se dibuja igual: el filamento de una lamparita). Las mallas se guardan: el mismo texto
## con las mismas medidas es la misma malla, se pida cuantas veces se pida. El nodo de todos los días es
## StrokeLabel.

## La grilla: el alto de una mayúscula, y cuánto avanza cada carácter (su ancho, 4, y el aire hasta el próximo).
const CAP := 6.0
const ADVANCE := 5.6
## Las versalitas, en fracción de una mayúscula.
const SMALL_CAPS := 0.75

enum Align { LEFT, CENTER, RIGHT }

## Los caracteres, cada uno una lista de trazos y cada trazo una lista de puntos de la grilla (x de 0 a 4, y de 0 a
## 6 desde la línea de base). Las curvas son chaflanes de una unidad.
const GLYPHS := {
	"0": [[Vector2(1, 0), Vector2(3, 0), Vector2(4, 1), Vector2(4, 5), Vector2(3, 6), Vector2(1, 6), Vector2(0, 5), Vector2(0, 1), Vector2(1, 0)], [Vector2(1, 1.5), Vector2(3, 4.5)]],
	"1": [[Vector2(1, 5), Vector2(2, 6), Vector2(2, 0)], [Vector2(1, 0), Vector2(3, 0)]],
	"2": [[Vector2(0, 5), Vector2(1, 6), Vector2(3, 6), Vector2(4, 5), Vector2(4, 4), Vector2(0, 0), Vector2(4, 0)]],
	"3": [[Vector2(0, 5), Vector2(1, 6), Vector2(3, 6), Vector2(4, 5), Vector2(4, 4), Vector2(3, 3), Vector2(1, 3)], [Vector2(3, 3), Vector2(4, 2), Vector2(4, 1), Vector2(3, 0), Vector2(1, 0), Vector2(0, 1)]],
	"4": [[Vector2(3, 0), Vector2(3, 6), Vector2(0, 2), Vector2(4, 2)]],
	"5": [[Vector2(4, 6), Vector2(0, 6), Vector2(0, 3), Vector2(3, 3), Vector2(4, 2), Vector2(4, 1), Vector2(3, 0), Vector2(0, 0)]],
	"6": [[Vector2(3, 6), Vector2(1, 6), Vector2(0, 5), Vector2(0, 1), Vector2(1, 0), Vector2(3, 0), Vector2(4, 1), Vector2(4, 2), Vector2(3, 3), Vector2(0, 3)]],
	"7": [[Vector2(0, 6), Vector2(4, 6), Vector2(1, 0)]],
	"8": [[Vector2(1, 3), Vector2(0, 4), Vector2(0, 5), Vector2(1, 6), Vector2(3, 6), Vector2(4, 5), Vector2(4, 4), Vector2(3, 3), Vector2(1, 3), Vector2(0, 2), Vector2(0, 1), Vector2(1, 0), Vector2(3, 0), Vector2(4, 1), Vector2(4, 2), Vector2(3, 3)]],
	"9": [[Vector2(4, 3), Vector2(1, 3), Vector2(0, 4), Vector2(0, 5), Vector2(1, 6), Vector2(3, 6), Vector2(4, 5), Vector2(4, 1), Vector2(3, 0), Vector2(1, 0)]],
	"A": [[Vector2(0, 0), Vector2(0, 4), Vector2(2, 6), Vector2(4, 4), Vector2(4, 0)], [Vector2(0, 2), Vector2(4, 2)]],
	"B": [[Vector2(0, 0), Vector2(0, 6), Vector2(3, 6), Vector2(4, 5), Vector2(4, 4), Vector2(3, 3), Vector2(0, 3)], [Vector2(3, 3), Vector2(4, 2), Vector2(4, 1), Vector2(3, 0), Vector2(0, 0)]],
	"C": [[Vector2(4, 5), Vector2(3, 6), Vector2(1, 6), Vector2(0, 5), Vector2(0, 1), Vector2(1, 0), Vector2(3, 0), Vector2(4, 1)]],
	"D": [[Vector2(0, 0), Vector2(0, 6), Vector2(2, 6), Vector2(4, 4), Vector2(4, 2), Vector2(2, 0), Vector2(0, 0)]],
	"E": [[Vector2(4, 6), Vector2(0, 6), Vector2(0, 0), Vector2(4, 0)], [Vector2(0, 3), Vector2(3, 3)]],
	"F": [[Vector2(4, 6), Vector2(0, 6), Vector2(0, 0)], [Vector2(0, 3), Vector2(3, 3)]],
	"G": [[Vector2(4, 5), Vector2(3, 6), Vector2(1, 6), Vector2(0, 5), Vector2(0, 1), Vector2(1, 0), Vector2(3, 0), Vector2(4, 1), Vector2(4, 3), Vector2(2, 3)]],
	"H": [[Vector2(0, 0), Vector2(0, 6)], [Vector2(4, 0), Vector2(4, 6)], [Vector2(0, 3), Vector2(4, 3)]],
	"I": [[Vector2(1, 6), Vector2(3, 6)], [Vector2(2, 6), Vector2(2, 0)], [Vector2(1, 0), Vector2(3, 0)]],
	"J": [[Vector2(4, 6), Vector2(4, 1), Vector2(3, 0), Vector2(1, 0), Vector2(0, 1)]],
	"K": [[Vector2(0, 0), Vector2(0, 6)], [Vector2(4, 6), Vector2(0, 2)], [Vector2(1.3, 3.3), Vector2(4, 0)]],
	"L": [[Vector2(0, 6), Vector2(0, 0), Vector2(4, 0)]],
	"M": [[Vector2(0, 0), Vector2(0, 6), Vector2(2, 3), Vector2(4, 6), Vector2(4, 0)]],
	"N": [[Vector2(0, 0), Vector2(0, 6), Vector2(4, 0), Vector2(4, 6)]],
	"O": [[Vector2(1, 0), Vector2(3, 0), Vector2(4, 1), Vector2(4, 5), Vector2(3, 6), Vector2(1, 6), Vector2(0, 5), Vector2(0, 1), Vector2(1, 0)]],
	"P": [[Vector2(0, 0), Vector2(0, 6), Vector2(3, 6), Vector2(4, 5), Vector2(4, 4), Vector2(3, 3), Vector2(0, 3)]],
	"Q": [[Vector2(1, 0), Vector2(3, 0), Vector2(4, 1), Vector2(4, 5), Vector2(3, 6), Vector2(1, 6), Vector2(0, 5), Vector2(0, 1), Vector2(1, 0)], [Vector2(2.5, 1.5), Vector2(4, 0)]],
	"R": [[Vector2(0, 0), Vector2(0, 6), Vector2(3, 6), Vector2(4, 5), Vector2(4, 4), Vector2(3, 3), Vector2(0, 3)], [Vector2(2, 3), Vector2(4, 0)]],
	"S": [[Vector2(4, 5), Vector2(3, 6), Vector2(1, 6), Vector2(0, 5), Vector2(0, 4), Vector2(1, 3), Vector2(3, 3), Vector2(4, 2), Vector2(4, 1), Vector2(3, 0), Vector2(1, 0), Vector2(0, 1)]],
	"T": [[Vector2(0, 6), Vector2(4, 6)], [Vector2(2, 6), Vector2(2, 0)]],
	"U": [[Vector2(0, 6), Vector2(0, 1), Vector2(1, 0), Vector2(3, 0), Vector2(4, 1), Vector2(4, 6)]],
	"V": [[Vector2(0, 6), Vector2(2, 0), Vector2(4, 6)]],
	"W": [[Vector2(0, 6), Vector2(1, 0), Vector2(2, 3), Vector2(3, 0), Vector2(4, 6)]],
	"X": [[Vector2(0, 6), Vector2(4, 0)], [Vector2(4, 6), Vector2(0, 0)]],
	"Y": [[Vector2(0, 6), Vector2(2, 3), Vector2(4, 6)], [Vector2(2, 3), Vector2(2, 0)]],
	"Z": [[Vector2(0, 6), Vector2(4, 6), Vector2(0, 0), Vector2(4, 0)]],
	"-": [[Vector2(1, 3), Vector2(3, 3)]],
	"—": [[Vector2(0, 3), Vector2(4, 3)]],
	"+": [[Vector2(0, 3), Vector2(4, 3)], [Vector2(2, 1), Vector2(2, 5)]],
	"*": [[Vector2(2, 1), Vector2(2, 5)], [Vector2(0.5, 2), Vector2(3.5, 4)], [Vector2(0.5, 4), Vector2(3.5, 2)]],
	"#": [[Vector2(1.3, 0.5), Vector2(1.3, 5.5)], [Vector2(2.7, 0.5), Vector2(2.7, 5.5)], [Vector2(0, 2), Vector2(4, 2)], [Vector2(0, 4), Vector2(4, 4)]],
	"/": [[Vector2(0, 0), Vector2(4, 6)]],
	"=": [[Vector2(0, 2), Vector2(4, 2)], [Vector2(0, 4), Vector2(4, 4)]],
	"<": [[Vector2(4, 5), Vector2(0, 3), Vector2(4, 1)]],
	">": [[Vector2(0, 5), Vector2(4, 3), Vector2(0, 1)]],
	"(": [[Vector2(3, 6), Vector2(1.5, 4.5), Vector2(1.5, 1.5), Vector2(3, 0)]],
	")": [[Vector2(1, 6), Vector2(2.5, 4.5), Vector2(2.5, 1.5), Vector2(1, 0)]],
	".": [[Vector2(2, 0), Vector2(2, 0.6)]],
	"·": [[Vector2(2, 2.7), Vector2(2, 3.3)]],
	"&": [[Vector2(4, 0), Vector2(1, 4), Vector2(1, 5), Vector2(2, 6), Vector2(3, 5), Vector2(3, 4), Vector2(0, 2),
		Vector2(0, 1), Vector2(1, 0), Vector2(2, 0), Vector2(4, 2)]],
	",": [[Vector2(2, 0.6), Vector2(1.5, -1)]],
	":": [[Vector2(2, 1), Vector2(2, 1.6)], [Vector2(2, 4), Vector2(2, 4.6)]],
	"!": [[Vector2(2, 6), Vector2(2, 2)], [Vector2(2, 0), Vector2(2, 0.6)]],
	"¡": [[Vector2(2, 0), Vector2(2, 4)], [Vector2(2, 5.4), Vector2(2, 6)]],
	"?": [[Vector2(0, 5), Vector2(1, 6), Vector2(3, 6), Vector2(4, 5), Vector2(4, 4), Vector2(2, 2.5), Vector2(2, 1.8)], [Vector2(2, 0), Vector2(2, 0.6)]],
	"¿": [[Vector2(4, 1), Vector2(3, 0), Vector2(1, 0), Vector2(0, 1), Vector2(0, 2), Vector2(2, 3.5), Vector2(2, 4.2)], [Vector2(2, 5.4), Vector2(2, 6)]],
	"%": [[Vector2(0, 0), Vector2(4, 6)], [Vector2(0.5, 5.5), Vector2(1, 5.5)], [Vector2(3, 0.5), Vector2(3.5, 0.5)]],
	"°": [[Vector2(1.5, 6), Vector2(2.5, 6), Vector2(2.5, 5), Vector2(1.5, 5), Vector2(1.5, 6)]],
	"\"": [[Vector2(1.3, 6), Vector2(1.3, 4.6)], [Vector2(2.7, 6), Vector2(2.7, 4.6)]],
	"'": [[Vector2(2, 6), Vector2(2, 4.6)]],
	"…": [[Vector2(0.5, 0), Vector2(0.5, 0.6)], [Vector2(2, 0), Vector2(2, 0.6)], [Vector2(3.5, 0), Vector2(3.5, 0.6)]],
	"→": [[Vector2(0, 3), Vector2(4, 3)], [Vector2(2.5, 4.5), Vector2(4, 3), Vector2(2.5, 1.5)]],
	"↑": [[Vector2(2, 0), Vector2(2, 6)], [Vector2(0.5, 4.5), Vector2(2, 6), Vector2(3.5, 4.5)]],
	"↓": [[Vector2(2, 6), Vector2(2, 0)], [Vector2(0.5, 1.5), Vector2(2, 0), Vector2(3.5, 1.5)]],
	"_": [[Vector2(0, -0.5), Vector2(4, -0.5)]],
	"•": [[Vector2(1.4, 3), Vector2(2.6, 3)], [Vector2(2, 2.4), Vector2(2, 3.6)]],
	"▶": [[Vector2(0.5, 6), Vector2(4, 3), Vector2(0.5, 0), Vector2(0.5, 6)]],
	"■": [[Vector2(0.5, 0.5), Vector2(3.5, 0.5), Vector2(3.5, 5.5), Vector2(0.5, 5.5), Vector2(0.5, 0.5)]],
	";": [[Vector2(2, 4), Vector2(2, 4.6)], [Vector2(2, 0.6), Vector2(1.5, -1)]],
}
## Lo que se escribe igual que otro carácter.
const SAME_AS := {"“": "\"", "”": "\"", "«": "\"", "»": "\"", "‘": "'", "’": "'", "–": "-", "×": "X", "º": "°", "ª": "°"}
## Lo que se arma de otro carácter más una marca arriba: [base, marca].
const COMPOSED := {
	"Á": ["A", "acute"], "É": ["E", "acute"], "Í": ["I", "acute"], "Ó": ["O", "acute"], "Ú": ["U", "acute"],
	"Ñ": ["N", "tilde"], "Ü": ["U", "dieresis"],
}
const MARKS := {
	"acute": [[Vector2(1.5, 6.8), Vector2(2.6, 7.8)]],
	"tilde": [[Vector2(0.8, 6.9), Vector2(1.5, 7.6), Vector2(2.5, 6.9), Vector2(3.2, 7.6)]],
	"dieresis": [[Vector2(1, 7), Vector2(1, 7.6)], [Vector2(3, 7), Vector2(3, 7.6)]],
}

static var _cache: Dictionary = {}


## Los trazos de un carácter, en unidades de la grilla, y a qué escala va (1, o SMALL_CAPS si era minúscula).
static func strokes(character: String) -> Array:
	var upper := character.to_upper()
	if SAME_AS.has(upper):
		upper = SAME_AS[upper]
	if GLYPHS.has(upper):
		return GLYPHS[upper]
	if COMPOSED.has(upper):
		var parts: Array = COMPOSED[upper]
		var out: Array = []
		out.append_array(GLYPHS[parts[0]])
		out.append_array(MARKS[parts[1]])
		return out
	return []


## Si se escribe en versalita: una minúscula que tiene mayúscula.
static func is_small(character: String) -> bool:
	return character != character.to_upper()


## Cuánto mide `text` escrito a `height` de mayúscula: ancho y alto, en metros. Con `stroke` (el trazo, en metros),
## lo que ocupa de verdad, trazo incluido, con el paso que le toca a ese trazo (ver `advance`).
static func measure(text: String, height: float, stroke := -1.0) -> Vector2:
	if text.is_empty():
		return Vector2.ZERO
	var unit := height / CAP
	if stroke >= 0.0:
		return Vector2(float(text.length() - 1) * advance(height, stroke) + 4.0 * unit + stroke, height)
	return Vector2((float(text.length()) * ADVANCE - (ADVANCE - 4.0)) * unit, height)


## EL PASO ENTRE LETRAS PARA UN TRAZO (el dios del juego: «en la versión más gruesa creo que podés mejorar el kerning…
## teniendo en cuenta que es una fuente monoespacio»): sigue siendo el mismo para todas las letras, pero el trazo crece
## medio ancho para cada lado y se comía el aire entre ellas; ahora el paso es el ancho de la letra, el aire de GAP y el
## trazo, así el aire que se ve es siempre GAP. Con el trazo de siempre (DEFAULT_WEIGHT del alto) da ADVANCE, como antes.
const GAP := 1.24
const DEFAULT_WEIGHT := 0.36


static func advance(height: float, stroke: float) -> float:
	var unit := height / CAP
	return (4.0 + GAP) * unit + stroke


## LOS SEGMENTOS de un texto, en metros, en el plano XY: pares de puntos. La línea de base en y = −alto/2, así
## que el texto queda centrado en alto; en ancho, según `align`.
static func segments(text: String, height: float, align: Align = Align.CENTER) -> PackedVector2Array:
	var unit := height / CAP
	var width := measure(text, height).x
	var x0 := 0.0
	match align:
		Align.CENTER:
			x0 = -width * 0.5
		Align.RIGHT:
			x0 = -width
	var out := PackedVector2Array()
	for i in text.length():
		var character := text[i]
		var scale := SMALL_CAPS if is_small(character) else 1.0
		var origin := Vector2(x0 + float(i) * ADVANCE * unit + 2.0 * unit * (1.0 - scale), -height * 0.5)
		for stroke: Array in strokes(character):
			for k in stroke.size() - 1:
				out.append(origin + (stroke[k] as Vector2) * unit * scale)
				out.append(origin + (stroke[k + 1] as Vector2) * unit * scale)
	return out


## ── EL CONTORNO DE LOS TRAZOS, A CUALQUIER GROSOR ──────────────────────────────────────────────
## (el dios del juego, 1/11/2026: «la fuente… no escala bien el grosor, hace como unos artefactos en sus esquinas…
## funciona bien sólo con el grosor por default… fijate cómo lo resolvés de la mejor manera»). Cada trazo era un
## rectángulo por segmento: en 2D con las puntas cortadas —muescas en cada esquina— y en 3D estiradas medio ancho —picos
## que salen en los chaflanes—; con el trazo fino no se notaba. Ahora CADA TRAZO ES SU CONTORNO: la línea corrida medio
## ancho para cada lado, con las esquinas en inglete (las muy agudas, cortadas: las corta el motor) y las puntas
## cuadradas; un trazo cerrado (la O) es su anillo. Sin agujeros —un polígono no los dibuja—: un anillo se parte en dos
## por el medio del agujero (ver `_without_holes`). Los trazos de una letra se pisan entre ellos, del mismo color: no se
## nota. Se guarda por carácter y por grosor en la grilla: escribir mucho no cuesta.

## LOS POLÍGONOS DE UN TEXTO, en metros, en el plano XY (y para arriba, como `segments`): sus trazos de `stroke` de
## ancho, sin agujeros. Para dibujar en 2D (ver CityChart) y para las mallas.
static func outlines(text: String, height: float, stroke: float, align: Align = Align.CENTER) -> Array[PackedVector2Array]:
	var unit := height / CAP
	# El ancho y el paso de este trazo; la caja de la letra empieza medio trazo adentro de lo que ocupa.
	var width := measure(text, height, stroke).x
	var step := advance(height, stroke)
	var x0 := stroke * 0.5
	match align:
		Align.CENTER:
			x0 = -width * 0.5 + stroke * 0.5
		Align.RIGHT:
			x0 = -width + stroke * 0.5
	var out: Array[PackedVector2Array] = []
	for i in text.length():
		var character := text[i]
		var scale := SMALL_CAPS if is_small(character) else 1.0
		var origin := Vector2(x0 + float(i) * step + 2.0 * unit * (1.0 - scale), -height * 0.5)
		# El grosor en la grilla de la letra: el mismo trazo en metros, en una versalita también.
		var weight := stroke / maxf(unit * scale, 1e-6)
		for shape in glyph_outline(character, weight):
			var placed := PackedVector2Array()
			for q in shape:
				placed.append(origin + q * unit * scale)
			out.append(placed)
	return out


## El contorno de un carácter en su grilla, con el trazo de `weight` de la grilla. Guardado.
static func glyph_outline(character: String, weight: float) -> Array[PackedVector2Array]:
	var key := "%s|%.3f" % [character.to_upper() if not is_small(character) else character, weight]
	if not _outline_cache.has(key):
		var out: Array[PackedVector2Array] = []
		for stroke: Array in strokes(character):
			out.append_array(stroke_outline(PackedVector2Array(stroke), weight * 0.5))
		_outline_cache[key] = out
	return _outline_cache[key]


static var _outline_cache := {}


## EL CONTORNO DE UNA LÍNEA de `half` de medio ancho: abierta, con las puntas cuadradas; cerrada (la primera punta en la
## última), su anillo. Sin agujeros.
static func stroke_outline(line: PackedVector2Array, half: float) -> Array[PackedVector2Array]:
	var clean := PackedVector2Array()
	for q in line:
		if clean.is_empty() or clean[clean.size() - 1].distance_to(q) > 1e-6:
			clean.append(q)
	if clean.size() < 2:
		if clean.size() == 1:
			var c := clean[0]
			return [PackedVector2Array([c + Vector2(-half, -half), c + Vector2(half, -half), c + Vector2(half, half),
				c + Vector2(-half, half)])]
		return []
	var closed := clean.size() > 3 and clean[0].distance_to(clean[clean.size() - 1]) < 1e-4
	var pieces: Array = []
	if closed:
		var ring := clean.slice(0, clean.size() - 1)
		pieces.append_array(Geometry2D.offset_polygon(ring, half, Geometry2D.JOIN_MITER))
		for inner in Geometry2D.offset_polygon(ring, -half, Geometry2D.JOIN_MITER):
			# Lo de adentro va como agujero: del otro sentido que lo de afuera.
			var hole := inner
			if Geometry2D.is_polygon_clockwise(hole) == Geometry2D.is_polygon_clockwise(pieces[0] if not pieces.is_empty()
					else ring):
				hole.reverse()
			pieces.append(hole)
	else:
		pieces.append_array(Geometry2D.offset_polyline(clean, half, Geometry2D.JOIN_MITER, Geometry2D.END_SQUARE))
	return _without_holes(pieces)


## LOS POLÍGONOS SIN AGUJEROS: de lo que devuelve el motor, los de afuera van del sentido del más grande y los agujeros
## del otro; cada agujero se le saca a los de afuera que lo contienen, partiéndolos en dos por el medio del agujero.
static func _without_holes(pieces: Array) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	if pieces.is_empty():
		return out
	var biggest: PackedVector2Array = pieces[0]
	for piece: PackedVector2Array in pieces:
		if absf(_area(piece)) > absf(_area(biggest)):
			biggest = piece
	var outer_sense := Geometry2D.is_polygon_clockwise(biggest)
	var holes: Array[PackedVector2Array] = []
	for piece: PackedVector2Array in pieces:
		if piece.size() < 3:
			continue
		if Geometry2D.is_polygon_clockwise(piece) == outer_sense:
			out.append(piece)
		else:
			holes.append(piece)
	for hole in holes:
		var middle := Vector2.ZERO
		for q in hole:
			middle += q
		middle /= float(hole.size())
		var cut: Array[PackedVector2Array] = []
		for shape in out:
			if not Geometry2D.is_point_in_polygon(middle, shape):
				cut.append(shape)
				continue
			var far := 1.0e5
			for side: float in [-1.0, 1.0]:
				var half_plane := PackedVector2Array([Vector2(middle.x, -far), Vector2(middle.x + side * far, -far),
					Vector2(middle.x + side * far, far), Vector2(middle.x, far)])
				for part in Geometry2D.intersect_polygons(shape, half_plane):
					for left in Geometry2D.clip_polygons(part, hole):
						if Geometry2D.is_polygon_clockwise(left) == Geometry2D.is_polygon_clockwise(part):
							cut.append(left)
		out = cut
	return out


static func _area(polygon: PackedVector2Array) -> float:
	var sum := 0.0
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		sum += a.x * b.y - b.x * a.y
	return sum * 0.5


## LA MALLA DE UN TEXTO, en metros: cada trazo es una tira de `stroke` de ancho; con `depth` 0 es plana, mirando a
## +Z, y con más es un prisma que sale de z = 0 hacia +Z. Guardada: pedirla otra vez no cuesta.
static func mesh(text: String, height: float, stroke: float, depth: float = 0.0, align: Align = Align.CENTER) -> ArrayMesh:
	var key := "%s|%.4f|%.4f|%.4f|%d" % [text, height, stroke, depth, align]
	if not _cache.has(key):
		_cache[key] = _build_outlines(outlines(text, height, stroke, align), depth)
	return _cache[key]


## VARIAS LÍNEAS EN UNA SOLA MALLA: cada una {"text", "height", "at"} —`at` es dónde empieza su línea de base a la
## izquierda, en metros—, todas con el trazo a `stroke_ratio` de su alto. Es lo que usa una hoja de texto (ver
## ManualInteractable): una malla por hoja y no una por renglón. No se guarda.
static func lines_mesh(lines: Array, stroke_ratio: float) -> ArrayMesh:
	var shapes: Array[PackedVector2Array] = []
	for line: Dictionary in lines:
		var height: float = line["height"]
		var at: Vector2 = line["at"]
		var shift := at + Vector2(0.0, height * 0.5)
		for shape in outlines(str(line["text"]), height, height * stroke_ratio, Align.LEFT):
			var moved := PackedVector2Array()
			for p in shape:
				moved.append(p + shift)
			shapes.append(moved)
	return _build_outlines(shapes, 0.0)


## La malla de trazos sueltos (cada uno una lista de puntos en metros, en el plano XY), con el mismo dibujo que una
## letra. Para lo que se dibuja con líneas sin ser texto. No se guarda: quien la pide la guarda si la repite.
static func polyline_mesh(polylines: Array, stroke: float, depth: float = 0.0) -> ArrayMesh:
	var shapes: Array[PackedVector2Array] = []
	for line: Variant in polylines:
		shapes.append_array(stroke_outline(PackedVector2Array(line), stroke * 0.5))
	return _build_outlines(shapes, depth)


## LA MALLA DE UNOS POLÍGONOS SIN AGUJEROS (ver `outlines`): plana, cada uno triangulado mirando a +Z en z = `depth`;
## con espesor, además sus costados de z = 0 a `depth`, mirando afuera.
static func _build_outlines(shapes: Array[PackedVector2Array], depth: float) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	for shape in shapes:
		if shape.size() < 3:
			continue
		var triangles := Geometry2D.triangulate_polygon(shape)
		for k in range(0, triangles.size() - 2, 3):
			var a := _v(shape[triangles[k]], depth)
			var b := _v(shape[triangles[k + 1]], depth)
			var c := _v(shape[triangles[k + 2]], depth)
			_triangle(verts, normals, a, b, c, Vector3.BACK)
		if depth > 0.0:
			# El costado mira afuera: a la derecha de cada borde si el polígono va en sentido horario, a la izquierda si no.
			var clockwise := Geometry2D.is_polygon_clockwise(shape)
			for e in shape.size():
				var p := shape[e]
				var q := shape[(e + 1) % shape.size()]
				var out := Vector3(q.y - p.y, p.x - q.x, 0.0).normalized()
				if not clockwise:
					out = -out
				_quad(verts, normals, _v(p, 0.0), _v(q, 0.0), _v(q, depth), _v(p, depth), out)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	var built := ArrayMesh.new()
	if not verts.is_empty():
		built.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return built


## Un triángulo mirando a `facing` (ver `_quad`).
static func _triangle(verts: PackedVector3Array, normals: PackedVector3Array, p: Vector3, q: Vector3, r: Vector3,
		facing: Vector3) -> void:
	if (r - p).cross(q - p).dot(facing) < 0.0:
		var swap := q
		q = r
		r = swap
	verts.append(p)
	verts.append(q)
	verts.append(r)
	for i in 3:
		normals.append(facing)


static func _v(p: Vector2, z: float) -> Vector3:
	return Vector3(p.x, p.y, z)


## Un cuadrilátero mirando a `facing`. ⚠ El frente de una cara en Godot es HORARIO visto de frente: el orden se
## decide comparando con la normal que daría, no se supone.
static func _quad(verts: PackedVector3Array, normals: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3,
		d: Vector3, facing: Vector3) -> void:
	for tri: Array in [[a, b, c], [a, c, d]]:
		var p: Vector3 = tri[0]
		var q: Vector3 = tri[1]
		var r: Vector3 = tri[2]
		if (r - p).cross(q - p).dot(facing) < 0.0:
			var swap := q
			q = r
			r = swap
		verts.append(p)
		verts.append(q)
		verts.append(r)
		for i in 3:
			normals.append(facing)
