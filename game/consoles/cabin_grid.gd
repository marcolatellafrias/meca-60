class_name CabinGrid
extends RefCounted

## LA CABINA DE LA MECA EN NÚMEROS: UNA CELDA, MÓDULOS CUADRADOS Y POCAS REGLAS, de las que sale todo lo demás (los
## pisos, las paredes, los huecos, los asientos, el ascensor y el afuera). La idea es la de la nave de
## character-parametric (`ShipGrid`): cambiar un número y que todo lo siga (el usuario, 13/11/2026: «con una sola
## variante parametrizamos… después, si queremos cambiar las proporciones o algo, es cuestión de cambiar un valor»).
##
##   · UNA SOLA CELDA PARA TODO (`CELL`): 1/16 del cubo de recurso (3,94 cm), casi la de los tableros de la nave (4 cm,
##     del tamaño de la mano), y el cubo de 63 cm es 16 × 16 justas: un hueco de recurso encaja en cualquier tablero.
##     Toda medida de la cabina es CELDAS ENTERAS.
##   · EL MÓDULO: un cuadrado de 3 cubos (48 celdas, 1,89 m). Cada piso es una grilla de `COLUMNS` × `ROWS` módulos,
##     entre sus paredes. LA COLUMNA 0 ES LA DE LA IZQUIERDA (−X) y LA FILA 0 LA DEL FRENTE (−Z).
##   · LOS PISOS: `FLOORS`, de `FLOOR_CELLS` cada uno, de losa a losa.
##   · LA CAJA ES UN CUBO: el ancho, el fondo y el alto dan lo mismo (204 celdas, 8,03 m). Es la caja de la meca (ver
##     `SIZE`).
##   · QUÉ VA EN CADA PISO (`SEATS`): la planta baja es DE SERVICIO, sin asientos (la munición, las baterías, los
##     tableros eléctricos, el ascensor en los 2 × 2 del medio); los dos de arriba, DOS ASIENTOS cada uno, en los
##     módulos del medio del frente (el usuario, 13/11/2026: el caso de 4 jugadores, «planta baja de servicio»).
##   · LOS HUECOS SON RECTÁNGULOS DE CELDAS, sin marcos: al frente, una ventana por módulo, con un parante en cada línea
##     entre módulos; atrás, la puerta de cada piso, en el medio.
##
## Ejes: X a la derecha, Y arriba, −Z al frente; el origen en el centro de la caja.

const CELL := SupplyLook.U / 16.0
const MODULE_CELLS := 48
const COLUMNS := 4
const ROWS := 4
const FLOORS := 3
const FLOOR_CELLS := 68
## El espesor de las paredes y de las losas.
const WALL_CELLS := 6
const SLAB_CELLS := 5

## El frente de cada piso: el antepecho, el vidrio (lo que queda arriba es el dintel) y el ancho de un parante.
const SILL_CELLS := 19
const GLASS_CELLS := 36
const POST_CELLS := 6
## La puerta de atrás de cada piso: ancho y alto.
const DOOR_CELLS := Vector2i(28, 52)
## Los asientos: por piso, las columnas de la fila del frente que llevan uno.
const SEATS := {1: [1, 2], 2: [1, 2]}
## Dónde va el asiento, desde la pared del frente: lo que ocupa el tablero de adelante y lo que queda hasta el centro
## de la silla.
const CONSOLE_CELLS := 13
const SEAT_CELLS := 33

const MODULE := MODULE_CELLS * CELL
const WALL := WALL_CELLS * CELL
const SLAB := SLAB_CELLS * CELL
const FLOOR_HEIGHT := FLOOR_CELLS * CELL
const WIDTH_CELLS := COLUMNS * MODULE_CELLS + WALL_CELLS * 2
const DEPTH_CELLS := ROWS * MODULE_CELLS + WALL_CELLS * 2
const HEIGHT_CELLS := FLOORS * FLOOR_CELLS
## EL LADO DE LA CAJA (la caja de la meca es un cubo: ver `cube_ok`).
const SIZE := WIDTH_CELLS * CELL
const HALF := SIZE * 0.5
## Lo de adentro, desde el centro hasta la cara de adentro de la pared.
const INNER := HALF - WALL


## Si el ancho, el fondo y el alto dan lo mismo: la caja de la meca es un cubo. Lo mira tests/load_all.
static func cube_ok() -> bool:
	return WIDTH_CELLS == DEPTH_CELLS and WIDTH_CELLS == HEIGHT_CELLS


## La línea del piso `index` (0 el de abajo, `FLOORS` el techo): el medio de su losa, salvo las de las puntas, que
## quedan adentro de la caja.
static func floor_line(index: int) -> float:
	return -HALF + index * FLOOR_HEIGHT


## Dónde está la losa `index`: su medio, ya adentro de la caja.
static func slab_y(index: int) -> float:
	return clampf(floor_line(index), -HALF + SLAB * 0.5, HALF - SLAB * 0.5)


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


## LOS ASIENTOS: dónde va cada uno (en el piso), mirando al frente.
static func seats() -> Array[Vector3]:
	var all: Array[Vector3] = []
	for index: int in SEATS:
		for column: int in SEATS[index]:
			all.append(seat(index, column))
	return all


static func seat(index: int, column: int) -> Vector3:
	return Vector3(column_x(column) + MODULE * 0.5, ground(index), -INNER + SEAT_CELLS * CELL)
