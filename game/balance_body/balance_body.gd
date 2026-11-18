class_name BalanceBody
extends RigidBody3D

## EL CUERPO CON EQUILIBRIO: lo que comparten la meca propia (Mech) y las mecas enemigas, los jefes (13/11/2026; ver
## docs/technical/base-comun.md). El usuario: «los jefes van a heredar una clase abstracta que comparten con la meca propia, que es
## todo el sistema de equilibrio… un cuerpo físico que se inclina y pierde equilibrio»; y a la vez «no quiero correr el
## riesgo de limitarme por compartir demasiado».
##
## POR ESO ES CHICO: una caja de `size` que mueve su motor (KinematicMover: el controlador de personaje, con movimiento
## discreto), caerse y volver. Todo lo demás son PIEZAS que cada uno arma, o cambia, en `_build`:
##   · BodyLegs     las piernas de dibujo que siguen al apoyo (dos, desde una pelvis). Otro medio de moverse —cuatro
##                  patas, patas que salen de los costados, ruedas, volar— es otra pieza.
##   · su esqueleto (MechSkeleton) y sus pies con choque (StompFeet).
##   · y lo suyo: la meca propia arma su cabina, sus teclas y sus brazos (ver Mech); un jefe, su cerebro y sus armas.
##
## LO QUE SE LE PIDE (`move`, `sprint`, `crouch`, `jump`, `dash`, `aim_yaw`) son variables: las escribe quien la maneje
## (las teclas, las consolas, el cerebro de un jefe) en `_think`, al empezar cada paso.
##
## *Hasta el 18/11/2026 había también UN CUERPO FÍSICO CON PÉNDULO (12/11/2026): la caja la movía Jolt, sostenida por un
## palo hasta un punto de apoyo que la seguía, se caía pasado un ángulo y se levantaba con toberas (BodyNozzles), con
## sus movimientos (BodyMoves) y sus perillas (BodySettings). Lo usaba sólo la meca de práctica; el usuario lo borró
## («Borrarlo») en la limpieza del esqueleto. Está en el commit d09b964, con su nota (docs/technical/pendulo.md).*

enum State { STANDING, DOWN, LIFT, RIGHT }

## Con menos inclinación que esto ya es el final de enderezarse (`State.RIGHT`: las piernas se estiran).
const LAST_STRETCH := 45.0
## Lo más que el pedido de giro se adelanta a donde mira el torso: bastante menos que media vuelta.
const AIM_LEAD := deg_to_rad(110.0)

## UN GOLPE DE COSTADO ARRIBA (el F2 del sandbox, `knock`): suave o fuerte (m/s).
const KNOCK_SOFT := 5.0
const KNOCK_STRONG := 14.0

## LA CAJA: su tamaño (m). Se pone antes de agregarlo al árbol (la masa es la de RigidBody3D; congelada: la mueve su
## motor, ver KinematicMover).
var size := Vector3.ONE * 8.0
var mover: KinematicMover = null
## LAS PERILLAS DE MOVERSE DE ESTA (ver KinematicSettings): si es null, las de todas (`KinematicSettings.current`). La
## meca jaula lleva las suyas (el usuario, 16/11/2026: «si un panel lo quiero modificar para este mecha, me gustaría
## que sea solamente para esta»). Se pone antes de agregarla.
var kinematic_knobs: KinematicSettings = null
var stomp: StompFeet = null
## POR LA RED (ver BodyNet): quién la simula y lo que viaja.
var net: BodyNet = null
## Lo que sobresale de la caja hacia adelante (m; el vidrio de la meca): el cilindro de la cinemática lo envuelve.
var outline_extra := 0.0
## A QUÉ ALTURA DEL PISO VA LA CARA DE ABAJO DE LA CAJA, parada (m). NO ES UNA
## PERILLA: la da el cuerpo (la meca propia, el de sus piernas: MechBody.WAIST, del F2). Se pone antes de agregarla.
var hover := 7.4
## SUS MEDIDAS (ver MechBody): el ancho, las piernas, los pies, la pelvis y los brazos. Las da el cuerpo (la meca, según
## su cabina: Mech.cabin_kit), con `hover` que haga juego (su `WAIST`). Se ponen antes de agregarla; sin ponerlas, las
## de siempre (MechBody sin tocar).
var measures := MechBody.new()

## ── LO QUE SE LE PIDE ──
## Caminar (x a la derecha, y adelante, de −1 a 1), correr, agacharse, saltar (en el aire, volar), el dash y hacia
## dónde mirar (en el mundo). Lo que hace con cada uno, en KinematicMover.
var move := Vector2.ZERO
var sprint := false
var crouch := false
var jump := false
var dash := false
var aim_yaw := 0.0

## ── LO QUE MIDE, para mirar ──
## El estado, las caídas, la altura de la cara de abajo sobre el apoyo y la inclinación (grados). Los escribe el motor.
var state := State.STANDING
var falls := 0
var height := 0.0
var tilt := 0.0

## ── EL APOYO ── (lo escribe el motor; lo leen las piernas)
var support := Vector3.ZERO
var support_speed := Vector3.ZERO
var grounded := false
var airborne := false

## ── SUS PIEZAS ──
## `look`: el nodo del dibujo.
var look: Node3D = null
## SU ESQUELETO (MechSkeleton, 18/11/2026): los huesos de la pelvis, las piernas, el torso y los brazos; las piezas
## cuelgan de ellos. La caja va donde dice el torso (`_place_from_bones`).
var skeleton: MechSkeleton = null
var legs: BodyLegs = null
var label: Label3D = null


func _init() -> void:
	can_sleep = false
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	freeze = true
	# LA CAJA NO ROZA: lo que se apoya en ella (una caja, alguien) resbala.
	var slick := PhysicsMaterial.new()
	slick.friction = 0.0
	slick.bounce = 0.0
	physics_material_override = slick


func _ready() -> void:
	aim_yaw = global_rotation.y
	Clay.shape_box(self, size, Vector3.ZERO)
	look = Node3D.new()
	look.name = "Dibujo"
	add_child(look)
	skeleton = MechSkeleton.new()
	skeleton.build(measures, size, _shoulder())
	add_child(skeleton)
	# Nace donde está la caja (antes del primer paso del motor, los brazos ya se arman sobre sus huesos).
	skeleton.root.global_transform = global_transform * Transform3D(Basis(), Vector3(0.0, -size.y * 0.5, 0.0))
	legs = BodyLegs.new()
	legs.body = self
	add_child(legs)
	skeleton.setup_layers(self)
	mover = KinematicMover.new()
	mover.name = "Motor"
	mover.body = self
	net = BodyNet.new()
	net.name = "Red"
	net.body = self
	add_child(net)
	_build()
	add_child(mover)
	label = Label3D.new()
	label.top_level = true
	label.font_size = 64
	label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 14
	label.modulate = Color(1.0, 0.95, 0.6)
	add_child(label)


## ── LO DE CADA UNO (para redefinir) ─────────────────────────────────────────────────────────────────────────────

## Arma sus piezas propias, con el cuerpo, el dibujo, el esqueleto, las piernas y el motor ya armados.
func _build() -> void:
	pass


## EL HOMBRO DERECHO en el espacio de la caja (el izquierdo, espejado), para el esqueleto. Lo de todos: arriba, al
## costado de la caja; la meca dice el suyo (Mech.shoulder).
func _shoulder() -> Vector3:
	return Vector3(size.x * 0.5, size.y * 0.3, 0.0)


## LA CAJA VA DONDE DICE EL TORSO (paso 2b del esqueleto, 18/11/2026): el motor pone la raíz (lo de
## juego), el esqueleto pone encima sus capas (caminar, el resorte) y el cuerpo —la caja, y con ella la cabina, el
## marco y las sillas— va donde quedó el torso, con el centro de la caja en el medio del hueso.
func _place_from_bones() -> void:
	var motor := mover.body_place()
	skeleton.root.global_transform = motor * Transform3D(Basis(), Vector3(0.0, -size.y * 0.5, 0.0))
	skeleton.animate()
	global_transform = skeleton.torso.global_transform * Transform3D(Basis(), Vector3(0.0, size.y * 0.5, 0.0))


## Al empezar cada paso: escribe lo que se le pide (las teclas, un cerebro).
func _think() -> void:
	pass


## Al terminar cada paso, con todo lo del cuerpo ya hecho.
func _after_step(_delta: float) -> void:
	pass


## ── CADA PASO ────────────────────────────────────────────────────────────────────────────────────────────────────

## UN PASO: el motor la mueve, la caja va donde él dice, las piernas lo siguen y los pies con choque van donde pisan
## (los arma la primera vez, ya en su lugar: ver StompFeet.build).
func _physics_process(delta: float) -> void:
	_think()
	# Por la red, una sola máquina la simula (el dueño, que manda su estado); las demás la siguen (ver BodyNet).
	if net.remote():
		net.follow(delta)
	else:
		mover.step(delta)
		net.send(delta)
	_place_from_bones()
	legs.place(delta)
	var places := legs.foot_transforms()
	if stomp == null:
		stomp = StompFeet.new()
		stomp.name = "Pies con choque"
		add_child(stomp)
		stomp.build(measures.FOOT_SIZE, places)
	else:
		stomp.follow(places)
	_after_step(delta)
	_show_label()


## LA PONE en `where` (el punto del piso debajo de su centro), quieta, sin barrer el camino.
func put(where: Transform3D) -> void:
	mover.put(where)
	freeze = true
	_place_from_bones()
	if stomp != null:
		legs.replant()
		legs.place(0.0)
		stomp.place_now(legs.foot_transforms())


func _show_label() -> void:
	label.global_position = global_position + Vector3(0, size.y + 2.0, 0)
	label.text = "%s · altura %.1f m · inclinación %.0f°\ncaídas %d · pasos %d" % [
		["parada", "TIRADA", "sube", "se endereza"][state], height, tilt, falls, legs.steps_taken]


## UN GOLPE DE COSTADO, suave o fuerte (el F2 del sandbox): un empujón (`knock_back`). *Era un impulso arriba de la
## caja del péndulo físico, que la inclinaba; se cambió con él el 18/11/2026.*
func knock(strong: bool) -> void:
	if state != State.STANDING:
		return
	var side := global_basis.x
	side.y = 0.0
	knock_back(side.normalized() * (KNOCK_STRONG if strong else KNOCK_SOFT))


## ── EMPUJARLA Y LEER SU VELOCIDAD ───────────────────────────────────────────────────────────────────────────────
## La mueve su motor (KinematicMover): lo que la empuja pasa por `knock_back`, `shove` y `carry`.

## Su velocidad (m/s, mundo).
func velocity() -> Vector3:
	return mover.velocity


## SI AHORA NO SE LE PUEDE PEGAR: la cinemática, mientras no está parada (tirada o levantándose). Lo pregunta quien
## pega (los jefes: HitReaction.untouchable). *El dash la dejaba intocable un momento
## (15/11/2026); el usuario lo sacó el mismo día: «no se lee realista en la meca, se siente tonto».*
func untouchable() -> bool:
	return state != State.STANDING


## SI UN GOLPE LO FRENA ALGO SUYO (el escudo de la meca, ver ToolMech): quien pega lo llama UNA SOLA VEZ POR GOLPE, antes
## de pegar (`untouchable` se pregunta muchas veces y no cuenta nada), con dónde pega (`at`, en el mundo) si lo sabe.
## True: el golpe se frenó y se da por usado (no se reintenta). Lo de casi todos: nada lo frena.
func block_hit(_at := Vector3.INF) -> bool:
	return false


## UN EMPUJÓN: una velocidad que se frena sola, con la gravedad de siempre (`knock_back`; ver KinematicMover.knock);
## `shove`, el que recorre `offset` m en el piso, con un saltito de `hop` m.
func knock_back(push: Vector3) -> void:
	mover.knock(push)


func shove(offset: Vector3, time: float, hop := 0.0) -> void:
	mover.shove(offset, time, hop)


## EL REVOLEO: un camino guionado hasta `offset` m en `time` s, con un arco de `hop` m (lo que lleva
## quien la agarró y la tira; ver KinematicMover.carry).
func carry(offset: Vector3, time: float, hop := 0.0) -> void:
	mover.carry(offset, time, hop)


## LA DERRIBA: cae siempre de espaldas, queda tirada y se levanta, animado (ver KinematicMover.knock_down; `state` dice
## en qué va).
func knock_down() -> void:
	mover.knock_down()


## LE PEGA A CUALQUIER CUERPO: a lo suelto, un impulso. A uno con equilibrio, nada: lo mueve su motor, y quien quiera
## empujarlo usa `knock_back`, `shove` o `carry` (ver HitReaction).
static func hit(body: RigidBody3D, impulse: Vector3, at := Vector3.ZERO) -> void:
	if not body is BalanceBody:
		body.apply_impulse(impulse, at)


## Su velocidad, la tenga como la tenga (con equilibrio, por su puerta; lo demás, de Jolt).
static func speed_of(body: RigidBody3D) -> Vector3:
	return (body as BalanceBody).velocity() if body is BalanceBody else body.linear_velocity


## ── LO QUE MIDE ──────────────────────────────────────────────────────────────────────────────────────────────────

## Hacia dónde mira, en el piso.
func yaw() -> float:
	var forward := -global_basis.z
	forward.y = 0.0
	return atan2(-forward.x, -forward.z) if forward.length_squared() > 0.01 else aim_yaw


## Cuánto hay de `point` al piso, derecho hacia abajo (o mucho, si no hay piso).
func ground_distance(point: Vector3) -> float:
	var hit := ray(point, point + Vector3.DOWN * 200.0)
	return point.y - (hit["position"] as Vector3).y if not hit.is_empty() else 200.0


## UN RAYO AL PISO. EL PISO ES LO FIJO: lo que se mueve —una persona, una bola, un brazo, otro cuerpo suelto— no es piso,
## y el rayo lo saltea y sigue. *El 12/11/2026 el rayo de apoyo, que sale de su centro hacia abajo, le pegó al jugador
## parado en el ascensor, justo debajo: tomó su cabeza por piso, el apoyo saltó seis metros y la meca salió disparada.*
func ray(from: Vector3, to: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	var skip: Array[RID] = [get_rid()]
	query.collision_mask = 1
	for attempt in 12:
		query.exclude = skip
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		var other := hit.get("collider") as CollisionObject3D
		if other == null or other is StaticBody3D:
			return hit
		skip.append(other.get_rid())
	return {}


static func gravity() -> float:
	return float(ProjectSettings.get_setting("physics/3d/default_gravity"))


## Las perillas de moverse que usa (las suyas, o las de todas).
func kinematic_settings() -> KinematicSettings:
	return kinematic_knobs if kinematic_knobs != null else KinematicSettings.current
