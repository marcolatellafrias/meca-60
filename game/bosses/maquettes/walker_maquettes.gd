class_name WalkerMaquettes
extends RefCounted

## LOS JEFES RECORRIBLES (15/11/2026): dos maquetas de arcilla, quietas, una de seis patas y una de cuatro. El usuario:
## «tienen que tener algo de recorrido, algo de interés… una silueta más o menos simple»; «una de 6 patas y otra de 4»;
## «varios puntos débiles… las baterías y los componentes que se dan a ver solamente a veces y… si vos estás a pie tenés
## que timear para cuando esté abierta una compuerta… y sacarlo».
##
## LA SILUETA ES SIMPLE (un casco sobre patas), PERO EL CUERPO ES UN LUGAR: cubiertas, pasarelas con baranda, escaleras
## y rampas, a la escala de una persona. Se llega tirándose desde el edificio de al lado.
## LOS PUNTOS DÉBILES SON BATERÍAS DETRÁS DE COMPUERTAS: cerradas casi siempre; se abren un rato después de un ataque
## fuerte suyo (el estado de la derecha). Cada una mueve una parte: la de una pata, la del cañón; y el núcleo. La
## compuerta grande del frente, a la altura de la meca, es la de la meca; las chicas, de a pie.
## El recorrido, en celeste: de dónde se tira uno, por dónde camina y adónde llega.
##   *Lo que se pensó y todavía no se ve: subido, al rato se sacude (hay que agarrarse o bajarse); si la meca se queda
##   pegada mucho tiempo, carga un pulso alrededor que la aleja.*

const HATCH := Color(0.85, 0.62, 0.12)
const DECK := Color(0.4, 0.42, 0.45)
const RAIL := Color(0.25, 0.26, 0.28)
const ROUTE := Color(0.35, 0.75, 1.0)
## Una batería, del tamaño de la de los recursos (SupplyLook: un cubo de 63 cm), un poco más grande para que se vea.
const BATTERY := 1.0

const HEXAPOD_LINES := [
	"una plataforma larga en seis patas: cubierta arriba, una pasarela de cada lado, la cabina adelante y una torre",
	"se sube tirándose del edificio a la cubierta de atrás (la plataforma de luz); de ahí, escaleras a todo",
	"PUNTOS DÉBILES: una batería por pata, detrás de una compuerta en la pasarela de su lado (seis); la del cañón, en la cubierta; el núcleo, arriba de la torre",
	"y la compuerta grande del frente, a la altura de la meca",
	"se abren después del pisotón; subido, al rato se sacude; con la meca encima mucho rato, un pulso la aleja",
]
const QUADRUPED_LINES := [
	"un bastión alto en cuatro patas: un casco con una pasarela alrededor, un segundo piso y la torreta arriba",
	"se sube tirándose del edificio a la cubierta; una rampa baja a la pasarela de alrededor, una escalera sube a la torreta",
	"PUNTOS DÉBILES: una batería por pata, en la pasarela de alrededor (cuatro); la del cañón, a los costados del segundo piso; el núcleo, arriba de la torreta",
	"y la compuerta grande del pecho, a la altura de la meca",
	"se abren después del cañonazo; subido, al rato se sacude; con la meca encima mucho rato, un pulso la aleja",
]


## ── EL HEXÁPODO PLATAFORMA ───────────────────────────────────────────────────────────────────────────────────────

static func hexapod(p: Node3D, open: bool) -> void:
	# El casco: de 16 a 26 m de alto, 18 de ancho y 50 de largo (adelante, −Z).
	Clay.box(p, Vector3(18.0, 10.0, 50.0), Vector3(0.0, 21.0, 0.0), BossMaquettes.HULL)
	Clay.box(p, Vector3(18.4, 0.4, 36.0), Vector3(0.0, 26.2, 7.0), DECK)
	# La cabina de adelante, con el cañón arriba.
	Clay.box(p, Vector3(14.0, 8.0, 12.0), Vector3(0.0, 30.0, -17.0), BossMaquettes.HULL.lightened(0.08))
	Clay.cylinder(p, 3.0, 2.0, Vector3(0.0, 35.0, -17.0), Clay.DARK)
	BossMaquettes._rod(p, Vector3(0.0, 35.0, -18.0), Vector3(0.0, 36.0, -32.0), 0.9, Clay.DARK)
	Clay.box(p, Vector3(10.0, 2.0, 0.3), Vector3(0.0, 31.0, -23.1), Clay.GLASS)
	# La torre del medio, con su escalera; arriba, el núcleo.
	Clay.cylinder(p, 3.5, 14.0, Vector3(0.0, 33.0, 6.0), BossMaquettes.HULL.lightened(0.05))
	_ladder(p, Vector3(0.0, 26.4, 9.5), Vector3(0.0, 40.0, 9.5), Vector3.BACK)
	_hatch(p, Vector3(0.0, 40.0, 6.0), Vector3.UP, 2.4, open)
	_railing_loop(p, [Vector3(-3.0, 40.0, 3.0), Vector3(3.0, 40.0, 3.0), Vector3(3.0, 40.0, 9.0), Vector3(-3.0, 40.0, 9.0)])
	# La cubierta de atrás, más baja, donde se cae: la plataforma de luz.
	Clay.box(p, Vector3(16.0, 2.0, 8.0), Vector3(0.0, 21.0, 29.0), DECK)
	Clay.box(p, Vector3(6.0, 0.1, 4.0), Vector3(0.0, 22.05, 29.5), Color(0.55, 0.85, 1.0, 0.6))
	_ladder(p, Vector3(4.0, 22.0, 25.3), Vector3(4.0, 26.4, 25.3), Vector3.BACK)
	_railing_loop(p, [Vector3(-8.0, 22.0, 25.0), Vector3(-8.0, 22.0, 33.0), Vector3(8.0, 22.0, 33.0), Vector3(8.0, 22.0, 25.0)], false)
	# La cubierta de arriba: barandas a los lados y la batería del cañón en el piso.
	for side: float in [-1.0, 1.0]:
		_railing(p, Vector3(side * 9.0, 26.4, -11.0), Vector3(side * 9.0, 26.4, 25.0))
	_hatch(p, Vector3(-4.5, 26.4, 0.0), Vector3.UP, 2.0, open)
	# Las pasarelas de los costados, más abajo, con una batería por pata detrás de su compuerta.
	for side: float in [-1.0, 1.0]:
		Clay.box(p, Vector3(2.4, 0.4, 44.0), Vector3(side * 10.2, 20.0, 0.0), DECK)
		_railing(p, Vector3(side * 11.3, 20.2, -22.0), Vector3(side * 11.3, 20.2, 22.0))
		_ladder(p, Vector3(side * 9.3, 20.2, 16.0 * side), Vector3(side * 9.3, 26.4, 16.0 * side), Vector3(side, 0.0, 0.0))
		for z: float in [-16.0, 0.0, 16.0]:
			_hatch(p, Vector3(side * 9.0, 23.0, z + 4.0), Vector3(side, 0.0, 0.0), 2.0, open)
			# La pata: de debajo del casco hacia afuera, rodilla alta y el pie lejos.
			var hip := Vector3(side * 8.0, 16.5, z)
			var knee := Vector3(side * 21.0, 25.0, z * 1.15)
			var foot := Vector3(side * 28.0, 0.0, z * 1.3)
			Clay.box(p, Vector3(5.0, 4.0, 5.0), hip + Vector3.DOWN, BossMaquettes.HULL.darkened(0.2))
			BossMaquettes._rod(p, hip, knee, 1.8, Clay.DARK)
			Clay.sphere(p, 2.4, knee, Clay.DARK.lightened(0.1))
			BossMaquettes._rod(p, knee, foot + Vector3.UP * 1.5, 1.5, Clay.DARK)
			Clay.cylinder(p, 3.2, 1.5, foot + Vector3.UP * 0.75, Clay.DARK)
	# La compuerta grande del frente, para la meca.
	_hatch(p, Vector3(0.0, 20.0, -25.0), Vector3.FORWARD, 6.0, open)
	# El edificio para tirarse, y el recorrido.
	_building(p, Vector3(-16.0, 0.0, 50.0), 36.0)
	_route(p, [Vector3(-16.0, 36.2, 50.0), Vector3(-8.0, 34.0, 38.0), Vector3(0.0, 22.2, 29.5), Vector3(4.0, 22.2, 26.5),
		Vector3(4.0, 26.6, 24.0), Vector3(4.0, 26.6, 16.0), Vector3(8.0, 26.6, 16.0), Vector3(10.2, 20.4, 16.0),
		Vector3(10.2, 20.4, -12.0)])
	_route(p, [Vector3(4.0, 26.6, 16.0), Vector3(0.0, 26.6, 11.0), Vector3(0.0, 40.2, 10.0), Vector3(0.0, 40.2, 7.5)])
	_person(p, Vector3(10.2, 20.2, -12.0))
	_person(p, Vector3(0.0, 40.0, 8.0))
	if open:
		BossMaquettes._ring(p, 34.0, Vector3.ZERO)


## ── EL CUADRÚPEDO BASTIÓN ────────────────────────────────────────────────────────────────────────────────────────

static func quadruped(p: Node3D, open: bool) -> void:
	# El casco: de 19 a 29 m, 20 de ancho y 30 de largo; arriba, la cubierta.
	Clay.box(p, Vector3(20.0, 10.0, 30.0), Vector3(0.0, 24.0, 0.0), BossMaquettes.HULL)
	Clay.box(p, Vector3(20.4, 0.4, 30.4), Vector3(0.0, 29.2, 0.0), DECK)
	# El segundo piso y la torreta, con su cañón.
	Clay.box(p, Vector3(14.0, 8.0, 16.0), Vector3(0.0, 33.4, 4.0), BossMaquettes.HULL.lightened(0.08))
	Clay.cylinder(p, 4.5, 4.0, Vector3(0.0, 39.4, 4.0), BossMaquettes.HULL.lightened(0.15))
	BossMaquettes._rod(p, Vector3(0.0, 39.5, 0.0), Vector3(0.0, 40.5, -18.0), 1.1, Clay.DARK)
	_ladder(p, Vector3(0.0, 29.4, 12.3), Vector3(0.0, 37.4, 12.3), Vector3.BACK)
	_ladder(p, Vector3(2.0, 37.4, 8.6), Vector3(2.0, 41.4, 8.6), Vector3.BACK)
	_hatch(p, Vector3(0.0, 41.4, 4.0), Vector3.UP, 2.4, open)
	for side: float in [-1.0, 1.0]:
		_hatch(p, Vector3(side * 7.0, 31.8, 4.0), Vector3(side, 0.0, 0.0), 2.0, open)
	# Barandas en la cubierta: el frente abierto y los costados.
	_railing(p, Vector3(-10.0, 29.4, -15.0), Vector3(10.0, 29.4, -15.0))
	_railing(p, Vector3(-10.0, 29.4, -15.0), Vector3(-10.0, 29.4, 15.0))
	_railing(p, Vector3(-10.0, 29.4, 15.0), Vector3(10.0, 29.4, 15.0))
	# La pasarela de alrededor, más abajo; una rampa de la cubierta a ella por la derecha.
	var walk := 21.0
	for side: float in [-1.0, 1.0]:
		Clay.box(p, Vector3(2.4, 0.4, 34.8), Vector3(side * 11.2, walk, 0.0), DECK)
		Clay.box(p, Vector3(20.0, 0.4, 2.4), Vector3(0.0, walk, side * 16.2), DECK)
	_railing_loop(p, [Vector3(-12.4, walk + 0.2, -17.4), Vector3(12.4, walk + 0.2, -17.4),
		Vector3(12.4, walk + 0.2, 17.4), Vector3(-12.4, walk + 0.2, 17.4)])
	_plank(p, Vector3(14.0, walk + 0.2, 14.0), Vector3(14.0, 29.4, -6.0), 2.4)
	Clay.box(p, Vector3(4.6, 0.4, 3.0), Vector3(12.3, 29.2, -7.5), DECK)
	# Las patas: columnas gruesas, la rodilla para atrás; una batería por pata, en la pasarela.
	for x: float in [-1.0, 1.0]:
		for z: float in [-1.0, 1.0]:
			var hip := Vector3(x * 9.0, 19.5, z * 12.0)
			var knee := Vector3(x * 17.0, 13.0, z * 17.0)
			var foot := Vector3(x * 18.0, 0.0, z * 19.0)
			Clay.box(p, Vector3(6.0, 5.0, 6.0), hip, BossMaquettes.HULL.darkened(0.2))
			BossMaquettes._rod(p, hip, knee, 2.6, Clay.DARK)
			Clay.sphere(p, 3.0, knee, Clay.DARK.lightened(0.1))
			BossMaquettes._rod(p, knee, foot + Vector3.UP * 2.0, 2.3, Clay.DARK)
			Clay.cylinder(p, 4.0, 2.0, foot + Vector3.UP, Clay.DARK)
			_hatch(p, Vector3(x * 10.0, 23.5, z * 10.0), Vector3(x, 0.0, 0.0), 2.0, open)
	# La compuerta grande del pecho, para la meca.
	_hatch(p, Vector3(0.0, 23.5, -15.0), Vector3.FORWARD, 6.0, open)
	_building(p, Vector3(-28.0, 0.0, 30.0), 42.0)
	_route(p, [Vector3(-28.0, 42.2, 30.0), Vector3(-16.0, 38.0, 18.0), Vector3(-5.0, 29.6, 10.0), Vector3(-5.0, 29.6, -8.0),
		Vector3(12.3, 29.6, -7.5), Vector3(14.0, 21.4, 14.0), Vector3(11.2, 21.4, 16.2), Vector3(-11.2, 21.4, 16.2),
		Vector3(-11.2, 21.4, -10.0)])
	_route(p, [Vector3(-5.0, 29.6, 10.0), Vector3(0.0, 29.6, 13.0), Vector3(0.0, 37.6, 13.0), Vector3(2.0, 37.6, 10.0),
		Vector3(2.0, 41.6, 9.0), Vector3(0.0, 41.6, 6.5)])
	_person(p, Vector3(-11.2, 21.2, -10.0))
	_person(p, Vector3(0.0, 41.4, 6.5))
	if open:
		BossMaquettes._zone(p, 8.0, Vector3(0.0, 0.0, -60.0))


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## UNA COMPUERTA en `at`, en una cara que mira a `out`, de `size` de lado. Cerrada, una tapa al ras; abierta, la tapa
## volcada hacia afuera (bisagra arriba) y la batería que brilla a la vista.
static func _hatch(p: Node3D, at: Vector3, out: Vector3, size: float, open: bool) -> void:
	var along := Vector3.UP if absf(out.y) < 0.9 else Vector3.FORWARD
	var right := along.cross(out).normalized()
	var up := out.cross(right).normalized()
	var frame := Clay.box(p, Vector3(size + 0.6, size + 0.6, 0.2), at + out * 0.05, Clay.DARK)
	frame.basis = Basis(right, up, out)
	if not open:
		var lid := Clay.box(p, Vector3(size, size, 0.35), at + out * 0.2, HATCH)
		lid.basis = Basis(right, up, out)
		return
	var lid := Clay.box(p, Vector3(size, size, 0.35), at + up * size * 0.5 + out * size * 0.5, HATCH.darkened(0.2))
	lid.basis = Basis(right, out, -up)
	var cell := minf(size * 0.6, BATTERY * (2.0 if size > 4.0 else 1.0))
	var battery := Clay.box(p, Vector3(cell, cell, cell), at + out * cell * 0.3, BossMaquettes.WEAK)
	battery.basis = Basis(right, up, out)
	battery.material_override = BossMaquettes._glow_material()


## Una escalera de mano de `bottom` a `top`, pegada a una pared que mira a `out`.
static func _ladder(p: Node3D, bottom: Vector3, top: Vector3, out: Vector3) -> void:
	var side := out.cross(Vector3.UP).normalized() * 0.35
	var lift := out * 0.25
	BossMaquettes._rod(p, bottom + side + lift, top + side + lift + Vector3.UP, 0.06, RAIL)
	BossMaquettes._rod(p, bottom - side + lift, top - side + lift + Vector3.UP, 0.06, RAIL)
	var rungs := int((top.y - bottom.y) / 0.5)
	for i in rungs:
		var y := bottom + (top - bottom) * (i + 0.5) / rungs + lift
		BossMaquettes._rod(p, y + side, y - side, 0.04, RAIL)


## Una baranda de `from` a `to` (en el piso): postes y el pasamanos a 1,1 m.
static func _railing(p: Node3D, from: Vector3, to: Vector3) -> void:
	var posts := maxi(int(from.distance_to(to) / 3.0), 1)
	for i in posts + 1:
		var at := from.lerp(to, float(i) / posts)
		Clay.box(p, Vector3(0.12, 1.1, 0.12), at + Vector3.UP * 0.55, RAIL)
	BossMaquettes._rod(p, from + Vector3.UP * 1.1, to + Vector3.UP * 1.1, 0.05, RAIL)


static func _railing_loop(p: Node3D, corners: Array, closed := true) -> void:
	for i in corners.size() - (0 if closed else 1):
		_railing(p, corners[i], corners[(i + 1) % corners.size()])


## Una tabla (una rampa) de `from` a `to`, de `width` de ancho.
static func _plank(p: Node3D, from: Vector3, to: Vector3, width: float) -> void:
	var along := to - from
	var part := Clay.box(p, Vector3(width, 0.4, along.length()), (from + to) * 0.5, DECK)
	part.basis = Basis.looking_at(along.normalized(), Vector3.UP)
	_railing(p, from + part.basis.x * width * 0.5, to + part.basis.x * width * 0.5)


## El edificio de al lado, para tirarse.
static func _building(p: Node3D, at: Vector3, height: float) -> void:
	Clay.box(p, Vector3(10.0, height, 10.0), at + Vector3.UP * height * 0.5, BossMaquettes.STONE.lightened(0.15))
	_person(p, at + Vector3.UP * height)


## El recorrido: puntos y tramos celestes.
static func _route(p: Node3D, points: Array) -> void:
	for i in points.size():
		Clay.sphere(p, 0.35, points[i], ROUTE)
		if i > 0:
			BossMaquettes._rod(p, points[i - 1], points[i], 0.12, ROUTE)


static func _person(p: Node3D, at: Vector3) -> void:
	BossMaquettes._person(p, at)
