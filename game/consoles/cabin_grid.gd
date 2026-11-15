class_name CabinGrid
extends RefCounted

## LA CABINA DE LA MECA EN NÚMEROS: UNA TRAMA CUADRADA Y POCAS REGLAS, de las que sale todo lo demás. La idea es la de la
## meca de character-parametric (`ShipGrid`): cambiar un número y que todo lo siga (el usuario, 13/11/2026: «con una
## sola variante parametrizamos… después, si queremos cambiar las proporciones o algo, es cuestión de cambiar un valor»).
##
##   · UNA CELDA CHICA PARA TODO (`CELL`): 1/16 del cubo de recurso (3,94 cm), casi la de los tableros de la meca (4 cm).
##     OJO: LA PISADA DE LAS ESCALERAS DE TODO EL JUEGO (Stairs.TREAD, del módulo Mundo) son 8 de estas celdas; cambiar
##     `CELL` o el nombre de la clase, avisándole.
##   · LA TRAMA (14/11/2026, el usuario: «este sistema de celdas me parece un sistema bueno»): la planta de adentro es de
##     `ACROSS` × `ACROSS` celdas de trama, cada una de `TRAMA_CELLS` celdas chicas (13: 51 cm). Todo ocupa celdas de
##     trama enteras. EJES: X a la derecha, Y arriba, −Z al frente; el origen en el centro de la caja.
##   · UN SOLO PISO, de `HEIGHT_CELLS` celdas chicas libres (96: 3,78 m), entre la losa del piso y la del techo.
##   · ADELANTE, EL VIDRIO: el frente y los costados hasta `SIDE_GLASS` celdas de trama (la mitad), de piso a techo, sin
##     marcos; la arista de arriba del frente, cortada a 45° (`CHAMFER` celdas de trama), también de vidrio, y el techo
##     de vidrio hasta `ROOF_GLASS` celdas (el corte, nada más). Cada uno, aparte (el usuario, 14/11/2026: «también
##     tengo que elegir hasta dónde llega el vidrio de arriba y yo decido si coincido o no con la de los costados»).
##   · ADELANTE, UN TABLERO de una celda de fondo, con TRES PUESTOS: un brazo a cada lado y la espalda al medio. Cada
##     puesto es UN HUECO entre DIVISORES que salen hacia atrás (todos de una celda, también los de las puntas contra la
##     pared), y la silla va adentro (`front_seats`). Un puesto cerrado (`OPEN_POSTS`) se rellena hasta la punta de los
##     divisores (el usuario, 15/11/2026, por la sesión Tableros: «es exactamente eso»; los de las puntas, del mismo
##     ancho: «queda raro»).
##   · ATRÁS, UNA TARIMA de dos celdas de fondo, de pared a pared, de `PLATFORM_HEIGHT` de alto: arriba, al medio, el movimiento
##     (`top_seat`). Dos escaleras rectas contra las paredes de los costados (dos celdas de ancho) suben a ella. En el
##     frente de la tarima, de cara al ascensor, los cuatro kits y la batería; arriba, en la pared de atrás, la munición.
##   · EL ASCENSOR EN EL MEDIO, aparte de la trama de los puestos: un hueco redondo de `LIFT_CELLS` celdas chicas de
##     radio (el usuario: «el ascensor del medio sale de esa grilla de módulos»).
##   · LA FORMA SE CAMBIA JUGANDO (`shape`, el panel F2, CabinShapePanel). Lo guardado (`SAVED`) es la forma de todas.
##
## *Hasta el 14/11/2026 la cabina era de módulos de 1,89 m, de varios pisos, con una caja de vidrio que sobresalía y una
## estructura a elegir (escaleras de afuera, escalera de adentro o el ascensor entre pisos). Se sacó todo para pasar a la
## cabina diseñada en planta (docs/technical/cabina.md).*

const CELL := SupplyLook.U / 16.0
## El espesor de las paredes y de las losas.
const WALL_CELLS := 6
const SLAB_CELLS := 5
const WALL := WALL_CELLS * CELL
const SLAB := SLAB_CELLS * CELL
## LA TARIMA DE ATRÁS: su fondo (celdas de trama). Su alto, en la forma (`PLATFORM_HEIGHT`).
const PLATFORM_ROWS := 2
## El tablero de adelante: su fondo (celdas de trama) y su alto (m). Los divisores: su ancho y hasta dónde llegan hacia
## atrás (celdas de trama, desde el vidrio). Los tres huecos se reparten lo que dejan los cuatro divisores (con 12 por
## lado, de 2,67). Menos de `MIN_ACROSS` por lado, no se puede.
const DESK_ROWS := 1
const DESK_HEIGHT := 0.8
const DIVIDER_CELLS := 1.0
const DIVIDER_ROWS := 2.5
const MIN_ACROSS := 12
## Las escaleras: su ancho (celdas de trama).
const STAIR_CELLS := 2
## EL HOMBRO: a qué parte del alto libre, en el medio del costado.
const SHOULDER_SHARE := 0.6

## Dónde se guarda la forma de todas las mecas (la escribe el panel F2; no se sube al repositorio).
const SAVED := "res://game/consoles/cabin_trama.tres"

## ── LA FORMA (ver `shape`): lo que cambia el panel, y lo que sale de ahí ─────────────────────────────────────────
static var TRAMA_CELLS := 13
static var ACROSS := 12
static var HEIGHT_CELLS := 96
static var CHAMFER := 2
## LA CABEZA (ver CabinShape.head): 0 plana, con el corte; 1 en rampa (ver `ramp`). En rampa, el alto libre del frente
## en celdas chicas (`FRONT_CELLS`); el de atrás es `HEIGHT_CELLS`.
static var HEAD := 0
static var FRONT_CELLS := 73
## EL ZÓCALO abajo del vidrio, en celdas chicas.
static var SILL_CELLS := 0
## EL INTERIOR (ver CabinShape.interior, ChamferCabin): 0 la tarima atrás con escaleras; 1 el centro octogonal con
## chanfles (`chamfered`). Sus medidas, en celdas chicas: el corte de las esquinas, la tarima y lo corrido atrás del
## ascensor; y cuántos escalones.
static var INTERIOR := 1
static var CORNER_CELLS := 18
static var DECK_CELLS := 29
static var DECK_STEPS := 3
static var LIFT_BACK_CELLS := 13
static var LIFT_CELLS := 26
## Hasta dónde llega el vidrio, desde el frente de adentro, en celdas de trama: el de los costados y el del techo.
static var SIDE_GLASS := 6
static var ROOF_GLASS := 2
## El alto de la tarima de atrás (m).
static var PLATFORM_HEIGHT := 1.2
## Qué puestos de adelante están abiertos (con su hueco y su silla), de izquierda a derecha. Los cerrados se rellenan.
## *Todavía no lo cambia nada: con dos jugadores, sólo el del medio (el usuario, 15/11/2026).*
static var OPEN_POSTS: Array[bool] = [true, true, true]
## EL COLOR DEL VIDRIO, con cuánto se ve en el alfa.
static var GLASS_COLOR := Color(0.6, 0.8, 0.92, 0.12)
## EL MARCO DEL VIDRIO (ver MechCabin._frame): 0 nada, 1 sólo las aristas, 2 las aristas y los parantes entre puestos;
## y el grosor de las aristas y el de los parantes (m).
static var FRAME_KIND := 1
static var EDGE_THICKNESS := 0.12
static var POST_THICKNESS := 0.08
## Una celda de trama (m).
static var TRAMA := 0.0
## Lo de adentro, desde el centro hasta la cara de adentro de la pared.
static var INNER := 0.0
## EL LADO DE LA CAJA, en planta (el ancho y el fondo), y su mitad.
static var SIZE := 0.0
static var HALF := 0.0
## EL ALTO DE LA CAJA, de la cara de abajo del piso a la de arriba del techo, y su mitad (el origen es su centro).
static var HEIGHT := 0.0
static var HALF_HEIGHT := 0.0
## Lo libre adentro, del piso al techo.
static var CLEAR := 0.0
## El radio del hueco del ascensor (cuadrado, la mitad del lado), y si es cuadrado (ver PelvisLift).
static var LIFT_HOLE := 0.0
static var LIFT_SQUARE := false
## LAS SILLAS: la altura de los ojos que buscan igualar (m, sobre su piso).
static var EYE_HEIGHT := 1.15
## CUÁNTO SALEN LOS HOMBROS del costado (ver CabinShape.shoulder_out, Mech.shoulder): es del cuerpo, para todas las mecas.
static var SHOULDER_OUT := 1.0


static func _static_init() -> void:
	var saved := load(SAVED) as CabinShape if ResourceLoader.exists(SAVED) else null
	apply(saved if saved != null else CabinShape.new())


## TOMA TODA LA FORMA GUARDADA: la cabina (`shape`), las sillas y el cuerpo (MechBody.dress). Las mecas que ya estaban
## no cambian: hay que rearmarlas (ver CabinShapePanel).
static func apply(saved: CabinShape) -> void:
	shape(saved)
	EYE_HEIGHT = saved.eye_height
	MechBody.dress(saved.thickness, saved.arm_length, saved.leg_length, saved.leg_stretch)
	SHOULDER_OUT = saved.shoulder_out


## CAMBIA LA FORMA DE LA CAJA (ver CabinShape, «La caja»): la celda de trama, cuántas por lado, el alto libre, el corte
## del vidrio, hasta dónde llega el vidrio de los costados y el del techo, el ascensor y el alto de la tarima. Lo que no
## entra se corrige: el vidrio llega por lo menos hasta el corte.
static func shape(saved: CabinShape) -> void:
	TRAMA_CELLS = maxi(saved.cell, 4)
	ACROSS = maxi(saved.across, MIN_ACROSS) / 2 * 2
	HEIGHT_CELLS = maxi(saved.height_cells, 60)
	CHAMFER = clampi(saved.chamfer, 0, ACROSS / 2)
	HEAD = clampi(saved.head, 0, 1)
	INTERIOR = clampi(saved.interior, 0, 1)
	CORNER_CELLS = clampi(saved.corner_cells, 8, 40)
	DECK_CELLS = clampi(saved.deck_cells, 18, 60)
	DECK_STEPS = clampi(saved.deck_steps, 1, 5)
	LIFT_BACK_CELLS = clampi(saved.lift_back_cells, 0, 30)
	FRONT_CELLS = clampi(saved.front_height_cells, 40, HEIGHT_CELLS)
	SILL_CELLS = clampi(saved.sill_cells, 0, (FRONT_CELLS if HEAD == 1 else HEIGHT_CELLS) - 30)
	# En rampa, el vidrio de los costados llega por lo menos a una celda (es donde termina la rampa).
	SIDE_GLASS = clampi(saved.side_glass, 1 if HEAD == 1 else CHAMFER, ACROSS - PLATFORM_ROWS)
	ROOF_GLASS = clampi(saved.roof_glass, CHAMFER, ACROSS)
	LIFT_CELLS = clampi(saved.lift_radius, 4, ACROSS * TRAMA_CELLS / 4)
	PLATFORM_HEIGHT = clampf(saved.platform_height, 0.3, HEIGHT_CELLS * CELL - 1.0)
	LIFT_SQUARE = saved.lift_square
	GLASS_COLOR = Color(saved.glass_color, saved.glass_opacity)
	FRAME_KIND = saved.frame_kind
	EDGE_THICKNESS = saved.edge_thickness
	POST_THICKNESS = saved.post_thickness
	TRAMA = TRAMA_CELLS * CELL
	INNER = ACROSS * 0.5 * TRAMA
	HALF = INNER + WALL
	SIZE = HALF * 2.0
	CLEAR = HEIGHT_CELLS * CELL
	HEIGHT = CLEAR + SLAB * 2.0
	HALF_HEIGHT = HEIGHT * 0.5
	LIFT_HOLE = LIFT_CELLS * CELL


## La forma de hoy, para guardarla.
static func current() -> CabinShape:
	var now := CabinShape.new()
	now.cell = TRAMA_CELLS
	now.across = ACROSS
	now.height_cells = HEIGHT_CELLS
	now.chamfer = CHAMFER
	now.head = HEAD
	now.interior = INTERIOR
	now.corner_cells = CORNER_CELLS
	now.deck_cells = DECK_CELLS
	now.deck_steps = DECK_STEPS
	now.lift_back_cells = LIFT_BACK_CELLS
	now.front_height_cells = FRONT_CELLS
	now.sill_cells = SILL_CELLS
	now.lift_radius = LIFT_CELLS
	now.lift_square = LIFT_SQUARE
	now.side_glass = SIDE_GLASS
	now.roof_glass = ROOF_GLASS
	now.platform_height = PLATFORM_HEIGHT
	now.glass_color = Color(GLASS_COLOR, 1.0)
	now.glass_opacity = GLASS_COLOR.a
	now.frame_kind = FRAME_KIND
	now.edge_thickness = EDGE_THICKNESS
	now.post_thickness = POST_THICKNESS
	now.eye_height = EYE_HEIGHT
	now.arm_length = MechBody.arm_size
	now.leg_length = MechBody.leg_size
	now.thickness = MechBody.thick_size
	now.leg_stretch = MechBody.stretch
	now.shoulder_out = SHOULDER_OUT
	return now


## Si la cabeza va en rampa (ver CabinShape.head).
static func ramp() -> bool:
	return HEAD == 1


## Si el interior es el del centro octogonal con chanfles (ver ChamferCabin).
static func chamfered() -> bool:
	return INTERIOR == 1


## El zócalo abajo del vidrio (m).
static func sill() -> float:
	return SILL_CELLS * CELL


## En rampa, el alto libre del frente (m); plana, el de todo.
static func front_clear() -> float:
	return FRONT_CELLS * CELL if ramp() else CLEAR


## La caja entera: el lado en planta y el alto.
static func box() -> Vector3:
	return Vector3(SIZE, HEIGHT, SIZE)


## Donde se pisa adentro (la cara de arriba de la losa del piso).
static func floor_top() -> float:
	return -HALF_HEIGHT + SLAB


## La cara de abajo del techo.
static func ceiling() -> float:
	return HALF_HEIGHT - SLAB


## La celda de trama `index` (0 la de la izquierda, o la del frente), su borde: de −`INNER` a `INNER`.
static func line(index: float) -> float:
	return -INNER + index * TRAMA


## Donde empieza la tarima de atrás (z de su frente).
static func platform_front() -> float:
	return INNER - PLATFORM_ROWS * TRAMA


## El ancho de cada hueco de los puestos de adelante (celdas de trama).
static func hole_cells() -> float:
	return (ACROSS - DIVIDER_CELLS * 4.0) / 3.0


## Donde empieza (a la izquierda) el divisor `index` (0 el de la pared izquierda, 3 el de la derecha), en celdas.
static func divider_cell(index: int) -> float:
	return index * (DIVIDER_CELLS + hole_cells())


## LOS TRES PUESTOS DE ADELANTE: dónde va cada silla (en el piso), mirando al frente, de izquierda a derecha (el brazo
## izquierdo, la espalda, el brazo derecho). En el medio de su hueco, a 0,75 celdas detrás del tablero (adentro del
## hueco, que llega hasta `DIVIDER_ROWS`).
static func front_seats() -> Array[Vector3]:
	var all: Array[Vector3] = []
	var z := line(DESK_ROWS + 0.75)
	for post in 3:
		all.append(Vector3(line(divider_cell(post) + DIVIDER_CELLS + hole_cells() * 0.5), floor_top(), z))
	return all


## Los divisores entre puestos (los dos del medio): x de su centro, de izquierda a derecha.
static func post_lines() -> Array[float]:
	return [line(divider_cell(1) + DIVIDER_CELLS * 0.5), line(divider_cell(2) + DIVIDER_CELLS * 0.5)]


## LA SILLA DE ARRIBA, en el medio de la tarima: la del movimiento.
static func top_seat() -> Vector3:
	return Vector3(0.0, floor_top() + PLATFORM_HEIGHT, INNER - PLATFORM_ROWS * TRAMA * 0.5)


## EL HOMBRO, en el espacio de la caja, sin lo que lo corre hacia afuera (ver Mech.shoulder): en el medio del costado,
## a `SHOULDER_SHARE` del alto libre.
static func shoulder() -> Vector3:
	return Vector3(HALF, floor_top() + CLEAR * SHOULDER_SHARE, 0.0)
