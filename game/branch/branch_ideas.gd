class_name BranchIdeas
extends RefCounted

## LAS IDEAS DE SUCURSAL, EN ARCILLA (13/11/2026): seis distribuciones de la base entre peleas, para que el usuario elija
## una. Cada una tiene lo mismo: EL HANGAR donde se estaciona la meca (15 m parada; su pasarela de abajo, a 7,4 m), LA
## OFICINA con el tablero de contratos (verde, con papeles), EL DEPÓSITO de recursos (estantes con cubos de 63 cm) y POR
## DÓNDE SE SUBE a la meca. Sin mecánicas: sólo el lugar. Lo claro es por donde camina la gente; la meca sale hacia −Z.
## *Es para mirar y descartar: la elegida pasa a su parcela y este archivo se borra.*

const NAMES: Array[String] = ["Todo bajo un techo", "Patio en U", "Torre de embarque", "Oficina sobre el portón",
	"Pozo", "Andén"]
const LINES: Array[String] = [
	"un galpón: la oficina en un entrepiso a 7,4 m con el depósito al lado, y un puente derecho a la meca",
	"al aire libre: la bahía al medio, la oficina a un lado y el depósito al otro; una torre de escalera para subir",
	"una explanada con una escalerilla rodante (como la de un avión) que se arrima a la meca; oficina y depósito en casillas",
	"un galpón largo: la oficina cruza arriba del portón y mira la bahía; el depósito abajo; pasarela por el costado",
	"la meca se estaciona en un pozo de 7,4 m: su pasarela queda al nivel del piso y todo se camina sin subir",
	"un andén a 7,4 m al costado de la bahía, con la oficina y el depósito arriba: se carga a nivel, se sube una vez",
]

## La pasarela de abajo de la meca parada.
const DECK := 7.4
const BAY := Vector2(26.0, 30.0)

const GROUND := Color(0.72, 0.70, 0.66)
const CONCRETE := Color(0.70, 0.70, 0.68)
const SHED := Color(0.66, 0.67, 0.68)
const WALL := Color(0.80, 0.76, 0.68)
const BRICK := Color(0.64, 0.47, 0.40)
const WALK := Color(0.92, 0.89, 0.80)
const BOARD := Color(0.26, 0.40, 0.32)
const PAPER := Color(0.95, 0.93, 0.86)
const WOOD := Color(0.50, 0.40, 0.31)
const GLASS := Color(0.55, 0.75, 0.85, 0.35)
const MARK := Color(0.95, 0.75, 0.15)
const CUBES: Array[Color] = [Color(0.78, 0.18, 0.15), Color(0.36, 0.38, 0.40), Color(0.74, 0.62, 0.36),
	Color(0.50, 0.55, 0.45), Color(0.86, 0.78, 0.60)]


static func build(index: int, parent: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Sucursal"
	parent.add_child(body)
	match index:
		0: _one_roof(body)
		1: _yard(body)
		2: _boarding_tower(body)
		3: _gate_office(body)
		4: _pit(body)
		_: _platform(body)
	return body


## Dónde va parada la meca (el piso bajo sus pies) y hacia dónde mira la cámara de la persona: `[meca, ojo, mira]`.
static func viewpoint(index: int) -> Array[Vector3]:
	match index:
		0: return [Vector3.ZERO, Vector3(-1, DECK + 1.7, 26.5), Vector3(0, DECK + 2.0, 0)]
		1: return [Vector3.ZERO, Vector3(-30, 1.7, -22), Vector3(0, 6, 10)]
		2: return [Vector3.ZERO, Vector3(-28, 1.7, -24), Vector3(0, 6, 0)]
		3: return [Vector3(0, 0, 10), Vector3(-10, 1.7, -24), Vector3(0, 10, 10)]
		4: return [Vector3(0, -DECK, 0), Vector3(-22, 1.7, 26), Vector3(0, 0, 0)]
		_: return [Vector3.ZERO, Vector3(-20, DECK + 1.7, -14), Vector3(0, DECK + 2.0, 6)]


# ------------------------------------------------------------------------------------------------ las piezas

static func block(body: StaticBody3D, x: float, z: float, w: float, d: float, h: float, color: Color, base := 0.0) -> void:
	Clay.solid(body, Vector3(w, h, d), Vector3(x, base + h * 0.5, z), color)


static func slab(body: StaticBody3D, x: float, z: float, w: float, d: float, top: float, color: Color, thick := 0.5) -> void:
	Clay.solid(body, Vector3(w, thick, d), Vector3(x, top - thick * 0.5, z), color)


static func paint(body: StaticBody3D, x: float, z: float, w: float, d: float, color: Color, top := 0.0) -> void:
	Clay.box(body, Vector3(w, 0.04, d), Vector3(x, top + 0.02, z), color)


## Un tramo de escalera (una losa inclinada) de `from` a `to` (las dos puntas, arriba de la losa), de `width`.
static func flight(body: StaticBody3D, from: Vector3, to: Vector3, width := 2.4) -> void:
	var along := to - from
	var basis := Basis.looking_at(along.normalized(), Vector3.UP)
	Clay.solid(body, Vector3(width, 0.4, along.length()), (from + to) * 0.5 - basis.y * 0.2, WALK, basis)


## El tablero de contratos: una pizarra verde con papeles sobre una pared, mirando hacia `facing`, y un mostrador
## adelante. `at` es el pie de la pared, en el piso.
static func contract_board(body: StaticBody3D, at: Vector3, facing: Vector3) -> void:
	var basis := Basis.looking_at(-facing, Vector3.UP)
	var middle := at + Vector3.UP * 1.9
	Clay.box(body, Vector3(5.0, 2.6, 0.15), middle, BOARD).basis = basis
	for i in 6:
		var spot := middle + basis * Vector3(-1.8 + (i % 3) * 1.8, 0.55 - floorf(i / 3.0) * 1.0, 0.1)
		Clay.box(body, Vector3(0.9, 0.7, 0.04), spot, PAPER).basis = basis
	Clay.solid(body, Vector3(3.0, 0.9, 1.2), at + facing * 2.6 + Vector3.UP * 0.45, WOOD, basis)


## Un estante de depósito de `length` (a lo largo de X local), con cubos de 63 cm en tres alturas.
static func shelf(body: StaticBody3D, at: Vector3, length: float, yaw := 0.0) -> void:
	var basis := Basis(Vector3.UP, yaw)
	for level in 3:
		Clay.solid(body, Vector3(length, 0.1, 0.9), at + basis * Vector3(0, 0.05 + level * 0.9, 0), WOOD, basis)
		var count := int(length / 0.9)
		for i in count:
			if (i * 7 + level * 3) % 5 == 0:
				continue
			Clay.box(body, Vector3.ONE * 0.63, at + basis * Vector3(-length * 0.5 + 0.45 + i * 0.9, 0.42 + level * 0.9, 0),
				CUBES[(i + level) % CUBES.size()]).basis = basis
	for end: float in [-1.0, 1.0]:
		Clay.box(body, Vector3(0.1, 2.7, 0.9), at + basis * Vector3(end * length * 0.5, 1.35, 0), WOOD).basis = basis


## Una oficina chica: la caja, la ventana y la puerta hacia `facing`.
static func office(body: StaticBody3D, at: Vector3, size: Vector3, facing: Vector3, color := WALL) -> void:
	Clay.solid(body, size, at + Vector3.UP * size.y * 0.5, color)
	var front := at + facing * (Vector3(size.x, 0, size.z) * 0.5).dot(facing.abs()) + Vector3.UP * size.y * 0.55
	var width := (size.x if is_zero_approx(facing.x) else size.z) * 0.6
	var sideways := Vector3(absf(facing.z), 0, absf(facing.x))
	Clay.box(body, sideways * width + Vector3.UP * size.y * 0.35 + facing.abs() * 0.1, front, GLASS)


## La marca de dónde se estaciona: un rectángulo amarillo en el piso, del tamaño de la bahía.
static func bay_mark(body: StaticBody3D, at: Vector3) -> void:
	for side: float in [-1.0, 1.0]:
		Clay.box(body, Vector3(0.5, 0.05, BAY.y), at + Vector3(side * BAY.x * 0.5, 0.03, 0), MARK)
		Clay.box(body, Vector3(BAY.x, 0.05, 0.5), at + Vector3(0, 0.03, side * BAY.y * 0.5), MARK)


## Un galpón: tres paredes (la de −Z abierta, por donde sale la meca) y cerchas en vez de techo (para ver adentro).
static func shed(body: StaticBody3D, at: Vector3, size: Vector3, color := SHED) -> void:
	var t := 0.8
	block(body, at.x - size.x * 0.5, at.z, t, size.z, size.y, color, at.y)
	block(body, at.x + size.x * 0.5, at.z, t, size.z, size.y, color, at.y)
	block(body, at.x, at.z + size.z * 0.5, size.x, t, size.y, color, at.y)
	for i in 5:
		var z := at.z - size.z * 0.5 + size.z * (i + 0.5) / 5.0
		Clay.box(body, Vector3(size.x, 0.6, 0.6), Vector3(at.x, at.y + size.y, z), Clay.DARK.lightened(0.2))


# ------------------------------------------------------------------------------------------------ 1 · todo bajo un techo

static func _one_roof(body: StaticBody3D) -> void:
	slab(body, 0, 4, 60, 60, 0, CONCRETE)
	shed(body, Vector3(0, 0, 4), Vector3(48, 24, 52))
	bay_mark(body, Vector3.ZERO)
	# El entrepiso de atrás, a la altura de la pasarela: la oficina a un lado, el depósito al otro.
	slab(body, 0, 24, 47, 8, DECK, CONCRETE.darkened(0.08), 0.6)
	block(body, 0, 24, 1.0, 8, DECK - 0.6, CONCRETE.darkened(0.15))
	office(body, Vector3(-14, DECK, 24.5), Vector3(14, 3.6, 6), Vector3(0, 0, -1))
	contract_board(body, Vector3(-14, DECK, 21.4), Vector3(0, 0, -1))
	for i in 3:
		shelf(body, Vector3(9, DECK, 22 + i * 2.2), 14.0)
	# El puente derecho a la pasarela de atrás de la meca y la escalera desde el piso.
	slab(body, 0, 13.5, 3, 7, DECK, WALK, 0.4)
	flight(body, Vector3(22, 0, -2), Vector3(22, DECK, 18), 2.4)


# ------------------------------------------------------------------------------------------------ 2 · patio en U

static func _yard(body: StaticBody3D) -> void:
	slab(body, 0, 6, 90, 60, 0, GROUND)
	paint(body, 0, 10, 80, 40, CONCRETE)
	bay_mark(body, Vector3.ZERO)
	for x: float in [-15.0, 15.0]:
		for z: float in [-14.0, 14.0]:
			block(body, x, z, 1.2, 1.2, 22, Clay.METAL)
	Clay.box(body, Vector3(31, 1, 1), Vector3(0, 22.5, -14), Clay.METAL)
	Clay.box(body, Vector3(31, 1, 1), Vector3(0, 22.5, 14), Clay.METAL)
	office(body, Vector3(-34, 0, 8), Vector3(16, 8, 20), Vector3(1, 0, 0))
	contract_board(body, Vector3(-25.9, 0, 2), Vector3(1, 0, 0))
	block(body, 34, 8, 16, 20, 7, BRICK)
	Clay.box(body, Vector3(0.1, 5, 10), Vector3(25.95, 2.5, 8), Clay.DARK)
	for i in 3:
		shelf(body, Vector3(22.5, 0, 0.5 + i * 2.6), 6.0, PI * 0.5)
	# La torre de escalera, al lado de la pasarela de atrás de la meca.
	block(body, 0, 20, 8, 6, DECK, Clay.METAL.darkened(0.1))
	flight(body, Vector3(-12, 0, 20), Vector3(-4, DECK, 20), 2.4)
	slab(body, 0, 15.5, 3, 4, DECK, WALK, 0.4)


# ------------------------------------------------------------------------------------------------ 3 · torre de embarque

static func _boarding_tower(body: StaticBody3D) -> void:
	slab(body, 0, 0, 80, 70, 0, CONCRETE)
	bay_mark(body, Vector3.ZERO)
	for corner: Vector2 in [Vector2(-36, -31), Vector2(36, -31), Vector2(-36, 31), Vector2(36, 31)]:
		block(body, corner.x, corner.y, 0.6, 0.6, 18, Clay.DARK)
		Clay.box(body, Vector3(2.4, 0.8, 1.2), Vector3(corner.x, 18.4, corner.y), MARK)
	# La escalerilla rodante, arrimada atrás de la meca: rieles en el piso por donde se corre.
	paint(body, 0, 20, 30, 0.4, Clay.DARK, 0)
	paint(body, 0, 23, 30, 0.4, Clay.DARK, 0)
	block(body, 0, 13.5, 4, 3, 0.5, Clay.METAL, DECK - 0.5)
	for corner: Vector2 in [Vector2(-1.8, 12.2), Vector2(1.8, 12.2), Vector2(-1.8, 14.8), Vector2(1.8, 14.8)]:
		block(body, corner.x, corner.y, 0.3, 0.3, DECK - 0.5, Clay.METAL)
	flight(body, Vector3(0, 0, 30), Vector3(0, DECK, 15), 2.6)
	block(body, 0, 21.5, 4, 4, 0.8, MARK)
	office(body, Vector3(-28, 0, 24), Vector3(10, 4, 7), Vector3(1, 0, 0), WALL)
	contract_board(body, Vector3(-28, 0, 20.4), Vector3(0, 0, -1))
	# El depósito: contenedores, uno abierto con estantes.
	var tones: Array[Color] = [Color(0.36, 0.46, 0.52), Color(0.55, 0.36, 0.30), Color(0.50, 0.52, 0.42)]
	for i in 3:
		block(body, 26, 26 - i * 3.2, 12, 2.6, 2.6, tones[i])
	block(body, 26, 26, 12, 2.6, 2.6, tones[2], 2.6)
	block(body, 29, 10, 6, 12, 2.6, BRICK)
	shelf(body, Vector3(25.4, 0, 10), 10.0, PI * 0.5)


# ------------------------------------------------------------------------------------------------ 4 · oficina sobre el portón

static func _gate_office(body: StaticBody3D) -> void:
	slab(body, 0, 10, 50, 76, 0, CONCRETE)
	shed(body, Vector3(0, 0, 14), Vector3(34, 24, 56))
	bay_mark(body, Vector3(0, 0, 10))
	# La oficina cruza el portón (abierto hacia −Z) arriba, de pared a pared, con un vidrio que mira adentro.
	slab(body, 0, -12, 34, 8, 18, WALL, 0.6)
	block(body, 0, -12, 34, 8, 5, WALL, 18)
	Clay.box(body, Vector3(30, 3, 0.1), Vector3(0, 20.6, -7.95), GLASS)
	contract_board(body, Vector3(0, 18.3, -15.8), Vector3(0, 0, 1))
	# El depósito, abajo, a los dos lados del portón, y la escalera a la oficina.
	for side: float in [-1.0, 1.0]:
		shelf(body, Vector3(side * 14.5, 0, -4), 10.0, PI * 0.5)
	flight(body, Vector3(15.5, 0, 10), Vector3(15.5, 18, -6), 2.0)
	# La pasarela por el costado, a la altura de la de la meca, con su escalera.
	slab(body, -14.5, 18, 4, 36, DECK, WALK, 0.4)
	flight(body, Vector3(-14.5, 0, 50), Vector3(-14.5, DECK, 36.2), 2.4)
	slab(body, -8.5, 14, 8, 3, DECK, WALK, 0.4)


# ------------------------------------------------------------------------------------------------ 5 · pozo

static func _pit(body: StaticBody3D) -> void:
	slab(body, -27, 0, 28, 70, 0, CONCRETE)
	slab(body, 27, 0, 28, 70, 0, CONCRETE)
	slab(body, 0, 25, 26, 20, 0, CONCRETE)
	slab(body, 0, 0, 26, 30, -DECK, CONCRETE.darkened(0.12))
	for side: float in [-1.0, 1.0]:
		block(body, side * 13.4, 0, 0.8, 30, DECK, CONCRETE.darkened(0.2), -DECK)
	# La rampa por donde sale la meca (hacia −Z), larga y suave.
	var ramp_basis := Basis(Vector3.RIGHT, -atan2(DECK, 40.0))
	Clay.solid(body, Vector3(26, 1, Vector2(40, DECK).length()), Vector3(0, -DECK * 0.5 - 0.5, -35), CONCRETE.darkened(0.06),
		ramp_basis)
	bay_mark(body, Vector3(0, -DECK, 0))
	# Puentes cortos a nivel, de la oficina y del depósito a la pasarela de la meca.
	slab(body, 0, 13.5, 3, 7, 0, WALK, 0.4)
	slab(body, -9.5, 2, 7, 3, 0, WALK, 0.4)
	slab(body, 9.5, 2, 7, 3, 0, WALK, 0.4)
	office(body, Vector3(-28, 0, 10), Vector3(14, 4, 18), Vector3(1, 0, 0))
	contract_board(body, Vector3(-20.9, 0, 10), Vector3(1, 0, 0))
	block(body, 28, 10, 14, 18, 6, BRICK)
	Clay.box(body, Vector3(0.1, 4, 8), Vector3(20.95, 2, 6), Clay.DARK)
	for i in 2:
		shelf(body, Vector3(17.5, 0, -6 - i * 3.0), 8.0)


# ------------------------------------------------------------------------------------------------ 6 · andén

static func _platform(body: StaticBody3D) -> void:
	slab(body, 0, 0, 70, 60, 0, CONCRETE)
	bay_mark(body, Vector3.ZERO)
	# El andén, a la altura de la pasarela, del lado izquierdo y atrás de la bahía.
	block(body, -21, 4, 14, 44, DECK, CONCRETE.darkened(0.1))
	block(body, -5, 22, 18, 8, DECK, CONCRETE.darkened(0.1))
	paint(body, -14.4, 4, 0.5, 44, MARK, DECK)
	office(body, Vector3(-22, DECK, 20), Vector3(10, 3.6, 8), Vector3(1, 0, 0))
	contract_board(body, Vector3(-16.9, DECK, 13), Vector3(1, 0, 0))
	for i in 3:
		shelf(body, Vector3(-25, DECK, -14 + i * 2.6), 8.0)
	flight(body, Vector3(-21, 0, -34), Vector3(-21, DECK, -18.2), 2.6)
