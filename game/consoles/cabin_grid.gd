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
##   · ADELANTE, EL VIDRIO: el frente y los costados hasta `SIDE_GLASS` celdas de trama, con el zócalo abajo; arriba, LA
##     CABEZA: plana, con la arista de arriba del frente cortada a 45° (`CHAMFER`) y el techo de vidrio hasta
##     `ROOF_GLASS`, o en rampa (`ramp`). Lo arma SquareCabin.
##   · LA PLANTA, con las cuatro esquinas cortadas (`CORNER_CELLS`); al medio, el ascensor; abajo, la pelvis de abajo
##     (`BASE`).
##   · LAS TRES SILLAS DE ADELANTE (`front_seats`), con tres perillas, para todas las cuadradas: la del medio, del
##     vidrio; los brazos, a los costados de ella y atrás (el usuario, 15/11/2026: «qué tan alejada está la izquierda y
##     derecha de la del medio, y qué tan offseteada para atrás»).
##   · EL ASCENSOR: un hueco redondo de `LIFT_CELLS` celdas chicas de radio (o menos, si no entra entre las sillas).
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
## Menos de `MIN_ACROSS` celdas de trama por lado, no se puede.
const MIN_ACROSS := 12
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
## LA PLANTA (ver SquareCabin), en celdas chicas: el corte de las esquinas.
static var CORNER_CELLS := 18
## LA PELVIS DE ABAJO (ver CabinShape.base_cells), en celdas chicas, y su alto (m). Es parte de la caja: el piso queda
## arriba de ella y las piernas salen de abajo.
static var BASE_CELLS := 25
static var BASE := 0.0
static var LIFT_CELLS := 26
## Hasta dónde llega el vidrio, desde el frente de adentro, en celdas de trama: el de los costados y el del techo.
static var SIDE_GLASS := 6
static var ROOF_GLASS := 2
## LAS SILLAS DE ADELANTE (ver `front_seats`), en celdas chicas: la del medio, de la cara de adentro del vidrio; los
## brazos, a cada costado de ella, en la misma línea.
static var SEAT_FRONT_CELLS := 16
static var SEAT_SPREAD_CELLS := 48
## EL COLOR DEL VIDRIO, con cuánto se ve en el alfa.
static var GLASS_COLOR := Color(0.6, 0.8, 0.92, 0.12)
## EL MARCO DEL VIDRIO (ver SquareCabin._edge, _posts): 0 nada, 1 sólo las aristas, 2 las aristas y los parantes entre puestos;
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
## El radio del hueco del ascensor (ver PelvisLift, SquareCabin.lift_radius).
static var LIFT_HOLE := 0.0
## LAS SILLAS: la altura de los ojos que buscan igualar (m, sobre su piso).
static var EYE_HEIGHT := 1.15


static func _static_init() -> void:
	var saved := load(SAVED) as CabinShape if ResourceLoader.exists(SAVED) else null
	apply(saved if saved != null else CabinShape.new())


## TOMA TODA LA FORMA GUARDADA: la cabina (`shape`), las sillas y el cuerpo (MechBody.dress). Las mecas que ya estaban
## no cambian: hay que rearmarlas (ver CabinShapePanel).
static func apply(saved: CabinShape) -> void:
	shape(saved)
	EYE_HEIGHT = saved.eye_height
	MechBody.current.dress(saved.thickness, saved.arm_length, saved.leg_length, saved.leg_stretch, saved.shoulder_out)


## CAMBIA LA FORMA DE LA CAJA (ver CabinShape, «La caja»): la celda de trama, cuántas por lado, el alto libre, el corte
## del vidrio, hasta dónde llega el vidrio de los costados y el del techo, el ascensor y el alto de la tarima. Lo que no
## entra se corrige: el vidrio llega por lo menos hasta el corte.
static func shape(saved: CabinShape) -> void:
	TRAMA_CELLS = maxi(saved.cell, 4)
	ACROSS = maxi(saved.across, MIN_ACROSS) / 2 * 2
	HEIGHT_CELLS = maxi(saved.height_cells, 55)
	CHAMFER = clampi(saved.chamfer, 0, ACROSS / 2)
	HEAD = clampi(saved.head, 0, 1)
	CORNER_CELLS = clampi(saved.corner_cells, 0, 40)
	BASE_CELLS = clampi(saved.base_cells, 0, 60)
	SEAT_FRONT_CELLS = clampi(saved.seat_front_cells, 8, 60)
	SEAT_SPREAD_CELLS = clampi(saved.seat_spread_cells, 15, 90)
	FRONT_CELLS = clampi(saved.front_height_cells, 40, HEIGHT_CELLS)
	SILL_CELLS = clampi(saved.sill_cells, 0, (FRONT_CELLS if HEAD == 1 else HEIGHT_CELLS) - 30)
	# En rampa, el vidrio de los costados llega por lo menos a una celda (es donde termina la rampa).
	SIDE_GLASS = clampi(saved.side_glass, 1 if HEAD == 1 else CHAMFER, ACROSS - 2)
	ROOF_GLASS = clampi(saved.roof_glass, CHAMFER, ACROSS)
	LIFT_CELLS = clampi(saved.lift_radius, 4, ACROSS * TRAMA_CELLS / 4)
	GLASS_COLOR = Color(saved.glass_color, saved.glass_opacity)
	FRAME_KIND = saved.frame_kind
	EDGE_THICKNESS = saved.edge_thickness
	POST_THICKNESS = saved.post_thickness
	TRAMA = TRAMA_CELLS * CELL
	INNER = ACROSS * 0.5 * TRAMA
	HALF = INNER + WALL
	SIZE = HALF * 2.0
	CLEAR = HEIGHT_CELLS * CELL
	BASE = BASE_CELLS * CELL
	HEIGHT = CLEAR + SLAB * 2.0 + BASE
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
	now.corner_cells = CORNER_CELLS
	now.base_cells = BASE_CELLS
	now.seat_front_cells = SEAT_FRONT_CELLS
	now.seat_spread_cells = SEAT_SPREAD_CELLS
	now.front_height_cells = FRONT_CELLS
	now.sill_cells = SILL_CELLS
	now.lift_radius = LIFT_CELLS
	now.side_glass = SIDE_GLASS
	now.roof_glass = ROOF_GLASS
	now.glass_color = Color(GLASS_COLOR, 1.0)
	now.glass_opacity = GLASS_COLOR.a
	now.frame_kind = FRAME_KIND
	now.edge_thickness = EDGE_THICKNESS
	now.post_thickness = POST_THICKNESS
	now.eye_height = EYE_HEIGHT
	now.arm_length = MechBody.current.arm_size
	now.leg_length = MechBody.current.leg_size
	now.thickness = MechBody.current.thick_size
	now.leg_stretch = MechBody.current.stretch
	now.shoulder_out = MechBody.current.shoulder_out
	return now


## Si la cabeza va en rampa (ver CabinShape.head).
static func ramp() -> bool:
	return HEAD == 1


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
	return -HALF_HEIGHT + BASE + SLAB


## La cara de abajo del techo.
static func ceiling() -> float:
	return HALF_HEIGHT - SLAB


## La celda de trama `index` (0 la de la izquierda, o la del frente), su borde: de −`INNER` a `INNER`.
static func line(index: float) -> float:
	return -INNER + index * TRAMA


## LAS TRES SILLAS DE ADELANTE, en el piso, de izquierda a derecha (el brazo izquierdo, el movimiento, el brazo
## derecho), EN LÍNEA, mirando al frente: a `SEAT_FRONT_CELLS` del vidrio; los brazos a `SEAT_SPREAD_CELLS` de la del
## medio a cada costado (sin pasarse de la pared). Para todas las cuadradas.
static func front_seats() -> Array[Vector3]:
	var y := floor_top()
	var middle := -INNER + SEAT_FRONT_CELLS * CELL
	var spread := minf(SEAT_SPREAD_CELLS * CELL, INNER - 0.4)
	return [Vector3(-spread, y, middle), Vector3(0.0, y, middle), Vector3(spread, y, middle)]


## EL HOMBRO, en el espacio de la caja, sin lo que lo corre hacia afuera (ver Mech.shoulder): en el medio del costado,
## a `SHOULDER_SHARE` del alto libre.
static func shoulder() -> Vector3:
	return Vector3(HALF, floor_top() + CLEAR * SHOULDER_SHARE, 0.0)
