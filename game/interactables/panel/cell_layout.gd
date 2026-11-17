class_name CellLayout
extends RefCounted

## LA DISPOSICIÓN COMÚN POR CELDAS de un artefacto (ver docs/planes-maestros/plan-maestro-de-nave/limpieza-componentes.md):
## el artefacto dice sus piezas en FILAS y COLUMNAS —cada pieza, las celdas que ocupa; cada grupo, otra fila o columna—
## y la disposición calcula dónde va cada una. Así ningún artefacto hace cuentas de celdas a mano.
##
## EN LA GRILLA DE MEDIA CELDA, como lo decidió el usuario: una pieza se centra sobre otra de distinto tamaño
## aunque una sea par y la otra impar —una tecla de 2 sobre un rodillo de 3 queda corrida media celda, centrada—. Lo de
## adentro de un artefacto va en medias celdas; el artefacto, en el tablero, sigue ocupando celdas enteras.
##
## En el otro eje, todo se centra —los de una fila, en alto; los de una columna, en ancho—, o se pega al principio o al
## final (`align`). Las piezas se recorren en el orden en que se dieron (`spots`), así el artefacto monta cada una en el
## lugar que le toca.

## Dónde va cada uno en el otro eje: arriba (o a la izquierda), al medio, abajo (o a la derecha).
enum Align { START, CENTRE, END }

var _children: Array = []
var _vertical := false
var _gap := 0
var _align := Align.CENTRE


## UNA FILA de `children` —las celdas de una pieza (Vector2i) u otra CellLayout—, de izquierda a derecha, con `gap`
## celdas entre una y otra.
static func row(children: Array, gap := 0, align := Align.CENTRE) -> CellLayout:
	return _make(children, false, gap, align)


## UNA COLUMNA, de arriba abajo.
static func column(children: Array, gap := 0, align := Align.CENTRE) -> CellLayout:
	return _make(children, true, gap, align)


static func _make(children: Array, vertical: bool, gap: int, align: Align) -> CellLayout:
	var out := CellLayout.new()
	out._children = children
	out._vertical = vertical
	out._gap = gap
	out._align = align
	return out


## Las celdas que ocupa todo, enteras.
func cells() -> Vector2i:
	var half := halves()
	return Vector2i(ceili(half.x * 0.5), ceili(half.y * 0.5))


## Lo que ocupa, en medias celdas.
func halves() -> Vector2i:
	var along := 0
	var across := 0
	for child: Variant in _children:
		var size := _halves_of(child)
		along += size.y if _vertical else size.x
		across = maxi(across, size.x if _vertical else size.y)
	along += maxi(_children.size() - 1, 0) * _gap * 2
	return Vector2i(across, along) if _vertical else Vector2i(along, across)


## DÓNDE VA CADA PIEZA: la esquina de arriba a la izquierda de cada una, en medias celdas, con todo empezando en la
## celda `at`; en el orden en que se dieron, entrando en los grupos.
func spots(at: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	_place(at * 2, out)
	return out


func _place(corner: Vector2i, out: Array[Vector2i]) -> void:
	var total := halves()
	var along := 0
	for child: Variant in _children:
		var size := _halves_of(child)
		var room := (total.x - size.x) if _vertical else (total.y - size.y)
		var across := 0 if _align == Align.START else (room if _align == Align.END else room >> 1)
		var at := corner + (Vector2i(across, along) if _vertical else Vector2i(along, across))
		if child is CellLayout:
			(child as CellLayout)._place(at, out)
		else:
			out.append(at)
		along += (size.y if _vertical else size.x) + _gap * 2


static func _halves_of(child: Variant) -> Vector2i:
	if child is CellLayout:
		return (child as CellLayout).halves()
	return (child as Vector2i) * 2
