class_name Mech
extends RigidBody3D

## LA MECA: una caja física 1:1 que es un PÉNDULO sobre su apoyo, con piernas que la siguen. Es UNA clase con sus piezas
## aparte, cada una en su archivo; acá queda el cuerpo y su equilibrio, que es lo que todo lo demás empuja:
##   · MechCabin    los tres pisos por dentro, el afuera (MechExterior), el ascensor (PelvisLift) y el marco que lleva a
##                  los que van adentro.
##   · MechLegs     la pelvis y las piernas: dibujo que pisa por radio alrededor del apoyo.
##   · MechNozzles  las toberas: levantarla y enderezarla cuando se cae, y el propulsor.
##   · MechMoves    correr, agacharse, el salto cargado y el propulsor.
##   · MechKeys     el teclado y el mouse de quien la posee: escribe LO QUE SE LE PIDE.
##   · los brazos   MechArm: PoseArm (discretos) o MuscleArm (físicos), según `arms_kind`: los dos caminos.
## *Hasta el 13/11/2026 eran tres clases una arriba de la otra (el cubo, el cubo péndulo, la meca péndulo), y la de
## abajo cargaba otro modelo de equilibrio —la línea— que la meca no usaba; el usuario pidió aplanarlo. Ese otro modelo
## quedó aparte, entero, en game/line_cube/.*
##
## LO QUE SE LE PIDE (`move`, `sprint`, `crouch`, `jump`, `aim_yaw`, `covering`, las piñas de sus brazos) son variables:
## hoy las escribe el teclado de quien la posee; mañana, las consolas de adentro o un jefe.
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
##         llegar a velocidad (la opción «B» del usuario; ver docs/meca.md para las otras).
##   · UN MÚSCULO la quiere derecha sobre su apoyo (`upright_*`), chico.
##   · EL GIRO EN Y es un motor con fuerza tope hacia `aim_yaw`: si algo la traba, no gira; un golpe la gira poco y
##     vuelve.
##   · LA CAJA NO ROZA (fricción 0, parada): lo que la frena son los pies, no las paredes.
##   · EN EL AIRE (un salto, un borde) va derecha y sin apoyo; cuando la punta del palo vuelve a tocar, aterriza.
## PASADO `fall_tilt` SE CAE: suelta del todo, un poco más pesada y con freno de giro. Apenas deja de caer y de rodar
## rápido, SE RECUPERA con sus toberas, subiendo y enderezándose a la vez (ver MechNozzles), y vuelve a pararse.
## TODO SE MUEVE CON FUERZAS E IMPULSOS, nunca por código: adentro y por afuera se camina.
##
## Las perillas, en MechSettings (el panel F1 de su fila); el F2 le pega arriba (`knock`).

enum State { STANDING, DOWN, LIFT, RIGHT }
## Los brazos que lleva: ninguno (la de práctica, para pegarle), discretos o físicos.
enum Arms { NONE, POSE, MUSCLE }

const SIZE := 8.0
const MASS := 50000.0
const NAMES := ["Meca de práctica", "Meca discreta", "Meca física"]
## Con menos inclinación que esto ya es el final de enderezarse (`State.RIGHT`: las piernas se estiran).
const LAST_STRETCH := 45.0
## Un cambio de velocidad de costado más chico que esto no es un golpe (m/s).
const HIT_NOISE := 0.3
## Lo más que el pedido de giro se adelanta a donde mira el torso: bastante menos que media vuelta.
const AIM_LEAD := deg_to_rad(110.0)
## LOS BRAZOS: el hombro, en el espacio de la caja (`x` del lado derecho), casi en el medio del costado. *El 12/11/2026
## se probó en el último tercio, hacia atrás: la postura era más natural, pero el brazo alcanzaba 2,6 m menos hacia
## adelante, y el usuario lo volvió («estaban bien los brazos a la mitad, no me gusta el sacrificio en rango»).* Y cuánto
## pesan los físicos, en partes de lo que pesa el brazo solo (ver MuscleArm.weight).
const SHOULDER := Vector3(SIZE * 0.5 + 1.0, 1.9, -0.4)
const ARM_WEIGHT := 0.4

## Qué brazos lleva. Se pone antes de agregarla al árbol.
var arms_kind := Arms.POSE

## ── LO QUE SE LE PIDE ──
## Caminar (x a la derecha, y adelante, de −1 a 1), correr, agacharse, el salto (mantenido carga, soltarlo salta; en el
## aire, el propulsor), hacia dónde mirar (en el mundo) y la postura de los brazos (cubriéndose, o normal).
var move := Vector2.ZERO
var sprint := false
var crouch := false
var jump := false
var aim_yaw := 0.0
var covering := false

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
var cabin: MechCabin = null
var legs: MechLegs = null
var nozzles: MechNozzles = null
var moves: MechMoves = null
var keys: MechKeys = null
var arms: Array[MechArm] = []
var label: Label3D = null

var _velocity_after := Vector3.ZERO
var _clock := 0.0
var _inertia := 1.0
var _slick := PhysicsMaterial.new()


func _init() -> void:
	mass = MASS
	can_sleep = false
	continuous_cd = true
	# Para saber contra qué choca (ver `_touch`).
	contact_monitor = true
	max_contacts_reported = 8
	# Un cubo macizo: I = m·L²/6.
	_inertia = MASS * SIZE * SIZE / 6.0


func _ready() -> void:
	name = NAMES[arms_kind]
	aim_yaw = global_rotation.y
	_slick.friction = 0.0
	_slick.bounce = 0.0
	physics_material_override = _slick
	Clay.shape_box(self, Vector3.ONE * SIZE, Vector3.ZERO)
	cabin = MechCabin.new()
	cabin.mech = self
	add_child(cabin)
	nozzles = MechNozzles.new(self, cabin)
	legs = MechLegs.new()
	legs.mech = self
	add_child(legs)
	moves = MechMoves.new(self)
	keys = MechKeys.new()
	keys.mech = self
	add_child(keys)
	_build_arms()
	cabin.build_frame()
	label = Label3D.new()
	label.top_level = true
	label.font_size = 64
	label.pixel_size = 0.02
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 14
	label.modulate = Color(1.0, 0.95, 0.6)
	add_child(label)
	add_to_group(SandboxPossession.GROUP)


func _build_arms() -> void:
	if arms_kind == Arms.NONE:
		return
	for side: float in [-1.0, 1.0]:
		var arm: MechArm = null
		if arms_kind == Arms.MUSCLE:
			var muscle := MuscleArm.new()
			muscle.weight = ARM_WEIGHT
			arm = muscle
		else:
			arm = PoseArm.new()
		arm.side = side
		arm.anchor = self
		arm.shoulder_local = Vector3(side * SHOULDER.x, SHOULDER.y, SHOULDER.z)
		arm.stance = MechArm.Stance.NORMAL
		add_child(arm)
		arms.append(arm)


func _physics_process(delta: float) -> void:
	var k := MechSettings.current
	keys.read()
	nozzles.rest()
	gravity_scale = k.fall_gravity if state == State.DOWN else 1.0
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
	legs.place(k, delta)
	# LA POSTURA DE LOS BRAZOS: la elegida parada; recogidos caída y subiendo (se estiran al enderezarse, con las piernas).
	var fallen := state == State.DOWN or state == State.LIFT
	for arm in arms:
		arm.stance = MechArm.Stance.TUCKED if fallen else (MechArm.Stance.COVER if covering else MechArm.Stance.NORMAL)
	cabin.ride()
	label.global_position = global_position + Vector3(0, SIZE + 2.0, 0)
	label.text = "%s · altura %.1f m · inclinación %.0f°\núltimo golpe %.1f m/s %s · caídas %d · pasos %d" % [
		["parada", "TIRADA", "sube", "se endereza"][state], height, tilt, last_hit, last_hit_kind, falls, legs.steps_taken]


## ── PARADA ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _standing(k: MechSettings, delta: float) -> void:
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
	height = global_position.y - support.y - SIZE * 0.5
	if tilt > k.fall_tilt:
		_fall_down()
		return
	_note_hit()
	moves.drive(k, delta)
	if airborne:
		_in_air(length)
	else:
		# SIN PISO BAJO EL APOYO, NO HAY APOYO (un borde, un pozo): queda en el aire, cae derecha y aterriza donde haya.
		if not _follow(k, delta, length):
			take_off()
			return
		_hold(k, length)
	_upright(k, length)
	_turn(k)
	_velocity_after = linear_velocity


## EL LARGO DEL PALO, del centro de la caja al apoyo: de la altura a la que va, por lo agachada que esté.
func rod(k: MechSettings) -> float:
	return (SIZE * 0.5 + k.hover_height) * moves.rod_scale


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
func _follow(k: MechSettings, delta: float, length: float) -> bool:
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
func _hold(k: MechSettings, length: float) -> void:
	var arm := global_basis * Vector3(0.0, -length, 0.0)
	var tip := global_position + arm
	var tip_speed := linear_velocity + angular_velocity.cross(arm)
	var accel := (support - tip) * k.pivot_kp - (tip_speed - support_speed) * k.pivot_kd + Vector3.UP * Mech.gravity()
	apply_force(accel * MASS, arm)


## EL MÚSCULO que la quiere derecha sobre su apoyo (medido contra el giro alrededor del apoyo).
func _upright(k: MechSettings, length: float) -> void:
	var up := global_basis.y.normalized()
	var axis := up.cross(Vector3.UP)
	var angle := up.angle_to(Vector3.UP)
	var spin := Vector3(angular_velocity.x, 0.0, angular_velocity.z)
	var turn := (axis.normalized() * angle if axis.length() > 0.0001 else Vector3.ZERO) * k.upright_kp
	apply_torque((turn - spin * k.upright_kd) * (_inertia + MASS * length * length))


## EL GIRO: hacia `aim_yaw` con velocidad tope, por un motor con fuerza tope. Dos topes, como los pies (plantarse es
## fuerte, salir es lento): GIRAR ELLA es débil (`yaw_force`, del orden de caminar) y FRENAR un giro que ya trae es
## fuerte (`yaw_hold`). *Con un solo tope fuerte, girar apoyada en una pared la despedía: la pared devuelve el torque
## como un empujón (torque ÷ medio lado), varias veces más que lo que empuja caminar. Un freno sólo se opone a lo que se
## mueve: no puede despedirla.*
##
## EL PEDIDO NO SE ACUMULA: nunca va más de `AIM_LEAD` por delante de donde mira. *Sin ese tope, un mouse más rápido que
## el torso se le adelantaba más de media vuelta y el torso giraba «por el camino corto», para el otro lado: según el
## ángulo, el mouse parecía invertido (lo vio el usuario: «en algunos ángulos está invertido y en otros no»).*
func _turn(k: MechSettings) -> void:
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


## DERECHA OTRA VEZ: mirando hacia donde miraba, y a buscar su apoyo.
func _recovered() -> void:
	global_basis = Basis(Vector3.UP, yaw())
	angular_velocity = Vector3.ZERO
	_velocity_after = linear_velocity
	_slick.friction = 0.0
	aim_yaw = global_rotation.y
	grounded = false
	state = State.STANDING


## EL F2: un golpe de costado ARRIBA, suave o fuerte.
func knock(strong: bool) -> void:
	if state != State.STANDING:
		return
	var k := MechSettings.current
	var side := global_basis.x
	side.y = 0.0
	apply_impulse(side.normalized() * MASS * (k.knock_strong if strong else k.knock_soft),
		global_basis * Vector3(0.0, SIZE * 0.5, 0.0))


## ── LO QUE MIDE ──────────────────────────────────────────────────────────────────────────────────────────────────

## Hacia dónde mira, en el piso.
func yaw() -> float:
	var forward := -global_basis.z
	forward.y = 0.0
	return atan2(-forward.x, -forward.z) if forward.length_squared() > 0.01 else aim_yaw


## Su resistencia a girar (un cubo macizo).
func inertia() -> float:
	return _inertia


## EL PISO DEBAJO DE `point`, hasta donde llegan las piernas (el palo y un poco más), o null si no hay. *«No hay piso»
## se leía como «el piso está 200 m abajo» (el valor que devuelve `ground_distance` cuando no encuentra): el apoyo se
## iba ahí y el resorte que agarra la caja la despedía hacia abajo.*
func _floor_below(point: Vector3, length: float) -> Variant:
	var hit := ray(point, point + Vector3.DOWN * (length + SIZE * 0.5))
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


## ── POSEERLA (ver SandboxPossession): lo atiende su teclado ──────────────────────────────────────────────────────

func possess_name() -> String:
	return String(name)


func possess_controls() -> PackedStringArray:
	return keys.controls()


func possess_status() -> String:
	return moves.status()


func possess_begin() -> void:
	keys.begin()


func possess_end() -> void:
	keys.end()


func possess_camera(first: bool, delta: float) -> Transform3D:
	return keys.camera(first, delta)
