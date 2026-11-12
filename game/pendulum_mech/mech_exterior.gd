class_name MechExterior
extends RefCounted

## EL AFUERA DE LA MECA PÉNDULO: por dónde se anda por fuera del cubo. Lo pidió el usuario el 12/11/2026 («la zona de
## escaleras de afuera… la escalera se debería sentir como algo que está encima del cubo, no algo que compite con el
## cubo… la plataforma… que dé la vuelta… en planta baja desde la parte de la escalera hasta los dos costados») y eligió
## entre cinco maquetas la del ZIGZAG FINO («vamos con la opción 2»; las otras —marineras, caracol, una pasarela por
## piso— se borraron).
##
##   · LA PASARELA EN U de planta baja: atrás, de costado a costado, y por los dos costados hasta antes de donde cuelgan
##     los brazos (`SIDE_END`), con baranda por afuera.
##   · Atrás, UN BALCÓN por puerta de los pisos de arriba y, por fuera de ellos, UN TRAMO LIVIANO de piso a piso, yendo y
##     viniendo.
##   · DOS TABLEROS para reparar, uno en cada costado, a la altura de la pasarela (dibujo, por ahora).
##
## Todo de barras y rejilla finas. SE CAMINA: cada piso, cada tramo (una rampa) y cada baranda le agrega su forma de
## choque a `solid`, el cuerpo de las formas de adentro de la meca, del que su marco copia la sombra (ver PendulumMech).
## En el espacio del cubo (el centro en el origen).

const HALF := HoverCube.SIZE * 0.5
## La pasarela y los balcones: su ancho, y el alto de la baranda.
const WALK := 1.1
const RAIL := 1.05
const BAR := 0.07
## Hasta dónde llega la pasarela por los costados, hacia el frente (z): antes de donde cuelgan los brazos.
const SIDE_END := -2.2
## Los tramos: su ancho, dónde va su eje (z) y hasta dónde llegan a cada lado (x).
const FLIGHT := 0.9
const FLIGHT_Z := HALF + WALK + FLIGHT * 0.5
const FLIGHT_X := 2.4
const BALCONY := 2.9
const STEEL := Color(0.24, 0.25, 0.28)
const GRATE := Color(0.36, 0.38, 0.41)


## Lo arma colgado de `holder` (el dibujo) y `solid` (sus formas de choque).
static func build(holder: Node3D, solid: PhysicsBody3D) -> void:
	var ground := _floor_y(0)
	var outer := HALF + WALK
	# LA PASARELA EN U.
	_deck(holder, solid, Vector3(-outer, ground, HALF), Vector3(outer, ground, outer))
	for side: float in [-1.0, 1.0]:
		_deck(holder, solid, Vector3(side * HALF, ground, SIDE_END), Vector3(side * outer, ground, HALF))
		_rail(holder, solid, Vector3(side * outer, ground, SIDE_END), Vector3(side * outer, ground, outer))
		_rail(holder, solid, Vector3(side * HALF, ground, SIDE_END), Vector3(side * outer, ground, SIDE_END))
		# Un tablero para reparar.
		Clay.box(holder, Vector3(0.18, 1.1, 0.9), Vector3(side * (HALF + 0.09), ground + 1.25, 1.2), Clay.RED)
		Clay.box(holder, Vector3(0.2, 0.2, 0.2), Vector3(side * (HALF + 0.12), ground + 1.25, 1.2), Clay.YELLOW)
	# La baranda de atrás de la pasarela, con el hueco por donde arranca el primer tramo.
	_rail(holder, solid, Vector3(-outer, ground, outer), Vector3(-FLIGHT_X - 0.5, ground, outer))
	_rail(holder, solid, Vector3(-FLIGHT_X + 0.5, ground, outer), Vector3(outer, ground, outer))
	# LOS BALCONES de los pisos de arriba, con el hueco de su baranda donde llega y donde sale un tramo.
	for index in [1, 2]:
		var y := _floor_y(index)
		_deck(holder, solid, Vector3(-BALCONY, y, HALF), Vector3(BALCONY, y, outer))
		for side: float in [-1.0, 1.0]:
			_rail(holder, solid, Vector3(side * BALCONY, y, HALF), Vector3(side * BALCONY, y, outer))
		_rail(holder, solid, Vector3(-FLIGHT_X + 0.5, y, outer), Vector3(FLIGHT_X - 0.5, y, outer))
	# LOS TRAMOS, yendo y viniendo, con el descanso donde empiezan y donde llegan.
	for index in 2:
		var way := 1.0 if index == 0 else -1.0
		var from := Vector3(-way * FLIGHT_X, _floor_y(index), FLIGHT_Z)
		var to := Vector3(way * FLIGHT_X, _floor_y(index + 1), FLIGHT_Z)
		_flight(holder, solid, from, to, way)
		for end: Vector3 in [from, to]:
			_deck(holder, solid, Vector3(end.x - 0.5, end.y, outer), Vector3(end.x + 0.5, end.y, outer + FLIGHT))
			var beyond := end.x + signf(end.x) * 0.5
			_rail(holder, solid, Vector3(beyond, end.y, outer), Vector3(beyond, end.y, outer + FLIGHT))
			_rail(holder, solid, Vector3(end.x - 0.5, end.y, outer + FLIGHT), Vector3(end.x + 0.5, end.y, outer + FLIGHT))


## Hasta dónde llega todo esto, en el espacio del cubo: para el volumen del marco.
static func bounds() -> AABB:
	var outer := HALF + WALK + 0.25
	return AABB(Vector3(-outer, -HALF - 0.3, SIDE_END - 0.3), Vector3(outer * 2.0, HoverCube.SIZE + 2.4,
		HALF + WALK + FLIGHT + 0.3 - SIDE_END + 0.3))


static func _floor_y(index: int) -> float:
	return PendulumMech.floor_y(index) + PendulumMech.SLAB * 0.5


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## Un piso de rejilla, fino, entre dos esquinas opuestas (a la misma altura).
static func _deck(holder: Node3D, solid: PhysicsBody3D, from: Vector3, to: Vector3) -> void:
	var size := Vector3(absf(to.x - from.x), 0.07, absf(to.z - from.z))
	var at := Vector3((from.x + to.x) * 0.5, from.y - 0.035, (from.z + to.z) * 0.5)
	Clay.box(holder, size, at, GRATE)
	Clay.shape_box(solid, size, at)


## Una baranda de `from` a `to` (por el piso): el pasamanos, una barra al medio y los parantes; y una pared fina que no
## deja caerse.
static func _rail(holder: Node3D, solid: PhysicsBody3D, from: Vector3, to: Vector3) -> void:
	var up := Vector3.UP * RAIL
	_bar(holder, from + up, to + up)
	_bar(holder, from + up * 0.5, to + up * 0.5, BAR * 0.7)
	var posts := maxi(roundi(from.distance_to(to) / 1.3), 1)
	for post in posts + 1:
		var at := from.lerp(to, float(post) / posts)
		_bar(holder, at, at + up)
	var along := MechBody.segment(from, to, Vector3.UP)
	Clay.shape_box(solid, Vector3(0.1, RAIL, from.distance_to(to)), along.origin + up * 0.5, along.basis)


## Un tramo de escalera de `from` a `to`: dos zancas, los escalones y la baranda de afuera; se camina como una rampa.
## `way`: hacia qué lado sube (x).
static func _flight(holder: Node3D, solid: PhysicsBody3D, from: Vector3, to: Vector3, way: float) -> void:
	var side := Vector3(0, 0, FLIGHT * 0.5)
	for edge: float in [-1.0, 1.0]:
		_bar(holder, from + side * edge, to + side * edge, 0.1)
	var steps := roundi((to.y - from.y) / 0.21)
	for step in range(1, steps):
		Clay.box(holder, Vector3(0.3, 0.05, FLIGHT), from.lerp(to, float(step) / steps), GRATE)
	_bar(holder, from + side + Vector3.UP * RAIL, to + side + Vector3.UP * RAIL)
	for post in 4:
		var at := from.lerp(to, post / 3.0) + side
		_bar(holder, at, at + Vector3.UP * RAIL)
	# La rampa, y la pared fina de su baranda de afuera. Un poco más larga que el tramo, para empalmar con los descansos.
	var low := from - Vector3(way * 0.25, 0.0, 0.0)
	var high := to + Vector3(way * 0.25, 0.0, 0.0)
	var slope := MechBody.segment(low, high, Vector3.UP)
	Clay.shape_box(solid, Vector3(FLIGHT, 0.1, low.distance_to(high)), slope.origin - slope.basis.y * 0.05, slope.basis)
	Clay.shape_box(solid, Vector3(0.1, RAIL, low.distance_to(high)), slope.origin + side + Vector3.UP * RAIL * 0.5, slope.basis)


## Una barra entre dos puntos (dibujo).
static func _bar(holder: Node3D, from: Vector3, to: Vector3, thickness := BAR) -> void:
	var bar := Clay.box(holder, Vector3(thickness, thickness, from.distance_to(to)), Vector3.ZERO, STEEL)
	bar.transform = MechBody.segment(from, to, Vector3.UP)
