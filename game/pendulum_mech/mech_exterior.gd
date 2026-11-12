class_name MechExterior
extends RefCounted

## EL AFUERA DE LA MECA PÉNDULO: por dónde se anda por fuera del cubo. Lo pidió el usuario el 12/11/2026 («la zona de
## escaleras de afuera… la escalera se debería sentir como algo que está encima del cubo, no algo que compite con el
## cubo… la plataforma… que dé la vuelta… en planta baja desde la parte de la escalera hasta los dos costados»).
##
## SE ARMA DE SUPERFICIES PISABLES (`surfaces`): cada una, un rectángulo en planta —de `x0` a `x1`, de `z0` a `z1`— con su
## altura en cada punta (`ya` en `x0`, `yb` en `x1`): igual en las dos, un PISO; distinta, un TRAMO de escalera, que sube
## a lo largo de x. De ahí sale todo, con dos reglas:
##   · LA ALTURA LIBRE (`headroom`): sobre cada punto pisable, lo que hay hasta la superficie de arriba. Tiene que pasar
##     una persona (`CLEAR`). *El primer zigzag (12/11/2026) tenía los dos tramos en el mismo carril, uno encima del
##     otro: donde se daban vuelta quedaba 1,1 m de altura (lo vio el usuario: «son imposibles»). Se había armado a ojo,
##     sin medir.*
##   · LAS BARANDAS VAN DONDE HAY CAÍDA: en cada borde de cada superficie, salvo donde del otro lado sigue otra
##     superficie a la misma altura o está la pared del cubo.
## Todo de barras y rejilla finas. SE CAMINA: cada piso, cada tramo (una rampa) y cada baranda le agrega su forma de
## choque a `solid`, el cuerpo de las formas de adentro de la meca, del que su marco copia la sombra (ver PendulumMech).
## En el espacio del cubo (el centro en el origen).
##
## LO COMÚN: la pasarela en U de planta baja —atrás, de costado a costado, y por los dos costados hasta antes de donde
## cuelgan los brazos—, y dos tableros para reparar. LAS ESCALERAS DE ATRÁS, a elegir (`variant`, ver NAMES): van en
## carriles paralelos a la pared de atrás; el primero es el de la pasarela y los balcones.

const NAMES := [
	"zigzag: el tramo de arriba, pegado a la pared",
	"dos tramos paralelos; se vuelve caminando por el balcón",
	"zigzag de ida y vuelta, cada tramo en su carril",
	"caja compacta: medio tramo, descanso y medio tramo",
	"la 2, con el balcón de arriba igual al de abajo",
	"la 2 corrida a un costado: balcones iguales, de la puerta al descanso",
]
const HALF := HoverCube.SIZE * 0.5
## El ancho de un carril (la pasarela, los balcones, los tramos) y el alto de la baranda.
const WALK := 1.1
const LANE := 0.9
const RAIL := 1.05
const BAR := 0.07
## Hasta dónde llega la pasarela por los costados, hacia el frente (z): antes de donde cuelgan los brazos.
const SIDE_END := -2.2
## Lo que tiene que quedar libre sobre cada lugar pisable (m).
const CLEAR := 2.1
const STEEL := Color(0.24, 0.25, 0.28)
const GRATE := Color(0.36, 0.38, 0.41)

## La escalera de atrás que se arma (ver NAMES).
static var variant := 0


## Lo arma colgado de `holder` (el dibujo) y `solid` (sus formas de choque).
static func build(holder: Node3D, solid: PhysicsBody3D) -> void:
	var all := surfaces(variant)
	for surface: Dictionary in all:
		_draw(holder, solid, surface)
	_rails(holder, solid, all)
	# Dos tableros para reparar, uno en cada costado, a la altura de la pasarela.
	for side: float in [-1.0, 1.0]:
		Clay.box(holder, Vector3(0.18, 1.1, 0.9), Vector3(side * (HALF + 0.09), _floor_y(0) + 1.25, 1.2), Clay.RED)
		Clay.box(holder, Vector3(0.2, 0.2, 0.2), Vector3(side * (HALF + 0.12), _floor_y(0) + 1.25, 1.2), Clay.YELLOW)
	var free := headroom(all)
	if free < CLEAR:
		push_warning("MechExterior: la escalera «%s» deja %.2f m de altura libre (hacen falta %.2f)" % [NAMES[variant], free, CLEAR])


## Hasta dónde llega todo esto, en el espacio del cubo: para el volumen del marco.
static func bounds() -> AABB:
	var outer := HALF + WALK + 0.25
	var back := _lane(2).y + 0.3
	return AABB(Vector3(-outer, -HALF - 0.3, SIDE_END - 0.3), Vector3(outer * 2.0, HoverCube.SIZE + 2.4, back - SIDE_END + 0.3))


static func _floor_y(index: int) -> float:
	return PendulumMech.floor_y(index) + PendulumMech.SLAB * 0.5


## El carril `index` (0, el de la pasarela y los balcones, pegado a la pared): de dónde a dónde va, en z.
static func _lane(index: int) -> Vector2:
	if index == 0:
		return Vector2(HALF, HALF + WALK)
	return Vector2(HALF + WALK + LANE * (index - 1), HALF + WALK + LANE * index)


## ── LAS SUPERFICIES ──────────────────────────────────────────────────────────────────────────────────────────────

## Una superficie de `x0` a `x1`, del carril `lane0` al `lane1`, con la altura `ya` en `x0` y `yb` en `x1`.
static func _s(x0: float, x1: float, lane0: int, lane1: int, ya: float, yb: float) -> Dictionary:
	return {"x0": x0, "x1": x1, "z0": _lane(lane0).x, "z1": _lane(lane1).y, "ya": ya, "yb": yb}


## Todas las superficies pisables de la escalera `which`, con la pasarela.
static func surfaces(which: int) -> Array[Dictionary]:
	var ground := _floor_y(0)
	var first := _floor_y(1)
	var second := _floor_y(2)
	var outer := HALF + WALK
	var all: Array[Dictionary] = [_s(-outer, outer, 0, 0, ground, ground)]
	for side: float in [-1.0, 1.0]:
		all.append({"x0": minf(side * HALF, side * outer), "x1": maxf(side * HALF, side * outer), "z0": SIDE_END, "z1": HALF,
			"ya": ground, "yb": ground})
	match which:
		0:
			# ZIGZAG: el primer tramo, por fuera, hacia un lado; el segundo vuelve PEGADO A LA PARED, del otro lado de la
			# puerta. El balcón del segundo piso va para un solo lado; el del tercero corre por fuera hasta su puerta.
			all.append(_s(-2.9, -2.0, 1, 1, ground, ground))
			all.append(_s(-2.0, 2.0, 1, 1, ground, first))
			all.append(_s(2.0, 2.9, 1, 1, first, first))
			all.append(_s(-0.9, 2.9, 0, 0, first, first))
			all.append(_s(-4.6, -0.9, 0, 0, second, first))
			all.append(_s(-outer, -4.6, 0, 1, second, second))
			all.append(_s(-4.6, 0.9, 1, 1, second, second))
			all.append(_s(-0.9, 0.9, 0, 0, second, second))
		1:
			# PARALELOS: los dos tramos suben para el mismo lado, uno arriba del otro; del final del primero al
			# arranque del segundo se vuelve caminando por el balcón.
			for index in 2:
				var low := _floor_y(index)
				var high := _floor_y(index + 1)
				all.append(_s(-2.9, -2.0, 1, 1, low, low))
				all.append(_s(-2.0, 2.0, 1, 1, low, high))
				all.append(_s(2.0, 2.9, 1, 1, high, high))
			all.append(_s(-2.9, 2.9, 0, 0, first, first))
			all.append(_s(-0.9, 2.9, 0, 0, second, second))
		2:
			# IDA Y VUELTA EN DOS CARRILES: el primer tramo en el carril del medio, el segundo vuelve en el de afuera.
			all.append(_s(-2.9, -2.0, 1, 1, ground, ground))
			all.append(_s(-2.0, 2.0, 1, 1, ground, first))
			all.append(_s(2.0, 2.9, 1, 2, first, first))
			all.append(_s(-2.9, 2.9, 0, 0, first, first))
			all.append(_s(-2.0, 2.0, 2, 2, second, first))
			all.append(_s(-2.9, -2.0, 1, 2, second, second))
			all.append(_s(-2.9, 0.9, 0, 0, second, second))
		3:
			# CAJA COMPACTA, al costado de las puertas: por piso, medio tramo en el carril del medio, un descanso, y
			# medio tramo de vuelta en el de afuera. Todos los pisos iguales, uno arriba del otro.
			all.append(_s(0.3, 1.2, 1, 1, ground, ground))
			for index in 2:
				var low := _floor_y(index)
				var high := _floor_y(index + 1)
				var middle := (low + high) * 0.5
				all.append(_s(1.2, 3.2, 1, 1, low, middle))
				all.append(_s(3.2, 4.1, 1, 2, middle, middle))
				all.append(_s(1.2, 3.2, 2, 2, high, middle))
				all.append(_s(0.3, 1.2, 1, 2, high, high))
				all.append(_s(-0.9, 1.4, 0, 0, high, high))
		4:
			# LA 2, CON EL BALCÓN DE ARRIBA IGUAL AL DE ABAJO: los dos de punta a punta de la escalera.
			_parallel(all, -2.9, -2.9)
		5:
			# LA 2, CORRIDA A UN COSTADO: la puerta en una punta del balcón y la escalera hacia el otro lado; los dos
			# balcones iguales, de la puerta al descanso de arriba, y el tramo arranca al borde de la puerta.
			_parallel(all, -0.9, -0.9)
	return all


## DOS TRAMOS PARALELOS que suben hacia +x, uno arriba del otro, en el carril del medio: el descanso de abajo arranca en
## `start`; los balcones del segundo y del tercer piso, iguales, van desde `balcony` hasta el descanso de arriba.
static func _parallel(all: Array[Dictionary], start: float, balcony: float) -> void:
	for index in 2:
		var low := _floor_y(index)
		var high := _floor_y(index + 1)
		all.append(_s(start, start + 0.9, 1, 1, low, low))
		all.append(_s(start + 0.9, start + 4.9, 1, 1, low, high))
		all.append(_s(start + 4.9, start + 5.8, 1, 1, high, high))
		all.append(_s(balcony, start + 5.8, 0, 0, high, high))


## La altura de `surface` en `x`.
static func _height(surface: Dictionary, x: float) -> float:
	var share := clampf((x - float(surface["x0"])) / maxf(float(surface["x1"]) - float(surface["x0"]), 0.001), 0.0, 1.0)
	return lerpf(float(surface["ya"]), float(surface["yb"]), share)


## Si `surface` cubre el punto (x, z).
static func _covers(surface: Dictionary, x: float, z: float) -> bool:
	return x >= float(surface["x0"]) - 0.001 and x <= float(surface["x1"]) + 0.001 \
		and z >= float(surface["z0"]) - 0.001 and z <= float(surface["z1"]) + 0.001


## LA ALTURA LIBRE más chica: sobre cada punto de cada superficie, lo que hay hasta la primera superficie de arriba (o
## hasta el techo de la pasarela, que no tiene: mucho).
static func headroom(all: Array[Dictionary]) -> float:
	var least := 99.0
	for surface: Dictionary in all:
		var x := float(surface["x0"]) + 0.05
		while x < float(surface["x1"]):
			var z := float(surface["z0"]) + 0.05
			while z < float(surface["z1"]):
				var here := _height(surface, x)
				for above: Dictionary in all:
					if above != surface and _covers(above, x, z) and _height(above, x) > here + 0.3:
						least = minf(least, _height(above, x) - here)
				z += 0.2
			x += 0.2
	return least


## ── EL DIBUJO Y LAS FORMAS ───────────────────────────────────────────────────────────────────────────────────────

## Una superficie: un piso de rejilla, o un tramo (dos zancas y los escalones; se camina como una rampa).
static func _draw(holder: Node3D, solid: PhysicsBody3D, surface: Dictionary) -> void:
	var x0 := float(surface["x0"])
	var x1 := float(surface["x1"])
	var z0 := float(surface["z0"])
	var z1 := float(surface["z1"])
	var ya := float(surface["ya"])
	var yb := float(surface["yb"])
	var middle := (z0 + z1) * 0.5
	var width := z1 - z0
	if is_equal_approx(ya, yb):
		var size := Vector3(x1 - x0, 0.07, width)
		var at := Vector3((x0 + x1) * 0.5, ya - 0.035, middle)
		Clay.box(holder, size, at, GRATE)
		Clay.shape_box(solid, size, at)
		return
	var from := Vector3(x0, ya, middle)
	var to := Vector3(x1, yb, middle)
	for edge: float in [-1.0, 1.0]:
		_bar(holder, from + Vector3(0, 0, edge * width * 0.5), to + Vector3(0, 0, edge * width * 0.5), 0.1)
	var steps := roundi(absf(yb - ya) / 0.21)
	for step in range(1, steps):
		Clay.box(holder, Vector3(0.3, 0.05, width), from.lerp(to, float(step) / steps), GRATE)
	var slope := MechBody.segment(from, to, Vector3.UP)
	Clay.shape_box(solid, Vector3(width, 0.1, from.distance_to(to)), slope.origin - slope.basis.y * 0.05, slope.basis)


## LAS BARANDAS, DONDE HAY CAÍDA: recorre los cuatro bordes de cada superficie de a pedacitos; un pedacito lleva baranda
## si justo afuera no sigue otra superficie a esa altura ni está la pared del cubo. Los pedacitos seguidos son una baranda.
static func _rails(holder: Node3D, solid: PhysicsBody3D, all: Array[Dictionary]) -> void:
	for surface: Dictionary in all:
		var x0 := float(surface["x0"])
		var x1 := float(surface["x1"])
		var z0 := float(surface["z0"])
		var z1 := float(surface["z1"])
		# Los dos bordes largos (a lo largo de x) y los dos de las puntas (a lo largo de z).
		for edge: Array in [[Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(0, 0, -1)], [Vector3(x0, 0, z1), Vector3(x1, 0, z1), Vector3(0, 0, 1)],
				[Vector3(x0, 0, z0), Vector3(x0, 0, z1), Vector3(-1, 0, 0)], [Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(1, 0, 0)]]:
			var from: Vector3 = edge[0]
			var to: Vector3 = edge[1]
			var out: Vector3 = edge[2]
			var pieces := maxi(roundi(from.distance_to(to) / 0.25), 1)
			var start := -1
			for piece in pieces + 1:
				var open := false
				if piece < pieces:
					var at := from.lerp(to, (piece + 0.5) / pieces)
					open = _drops(all, surface, at, out)
				if open and start < 0:
					start = piece
				elif not open and start >= 0:
					var a := from.lerp(to, float(start) / pieces)
					var b := from.lerp(to, float(piece) / pieces)
					a.y = _height(surface, a.x)
					b.y = _height(surface, b.x)
					_rail(holder, solid, a, b)
					start = -1


## Si en el borde de `surface`, en `at`, hacia `out`, hay caída: afuera no sigue otra superficie a esa altura, ni está la
## pared del cubo.
static func _drops(all: Array[Dictionary], surface: Dictionary, at: Vector3, out: Vector3) -> bool:
	var beyond := at + out * 0.2
	if absf(beyond.x) < HALF and absf(beyond.z) < HALF:
		return false
	var here := _height(surface, at.x)
	for other: Dictionary in all:
		if other != surface and _covers(other, beyond.x, beyond.z) and absf(_height(other, beyond.x) - here) < 0.45:
			return false
	return true


## Una baranda de `from` a `to` (por el piso): el pasamanos, una barra al medio y los parantes; y una pared fina que no
## deja caerse.
static func _rail(holder: Node3D, solid: PhysicsBody3D, from: Vector3, to: Vector3) -> void:
	if from.distance_to(to) < 0.3:
		return
	var up := Vector3.UP * RAIL
	_bar(holder, from + up, to + up)
	_bar(holder, from + up * 0.5, to + up * 0.5, BAR * 0.7)
	var posts := maxi(roundi(from.distance_to(to) / 1.3), 1)
	for post in posts + 1:
		var at := from.lerp(to, float(post) / posts)
		_bar(holder, at, at + up)
	var along := MechBody.segment(from, to, Vector3.UP)
	Clay.shape_box(solid, Vector3(0.1, RAIL, from.distance_to(to)), along.origin + up * 0.5, along.basis)


## Una barra entre dos puntos (dibujo).
static func _bar(holder: Node3D, from: Vector3, to: Vector3, thickness := BAR) -> void:
	var bar := Clay.box(holder, Vector3(thickness, thickness, from.distance_to(to)), Vector3.ZERO, STEEL)
	bar.transform = MechBody.segment(from, to, Vector3.UP)
