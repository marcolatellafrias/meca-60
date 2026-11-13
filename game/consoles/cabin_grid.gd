class_name CabinGrid
extends RefCounted

## LA CABINA DE LA MECA EN NÚMEROS: UNA CELDA, MÓDULOS CUADRADOS Y POCAS REGLAS, de las que sale todo lo demás (los
## pisos, las paredes, los huecos, los asientos, el ascensor y el afuera). La idea es la de la meca de
## character-parametric (`ShipGrid`): cambiar un número y que todo lo siga (el usuario, 13/11/2026: «con una sola
## variante parametrizamos… después, si queremos cambiar las proporciones o algo, es cuestión de cambiar un valor»).
##
##   · UNA SOLA CELDA PARA TODO (`CELL`): 1/16 del cubo de recurso (3,94 cm), casi la de los tableros de la meca (4 cm,
##     del tamaño de la mano), y el cubo de 63 cm es 16 × 16 justas: un hueco de recurso encaja en cualquier tablero.
##     Toda medida de la cabina es CELDAS ENTERAS. OJO: LA PISADA DE LAS ESCALERAS DE TODO EL JUEGO (Stairs.TREAD, del
##     módulo Mundo) son 8 de estas celdas; cambiar `CELL` o el nombre de la clase, avisándole.
##   · EL MÓDULO: un cuadrado de 3 cubos (48 celdas, 1,89 m). Cada piso es una grilla de `COLUMNS` × `ROWS` módulos,
##     entre sus paredes. LA COLUMNA 0 ES LA DE LA IZQUIERDA (−X) y LA FILA 0 LA DEL FRENTE (−Z).
##   · LOS PISOS: `FLOORS`, de `FLOOR_CELLS` cada uno, de losa a losa.
##   · LA CAJA ES CUADRADA EN PLANTA y CRECE PARA ARRIBA (el usuario, 13/11/2026: «el formato de cubo está bueno… al
##     girar no tiene tantos problemas de colisión. Pero en vertical no tiene problema en crecer»): el ancho y el fondo
##     salen de los módulos (`SIZE`); el alto, de los pisos y del alto de cada uno (`HEIGHT`). Con 4 módulos, 3 pisos y
##     68 celdas por piso es un cubo de 204 celdas (8,03 m), la de siempre.
##   · QUÉ VA EN CADA PISO (`seat_floors`): la planta baja es DE SERVICIO, sin asientos (la munición, las baterías, los
##     tableros eléctricos, el ascensor en el medio); los de arriba, DOS ASIENTOS cada uno, a los dos lados del medio
##     del frente (el usuario, 13/11/2026: el caso de 4 jugadores, «planta baja de servicio»).
##   · EL FRENTE ES UNA CAJA DE VIDRIO QUE SOBRESALE (`GLASS_OUT_CELLS`): vidrio al frente, a los costados, arriba y
##     abajo, sin parantes; lo único que la corta son las losas del medio. Atrás, la puerta de cada piso, en el medio.
##   · LA FORMA SE CAMBIA JUGANDO (`shape`, el panel F2 de las filas de la meca, CabinShapePanel): cuántos módulos por
##     lado, cuántos pisos, el alto de cada piso y cuánto sobresale el vidrio. Lo guardado (`SAVED`) es la forma de
##     todas las mecas.
##
## Ejes: X a la derecha, Y arriba, −Z al frente; el origen en el centro de la caja.

const CELL := SupplyLook.U / 16.0
const MODULE_CELLS := 48
## El espesor de las paredes y de las losas.
const WALL_CELLS := 6
const SLAB_CELLS := 5
## LA ALTURA DE REFERENCIA DE LOS TABLEROS: hasta donde llegaba el antepecho (y el primer tablero, un bloque que tapaba
## la vista para abajo y se sacó). No arma nada: es de donde se empiezan a ubicar los controles.
const DESK_CELLS := 19
## La puerta de atrás de cada piso: ancho y alto.
const DOOR_CELLS := Vector2i(28, 52)
## Dónde va el asiento, desde la pared del frente: lo que ocupaba el tablero de adelante (otra referencia, como
## `DESK_CELLS`) y lo que queda hasta el centro de la silla.
const CONSOLE_CELLS := 13
const SEAT_CELLS := 33
## EL ASCENSOR, en celdas sueltas (el usuario: «más en términos de celdas sueltas en vez de módulos»): el radio del hueco
## es un cuarto del ancho de adentro, menos `LIFT_MARGIN_CELLS`. Con 4 × 4 módulos, los 2 × 2 del medio.
const LIFT_MARGIN_CELLS := 3

const MODULE := MODULE_CELLS * CELL
const WALL := WALL_CELLS * CELL
const SLAB := SLAB_CELLS * CELL

## Dónde se guarda la forma de todas las mecas (la escribe el panel F2; no se sube al repositorio).
const SAVED := "res://game/consoles/cabin_shape.tres"

## ── LA FORMA (ver `shape`): lo que cambia el panel, y lo que sale de ahí ─────────────────────────────────────────
## Módulos por lado (las columnas y las filas, iguales: la planta es cuadrada), pisos, alto de un piso y cuánto
## sobresale el vidrio.
static var COLUMNS := 4
static var ROWS := 4
static var FLOORS := 3
static var GLASS_OUT_CELLS := 12
static var FLOOR_CELLS := 68
static var FLOOR_HEIGHT := 0.0
static var WIDTH_CELLS := 0
static var DEPTH_CELLS := 0
static var HEIGHT_CELLS := 0
## EL LADO DE LA CAJA, en planta (el ancho y el fondo), y su mitad.
static var SIZE := 0.0
static var HALF := 0.0
## EL ALTO DE LA CAJA, de la losa de abajo a la de arriba, y su mitad (el origen de la caja es su centro).
static var HEIGHT := 0.0
static var HALF_HEIGHT := 0.0
## Lo de adentro, desde el centro hasta la cara de adentro de la pared.
static var INNER := 0.0
static var GLASS_OUT := 0.0
## El radio del hueco del ascensor.
static var LIFT_HOLE := 0.0


static func _static_init() -> void:
	var saved := load(SAVED) as CabinShape if ResourceLoader.exists(SAVED) else null
	if saved != null:
		shape(saved.modules, saved.floors, saved.floor_cells, saved.glass_out)
	else:
		shape(COLUMNS, FLOORS, FLOOR_CELLS, GLASS_OUT_CELLS)


## CAMBIA LA FORMA: `modules` por lado, `floors` pisos de `floor_cells` celdas cada uno (de losa a losa) y el vidrio
## que sobresale `glass_out` celdas. Las mecas que ya estaban no cambian: hay que rearmarlas (ver CabinShapePanel).
static func shape(modules: int, floors: int, floor_cells: int, glass_out: int) -> void:
	COLUMNS = maxi(modules, 1)
	ROWS = COLUMNS
	FLOORS = maxi(floors, 1)
	GLASS_OUT_CELLS = maxi(glass_out, 0)
	WIDTH_CELLS = COLUMNS * MODULE_CELLS + WALL_CELLS * 2
	DEPTH_CELLS = ROWS * MODULE_CELLS + WALL_CELLS * 2
	FLOOR_CELLS = maxi(floor_cells, SLAB_CELLS + 1)
	HEIGHT_CELLS = FLOORS * FLOOR_CELLS
	FLOOR_HEIGHT = FLOOR_CELLS * CELL
	SIZE = WIDTH_CELLS * CELL
	HALF = SIZE * 0.5
	HEIGHT = HEIGHT_CELLS * CELL
	HALF_HEIGHT = HEIGHT * 0.5
	INNER = HALF - WALL
	GLASS_OUT = GLASS_OUT_CELLS * CELL
	LIFT_HOLE = (COLUMNS * MODULE_CELLS / 4 - LIFT_MARGIN_CELLS) * CELL
	# LAS PIERNAS Y LOS BRAZOS, EN PROPORCIÓN A LA CAJA (ver MechBody.scale_to): la de siempre son 4 módulos.
	MechBody.scale_to(float(WIDTH_CELLS) / float(4 * MODULE_CELLS + WALL_CELLS * 2))


## La forma de hoy, para guardarla.
static func current() -> CabinShape:
	var now := CabinShape.new()
	now.modules = COLUMNS
	now.floors = FLOORS
	now.floor_cells = FLOOR_CELLS
	now.glass_out = GLASS_OUT_CELLS
	return now


## La caja entera: el lado en planta y el alto.
static func box() -> Vector3:
	return Vector3(SIZE, HEIGHT, SIZE)


## La línea del piso `index` (0 el de abajo, `FLOORS` el techo): el medio de su losa, salvo las de las puntas, que
## quedan adentro de la caja.
static func floor_line(index: int) -> float:
	return -HALF_HEIGHT + index * FLOOR_HEIGHT


## Dónde está la losa `index`: su medio, ya adentro de la caja.
static func slab_y(index: int) -> float:
	return clampf(floor_line(index), -HALF_HEIGHT + SLAB * 0.5, HALF_HEIGHT - SLAB * 0.5)


## Donde se pisa en el piso `index`.
static func ground(index: int) -> float:
	return slab_y(index) + SLAB * 0.5


## Lo libre de un piso, de su piso al techo (la losa de arriba).
static func clear_height(index: int) -> float:
	return slab_y(index + 1) - SLAB * 0.5 - ground(index)


## El borde izquierdo de la columna `column` (x) y el de adelante de la fila `row` (z).
static func column_x(column: int) -> float:
	return -INNER + column * MODULE


static func row_z(row: int) -> float:
	return -INNER + row * MODULE


## El centro del módulo (`column`, `row`) en planta, a la altura `y`.
static func module_center(column: int, row: int, y := 0.0) -> Vector3:
	return Vector3(column_x(column) + MODULE * 0.5, y, row_z(row) + MODULE * 0.5)


## LOS PISOS CON ASIENTOS: todos menos la planta baja, que es de servicio; con un solo piso, ése.
static func seat_floors() -> Array[int]:
	var all: Array[int] = []
	for index in range(1 if FLOORS > 1 else 0, FLOORS):
		all.append(index)
	return all


## LOS ASIENTOS: dónde va cada uno (en el piso), mirando al frente. Dos por piso con asientos.
static func seats() -> Array[Vector3]:
	var all: Array[Vector3] = []
	for index in seat_floors():
		for side: float in [-1.0, 1.0]:
			all.append(seat(index, side))
	return all


## El asiento del piso `index` del lado `side` (−1 el izquierdo, 1 el derecho): medio módulo a ese lado del medio, a
## `SEAT_CELLS` de la pared del frente.
static func seat(index: int, side: float) -> Vector3:
	return Vector3(side * MODULE * 0.5, ground(index), -INNER + SEAT_CELLS * CELL)
