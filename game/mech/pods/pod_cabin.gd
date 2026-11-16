class_name PodCabin
extends MechCabin

## LA MECA DE CÁPSULAS (15/11/2026, de la maqueta 37 de tests/sphere_pods_look; el usuario: «pasemos esta maqueta de
## forma paramétrica y ordenada al sistema de la nave»). Una cabina más de la meca (ver Mech.Cabin.PODS), SIN INTERIOR,
## SIN ASCENSOR: el torso es macizo y cada uno va en su CÁPSULA, una esfera empotrada en el cuerpo, todas iguales.
##   · EL TORSO: un domo de fondo chato (el borde de abajo, redondeado), una pared derecha en el medio y el domo arriba;
##     torneado en redondo, sin planos rectos más que el fondo.
##   · LAS CÁPSULAS: la del movimiento, arriba (asoma la mitad: ve todo alrededor); el artillero, al frente en la mitad
##     de la pared; los brazos izquierdo y derecho, a `POD_STEP` grados de él. Cada una es OPACA CON UNA VENTANA DE
##     VIDRIO hacia afuera (`WINDOW`): desde adentro se ve oscuro todo menos la ventana (el usuario: «la esfera empotrada
##     tiene una parte opaca y otra translúcida de cristal»). Cada una con su silla (en modo creativo se entra y E).
##   · UN SOLO RADIAL para todo lo que va pegado al cuerpo, en la mitad de la pared: las cápsulas, LOS HOMBROS (a
##     `SHOULDER_STEP` grados, aparte) y LOS RECURSOS (atrás; sólo se ven).
##   · LA GATLING abajo de la cápsula del medio (sólo se ve) y LA COLUMNA que baja del fondo a la pelvis.
## Cada uno la ve desde su lado: el del medio, centrado; los de los brazos, su lado; el de arriba, todo (el usuario: «cada
## uno tiene su campo de visión que le beneficia a su tarea»).

## LA FORMA SE CAMBIA JUGANDO (el F2 de su fila, PodShapePanel; se guarda en `SAVED`, ver PodShape).
const SAVED := "res://game/mech/pods/pod_shape.tres"
const BODY_FIELDS: Array[String] = ["arm_length", "leg_length", "thickness", "leg_stretch", "shoulder_out"]
static var RADIUS := 5.8
static var WALL_TALL := 3.0
static var DOME := 3.8
static var EDGE := 0.7
static var POD_STEP := 45.0
static var POD_OUT := 0.25
static var WINDOW := 55.0
static var SHOULDER_STEP := 90.0
static var BODY := PodShape.new()
## La cápsula de uno: su radio (m), y cuánto asoma la de arriba.
const POD := 0.9
const TOP_OUT := 0.5
## La ventana de la de arriba (grados desde su centro): un poco más que la mitad, para ver el horizonte.
const TOP_WINDOW := 95.0
## Los recursos de atrás (sólo se ven): desde qué rumbo, cada cuántos grados, y cuáles.
const SUPPLY_FROM := 130.0
const SUPPLY_STEP := 16.0
const SUPPLIES := ["kit", "kit", "ammo", "battery", "ammo", "kit", "kit"]
const SUPPLY := 0.63
## La columna de abajo, del fondo a la pelvis.
const COLUMN := 1.2
## Los puestos de las cápsulas, en el orden de las sillas (ver MechCabin.POSTS): izquierda, medio, derecha, arriba.
const POD_NAMES := ["brazo izquierdo", "artillero", "brazo derecho", "movimiento"]

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const RIM := Color(0.22, 0.23, 0.25)
const SUPPLY_COLORS := {"kit": Color(0.72, 0.42, 0.36), "ammo": Color(0.48, 0.5, 0.36),
	"battery": Color(0.36, 0.55, 0.38)}


static func _static_init() -> void:
	var saved := load(SAVED) as PodShape if ResourceLoader.exists(SAVED) else null
	apply(saved if saved != null else PodShape.new())


## TOMA LA FORMA. Las mecas que ya estaban no cambian: hay que rearmarlas (ver PodShapePanel).
static func apply(shape: PodShape) -> void:
	RADIUS = shape.radius
	WALL_TALL = shape.wall
	DOME = shape.dome
	EDGE = minf(shape.edge, shape.radius - 0.5)
	POD_STEP = shape.pod_step
	POD_OUT = shape.pod_out
	WINDOW = shape.window
	SHOULDER_STEP = shape.shoulder_step
	for field: String in BODY_FIELDS:
		BODY.set(field, shape.get(field))


## La forma de hoy, para guardarla.
static func current() -> PodShape:
	var now := PodShape.new()
	now.radius = RADIUS
	now.wall = WALL_TALL
	now.dome = DOME
	now.edge = EDGE
	now.pod_step = POD_STEP
	now.pod_out = POD_OUT
	now.window = WINDOW
	now.shoulder_step = SHOULDER_STEP
	for field: String in BODY_FIELDS:
		now.set(field, BODY.get(field))
	return now


## ── LAS MEDIDAS (en el espacio de la caja: el centro, en el medio) ──────────────────────────────────────────────

static func box() -> Vector3:
	return Vector3(RADIUS * 2.0, height(), RADIUS * 2.0)


static func height() -> float:
	return EDGE + WALL_TALL + DOME


static func bottom() -> float:
	return -height() * 0.5


## La mitad de la pared: el alto del radial (las cápsulas, los hombros, los recursos).
static func middle() -> float:
	return bottom() + EDGE + WALL_TALL * 0.5


## EL PERFIL DEL TORSO, de abajo arriba: (radio, alto desde el fondo). El fondo chato, el borde redondeado, la pared y
## el domo.
static func profile() -> Array[Vector2]:
	var steps := 24
	var points: Array[Vector2] = [Vector2(0.0, 0.0)]
	for i in range(0, steps + 1):
		var angle := -PI * 0.5 + PI * 0.5 * float(i) / steps
		points.append(Vector2(RADIUS - EDGE + EDGE * cos(angle), EDGE + EDGE * sin(angle)))
	for i in range(0, steps + 1):
		var angle := PI * 0.5 * float(i) / steps
		points.append(Vector2(RADIUS * cos(angle), EDGE + WALL_TALL + DOME * sin(angle)))
	return points


## EL RADIAL: el punto del cuerpo a `heading` grados del frente (hacia la derecha) y al alto `y` (de la caja), y hacia
## afuera ahí: [punto, normal].
static func surface(heading: float, y: float) -> Array:
	var points := profile()
	var from_floor := y - bottom()
	var r := 0.0
	var slope := Vector2(0.0, 1.0)
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		if from_floor >= a.y and from_floor <= b.y and b.y - a.y > 0.0001:
			r = lerpf(a.x, b.x, (from_floor - a.y) / (b.y - a.y))
			slope = (b - a).normalized()
			break
	var h := deg_to_rad(heading)
	var flat := Vector3(sin(h), 0.0, -cos(h))
	# La normal del perfil (hacia afuera), girada al rumbo.
	var normal := Vector2(slope.y, -slope.x)
	return [flat * r + Vector3(0.0, y, 0.0), (flat * normal.x + Vector3(0.0, normal.y, 0.0)).normalized()]


## EL HOMBRO (el derecho; el izquierdo, espejado): en el radial, a `SHOULDER_STEP` grados.
static func shoulder() -> Vector3:
	return surface(SHOULDER_STEP, middle())[0]


## LAS CÁPSULAS: [centro, hacia afuera], en el orden de las sillas (izquierda, medio, derecha, arriba).
static func pods() -> Array:
	var all: Array = []
	for heading: float in [-POD_STEP, 0.0, POD_STEP]:
		var spot := surface(heading, middle())
		all.append([(spot[0] as Vector3) - (spot[1] as Vector3) * POD * (1.0 - 2.0 * POD_OUT), spot[1]])
	var top := Vector3(0.0, -bottom(), 0.0)
	all.append([top - Vector3.UP * POD * (1.0 - 2.0 * TOP_OUT), Vector3.UP])
	return all


## El piso de una cápsula, debajo de su centro.
static func pod_floor(center: Vector3) -> Vector3:
	return center + Vector3(0.0, -POD * 0.8, 0.0)


## Donde se mira en primera persona al poseerla: la silla de arriba, la del movimiento.
func top_seat() -> Vector3:
	return pod_floor(pods()[3][0])


func _ready() -> void:
	name = "Cabina de cápsulas"
	interior = StaticBody3D.new()
	interior.name = "Interior"
	interior.collision_layer = 0
	interior.collision_mask = 0
	add_child(interior)
	_torso()
	var all := pods()
	for index in all.size():
		_pod(all[index][0], all[index][1], index)
	for index in SUPPLIES.size():
		var spot := surface(SUPPLY_FROM + index * SUPPLY_STEP, middle())
		_supply(spot[0], spot[1], SUPPLIES[index])
	_gatling(all[1][0], all[1][1])
	_column()


## ── LAS PIEZAS ─────────────────────────────────────────────────────────────────────────────────────────────────

## EL TORSO, torneado (por fuera; desde adentro de una cápsula no se ve: es como si tuviera su hueco).
func _torso() -> void:
	var part := MeshInstance3D.new()
	part.name = "Torso"
	part.mesh = PodCabin.lathe(profile(), 48)
	part.material_override = Clay.material(METAL)
	part.position = Vector3(0.0, bottom(), 0.0)
	add_child(part)


## UNA CÁPSULA: la esfera opaca (de dos caras: desde adentro se ve oscura) con la ventana de vidrio hacia afuera, el
## aro oscuro donde se mete en el cuerpo, el piso y la silla.
func _pod(center: Vector3, way: Vector3, index: int) -> void:
	var turn := _pointing(way)
	# La de arriba, del movimiento, ve todo alrededor: toda su mitad de afuera es ventana.
	var window := TOP_WINDOW if index == 3 else WINDOW
	var shell := MeshInstance3D.new()
	shell.name = "Cápsula %s" % POD_NAMES[index]
	shell.mesh = PodCabin.capsule(POD, window)
	shell.transform = Transform3D(turn, center)
	add_child(shell)
	# La ventana: el borde, un aro oscuro.
	var cap := deg_to_rad(window)
	_ring(center + way * POD * cos(cap), way, POD * sin(cap), 0.08, RIM)
	# Donde se mete en el cuerpo (el corte de la esfera con la piel).
	var out := POD * (2.0 * (TOP_OUT if index == 3 else POD_OUT) - 1.0)
	_ring(center - way * out, way, sqrt(maxf(POD * POD - out * out, 0.04)) + 0.03, 0.14, RIM)
	# El piso, para pararse, y la silla mirando al frente.
	var floor_at := pod_floor(center)
	Clay.cylinder(self, POD * 0.6, 0.06, floor_at, DARK_METAL)
	var slab := CollisionShape3D.new()
	var slab_shape := BoxShape3D.new()
	slab_shape.size = Vector3(POD * 1.1, 0.1, POD * 1.1)
	slab.shape = slab_shape
	slab.position = floor_at - Vector3(0.0, 0.05, 0.0)
	interior.add_child(slab)
	var chair := (load(SEAT_SCENE) as PackedScene).instantiate() as SeatInteractable
	chair.name = "Asiento %s" % POD_NAMES[index]
	chair.position = floor_at + Vector3(0.0, 0.03, 0.15)
	chair.eye_height = CabinGrid.EYE_HEIGHT
	add_child(chair)
	chairs.append(chair)


## UN RECURSO (kit, munición, batería): un cubo de 63 cm metido a medias en el cuerpo, con su aro (sólo se ve).
func _supply(at: Vector3, way: Vector3, kind: String) -> void:
	var cube := Clay.box(self, Vector3.ONE * SUPPLY, at + way * SUPPLY * 0.12, SUPPLY_COLORS[kind])
	cube.basis = _pointing(way)
	_ring(at, way, SUPPLY * 0.72, 0.14, RIM)


## LA GATLING, abajo de la cápsula del medio, mirando al frente (sólo se ve): la caja, seis caños en redondo y la tapa.
func _gatling(center: Vector3, way: Vector3) -> void:
	var gun := Node3D.new()
	gun.name = "Gatling"
	var flat := Vector3(way.x, 0.0, way.z).normalized()
	gun.position = center + flat * (POD * 0.4) + Vector3(0.0, -POD - 0.75, 0.0)
	gun.basis = Basis.looking_at(flat, Vector3.UP)
	add_child(gun)
	Clay.box(gun, Vector3(1.1, 0.9, 1.4), Vector3(0.0, 0.0, 0.2), DARK_METAL)
	Clay.cylinder(gun, 0.5, 0.25, Vector3(0.0, 0.0, -0.6), RIM, Vector3(90.0, 0.0, 0.0))
	for i in 6:
		var angle := TAU * i / 6.0
		Clay.cylinder(gun, 0.08, 1.9, Vector3(cos(angle) * 0.28, sin(angle) * 0.28, -1.6), DARK_METAL,
			Vector3(90.0, 0.0, 0.0))
	Clay.cylinder(gun, 0.42, 0.18, Vector3(0.0, 0.0, -2.3), RIM, Vector3(90.0, 0.0, 0.0))


## LA COLUMNA: del fondo del torso a la pelvis, oscura (une las piernas al cuerpo).
func _column() -> void:
	var drop := mech.measures.HIP_DROP + 0.4 if mech != null else 1.6
	Clay.cylinder(self, COLUMN, drop, Vector3(0.0, bottom() - drop * 0.5 + 0.1, 0.0), DARK_METAL)


## Un aro (un toro) centrado en `at`, de radio `radius`, con el eje hacia `way`.
func _ring(at: Vector3, way: Vector3, radius: float, thick: float, color: Color) -> void:
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = radius
	mesh.outer_radius = radius + thick
	ring.mesh = mesh
	ring.material_override = Clay.material(color)
	ring.transform = Transform3D(_pointing(way), at)
	add_child(ring)


## Una base que lleva +Y a `way`.
static func _pointing(way: Vector3) -> Basis:
	var dir := way.normalized()
	if dir.dot(Vector3.UP) > 0.999:
		return Basis()
	if dir.dot(Vector3.UP) < -0.999:
		return Basis(Vector3.RIGHT, PI)
	return Basis(Quaternion(Vector3.UP, dir))


## ── LAS MALLAS ─────────────────────────────────────────────────────────────────────────────────────────────────

## TORNEA `points` (de abajo arriba: (radio, alto)) en redondo, en `around` gajos, con sus normales.
static func lathe(points: Array[Vector2], around: int) -> ArrayMesh:
	var normals: Array[Vector2] = []
	for i in points.size():
		var before := points[maxi(i - 1, 0)]
		var after := points[mini(i + 1, points.size() - 1)]
		var along := (after - before).normalized()
		normals.append(Vector2(along.y, -along.x))
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in around:
		var a0 := TAU * j / around
		var a1 := TAU * (j + 1) / around
		for i in points.size() - 1:
			var quad: Array = [[i, a0], [i + 1, a0], [i + 1, a1], [i, a1]]
			for corner: int in [0, 2, 1, 0, 3, 2]:
				var index: int = quad[corner][0]
				var turn: float = quad[corner][1]
				var p := points[index]
				var n := normals[index]
				tool.set_normal(Vector3(n.x * cos(turn), n.y, n.x * sin(turn)))
				tool.add_vertex(Vector3(p.x * cos(turn), p.y, p.x * sin(turn)))
	return tool.commit()


## LA CÁPSULA: una esfera de `radius` con el eje en +Y, en dos superficies: la ventana (el casquete de `window` grados
## alrededor de +Y), de vidrio; el resto, opaco DE DOS CARAS (desde adentro también tapa).
static func capsule(radius: float, window: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var cap := deg_to_rad(window)
	var rings := 16
	var around := 32
	for part in 2:
		var from := 0.0 if part == 0 else cap
		var to := cap if part == 0 else PI
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		for i in rings:
			var t0 := lerpf(from, to, float(i) / rings)
			var t1 := lerpf(from, to, float(i + 1) / rings)
			for j in around:
				var p0 := TAU * j / around
				var p1 := TAU * (j + 1) / around
				var quad: Array = [[t0, p0], [t1, p0], [t1, p1], [t0, p1]]
				for corner: int in [0, 2, 1, 0, 3, 2]:
					var t: float = quad[corner][0]
					var p: float = quad[corner][1]
					var n := Vector3(sin(t) * cos(p), cos(t), sin(t) * sin(p))
					tool.set_normal(n)
					tool.add_vertex(n * radius)
		tool.commit(mesh)
		var paint := StandardMaterial3D.new()
		if part == 0:
			paint.albedo_color = Color(0.55, 0.75, 0.85, 0.22)
			paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			paint.roughness = 0.1
		else:
			paint.albedo_color = DARK_METAL
			paint.roughness = 0.85
		paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.surface_set_material(part, paint)
	return mesh


## ── EL MARCO Y LA U ────────────────────────────────────────────────────────────────────────────────────────────

## EL MARCO: una caja alrededor de cada cápsula (lo que se camina adentro son sus pisos).
func build_frame() -> void:
	frame = MotionFrame.new()
	mech.add_child(frame)
	var all := pods()
	frame.floor_height = pod_floor(all[1][0]).y
	for pod: Array in all:
		var center: Vector3 = pod[0]
		var reach := POD + 0.3
		frame.add_volume(AABB(center - Vector3.ONE * reach, Vector3.ONE * reach * 2.0))
	interior.collision_layer = 1
	frame.cast_shadow(self)
	interior.collision_layer = 0
	interior.collision_mask = 0
	for body in find_children("*", "RigidBody3D", true, false):
		mech.add_collision_exception_with(body as RigidBody3D)


## LA U: adentro de la cápsula de arriba, parado al lado de la silla.
func board() -> void:
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	if mech.keys.driving:
		SandboxPossession.of(get_tree()).release()
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	var spot := pod_floor(pods()[3][0]) + Vector3(0.0, 0.05, -0.3)
	player.place_at(mech.global_transform * spot, mech.yaw())
