class_name ArenaConcepts
extends RefCounted

## LA ARENA, EN CONCEPTOS (13/11/2026): UNA sola arena, plana y circular, más grande que la de un Dark Souls (es para
## mecas contra mecas), con EDIFICIOS DE DOS ALTURAS (11 y 30 m: los que tapan a la gente y los que tapan a la meca) sin
## simetría y SIEMPRE ESPACIOSA (un hueco mínimo entre dos edificios). La gente SUBE A LOS TECHOS por escaleras de
## afuera (un mejor ángulo, tirar la bomba, esconderse para sabotear). Los recursos, de dos maneras: buscándolos (lo
## amarillo con bandera) o un paquete de la empresa que cae en paracaídas. Cada concepto es una estética distinta para lo
## mismo; las piezas se reparten con una semilla fija (no son a mano: así ninguna queda simétrica ni apretada).

const NAMES: Array[String] = ["Afueras", "Chacra", "Patio industrial", "Mitad pueblo, mitad campo", "Afueras grande"]
const LINES: Array[String] = [
	"Ø 260 m · casas de 11 m y torres de 30 con escalera afuera · galpones con recursos · al menos 30 m entre edificios",
	"Ø 260 m · silos de 30 m, tanques elevados y graneros de 11 · más espaciado: 40 m entre piezas",
	"Ø 260 m · galpones de 11 m, torres y chimeneas de 30 · las cajas de munición tienen sentido en los depósitos",
	"Ø 260 m · un lado apretado de casas y torres (26 m), el otro abierto con silos y un tanque (50 m)",
	"Ø 340 m · las afueras, más grandes, para comparar la escala",
]
const RADII: Array[float] = [130.0, 130.0, 130.0, 130.0, 170.0]

## Las dos alturas.
const LOW := 11.0
const TALL := 30.0
## Cuánto sube un tramo de escalera, y su largo: la escalera va en zigzag (dos carriles) pegada a una fachada.
const FLIGHT_RISE := 7.5
const FLIGHT_RUN := 14.0
const LANE := 2.6

const GROUND_DIRT := Color(0.72, 0.68, 0.60)
const GROUND_GRASS := Color(0.62, 0.66, 0.52)
const GROUND_CONCRETE := Color(0.70, 0.70, 0.68)
const BOUND := Color(0.52, 0.50, 0.48)
const STAIRS := BattlefieldIdeas.PATH
const CANOPY := Color(0.93, 0.90, 0.84)

## Lo que se reparte en cada concepto: `[tipo, cuántos, hueco mínimo, lado]` (lado: −1 sólo la mitad oeste, 1 la este,
## 0 cualquiera).
const RECIPES := [
	[["tower", 4, 30.0, 0], ["shed", 2, 30.0, 0], ["house", 8, 30.0, 0]],
	[["silo", 4, 40.0, 0], ["shed", 3, 40.0, 0], ["tank", 3, 40.0, 0], ["house", 2, 40.0, 0]],
	[["tower", 2, 30.0, 0], ["chimney", 3, 30.0, 0], ["shed", 5, 30.0, 0], ["tank", 2, 30.0, 0]],
	[["tower", 3, 26.0, -1], ["house", 7, 26.0, -1], ["silo", 2, 50.0, 1], ["tank", 1, 50.0, 1], ["shed", 1, 50.0, 1]],
	[["tower", 6, 30.0, 0], ["shed", 3, 30.0, 0], ["house", 12, 30.0, 0]],
]
const GROUNDS := [GROUND_DIRT, GROUND_GRASS, GROUND_CONCRETE, GROUND_DIRT, GROUND_DIRT]


static func build(index: int, parent: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Arena"
	parent.add_child(body)
	var radius: float = RADII[index]
	ArenaIdeas.disc(body, radius, 0, GROUNDS[index])
	ArenaIdeas.annulus(body, radius, radius + 4, 8, BOUND)
	if index == 1:
		BattlefieldIdeas.mark(body, -40, 50, 90, 60, BattlefieldIdeas.FIELD)
		BattlefieldIdeas.mark(body, 60, -40, 60, 80, BattlefieldIdeas.FIELD.darkened(0.08))
	if index == 3:
		# La mitad de campo, en franjas recortadas al círculo.
		for i in range(-12, 13):
			var z := i * 10.0
			var reach := sqrt(maxf(radius * radius - z * z, 0.0)) - 1.0
			if reach > 1.0:
				BattlefieldIdeas.mark(body, reach * 0.5, z, reach, 10.2, GROUND_GRASS)
	var placed := place(index)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + index
	var roof_supply := false
	for piece: Dictionary in placed:
		_draw(body, piece, rng)
		if piece.kind == "tower" and not roof_supply:
			ArenaIdeas.supply(body, piece.at, TALL)
			roof_supply = true
	_drop(body, Vector2(radius * 0.25, -radius * 0.2), 38.0)
	return body


static func viewpoint(index: int) -> Array[Vector3]:
	return [Vector3(0, 0, RADII[index] * 0.62), Vector3(0.1, 0, -1)]


## EL HUECO MÁS CHICO entre dos piezas de un concepto (m): para comprobar que nada quedó apretado.
static func narrowest_gap(index: int) -> float:
	var placed := place(index)
	var best := INF
	for i in placed.size():
		for j in range(i + 1, placed.size()):
			best = minf(best, _gap(placed[i], placed[j]))
	return best


# ------------------------------------------------------------------------------------------------ repartir

## Reparte las piezas del concepto con su semilla: cada una prueba lugares hasta que queda lejos de las demás (su hueco
## mínimo), adentro del círculo y fuera de donde nace la meca. Devuelve `{kind, at, size, height, stairs}`.
static func place(index: int) -> Array[Dictionary]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + index
	var radius: float = RADII[index]
	var spawn := Vector2(0, radius * 0.62)
	var out: Array[Dictionary] = []
	for line: Array in RECIPES[index]:
		var kind: String = line[0]
		var count: int = line[1]
		var gap: float = line[2]
		var side: int = line[3]
		for n in count:
			for attempt in 400:
				var size := _size(kind, rng)
				var spot := Vector2.from_angle(rng.randf() * TAU) * sqrt(rng.randf()) * (radius - 14.0)
				if side != 0 and signf(spot.x) != side:
					continue
				var piece := {"kind": kind, "at": spot, "size": size}
				if (spot + size * 0.5 * Vector2(signf(spot.x), signf(spot.y))).length() > radius - 8.0:
					continue
				if spot.distance_to(spawn) < 30.0 or spot.distance_to(spawn + Vector2(0, 30)) < 30.0:
					continue
				var fits := true
				for other: Dictionary in out:
					if _gap(piece, other) < maxf(gap, other.gap):
						fits = false
						break
				if not fits:
					continue
				piece.gap = gap
				piece.height = TALL if kind in ["tower", "silo", "chimney"] else LOW
				piece.stairs = _facing_centre(spot) if kind != "chimney" else -1
				out.append(piece)
				break
	return out


static func _size(kind: String, rng: RandomNumberGenerator) -> Vector2:
	var size := Vector2.ZERO
	match kind:
		"tower": size = Vector2(rng.randf_range(18, 22), rng.randf_range(18, 24))
		"house": size = Vector2(rng.randf_range(22, 30), rng.randf_range(14, 20))
		"shed": size = Vector2(rng.randf_range(30, 38), rng.randf_range(20, 24))
		"silo": size = Vector2(18, 18)
		"tank": size = Vector2(18, 18)
		_: size = Vector2(8, 8)
	return size if rng.randf() < 0.5 else Vector2(size.y, size.x)


## La distancia entre dos rectángulos alineados a los ejes (0 si se tocan).
static func _gap(a: Dictionary, b: Dictionary) -> float:
	var apart: Vector2 = ((a.at as Vector2) - (b.at as Vector2)).abs() - ((a.size as Vector2) + (b.size as Vector2)) * 0.5
	return Vector2(maxf(apart.x, 0.0), maxf(apart.y, 0.0)).length()


## La fachada que mira al centro: 0 +X, 1 −X, 2 +Z, 3 −Z.
static func _facing_centre(spot: Vector2) -> int:
	if absf(spot.x) > absf(spot.y):
		return 1 if spot.x > 0 else 0
	return 3 if spot.y > 0 else 2


# ------------------------------------------------------------------------------------------------ dibujar

static func _draw(body: StaticBody3D, piece: Dictionary, rng: RandomNumberGenerator) -> void:
	var at: Vector2 = piece.at
	var size: Vector2 = piece.size
	var height: float = piece.height
	match piece.kind as String:
		"tower":
			var tone: Color = [BattlefieldIdeas.WALL, BattlefieldIdeas.BRICK, Clay.METAL][rng.randi() % 3]
			BattlefieldIdeas.block(body, at.x, at.y, size.x, size.y, height, tone)
			BattlefieldIdeas.block(body, at.x, at.y, size.x + 0.6, size.y + 0.6, 0.8, tone.darkened(0.25), height)
		"house":
			var tone: Color = [BattlefieldIdeas.WALL, BattlefieldIdeas.BRICK][rng.randi() % 2]
			BattlefieldIdeas.block(body, at.x, at.y, size.x, size.y, height, tone)
			BattlefieldIdeas.block(body, at.x, at.y, size.x + 0.6, size.y + 0.6, 0.8, BattlefieldIdeas.ROOF, height)
		"shed":
			BattlefieldIdeas.block(body, at.x, at.y, size.x, size.y, height, Clay.METAL.lightened(0.15))
			var door := _outward(piece.stairs ^ 1) * ((size.x if (piece.stairs ^ 1) < 2 else size.y) * 0.5)
			Clay.box(body, Vector3(6, 5, 0.3) if (piece.stairs ^ 1) >= 2 else Vector3(0.3, 5, 6),
				Vector3(at.x + door.x, 2.5, at.y + door.y), Clay.DARK)
			var tile := at + _outward(piece.stairs ^ 1) * ((size.x if (piece.stairs ^ 1) < 2 else size.y) * 0.5 + 5.0)
			ArenaIdeas.supply(body, tile)
		"silo":
			BattlefieldIdeas.drum(body, at.x, at.y, size.x * 0.5 - 1.0, height, BattlefieldIdeas.WALL)
			Clay.cylinder(body, size.x * 0.5 - 0.6, 1.0, Vector3(at.x, height + 0.5, at.y), BattlefieldIdeas.ROOF)
		"tank":
			for leg: Vector2 in [Vector2(-6, -6), Vector2(6, -6), Vector2(-6, 6), Vector2(6, 6)]:
				BattlefieldIdeas.block(body, at.x + leg.x, at.y + leg.y, 1.2, 1.2, height, Clay.METAL)
			BattlefieldIdeas.slab(body, at.x, at.y, size.x, size.y, Clay.METAL.darkened(0.1), height)
			BattlefieldIdeas.drum(body, at.x, at.y, 6.0, 7.0, Clay.METAL.lightened(0.1), height)
		_:
			BattlefieldIdeas.drum(body, at.x, at.y, 3.5, height, BattlefieldIdeas.BRICK.lightened(0.1))
	if piece.stairs >= 0:
		stairs(body, at, size, height, piece.stairs)


## UNA ESCALERA DE AFUERA, en zigzag sobre la fachada `side`: tramos de `FLIGHT_RISE` en dos carriles, con un descanso en
## cada vuelta y el último pegado al borde del techo.
static func stairs(body: StaticBody3D, at: Vector2, size: Vector2, height: float, side: int) -> void:
	var normal := _outward(side)
	var along := Vector2(-normal.y, normal.x)
	var facade := size.x if side >= 2 else size.y
	var half_depth := (size.y if side >= 2 else size.x) * 0.5
	var run := minf(FLIGHT_RUN, facade - 7.0)
	var flights := ceili(height / FLIGHT_RISE)
	var rise := height / flights
	for i in flights:
		var lane := i % 2
		var direction := 1.0 if lane == 0 else -1.0
		var centre := at + normal * (half_depth + LANE * (lane + 0.5))
		BattlefieldIdeas.ramp(body, centre.x, centre.y, LANE - 0.1, run, rise, along * direction, STAIRS, rise * i)
		# El descanso al final del tramo, ancho de los dos carriles.
		var end := at + along * direction * (run * 0.5 + 1.5) + normal * (half_depth + LANE)
		var landing_basis := Basis(Vector3.UP, atan2(-normal.x, -normal.y))
		Clay.solid(body, Vector3(LANE * 2.0, 0.5, 3.0), Vector3(end.x, rise * (i + 1) - 0.25, end.y), STAIRS,
			landing_basis)


static func _outward(side: int) -> Vector2:
	return [Vector2.RIGHT, Vector2.LEFT, Vector2(0, 1), Vector2(0, -1)][side]


## EL PAQUETE DE LA EMPRESA, cayendo: un cajón con su paracaídas, y la marca en el piso de dónde va a caer.
static func _drop(body: StaticBody3D, at: Vector2, height: float) -> void:
	Clay.box(body, Vector3(1.6, 1.6, 1.6), Vector3(at.x, height, at.y), BattlefieldIdeas.SUPPLY.darkened(0.2))
	var canopy := Clay.sphere(body, 7.0, Vector3(at.x, height + 8.0, at.y), CANOPY)
	canopy.scale = Vector3(1.0, 0.45, 1.0)
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
		var line := MeshInstance3D.new()
		line.mesh = BoxMesh.new()
		line.material_override = Clay.material(Clay.DARK)
		body.add_child(line)
		Clay.segment(line, Vector3(at.x + corner.x * 0.7, height + 0.8, at.y + corner.y * 0.7),
			Vector3(at.x + corner.x * 5.6, height + 7.0, at.y + corner.y * 5.6), 0.1)
	ArenaIdeas.annulus(body, 5.5, 6.5, 0.1, BattlefieldIdeas.SUPPLY, 0.0)
	BattlefieldIdeas.mark(body, at.x, at.y, 1.0, 1.0, BattlefieldIdeas.SUPPLY)
