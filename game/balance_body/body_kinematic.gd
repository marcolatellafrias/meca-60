class_name BodyKinematic
extends RefCounted

## LA MECA CINEMÁTICA: EL MISMO CUERPO, MOVIDO A MANO (13/11/2026; ver BalanceBody `kinematic`). El usuario: «lo único
## que cambia es que se mueve de forma cinemática… así puedo hacer dashes, otras cosas con más libertad, sin hacer
## fuerzas enormes que puedan buguear el mapa». Todo lo demás —los brazos, la cabina, las piernas, las escaleras, las
## toberas, caminar, saltar, el dash— es lo de siempre: le piden lo mismo y le empujan igual, por `push_force` y
## `push_impulse` del cuerpo, que acá llegan a `velocity` en vez de a Jolt.
##
## CINEMÁTICA NO ES SIN FÍSICA: LA ESCRIBE ESTA PIEZA. Jolt no la mueve (la caja está congelada, cinemática); cada paso
## calcula dónde va y la pone ahí.
##   · EL MISMO PÉNDULO (ver BalanceBody): el torso tiene su velocidad; el PUNTO DE APOYO lo sigue con las mismas reglas y
##     perillas (frenar al instante, alcanzarlo con tope); LA INCLINACIÓN es lo que el torso se le adelantó, sobre el
##     largo del palo: la gravedad la vuelca y un músculo chico la endereza. Pasada `fall_tilt`, SE CAE.
##   · CAERSE ES ESCRITO: vuelca alrededor del apoyo hasta quedar acostada, espera y se levanta por el mismo camino (las
##     toberas se ven prendidas). La caída física rodaba contra el piso; acá no hay piso que la haga rodar.
##   · LO FIJO LA FRENA: todo movimiento se prueba antes, también subir y bajar; contra algo fijo se desliza y pierde la
##     velocidad que iba contra eso. LO SUELTO NO LA FRENA: lo empuja (*sin regla todavía: a una pila de cubos la
##     despedía a 14 m/s, medido en la maqueta*).
##   · EL GIRO tiene tope de velocidad y de aceleración, y SI ALGO FIJO LO TRABA, NO GIRA: la caja girada se prueba antes.
##     *En la maqueta, girando pegada a una pared se le metían las esquinas y al salir saltaba 2 m de un paso.*
##   · UN BORDE: si el piso baja más de `STEP_DOWN` de un paso al otro, queda en el aire y cae. *Con el rayo largo,
##     pasando el borde de una pared, bajaba 16 m de golpe.*
## Los de adentro van en su marco (MotionFrame), como en la meca física.

## El giro: aceleración tope (grados por segundo al cuadrado).
const TURN_ACCEL := 140.0
## La caída escrita: cuánto queda acostada y cuánto tarda en levantarse (s).
const LIE_TIME := 1.0
const RISE_TIME := 1.6
## Parada, lo más que baja el piso de un paso al otro sin quedar en el aire (m).
const STEP_DOWN := 2.0

## La velocidad del torso (m/s, mundo) y lo que la empuja en este paso (N).
var velocity := Vector3.ZERO
var force := Vector3.ZERO

var _body: BalanceBody = null
var _yaw := 0.0
var _yaw_speed := 0.0
var _fall_way := Vector3.FORWARD
var _fall_angle := 0.0
var _fall_speed := 0.0
var _clock := 0.0
var _box := BoxShape3D.new()


func _init(body: BalanceBody) -> void:
	_body = body
	_yaw = body.global_rotation.y
	_box.size = body.size - Vector3.ONE * 0.1


## UN PASO (ver arriba): lo que se le pide, el péndulo o la caída, y la pone donde calculó.
func step(k: BodySettings, delta: float) -> void:
	var centre := _body.global_position
	match _body.state:
		BalanceBody.State.STANDING:
			_body.moves.step(k, delta)
			if not _body.grounded and not _body.airborne:
				var under: Variant = _floor_at(centre, _body.rod(k) + _body.size.y * 0.5)
				if under == null:
					_body.take_off()
				else:
					_body.support = under
					_body.support_speed = Vector3.ZERO
					_body.grounded = true
			_body.moves.drive(k, delta)
			_body.nozzles.fire(k)
			velocity += force / _body.mass * delta
			if _body.airborne:
				centre = _in_air(k, delta, centre)
			else:
				centre = _standing(k, delta, centre)
			_turn(k, delta, centre)
		_:
			_body.nozzles.fire(k)
			centre = _fallen(k, delta)
	force = Vector3.ZERO
	_place(centre)


## PARADA: el péndulo (ver arriba).
func _standing(k: BodySettings, delta: float, centre: Vector3) -> Vector3:
	var length := _body.rod(k)
	var off := Vector3(centre.x - _body.support.x, 0.0, centre.z - _body.support.z)
	var relative := Vector3(velocity.x, 0.0, velocity.z) - _body.support_speed
	var push := off / length * BalanceBody.gravity() - off * k.upright_kp - relative * k.upright_kd
	velocity.x += push.x * delta
	velocity.z += push.z * delta
	# EL APOYO SIGUE AL TORSO: quiere su velocidad y ponerse debajo; frena al instante, alcanza con tope.
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var wanted := (flat + off * k.feet_catch).limit_length(k.feet_speed)
	if _body.support_speed.length_squared() > 0.0001:
		var heading := _body.support_speed.normalized()
		var needed := maxf(wanted.dot(heading), 0.0)
		if _body.support_speed.length() > needed:
			_body.support_speed = heading * needed
	var gap := (wanted - _body.support_speed).length()
	_body.support_speed = _body.support_speed.move_toward(wanted, minf(k.feet_accel, gap * k.feet_react) * delta)
	_body.support += _body.support_speed * delta
	var floor_y: Variant = _floor_at(_body.support, STEP_DOWN)
	if floor_y == null:
		_body.take_off()
		return centre
	_body.support.y = (floor_y as Vector3).y
	# EL TORSO, con su velocidad de costado (probando); su altura, la del palo.
	centre = _slide(centre, flat * delta)
	off = Vector3(centre.x - _body.support.x, 0.0, centre.z - _body.support.z)
	if off.length() > length * 0.95:
		off = off.normalized() * length * 0.95
	centre.y = _body.support.y + sqrt(length * length - off.length_squared())
	velocity.y = 0.0
	_body.tilt = rad_to_deg(asin(clampf(off.length() / length, 0.0, 1.0)))
	_body.height = centre.y - _body.support.y - _body.size.y * 0.5
	if _body.tilt > k.fall_tilt:
		_fall(k, off)
	return centre


## EN EL AIRE: derecha, con la gravedad del aire (BodyMoves.gravity_share); aterriza cuando la punta del palo toca el
## piso bajando, con la velocidad que trae.
func _in_air(k: BodySettings, delta: float, centre: Vector3) -> Vector3:
	velocity.y -= BalanceBody.gravity() * _body.moves.gravity_share(k) * delta
	centre = _slide(centre, velocity * delta)
	_body.tilt = move_toward(_body.tilt, 0.0, 60.0 * delta)
	var floor_y: Variant = _floor_at(centre, 400.0)
	if floor_y == null:
		return centre
	_body.support = floor_y
	_body.height = centre.y - _body.support.y - _body.size.y * 0.5
	if centre.y - _body.rod(k) <= _body.support.y and velocity.y <= 0.0:
		_body.airborne = false
		_body.grounded = true
		centre.y = _body.support.y + _body.rod(k)
		velocity.y = 0.0
		_body.support_speed = Vector3(velocity.x, 0.0, velocity.z)
		_body.legs.replant()
	return centre


## EL GIRO: hacia `aim_yaw`, con tope de velocidad y de aceleración; si algo fijo lo traba, no gira.
func _turn(k: BodySettings, delta: float, centre: Vector3) -> void:
	var error := clampf(wrapf(_body.aim_yaw - _yaw, -PI, PI), -BalanceBody.AIM_LEAD, BalanceBody.AIM_LEAD)
	_body.aim_yaw = _yaw + error
	var top := deg_to_rad(k.turn_speed)
	var wanted := clampf(error * k.yaw_grip, -top, top)
	_yaw_speed = move_toward(_yaw_speed, wanted, deg_to_rad(TURN_ACCEL) * delta)
	var next := _yaw + _yaw_speed * delta
	if _blocked(Transform3D(Basis(Vector3.UP, next), centre)):
		_yaw_speed = 0.0
		return
	_yaw = next


## SE CAE: vuelca alrededor del apoyo hacia donde se inclinaba.
func _fall(k: BodySettings, off: Vector3) -> void:
	_body.state = BalanceBody.State.DOWN
	_body.falls += 1
	_body.grounded = false
	_fall_way = off.normalized() if off.length_squared() > 0.0001 else -Basis(Vector3.UP, _yaw).z
	_fall_angle = deg_to_rad(_body.tilt)
	_fall_speed = Vector3(velocity.x, 0.0, velocity.z).dot(_fall_way) / _body.rod(k)
	_clock = 0.0
	velocity = Vector3.ZERO
	_body.support_speed = Vector3.ZERO


## CAÍDA ESCRITA (ver arriba): DOWN mientras vuelca y queda acostada; LIFT y RIGHT mientras se levanta (las piernas y
## las toberas las leen como siempre).
func _fallen(k: BodySettings, delta: float) -> Vector3:
	var length := _body.rod(k)
	var lying := acos(clampf(_body.size.z * 0.5 / length, 0.0, 1.0))
	_clock += delta
	if _body.state == BalanceBody.State.DOWN:
		if _fall_angle < lying:
			_fall_speed += BalanceBody.gravity() / length * sin(_fall_angle) * delta
			_fall_angle = minf(_fall_angle + _fall_speed * delta, lying)
			_clock = 0.0
		elif _clock > LIE_TIME:
			_body.state = BalanceBody.State.LIFT
			_clock = 0.0
	else:
		_body.nozzles.get_up(k)
		var share := clampf(_clock / RISE_TIME, 0.0, 1.0)
		_fall_angle = lerpf(lying, 0.0, smoothstep(0.0, 1.0, share))
		if rad_to_deg(_fall_angle) <= BalanceBody.LAST_STRETCH:
			_body.state = BalanceBody.State.RIGHT
		if share >= 1.0:
			_fall_angle = 0.0
			_body.state = BalanceBody.State.STANDING
			_body.grounded = false
			_body.aim_yaw = _yaw
	_body.tilt = rad_to_deg(_fall_angle)
	var centre := _body.support + _fall_way * sin(_fall_angle) * length + Vector3.UP * cos(_fall_angle) * length
	_body.height = _body.ground_distance(centre)
	return centre


## LA PONE DONDE CALCULÓ: girada, e inclinada hacia el torso desde el apoyo (o hacia donde cae).
func _place(centre: Vector3) -> void:
	var lean := Basis()
	var way := _fall_way if _body.state != BalanceBody.State.STANDING \
		else Vector3(centre.x - _body.support.x, 0.0, centre.z - _body.support.z)
	if not _body.airborne and way.length_squared() > 0.0001 and _body.tilt > 0.01:
		lean = Basis(Vector3.UP.cross(way.normalized()).normalized(), deg_to_rad(_body.tilt))
	_body.global_transform = Transform3D(lean * Basis(Vector3.UP, _yaw), centre)


## ── EL MUNDO ─────────────────────────────────────────────────────────────────────────────────────────────────────

## MOVERSE PROBANDO: `motion` desde `from`; contra algo fijo se desliza y pierde la velocidad que iba contra eso; lo que
## se mueve se saltea (lo empuja el motor).
func _slide(from: Vector3, motion: Vector3) -> Vector3:
	if motion.length_squared() < 0.0000001:
		return from
	var params := PhysicsTestMotionParameters3D.new()
	params.from = Transform3D(_body.global_basis, from)
	params.motion = motion
	params.margin = 0.02
	var skip: Array[RID] = []
	for attempt in 8:
		params.exclude_bodies = skip
		var result := PhysicsTestMotionResult3D.new()
		if not PhysicsServer3D.body_test_motion(_body.get_rid(), params, result):
			return params.from.origin + params.motion
		var other := result.get_collider()
		if BodyKinematic.fixed(other):
			var normal := result.get_collision_normal()
			var into := velocity.dot(normal)
			if into < 0.0:
				velocity -= normal * into
			var done := result.get_travel()
			params.from.origin += done
			params.motion = (params.motion - done).slide(normal)
			if params.motion.length_squared() < 0.0000001:
				return params.from.origin
		else:
			skip.append(result.get_collider_rid())
	return params.from.origin


## Si la caja, puesta en `where`, se mete en algo fijo.
func _blocked(where: Transform3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _box
	query.transform = where
	query.collision_mask = 1
	query.exclude = [_body.get_rid()]
	for hit: Dictionary in _body.get_world_3d().direct_space_state.intersect_shape(query, 16):
		if BodyKinematic.fixed(hit["collider"]):
			return true
	return false


## EL PISO debajo de `point`, a lo más `reach` para abajo (lo fijo; lo que se mueve no es piso), o null.
func _floor_at(point: Vector3, reach: float) -> Variant:
	var hit := _body.ray(point + Vector3.UP * 2.0, point + Vector3.DOWN * reach)
	return null if hit.is_empty() else hit["position"]


## LO FIJO: lo estático que no se mueve (una pared, un edificio, el piso).
static func fixed(other: Object) -> bool:
	return other is StaticBody3D and not other is AnimatableBody3D
