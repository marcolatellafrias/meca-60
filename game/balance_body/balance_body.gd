class_name BalanceBody
extends RigidBody3D

## EL CUERPO CON EQUILIBRIO: lo que comparten la meca propia (Mech) y las mecas enemigas, los jefes (13/11/2026; ver
## docs/technical/base-comun.md). El usuario: «los jefes van a heredar una clase abstracta que comparten con la meca propia, que es
## todo el sistema de equilibrio… un cuerpo físico que se inclina y pierde equilibrio»; y a la vez «no quiero correr el
## riesgo de limitarme por compartir demasiado».
##
## POR ESO ES CHICO: UN SOLO CUERPO FÍSICO, una caja de `size`, con su equilibrio —el péndulo—, caerse y volver. Todo lo
## demás son PIEZAS que cada uno arma, o cambia, en `_build`:
##   · BodyLegs     las piernas de dibujo que siguen al apoyo (dos, desde una pelvis). Otro medio de moverse —cuatro
##                  patas, patas que salen de los costados, ruedas, volar— es otra pieza.
##   · BodyNozzles  las toberas: levantarse cuando se cae, y el propulsor.
##   · BodyMoves    lo que hace con lo que se le pide: caminar, correr, agacharse, saltar. (Los dashes van acá.)
##   · y lo suyo: la meca propia arma su cabina, sus teclas y sus brazos (ver Mech); un jefe, su cerebro y sus armas.
##
## LO QUE SE LE PIDE (`move`, `sprint`, `crouch`, `jump`, `aim_yaw`) son variables: las escribe quien la maneje (las
## teclas, las consolas, el cerebro de un jefe) en `_think`, al empezar cada paso.
## TODO SE MUEVE CON FUERZAS E IMPULSOS, nunca por código: por adentro y por afuera de la meca se camina.
##
## ── EL EQUILIBRIO: UN PÉNDULO (12/11/2026) ───────────────────────────────────────────────────────────────────────
## El usuario: «la meca sí quiero que tenga una colisión 1-1… el cubo se inclina como con un eje… desde el centro de ese
## cubo hasta el piso… las piernas van a seguir siendo IK»; y lo que separa una piña de una pared: «el torso sale
## despedido y los pies quedan atrás… / el torso se frena y los pies simplemente se plantan debajo».
## UN SOLO CUERPO FÍSICO, EL TORSO, QUE SIEMPRE VA ADELANTE; LOS PIES SIEMPRE LO SIGUEN.
##   · ES UN PÉNDULO INVERTIDO: un palo rígido va del centro de la caja al PUNTO DE APOYO, en el piso (`support`). La
##     punta del palo está agarrada a ese punto (`pivot_*`); la caja sólo puede girar alrededor de él.
##   · CAMINAR EMPUJA AL TORSO, en su centro, hacia la velocidad pedida, con inercia para arrancar y para frenar.
##   · EL PUNTO DE APOYO SIGUE AL TORSO (`feet_*`): quiere estar debajo de su centro e ir a su velocidad. FRENAR ES
##     INSTANTÁNEO (un pie se planta), pero para alcanzarlo acelera con tope. De ahí sale todo:
##       – una PIÑA le da velocidad al torso, la punta queda agarrada atrás y se inclina hacia donde va; los pies salen
##         a alcanzarlo y, si no llegan antes de `fall_tilt`, se cae. Arriba vuelca más que abajo.
##       – una PARED frena al torso y los pies se plantan debajo: no se cae, a ninguna velocidad.
##       – ARRANCAR la inclina un poco hacia adelante (los pies reaccionan con demora, `feet_react`) y se nivela al
##         llegar a velocidad (la opción «B» del usuario; ver docs/technical/pendulo.md para las otras).
##   · UN MÚSCULO la quiere derecha sobre su apoyo (`upright_*`), chico.
##   · EL GIRO EN Y es un motor con fuerza tope hacia `aim_yaw`: si algo la traba, no gira; un golpe la gira poco y
##     vuelve.
##   · LA CAJA NO ROZA (fricción 0, parada): lo que la frena son los pies, no las paredes.
##   · EN EL AIRE (un salto, un borde) va derecha y sin apoyo; cuando la punta del palo vuelve a tocar, aterriza.
## PASADO `fall_tilt` SE CAE: suelta del todo, un poco más pesada y con freno de giro. Apenas deja de caer y de rodar
## rápido, SE RECUPERA con sus toberas, subiendo y enderezándose a la vez (ver BodyNozzles), y vuelve a pararse.
##
## Las perillas, en `knobs` (un BodySettings; por defecto el de todas, `BodySettings.current`).

enum State { STANDING, DOWN, LIFT, RIGHT }

## Con menos inclinación que esto ya es el final de enderezarse (`State.RIGHT`: las piernas se estiran).
const LAST_STRETCH := 45.0
## Un cambio de velocidad de costado más chico que esto no es un golpe (m/s).
const HIT_NOISE := 0.3
## Lo más que el pedido de giro se adelanta a donde mira el torso: bastante menos que media vuelta.
const AIM_LEAD := deg_to_rad(110.0)

## LA CAJA: su tamaño (m) y sus perillas. Se ponen antes de agregarlo al árbol (la masa es la de RigidBody3D).
var size := Vector3.ONE * 8.0
var knobs: BodySettings = null
## CINEMÁTICA (13/11/2026, ver KinematicMover): el mismo cuerpo, con todo lo suyo, pero lo mueve el controlador de
## personaje del motor, con movimiento discreto, en vez de Jolt; y sus pies tienen choque (StompFeet). Se pone antes de
## agregarlo al árbol.
var kinematic := false
var mover: KinematicMover = null
## LAS PERILLAS DE MOVERSE DE ESTA (ver KinematicSettings): si es null, las de todas (`KinematicSettings.current`). La
## meca jaula lleva las suyas (el usuario, 16/11/2026: «si un panel lo quiero modificar para este mecha, me gustaría
## que sea solamente para esta»). Se pone antes de agregarla.
var kinematic_knobs: KinematicSettings = null
var stomp: StompFeet = null
## Lo que sobresale de la caja hacia adelante (m; el vidrio de la meca): el cilindro de la cinemática lo envuelve.
var outline_extra := 0.0
## A QUÉ ALTURA DEL PISO VA LA CARA DE ABAJO DE LA CAJA, parada (m): de ahí sale el largo del palo del péndulo. NO ES UNA
## PERILLA: la da el cuerpo (la meca propia, el de sus piernas: MechBody.WAIST, del F2). Se pone antes de agregarla.
var hover := 7.4
## SUS MEDIDAS (ver MechBody): el ancho, las piernas, los pies, la pelvis y los brazos. Las da el cuerpo (la meca, según
## su cabina: Mech.cabin_kit), con `hover` que haga juego (su `WAIST`). Se ponen antes de agregarla; sin ponerlas, las
## de siempre (MechBody sin tocar).
var measures := MechBody.new()

## ── LO QUE SE LE PIDE ──
## Caminar (x a la derecha, y adelante, de −1 a 1), correr, agacharse, el salto (mantenido carga, soltarlo salta; en el
## aire, el propulsor), el dash (en el aire) y hacia dónde mirar (en el mundo).
var move := Vector2.ZERO
var sprint := false
var crouch := false
var jump := false
## El dash (en el aire: ver BodyMoves).
var dash := false
var aim_yaw := 0.0

## ── LO QUE MIDE, para mirar ──
## El estado, las caídas, la altura de la cara de abajo sobre el apoyo (o del centro, recuperándose), la inclinación
## (grados) y el último golpe (m/s) y contra qué: "fijo", "golpe" o "empujón" (sin contacto).
var state := State.STANDING
var falls := 0
var height := 0.0
var tilt := 0.0
var last_hit := 0.0
var last_hit_kind := ""

## ── EL APOYO ── (lo leen las piernas y los movimientos)
var support := Vector3.ZERO
var support_speed := Vector3.ZERO
var grounded := false
var airborne := false

## ── SUS PIEZAS ──
## `look`: el nodo del dibujo.
var look: Node3D = null
## SU ESQUELETO (MechSkeleton, 18/11/2026): los huesos de la pelvis, las piernas, el torso y los brazos; las piezas
## cuelgan de ellos. El torso sigue a la caja (`_follow_bones`).
var skeleton: MechSkeleton = null
var legs: BodyLegs = null
## Las toberas, invisibles (ver BodyNozzles). *Hasta el 17/11/2026 se podían ver (`show_nozzles`), en la meca grande.*
var nozzles: BodyNozzles = null
var moves: BodyMoves = null
var label: Label3D = null

var _velocity_after := Vector3.ZERO
var _clock := 0.0
var _inertia := 1.0
var _slick := PhysicsMaterial.new()


func _init() -> void:
	can_sleep = false
	continuous_cd = true
	# Para saber contra qué choca (ver `_touch`).
	contact_monitor = true
	max_contacts_reported = 8


func _ready() -> void:
	if knobs == null:
		knobs = BodySettings.current
	# Una caja maciza: el promedio de sus tres ejes, m·(a² + b²)/12 cada uno.
	_inertia = mass * (size.x * size.x + size.y * size.y + size.z * size.z) / 18.0
	aim_yaw = global_rotation.y
	_slick.friction = 0.0
	_slick.bounce = 0.0
	physics_material_override = _slick
	Clay.shape_box(self, size, Vector3.ZERO)
	look = Node3D.new()
	look.name = "Dibujo"
	add_child(look)
	nozzles = BodyNozzles.new(self)
	skeleton = MechSkeleton.new()
	skeleton.build(measures, size, _shoulder())
	add_child(skeleton)
	_follow_bones()
	legs = BodyLegs.new()
	legs.body = self
	add_child(legs)
	moves = BodyMoves.new(self)
	if kinematic:
		freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		freeze = true
		mover = KinematicMover.new()
		mover.name = "Motor"
		mover.body = self
	_build()
	if mover != null:
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

## Arma sus piezas propias, con el cuerpo, el dibujo, las toberas, las piernas y los movimientos ya armados.
func _build() -> void:
	pass


## EL HOMBRO DERECHO en el espacio de la caja (el izquierdo, espejado), para el esqueleto. Lo de todos: arriba, al
## costado de la caja; la meca dice el suyo (Mech.shoulder).
func _shoulder() -> Vector3:
	return Vector3(size.x * 0.5, size.y * 0.3, 0.0)


## EL TORSO SIGUE A LA CAJA: el hueso del torso (y la cintura, su raíz) en el piso de la caja, con sus ejes.
func _follow_bones() -> void:
	if skeleton == null:
		return
	var floor_of_box := global_transform * Transform3D(Basis(), Vector3(0.0, -size.y * 0.5, 0.0))
	skeleton.waist.global_transform = floor_of_box
	skeleton.torso.global_transform = floor_of_box


## Al empezar cada paso: escribe lo que se le pide (las teclas, un cerebro).
func _think() -> void:
	pass


## Al terminar cada paso, con todo lo del cuerpo ya hecho.
func _after_step(_k: BodySettings, _delta: float) -> void:
	pass


## ── CADA PASO ────────────────────────────────────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	var k := knobs
	_think()
	nozzles.rest()
	if kinematic:
		_kinematic_step(k, delta)
		return
	gravity_scale = k.fall_gravity if state == State.DOWN else moves.gravity_share(k)
	angular_damp = k.ground_spin_damp if state == State.DOWN else 0.0
	if state != State.STANDING:
		tilt = rad_to_deg(global_basis.y.normalized().angle_to(Vector3.UP))
	match state:
		State.STANDING:
			moves.step(k, delta)
			_standing(k, delta)
		State.DOWN:
			var settled := linear_velocity.length() < k.settle_speed and angular_velocity.length() < k.settle_spin
			_clock = _clock + delta if settled else 0.0
			height = ground_distance(global_position)
			if _clock >= k.limp_time:
				state = State.LIFT
				_clock = 0.0
		State.LIFT:
			nozzles.get_up(k)
			if tilt <= LAST_STRETCH:
				state = State.RIGHT
		State.RIGHT:
			nozzles.get_up(k)
			if tilt <= k.upright_done and angular_velocity.length() < 0.4:
				_recovered()
	nozzles.fire(k)
	_follow_bones()
	legs.place(k, delta)
	_after_step(k, delta)
	_show_label()


## UN PASO CINEMÁTICO: el motor la mueve, la caja va donde él dice, las piernas lo siguen y los pies con choque van
## donde pisan (los arma la primera vez, ya en su lugar: ver StompFeet.build).
func _kinematic_step(k: BodySettings, delta: float) -> void:
	mover.step(delta)
	global_transform = mover.body_place()
	_follow_bones()
	legs.place(k, delta)
	var places := legs.foot_transforms()
	if stomp == null:
		stomp = StompFeet.new()
		stomp.name = "Pies con choque"
		add_child(stomp)
		stomp.build(measures.FOOT_SIZE, places)
	else:
		stomp.follow(places)
	_after_step(k, delta)
	_show_label()


## LA PONE en `where` (el punto del piso debajo de su centro), quieta, sin barrer el camino. Sólo la cinemática: la
## física se pone con su transformación.
func put(where: Transform3D) -> void:
	if mover == null:
		return
	mover.put(where)
	freeze = true
	global_transform = mover.body_place()
	_follow_bones()
	if stomp != null:
		legs.replant()
		legs.place(knobs, 0.0)
		stomp.place_now(legs.foot_transforms())


func _show_label() -> void:
	label.global_position = global_position + Vector3(0, size.y + 2.0, 0)
	label.text = "%s · altura %.1f m · inclinación %.0f°\núltimo golpe %.1f m/s %s · caídas %d · pasos %d" % [
		["parada", "TIRADA", "sube", "se endereza"][state], height, tilt, last_hit, last_hit_kind, falls, legs.steps_taken]


## ── PARADO ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _standing(k: BodySettings, delta: float) -> void:
	var length := rod(k)
	if not grounded and not airborne:
		var floor_point: Variant = _floor_below(global_position, length)
		if floor_point == null:
			take_off()
			return
		support = floor_point
		support_speed = Vector3.ZERO
		grounded = true
	tilt = rad_to_deg(global_basis.y.normalized().angle_to(Vector3.UP))
	height = global_position.y - support.y - size.y * 0.5
	if tilt > k.fall_tilt:
		_fall_down()
		return
	_note_hit()
	moves.drive(k, delta)
	if airborne:
		_in_air(length)
	else:
		# SIN PISO BAJO EL APOYO, NO HAY APOYO (un borde, un pozo): queda en el aire, cae derecho y aterriza donde haya.
		if not _follow(k, delta, length):
			take_off()
			return
		_hold(k, length)
	_upright(k, length)
	_turn(k)
	_velocity_after = linear_velocity


## EL LARGO DEL PALO, del centro de la caja al apoyo: de la altura a la que va, por lo agachado que esté.
func rod(k: BodySettings) -> float:
	return (size.y * 0.5 + hover) * moves.rod_scale


## QUEDA EN EL AIRE (un salto, un borde): sin apoyo hasta que la punta del palo vuelva a tocar.
func take_off() -> void:
	airborne = true
	grounded = false


## EN EL AIRE: sin apoyo; el punto va debajo, en el piso que haya, y cuando la punta del palo lo toca bajando, ATERRIZA:
## vuelve el apoyo, que arranca con la velocidad que trae (no hay nada que alcanzar).
func _in_air(length: float) -> void:
	var hit := ray(global_position, global_position + Vector3.DOWN * 400.0)
	if hit.is_empty():
		return
	support = hit["position"]
	if global_position.y - length <= support.y and linear_velocity.y <= 0.0:
		airborne = false
		grounded = true
		support_speed = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
		legs.replant()


## Para mirar: el último golpe (lo que cambió la velocidad de costado) y contra qué.
func _note_hit() -> void:
	var change := linear_velocity - _velocity_after
	var flat := Vector3(change.x, 0.0, change.z)
	if flat.length() <= HIT_NOISE:
		return
	last_hit = flat.length()
	var touch := _touch()
	last_hit_kind = "fijo" if bool(touch["fixed"]) else ("golpe" if touch["at"] != null else "empujón")


## CONTRA QUÉ CHOCÓ en el último paso de la física: `at`, el punto del contacto con algo que se mueve (o null), y
## `fixed`, si sólo tocó cosas fijas. Fijo es lo estático (una pared, un edificio, el piso) o un cuerpo congelado.
func _touch() -> Dictionary:
	var physics := PhysicsServer3D.body_get_direct_state(get_rid())
	var fixed := false
	if physics == null:
		return {"fixed": false, "at": null}
	for i in physics.get_contact_count():
		var other := physics.get_contact_collider_object(i)
		var still := (other is StaticBody3D and not other is AnimatableBody3D) \
			or (other is RigidBody3D and (other as RigidBody3D).freeze)
		if still:
			fixed = true
		else:
			return {"fixed": false, "at": physics.get_contact_local_position(i)}
	return {"fixed": fixed, "at": null}


## EL PUNTO DE APOYO SIGUE AL TORSO (ver arriba): quiere ir a su velocidad y ponerse debajo. Frenar es instantáneo;
## alcanzarlo, con tope.
func _follow(k: BodySettings, delta: float, length: float) -> bool:
	var off := Vector3(global_position.x - support.x, 0.0, global_position.z - support.z)
	var wanted := (Vector3(linear_velocity.x, 0.0, linear_velocity.z) + off * k.feet_catch).limit_length(k.feet_speed)
	# Se planta: nunca va más rápido, en su dirección, que lo que hace falta.
	if support_speed.length_squared() > 0.0001:
		var heading := support_speed.normalized()
		var needed := maxf(wanted.dot(heading), 0.0)
		if support_speed.length() > needed:
			support_speed = heading * needed
	# Salir a alcanzarlo: reaccionan según cuánto les falta (`feet_react`), con tope (`feet_accel`). Por esa demora,
	# mientras el torso acelera los pies van un poco atrás y se inclina hacia adelante; a velocidad, se nivela.
	var gap := (wanted - support_speed).length()
	support_speed = support_speed.move_toward(wanted, minf(k.feet_accel, gap * k.feet_react) * delta)
	support += support_speed * delta
	var floor_point: Variant = _floor_below(Vector3(support.x, global_position.y, support.z), length)
	if floor_point == null:
		return false
	support.y = (floor_point as Vector3).y
	return true


## LA PUNTA DEL PALO, AGARRADA AL APOYO: un resorte firme entre la punta (debajo de la caja, a `length` de su centro) y
## el punto, y el peso, que lo lleva el apoyo.
func _hold(k: BodySettings, length: float) -> void:
	var arm := global_basis * Vector3(0.0, -length, 0.0)
	var tip := global_position + arm
	var tip_speed := linear_velocity + angular_velocity.cross(arm)
	var accel := (support - tip) * k.pivot_kp - (tip_speed - support_speed) * k.pivot_kd + Vector3.UP * BalanceBody.gravity()
	apply_force(accel * mass, arm)


## EL MÚSCULO que lo quiere derecho sobre su apoyo (medido contra el giro alrededor del apoyo).
func _upright(k: BodySettings, length: float) -> void:
	var up := global_basis.y.normalized()
	var axis := up.cross(Vector3.UP)
	var angle := up.angle_to(Vector3.UP)
	var spin := Vector3(angular_velocity.x, 0.0, angular_velocity.z)
	var turn := (axis.normalized() * angle if axis.length() > 0.0001 else Vector3.ZERO) * k.upright_kp
	apply_torque((turn - spin * k.upright_kd) * (_inertia + mass * length * length))


## EL GIRO: hacia `aim_yaw` con velocidad tope, por un motor con fuerza tope. Dos topes, como los pies (plantarse es
## fuerte, salir es lento): GIRAR ÉL es débil (`yaw_force`, del orden de caminar) y FRENAR un giro que ya trae es
## fuerte (`yaw_hold`). *Con un solo tope fuerte, girar apoyado en una pared lo despedía: la pared devuelve el torque
## como un empujón (torque ÷ medio lado), varias veces más que lo que empuja caminar. Un freno sólo se opone a lo que se
## mueve: no puede despedirlo.*
##
## EL PEDIDO NO SE ACUMULA: nunca va más de `AIM_LEAD` por delante de donde mira. *Sin ese tope, un mouse más rápido que
## el torso se le adelantaba más de media vuelta y el torso giraba «por el camino corto», para el otro lado: según el
## ángulo, el mouse parecía invertido (lo vio el usuario: «en algunos ángulos está invertido y en otros no»).*
func _turn(k: BodySettings) -> void:
	var error := clampf(wrapf(aim_yaw - yaw(), -PI, PI), -AIM_LEAD, AIM_LEAD)
	aim_yaw = yaw() + error
	var wanted := clampf(error * k.yaw_grip, -deg_to_rad(k.turn_speed), deg_to_rad(k.turn_speed))
	var spin := angular_velocity.y
	var push := (wanted - spin) * k.yaw_grip
	# Lo que le saca giro (va contra `spin`) es freno; lo que le da, motor.
	var braking := spin * push < 0.0
	var most := k.yaw_hold if braking else k.yaw_force
	apply_torque(Vector3.UP * clampf(push, -most, most) * _inertia)


## ── CAERSE Y VOLVER ─────────────────────────────────────────────────────────────────────────────────────────────

func _fall_down() -> void:
	_slick.friction = 1.0
	state = State.DOWN
	_clock = 0.0
	grounded = false
	airborne = false
	falls += 1


## DERECHO OTRA VEZ: mirando hacia donde miraba, y a buscar su apoyo.
func _recovered() -> void:
	global_basis = Basis(Vector3.UP, yaw())
	angular_velocity = Vector3.ZERO
	_velocity_after = linear_velocity
	_slick.friction = 0.0
	aim_yaw = global_rotation.y
	grounded = false
	state = State.STANDING


## UN GOLPE DE COSTADO ARRIBA, suave o fuerte (el F2 del sandbox).
func knock(strong: bool) -> void:
	if state != State.STANDING:
		return
	var side := global_basis.x
	side.y = 0.0
	push_impulse(side.normalized() * mass * (knobs.knock_strong if strong else knobs.knock_soft),
		global_basis * Vector3(0.0, size.y * 0.5, 0.0))


## ── EMPUJARLA Y LEER SU VELOCIDAD: UNA SOLA PUERTA PARA LOS DOS MODOS ────────────────────────────────────────────
## Física, va a Jolt; cinemática, a la velocidad que mueve KinematicMover. Todo lo que la empuja (caminar, saltar, el
## dash, el propulsor, las piñas, los misiles, las zonas) pasa por acá.

## Su velocidad (m/s, mundo).
func velocity() -> Vector3:
	return mover.velocity if kinematic else linear_velocity


func set_velocity(value: Vector3) -> void:
	if kinematic:
		mover.velocity = value
	else:
		linear_velocity = value


## UNA FUERZA (N) en este paso, en el punto `at` (desde su centro, en el mundo). Cinemática, sólo cuenta lo que mueve el
## centro (el giro lo hace el péndulo).
func push_force(force: Vector3, at := Vector3.ZERO) -> void:
	# Cinemática, nada: la mueve su motor (las toberas sólo se ven).
	if not kinematic:
		apply_force(force, at)


## UN IMPULSO (N·s) en `at` (desde su centro, en el mundo). Cinemática: un cambio de velocidad del torso, sólo parada.
func push_impulse(impulse: Vector3, at := Vector3.ZERO) -> void:
	# Cinemática, todavía nada: con movimiento discreto, falta decidir qué le hace un golpe (ver KinematicMover).
	if not kinematic:
		apply_impulse(impulse, at)


## SI AHORA NO SE LE PUEDE PEGAR: la cinemática, mientras no está parada (tirada o levantándose). Lo pregunta quien
## pega (los jefes: HitReaction.untouchable); la física, siempre se le puede. *El dash la dejaba intocable un momento
## (15/11/2026); el usuario lo sacó el mismo día: «no se lee realista en la meca, se siente tonto».*
func untouchable() -> bool:
	return kinematic and state != State.STANDING


## SI UN GOLPE LO FRENA ALGO SUYO (el escudo de la meca, ver ToolMech): quien pega lo llama UNA SOLA VEZ POR GOLPE, antes
## de pegar (`untouchable` se pregunta muchas veces y no cuenta nada), con dónde pega (`at`, en el mundo) si lo sabe.
## True: el golpe se frenó y se da por usado (no se reintenta). Lo de casi todos: nada lo frena.
func block_hit(_at := Vector3.INF) -> bool:
	return false


## UN EMPUJÓN A LA CINEMÁTICA: una velocidad que se frena sola, con la gravedad de siempre (`knock_back`; ver
## KinematicMover.knock); `shove`, el que recorre `offset` m en el piso, con un saltito de `hop` m. A la física, nada: a
## ella se le pega con `push_impulse`.
func knock_back(push: Vector3) -> void:
	if kinematic and mover != null:
		mover.knock(push)


func shove(offset: Vector3, time: float, hop := 0.0) -> void:
	if kinematic and mover != null:
		mover.shove(offset, time, hop)


## EL REVOLEO DE LA CINEMÁTICA: un camino guionado hasta `offset` m en `time` s, con un arco de `hop` m (lo que lleva
## quien la agarró y la tira; ver KinematicMover.carry).
func carry(offset: Vector3, time: float, hop := 0.0) -> void:
	if kinematic and mover != null:
		mover.carry(offset, time, hop)


## DERRIBA A LA CINEMÁTICA: cae siempre de espaldas, queda tirada y se levanta, animado (ver
## KinematicMover.knock_down; `state` dice en qué va). A la física, nada: se cae sola con su física.
func knock_down() -> void:
	if kinematic and mover != null:
		mover.knock_down()


## LE PEGA A CUALQUIER CUERPO: a uno con equilibrio, por su puerta (física o cinemática); a lo demás, de siempre.
static func hit(body: RigidBody3D, impulse: Vector3, at := Vector3.ZERO) -> void:
	if body is BalanceBody:
		(body as BalanceBody).push_impulse(impulse, at)
	else:
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


## Su resistencia a girar (una caja maciza).
func inertia() -> float:
	return _inertia


## EL PISO DEBAJO DE `point`, hasta donde llegan las piernas (el palo y un poco más), o null si no hay. *«No hay piso»
## se leía como «el piso está 200 m abajo» (el valor que devuelve `ground_distance` cuando no encuentra): el apoyo se
## iba ahí y el resorte que agarra la caja la despedía hacia abajo.*
func _floor_below(point: Vector3, length: float) -> Variant:
	var hit := ray(point, point + Vector3.DOWN * (length + size.y * 0.5))
	if hit.is_empty():
		return null
	return hit["position"]


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
