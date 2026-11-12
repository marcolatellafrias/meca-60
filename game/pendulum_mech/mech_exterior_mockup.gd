class_name MechExteriorMockup
extends RefCounted

## MAQUETAS DEL AFUERA DE LA MECA PÉNDULO (12/11/2026), para elegir: cómo se sube de un piso a otro por atrás, la
## pasarela de planta baja y el ascensor de la pelvis. Lo pidió el usuario («empezar a bocetear cómo va a ser la zona de
## escaleras de afuera… la escalera se debería sentir como algo que está encima del cubo, no algo que compite con el
## cubo… la plataforma… lo suficientemente grande como para que pueda caminar un personaje… que dé la vuelta… en planta
## baja desde la parte de la escalera hasta los dos costados… un ascensor cilíndrico que baja… hasta una altura que sea
## cómoda para cuando la meca esté agachada»). ES SÓLO DIBUJO, en el espacio del cubo (el centro en el origen): no se
## camina ni se choca. Lo que se elija pasa a la meca de verdad, con sus formas de choque y su marco.
##
## Todas (menos la base) llevan LO COMÚN: la pasarela en U de planta baja, de atrás a los dos costados, con su baranda;
## dos tableros para reparar en los costados; y el ascensor: un cilindro que cuelga de la pelvis, cuyo piso queda a un
## salto del suelo con la meca agachada y lejos con la meca parada.

const NAMES := [
	"sin nada (la base)",
	"zigzag fino atrás",
	"escaleras marineras y balconcitos",
	"caracol en la esquina de atrás",
	"una pasarela por piso, unidas por marineras",
]
const HALF := HoverCube.SIZE * 0.5
## La pasarela y los balcones: su ancho, y el alto de la baranda.
const WALK := 1.1
const RAIL := 1.05
const BAR := 0.07
## Hasta dónde llega la pasarela por los costados, hacia el frente (z): antes de donde cuelgan los brazos.
const SIDE_END := -2.2
## El ascensor: su radio, y a qué altura queda su piso bajado (en el espacio del cubo; la cara de abajo está en −4).
const LIFT_RADIUS := 0.85
const LIFT_FLOOR := -7.05
const STEEL := Color(0.24, 0.25, 0.28)
const GRATE := Color(0.36, 0.38, 0.41)
const PERSON := Color(0.95, 0.55, 0.2)


## Arma la maqueta `variant` (ver NAMES) colgada de `holder`, que está en el espacio del cubo.
static func build(holder: Node3D, variant: int) -> void:
	if variant == 0:
		return
	_common(holder)
	match variant:
		1:
			_zigzag(holder)
		2:
			_ladders(holder)
		3:
			_spiral(holder)
		4:
			_rings(holder)


static func _floor_y(index: int) -> float:
	return PendulumMech.floor_y(index) + PendulumMech.SLAB * 0.5


## ── LO COMÚN ─────────────────────────────────────────────────────────────────────────────────────────────────────

static func _common(holder: Node3D) -> void:
	_walk_u(holder, _floor_y(0))
	# Dos tableros para reparar, uno en cada costado, a la altura de la pasarela.
	for side: float in [-1.0, 1.0]:
		Clay.box(holder, Vector3(0.18, 1.1, 0.9), Vector3(side * (HALF + 0.09), _floor_y(0) + 1.25, 1.2), Clay.RED)
		Clay.box(holder, Vector3(0.2, 0.2, 0.2), Vector3(side * (HALF + 0.12), _floor_y(0) + 1.25, 1.2), Clay.YELLOW)
	_lift(holder)
	# Uno parado en la pasarela, para la escala.
	_person(holder, Vector3(HALF + WALK * 0.5, _floor_y(0), 2.6))


## LA PASARELA EN U a la altura `y`: atrás, de costado a costado, y por los dos costados hasta `SIDE_END`; con baranda
## por afuera.
static func _walk_u(holder: Node3D, y: float) -> void:
	var outer := HALF + WALK
	_deck(holder, Vector3(-outer, y, HALF), Vector3(outer, y, outer))
	for side: float in [-1.0, 1.0]:
		_deck(holder, Vector3(side * HALF, y, SIDE_END), Vector3(side * outer, y, HALF))
		_rail(holder, Vector3(side * outer, y, SIDE_END), Vector3(side * outer, y, outer))
		_rail(holder, Vector3(side * HALF, y, SIDE_END), Vector3(side * outer, y, SIDE_END))
	_rail(holder, Vector3(-outer, y, outer), Vector3(outer, y, outer))


## EL ASCENSOR: el tubo que cruza la pelvis, y la jaula bajada: su piso redondo, cuatro parantes y un aro.
static func _lift(holder: Node3D) -> void:
	var pelvis_bottom := -HALF - MechBody.PELVIS_SIZE.y
	Clay.cylinder(holder, LIFT_RADIUS + 0.12, 0.5, Vector3(0, pelvis_bottom - 0.25, 0), STEEL)
	Clay.cylinder(holder, LIFT_RADIUS, 0.12, Vector3(0, LIFT_FLOOR, 0), GRATE)
	Clay.cylinder(holder, LIFT_RADIUS + 0.05, 0.08, Vector3(0, LIFT_FLOOR + 1.0, 0), STEEL)
	for corner in 4:
		var at := Basis(Vector3.UP, corner * PI * 0.5 + PI * 0.25) * Vector3(LIFT_RADIUS - 0.05, 0, 0)
		_bar(holder, at + Vector3(0, LIFT_FLOOR, 0), at + Vector3(0, pelvis_bottom, 0))


## ── LAS VARIANTES ────────────────────────────────────────────────────────────────────────────────────────────────

## 1 · ZIGZAG FINO: un balcón por puerta y, por fuera de ellos, un tramo liviano de piso a piso, yendo y viniendo.
static func _zigzag(holder: Node3D) -> void:
	var lane := HALF + WALK
	for index in [1, 2]:
		_balcony(holder, index, 2.9)
	for index in 2:
		var way := 1.0 if index == 0 else -1.0
		var from := Vector3(-way * 2.4, _floor_y(index), lane + 0.45)
		var to := Vector3(way * 2.4, _floor_y(index + 1), lane + 0.45)
		_flight(holder, from, to, 0.9)
		# El paso del balcón al tramo, arriba y abajo.
		_deck(holder, Vector3(way * 2.4 - 0.5, _floor_y(index + 1), lane), Vector3(way * 2.4 + 0.5, _floor_y(index + 1), lane + 0.9))
	_deck(holder, Vector3(-2.9, _floor_y(0), lane), Vector3(-1.9, _floor_y(0), lane + 0.9))


## 2 · MARINERAS: un balconcito por puerta y una escalera vertical de uno al de arriba.
static func _ladders(holder: Node3D) -> void:
	for index in [1, 2]:
		_balcony(holder, index, 1.4)
	for index in 2:
		var x := 1.05 if index == 0 else -1.05
		_ladder(holder, Vector3(x, _floor_y(index), HALF + 0.12), _floor_y(index + 1) + RAIL)


## 3 · CARACOL: una jaula redonda en una esquina de atrás, de planta baja al último piso, con un puentecito a cada puerta.
static func _spiral(holder: Node3D) -> void:
	var centre := Vector3(HALF - 1.2, 0.0, HALF + 1.25)
	var radius := 1.15
	var bottom := _floor_y(0)
	var top := _floor_y(2)
	_bar(holder, Vector3(centre.x, bottom, centre.z), Vector3(centre.x, top + RAIL, centre.z), 0.16)
	var steps := roundi((top - bottom) / 0.21)
	for step in steps + 1:
		var turn := Basis(Vector3.UP, step * deg_to_rad(26.0))
		var out := turn * Vector3(radius, 0, 0)
		var y := bottom + (top - bottom) * step / steps
		var tread := Clay.box(holder, Vector3(radius, 0.05, 0.34), Vector3.ZERO, GRATE)
		tread.transform = Transform3D(turn, centre + Vector3(0, y, 0) + out * 0.5)
	for post in 6:
		var at := centre + Basis(Vector3.UP, post * PI / 3.0) * Vector3(radius + 0.06, 0, 0)
		_bar(holder, Vector3(at.x, bottom, at.z), Vector3(at.x, top + RAIL, at.z))
	for index in [1, 2]:
		Clay.cylinder(holder, radius + 0.1, 0.07, Vector3(centre.x, _floor_y(index) + RAIL, centre.z), STEEL)
		_balcony(holder, index, 1.4)
		_deck(holder, Vector3(1.4, _floor_y(index), HALF), Vector3(centre.x - radius * 0.6, _floor_y(index), HALF + WALK))


## 4 · UNA PASARELA POR PISO: la U de planta baja repetida en los otros dos, unidas por marineras en las esquinas de atrás.
static func _rings(holder: Node3D) -> void:
	for index in [1, 2]:
		_walk_u(holder, _floor_y(index))
	for index in 2:
		var x := (HALF + WALK * 0.5) * (1.0 if index == 0 else -1.0)
		_ladder(holder, Vector3(x, _floor_y(index), HALF + WALK - 0.15), _floor_y(index + 1) + RAIL)
	_person(holder, Vector3(-HALF - WALK * 0.5, _floor_y(1), 1.5))


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## Un balcón delante de la puerta del piso `index`, de `half_width` a cada lado, con su baranda.
static func _balcony(holder: Node3D, index: int, half_width: float) -> void:
	var y := _floor_y(index)
	var outer := HALF + WALK
	_deck(holder, Vector3(-half_width, y, HALF), Vector3(half_width, y, outer))
	_rail(holder, Vector3(-half_width, y, outer), Vector3(half_width, y, outer))
	for side: float in [-1.0, 1.0]:
		_rail(holder, Vector3(side * half_width, y, HALF), Vector3(side * half_width, y, outer))


## Un piso de rejilla, fino, entre dos esquinas opuestas (a la misma altura).
static func _deck(holder: Node3D, from: Vector3, to: Vector3) -> void:
	var size := Vector3(absf(to.x - from.x), 0.07, absf(to.z - from.z))
	Clay.box(holder, size, Vector3((from.x + to.x) * 0.5, from.y - 0.035, (from.z + to.z) * 0.5), GRATE)


## Una baranda de `from` a `to` (por el piso): el pasamanos, una barra al medio y los parantes.
static func _rail(holder: Node3D, from: Vector3, to: Vector3) -> void:
	var up := Vector3.UP * RAIL
	_bar(holder, from + up, to + up)
	_bar(holder, from + up * 0.5, to + up * 0.5, BAR * 0.7)
	var posts := maxi(roundi(from.distance_to(to) / 1.3), 1)
	for post in posts + 1:
		var at := from.lerp(to, float(post) / posts)
		_bar(holder, at, at + up)


## Un tramo de escalera de `from` a `to`: dos zancas, los escalones y la baranda de afuera.
static func _flight(holder: Node3D, from: Vector3, to: Vector3, width: float) -> void:
	var side := Vector3(0, 0, width * 0.5)
	for edge: float in [-1.0, 1.0]:
		_bar(holder, from + side * edge, to + side * edge, 0.1)
	var steps := roundi((to.y - from.y) / 0.21)
	for step in range(1, steps):
		var at := from.lerp(to, float(step) / steps)
		Clay.box(holder, Vector3(0.3, 0.05, width), at, GRATE)
	_bar(holder, from + side + Vector3.UP * RAIL, to + side + Vector3.UP * RAIL)
	for post in 4:
		var at := from.lerp(to, post / 3.0) + side
		_bar(holder, at, at + Vector3.UP * RAIL)


## Una escalera vertical desde `foot` hasta la altura `top`: dos largueros y los peldaños.
static func _ladder(holder: Node3D, foot: Vector3, top: float) -> void:
	for edge: float in [-1.0, 1.0]:
		_bar(holder, foot + Vector3(edge * 0.28, 0, 0), Vector3(foot.x + edge * 0.28, top, foot.z))
	var rung := foot.y + 0.3
	while rung < top - 0.1:
		_bar(holder, Vector3(foot.x - 0.28, rung, foot.z), Vector3(foot.x + 0.28, rung, foot.z), BAR * 0.7)
		rung += 0.32


## Una barra entre dos puntos.
static func _bar(holder: Node3D, from: Vector3, to: Vector3, thickness := BAR) -> void:
	var bar := Clay.box(holder, Vector3(thickness, thickness, from.distance_to(to)), Vector3.ZERO, STEEL)
	bar.transform = MechBody.segment(from, to, Vector3.UP)


## Uno de 1,8 m parado en `feet`, para la escala.
static func _person(holder: Node3D, feet: Vector3) -> void:
	Clay.cylinder(holder, 0.24, 1.35, feet + Vector3(0, 0.675, 0), PERSON)
	Clay.sphere(holder, 0.22, feet + Vector3(0, 1.58, 0), PERSON)
