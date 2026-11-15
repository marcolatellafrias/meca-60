class_name RoundGrid
extends RefCounted

## LA MECA REDONDA EN NÚMEROS (el usuario, 15/11/2026: «haremos que esta versión cilíndrica sea paramétrica también…
## para no pisar lo de la cuadrada… un fork en otra parcela»). Como CabinGrid para la cuadrada: de acá sale todo, y se
## cambia jugando (el F2 de la fila «Meca redonda», RoundShapePanel). Ver RoundCabin, docs/technical/cabina-redonda.md.
##   · ADENTRO, `SIDES` LADOS PLANOS; AFUERA, UN CILINDRO LISO. Ejes como la cuadrada: X a la derecha, Y arriba, −Z al
##     frente; el origen en el centro de la caja. Los lados se cuentan desde el del frente (0), a la derecha.
##   · DE ABAJO A ARRIBA: el disco (`DISC`), la losa del piso, la cabina (`CLEAR` libres) y la losa del techo.
##   · LA TARIMA, al centro, con un escalón todo alrededor; el ascensor, corrido atrás (`LIFT_BACK`), dentro de ella.
##   · LAS SILLAS: tres adelante, cada una en su lado, mirando hacia afuera (siguen al cilindro); la del movimiento, en la
##     tarima, delante del ascensor.

## Dónde se guarda la forma (la escribe el panel F2; no se sube al repositorio).
const SAVED := "res://game/mech/round/round_shape.tres"
## El espesor de la pared (del lado de adentro a la piel de afuera, en el medio de un lado) y de las losas.
const WALL := 0.22
const SLAB := 0.22
## El escalón de alrededor de la tarima: su ancho (m).
const STEP := 0.3
## Las sillas de adelante: a cuánto de la pared, en el medio de su lado (m).
const SEAT_IN := 0.95
## La silla del movimiento: a cuánto del borde del ascensor, hacia adelante (de centro a borde, m).
const SEAT_GAP := 0.5
## Los hombros: a qué parte del alto libre.
const SHOULDER_SHARE := 0.55

static var SIDES := 12
static var RADIUS := 3.55
static var CLEAR := 2.3
static var DISC := 1.0
## El domo de arriba (ver RoundShape.dome): si va, y su alto sobre el borde de las paredes.
static var DOME := false
static var DOME_TALL := 1.8
static var PLATFORM_R := 1.35
static var PLATFORM_TALL := 0.3
static var LIFT_R := 0.5
static var LIFT_BACK := 0.7
static var GLASS_SIDES := 5
static var GLASS_COLOR := Color(0.6, 0.8, 0.92, 0.14)
## Lo que sale: la distancia del centro al medio de un lado de adentro, el radio de afuera y el alto de la caja.
static var APOTHEM := 0.0
static var OUTER := 0.0
static var HEIGHT := 0.0
static var HALF_HEIGHT := 0.0


static func _static_init() -> void:
	var saved := load(SAVED) as RoundShape if ResourceLoader.exists(SAVED) else null
	apply(saved if saved != null else RoundShape.new())


## TOMA LA FORMA. Las mecas que ya estaban no cambian: hay que rearmarlas (ver RoundShapePanel).
static func apply(saved: RoundShape) -> void:
	SIDES = maxi(saved.sides, 6) / 2 * 2
	RADIUS = saved.radius
	CLEAR = saved.clear_height
	DISC = saved.disc_height
	DOME = saved.dome
	DOME_TALL = saved.dome_height
	APOTHEM = RADIUS * cos(PI / SIDES)
	OUTER = APOTHEM + WALL
	PLATFORM_TALL = saved.platform_height
	LIFT_R = saved.lift_radius
	# La tarima no llega a las sillas de adelante; el ascensor queda dentro de la tarima.
	PLATFORM_R = clampf(saved.platform_radius, 0.6, APOTHEM - SEAT_IN - 0.6)
	LIFT_BACK = clampf(saved.lift_back, 0.0, maxf(PLATFORM_R * cos(PI / SIDES) - LIFT_R - 0.1, 0.0))
	GLASS_SIDES = clampi(saved.glass_sides, 1, SIDES - 1) / 2 * 2 + 1
	GLASS_COLOR = Color(saved.glass_color, saved.glass_opacity)
	# La caja: el disco, el piso, la cabina y, arriba, el techo o el domo.
	HEIGHT = DISC + SLAB + CLEAR + (DOME_TALL if DOME else SLAB)
	HALF_HEIGHT = HEIGHT * 0.5


## La forma de hoy, para guardarla.
static func current() -> RoundShape:
	var now := RoundShape.new()
	now.sides = SIDES
	now.radius = RADIUS
	now.clear_height = CLEAR
	now.disc_height = DISC
	now.dome = DOME
	now.dome_height = DOME_TALL
	now.platform_radius = PLATFORM_R
	now.platform_height = PLATFORM_TALL
	now.lift_radius = LIFT_R
	now.lift_back = LIFT_BACK
	now.glass_sides = GLASS_SIDES
	now.glass_color = Color(GLASS_COLOR, 1.0)
	now.glass_opacity = GLASS_COLOR.a
	return now


## La caja entera (la del cuerpo, que choca con el mundo): el cilindro, en su caja.
static func box() -> Vector3:
	return Vector3(OUTER * 2.0, HEIGHT, OUTER * 2.0)


## Donde se pisa adentro, y la cara de abajo del techo.
static func floor_top() -> float:
	return -HALF_HEIGHT + DISC + SLAB


static func ceiling() -> float:
	return floor_top() + CLEAR


## Un punto a `distance` del centro, hacia el ángulo `angle` (0 al frente, positivo a la derecha), a la altura `y`.
static func at(distance: float, angle: float, y: float) -> Vector3:
	return Vector3(sin(angle) * distance, y, -cos(angle) * distance)


## El ángulo del medio del lado `side` (0 el del frente, a la derecha).
static func side_angle(side: int) -> float:
	return TAU * side / SIDES


## El borde de un polígono de `SIDES` lados de radio (a los vértices) `radius`, en `per_side` puntos por lado, con un
## lado plano al frente: para las placas. Los vértices caen justo en los puntos.
static func polygon(radius: float, per_side := 4) -> PackedVector2Array:
	var apothem := radius * cos(PI / SIDES)
	var points := PackedVector2Array()
	var count := SIDES * per_side
	for step in count:
		var angle := PI / SIDES + TAU * step / count
		var nearest := roundf(angle / (TAU / SIDES)) * TAU / SIDES
		var reach := apothem / cos(angle - nearest)
		points.append(Vector2(sin(angle) * reach, -cos(angle) * reach))
	return points


## Un círculo de `radius` con centro en `center`, en los mismos ángulos que `polygon`.
static func circle(radius: float, center := Vector2.ZERO, per_side := 4) -> PackedVector2Array:
	var points := PackedVector2Array()
	var count := SIDES * per_side
	for step in count:
		var angle := PI / SIDES + TAU * step / count
		points.append(center + Vector2(sin(angle), -cos(angle)) * radius)
	return points


## LAS TRES SILLAS DE ADELANTE: en los lados −1, 0 y 1, a `SEAT_IN` de la pared, mirando hacia afuera. [lugar, giro]
static func front_seats() -> Array:
	var all := []
	for side in [-1, 0, 1]:
		var angle := side_angle(side)
		all.append([at(APOTHEM - SEAT_IN, angle, floor_top()), -angle])
	return all


## LA SILLA DEL MOVIMIENTO, en la tarima, delante del ascensor.
static func top_seat() -> Vector3:
	return Vector3(0.0, floor_top() + PLATFORM_TALL, LIFT_BACK - LIFT_R - SEAT_GAP)


## EL HOMBRO (sin lo que lo corre afuera, ver Mech.cabin_kit): en el costado, a `SHOULDER_SHARE` del alto libre.
static func shoulder() -> Vector3:
	return Vector3(OUTER, floor_top() + CLEAR * SHOULDER_SHARE, 0.0)
