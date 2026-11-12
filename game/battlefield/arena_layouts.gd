class_name ArenaLayouts
extends RefCounted

## LA ARENA MAYORMENTE LIBRE (13/11/2026): la arena es un FONDO donde las mecas pelean, se mueven y esquivan; lo que sirve
## a pie (cubrirse, escaleras, recovecos, de dónde saltar) va JUNTO, EN ZONAS, no desparramado. El usuario: «la arena
## debería estar mayoritariamente libre de cosas… las cosas no tienen que estar desparramadas tan así al tuntún, pero
## tampoco tan perfectitas». Cada idea es una distribución distinta de esas zonas (el anillo, el centro, bolsones, una
## media luna) o un tropo (el estadio, el viaducto). Todas Ø 260 m, planas, con el muro de borde.

const NAMES: Array[String] = ["Centro libre, borde con cosas", "Torre al medio", "Cráter de ruinas", "Tres bolsones",
	"Media luna", "Estadio", "Viaducto", "Playa de vagones"]
const LINES: Array[String] = [
	"el centro (Ø 170 m) vacío para las mecas · en el borde, casas con escaleras, autos y callejones para la gente",
	"una torre grande al medio (50 m, con balcones a 11 y 30) para subir y cubrirse · alrededor, nada",
	"al medio, ruinas de 1 a 3 m: la gente se cubre, la meca pasa · en el borde, edificios enteros y autos",
	"tres barrios chicos y distintos pegados al muro · entre ellos, campo abierto",
	"un barrio en media luna sobre un lado del muro · el resto libre, con un tanque de hito",
	"gradas alrededor que la gente sube (y de donde salta) · la cancha, libre · recursos bajo las gradas",
	"una autopista a 18 m cruza en curva: la meca pasa por abajo, la gente camina arriba · el resto libre",
	"vagones quietos en vías sobre un lado: cubren a la gente, la meca los ve por arriba · el resto libre",
]
const RADII: Array[float] = [130.0, 130.0, 130.0, 130.0, 130.0, 130.0, 130.0, 130.0]
const RADIUS := 130.0

const GROUND := Color(0.74, 0.71, 0.64)
const CRATER := Color(0.62, 0.59, 0.54)
const RUIN := Color(0.66, 0.62, 0.57)
const CARS: Array[Color] = [Color(0.56, 0.32, 0.28), Color(0.34, 0.42, 0.50), Color(0.52, 0.54, 0.44),
	Color(0.80, 0.76, 0.64), Color(0.30, 0.30, 0.32)]
const TONES: Array[Color] = [BattlefieldIdeas.WALL, BattlefieldIdeas.BRICK, Color(0.66, 0.68, 0.70),
	Color(0.74, 0.66, 0.56)]


static func build(index: int, parent: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Arena"
	parent.add_child(body)
	var rng := RandomNumberGenerator.new()
	rng.seed = 500 + index
	ArenaIdeas.disc(body, RADIUS, 0, GROUND)
	ArenaIdeas.annulus(body, RADIUS, RADIUS + 4, 8, ArenaConcepts.BOUND)
	match index:
		0: _edge_ring(body, rng)
		1: _central_tower(body, rng)
		2: _ruin_crater(body, rng)
		3: _pockets(body, rng)
		4: _crescent(body, rng)
		5: _stadium(body, rng)
		6: _viaduct(body, rng)
		_: _wagon_yard(body, rng)
	return body


static func viewpoint(index: int) -> Array[Vector3]:
	match index:
		1: return [Vector3(0, 0, 70), Vector3(0, 0, -1)]
		5: return [Vector3(0, 0, 40), Vector3(0.2, 0, -1)]
		6: return [Vector3(-30, 0, 40), Vector3(0.5, 0, -1)]
		7: return [Vector3(-30, 0, 30), Vector3(0.7, 0, -1)]
		_: return [Vector3(0, 0, 50), Vector3(0.1, 0, -1)]


# ------------------------------------------------------------------------------------------------ las piezas

## Un edificio GIRADO: su propio cuerpo estático, con la fachada +Z (donde va la escalera) mirando hacia `facing`.
static func building(body: StaticBody3D, at: Vector2, facing: Vector2, size: Vector2, height: float, tone: Color,
		with_stairs := true) -> void:
	var piece := StaticBody3D.new()
	piece.position = Vector3(at.x, 0, at.y)
	piece.rotation.y = atan2(facing.x, facing.y)
	body.add_child(piece)
	BattlefieldIdeas.block(piece, 0, 0, size.x, size.y, height, tone)
	BattlefieldIdeas.block(piece, 0, 0, size.x + 0.6, size.y + 0.6, 0.8, tone.darkened(0.25), height)
	if with_stairs:
		ArenaConcepts.stairs(piece, Vector2.ZERO, size, height, 2)


## Un auto: la caja y la cabina, girado `yaw`.
static func car(body: StaticBody3D, at: Vector2, yaw: float, color: Color, base := 0.0) -> void:
	var basis := Basis(Vector3.UP, yaw)
	Clay.solid(body, Vector3(1.9, 0.9, 4.4), Vector3(at.x, base + 0.65, at.y), color, basis)
	Clay.solid(body, Vector3(1.7, 0.7, 2.2), Vector3(at.x, base + 1.45, at.y) + basis * Vector3(0, 0, -0.3), color.darkened(0.2),
		basis)


## Una ruina: un pedazo de pared en L de `height`, girado `yaw`.
static func ruin(body: StaticBody3D, at: Vector2, yaw: float, length: float, height: float) -> void:
	var basis := Basis(Vector3.UP, yaw)
	var centre := Vector3(at.x, height * 0.5, at.y)
	Clay.solid(body, Vector3(length, height, 0.8), centre, RUIN, basis)
	Clay.solid(body, Vector3(0.8, height * 0.6, length * 0.6), centre + basis * Vector3(length * 0.5, -height * 0.2,
		length * 0.3), RUIN.darkened(0.05), basis)


## Un punto sobre un círculo de radio `radius`, a `degrees`.
static func on_ring(radius: float, degrees: float) -> Vector2:
	return ArenaIdeas.at_angle(radius, degrees)


## UN BARRIO CHICO pegado al muro, centrado en el ángulo `degrees`, de `span` grados: dos filas de casas (la de afuera
## más alta), callejones entre ellas, autos en la calle de adelante y recursos en un callejón.
static func barrio(body: StaticBody3D, rng: RandomNumberGenerator, degrees: float, span: float, tall_count := 1) -> void:
	var count := maxi(2, int(span / 14.0))
	var talls := 0
	for i in count:
		var a := degrees - span * 0.5 + span * (i + 0.5) / count + rng.randf_range(-2.5, 2.5)
		var outer := on_ring(RADIUS - 16 + rng.randf_range(-2, 2), a)
		var tall := talls < tall_count and rng.randf() < 0.45
		if tall:
			talls += 1
		building(body, outer, -outer.normalized(), Vector2(rng.randf_range(20, 24), rng.randf_range(16, 20)),
			ArenaConcepts.TALL if tall else ArenaConcepts.LOW, TONES[rng.randi() % TONES.size()], i % 2 == 0)
		if i % 2 == 1 and rng.randf() < 0.8:
			var inner := on_ring(RADIUS - 40 + rng.randf_range(-3, 3), a + rng.randf_range(-3, 3))
			building(body, inner, -inner.normalized(), Vector2(rng.randf_range(18, 22), rng.randf_range(12, 16)),
				ArenaConcepts.LOW, TONES[rng.randi() % TONES.size()], true)
		if rng.randf() < 0.6:
			var spot := on_ring(RADIUS - 56 + rng.randf_range(-4, 4), a + rng.randf_range(-4, 4))
			car(body, spot, deg_to_rad(a) + rng.randf_range(-0.4, 0.4), CARS[rng.randi() % CARS.size()])
	ArenaIdeas.supply(body, on_ring(RADIUS - 28, degrees + span / count))


# ------------------------------------------------------------------------------------------------ 1 · el borde

static func _edge_ring(body: StaticBody3D, rng: RandomNumberGenerator) -> void:
	for sector: Vector2 in [Vector2(20, 80), Vector2(115, 70), Vector2(200, 60), Vector2(285, 90)]:
		barrio(body, rng, sector.x, sector.y)
	ArenaConcepts._drop(body, Vector2(10, -20), 38.0)


# ------------------------------------------------------------------------------------------------ 2 · la torre

## La torre: un cilindro grueso con balcones en dos alturas y una escalera de afuera hasta arriba; unas pocas ruinas al
## pie. Es al revés del anillo: lo de la gente, en el medio y en altura.
static func _central_tower(body: StaticBody3D, rng: RandomNumberGenerator) -> void:
	BattlefieldIdeas.drum(body, 0, 0, 16, 50, BattlefieldIdeas.WALL)
	for level: float in [ArenaConcepts.LOW, ArenaConcepts.TALL]:
		ArenaIdeas.disc(body, 21, level, Clay.METAL, 0.6)
	ArenaIdeas.disc(body, 17, 50.8, BattlefieldIdeas.ROOF, 0.8)
	ArenaConcepts.stairs(body, Vector2(0, 0), Vector2(26, 42), 50.0, 2)
	ArenaIdeas.supply(body, Vector2(0, -18), ArenaConcepts.TALL)
	ArenaIdeas.supply(body, Vector2(0, 0), 50.8)
	for i in 5:
		var a := 40.0 + i * 70.0 + rng.randf_range(-10, 10)
		ruin(body, on_ring(32 + rng.randf_range(0, 8), a), deg_to_rad(a), rng.randf_range(6, 10), rng.randf_range(1.5, 3))
	ArenaConcepts._drop(body, Vector2(70, -40), 38.0)


# ------------------------------------------------------------------------------------------------ 3 · el cráter

static func _ruin_crater(body: StaticBody3D, rng: RandomNumberGenerator) -> void:
	Clay.cylinder(body, 80, 0.06, Vector3(0, 0.03, 0), CRATER)
	for i in 22:
		var spot := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * 72.0
		if spot.distance_to(Vector2(0, 50)) < 16.0:
			continue
		ruin(body, spot, rng.randf() * TAU, rng.randf_range(5, 12), rng.randf_range(1.0, 3.0))
	for i in 6:
		var spot := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(20, 70)
		car(body, spot, rng.randf() * TAU, CARS[4].lightened(0.15))
	ArenaIdeas.supply(body, Vector2(-30, 10))
	for sector: Vector2 in [Vector2(10, 100), Vector2(150, 80), Vector2(250, 70)]:
		barrio(body, rng, sector.x, sector.y, 2)
	ArenaConcepts._drop(body, Vector2(30, -10), 38.0)


# ------------------------------------------------------------------------------------------------ 4 · bolsones

static func _pockets(body: StaticBody3D, rng: RandomNumberGenerator) -> void:
	barrio(body, rng, 30, 55, 1)
	barrio(body, rng, 150, 40, 2)
	barrio(body, rng, 255, 65, 1)
	ArenaConcepts._drop(body, Vector2(30, -45), 38.0)


# ------------------------------------------------------------------------------------------------ 5 · media luna

static func _crescent(body: StaticBody3D, rng: RandomNumberGenerator) -> void:
	barrio(body, rng, 270, 150, 3)
	var tank := Vector2(55, 20)
	for leg: Vector2 in [Vector2(-6, -6), Vector2(6, -6), Vector2(-6, 6), Vector2(6, 6)]:
		BattlefieldIdeas.block(body, tank.x + leg.x, tank.y + leg.y, 1.2, 1.2, ArenaConcepts.TALL, Clay.METAL)
	BattlefieldIdeas.slab(body, tank.x, tank.y, 18, 18, Clay.METAL.darkened(0.1), ArenaConcepts.TALL)
	BattlefieldIdeas.drum(body, tank.x, tank.y, 7.0, 9.0, Clay.METAL.lightened(0.1), ArenaConcepts.TALL)
	ArenaConcepts.stairs(body, tank, Vector2(18, 18), ArenaConcepts.TALL, 1)
	ArenaConcepts._drop(body, Vector2(40, 50), 38.0)


# ------------------------------------------------------------------------------------------------ 6 · estadio

## Gradas: escalones de 2 m que suben hacia afuera hasta 16 m, con cuatro bocas (túneles) para entrar a la cancha.
static func _stadium(body: StaticBody3D, _rng: RandomNumberGenerator) -> void:
	var mouths: Array[float] = [deg_to_rad(20), deg_to_rad(115), deg_to_rad(200), deg_to_rad(290)]
	for step in 8:
		var inner := 92.0 + step * 4.5
		ArenaIdeas.annulus(body, inner, RADIUS, 2.0, BattlefieldIdeas.WALL.darkened(0.03 * (step % 2)), step * 2.0,
			mouths, 12.0)
	for mouth in mouths:
		var spot := Vector2(cos(mouth), sin(mouth)) * 96.0
		ArenaIdeas.supply(body, spot)
	BattlefieldIdeas.mark(body, 0, 0, 120, 80, BattlefieldIdeas.GRASS)
	ArenaConcepts._drop(body, Vector2(20, -20), 38.0)


# ------------------------------------------------------------------------------------------------ 7 · viaducto

## Una autopista elevada en curva: tablero a 18 m sobre pilares cada 26 m (la meca, de 15 m, pasa por abajo). Sube a
## la gente una rampa en cada punta (contra el muro). Autos quietos arriba.
static func _viaduct(body: StaticBody3D, rng: RandomNumberGenerator) -> void:
	var deck := 18.0
	var centre := Vector2(-150, -40)
	var bend := 170.0
	var count := 12
	var first := -50.0
	var last := 40.0
	for i in count + 1:
		var a := deg_to_rad(lerpf(first, last, float(i) / count))
		var spot := centre + Vector2(cos(a), sin(a)) * bend
		if spot.length() > RADIUS - 6.0:
			continue
		var next_a := deg_to_rad(lerpf(first, last, float(i + 1) / count))
		var next := centre + Vector2(cos(next_a), sin(next_a)) * bend
		var along := next - spot
		var basis := Basis(Vector3.UP, atan2(along.x, along.y))
		var middle := (spot + next) * 0.5
		if next.length() < RADIUS - 6.0:
			Clay.solid(body, Vector3(16, 1.6, along.length() + 0.5), Vector3(middle.x, deck - 0.8, middle.y), Clay.METAL,
				basis)
			Clay.solid(body, Vector3(0.4, 1.2, along.length()), Vector3(middle.x, deck + 0.6, middle.y) +
				basis * Vector3(7.8, 0, 0), Clay.DARK, basis)
			Clay.solid(body, Vector3(0.4, 1.2, along.length()), Vector3(middle.x, deck + 0.6, middle.y) +
				basis * Vector3(-7.8, 0, 0), Clay.DARK, basis)
			if rng.randf() < 0.5:
				car(body, middle, atan2(along.x, along.y), CARS[rng.randi() % CARS.size()], deck)
		BattlefieldIdeas.block(body, spot.x, spot.y, 3, 3, deck - 1.6, Clay.METAL.darkened(0.15))
	# Las torres de escalera de la gente, pegadas al costado de la autopista en las dos puntas.
	for tip: float in [first + 20.0, last - 26.0]:
		var a := deg_to_rad(tip)
		var radial := Vector2(cos(a), sin(a))
		building(body, centre + radial * (bend + 12.5), radial, Vector2(20, 8), deck, BattlefieldIdeas.BRICK)
	ArenaIdeas.supply(body, centre + Vector2.from_angle(deg_to_rad(-5)) * bend, deck)
	ArenaConcepts._drop(body, Vector2(60, 30), 38.0)


# ------------------------------------------------------------------------------------------------ 8 · vagones

## Cuatro vías paralelas sobre un lado, con vagones quietos de 4 m de alto (tapan a la gente; la meca ve por arriba),
## huecos entre ellos para cruzar, y una torre de señales con escalera de donde mirar.
static func _wagon_yard(body: StaticBody3D, rng: RandomNumberGenerator) -> void:
	for line in 4:
		var x := 50.0 + line * 14.0
		var reach := sqrt(maxf(RADIUS * RADIUS - x * x, 0.0)) - 6.0
		BattlefieldIdeas.mark(body, x, 0, 3.4, reach * 2.0, Clay.DARK.lightened(0.25))
		var z := -reach + rng.randf_range(4, 14)
		while z < reach - 16.0:
			var length := 16.0
			if rng.randf() < 0.7:
				BattlefieldIdeas.block(body, x, z + length * 0.5, 3.2, length, 4.0, BattlefieldIdeas.CARGO[rng.randi() % 4])
			z += length + (rng.randf_range(1.5, 3.0) if rng.randf() < 0.7 else rng.randf_range(10, 20))
	BattlefieldIdeas.block(body, 40, -50, 10, 10, ArenaConcepts.TALL, BattlefieldIdeas.BRICK)
	ArenaConcepts.stairs(body, Vector2(40, -50), Vector2(10, 22), ArenaConcepts.TALL, 1)
	ArenaIdeas.supply(body, Vector2(57, 10))
	ArenaIdeas.supply(body, Vector2(85, -30))
	ArenaConcepts._drop(body, Vector2(-30, -70), 38.0)
