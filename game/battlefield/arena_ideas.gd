class_name ArenaIdeas
extends RefCounted

## LAS ARENAS ABSTRACTAS, EN ARCILLA (13/11/2026): antes de las temáticas (ver BattlefieldIdeas), formas sin tema para
## probar ESCALA, ALTURAS, COBERTURA, EL BORDE (circular) y UN OBSTÁCULO DE CIRCUNSTANCIA por arena (algo que pasa o se
## mueve, como un tren), con la idea de las arenas de peleas de jefes. El usuario: «quiero experimentar con formas
## abstractas, escalas, alturas, y lugares para cubrirse, delimitación del mapa (circular), obstáculos circunstanciales».
## Lo azul es LO QUE SE MUEVE (dibujado quieto, en un momento de su recorrido); lo amarillo con bandera, los recursos.

const NAMES: Array[String] = ["Anillo de pilares", "Terrazas", "Cráter que se inunda", "Tren", "Columnas que suben",
	"Muro que se cierra", "Barredora", "Islas"]
const LINES: Array[String] = [
	"Ø 140 m · muro de 10 m · doce pilares de 30 m para cubrirse; algunos rotos, más bajos",
	"Ø 180 m · borde: caída · tres pisos (0, 5 y 10 m) que la meca salta; la gente sube por escaleras",
	"Ø 160 m · borde: el labio · el fondo a −12 m; el agua sube y baja y empuja a todos arriba",
	"Ø 180 m · muro con dos túneles · un tren cruza por el medio cada tanto: tapa, separa y atropella",
	"Ø 160 m · muro · una grilla de columnas que suben y bajan: la cobertura cambia de lugar",
	"Ø 220 m · un muro que se va cerrando hasta Ø 120 · tapias bajas: tapan a la gente, no a la meca",
	"Ø 120 m · borde: caída · un brazo gira a 3–6 m del piso: la gente pasa abajo, la meca lo salta",
	"Ø 200 m · vacío alrededor · islas a saltos de meca; la gente cruza por pasarelas angostas",
]
## El radio de cada arena (m): la cámara de arriba se aleja según esto.
const RADII: Array[float] = [70.0, 90.0, 80.0, 90.0, 80.0, 110.0, 60.0, 100.0]

const FLOOR := Color(0.78, 0.76, 0.71)
const FLOOR_LOW := Color(0.70, 0.68, 0.63)
const FLOOR_HIGH := Color(0.85, 0.83, 0.78)
const BLOCK := Color(0.62, 0.61, 0.59)
const BOUND := Color(0.52, 0.50, 0.48)
const VOID := Color(0.42, 0.44, 0.46)
const WATER := Color(0.40, 0.55, 0.64, 0.75)
const MOVES := Color(0.36, 0.48, 0.66)
const MOVES_TRACE := Color(0.55, 0.66, 0.80)
const PATH := BattlefieldIdeas.PATH


static func build(index: int, parent: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Arena"
	parent.add_child(body)
	match index:
		0: _pillars(body)
		1: _terraces(body)
		2: _crater(body)
		3: _train(body)
		4: _columns(body)
		5: _closing(body)
		6: _sweeper(body)
		_: _islands(body)
	return body


static func viewpoint(index: int) -> Array[Vector3]:
	match index:
		0: return [Vector3(0, 0, 48), Vector3(0.2, 0, -1)]
		1: return [Vector3(-10, 0, 76), Vector3(0.15, 0, -1)]
		2: return [Vector3(0, -12, 30), Vector3(0, 0, -1)]
		3: return [Vector3(-30, 0, 50), Vector3(0.4, 0, -1)]
		4: return [Vector3(0, 0, 40), Vector3(0.1, 0, -1)]
		5: return [Vector3(-10, 0, 46), Vector3(0.1, 0, -1)]
		6: return [Vector3(-8, 0, 44), Vector3(0.25, 0, -1)]
		_: return [Vector3(0, 0, 70), Vector3(0, 0, -1)]


# ------------------------------------------------------------------------------------------------ las piezas

## Un disco de piso de `thick` de grueso con la cara de arriba en `top`.
static func disc(body: StaticBody3D, radius: float, top: float, color: Color, thick := 1.0, at := Vector2.ZERO) -> void:
	var centre := Vector3(at.x, top - thick * 0.5, at.y)
	Clay.cylinder(body, radius, thick, centre, color)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = radius
	cylinder.height = thick
	shape.shape = cylinder
	shape.position = centre
	body.add_child(shape)


## Una corona (de `inner` a `outer`) de cajas, de `h` de alto desde `base`. `gaps`: ángulos (rad) donde se abre.
static func annulus(body: StaticBody3D, inner: float, outer: float, h: float, color: Color, base := 0.0,
		gaps: Array[float] = [], gap_width := 0.0) -> void:
	var mid := (inner + outer) * 0.5
	var count := maxi(16, int(TAU * mid / 6.0))
	var length := TAU * mid / count * 1.06
	for i in count:
		var angle := TAU * (i + 0.5) / count
		var skip := false
		for gap in gaps:
			if absf(wrapf(angle - gap, -PI, PI)) * mid < gap_width * 0.5:
				skip = true
		if skip:
			continue
		var basis := Basis(Vector3.UP, -angle)
		var at := Vector3(cos(angle) * mid, base + h * 0.5, sin(angle) * mid)
		Clay.solid(body, Vector3(outer - inner, h, length), at, color, basis)


static func at_angle(radius: float, degrees: float) -> Vector2:
	return Vector2(cos(deg_to_rad(degrees)), sin(deg_to_rad(degrees))) * radius


static func block(body: StaticBody3D, p: Vector2, w: float, d: float, h: float, color := BLOCK, base := 0.0) -> void:
	BattlefieldIdeas.block(body, p.x, p.y, w, d, h, color, base)


static func supply(body: StaticBody3D, p: Vector2, top := 0.0) -> void:
	BattlefieldIdeas.supply(body, p.x, p.y, top, 4.0)


# ------------------------------------------------------------------------------------------------ 1 · Anillo de pilares

## La sala de jefe clásica: un círculo cerrado y pilares gruesos para esconderse detrás y que el jefe rompa.
static func _pillars(body: StaticBody3D) -> void:
	disc(body, 70, 0, FLOOR)
	annulus(body, 70, 74, 10, BOUND)
	for i in 12:
		var p := at_angle(44, i * 30.0 + 15.0)
		var tall := 30.0 if i % 4 != 1 else 11.0
		BattlefieldIdeas.drum(body, p.x, p.y, 5, tall, BLOCK)
	for degrees: float in [15.0, 135.0, 255.0]:
		supply(body, at_angle(54, degrees))


# ------------------------------------------------------------------------------------------------ 2 · Terrazas

## Alturas: tres pisos concéntricos de 5 m (la meca los salta; desde arriba se ve y se le pega al de abajo). Los
## escalones de la gente son rampas angostas. Borde: se cae.
static func _terraces(body: StaticBody3D) -> void:
	disc(body, 90, 0, FLOOR, 4.0)
	disc(body, 60, 5, FLOOR_HIGH, 5.0)
	disc(body, 30, 10, FLOOR_HIGH.lightened(0.1), 5.0)
	disc(body, 300, -40, VOID)
	for degrees: float in [30.0, 150.0, 270.0]:
		var p := at_angle(66, degrees)
		BattlefieldIdeas.ramp(body, p.x, p.y, 2.5, 10, 5, -p.normalized(), PATH)
		var q := at_angle(36, degrees + 60.0)
		BattlefieldIdeas.ramp(body, q.x, q.y, 2.5, 10, 5, -q.normalized(), PATH, 5.0)
	for degrees: float in [80.0, 200.0, 320.0]:
		block(body, at_angle(76, degrees), 9, 9, 12)
	supply(body, at_angle(78, 0.0))
	supply(body, at_angle(45, 240.0), 5.0)
	supply(body, Vector2.ZERO, 10.0)


# ------------------------------------------------------------------------------------------------ 3 · Cráter que se inunda

## Un pozo con gradas. El agua sube y baja (dibujada a −6 m): lo de abajo queda tapado y hay que pelear arriba. Los
## recursos, en el fondo: hay que bajar cuando el agua baja.
static func _crater(body: StaticBody3D) -> void:
	disc(body, 40, -12, FLOOR_LOW)
	annulus(body, 40, 56, 4, FLOOR_LOW.lightened(0.05), -12)
	annulus(body, 56, 70, 8, FLOOR, -12)
	annulus(body, 70, 82, 12, FLOOR_HIGH, -12)
	disc(body, 300, -12.5, VOID)
	Clay.cylinder(body, 70, 0.2, Vector3(0, -6, 0), WATER)
	for i in 4:
		block(body, at_angle(22, i * 90.0 + 45.0), 8, 8, 9, BLOCK, -12)
	supply(body, Vector2(0, 0), -12)
	supply(body, at_angle(76, 200.0))


# ------------------------------------------------------------------------------------------------ 4 · Tren

## Un círculo cruzado por una vía; el tren (cuatro vagones de 6 m de alto) entra por un túnel y sale por el otro. Mientras
## pasa tapa y separa; si te agarra, te lleva. Bloques a los costados para esperarlo.
static func _train(body: StaticBody3D) -> void:
	disc(body, 90, 0, FLOOR)
	annulus(body, 90, 94, 14, BOUND, 0, [0.0, PI] as Array[float], 14.0)
	BattlefieldIdeas.mark(body, 0, 0, 190, 8, BLOCK.darkened(0.15))
	for x: float in [-40.0, -18.0, 4.0, 26.0]:
		BattlefieldIdeas.block(body, x, 0, 20, 6, 6, MOVES)
	BattlefieldIdeas.block(body, 48, 0, 6, 6, 8, MOVES.darkened(0.2))
	for side: float in [-1.0, 1.0]:
		block(body, Vector2(-50, 28 * side), 16, 8, 14)
		block(body, Vector2(30, 34 * side), 10, 10, 18)
		block(body, Vector2(0, 60 * side), 22, 6, 9)
	supply(body, Vector2(-60, 46))
	supply(body, Vector2(60, -46))


# ------------------------------------------------------------------------------------------------ 5 · Columnas que suben

## Una grilla de columnas cuadradas que suben y bajan de a poco (dibujadas en un momento: de 1 a 18 m). La cobertura que
## había deja de estar; una que sube puede levantar a quien esté arriba.
static func _columns(body: StaticBody3D) -> void:
	disc(body, 80, 0, FLOOR)
	annulus(body, 80, 84, 10, BOUND)
	var heights: Array[float] = [1.0, 6.0, 18.0, 3.0, 12.0, 9.0, 15.0, 2.0]
	var n := 0
	for i in range(-3, 4):
		for j in range(-3, 4):
			var p := Vector2(i, j) * 20.0
			if p.length() > 64.0 or (i + j) % 2 != 0:
				continue
			block(body, p, 10, 10, heights[n % heights.size()], MOVES if heights[n % heights.size()] > 4.0 else MOVES_TRACE)
			n += 1
	supply(body, Vector2(10, 10))
	supply(body, Vector2(-50, -10))


# ------------------------------------------------------------------------------------------------ 6 · Muro que se cierra

## Grande al empezar (Ø 220) y un muro que se va cerrando hasta Ø 120 (dibujado a mitad de camino, con la marca de donde
## termina): la pelea empieza lejos y termina cuerpo a cuerpo. Tapias de 4 m, que esconden a una persona y no a la meca.
static func _closing(body: StaticBody3D) -> void:
	disc(body, 110, 0, FLOOR)
	annulus(body, 110, 113, 3, BOUND)
	annulus(body, 85, 88, 16, MOVES)
	annulus(body, 59, 61, 0.1, MOVES_TRACE)
	for i in 10:
		var p := at_angle(40.0 + (i % 3) * 22.0, i * 36.0 + 10.0)
		var basis_turn := float(i * 36 + 100)
		var wall_dir := Vector2(cos(deg_to_rad(basis_turn)), sin(deg_to_rad(basis_turn)))
		block(body, p, 14 if absf(wall_dir.x) > 0.5 else 2, 2 if absf(wall_dir.x) > 0.5 else 14, 4)
	supply(body, at_angle(98, 30.0))
	supply(body, at_angle(98, 210.0))
	supply(body, Vector2.ZERO)


# ------------------------------------------------------------------------------------------------ 7 · Barredora

## Chica y apretada. Un brazo largo gira alrededor de un eje: va de 3 a 6 m del piso, así que una persona pasa por abajo
## y la meca tiene que saltarlo (o agacharse no alcanza). Borde: se cae.
static func _sweeper(body: StaticBody3D) -> void:
	disc(body, 60, 0, FLOOR, 4.0)
	disc(body, 300, -40, VOID)
	BattlefieldIdeas.drum(body, 0, 0, 6, 12, BLOCK)
	Clay.solid(body, Vector3(56, 3, 3), Vector3(31, 4.5, 0), MOVES, Basis(Vector3.UP, deg_to_rad(-30)))
	annulus(body, 54, 56, 0.1, MOVES_TRACE)
	for degrees: float in [100.0, 220.0, 340.0]:
		block(body, at_angle(40, degrees), 7, 7, 2.5)
	supply(body, at_angle(48, 160.0))
	supply(body, at_angle(48, 280.0))


# ------------------------------------------------------------------------------------------------ 8 · Islas

## Islas redondas sobre el vacío, a saltos de meca (14 m de alto; 12 a 20 de hueco). La gente cruza por pasarelas de 2 m.
## Caerse es perder: el borde es todo.
static func _islands(body: StaticBody3D) -> void:
	disc(body, 400, -50, VOID)
	var spots: Array[Vector2] = [Vector2(0, 70), Vector2(0, 0), Vector2(-62, 30), Vector2(60, 30), Vector2(-50, -55),
		Vector2(50, -55)]
	var sizes: Array[float] = [22.0, 30.0, 18.0, 20.0, 22.0, 16.0]
	for i in spots.size():
		disc(body, sizes[i], 0, FLOOR if i != 1 else FLOOR_HIGH, 20.0, spots[i])
	for pair: Vector2i in [Vector2i(0, 1), Vector2i(1, 2), Vector2i(1, 3), Vector2i(1, 4), Vector2i(1, 5), Vector2i(2, 4)]:
		var a := spots[pair.x]
		var b := spots[pair.y]
		var mid := (a + b) * 0.5
		var along := b - a
		Clay.solid(body, Vector3(2, 0.4, along.length()), Vector3(mid.x, -0.2, mid.y), PATH,
			Basis(Vector3.UP, atan2(along.x, along.y)))
	block(body, Vector2(0, -6), 10, 10, 16)
	block(body, Vector2(-62, 30), 6, 6, 10)
	supply(body, Vector2(60, 30))
	supply(body, Vector2(50, -55))
