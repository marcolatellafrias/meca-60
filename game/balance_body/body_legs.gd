class_name BodyLegs
extends Node3D

## LA PELVIS Y LAS PIERNAS DE UN CUERPO CON EQUILIBRIO (ver BalanceBody), DOS, DESDE UNA PELVIS DEBAJO DE LA CAJA: DIBUJO
## (IK, MechBody; cada pierna, un MechLeg). No sostienen nada: siguen al apoyo del péndulo (ver BalanceBody). Es la pieza
## de piernas de la meca propia; un cuerpo con otro medio de moverse —cuatro patas, patas que salen de los costados de la
## caja y no de abajo, ruedas— arma otra (ver docs/technical/base-comun.md). El usuario: «las piernas van a seguir siendo IK».
##
## LOS PASOS SON LA MARCHA COMÚN (Gait, game/common/; 18/11/2026, módulo Jefes, con el aviso a las armas): un ciclo
## continuo, cada pie con su desfase, que pisa adelantado según la velocidad (el apoyo queda centrado debajo de su lugar).
## El usuario: «me gusta pasarlo al sistema para que lo usen todos». *Antes hubo dos reglas propias: los pasos de largo
## fijo (13/11/2026; el que quedó más lejos de su lugar sale, con topes de tiempo, giro y cruce) y la de un tercio de
## paso, con un interruptor en el F4 para compararlas; las dos se borraron en la limpieza del esqueleto (18/11/2026).*
##   · LA PELVIS, una sola pieza, mira al promedio de los dos pies (va atrás del torso al girar, y lo alcanza). Es un
##     cilindro acostado de cadera a cadera, el de la maqueta de la meca jaula (ver `_ready`). *Hasta el 17/11/2026 era
##     un tambor redondo y hueco, por el que pasaba el ascensor de la meca grande (PelvisLift), y la jaula lo cambiaba
##     por el cilindro.*
##   · LAS RODILLAS doblan hacia adelante de la pelvis y del pie, un poco hacia afuera (`knee_out`); agachada, más
##     (`knee_out_crouched`).
##   · LA CAJA SUBE UN POCO A MITAD DE CADA PASO Y SE INCLINA DE COSTADO (`walk_rise`, `walk_lean`); lo demás lo
##     absorben las rodillas.
##   · CAÍDA, SE PLIEGAN (no se achican: las piezas no se estiran) con easing; al empezar a enderezarse, se estiran
##     hacia debajo de las caderas: al quedar derecha ya está parada.
##   · EL PIE, NUNCA MÁS LEJOS DE LO QUE LA PIERNA ALCANZA: en el aire cuelga de la cadera.
##   · CADA PIE TIENE SU LUGAR: debajo de su cadera, pegado a la caja, EN EL PISO DE VERDAD (un rayo; pisa techos y
##     escalones, cada pie a su altura, y las rodillas lo absorben).
##   · GIRAR ES LO MISMO: el lugar gira con la caja, el pie queda lejos y sale; cada lugar está de su lado: no se cruzan.
##   · SE TURNAN: no sale uno mientras el otro está en el aire.
##   · QUIETA, SE ACOMODA: frenada, cada pie da un paso hasta su lugar (la marcha común, sin esperar).

var body: BalanceBody = null
var steps_taken := 0

var _feet: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _feet_yaw: Array[float] = [0.0, 0.0]
## El pie que está en el aire (−1, ninguno).
var _swing := -1
## HACIA DÓNDE APUNTAN LAS PIERNAS (el giro en Y de la pelvis, en el mundo): lo lee quien quiera seguirlas (el módulo de
## arriba de la meca jaula, ver CageMech.upper_heading).
var facing_yaw := 0.0
var _planted := false
var _tuck := 0.0
## LA MARCHA COMÚN (Gait), de dos caderas; y hacia dónde miraba cada pie al salir.
var _gait := Gait.new()
var _lift_yaw: Array[float] = [0.0, 0.0]
## LA CAJA AL CAMINAR (sube con el paso, se inclina de costado; LegSettings, «La caja al caminar»): las señales de la
## marcha (GaitSignals). Las escribe sobre los huesos la tabla del esqueleto (MechSkeleton.setup_layers), con
## `walk_rise` y `walk_lean`. *Hasta el paso 2b del esqueleto (18/11/2026) la tabla vivía acá y movía un nodo sin
## dibujo que sumaba a mano el motor.*
var signals := GaitSignals.new()
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
		if not _planted:
			_gait_setup()
			_gait.place(Transform3D(Basis(Vector3.UP, yaw), body.support))
			_feet = [_gait.feet[0], _gait.feet[1]]
			_feet_yaw = [yaw, yaw]
			_swing = -1
			_planted = true
		_walk(delta, yaw)
	else:
		_planted = false
		_swing = -1
	# LA CAJA AL CAMINAR: las señales (parada, de la marcha; si no, se apagan) y la tabla.
	signals.full_speed = body.kinematic_settings().walk_speed
	if standing and not tucked:
		signals.read(_gait, Basis(Vector3.UP, yaw), body.support_speed, delta)
	else:
		signals.step_progress = 0.0
		signals.plant = 0.0
		signals.horizontal_velocity_smooth = signals.horizontal_velocity_smooth.lerp(Vector2.ZERO, 1.0 - exp(-8.0 * delta))
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
		var ground := _feet[i] if standing else (_feet[i] if folded else body.measures.foot_rest(root, side))
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


## LOS PASOS: la marcha común (Gait) con dos caderas; acá sólo el giro de cada pie, que va de
## hacia donde miraba al salir a hacia donde mira la caja.
func _walk(delta: float, yaw: float) -> void:
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


## LO QUE HACE LA CAJA CON LOS PASOS (lo escribe la tabla del esqueleto): sube a mitad de cada paso y se hunde al pisar
## (m), y se inclina de costado según la velocidad de costado (rad).
func walk_rise() -> float:
	var s := LegSettings.current
	return (signals.step_progress * s.bob - signals.plant * s.stomp_dip) * _stride()


func walk_lean() -> float:
	var side := clampf(signals.horizontal_velocity_smooth.x / maxf(signals.full_speed, 0.01), -1.0, 1.0)
	return side * deg_to_rad(LegSettings.current.side_lean)


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


## DÓNDE ESTÁN LOS PIES (mundo), como se dibujaron en el último paso: los siguen los pies con choque (StompFeet).
func foot_transforms() -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for leg in _legs:
		out.append(leg.foot())
	return out
