class_name BattlefieldIdeas
extends RefCounted

## LAS IDEAS DE MAPA DE PELEA, EN ARCILLA (13/11/2026): seis mapas distintos de 200 × 200 m para que el usuario elija
## uno. Cada uno es UN SOLO `StaticBody3D` con cajas: el piso y lo que tapa a una meca de 15 m. Lo amarillo (una baldosa
## y un poste con bandera) es DÓNDE HAY RECURSOS para ir a buscar a pie; lo claro, POR DÓNDE CAMINA UNA PERSONA y la
## meca no entra. *Es para mirar y descartar: el elegido pasa a su parcela y los demás se borran con este archivo.*

const SIZE := 200.0
const NAMES: Array[String] = ["Pueblo", "Cantera", "Puerto", "Río y puente", "Fábrica", "Campo"]

const GRASS := Color(0.60, 0.64, 0.50)
const FIELD := Color(0.72, 0.68, 0.48)
const DIRT := Color(0.68, 0.62, 0.53)
const CONCRETE := Color(0.69, 0.69, 0.67)
const STONE := Color(0.60, 0.58, 0.55)
const WALL := Color(0.80, 0.76, 0.68)
const BRICK := Color(0.64, 0.47, 0.40)
const ROOF := Color(0.47, 0.40, 0.37)
const PATH := Color(0.92, 0.89, 0.80)
const WATER := Color(0.40, 0.52, 0.60)
const SUPPLY := Color(0.95, 0.72, 0.15)
const TREE := Color(0.38, 0.50, 0.35)
const WOOD := Color(0.46, 0.37, 0.30)
const CARGO: Array[Color] = [Color(0.55, 0.36, 0.30), Color(0.36, 0.46, 0.52), Color(0.50, 0.52, 0.42),
	Color(0.66, 0.58, 0.40)]


## Arma la idea `index` (0…5) colgada de `parent`, centrada en su origen, con el piso en y = 0.
static func build(index: int, parent: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Mapa"
	parent.add_child(body)
	match index:
		0: _town(body)
		1: _quarry(body)
		2: _harbour(body)
		3: _river(body)
		4: _factory(body)
		_: _farmland(body)
	return body


## DÓNDE PARAR LA MECA PARA MIRARLO y hacia dónde mira: `[posición, dirección]`.
static func viewpoint(index: int) -> Array[Vector3]:
	match index:
		0: return [Vector3(-12, 0, 36), Vector3(0.15, 0, -1)]
		1: return [Vector3(0, 0, 0), Vector3(-0.4, 0, 1)]
		2: return [Vector3(40, 0, -22), Vector3(-1, 0, 0.5)]
		3: return [Vector3(-30, 0, -10), Vector3(1, 0, -0.6)]
		4: return [Vector3(-5, 0, 12), Vector3(-0.55, 0, -1)]
		_: return [Vector3(5, 0, -16), Vector3(-0.3, 0, 1)]


# ------------------------------------------------------------------------------------------------ las piezas

## Una caja que choca, apoyada en `base`, centrada en (x, z).
static func block(body: StaticBody3D, x: float, z: float, w: float, d: float, h: float, color: Color, base := 0.0) -> void:
	Clay.solid(body, Vector3(w, h, d), Vector3(x, base + h * 0.5, z), color)


## Un piso de 1 m de grueso con la cara de arriba en `top`.
static func slab(body: StaticBody3D, x: float, z: float, w: float, d: float, color: Color, top := 0.0) -> void:
	Clay.solid(body, Vector3(w, 1.0, d), Vector3(x, top - 0.5, z), color)


## Pintura en el piso (no choca): un camino a pie, un cantero.
static func mark(body: StaticBody3D, x: float, z: float, w: float, d: float, color: Color, top := 0.0) -> void:
	Clay.box(body, Vector3(w, 0.08, d), Vector3(x, top + 0.04, z), color)


## Una rampa de `w` de ancho que sube `rise` en `run` metros hacia `toward` (x, z), con su mitad en (x, z).
static func ramp(body: StaticBody3D, x: float, z: float, w: float, run: float, rise: float, toward: Vector2,
		color: Color, base := 0.0) -> void:
	var basis := Basis(Vector3.UP, atan2(-toward.x, -toward.y)) * Basis(Vector3.RIGHT, atan2(rise, run))
	var top := Vector3(x, base + rise * 0.5, z)
	Clay.solid(body, Vector3(w, 1.0, Vector2(run, rise).length()), top - basis.y * 0.5, color, basis)


## Un anillo cuadrado (una terraza): de `inner` a `outer` de lado, de `h` de alto.
static func ring(body: StaticBody3D, outer: float, inner: float, h: float, color: Color) -> void:
	var band := (outer - inner) * 0.5
	var mid := (outer + inner) * 0.25
	block(body, 0, -mid, outer, band, h, color)
	block(body, 0, mid, outer, band, h, color)
	block(body, -mid, 0, band, inner, h, color)
	block(body, mid, 0, band, inner, h, color)


## Un cilindro que choca (con una caja): un silo, una chimenea, un tanque.
static func drum(body: StaticBody3D, x: float, z: float, radius: float, h: float, color: Color, base := 0.0) -> void:
	Clay.cylinder(body, radius, h, Vector3(x, base + h * 0.5, z), color)
	Clay.shape_box(body, Vector3(radius * 1.6, h, radius * 1.6), Vector3(x, base + h * 0.5, z))


## DONDE HAY RECURSOS: la baldosa amarilla, unos cubos de 63 cm y un poste con bandera que se ve de lejos.
static func supply(body: StaticBody3D, x: float, z: float, top := 0.0, tile := 6.0) -> void:
	mark(body, x, z, tile, tile, SUPPLY, top + 0.02)
	for i in 3:
		Clay.box(body, Vector3.ONE * 0.63, Vector3(x - 0.8 + i * 0.8, top + 0.32, z), [Clay.RED, Clay.DARK, FIELD][i])
	Clay.box(body, Vector3(0.4, 10.0, 0.4), Vector3(x + 1.6, top + 5.0, z), Clay.DARK)
	Clay.box(body, Vector3(2.6, 1.6, 0.3), Vector3(x + 2.9, top + 9.2, z), SUPPLY)


static func tree(body: StaticBody3D, x: float, z: float, h := 13.0) -> void:
	Clay.cylinder(body, 0.6, h * 0.5, Vector3(x, h * 0.25, z), WOOD)
	Clay.shape_box(body, Vector3(1.2, h * 0.5, 1.2), Vector3(x, h * 0.25, z))
	Clay.sphere(body, h * 0.36, Vector3(x, h * 0.66, z), TREE)


# ------------------------------------------------------------------------------------------------ 1 · Pueblo

## Manzanas de casas de 7 a 20 m con avenidas de 18 m para la meca y una plaza con iglesia. Cada manzana tiene un
## pasillo de 4 m entre sus dos edificios: por ahí pasa una persona y la meca no. Los recursos, en los pasillos.
static func _town(body: StaticBody3D) -> void:
	slab(body, 0, 0, SIZE, SIZE, DIRT)
	var centres: Array[float] = [-78.0, -26.0, 26.0, 78.0]
	for i in 4:
		for j in 4:
			if (i == 1 or i == 2) and (j == 1 or j == 2):
				continue
			var x := centres[i]
			var z := centres[j]
			mark(body, x, z, 34, 34, PATH)
			var tall := 7.0 + ((i * 7 + j * 13) % 4) * 4.5
			var other := 7.0 + ((i * 5 + j * 3 + 2) % 4) * 4.5
			if (i + j) % 2 == 0:
				block(body, x - 9.5, z, 15, 34, tall, WALL if i % 2 == 0 else BRICK)
				block(body, x + 9.5, z, 15, 34, other, BRICK if j % 2 == 0 else WALL)
			else:
				block(body, x, z - 9.5, 34, 15, tall, WALL if j % 2 == 0 else BRICK)
				block(body, x, z + 9.5, 34, 15, other, BRICK if i % 2 == 0 else WALL)
			if (i * 4 + j) % 3 == 0:
				supply(body, x, z, 0.0, 3.4)
	# La plaza: pasto, la iglesia (el hito) y una fuente baja.
	mark(body, 0, 6, 70, 58, GRASS)
	block(body, 0, -30, 16, 22, 13, WALL)
	block(body, 0, -37, 9, 9, 30, WALL)
	block(body, 0, -37, 11, 11, 2, ROOF, 30)
	drum(body, 0, 10, 5, 1.2, STONE)
	supply(body, 14, -24)


# ------------------------------------------------------------------------------------------------ 2 · Cantera

## Tres niveles: el fondo, una terraza a 6 m y el borde a 12 m. La meca sube por rampas anchas o saltando; la gente, por
## escaleras angostas. Bloques de piedra en el fondo para cubrirse. Los recursos, en galpones arriba.
static func _quarry(body: StaticBody3D) -> void:
	slab(body, 0, 0, SIZE, SIZE, DIRT)
	ring(body, 150, 90, 6, STONE)
	ring(body, SIZE, 150, 12, STONE.darkened(0.08))
	ramp(body, 36, 0, 16, 18, 6, Vector2(1, 0), DIRT)
	ramp(body, -20, -36, 16, 18, 6, Vector2(0, -1), DIRT)
	ramp(body, -66, 30, 16, 18, 6, Vector2(-1, 0), DIRT, 6.0)
	ramp(body, 30, 66, 16, 18, 6, Vector2(0, 1), DIRT, 6.0)
	# Las escaleras de la gente.
	ramp(body, -41, 20, 2.5, 8, 6, Vector2(-1, 0), PATH)
	ramp(body, 20, 41, 2.5, 8, 6, Vector2(0, 1), PATH)
	ramp(body, 71, -30, 2.5, 8, 6, Vector2(1, 0), PATH, 6.0)
	ramp(body, -30, -71, 2.5, 8, 6, Vector2(0, -1), PATH, 6.0)
	# Los bloques del fondo.
	block(body, -20, 10, 10, 10, 9, STONE.lightened(0.12))
	block(body, 15, -18, 8, 12, 11, STONE.lightened(0.12))
	block(body, 10, 26, 12, 8, 7, STONE.lightened(0.12))
	block(body, -28, -24, 9, 9, 13, STONE.lightened(0.12))
	# Los galpones y la torre de la cinta (el hito).
	block(body, -62, 56, 10, 6, 5, WALL, 6.0)
	supply(body, -55, 62, 6.0)
	block(body, 62, -56, 10, 6, 5, WALL, 6.0)
	supply(body, 55, -62, 6.0)
	supply(body, 0, 88, 12.0)
	supply(body, -36, 36)
	block(body, 82, -82, 12, 12, 22, ROOF, 12.0)


# ------------------------------------------------------------------------------------------------ 3 · Puerto

## Un patio de contenedores (pilas de 2 a 6, calles de 12 m para la meca, huecos de 3 m para la gente), dos grúas, un
## barco amarrado y el agua de un lado: el borde del muelle es una caída. Los recursos, en los depósitos y el muelle.
static func _harbour(body: StaticBody3D) -> void:
	block(body, 0, -30, SIZE, 140, 6, CONCRETE, -6.0)
	slab(body, 0, 70, SIZE, 60, WATER, -3.0)
	mark(body, 0, 37.5, SIZE, 3, PATH)
	for row in 5:
		for column in 7:
			var height := 2 + (row * 5 + column * 3 + row * column) % 5
			block(body, -85.0 + column * 15.0, -88.0 + row * 18.0, 12, 5.4, 2.6 * height, CARGO[(row + column * 3) % 4])
	for x: float in [-50.0, 30.0]:
		for leg: Vector2 in [Vector2(-12, 14), Vector2(12, 14), Vector2(-12, 34), Vector2(12, 34)]:
			block(body, x + leg.x, leg.y, 3, 3, 30, Clay.METAL)
		block(body, x, 14, 28, 3, 3, Clay.METAL, 27.0)
		block(body, x, 34, 28, 3, 3, Clay.METAL, 27.0)
		block(body, x, 36, 8, 52, 4, Clay.METAL, 30.0)
	block(body, -15, 62, 90, 20, 13, ROOF, -3.0)
	block(body, -50, 62, 12, 16, 10, WALL, 10.0)
	block(body, 58, -76, 50, 30, 12, WALL)
	block(body, 76, -30, 30, 30, 10, BRICK)
	supply(body, 58, -57)
	supply(body, 57, -30)
	supply(body, -90, 28)
	supply(body, -40, -61, 0.0, 3.0)
	supply(body, 80, 28)


# ------------------------------------------------------------------------------------------------ 4 · Río y puente

## Dos orillas y un cauce de 30 m, 6 m más abajo: la meca lo cruza por el puente ancho, por el vado o metiéndose (le
## tapa las piernas). La gente, además, por una pasarela. Lomas para cubrirse. Recursos en cada orilla y bajo el puente.
static func _river(body: StaticBody3D) -> void:
	block(body, -57.5, 0, 85, SIZE, 8, GRASS, -8.0)
	block(body, 57.5, 0, 85, SIZE, 8, GRASS, -8.0)
	slab(body, 0, 0, 30, SIZE, WATER, -6.0)
	block(body, 0, -50, 34, 16, 2, CONCRETE, -2.0)
	block(body, 0, -50, 4, 12, 4, CONCRETE, -6.0)
	block(body, 0, 58, 34, 3, 0.6, PATH, -0.6)
	block(body, 0, 58, 2, 2, 5.4, CONCRETE, -6.0)
	ramp(body, -8.5, 10, 20, 13, 6, Vector2(-1, 0), DIRT, -6.0)
	ramp(body, 8.5, 10, 20, 13, 6, Vector2(1, 0), DIRT, -6.0)
	for hill: Array in [[-60.0, -22.0, 18.0, 12.0], [-45.0, 66.0, 12.0, 8.0], [56.0, 34.0, 20.0, 14.0], [66.0, -68.0, 12.0, 9.0]]:
		var x: float = hill[0]
		var z: float = hill[1]
		var radius: float = hill[2]
		var height: float = hill[3]
		block(body, x, z, radius * 2.0, radius * 2.0, height / 3.0, GRASS.darkened(0.06))
		block(body, x, z, radius * 1.4, radius * 1.4, height / 3.0, GRASS.darkened(0.12), height / 3.0)
		block(body, x, z, radius * 0.8, radius * 0.8, height / 3.0, GRASS.darkened(0.18), height * 2.0 / 3.0)
	drum(body, -82, 20, 4, 14, WALL)
	drum(body, -82, 31, 4, 14, WALL)
	block(body, -76, 46, 16, 10, 7, BRICK)
	supply(body, -68, 28)
	drum(body, 80, -22, 4, 14, WALL)
	block(body, 76, -36, 14, 10, 7, BRICK)
	supply(body, 68, -26)
	supply(body, 0, -32, -6.0)
	mark(body, -40, 58, 46, 2.5, PATH)
	mark(body, 40, 58, 46, 2.5, PATH)


# ------------------------------------------------------------------------------------------------ 5 · Fábrica

## Cuatro galpones grandes alrededor de un patio de 100 m, con las salidas en las esquinas. La gente cruza por adentro
## de los galpones (las puertas oscuras); la meca, por el patio y alrededor. Chimeneas, tanques y vagones para cubrirse.
static func _factory(body: StaticBody3D) -> void:
	slab(body, 0, 0, SIZE, SIZE, CONCRETE)
	block(body, 0, -72, 100, 36, 18, BRICK)
	block(body, 0, 72, 100, 36, 16, BRICK)
	block(body, -78, 0, 30, 70, 14, WALL)
	block(body, 78, 0, 30, 70, 20, WALL)
	for door: Array in [[0.0, -53.9, 5.0, 0.3], [0.0, 53.9, 5.0, 0.3], [-62.9, 0.0, 0.3, 5.0], [62.9, 0.0, 0.3, 5.0]]:
		Clay.box(body, Vector3(door[2], 4.0, door[3]), Vector3(door[0], 2.0, door[1]), Clay.DARK)
	drum(body, -30, -46, 3.5, 42, BRICK.lightened(0.1))
	drum(body, -18, -46, 3.5, 34, BRICK.lightened(0.1))
	for x: float in [30.0, 44.0]:
		for z: float in [28.0, 42.0]:
			drum(body, x, z, 6, 10, Clay.METAL)
	mark(body, 0, -12, 126, 3, ROOF)
	for i in 3:
		block(body, -34.0 + i * 14.0, -12, 12, 3.2, 3.4, CARGO[i])
	supply(body, 6, -50)
	supply(body, -59, 6)
	supply(body, 59, 6)
	supply(body, 6, 50)


# ------------------------------------------------------------------------------------------------ 6 · Campo

## Campo abierto: hileras de árboles que tapan a medias, un terraplén de ruta de 4 m que cruza todo (tapa a una
## persona, no a la meca), y una chacra con granero, silos y un tanque de agua (el hito). Recursos en la chacra, en un
## camión sobre la ruta y en una parva.
static func _farmland(body: StaticBody3D) -> void:
	slab(body, 0, 0, SIZE, SIZE, GRASS)
	mark(body, -55, 40, 70, 90, FIELD)
	mark(body, 60, 45, 60, 80, FIELD.darkened(0.1))
	mark(body, 20, -78, 140, 34, FIELD.lightened(0.08))
	# El terraplén de la ruta: sube y baja por todo su largo.
	block(body, 0, -45, SIZE, 10, 4, DIRT)
	ramp(body, 0, -36, SIZE, 8, 4, Vector2(0, -1), DIRT)
	ramp(body, 0, -54, SIZE, 8, 4, Vector2(0, 1), DIRT)
	block(body, 62, -45, 8, 3, 3, CARGO[1], 4.0)
	supply(body, 54, -45, 4.0, 4.0)
	# La chacra.
	block(body, 0, 34, 26, 14, 10, BRICK)
	block(body, 22, 30, 10, 10, 6, WALL)
	for i in 3:
		drum(body, -22, 26.0 + i * 9.0, 4, 16, WALL)
	for leg: Vector2 in [Vector2(-3, -3), Vector2(3, -3), Vector2(-3, 3), Vector2(3, 3)]:
		block(body, -40 + leg.x, 8 + leg.y, 1.2, 1.2, 20, Clay.METAL)
	drum(body, -40, 8, 5.5, 6, Clay.METAL, 20.0)
	supply(body, 2, 22)
	supply(body, -40, 16)
	drum(body, 62, 52, 5, 4, FIELD.lightened(0.15))
	supply(body, 62, 44)
	# Las hileras de árboles.
	for i in 10:
		tree(body, -84, -22.0 + i * 11.0)
		tree(body, -30.0 + i * 11.0, 84)
	for i in 5:
		tree(body, 30, -20.0 + i * 11.0, 11.0)
	for spot: Vector2 in [Vector2(70, -5), Vector2(80, 4), Vector2(74, 14), Vector2(86, -10), Vector2(-60, -76), Vector2(-48, -82)]:
		tree(body, spot.x, spot.y, 14.0)
