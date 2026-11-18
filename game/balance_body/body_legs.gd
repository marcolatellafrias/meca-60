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
##     cilindro acostado de cadera a cadera, el de la maqueta de la meca jaula (ver `_ready`). *Hasta el 17/11/2026 era
##     un tambor redondo y hueco, por el que pasaba el ascensor de la meca grande (PelvisLift), y la jaula lo cambiaba
##     por el cilindro.*
##   · LAS RODILLAS doblan hacia adelante de la pelvis y del pie, un poco hacia afuera (`knee_out`); agachada, más
##     (`knee_out_crouched`).
##   · EL CUERPO NO SUBE NI BAJA CON LOS PASOS: la caja es la de verdad (adentro se camina); lo absorben las rodillas.
##   · CAÍDA, SE PLIEGAN (no se achican: las piezas no se estiran) con easing; al empezar a enderezarse, se estiran
##     hacia debajo de las caderas: al quedar derecha ya está parada.
##   · EL PIE, NUNCA MÁS LEJOS DE LO QUE LA PIERNA ALCANZA: en el aire cuelga de la cadera.
##
## LOS PASOS NUEVOS SON LA MARCHA COMÚN (Gait, game/common/; 18/11/2026, módulo Jefes, con el aviso a las armas): un
## ciclo continuo, cada pie con su desfase, que pisa adelantado según la velocidad (el apoyo queda centrado debajo de su
## lugar). El usuario: «me gusta pasarlo al sistema para que lo usen todos». *Hasta ese día eran la regla de abajo (sale
## a un tercio de paso atrás, pisa un tercio adelante): entre un paso y el otro un tercio del ciclo ningún pie estaba en
## el aire; el usuario: «hacen paso, paso, pausa».* Lo de abajo sigue valiendo para el lugar de cada pie y el piso.
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
##   · QUIETA, SE ACOMODA: frenada, cada pie da un paso hasta su lugar (la marcha común, sin esperar).

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
## HACIA DÓNDE APUNTAN LAS PIERNAS (el giro en Y de la pelvis, en el mundo): lo lee quien quiera seguirlas (el módulo de
## arriba de la meca jaula, ver CageMech.upper_heading).
var facing_yaw := 0.0
var _swing_clock := 0.0
var _swing_time := 1.0
var _planted := false
var _tuck := 0.0
## LA MARCHA COMÚN de los pasos nuevos (Gait), de dos caderas; y hacia dónde miraba cada pie al salir.
var _gait := Gait.new()
var _lift_yaw: Array[float] = [0.0, 0.0]
## LA CAJA AL CAMINAR (sube con el paso, se inclina de costado; LegSettings, «La caja al caminar»): las señales de la
## marcha (GaitSignals), la tabla común (ProceduralBoneAnimator) y la pieza que mueve, sin dibujo: la lee el motor
## (`pose_offset`, en KinematicMover.body_place).
var signals := GaitSignals.new()
var _pose := Node3D.new()
var _table: ProceduralBoneAnimator = null
var _pelvis: MeshInstance3D = null
var _legs: Array[MechLeg] = []


func _ready() -> void:
	# LA PELVIS: el nodo que se mueve (centrado como la pelvis de MechBody) y, colgado de él, el cilindro.
	var measures := body.measures
	_pelvis = MeshInstance3D.new()
	_pelvis.top_level = true
	add_child(_pelvis)
	Clay.cylinder(_pelvis, measures.LEG_THICKNESS * 0.55, measures.HIP_X * 2.0 - measures.LEG_THICKNESS * 0.9,
		Vector3(0.0, measures.PELVIS_SIZE.y * 0.5 - measures.HIP_DROP, 0.0), MechBody.JOINT_COLOR, Vector3(0.0, 0.0, 90.0))
	# En el esqueleto: cuelga del hueso de la pelvis (que apunta para abajo: se le deshace el medio giro).
	if body.skeleton != null:
		remove_child(_pelvis)
		body.skeleton.pelvis.add_child(_pelvis)
		_pelvis.top_level = false
		_pelvis.transform = Transform3D(Basis.from_euler(MechSkeleton.DOWN).inverse(), Vector3.ZERO)
	for i in 2:
		var leg := MechLeg.new()
		leg.measures = body.measures
		if body.skeleton != null:
			leg.thigh_bone = body.skeleton.thighs[i]
			leg.shin_bone = body.skeleton.shins[i]
			leg.foot_bone = body.skeleton.feet[i]
		add_child(leg)
		_legs.append(leg)
	_pose.name = "LaCajaAlCaminar"
	add_child(_pose)
	_table = ProceduralBoneAnimator.create(signals)
	_table.register_formula(_pose, ProceduralBoneAnimator.Axis.POS_Y, _bob_now)
	_table.register_formula(_pose, ProceduralBoneAnimator.Axis.ROT_Z, _lean_now)


## Los pies vuelven a plantarse debajo (al aterrizar).
func replant() -> void:
	_planted = false


func place(k: BodySettings, delta: float) -> void:
	var standing := body.state == BalanceBody.State.STANDING and body.grounded
	# RECOGIDAS tirada y subiendo; ESTIRADAS parada y ya al empezar a enderezarse. LA CINEMÁTICA, NUNCA RECOGIDAS: se
	# cae en su POSE DE REPOSO, la de parada quieta (las rodillas dobladas a su altura de siempre, los pies planos), y
	# esa pose entera se vuelca con la caja: tirada de espaldas, los pies apuntan para arriba (el usuario, 15/11/2026:
	# «agarrar la pose de reposo… las piernas deberían quedar flexionadas como con el factor de distancia del piso»).
	var folded := (body.state == BalanceBody.State.DOWN or body.state == BalanceBody.State.LIFT) and not body.kinematic
	var lying := body.kinematic and not standing and body.state != BalanceBody.State.STANDING
	_tuck = move_toward(_tuck, 1.0 if folded else 0.0, delta / maxf(k.fold_time if folded else k.unfold_time, 0.01))
	var share := smoothstep(0.0, 1.0, _tuck)
	# RECOGIDAS EN EL DASH, LEVITANDO Y EN PICADA (KinematicMover.tucks), de una; al terminar se plantan debajo. SUTIL
	# (el usuario: «parecerse a la pose en reposo pero un poco más recogida nomás, y con los pies un poco apuntando hacia
	# abajo»): la pose de parada quieta con el pie subido hacia la cadera (LegSettings.tuck_lift) y la punta abajo.
	var tucked := body.kinematic and body.mover != null and body.state == BalanceBody.State.STANDING \
		and body.mover.tucks()
	var yaw := body.yaw()
	var centre := body.global_position
	var under := body.support if standing else Vector3(centre.x, centre.y - body.ground_distance(centre), centre.z)
	var root := Transform3D(Basis(Vector3.UP, yaw), under)
	# Tirada: se arma parada (sobre el motor, como si no se hubiera caído) y después se vuelca con la caja (`fall`).
	var upright := body.mover.standing_place() if lying else Transform3D()
	var fall := body.global_transform * upright.affine_inverse() if lying else Transform3D()
	if lying:
		yaw = upright.basis.get_euler().y
		root = Transform3D(upright.basis, body.mover.global_position)
	if standing and not tucked:
		var classic := LegSettings.current.new_steps
		if not _planted:
			if classic:
				_gait_setup()
				_gait.place(Transform3D(Basis(Vector3.UP, yaw), body.support))
				_feet = [_gait.feet[0], _gait.feet[1]]
			else:
				_feet = [body.measures.foot_rest(root, -1.0), body.measures.foot_rest(root, 1.0)]
			_feet_yaw = [yaw, yaw]
			_swing = -1
			_planted = true
		if classic:
			_classic(delta, yaw)
		else:
			_stepping(k, delta, yaw)
	else:
		_planted = false
		_swing = -1
	# LA CAJA AL CAMINAR: las señales (parada, de la marcha; si no, se apagan) y la tabla.
	signals.full_speed = body.kinematic_settings().walk_speed
	if standing and not tucked and LegSettings.current.new_steps:
		signals.read(_gait, Basis(Vector3.UP, yaw), body.support_speed, delta)
	else:
		signals.step_progress = 0.0
		signals.plant = 0.0
		signals.horizontal_velocity_smooth = signals.horizontal_velocity_smooth.lerp(Vector2.ZERO, 1.0 - exp(-8.0 * delta))
	_table.update()
	# LA PELVIS: cuelga de la caja, inclinada como ella, mirando al promedio de los dos pies.
	var pelvis_yaw := lerp_angle(_feet_yaw[0], _feet_yaw[1], 0.5) if standing and not tucked else yaw
	facing_yaw = pelvis_yaw
	var leaning := Basis(Quaternion(Vector3.UP, body.global_basis.y.normalized())) if body.tilt > 0.01 else Basis()
	var waist := Transform3D(leaning * Basis(Vector3.UP, pelvis_yaw),
		body.global_transform * Vector3(0.0, -body.size.y * 0.5, 0.0))
	if lying:
		waist = Transform3D(upright.basis, upright * Vector3(0.0, -body.size.y * 0.5, 0.0))
	elif not standing:
		waist.basis = body.global_basis
	if body.skeleton != null:
		body.skeleton.put_pelvis(fall * body.measures.pelvis(waist))
	else:
		_pelvis.global_transform = fall * body.measures.pelvis(waist)
	var crouched := clampf((1.0 - body.moves.rod_scale) / maxf(1.0 - k.crouch_rod, 0.01), 0.0, 1.0)
	var out := lerpf(k.knee_out, k.knee_out_crouched, crouched)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		# Estiradas: parada, donde pisan; recién caída, donde pisaban; enderezándose o en el aire, debajo de las caderas.
		var ground := _foot_ground(k, i) if standing else (_feet[i] if folded else body.measures.foot_rest(root, side))
		var facing := Basis(Vector3.UP, _feet_yaw[i]) if standing else root.basis.orthonormalized()
		var hip := body.measures.hip(waist, side)
		if tucked:
			# Debajo de su lugar de parada, a la altura de parada menos lo que se recoge.
			var rest := body.measures.foot_rest(Transform3D(Basis(Vector3.UP, yaw), body.global_position), side)
			var drop := (body.hover - body.measures.HIP_DROP) * (1.0 - LegSettings.current.tuck_lift)
			ground = Vector3(rest.x, hip.y - drop, rest.z)
			facing = Basis(Vector3.UP, yaw)
		var to_ankle := ground + Vector3.UP * body.measures.ANKLE - hip
		var reach := body.measures.leg_reach()
		if to_ankle.length() > reach:
			ground = hip + to_ankle.normalized() * reach - Vector3.UP * body.measures.ANKLE
		# LA RODILLA: hacia adelante de la pelvis y del pie, y un poco hacia afuera.
		var ahead := -waist.basis.z - facing.z
		ahead.y = 0.0
		var knee_way := ahead.normalized() + waist.basis.x * side * out
		# CON EL ESQUELETO, LA IK COMÚN SOBRE LOS HUESOS (MechLeg.reach_to): el pie plano mirando hacia donde camina
		# (recogido, con la punta abajo); tirada, todo volcado con la caja (`fall`). Plegándose (la física), como antes.
		if body.skeleton != null and share <= 0.001:
			var forward := -facing.z
			forward.y = 0.0
			forward = forward.normalized() if forward.length_squared() > 0.0001 else Vector3.FORWARD
			var flat := Basis.looking_at(forward, Vector3.UP)
			if tucked:
				flat = flat * Basis(Vector3.RIGHT, -deg_to_rad(LegSettings.current.tuck_toes))
			if lying:
				ground = fall * ground
				knee_way = fall.basis * knee_way
				flat = fall.basis * flat
			_legs[i].reach_to(ground, knee_way, flat)
			continue
		var open := body.measures.leg(hip, ground, facing, knee_way)
		if tucked:
			open = BodyLegs._toes_down(open, LegSettings.current.tuck_toes)
		if lying:
			open = BodyLegs._moved(open, fall)
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
	var at := body.support + body.support_speed * left + basis * Vector3(side * body.measures.STANCE_X, 0.0, 0.0) + lead
	# NUNCA CRUZADO: de su lado del otro pie, a por lo menos MechBody.STANCE_X * 1.2.
	var local := basis.inverse() * (at - _feet[other])
	if local.x * side < body.measures.STANCE_X * 1.2:
		local.x = side * body.measures.STANCE_X * 1.2
		at = _feet[other] + basis * local
	at.y = body.support.y
	return {"at": at, "yaw": facing}


## EL PIE EN EL AIRE: de donde salió hacia donde va a pisar (que se mueve con el cuerpo), en arco.
func _foot_ground(k: BodySettings, index: int) -> Vector3:
	if _swing != index:
		return _feet[index]
	if LegSettings.current.new_steps:
		return _feet[index]
	var share := clampf(_swing_clock / _swing_time, 0.0, 1.0)
	var spot := _target(k, index, body.yaw(), maxf(_swing_time - _swing_clock, 0.0))
	var to: Vector3 = spot["at"]
	var eased := smoothstep(0.0, 1.0, share)
	_feet_yaw[index] = lerp_angle(_swing_yaw, float(spot["yaw"]), eased)
	var lift := clampf(Vector2(to.x - _swing_from.x, to.z - _swing_from.z).length() / (2.0 * _reach(k)), 0.35, 1.0)
	return _swing_from.lerp(to, eased) + Vector3.UP * sin(share * PI) * _lift(k) * lift


## LOS PASOS NUEVOS (ver arriba): la marcha común (Gait) con dos caderas; acá sólo el giro de cada pie, que va de
## hacia donde miraba al salir a hacia donde mira la caja.
func _classic(delta: float, yaw: float) -> void:
	_gait_setup()
	_gait.update(delta, Transform3D(Basis(Vector3.UP, yaw), body.support), body.support_speed)
	steps_taken = _gait.steps_taken
	_swing = -1
	for i in 2:
		var share: float = _gait.swing_share[i]
		if share >= 0.0 and _feet_yaw.size() > i:
			if share <= 0.0 or _lift_yaw[i] == INF:
				_lift_yaw[i] = _feet_yaw[i]
			_feet_yaw[i] = lerp_angle(_lift_yaw[i], yaw, smoothstep(0.0, 1.0, share))
			_swing = i
		else:
			if _lift_yaw[i] != INF:
				_feet_yaw[i] = yaw
			_lift_yaw[i] = INF
		_feet[i] = _gait.feet[i]


## Las perillas de la marcha, de LegSettings (F4) y de las medidas de estas piernas: el ciclo es dos pasos, y en el aire
## va un poco menos de la mitad de cada uno.
func _gait_setup() -> void:
	var s := LegSettings.current
	if _gait.rests.is_empty():
		var rests: Array[Vector3] = [body.measures.foot_rest(Transform3D(), -1.0),
			body.measures.foot_rest(Transform3D(), 1.0)]
		_gait.setup(rests)
		_gait.ground = _ground
	_gait.stride = s.stride * _stride()
	_gait.lift = s.lift * _stride()
	_gait.stomp = s.stomp
	_gait.fastest = s.fastest * 2.0 / _gait.swing_part
	_gait.slowest = s.slowest * 2.0 / _gait.swing_part


## LAS DOS FILAS DE LA TABLA: sube a mitad de cada paso y se hunde al pisar (m) y se inclina de costado según la velocidad de costado (rad).
func _bob_now() -> float:
	var s := LegSettings.current
	return (signals.step_progress * s.bob - signals.plant * s.stomp_dip) * _stride()


func _lean_now() -> float:
	var side := clampf(signals.horizontal_velocity_smooth.x / maxf(signals.full_speed, 0.01), -1.0, 1.0)
	return side * deg_to_rad(LegSettings.current.side_lean)


## LO QUE LA CAJA SUBE Y SE INCLINA CAMINANDO, en sus ejes (la tabla; ver `signals`): lo compone el motor.
func pose_offset() -> Transform3D:
	return _pose.transform


## Si algún pie está en el aire (para las pruebas: la pausa entre pasos).
func swinging() -> bool:
	return _swing >= 0


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
	var hip := Vector3(side * body.measures.HIP_X, -body.measures.HIP_DROP, 0.0)
	var knee := hip + Vector3(0.0, 0.15, -1.0).normalized() * body.measures.THIGH
	var ankle := knee + Vector3(0.0, -0.45, 1.0).normalized() * body.measures.SHIN
	var up := waist.basis.y
	return {
		"thigh": MechBody.segment(waist * hip, waist * knee, up),
		"shin": MechBody.segment(waist * knee, waist * ankle, up),
		"foot": Transform3D(waist.basis, waist * (ankle + Vector3(0.0, body.measures.FOOT_SIZE.y * 0.5 - body.measures.ANKLE,
			-body.measures.FOOT_AHEAD))),
		"knee": waist * knee,
	}


## LA PUNTA DEL PIE `degrees` grados hacia abajo, girando sobre el tobillo (recogidas).
static func _toes_down(pose: Dictionary, degrees: float) -> Dictionary:
	var foot: Transform3D = pose["foot"]
	var ankle: Vector3 = pose["ankle"]
	var turn := Basis(foot.basis.x.normalized(), -deg_to_rad(degrees))
	var out := pose.duplicate()
	out["foot"] = Transform3D(turn * foot.basis, ankle + turn * (foot.origin - ankle))
	return out


## UNA PIERNA ARMADA, movida entera por `by` (tirada: la pose de parada, volcada con la caja).
static func _moved(pose: Dictionary, by: Transform3D) -> Dictionary:
	return {
		"thigh": by * (pose["thigh"] as Transform3D),
		"shin": by * (pose["shin"] as Transform3D),
		"foot": by * (pose["foot"] as Transform3D),
		"knee": by * (pose["knee"] as Vector3),
		"ankle": by * (pose["ankle"] as Vector3),
	}


static func _blend(from: Dictionary, to: Dictionary, share: float) -> Dictionary:
	return {
		"thigh": (from["thigh"] as Transform3D).interpolate_with(to["thigh"], share),
		"shin": (from["shin"] as Transform3D).interpolate_with(to["shin"], share),
		"foot": (from["foot"] as Transform3D).interpolate_with(to["foot"], share),
		"knee": (from["knee"] as Vector3).lerp(to["knee"], share),
	}


## EL PASO DE ESTAS PIERNAS: el del F1 y el del F4 son los de piernas medianas; se escalan con su largo (el `stride` de
## las medidas de este cuerpo).
func _stride() -> float:
	return body.measures.stride


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
