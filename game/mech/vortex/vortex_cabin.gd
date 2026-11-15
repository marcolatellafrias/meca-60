class_name VortexCabin
extends MechCabin

## EL DISCO DE DOS PISOS CON VÓRTICE (15/11/2026, el usuario, de la maqueta tests/vortex_disc_look: «creo que hay
## potencial, ponémelo con brazos reales (con física), piernas reales, y torso con física en una parcela al principio
## del sandbox así lo pruebo y veo cómo se siente»). Una cabina más de la meca (ver Mech.Cabin.VORTEX), sin sillas ni
## ascensor:
##   · EL VÓRTICE: una columna opaca en el centro, con la boca abajo del disco. El que se para debajo sube chupado por
##     adentro del tubo y sale a la planta baja por su puerta; el que entra al tubo por la puerta baja despacio hasta el
##     suelo (ver `_physics_process`). Llega hasta el suelo con la meca parada: por ahora no hace falta agacharla.
##   · LA PLANTA BAJA, cerrada: la máquina, el banco de reparación, el tablero de la energía y las municiones (sólo se
##     ven). La ESCALERA CARACOL, pegada a la pared, sube al primer piso por un hueco del piso de arriba; se pisa una
##     rampa en hélice (los escalones se ven).
##   · EL PRIMER PISO, abierto: el anillo alrededor de un núcleo opaco que no se cruza; el borde con su bevel, el manejo
##     adelante, los mandos de los brazos a los costados y las ametralladoras en enchufes del borde (sólo se ven).
## Arriba se camina al aire libre: el marco (ver MechCabin) lleva a todos hasta 2,6 m sobre el primer piso.

## LA FORMA SE CAMBIA JUGANDO (el F2 de su fila, VortexShapePanel; se guarda en `SAVED`, ver VortexShape): el radio, el
## alto de la planta baja, el núcleo del medio, el ancho de la escalera y el largo de los brazos y las piernas de esta
## meca. Lo demás sale de acá. *El radio era 3,2 y la planta baja 2,3; el usuario los fue subiendo al probarla.*
const SAVED := "res://game/mech/vortex/vortex_shape.tres"
static var OUTER := 5.5
static var WALK := 5.05
static var CLEAR := 3.0
static var STAIR_OUT := 5.0
static var STAIR_IN := 3.2
static var CORE_ON := true
## El largo de las piernas y de los brazos de esta meca, en partes de los de las otras (los lee Mech.cabin_kit).
static var LEGS := 0.6
static var ARMS := 1.0
const RIM_OUT := 1.0
const RIM_IN := 0.8
const SHELL := 0.15
const CORE := 0.85
const TUBE := 0.7
const TUBE_WALL := 0.12
const DECK_SLAB := 0.25
const STAIR_FROM := PI / 3.0
const STAIR_TO := PI * 25.0 / 18.0
const STEPS := 14
## La puerta del tubo, en la planta baja (ángulo desde el frente, hacia la derecha) y su medio ancho.
const DOOR_AT := PI * 11.0 / 6.0
const DOOR_HALF := 0.5
## LO QUE HACE EL VÓRTICE: sube a esto (m/s) y baja a no más de esto.
const RISE := 6.0
const SINK := 4.0
## Arriba se camina hasta este alto sobre el primer piso (m): lo que lleva el marco.
const OPEN_ABOVE := 2.6

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const DECK := Color(0.72, 0.73, 0.75)
const LOW_FLOOR := Color(0.6, 0.58, 0.55)
const STAIR := Color(0.62, 0.55, 0.42)
const VORTEX := Color(0.36, 0.3, 0.5)
const RED := Color(0.8, 0.22, 0.18)
const YELLOW := Color(0.93, 0.75, 0.16)
const FACE := Color(0.92, 0.9, 0.84)

var _vortex: Area3D = null
## Los que están en el vórtice: cuerpo → true si sube, false si baja.
var _pulled := {}


static func _static_init() -> void:
	var saved := load(SAVED) as VortexShape if ResourceLoader.exists(SAVED) else null
	apply(saved if saved != null else VortexShape.new())


## TOMA LA FORMA. Las mecas que ya estaban no cambian: hay que rearmarlas (ver VortexShapePanel).
static func apply(shape: VortexShape) -> void:
	OUTER = shape.radius
	WALK = OUTER - 0.45
	CLEAR = shape.floor_height
	STAIR_OUT = WALK - 0.05
	# La escalera deja por lo menos un paso de 0,9 m entre ella y el tubo del vórtice.
	STAIR_IN = maxf(STAIR_OUT - shape.stair_width, TUBE + TUBE_WALL + 0.9)
	CORE_ON = shape.core
	LEGS = shape.legs
	ARMS = shape.arms


## La forma de hoy, para guardarla.
static func current() -> VortexShape:
	var now := VortexShape.new()
	now.radius = OUTER
	now.floor_height = CLEAR
	now.core = CORE_ON
	now.stair_width = STAIR_OUT - STAIR_IN
	now.legs = LEGS
	now.arms = ARMS
	return now


## LA CAJA, EL HOMBRO Y LOS PISOS (en el espacio de la caja: el centro, en el medio).
static func box() -> Vector3:
	return Vector3(OUTER * 2.0, height(), OUTER * 2.0)


static func height() -> float:
	return DECK_SLAB + CLEAR + DECK_SLAB + RIM_OUT


static func bottom() -> float:
	return -height() * 0.5


static func ground_floor() -> float:
	return bottom() + DECK_SLAB


static func upper_floor() -> float:
	return ground_floor() + CLEAR + DECK_SLAB


static func shoulder() -> Vector3:
	return Vector3(OUTER, ground_floor() + 1.25, 0.0)


static func out(angle: float) -> Vector3:
	return Vector3(sin(angle), 0.0, -cos(angle))


## Donde se mira en primera persona al poseerla: parado en el manejo, adelante (ver MechKeys.camera, que le suma el
## alto de los ojos sentado).
func top_seat() -> Vector3:
	return out(0.0) * (WALK - 0.6) + Vector3(0.0, upper_floor() + 1.65 - SeatInteractable.STATION_EYE_HEIGHT, 0.0)


func _ready() -> void:
	name = "Cabina del vórtice"
	interior = StaticBody3D.new()
	interior.name = "Interior"
	interior.collision_layer = 0
	interior.collision_mask = 0
	add_child(interior)
	_shell()
	_upstairs()
	_tube()
	_stairs()
	_rooms()
	for station: Array in [[0.0, "drive"], [deg_to_rad(70.0), "arm"], [deg_to_rad(290.0), "arm"],
			[deg_to_rad(40.0), "gun"], [deg_to_rad(320.0), "gun"], [deg_to_rad(100.0), "socket"],
			[deg_to_rad(180.0), "socket"], [deg_to_rad(255.0), "socket"]]:
		_station(station[0], station[1])
	_vortex = Area3D.new()
	_vortex.name = "Vórtice"
	_vortex.collision_layer = 0
	_vortex.collision_mask = 1 | MotionFrame.LAYER
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	# Hasta el suelo con la meca parada, y un poco más (la tiene agachada o en un pozo).
	var low := -Mech.standing_height(Mech.Cabin.VORTEX) - 1.0
	var high := ground_floor() + 1.4
	cylinder.radius = TUBE + 0.4
	cylinder.height = high - low
	shape.shape = cylinder
	shape.position.y = (low + high) * 0.5
	_vortex.add_child(shape)
	add_child(_vortex)


## ── LA CÁSCARA Y LOS PISOS ───────────────────────────────────────────────────────────────────────────────────────

func _shell() -> void:
	var low := bottom()
	var floor0 := ground_floor()
	var floor1 := upper_floor()
	var wall := OUTER - SHELL
	# Afuera: el fondo, la pared hasta el borde de arriba, el bevel y la cara de adentro del borde.
	_revolve(self, [Vector2(TUBE + TUBE_WALL, low), Vector2(OUTER - 0.15, low), Vector2(OUTER, low + 0.15),
		Vector2(OUTER, floor1 + RIM_OUT), Vector2(WALK, floor1 + RIM_IN), Vector2(WALK, floor1)], METAL)
	# Adentro de la planta baja: la pared y el piso.
	_revolve(self, [Vector2(wall, floor1 - DECK_SLAB), Vector2(wall, floor0)], METAL.lightened(0.08))
	_revolve(self, [Vector2(wall, floor0), Vector2(TUBE + TUBE_WALL, floor0)], LOW_FLOOR)
	_arc_shapes(TUBE + TUBE_WALL, wall, 0.0, TAU, low, floor0)
	# La pared choca gruesa hacia afuera (el que se resbala adentro cuando la meca arranca no la atraviesa); y el
	# borde de arriba, desde el piso hasta su alto.
	_arc_shapes(wall, OUTER + 0.5, 0.0, TAU, floor0, floor1)
	_arc_shapes(WALK, OUTER + 0.5, 0.0, TAU, floor1, floor1 + RIM_OUT)


## EL PRIMER PISO: la losa con el hueco de la escalera (ver `_hole_from`) y el núcleo opaco.
func _upstairs() -> void:
	var floor1 := upper_floor()
	var wall := OUTER - SHELL
	var hole_from := _hole_from()
	for part: Array in [[0.0, STAIR_IN, 0.0, TAU], [STAIR_IN, STAIR_OUT, STAIR_TO, hole_from + TAU],
			[STAIR_OUT, wall, 0.0, TAU]]:
		var r0: float = part[0]
		var r1: float = part[1]
		_revolve(self, [Vector2(r1, floor1 - DECK_SLAB), Vector2(r1, floor1), Vector2(r0, floor1), Vector2(r0, floor1 - DECK_SLAB),
			Vector2(r1, floor1 - DECK_SLAB)], DECK, part[2], part[3])
		_arc_shapes(r0, r1, part[2], part[3], floor1 - DECK_SLAB, floor1)
	# Los cantos del hueco.
	for r: float in [STAIR_IN, STAIR_OUT]:
		_revolve(self, [Vector2(r, floor1), Vector2(r, floor1 - DECK_SLAB)], METAL, hole_from, STAIR_TO)
	# La baranda del hueco, del lado de adentro (se ve; no choca: el que se cae, cae a la escalera).
	var posts := 8
	for i in posts + 1:
		var angle := lerpf(hole_from, STAIR_TO, float(i) / posts)
		Clay.cylinder(self, 0.03, 1.0, out(angle) * (STAIR_IN + 0.05) + Vector3(0, floor1 + 0.5, 0), DARK_METAL)
	_revolve(self, [Vector2(STAIR_IN + 0.08, floor1 + 1.0), Vector2(STAIR_IN + 0.08, floor1 + 0.94)], DARK_METAL,
		hole_from, STAIR_TO)
	# El núcleo: opaco, con una tapa; choca. Se puede sacar (ver VortexShape.core).
	if not CORE_ON:
		return
	_revolve(self, [Vector2(CORE, floor1), Vector2(CORE, floor1 + 1.9), Vector2(CORE - 0.15, floor1 + 2.05),
		Vector2(0.0, floor1 + 2.05)], DARK_METAL.lightened(0.15))
	_arc_shapes(0.0, CORE, 0.0, TAU, floor1, floor1 + 2.05)


## EL VÓRTICE: la boca acampanada debajo del disco y el tubo hasta el techo de la planta baja, con su puerta. Choca su
## pared (menos la puerta, en la planta baja); adentro no hay piso.
func _tube() -> void:
	var low := bottom()
	var floor0 := ground_floor()
	var top := upper_floor() - DECK_SLAB
	_revolve(self, [Vector2(1.3, low - 0.3), Vector2(TUBE + TUBE_WALL, low - 0.05), Vector2(TUBE + TUBE_WALL, top)],
		VORTEX)
	_revolve(self, [Vector2(TUBE, top), Vector2(TUBE, low - 0.05), Vector2(1.15, low - 0.3)], VORTEX.darkened(0.5))
	var door := Clay.box(self, Vector3(0.75, 1.9, 0.06), out(DOOR_AT) * (TUBE + TUBE_WALL + 0.02)
		+ Vector3(0, floor0 + 0.95, 0), Color(0.12, 0.1, 0.16))
	door.rotation.y = -DOOR_AT
	_arc_shapes(TUBE, TUBE + TUBE_WALL, 0.0, TAU, low - 0.3, floor0)
	_arc_shapes(TUBE, TUBE + TUBE_WALL, DOOR_AT + DOOR_HALF, DOOR_AT - DOOR_HALF + TAU, floor0, top)
	_arc_shapes(TUBE, TUBE + TUBE_WALL, DOOR_AT - DOOR_HALF, DOOR_AT + DOOR_HALF, floor0 + 2.0, top)
	# La corriente que chupa, del suelo a la boca: se ve a través (es aire).
	var pull := StandardMaterial3D.new()
	pull.albedo_color = Color(0.6, 0.5, 0.9, 0.16)
	pull.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pull.cull_mode = BaseMaterial3D.CULL_DISABLED
	pull.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var air := _revolve(self, [Vector2(1.0, low - Mech.standing_height(Mech.Cabin.VORTEX) + height() * 0.5 + 0.02),
		Vector2(1.1, low - 0.3)], Color.WHITE)
	air.material_override = pull
	air.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## LA ESCALERA CARACOL: cada escalón, un trozo de anillo macizo hasta el piso, entre dos líneas que salen del centro
## (el usuario: «que se atenga más al cilindro, salen solos los escalones de líneas del centro»); se pisa una rampa en
## hélice.
func _stairs() -> void:
	var floor0 := ground_floor()
	var rise := (upper_floor() - floor0) / STEPS
	var sweep := (STAIR_TO - STAIR_FROM) / STEPS
	for i in STEPS:
		add_child(_wedge(STAIR_IN, STAIR_OUT, STAIR_FROM + sweep * i, STAIR_FROM + sweep * (i + 1), floor0,
			floor0 + rise * (i + 1), STAIR.darkened(0.06 * (i % 2))))
	var pieces := STEPS * 2
	var span := (STAIR_TO - STAIR_FROM) / pieces
	var climb := (upper_floor() - floor0) / pieces
	for i in pieces:
		var a0 := STAIR_FROM + span * i
		var a1 := a0 + span
		var h0 := floor0 + climb * i
		var h1 := h0 + climb
		var points := PackedVector3Array()
		for r: float in [STAIR_IN, STAIR_OUT]:
			points.append_array([out(a0) * r + Vector3(0, floor0, 0), out(a1) * r + Vector3(0, floor0, 0),
				out(a0) * r + Vector3(0, h0, 0), out(a1) * r + Vector3(0, h1, 0)])
		_convex(points)


## LA PLANTA BAJA (sólo se ve): la máquina adelante, el banco de reparación, el tablero de la energía y las municiones.
func _rooms() -> void:
	var floor0 := ground_floor()
	var at := func(degrees: float, reach: float, y: float) -> Vector3:
		return out(deg_to_rad(degrees)) * reach + Vector3(0, floor0 + y, 0)
	Clay.box(self, Vector3(1.6, 1.5, 0.9), at.call(0.0, OUTER - 0.85, 0.75), DARK_METAL.lightened(0.1))
	Clay.shape_box(interior, Vector3(1.6, 1.5, 0.9), at.call(0.0, OUTER - 0.85, 0.75))
	for x: float in [-0.5, 0.0, 0.5]:
		Clay.cylinder(self, 0.08, 0.7, at.call(0.0, OUTER - 0.85, 1.85) + Vector3(x, 0, 0), METAL)
	Clay.cylinder(self, 0.25, 0.4, at.call(0.0, OUTER - 1.45, 0.9), RED, Vector3(90, 0, 0))
	var bench_angle := deg_to_rad(300.0)
	var bench := Clay.box(self, Vector3(1.4, 0.9, 0.6), at.call(300.0, OUTER - 0.6, 0.45), Color(0.5, 0.42, 0.32))
	bench.rotation.y = -bench_angle
	Clay.shape_box(interior, Vector3(1.4, 0.9, 0.6), bench.position, bench.basis)
	Clay.box(self, Vector3(0.3, 0.2, 0.3), bench.position + Vector3(0, 0.55, 0), METAL)
	var panel := Clay.box(self, Vector3(1.0, 0.9, 0.12), at.call(340.0, OUTER - SHELL - 0.08, 1.3), DARK_METAL)
	panel.rotation.y = -deg_to_rad(340.0)
	for i in 3:
		var lever := Clay.cylinder(panel, 0.03, 0.4, Vector3((i - 1) * 0.3, (i - 1) * 0.12, 0.22), YELLOW, Vector3(90, 0, 0))
		lever.name = "Palanca %d" % i
	for i in 4:
		# Fuera de la escalera (que termina a los 250°): la cuarta, encima de la segunda.
		var angle := 262.0 + (i if i < 3 else 1) * 8.0
		var crate := Clay.box(self, Vector3(0.6, 0.45, 0.45), at.call(angle, OUTER - 0.65, 0.225 + (0.45 if i == 3 else 0.0)), AMMO)
		crate.rotation.y = -deg_to_rad(angle)


## UN PUESTO del primer piso, en el borde (sólo se ve): el manejo, los mandos de un brazo, una ametralladora en su
## enchufe, o un enchufe vacío.
func _station(angle: float, kind: String) -> void:
	var floor1 := upper_floor()
	var outward := out(angle)
	if kind == "gun" or kind == "socket":
		Clay.box(self, Vector3(0.45, 0.06, 0.45), outward * (WALK + 0.32) + Vector3(0, floor1 + RIM_OUT - 0.03, 0),
			YELLOW.darkened(0.3)).rotation.y = -angle
		if kind == "socket":
			return
		var gun := Node3D.new()
		gun.position = outward * (WALK + 0.32) + Vector3(0.0, floor1 + RIM_OUT, 0.0)
		gun.rotation.y = -angle
		add_child(gun)
		Clay.cylinder(gun, 0.07, 0.3, Vector3(0.0, 0.15, 0.0), DARK_METAL)
		Clay.box(gun, Vector3(0.24, 0.24, 0.6), Vector3(0.0, 0.4, -0.05), DARK_METAL)
		Clay.cylinder(gun, 0.05, 0.85, Vector3(0.0, 0.42, -0.75), DARK_METAL, Vector3(90.0, 0.0, 0.0))
		Clay.box(gun, Vector3(0.5, 0.3, 0.04), Vector3(0.0, 0.5, -0.38), METAL)
		for side: float in [-1.0, 1.0]:
			Clay.cylinder(gun, 0.03, 0.2, Vector3(side * 0.13, 0.38, 0.3), YELLOW, Vector3(90.0, 0.0, 0.0))
		return
	var bevel := Vector2(OUTER - WALK, RIM_OUT - RIM_IN)
	var up := (Vector3.UP * bevel.x - outward * bevel.y).normalized()
	var along := Vector3(cos(angle), 0.0, sin(angle))
	var plate := Node3D.new()
	plate.basis = Basis(along, up, along.cross(up))
	plate.position = outward * (WALK + bevel.x * 0.5) + Vector3(0.0, floor1 + (RIM_IN + RIM_OUT) * 0.5, 0.0)
	add_child(plate)
	if kind == "drive":
		for side: float in [-1.0, 1.0]:
			Clay.box(plate, Vector3(0.16, 0.06, 0.24), Vector3(side * 0.2, 0.03, 0.0), DARK_METAL)
			Clay.cylinder(plate, 0.025, 0.42, Vector3(side * 0.2, 0.24, 0.0), DARK_METAL)
			Clay.sphere(plate, 0.06, Vector3(side * 0.2, 0.46, 0.0), RED)
		return
	Clay.box(plate, Vector3(0.7, 0.05, 0.3), Vector3(0.0, 0.025, 0.0), DARK_METAL)
	for side: float in [-1.0, 1.0]:
		Clay.cylinder(plate, 0.04, 0.3, Vector3(side * 0.22, 0.17, 0.0), DARK_METAL)
		Clay.box(plate, Vector3(0.1, 0.1, 0.18), Vector3(side * 0.22, 0.34, 0.0), RED)
	Clay.cylinder(plate, 0.13, 0.04, Vector3(0.0, 0.04, 0.0), FACE)


## ── EL MARCO Y EL VÓRTICE ────────────────────────────────────────────────────────────────────────────────────────

## EL MARCO: la cabina entera (de la losa de abajo hasta `OPEN_ABOVE` sobre el primer piso, que está al aire libre) y
## la boca del vórtice, un poco debajo del disco.
func build_frame() -> void:
	frame = MotionFrame.new()
	mech.add_child(frame)
	frame.floor_height = ground_floor()
	var low := bottom()
	frame.add_volume(AABB(Vector3(-OUTER, low, -OUTER), Vector3(OUTER * 2.0, upper_floor() + OPEN_ABOVE - low, OUTER * 2.0)))
	frame.add_volume(AABB(Vector3(-TUBE, low - 1.2, -TUBE), Vector3(TUBE * 2.0, 1.2, TUBE * 2.0)))
	interior.collision_layer = 1
	frame.cast_shadow(self)
	interior.collision_layer = 0
	interior.collision_mask = 0
	for body in find_children("*", "RigidBody3D", true, false):
		mech.add_collision_exception_with(body as RigidBody3D)


## GENTE PARADA ADENTRO, PARA VER LA ESCALA (el usuario: «ponele personajes adentro así veo escala»): tres arriba,
## cada uno frente a un puesto (el manejo, el brazo izquierdo y la ametralladora de la izquierda), y uno en la planta
## baja, en el banco. Van al lado de la meca en el árbol (como los maniquíes de las sillas) y los lleva el marco.
func seat_dummies() -> void:
	var holder := mech.get_parent() as Node3D
	if holder == null:
		return
	var places := [[0.0, upper_floor(), WALK - 0.45], [deg_to_rad(290.0), upper_floor(), WALK - 0.45],
		[deg_to_rad(320.0), upper_floor(), WALK - 0.45], [deg_to_rad(300.0), ground_floor(), OUTER - 1.3]]
	for i in places.size():
		var angle: float = places[i][0]
		var spot: Vector3 = out(angle) * float(places[i][2]) + Vector3(0.0, places[i][1], 0.0)
		var person := PeopleArchetype.spawn(holder, DUMMY_BODIES[i % DUMMY_BODIES.size()], mech.global_transform * spot,
			mech.yaw() - angle)
		# Aparece adentro de la caja maciza: que no la empuje antes de que el marco lo lleve (ver `ride`).
		mech.add_collision_exception_with(person.char_rigidbody)
		dummies.append(person)


## LA U: a la planta baja, al lado de la puerta del vórtice, mirándola.
func board() -> void:
	var player := DesignSandbox.player_of(get_tree())
	if player == null:
		return
	if mech.keys.driving:
		SandboxPossession.of(get_tree()).release()
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	var spot := out(DOOR_AT) * 1.7 + Vector3(0.0, ground_floor() + 0.05, 0.0)
	player.place_at(mech.global_transform * spot, mech.yaw() - DOOR_AT + PI)


## LA CAJA NO CHOCA CON LOS QUE VAN ADENTRO (ver MechCabin.ride) NI CON LOS QUE ESTÁ LLEVANDO EL VÓRTICE: suben por
## debajo de la caja antes de entrar al marco, y bajan por debajo después de salir.
func ride() -> void:
	super()
	for body: Variant in _pulled.keys():
		if is_instance_valid(body):
			mech.add_collision_exception_with(body as PhysicsBody3D)


## EL VÓRTICE, en cada paso: a quien entra desde abajo lo sube por el tubo, hacia el medio, y arriba lo deja en la planta
## baja, al lado de la puerta; a quien entra desde la planta baja (por la puerta) lo deja caer despacio hasta el suelo.
func _physics_process(_delta: float) -> void:
	if mech == null or _vortex == null:
		return
	var inside := {}
	for found in _vortex.get_overlapping_bodies():
		var body := found as CharacterRigidBody3D
		if body == null or not body.kind.simulates():
			continue
		inside[body] = true
		var local := mech.to_local(body.global_position)
		if not _pulled.has(body):
			_pulled[body] = local.y < ground_floor() - 0.6
			mech.add_collision_exception_with(body)
		var carried := mech.linear_velocity + mech.angular_velocity.cross(body.global_position - mech.global_position)
		var up := mech.global_basis.y
		var relative := body.linear_velocity - carried
		var toward := mech.global_basis * Vector3(-local.x, 0.0, -local.z)
		if _pulled[body]:
			if local.y >= ground_floor() + 0.95:
				_pop(body)
				continue
			body.linear_velocity = carried + toward * 4.0 + up * RISE
		else:
			var along := relative.dot(up)
			body.linear_velocity = carried + toward * 1.5 + (relative - up * along) * 0.5 + up * maxf(along, -SINK)
	for body: Variant in _pulled.keys():
		if inside.has(body):
			continue
		_pulled.erase(body)
		if is_instance_valid(body) and not frame._members.has(body):
			mech.remove_collision_exception_with(body as PhysicsBody3D)


## Arriba del tubo: lo para en la planta baja, al lado de la puerta, mirando hacia afuera de ella.
func _pop(body: CharacterRigidBody3D) -> void:
	_pulled.erase(body)
	for found in get_tree().root.find_children("*", "BoneInstantiator", true, false):
		var person := found as BoneInstantiator
		if person.char_rigidbody == body:
			var spot := out(DOOR_AT) * 1.7 + Vector3(0.0, ground_floor() + 0.05, 0.0)
			person.place_at(mech.global_transform * spot, mech.yaw() - DOOR_AT)
			return


## DESDE DÓNDE VA EL HUECO DE ARRIBA: desde el escalón en que, bajando, la cabeza ya no pasa debajo del piso de arriba.
func _hole_from() -> float:
	var rise := (upper_floor() - ground_floor()) / STEPS
	var step := clampi(floori((CLEAR - 2.0) / rise), 1, STEPS - 2)
	return STAIR_FROM + (STAIR_TO - STAIR_FROM) * step / STEPS


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## UNA VUELTA (o un tramo, de `from` a `to`) de un perfil (`r`, `y`): suave alrededor, con aristas en el perfil.
func _revolve(parent: Node3D, profile: Array, color: Color, from := 0.0, to := TAU) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := maxi(4, ceili(64.0 * (to - from) / TAU))
	for s in sides:
		var a0 := lerpf(from, to, float(s) / sides)
		var a1 := lerpf(from, to, float(s + 1) / sides)
		for p in profile.size() - 1:
			var p0: Vector2 = profile[p]
			var p1: Vector2 = profile[p + 1]
			var edge := p1 - p0
			var normal := Vector2(edge.y, -edge.x).normalized()
			var quad := [[p0, a0], [p1, a0], [p1, a1], [p0, a1]]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				var point: Vector2 = quad[corner][0]
				var away := out(quad[corner][1])
				tool.set_normal(away * normal.x + Vector3.UP * normal.y)
				tool.add_vertex(away * point.x + Vector3.UP * point.y)
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	parent.add_child(mesh)
	return mesh


## UN TROZO DE ANILLO MACIZO, de `r0` a `r1`, entre los ángulos `a0` y `a1`, de `y0` a `y1`: las caras de adentro y de
## afuera, suaves; arriba y las dos puntas, planas.
func _wedge(r0: float, r1: float, a0: float, a1: float, y0: float, y1: float, color: Color) -> MeshInstance3D:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var at := func(r: float, a: float, y: float) -> Vector3:
		return out(a) * r + Vector3(0.0, y, 0.0)
	var pieces := maxi(2, ceili(48.0 * (a1 - a0) / TAU))
	for k in pieces:
		var b0 := lerpf(a0, a1, float(k) / pieces)
		var b1 := lerpf(a0, a1, float(k + 1) / pieces)
		_quad(tool, at.call(r1, b0, y0), at.call(r1, b1, y0), at.call(r1, b1, y1), at.call(r1, b0, y1), SMOOTH_OUT)
		_quad(tool, at.call(r0, b1, y0), at.call(r0, b0, y0), at.call(r0, b0, y1), at.call(r0, b1, y1), SMOOTH_IN)
		_quad(tool, at.call(r0, b0, y1), at.call(r1, b0, y1), at.call(r1, b1, y1), at.call(r0, b1, y1), FLAT)
	for b: float in [a0, a1]:
		_quad(tool, at.call(r0, b, y0), at.call(r1, b, y0), at.call(r1, b, y1), at.call(r0, b, y1), FLAT)
	return _mesh(tool, color)


## Formas de choque de un anillo (o un tramo) entre `r0` y `r1`, de `y0` a `y1`: un trozo convexo cada tanto.
func _arc_shapes(r0: float, r1: float, from: float, to: float, y0: float, y1: float) -> void:
	var pieces := maxi(2, ceili(32.0 * (to - from) / TAU))
	for i in pieces:
		var a0 := lerpf(from, to, float(i) / pieces)
		var a1 := lerpf(from, to, float(i + 1) / pieces)
		var points := PackedVector3Array()
		for y: float in [y0, y1]:
			for a: float in [a0, a1]:
				points.append(out(a) * r1 + Vector3(0, y, 0))
				if r0 > 0.001:
					points.append(out(a) * r0 + Vector3(0, y, 0))
				else:
					points.append(Vector3(0, y, 0))
		_convex(points)
