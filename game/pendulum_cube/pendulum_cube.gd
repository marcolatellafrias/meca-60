class_name PendulumCube
extends HoverCube

## EL CUBO PÉNDULO: el modelo de equilibrio de la meca (12/11/2026), que no es el de los personajes. El usuario: «el
## sistema de los personajes y de la meca no pueden ser iguales… la meca sí quiero que tenga una colisión 1-1… el cubo se
## inclina como con un eje… desde el centro de ese cubo hasta el piso… las piernas van a seguir siendo IK»; y lo que
## separa una piña de una pared: «el torso sale despedido y los pies quedan atrás… / el torso se frena y los pies
## simplemente se plantan debajo».
##
## UN SOLO CUERPO FÍSICO, EL TORSO (la caja, 1:1), QUE SIEMPRE VA ADELANTE; LOS PIES SIEMPRE LO SIGUEN.
##   · ES UN PÉNDULO INVERTIDO: un palo rígido va del centro del cubo al PUNTO DE APOYO, en el piso (`_support`). La
##     punta del palo está agarrada a ese punto (`pivot_*`); el cubo sólo puede girar alrededor de él. Inclinarse lo
##     baja, solo.
##   · CAMINAR EMPUJA AL TORSO, en su centro, hacia la velocidad pedida, con inercia para arrancar y para frenar
##     (`walk_accel`, `walk_brake`). Los pies no empujan nada.
##   · EL PUNTO DE APOYO SIGUE AL TORSO (`feet_*`): quiere estar debajo de su centro e ir a su velocidad. FRENAR ES
##     INSTANTÁNEO (un pie se planta), pero para alcanzarlo acelera con tope. De ahí sale todo:
##       – una PIÑA le da velocidad al torso, la punta queda agarrada atrás y el cubo se inclina hacia donde va; los pies
##         salen a alcanzarlo y, si no llegan antes de `fall_tilt`, se cae. Arriba vuelca más que abajo.
##       – una PARED frena al torso y los pies se plantan debajo: no hay nada que alcanzar, no se cae, a ninguna
##         velocidad.
##       – ARRANCAR lo inclina un poco hacia adelante (los pies reaccionan con demora, `feet_react`, y van atrás) y se
##         nivela al llegar a velocidad (la opción
##         «B» del usuario: lo que sale solo; ver docs/cubo-pendulo.md para las otras).
##   · UN MÚSCULO lo quiere derecho sobre su apoyo (`upright_*`), chico.
##   · EL GIRO EN Y es un motor con fuerza tope hacia donde se pide (el mouse, manejándolo): si algo lo traba, no gira;
##     un golpe lo gira poco y vuelve (`yaw_*`).
##   · LA CAJA NO ROZA (fricción 0, parada): lo que la frena son los pies, no las paredes.
## LAS PIERNAS SON DIBUJO (IK, MechBody): pisan por radio alrededor del punto de apoyo, mirando hacia donde mira el
## torso; cada pie guarda hacia dónde miraba al pisar y LA PELVIS, una sola pieza, mira al promedio de los dos pies (va
## atrás del torso al girar, y lo alcanza). Caído, se pliegan; al enderezarse, se estiran.
## PASADO `fall_tilt`, O SIN PISO BAJO SU APOYO, SE CAE: suelto del todo; después se recupera con las toberas, como el
## cubo.
##
## Las perillas, en PendulumCubeSettings (el panel F1 de su fila); el F2 le pega arriba.

## Lo más que el pedido del mouse se adelanta a donde mira el torso: bastante menos que media vuelta.
const AIM_LEAD := deg_to_rad(110.0)

## Hacia dónde se le pide mirar (el mouse), en el mundo.
var aim_yaw := 0.0
var steps_taken := 0

var _support := Vector3.ZERO
var _support_speed := Vector3.ZERO
var _grounded := false
## EN EL AIRE a propósito (un salto: ver PendulumMech): derecho, sin apoyo, hasta que la punta del palo vuelve a tocar.
var _airborne := false
var _feet: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _feet_yaw: Array[float] = [0.0, 0.0]
var _step := {}
var _planted := false
var _tuck := 0.0
var _pelvis: MeshInstance3D = null
var _legs: Array[MechLeg] = []
var _slick := PhysicsMaterial.new()


func _ready() -> void:
	super()
	name = "Cubo péndulo"
	aim_yaw = global_rotation.y
	_slick.friction = 0.0
	_slick.bounce = 0.0
	physics_material_override = _slick
	_pelvis = Clay.box(self, MechBody.PELVIS_SIZE, Vector3.ZERO, Clay.METAL.darkened(0.15))
	_pelvis.top_level = true
	for i in 2:
		var leg := MechLeg.new()
		add_child(leg)
		_legs.append(leg)


func tuning() -> HoverCubeSettings:
	return PendulumCubeSettings.shared


## Nada trabado: la inclinación es física y el giro lo lleva su motor.
func _lock(_on: bool) -> void:
	axis_lock_angular_x = false
	axis_lock_angular_y = false
	axis_lock_angular_z = false


func _physics_process(delta: float) -> void:
	super(delta)
	_place_legs(delta)
	_label.text += " · pasos %d" % steps_taken


## ── PARADO ──────────────────────────────────────────────────────────────────────────────────────────────────────

func _standing(knobs: HoverCubeSettings, delta: float) -> void:
	var k := knobs as PendulumCubeSettings
	var rod := _rod(k)
	if not _grounded and not _airborne:
		var floor_point: Variant = _floor_below(global_position, rod)
		if floor_point == null:
			_no_floor()
			return
		_support = floor_point
		_support_speed = Vector3.ZERO
		_grounded = true
	tilt = rad_to_deg(global_basis.y.normalized().angle_to(Vector3.UP))
	height = global_position.y - _support.y - SIZE * 0.5
	if tilt > k.fall_tilt:
		_fall_down()
		return
	_note_hit()
	_drive(k, delta)
	if _airborne:
		_in_air(k, rod)
	else:
		# SIN PISO BAJO EL APOYO, NO HAY APOYO (un borde, un pozo).
		if not _follow(k, delta, rod):
			_no_floor()
			return
		_hold(k, rod)
	_upright(k, rod)
	_turn(k)
	_velocity_after = linear_velocity


## EL LARGO DEL PALO, del centro del cubo al apoyo: de la altura a la que va el cubo. (Quien se agacha lo acorta.)
func _rod(k: PendulumCubeSettings) -> float:
	return SIZE * 0.5 + k.hover_height


## Sin piso bajo el apoyo: el cubo se cae. (Quien sabe estar en el aire, queda en el aire.)
func _no_floor() -> void:
	_fall_down()


## EN EL AIRE: sin apoyo; el punto va debajo, en el piso que haya, y cuando la punta del palo lo toca bajando, ATERRIZA:
## vuelve el apoyo, que arranca con la velocidad que trae (no hay nada que alcanzar).
func _in_air(_k: PendulumCubeSettings, rod: float) -> void:
	var hit := _ray(global_position, global_position + Vector3.DOWN * 400.0)
	if hit.is_empty():
		return
	_support = hit["position"]
	if global_position.y - rod <= _support.y and linear_velocity.y <= 0.0:
		_airborne = false
		_grounded = true
		_support_speed = Vector3(linear_velocity.x, 0.0, linear_velocity.z)
		_planted = false


## Para mirar: el último golpe (lo que cambió la velocidad de costado) y contra qué.
func _note_hit() -> void:
	var change := linear_velocity - _velocity_after
	var flat := Vector3(change.x, 0.0, change.z)
	if flat.length() <= HIT_NOISE:
		return
	last_hit = flat.length()
	var touch := _touch()
	last_hit_kind = "fijo" if bool(touch["fixed"]) else ("golpe" if touch["at"] != null else "empujón")


## CAMINAR: empuja al torso, en su centro, hacia la velocidad pedida (W/S hacia donde mira, A/D de costado), con tope
## para arrancar y para frenar: la inercia de la meca.
func _drive(k: PendulumCubeSettings, delta: float) -> void:
	var wanted := Vector3.ZERO
	if driving and UIState.gameplay_active():
		var facing := Basis(Vector3.UP, _yaw())
		var stick := Vector3(HoverCube._axis(KEY_D, KEY_A), 0.0, -HoverCube._axis(KEY_W, KEY_S))
		wanted = facing * stick.limit_length(1.0) * k.walk_speed
	_walk = wanted
	var flat := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
	var most := k.walk_accel if wanted.length_squared() > 0.0001 else k.walk_brake
	var push := ((wanted - flat) / maxf(delta, 0.0001)).limit_length(most)
	apply_central_force(push * CUBE_MASS)


## EL PUNTO DE APOYO SIGUE AL TORSO (ver arriba): quiere ir a su velocidad y ponerse debajo. Frenar es instantáneo;
## alcanzarlo, con tope.
func _follow(k: PendulumCubeSettings, delta: float, rod: float) -> bool:
	var off := Vector3(global_position.x - _support.x, 0.0, global_position.z - _support.z)
	var wanted := (Vector3(linear_velocity.x, 0.0, linear_velocity.z) + off * k.feet_catch).limit_length(k.feet_speed)
	# Se planta: nunca va más rápido, en su dirección, que lo que hace falta.
	if _support_speed.length_squared() > 0.0001:
		var heading := _support_speed.normalized()
		var needed := maxf(wanted.dot(heading), 0.0)
		if _support_speed.length() > needed:
			_support_speed = heading * needed
	# Salir a alcanzarlo: reaccionan según cuánto les falta (`feet_react`), con tope (`feet_accel`). Por esa demora,
	# mientras el torso acelera los pies van un poco atrás y se inclina hacia adelante; a velocidad, se nivela.
	var gap := (wanted - _support_speed).length()
	_support_speed = _support_speed.move_toward(wanted, minf(k.feet_accel, gap * k.feet_react) * delta)
	_support += _support_speed * delta
	var floor_point: Variant = _floor_below(Vector3(_support.x, global_position.y, _support.z), rod)
	if floor_point == null:
		return false
	_support.y = (floor_point as Vector3).y
	return true


## LA PUNTA DEL PALO, AGARRADA AL APOYO: un resorte firme entre la punta (debajo del cubo, a `rod` de su centro) y el
## punto, y el peso, que lo lleva el apoyo.
func _hold(k: PendulumCubeSettings, rod: float) -> void:
	var arm := global_basis * Vector3(0.0, -rod, 0.0)
	var tip := global_position + arm
	var tip_speed := linear_velocity + angular_velocity.cross(arm)
	var accel := (_support - tip) * k.pivot_kp - (tip_speed - _support_speed) * k.pivot_kd + Vector3.UP * _gravity()
	apply_force(accel * CUBE_MASS, arm)


## EL MÚSCULO que lo quiere derecho sobre su apoyo (medido contra el giro alrededor del apoyo).
func _upright(k: PendulumCubeSettings, rod: float) -> void:
	var up := global_basis.y.normalized()
	var axis := up.cross(Vector3.UP)
	var angle := up.angle_to(Vector3.UP)
	var spin := Vector3(angular_velocity.x, 0.0, angular_velocity.z)
	var turn := (axis.normalized() * angle if axis.length() > 0.0001 else Vector3.ZERO) * k.upright_kp
	apply_torque((turn - spin * k.upright_kd) * (_inertia + CUBE_MASS * rod * rod))


## EL GIRO: hacia `aim_yaw` con velocidad tope, por un motor con fuerza tope. Dos topes, como los pies (plantarse es
## fuerte, salir es lento): GIRAR ÉL es débil (`yaw_force`, del orden de caminar) y FRENAR un giro que ya trae es fuerte
## (`yaw_hold`). *Con un solo tope fuerte, girar apoyado en una pared lo despedía: la pared devuelve el torque como un
## empujón (torque ÷ medio lado), varias veces más que lo que empuja caminar. Un freno sólo se opone a lo que se mueve:
## no puede despedirlo.*
##
## EL PEDIDO NO SE ACUMULA: nunca va más de `AIM_LEAD` por delante de donde mira (como el torso de la meca de pelea,
## Mech._turn_torso). *Sin ese tope, un mouse más rápido que el torso se le adelantaba más de media vuelta y el torso
## giraba «por el camino corto», para el otro lado: según el ángulo, el mouse parecía invertido (lo vio el usuario: «en
## algunos ángulos está invertido y en otros no»).*
func _turn(k: PendulumCubeSettings) -> void:
	var error := clampf(wrapf(aim_yaw - _yaw(), -PI, PI), -AIM_LEAD, AIM_LEAD)
	aim_yaw = _yaw() + error
	var wanted := clampf(error * k.yaw_grip, -deg_to_rad(k.turn_speed), deg_to_rad(k.turn_speed))
	var spin := angular_velocity.y
	var push := (wanted - spin) * k.yaw_grip
	# Lo que le saca giro (va contra `spin`) es freno; lo que le da, motor.
	var braking := spin * push < 0.0
	var most := k.yaw_hold if braking else k.yaw_force
	apply_torque(Vector3.UP * clampf(push, -most, most) * _inertia)


## Hacia dónde mira, en el piso.
func _yaw() -> float:
	var forward := -global_basis.z
	forward.y = 0.0
	return atan2(-forward.x, -forward.z) if forward.length_squared() > 0.01 else aim_yaw


## EL PISO DEBAJO DE `point`, hasta donde llegan las piernas (el palo y un poco más), o null si no hay. *«No hay piso»
## se leía como «el piso está 200 m abajo» (el valor que devuelve `_ground_distance` cuando no encuentra): el apoyo se
## iba ahí y el resorte que agarra el cubo lo despedía hacia abajo.*
func _floor_below(point: Vector3, rod: float) -> Variant:
	var hit := _ray(point, point + Vector3.DOWN * (rod + SIZE * 0.5))
	if hit.is_empty():
		return null
	return hit["position"]


## El punto del piso debajo de `point` (para el dibujo de las piernas, caído).
func _ground_under(point: Vector3) -> Vector3:
	return Vector3(point.x, point.y - _ground_distance(point), point.z)


## ── CAERSE Y VOLVER ─────────────────────────────────────────────────────────────────────────────────────────────

func _fall_down() -> void:
	_slick.friction = 1.0
	state = State.LIMP
	_clock = 0.0
	_grounded = false
	_airborne = false
	falls += 1


func _recovered() -> void:
	super()
	_slick.friction = 0.0
	aim_yaw = global_rotation.y
	_grounded = false


## EL F2: un golpe de costado ARRIBA, suave o fuerte.
func knock(strong: bool) -> void:
	if state != State.HOVER:
		return
	var k := tuning() as PendulumCubeSettings
	var side := global_basis.x
	side.y = 0.0
	apply_impulse(side.normalized() * CUBE_MASS * (k.knock_strong if strong else k.knock_soft),
		global_basis * Vector3(0.0, SIZE * 0.5, 0.0))


## EL MOUSE, manejándolo: hacia dónde mirar.
func possess_controls() -> PackedStringArray:
	return PackedStringArray(["W/S adelante y atrás (hacia donde mira el torso)", "A/D de costado",
		"mouse mira: la cabeza al instante, el torso la alcanza"])


## El mouse de costado pide hacia dónde mirar: la cabeza del que va sentado mira ahí YA, y el torso la alcanza con su
## demora (lo pidió el usuario: «que con delay se gire la nave, pero que yo pueda mirar normalmente»).
func _mouse_turn(amount: float) -> void:
	if state == State.HOVER:
		aim_yaw -= amount


func _head_yaw() -> float:
	return wrapf(aim_yaw - _yaw(), -PI, PI) if state == State.HOVER else 0.0


## ── LA PELVIS Y LAS PIERNAS (dibujo) ─────────────────────────────────────────────────────────────────────────────

func _place_legs(delta: float) -> void:
	var k := tuning() as PendulumCubeSettings
	var standing := state == State.HOVER and _grounded
	# RECOGIDAS tirado y subiendo; ESTIRADAS parado y ya al empezar a enderezarse.
	var folded := state == State.LIMP or state == State.LIFT
	_tuck = move_toward(_tuck, 1.0 if folded else 0.0, delta / maxf(k.fold_time if folded else k.unfold_time, 0.01))
	var share := smoothstep(0.0, 1.0, _tuck)
	var under := _support if standing else _ground_under(global_position)
	var root := Transform3D(Basis(Vector3.UP, _yaw()), under)
	if standing:
		if not _planted:
			_feet = [MechBody.foot_rest(root, -1.0), MechBody.foot_rest(root, 1.0)]
			_feet_yaw = [_yaw(), _yaw()]
			_planted = true
		_stepping(k, delta, root)
	else:
		_planted = false
		_step = {}
	# LA PELVIS: cuelga del cubo, inclinada como él, mirando al promedio de los dos pies.
	var pelvis_yaw := lerp_angle(_feet_yaw[0], _feet_yaw[1], 0.5) if standing else _yaw()
	var leaning := Basis(Quaternion(Vector3.UP, global_basis.y.normalized())) if tilt > 0.01 else Basis()
	var waist := Transform3D(leaning * Basis(Vector3.UP, pelvis_yaw), global_transform * Vector3(0.0, -SIZE * 0.5, 0.0))
	if not standing:
		waist.basis = global_basis
	_pelvis.global_transform = MechBody.pelvis(waist)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		# Estiradas: parado, donde pisan; recién caído, donde pisaban; enderezándose o en el aire, debajo de las caderas.
		var ground := _foot_ground(k, i) if standing else (_feet[i] if state == State.LIMP or state == State.LIFT
			else MechBody.foot_rest(root, side))
		var facing := Basis(Vector3.UP, _feet_yaw[i]) if standing else root.basis
		# EL PIE, NUNCA MÁS LEJOS DE LO QUE LA PIERNA ALCANZA: en el aire cuelga de la cadera (si no, quedaba en el piso).
		var hip := MechBody.hip(waist, side)
		var to_ankle := ground + Vector3.UP * MechBody.ANKLE - hip
		var reach := MechBody.THIGH + MechBody.SHIN - 0.5
		if to_ankle.length() > reach:
			ground = hip + to_ankle.normalized() * reach - Vector3.UP * MechBody.ANKLE
		var open := MechBody.leg(hip, ground, facing)
		_legs[i].pose(_blend(open, _tucked_leg(waist, side), share) if share > 0.001 else open)


## LOS PASOS POR RADIO: cada pie queda donde pisó hasta que su lugar —al costado del apoyo, mirando como el torso,
## adelantado con la marcha— se aleja más que `step_radius` (o él queda mirando muy distinto que el torso); ahí da un
## paso hasta ese lugar, de a un pie.
func _stepping(k: PendulumCubeSettings, delta: float, root: Transform3D) -> void:
	var ahead := Transform3D(root.basis, root.origin + _support_speed * k.step_lead)
	if not _step.is_empty():
		var foot := int(_step["foot"])
		_step["clock"] = float(_step["clock"]) + delta
		_step["to"] = MechBody.foot_rest(ahead, -1.0 if foot == 0 else 1.0)
		_feet_yaw[foot] = lerp_angle(float(_step["yaw_from"]), _yaw(), clampf(float(_step["clock"]) / k.step_time, 0.0, 1.0))
		if float(_step["clock"]) >= k.step_time:
			_feet[foot] = _step["to"]
			_step = {}
		return
	var worst := -1
	var farthest := k.step_radius
	for i in 2:
		var rest := MechBody.foot_rest(ahead, -1.0 if i == 0 else 1.0)
		var away := Vector2(rest.x - _feet[i].x, rest.z - _feet[i].z).length()
		if away > farthest:
			worst = i
			farthest = away
	if worst < 0:
		return
	_step = {"foot": worst, "from": _feet[worst], "to": MechBody.foot_rest(ahead, -1.0 if worst == 0 else 1.0),
		"clock": 0.0, "yaw_from": _feet_yaw[worst]}
	steps_taken += 1


func _foot_ground(k: PendulumCubeSettings, index: int) -> Vector3:
	if _step.is_empty() or int(_step["foot"]) != index:
		return _feet[index]
	var share := clampf(float(_step["clock"]) / k.step_time, 0.0, 1.0)
	var from: Vector3 = _step["from"]
	var to: Vector3 = _step["to"]
	return from.lerp(to, share) + Vector3.UP * sin(share * PI) * k.step_height


## UNA PIERNA RECOGIDA, en el espacio de la cintura: el muslo adelante y casi horizontal, la canilla de vuelta abajo y
## el pie debajo de la cadera. Se pliega, no se achica: las piezas no se estiran.
func _tucked_leg(waist: Transform3D, side: float) -> Dictionary:
	var hip := Vector3(side * MechBody.HIP_X, -MechBody.HIP_DROP, 0.0)
	var knee := hip + Vector3(0.0, 0.15, -1.0).normalized() * MechBody.THIGH
	var ankle := knee + Vector3(0.0, -0.45, 1.0).normalized() * MechBody.SHIN
	var up := waist.basis.y
	return {
		"thigh": MechBody.segment(waist * hip, waist * knee, up),
		"shin": MechBody.segment(waist * knee, waist * ankle, up),
		"foot": Transform3D(waist.basis, waist * (ankle + Vector3(0.0, MechBody.FOOT_SIZE.y * 0.5 - MechBody.ANKLE,
			-MechBody.FOOT_AHEAD))),
		"knee": waist * knee,
	}


static func _blend(from: Dictionary, to: Dictionary, share: float) -> Dictionary:
	return {
		"thigh": (from["thigh"] as Transform3D).interpolate_with(to["thigh"], share),
		"shin": (from["shin"] as Transform3D).interpolate_with(to["shin"], share),
		"foot": (from["foot"] as Transform3D).interpolate_with(to["foot"], share),
		"knee": (from["knee"] as Vector3).lerp(to["knee"], share),
	}
