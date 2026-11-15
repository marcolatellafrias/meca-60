class_name BodyLegs
extends Node3D

## LA PELVIS Y LAS PIERNAS DE UN CUERPO CON EQUILIBRIO (ver BalanceBody), DOS, DESDE UNA PELVIS DEBAJO DE LA CAJA: DIBUJO
## (IK, MechBody; cada pierna, un MechLeg). No sostienen nada: siguen al apoyo del péndulo (ver BalanceBody). Es la pieza
## de piernas de la meca propia; un cuerpo con otro medio de moverse —cuatro patas, patas que salen de los costados de la
## caja y no de abajo, ruedas— arma otra (ver docs/technical/base-comun.md). El usuario: «las piernas van a seguir siendo IK».
##
## LOS PASOS, DE LARGO FIJO (13/11/2026; reemplazan a los pasos por radio). El usuario: «mientras más rápido van a dar
## más rápido los pasos, pero no va a cambiar el largo».
##   · ANDANDO, LOS PIES SE TURNAN SIN PARAR: apenas uno pisa, sale el otro. El que sale es el que quedó más lejos de su
##     lugar (así se turnan solos) y pisa adelante de donde va a estar su lugar cuando pise —al costado del apoyo—, lo
##     que avanza el cuerpo en medio paso, a lo más `step_reach`: siempre el mismo largo. LO QUE DURA UN PASO es lo que
##     tarda el apoyo en recorrer el doble de eso, con topes (`step_fastest`, `step_slowest`): más rápido, más seguido.
##   · QUIETA, SE ACOMODA: un pie que quedó lejos de su lugar (`settle_gap`) o girado (`settle_turn`) da un paso.
##   · NUNCA SE CRUZAN: un pie pisa siempre de su lado del otro, a por lo menos `MechBody.STANCE_X * 1.2`, contado hacia donde mira; y
##     un paso gira el pie a lo más `turn_per_step` de lo que mira el otro: girando en el lugar, gira de a pasos.
##   · LA PELVIS, una sola pieza, mira al promedio de los dos pies (va atrás del torso al girar, y lo alcanza). Es un
##     tambor redondo y hueco: por adentro pasa el ascensor (PelvisLift).
##   · LAS RODILLAS doblan hacia adelante de la pelvis y del pie, un poco hacia afuera (`knee_out`); agachada, más
##     (`knee_out_crouched`).
##   · EL CUERPO NO SUBE NI BAJA CON LOS PASOS: la caja es la de verdad (adentro se camina); lo absorben las rodillas.
##   · CAÍDA, SE PLIEGAN (no se achican: las piezas no se estiran) con easing; al empezar a enderezarse, se estiran
##     hacia debajo de las caderas: al quedar derecha ya está parada.
##   · EL PIE, NUNCA MÁS LEJOS DE LO QUE LA PIERNA ALCANZA: en el aire cuelga de la cadera.
##
## LOS PASOS NUEVOS, EL SISTEMA CLÁSICO DE PIERNAS DE MECA CON IK (13/11/2026; con el interruptor de LegSettings, F4,
## mientras se comparan con los de arriba). El usuario: «el sistema actual es uno derivado de los personajes y es medio
## rebuscado… es un trope bastante común el de piernas para mecas con IK».
##   · CADA PIE TIENE SU LUGAR: debajo de su cadera, pegado a la caja, EN EL PISO DE VERDAD (un rayo; pisa techos y
##     escalones, cada pie a su altura, y las rodillas lo absorben: la caja no sube ni baja).
##   · UN PIE QUE QUEDÓ UN TERCIO DE PASO ATRÁS DE SU LUGAR, SALE, y pisa un tercio adelante de donde va a estar su
##     lugar al pisar; en el aire dura lo que la caja tarda en recorrer el otro tercio, con topes. Así recorre en el
##     mundo siempre el mismo largo (`stride`): más rápido, más seguido.
##   · GIRAR ES LO MISMO: el lugar gira con la caja, el pie queda lejos y sale. Y como cada lugar está de su lado, no se
##     cruzan. No hay reglas de giro ni de cruce.
##   · SE TURNAN: no sale uno mientras el otro está en el aire.
##   · QUIETA, SE ACOMODA: frenada, después de `settle_wait`, trae el pie que quedó corrido o girado.

## Lo mínimo entre los dos pies, de costado, contado hacia donde mira el que pisa (m).
## Más lento que esto (m/s) está quieta: los pies sólo se acomodan.
const STILL := 0.4

var body: BalanceBody = null
var steps_taken := 0

var _feet: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _feet_yaw: Array[float] = [0.0, 0.0]
## El paso de ahora: qué pie (−1, ninguno), de dónde salió y hacia dónde miraba, cuánto lleva y cuánto dura.
var _swing := -1
var _swing_from := Vector3.ZERO
var _swing_yaw := 0.0
var _swing_clock := 0.0
var _swing_time := 1.0
var _planted := false
var _tuck := 0.0
## Pasos nuevos: cuánto lleva quieta (s).
var _still_clock := 0.0
var _pelvis: MeshInstance3D = null
var _legs: Array[MechLeg] = []


func _ready() -> void:
	_pelvis = PelvisLift.tube(Clay.METAL.darkened(0.15))
	_pelvis.top_level = true
	add_child(_pelvis)
	for i in 2:
		var leg := MechLeg.new()
		leg.length_scale = body.leg_scale
		add_child(leg)
		_legs.append(leg)


## Los pies vuelven a plantarse debajo (al aterrizar).
func replant() -> void:
	_planted = false


func place(k: BodySettings, delta: float) -> void:
	var standing := body.state == BalanceBody.State.STANDING and body.grounded
	# RECOGIDAS tirada y subiendo; ESTIRADAS parada y ya al empezar a enderezarse.
	var folded := body.state == BalanceBody.State.DOWN or body.state == BalanceBody.State.LIFT
	_tuck = move_toward(_tuck, 1.0 if folded else 0.0, delta / maxf(k.fold_time if folded else k.unfold_time, 0.01))
	var share := smoothstep(0.0, 1.0, _tuck)
	var yaw := body.yaw()
	var centre := body.global_position
	var under := body.support if standing else Vector3(centre.x, centre.y - body.ground_distance(centre), centre.z)
	var root := Transform3D(Basis(Vector3.UP, yaw), under)
	if standing:
		var classic := LegSettings.current.new_steps
		if not _planted:
			if classic:
				_feet = [_home(0, yaw, 0.0), _home(1, yaw, 0.0)]
			else:
				_feet = [MechBody.foot_rest(root, -1.0), MechBody.foot_rest(root, 1.0)]
			_feet_yaw = [yaw, yaw]
			_swing = -1
			_still_clock = 0.0
			_planted = true
		if classic:
			_classic(delta, yaw)
		else:
			_stepping(k, delta, yaw)
	else:
		_planted = false
		_swing = -1
	# LA PELVIS: cuelga de la caja, inclinada como ella, mirando al promedio de los dos pies.
	var pelvis_yaw := lerp_angle(_feet_yaw[0], _feet_yaw[1], 0.5) if standing else yaw
	var leaning := Basis(Quaternion(Vector3.UP, body.global_basis.y.normalized())) if body.tilt > 0.01 else Basis()
	var waist := Transform3D(leaning * Basis(Vector3.UP, pelvis_yaw),
		body.global_transform * Vector3(0.0, -body.size.y * 0.5, 0.0))
	if not standing:
		waist.basis = body.global_basis
	_pelvis.global_transform = MechBody.pelvis(waist)
	var crouched := clampf((1.0 - body.moves.rod_scale) / maxf(1.0 - k.crouch_rod, 0.01), 0.0, 1.0)
	var out := lerpf(k.knee_out, k.knee_out_crouched, crouched)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		# Estiradas: parada, donde pisan; recién caída, donde pisaban; enderezándose o en el aire, debajo de las caderas.
		var ground := _foot_ground(k, i) if standing else (_feet[i] if folded else MechBody.foot_rest(root, side))
		var facing := Basis(Vector3.UP, _feet_yaw[i]) if standing else root.basis
		var hip := MechBody.hip(waist, side)
		var to_ankle := ground + Vector3.UP * MechBody.ANKLE - hip
		var reach := (MechBody.THIGH + MechBody.SHIN) * body.leg_scale - 0.5
		if to_ankle.length() > reach:
			ground = hip + to_ankle.normalized() * reach - Vector3.UP * MechBody.ANKLE
		# LA RODILLA: hacia adelante de la pelvis y del pie, y un poco hacia afuera.
		var ahead := -waist.basis.z - facing.z
		ahead.y = 0.0
		var knee_way := ahead.normalized() + waist.basis.x * side * out
		var open := MechBody.leg(hip, ground, facing, knee_way, body.leg_scale)
		_legs[i].pose(BodyLegs._blend(open, _tucked_leg(waist, side), share) if share > 0.001 else open)


## LOS PASOS DE LARGO FIJO (ver arriba).
func _stepping(k: BodySettings, delta: float, yaw: float) -> void:
	if _swing >= 0:
		_swing_clock += delta
		if _swing_clock < _swing_time:
			return
		var landed := _target(k, _swing, yaw, 0.0)
		_feet[_swing] = landed["at"]
		_feet_yaw[_swing] = landed["yaw"]
		_swing = -1
	# EL QUE SALE: el que quedó más lejos de su lugar. Andando, siempre sale uno; quieta, sólo si quedó lejos o girado.
	var speed := body.support_speed.length()
	var moving := speed > STILL
	var time := k.step_slowest
	if moving:
		time = clampf(2.0 * _reach(k) / speed, k.step_fastest, k.step_slowest)
	var worst := -1
	var farthest := 0.0
	for i in 2:
		var spot := _target(k, i, yaw, time)
		var at: Vector3 = spot["at"]
		var gap := Vector2(at.x - _feet[i].x, at.z - _feet[i].z).length()
		var turned := rad_to_deg(absf(angle_difference(_feet_yaw[i], float(spot["yaw"]))))
		var due := gap > 0.05 if moving else (gap > _settle(k) or turned > k.settle_turn)
		var score := gap + turned * 0.05
		if due and score > farthest:
			worst = i
			farthest = score
	if worst < 0:
		return
	_swing = worst
	_swing_from = _feet[worst]
	_swing_yaw = _feet_yaw[worst]
	_swing_clock = 0.0
	_swing_time = time
	steps_taken += 1


## DÓNDE PISA el pie `index` si le quedan `left` segundos de paso: al costado de donde va a estar el apoyo, adelantado
## lo que avanza el cuerpo en medio paso (a lo más `step_reach`), mirando como el torso —a lo más `turn_per_step` del
## otro pie— y nunca cruzado. Devuelve `at` (el punto del piso) y `yaw`.
func _target(k: BodySettings, index: int, yaw: float, left: float) -> Dictionary:
	var side := -1.0 if index == 0 else 1.0
	var other := 1 - index
	var turn := deg_to_rad(k.turn_per_step)
	var facing := _feet_yaw[other] + clampf(angle_difference(_feet_yaw[other], yaw), -turn, turn)
	var speed := body.support_speed.length()
	var lead := Vector3.ZERO
	if speed > 0.01:
		var whole := _swing_time if _swing == index else left
		lead = body.support_speed / speed * minf(_reach(k), speed * whole * 0.5)
	var basis := Basis(Vector3.UP, facing)
	var at := body.support + body.support_speed * left + basis * Vector3(side * MechBody.STANCE_X, 0.0, 0.0) + lead
	# NUNCA CRUZADO: de su lado del otro pie, a por lo menos MechBody.STANCE_X * 1.2.
	var local := basis.inverse() * (at - _feet[other])
	if local.x * side < MechBody.STANCE_X * 1.2:
		local.x = side * MechBody.STANCE_X * 1.2
		at = _feet[other] + basis * local
	at.y = body.support.y
	return {"at": at, "yaw": facing}


## EL PIE EN EL AIRE: de donde salió hacia donde va a pisar (que se mueve con el cuerpo), en arco.
func _foot_ground(k: BodySettings, index: int) -> Vector3:
	if _swing != index:
		return _feet[index]
	if LegSettings.current.new_steps:
		return _classic_swing(index)
	var share := clampf(_swing_clock / _swing_time, 0.0, 1.0)
	var spot := _target(k, index, body.yaw(), maxf(_swing_time - _swing_clock, 0.0))
	var to: Vector3 = spot["at"]
	var eased := smoothstep(0.0, 1.0, share)
	_feet_yaw[index] = lerp_angle(_swing_yaw, float(spot["yaw"]), eased)
	var lift := clampf(Vector2(to.x - _swing_from.x, to.z - _swing_from.z).length() / (2.0 * _reach(k)), 0.35, 1.0)
	return _swing_from.lerp(to, eased) + Vector3.UP * sin(share * PI) * _lift(k) * lift


## LOS PASOS NUEVOS (ver arriba): termina el paso de ahora y, si no hay ninguno en el aire, ve si sale uno.
func _classic(delta: float, yaw: float) -> void:
	var s := LegSettings.current
	var stride := s.stride * _stride()
	if _swing >= 0:
		_swing_clock += delta
		if _swing_clock < _swing_time:
			return
		_feet[_swing] = _landing(_swing, yaw, 0.0)
		_feet_yaw[_swing] = yaw
		_swing = -1
	var velocity := Vector3(body.support_speed.x, 0.0, body.support_speed.z)
	var speed := velocity.length()
	var moving := speed > STILL
	_still_clock = 0.0 if moving else _still_clock + delta
	var worst := -1
	var farthest := 0.0
	for i in 2:
		var off := _feet[i] - _home(i, yaw, 0.0)
		off.y = 0.0
		var gap := off.length()
		var turned := absf(angle_difference(_feet_yaw[i], yaw))
		# ATRÁS (o de costado) a un tercio de paso: sale. Adelante no: es el que recién pisó.
		var due := gap >= stride / 3.0 and (not moving or off.dot(velocity) <= 0.0)
		# Quieta, después de esperar: lo corrido o girado vuelve a su lugar.
		if not moving and _still_clock >= s.settle_wait:
			due = due or gap > stride * 0.05 or turned > deg_to_rad(5.0)
		if due and gap + turned > farthest:
			worst = i
			farthest = gap + turned
	if worst < 0:
		return
	_swing = worst
	_swing_from = _feet[worst]
	_swing_yaw = _feet_yaw[worst]
	_swing_clock = 0.0
	_swing_time = clampf(stride / 3.0 / speed, s.fastest, s.slowest) if moving else s.slowest
	steps_taken += 1


## EL LUGAR DEL PIE `index` dentro de `ahead` segundos: debajo de su cadera, en el piso de verdad.
func _home(index: int, yaw: float, ahead: float) -> Vector3:
	var side := -1.0 if index == 0 else 1.0
	var root := Transform3D(Basis(Vector3.UP, yaw), body.support + Vector3(body.support_speed.x, 0.0,
		body.support_speed.z) * ahead)
	return _ground(MechBody.foot_rest(root, side))


## DÓNDE PISA el pie `index` si le quedan `left` segundos de paso: un tercio de paso adelante de su lugar, hacia donde va.
func _landing(index: int, yaw: float, left: float) -> Vector3:
	var at := _home(index, yaw, left)
	var velocity := Vector3(body.support_speed.x, 0.0, body.support_speed.z)
	if velocity.length() > STILL:
		at = _ground(at + velocity.normalized() * LegSettings.current.stride * _stride() / 3.0)
	return at


## EL PIE EN EL AIRE (pasos nuevos): de donde salió hacia donde va a pisar, que se mueve con la caja, en arco.
func _classic_swing(index: int) -> Vector3:
	var s := LegSettings.current
	var share := clampf(_swing_clock / _swing_time, 0.0, 1.0)
	var to := _landing(index, body.yaw(), maxf(_swing_time - _swing_clock, 0.0))
	var eased := smoothstep(0.0, 1.0, share)
	_feet_yaw[index] = lerp_angle(_swing_yaw, body.yaw(), eased)
	var stride := s.stride * _stride()
	var lift := clampf(Vector2(to.x - _swing_from.x, to.z - _swing_from.z).length() / stride, 0.35, 1.0)
	return _swing_from.lerp(to, eased) + Vector3.UP * sin(share * PI) * s.lift * _stride() * lift


## EL PISO DE VERDAD debajo de `at`: un rayo desde la altura de la caja hacia abajo, que saltea lo que se mueve y los
## pies con choque de la meca. Sin piso, la altura del apoyo.
func _ground(at: Vector3) -> Vector3:
	var top := Vector3(at.x, body.global_position.y, at.z)
	var query := PhysicsRayQueryParameters3D.create(top, Vector3(at.x, body.support.y - body.hover, at.z))
	var skip: Array[RID] = [body.get_rid()]
	if body.stomp != null:
		for foot in body.stomp.bodies():
			skip.append(foot.get_rid())
	var space := body.get_world_3d().direct_space_state
	for attempt in 8:
		query.exclude = skip
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			break
		var other := hit.get("collider") as CollisionObject3D
		if other == null or (other is StaticBody3D and not other is AnimatableBody3D):
			return Vector3(at.x, (hit["position"] as Vector3).y, at.z)
		skip.append(other.get_rid())
	return Vector3(at.x, body.support.y, at.z)


## UNA PIERNA RECOGIDA, en el espacio de la cintura: el muslo adelante y casi horizontal, la canilla de vuelta abajo y
## el pie debajo de la cadera.
func _tucked_leg(waist: Transform3D, side: float) -> Dictionary:
	var hip := Vector3(side * MechBody.HIP_X, -MechBody.HIP_DROP, 0.0)
	var knee := hip + Vector3(0.0, 0.15, -1.0).normalized() * MechBody.THIGH * body.leg_scale
	var ankle := knee + Vector3(0.0, -0.45, 1.0).normalized() * MechBody.SHIN * body.leg_scale
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


## EL PASO DE ESTAS PIERNAS: el del F1 y el del F4 son los de piernas medianas; se escalan con su largo (MechBody.stride,
## del F2, por el de este cuerpo: BalanceBody.leg_scale).
func _stride() -> float:
	return MechBody.stride * body.leg_scale


func _reach(k: BodySettings) -> float:
	return k.step_reach * _stride()


func _lift(k: BodySettings) -> float:
	return k.step_height * _stride()


func _settle(k: BodySettings) -> float:
	return k.settle_gap * _stride()


## DÓNDE ESTÁN LOS PIES (mundo), como se dibujaron en el último paso: los siguen los pies con choque (StompFeet).
func foot_transforms() -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for leg in _legs:
		out.append(leg.foot())
	return out
