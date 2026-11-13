class_name Battlefield
extends RefCounted

## EL MAPA DE PELEA (13/11/2026; ver docs/technical/mapa.md): una arena circular de Ø 260 m, PLANA Y MAYORMENTE LIBRE para que
## las mecas peleen, se muevan y esquiven. Lo de la gente va JUNTO, EN EL BORDE: cuatro barrios chicos contra el muro,
## con casas de 11 m, edificios de 30 y uno de 44 de hito, ESCALERAS DE AFUERA para subir a los techos (un mejor ángulo,
## tirar la bomba, esconderse), autos y los RECURSOS en la calle de adelante de cada barrio (y unos arriba de un edificio alto). Al medio, sólo TRES RUINAS
## para cubrirse, lejos una de otra: una pared rota, una esquina de edificio y una tapia baja.
## El usuario eligió esta distribución entre ocho maquetas: «vamos a ir con la opción 1… alguno de los edificios más
## altos… algunos pocos objetos más al medio que sirvan como para cubrirse… pero que no estorbe tanto».
##
## Todo es un `StaticBody3D` (el piso de la meca es SÓLO lo estático) en arcilla (`Clay`): el arte viene después. La
## distribución es fija: una semilla propia, no la de la parcela (es UN mapa).

const RADIUS := 130.0
## El muro del borde: se ve de 8 m, pero choca hasta 40 (la meca salta 14 m y no tiene que salirse).
const WALL_SEEN := 8.0
const WALL_SOLID := 40.0
const WALL_THICK := 4.0
## Las alturas de los edificios: el que tapa a la gente, el que tapa a la meca y el hito.
const LOW := 11.0
const TALL := 30.0
const LANDMARK := 44.0
## LA ESCALERA DE INCENDIO: en zigzag (dos carriles pegados a una fachada), UN TRAMO POR PISO de unos `STORY` m, con un
## descanso de los dos carriles en cada vuelta. Los tramos y los descansos son los de `Stairs` (escalones de 15 cm para
## los pies, rampa para la cápsula: ver docs/technical/escaleras.md).
const STORY := 3.0
const LANE := 1.4
const LANDING := 1.6
## LOS BARRIOS: en qué ángulo del borde (grados) y cuánto abarcan; cuántos edificios de 30 m; y si lleva el hito.
const BARRIOS := [[20.0, 80.0, 2, false], [115.0, 70.0, 2, false], [200.0, 60.0, 1, false], [285.0, 90.0, 2, true]]
## Dónde nace la meca: en el centro libre, mirando al medio.
const SPAWN := Vector2(0.0, 45.0)
const LAYOUT_SEED := 501

const GROUND := Color(0.74, 0.71, 0.64)
const BOUND := Color(0.52, 0.50, 0.48)
const STAIRS := Color(0.92, 0.89, 0.80)
const ROOF := Color(0.47, 0.40, 0.37)
const RUIN := Color(0.64, 0.61, 0.57)
const PAD := Color(0.86, 0.72, 0.38)
const POLE := Color(0.2, 0.21, 0.23)
const FLAG := Color(0.95, 0.72, 0.15)
const TONES: Array[Color] = [Color(0.80, 0.76, 0.68), Color(0.64, 0.47, 0.40), Color(0.66, 0.68, 0.70),
	Color(0.74, 0.66, 0.56)]
const CARS: Array[Color] = [Color(0.56, 0.32, 0.28), Color(0.34, 0.42, 0.50), Color(0.52, 0.54, 0.44),
	Color(0.80, 0.76, 0.64), Color(0.30, 0.30, 0.32)]


## Arma el mapa colgado de `parent`, centrado en su origen, con el piso en y = 0. Devuelve el cuerpo estático; los
## recursos (cuerpos que se agarran) van colgados de `parent` aparte.
static func build(parent: Node3D) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "Mapa"
	parent.add_child(body)
	var rng := RandomNumberGenerator.new()
	rng.seed = LAYOUT_SEED
	_ground(body)
	_wall(body)
	var supplies: Array[Vector3] = []
	for barrio: Array in BARRIOS:
		_barrio(body, rng, barrio[0], barrio[1], barrio[2], barrio[3], supplies)
	_ruins(body)
	var kinds := PackageArchetype.catalogue()
	for i in supplies.size():
		_supply(body, parent, supplies[i], kinds, i)
	return body


# ------------------------------------------------------------------------------------------------ el piso y el borde

static func _ground(body: StaticBody3D) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = RADIUS
	mesh.bottom_radius = RADIUS
	mesh.height = 1.0
	mesh.radial_segments = 96
	var disc := MeshInstance3D.new()
	disc.mesh = mesh
	disc.material_override = Clay.material(GROUND)
	# Un pelo arriba del piso del sandbox, para que no titile con él.
	disc.position.y = -0.48
	body.add_child(disc)
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = RADIUS
	cylinder.height = 1.0
	shape.shape = cylinder
	shape.position.y = -0.5
	body.add_child(shape)


static func _wall(body: StaticBody3D) -> void:
	var middle := RADIUS + WALL_THICK * 0.5
	var count := 72
	var length := TAU * middle / count * 1.04
	for i in count:
		var angle := TAU * (i + 0.5) / count
		var basis := Basis(Vector3.UP, -angle)
		var at := Vector3(cos(angle) * middle, 0.0, sin(angle) * middle)
		Clay.box(body, Vector3(WALL_THICK, WALL_SEEN, length), at + Vector3.UP * WALL_SEEN * 0.5, BOUND).basis = basis
		Clay.shape_box(body, Vector3(WALL_THICK, WALL_SOLID, length), at + Vector3.UP * WALL_SOLID * 0.5, basis)


# ------------------------------------------------------------------------------------------------ los barrios

static func on_ring(radius: float, degrees: float) -> Vector2:
	return Vector2(cos(deg_to_rad(degrees)), sin(deg_to_rad(degrees))) * radius


## UN BARRIO pegado al muro, centrado en `degrees`, de `span` grados: una fila de afuera contra el muro (con `talls` de
## 30 m y, si `landmark`, el hito), algunas casas más adentro, autos en la calle de adelante y un lugar de recursos en un
## la calle de adelante. Agrega a `supplies` dónde van los recursos (x, altura, z).
static func _barrio(body: StaticBody3D, rng: RandomNumberGenerator, degrees: float, span: float, talls: int,
		landmark: bool, supplies: Array[Vector3]) -> void:
	var count := maxi(2, int(span / 14.0))
	var tall_slots: Array[int] = []
	while tall_slots.size() < talls:
		var slot := rng.randi() % count
		if not slot in tall_slots:
			tall_slots.append(slot)
	for i in count:
		var a := degrees - span * 0.5 + span * (i + 0.5) / count + rng.randf_range(-2.5, 2.5)
		var height := TALL if i in tall_slots else LOW
		if landmark and i == tall_slots[0]:
			height = LANDMARK
		var outer := on_ring(RADIUS - 16.0 + rng.randf_range(-2.0, 2.0), a)
		var size := Vector2(rng.randf_range(20, 24), rng.randf_range(16, 20))
		building(body, outer, -outer.normalized(), size, height, TONES[rng.randi() % TONES.size()], true)
		if height >= TALL and supplies.size() < 2 * BARRIOS.size() and rng.randf() < 0.5:
			supplies.append(Vector3(outer.x, height, outer.y))
		if i % 2 == 1 and rng.randf() < 0.8:
			var inner := on_ring(RADIUS - 40.0 + rng.randf_range(-3.0, 3.0), a + rng.randf_range(-3.0, 3.0))
			building(body, inner, -inner.normalized(), Vector2(rng.randf_range(18, 22), rng.randf_range(12, 16)), LOW,
				TONES[rng.randi() % TONES.size()], true)
		if rng.randf() < 0.6:
			var spot := on_ring(RADIUS - 56.0 + rng.randf_range(-4.0, 4.0), a + rng.randf_range(-4.0, 4.0))
			car(body, spot, deg_to_rad(a) + rng.randf_range(-0.4, 0.4), CARS[rng.randi() % CARS.size()])
	var front := on_ring(RADIUS - 66.0, degrees)
	supplies.append(Vector3(front.x, 0.0, front.y))


## UN EDIFICIO, girado: su propio cuerpo estático, con la fachada +Z (donde va la escalera) mirando hacia `facing`. El
## techo es plano y se pisa a `height` (la escalera llega al ras).
static func building(body: StaticBody3D, at: Vector2, facing: Vector2, size: Vector2, height: float, tone: Color,
		with_stairs: bool) -> StaticBody3D:
	var piece := StaticBody3D.new()
	piece.position = Vector3(at.x, 0, at.y)
	piece.rotation.y = atan2(facing.x, facing.y)
	body.add_child(piece)
	Clay.solid(piece, Vector3(size.x, height, size.y), Vector3(0, height * 0.5, 0), tone)
	Clay.box(piece, Vector3(size.x - 0.2, 0.04, size.y - 0.2), Vector3(0, height + 0.02, 0), ROOF)
	if with_stairs:
		stairs(piece, size, height)
	return piece


## LA ESCALERA DE INCENDIO sobre la fachada +Z de un edificio de `size` centrado en el origen: un tramo por piso, en
## zigzag por dos carriles, con un descanso en cada vuelta; el último descanso da al techo (la tabla de la cápsula sube
## hasta él).
static func stairs(piece: StaticBody3D, size: Vector2, height: float) -> void:
	var flights := maxi(1, roundi(height / STORY))
	var rise := height / flights
	var run := Stairs.run_for(rise)
	var face := size.y * 0.5
	for i in flights:
		var lane := i % 2
		var direction := 1.0 if lane == 0 else -1.0
		var start := Vector3(-direction * run * 0.5, rise * i, face + LANE * (lane + 0.5))
		Stairs.flight(piece, start, Vector3(direction, 0, 0), rise, LANE - 0.1, STAIRS)
		var last := i == flights - 1
		Stairs.landing(piece, Vector3(direction * (run * 0.5 + LANDING * 0.5), rise * (i + 1), face + LANE),
			Vector2(LANDING, LANE * 2.0), 0.0, STAIRS, Vector3(0, 0, -1) if last else Vector3.ZERO)


## Un auto: la caja y la cabina, girado `yaw`.
static func car(body: StaticBody3D, at: Vector2, yaw: float, color: Color) -> void:
	var basis := Basis(Vector3.UP, yaw)
	Clay.solid(body, Vector3(1.9, 0.9, 4.4), Vector3(at.x, 0.65, at.y), color, basis)
	Clay.solid(body, Vector3(1.7, 0.7, 2.2), Vector3(at.x, 1.45, at.y) + basis * Vector3(0, 0, -0.3),
		color.darkened(0.2), basis)


# ------------------------------------------------------------------------------------------------ las ruinas del medio

## TRES COSAS PARA CUBRIRSE, lejos una de otra y de donde nace la meca: una pared rota en tres tramos que bajan (14, 10
## y 6 m: tapa a la meca de un lado y se salta del otro), la esquina de un edificio caído (16 m, en L) y una tapia baja
## (4 m: tapa a la gente; la meca la pasa por encima).
static func _ruins(body: StaticBody3D) -> void:
	var wall_basis := Basis(Vector3.UP, deg_to_rad(20.0))
	var heights: Array[float] = [14.0, 10.0, 6.0]
	for i in 3:
		var at := Vector3(-38, heights[i] * 0.5, -12) + wall_basis * Vector3((i - 1) * 9.6, 0, 0)
		Clay.solid(body, Vector3(9.0, heights[i], 2.5), at, RUIN, wall_basis)
	var corner := Vector3(42, 0, 8)
	var corner_basis := Basis(Vector3.UP, deg_to_rad(-35.0))
	Clay.solid(body, Vector3(16.0, 16.0, 2.5), corner + corner_basis * Vector3(0, 8, 0), RUIN.darkened(0.05),
		corner_basis)
	Clay.solid(body, Vector3(2.5, 11.0, 12.0), corner + corner_basis * Vector3(-6.75, 5.5, 7.25), RUIN.darkened(0.05),
		corner_basis)
	var low_basis := Basis(Vector3.UP, deg_to_rad(-8.0))
	Clay.solid(body, Vector3(18.0, 4.0, 1.5), Vector3(4, 2, -58), RUIN, low_basis)


# ------------------------------------------------------------------------------------------------ los recursos

## UN LUGAR DE RECURSOS: una baldosa ocre, un poste con bandera que se ve de lejos y tres cubos sueltos (los de verdad,
## que se agarran: `PackageArchetype.build_body`), del catálogo en ronda. Los cubos cuelgan de `parent`, no del mapa:
## son cuerpos que se mueven.
static func _supply(body: StaticBody3D, parent: Node3D, at: Vector3, kinds: Array[SeededArchetype], index: int) -> void:
	Clay.box(body, Vector3(5, 0.04, 5), at + Vector3.UP * 0.02, PAD)
	Clay.box(body, Vector3(0.3, 8.0, 0.3), at + Vector3(2.2, 4.0, 2.2), POLE)
	Clay.box(body, Vector3(2.2, 1.3, 0.15), at + Vector3(3.3, 7.3, 2.2), FLAG)
	for k in 3:
		var kind := kinds[(index * 3 + k) % kinds.size()] as PackageArchetype
		var cube := kind.build_body()
		cube.position = at + Vector3((k - 1) * 1.1, kind.rest_height() + 0.02, 0.0)
		parent.add_child(cube)
