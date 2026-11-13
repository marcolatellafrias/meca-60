class_name KinematicMech
extends AnimatableBody3D

## LA MECA CINEMÁTICA (13/11/2026) — MAQUETA: la tercera alternativa, ni física ni mixta. El usuario: «la totalmente
## cinemática… así puedo hacer dashes, otras cosas con más libertad, sin hacer fuerzas enormes que puedan buguear el
## mapa». Lo que se prueba acá son sus riesgos: los de adentro, los choques y lo que empuja afuera.
##
## CINEMÁTICA NO ES SIN FÍSICA: LA FÍSICA LA ESCRIBE ELLA. Jolt no la mueve; cada paso calcula dónde va y se pone ahí
## (un AnimatableBody: el motor sabe su velocidad, así lleva a lo que tiene encima y empuja lo suelto).
##   · EL MISMO PÉNDULO DE LA META FÍSICA (ver BalanceBody), escrito a mano: el TORSO tiene su velocidad; el PUNTO DE
##     APOYO lo sigue con las mismas reglas (frenar es instantáneo, alcanzarlo tiene tope); LA INCLINACIÓN es lo que el
##     torso se adelantó a su apoyo, sobre el largo del palo. Pasada `fall_tilt`, SE CAE (una caída escrita: vuelca
##     alrededor del apoyo hasta quedar acostada) y se levanta.
##   · UN GOLPE es un cambio de velocidad del torso (`push`): los pies salen a alcanzarlo, como en la física.
##   · LAS PAREDES LA FRENAN: antes de moverse, se prueba el movimiento; contra algo fijo, se desliza y pierde la parte de
##     la velocidad que iba contra la pared. LO SUELTO NO LA FRENA: lo empuja.
##   · EL GIRO tiene tope de velocidad Y DE ACELERACIÓN (`TURN_ACCEL`): girar de golpe tiraría lo que tiene encima.
##   · SALTO, PROPULSOR Y DASH: velocidades que pone ella, con la gravedad del aire de las perillas (las mismas que la
##     meca física: BodySettings).
##   · LOS DE ADENTRO van en su MotionFrame, como en la meca de siempre: el marco les suma lo que cambia la velocidad de
##     la caja en su punto. Es lo que más hay que mirar.
## Perillas: las de la meca (BodySettings.current), salvo lo de abajo.

enum State { STANDING, DOWN, RISE }

## La caja (m) y el casco: el alto de las paredes de adentro y su grosor.
const SIZE := Vector3(12.0, 9.0, 12.0)
const WALL_HEIGHT := 3.2
const WALL := 0.4
## El giro: aceleración tope (grados por segundo al cuadrado).
const TURN_ACCEL := 140.0
## La caída escrita: cuánto tarda en quedar acostada, cuánto queda (s) y cuánto tarda en levantarse.
const LIE_TIME := 1.0
const RISE_TIME := 1.4
## Los pies del dibujo: separados a cada lado.
const STANCE := 3.0
## Parada, lo más que baja el piso de un paso al otro sin que quede en el aire (m).
const STEP_DOWN := 2.0
## Un cambio de velocidad más chico que esto no es un golpe (m/s), para mirar.
const HIT_NOISE := 0.3

## ── LO QUE SE LE PIDE (como la meca física) ──
var move := Vector2.ZERO
var sprint := false
var crouch := false
var jump := false
var dash := false
var aim_yaw := 0.0

## ── LO QUE MIDE ──
var state := State.STANDING
var airborne := false
var tilt := 0.0
var falls := 0
var last_hit := 0.0
var fuel := 1.0
var jump_charge := 0.0

var frame: MotionFrame = null
var interior: StaticBody3D = null

## El torso (su centro) y su velocidad; el apoyo y la suya; hacia dónde mira y lo que gira.
var _centre := Vector3.ZERO
var _velocity := Vector3.ZERO
var _support := Vector3.ZERO
var _support_speed := Vector3.ZERO
var _yaw := 0.0
var _yaw_speed := 0.0
var _rod_scale := 1.0
var _jump_was := false
var _dash_was := true
var _thrust_armed := false
var _dashes := 1
var _fall_way := Vector3.FORWARD
var _fall_angle := 0.0
var _fall_speed := 0.0
var _clock := 0.0
var _riders := {}
## Lo suelto que lleva (ver `carry`).
var _carried: Array[RigidBody3D] = []
var _driving := false
var _chase_yaw := 0.0
## La rutina de la K (ver `routine`): pasos `[segundos, move, sprint, jump, dash, giro]`.
var _routine: Array = []
var _routine_clock := 0.0
var _feet: Array[Vector3] = []
var _swing := -1
var _swing_from := Vector3.ZERO
var _swing_clock := 0.0
var _legs: Array[MechLeg] = []


func _init() -> void:
	sync_to_physics = true


func _ready() -> void:
	Clay.shape_box(self, SIZE, Vector3.ZERO)
	_build_hull()
	_centre = global_position
	_yaw = global_rotation.y
	aim_yaw = _yaw
	_support = Vector3(_centre.x, _centre.y - _rod(), _centre.z)
	for side: float in [-1.0, 1.0]:
		_feet.append(_support + Basis(Vector3.UP, _yaw) * Vector3(side * STANCE, 0.0, 0.0))
		var leg := MechLeg.new()
		add_child(leg)
		_legs.append(leg)
	frame = MotionFrame.new()
	add_child(frame)
	frame.floor_height = -SIZE.y * 0.5 + WALL
	frame.add_volume(AABB(-SIZE * 0.5, SIZE + Vector3(0.0, WALL_HEIGHT, 0.0)))
	# La sombra copia SÓLO lo de adentro: con la caja entera, los de adentro quedaban metidos en una caja maciza y
	# salían despedidos (medido el 13/11/2026: los cubos, a 127 m/s).
	interior.collision_layer = 1
	frame.cast_shadow(interior)
	interior.collision_layer = 0
	interior.collision_mask = 0
	add_to_group(SandboxPossession.GROUP)


## EL CASCO: una caja abierta arriba —el piso, paredes bajas, una puerta atrás—, para ver lo de adentro desde afuera.
## Lo que choca adentro es `interior` (lo copia la sombra del marco); afuera, la caja entera.
func _build_hull() -> void:
	interior = StaticBody3D.new()
	interior.name = "Adentro"
	add_child(interior)
	var bottom := -SIZE.y * 0.5
	var hull := Clay.METAL.darkened(0.05)
	_solid(Vector3(SIZE.x, WALL, SIZE.z), Vector3(0.0, bottom + WALL * 0.5, 0.0), hull.darkened(0.2))
	# La caja que choca afuera, de vidrio: se ve lo de adentro.
	Clay.box(self, Vector3(SIZE.x, SIZE.y - WALL, SIZE.z) * 0.99, Vector3(0.0, WALL * 0.5, 0.0), Clay.GLASS)
	var top := bottom + WALL + WALL_HEIGHT * 0.5
	for x: float in [-1.0, 1.0]:
		_solid(Vector3(WALL, WALL_HEIGHT, SIZE.z), Vector3(x * (SIZE.x - WALL) * 0.5, top, 0.0), hull.lightened(0.1))
	_solid(Vector3(SIZE.x, WALL_HEIGHT, WALL), Vector3(0.0, top, -(SIZE.z - WALL) * 0.5), hull.lightened(0.1))
	# Atrás, con puerta.
	var side := (SIZE.x - 3.0) * 0.5
	for x: float in [-1.0, 1.0]:
		_solid(Vector3(side, WALL_HEIGHT, WALL), Vector3(x * (SIZE.x - side) * 0.5, top, (SIZE.z - WALL) * 0.5), hull.lightened(0.1))
	# El frente, para saber hacia dónde mira.
	Clay.box(self, Vector3(SIZE.x * 0.6, 0.6, 0.3), Vector3(0.0, top, -SIZE.z * 0.5 - 0.2), Clay.YELLOW)


func _solid(size: Vector3, at: Vector3, color: Color) -> void:
	Clay.box(self, size, at, color)
	Clay.shape_box(interior, size, at)


## Lo que va del centro de la caja a su apoyo, parada (m).
func _rod() -> float:
	return (SIZE.y * 0.5 + BodySettings.current.hover_height) * _rod_scale


## ── CADA PASO ────────────────────────────────────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	var k := BodySettings.current
	_read(delta)
	var before := _velocity
	match state:
		State.STANDING:
			_moves(k, delta)
			if airborne:
				_in_air(k, delta)
			else:
				_standing(k, delta)
			_turn(delta)
		State.DOWN, State.RISE:
			_fallen(k, delta)
	var change := Vector3(_velocity.x - before.x, 0.0, _velocity.z - before.z)
	if change.length() > HIT_NOISE and state == State.STANDING and not airborne:
		last_hit = change.length()
	_place()
	_step_feet(k, delta)
	_ride()


## AGACHARSE, EL SALTO, EL PROPULSOR Y EL DASH (como BodyMoves).
func _moves(k: BodySettings, delta: float) -> void:
	if airborne:
		jump_charge = 0.0
		if not jump:
			_thrust_armed = true
		if jump and _thrust_armed and fuel > 0.0:
			fuel = maxf(fuel - delta / k.thrust_time, 0.0)
			_velocity.y += (k.thrust - BalanceBody.gravity()) * delta
		else:
			var falling := _velocity.y < 0.0
			_velocity.y -= BalanceBody.gravity() * k.air_gravity * (k.fall_extra if falling else 1.0) * delta
		if dash and not _dash_was and _dashes > 0 and fuel >= k.dash_cost:
			_dash(k)
	else:
		_dashes = k.dash_count
		_thrust_armed = false
		fuel = minf(fuel + delta / k.thrust_refill, 1.0)
		if jump and not crouch:
			jump_charge = minf(jump_charge + delta / k.jump_charge_time, 1.0)
		elif _jump_was and jump_charge > 0.0:
			var rise := lerpf(k.jump_least, 1.0, jump_charge) * k.jump_height
			_velocity.y = sqrt(2.0 * BalanceBody.gravity() * k.air_gravity * rise)
			jump_charge = 0.0
			airborne = true
		else:
			jump_charge = 0.0
	_jump_was = jump
	_dash_was = dash
	var low := k.crouch_rod if crouch and not airborne else 1.0
	_rod_scale = move_toward(_rod_scale, minf(low, lerpf(1.0, k.jump_squat, jump_charge)), k.rod_rate * delta)
	# CAMINAR: el torso hacia la velocidad pedida, con tope (en el aire, casi nada).
	var walk := k.walk_speed * (k.crouch_speed if crouch and not airborne else 1.0)
	var stick := Vector3(move.x, 0.0, -move.y)
	var sprinting := sprint and stick.z < 0.0 and not crouch
	var wanted := Basis(Vector3.UP, _yaw) * stick.limit_length(1.0) * walk * (k.sprint_multiplier if sprinting else 1.0)
	var flat := Vector3(_velocity.x, 0.0, _velocity.z)
	var most := k.walk_accel if wanted.length_squared() > 0.0001 else k.walk_brake
	if flat.length() > walk:
		most *= k.sprint_accel
	if airborne:
		most = k.air_accel
	var add := ((wanted - flat) / maxf(delta, 0.0001)).limit_length(most) * delta
	_velocity.x += add.x
	_velocity.z += add.z


func _dash(k: BodySettings) -> void:
	var stick := Vector3(move.x, 0.0, -move.y)
	if stick.length_squared() < 0.01:
		stick = Vector3.FORWARD
	var way := (Basis(Vector3.UP, _yaw) * stick).normalized()
	var flat := Vector3(_velocity.x, 0.0, _velocity.z)
	var keep := way * maxf(flat.dot(way), 0.0) + way * k.dash_speed
	_velocity = Vector3(keep.x, maxf(_velocity.y, k.dash_lift), keep.z)
	fuel = maxf(fuel - k.dash_cost, 0.0)
	_dashes -= 1


## PARADA: el péndulo (ver arriba). El apoyo sigue al torso; la gravedad vuelca lo que se adelantó, un músculo chico lo
## endereza; la altura sale del palo.
func _standing(k: BodySettings, delta: float) -> void:
	var length := _rod()
	var off := Vector3(_centre.x - _support.x, 0.0, _centre.z - _support.z)
	# La gravedad vuelca hacia donde se inclina; el músculo lo quiere derecho.
	var lean := off / length
	var relative := Vector3(_velocity.x, 0.0, _velocity.z) - _support_speed
	var push := lean * BalanceBody.gravity() - off * k.upright_kp - relative * k.upright_kd
	_velocity.x += push.x * delta
	_velocity.z += push.z * delta
	# EL APOYO SIGUE AL TORSO: quiere su velocidad y ponerse debajo; frena al instante, alcanza con tope.
	var flat := Vector3(_velocity.x, 0.0, _velocity.z)
	var wanted := (flat + off * k.feet_catch).limit_length(k.feet_speed)
	if _support_speed.length_squared() > 0.0001:
		var heading := _support_speed.normalized()
		var needed := maxf(wanted.dot(heading), 0.0)
		if _support_speed.length() > needed:
			_support_speed = heading * needed
	var gap := (wanted - _support_speed).length()
	_support_speed = _support_speed.move_toward(wanted, minf(k.feet_accel, gap * k.feet_react) * delta)
	_support += _support_speed * delta
	# SIN PISO CERCA BAJO EL APOYO (un borde: más de `STEP_DOWN` para abajo), queda en el aire y cae. *Con el rayo
	# largo, al pasar el borde de arriba de una pared bajaba 16 m de golpe (medido el 13/11/2026).*
	var floor_y: Variant = _floor_at(_support, STEP_DOWN)
	if floor_y == null:
		airborne = true
		_support_speed = Vector3.ZERO
		return
	_support.y = float(floor_y)
	# EL TORSO se mueve con su velocidad de costado (probando paredes); su altura, la del palo.
	_centre = _slide(_centre, flat * delta)
	off = Vector3(_centre.x - _support.x, 0.0, _centre.z - _support.z)
	if off.length() > length * 0.95:
		off = off.normalized() * length * 0.95
	_centre.y = _support.y + sqrt(length * length - off.length_squared())
	_velocity.y = 0.0
	tilt = rad_to_deg(asin(clampf(off.length() / length, 0.0, 1.0)))
	if tilt > k.fall_tilt:
		_fall(off)


## EN EL AIRE: derecha y sin apoyo; aterriza cuando la punta del palo toca el piso bajando, con la velocidad que trae.
func _in_air(_k: BodySettings, delta: float) -> void:
	# Todo el movimiento se prueba, también el de subir y bajar: si no, saltando por arriba de una pared baja, al bajar
	# se metía adentro (medido el 13/11/2026) y de ahí en más la atravesaba.
	_centre = _slide(_centre, _velocity * delta)
	var flat := Vector3(_velocity.x, 0.0, _velocity.z)
	tilt = move_toward(tilt, 0.0, 60.0 * delta)
	var floor_y: Variant = _floor_at(_centre, _rod() + SIZE.y + 400.0)
	_support = Vector3(_centre.x, float(floor_y) if floor_y != null else _centre.y - 400.0, _centre.z)
	if floor_y != null and _centre.y - _rod() <= float(floor_y) and _velocity.y <= 0.0:
		airborne = false
		_centre.y = float(floor_y) + _rod()
		_velocity.y = 0.0
		_support_speed = flat


## EL GIRO: hacia `aim_yaw` con tope de velocidad y de aceleración. SI ALGO FIJO LO TRABA, NO GIRA (como la meca
## física): la caja girada se prueba antes. *Sin eso, girando pegada a una pared las esquinas se le metían adentro, al
## salir saltaba 2 m en un paso y los de adentro salían despedidos (medido el 13/11/2026).*
func _turn(delta: float) -> void:
	var k := BodySettings.current
	var error := wrapf(aim_yaw - _yaw, -PI, PI)
	var top := deg_to_rad(k.turn_speed)
	var wanted := clampf(error * k.yaw_grip, -top, top)
	_yaw_speed = move_toward(_yaw_speed, wanted, deg_to_rad(TURN_ACCEL) * delta)
	var next := _yaw + _yaw_speed * delta
	if _blocked(Transform3D(Basis(Vector3.UP, next), _centre)):
		_yaw_speed = 0.0
		aim_yaw = _yaw
		return
	_yaw = next


## Si la caja, puesta en `where`, se mete en algo fijo.
func _blocked(where: Transform3D) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = SIZE - Vector3.ONE * 0.1
	query.shape = box
	query.transform = where
	query.collision_mask = 1
	query.exclude = [get_rid()]
	for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query, 16):
		var other: Object = hit["collider"]
		if other is StaticBody3D and not other is AnimatableBody3D:
			return true
	return false


## SE CAE: vuelca alrededor del apoyo hacia donde se inclinaba.
func _fall(off: Vector3) -> void:
	state = State.DOWN
	falls += 1
	_fall_way = off.normalized() if off.length_squared() > 0.0001 else -Basis(Vector3.UP, _yaw).z
	_fall_angle = deg_to_rad(tilt)
	_fall_speed = Vector3(_velocity.x, 0.0, _velocity.z).dot(_fall_way) / _rod()
	_clock = 0.0
	_velocity = Vector3.ZERO
	_support_speed = Vector3.ZERO


## CAÍDA ESCRITA: vuelca como un palo (más rápido cuanto más inclinada) hasta quedar acostada; espera; se levanta
## por el mismo camino, de a poco.
func _fallen(_k: BodySettings, delta: float) -> void:
	var length := _rod()
	var lying := acos(clampf(SIZE.z * 0.5 / length, 0.0, 1.0))
	_clock += delta
	if state == State.DOWN:
		if _fall_angle < lying:
			_fall_speed += BalanceBody.gravity() / length * sin(_fall_angle) * delta
			_fall_angle = minf(_fall_angle + _fall_speed * delta, lying)
			_clock = 0.0
		elif _clock > LIE_TIME:
			state = State.RISE
			_clock = 0.0
	else:
		_fall_angle = lerpf(lying, 0.0, smoothstep(0.0, 1.0, _clock / RISE_TIME))
		if _clock >= RISE_TIME:
			state = State.STANDING
			_fall_angle = 0.0
	_centre = _support + _fall_way * sin(_fall_angle) * length + Vector3.UP * cos(_fall_angle) * length
	tilt = rad_to_deg(_fall_angle)


## SE PONE DONDE CALCULÓ: el giro y la inclinación (hacia el torso desde el apoyo).
func _place() -> void:
	var lean := Basis()
	var off := Vector3(_centre.x - _support.x, 0.0, _centre.z - _support.z)
	if not airborne and off.length_squared() > 0.0001 and tilt > 0.01:
		lean = Basis(Vector3.UP.cross(off.normalized()).normalized(), deg_to_rad(tilt))
	global_transform = Transform3D(lean * Basis(Vector3.UP, _yaw), _centre)


## LLEVA ADENTRO a `body`: entra a su marco y siente `felt` de la inercia (0: nada, como la gente; 1: toda, como algo
## suelto; ver MotionFrame).
func carry(body: RigidBody3D, felt: float) -> void:
	frame.join(body, felt)
	_carried.append(body)


## UN GOLPE: un cambio de velocidad del torso (m/s, mundo).
func push(change: Vector3) -> void:
	if state != State.STANDING:
		return
	_velocity += Vector3(change.x, change.y if airborne else 0.0, change.z)


## UN GOLPE DE COSTADO, suave o fuerte (las teclas N y M), con las perillas de la meca.
func knock(strong: bool) -> void:
	var side := Basis(Vector3.UP, _yaw).x
	push(side * (BodySettings.current.knock_strong if strong else BodySettings.current.knock_soft))


## ── EL MUNDO ─────────────────────────────────────────────────────────────────────────────────────────────────────

## MOVERSE PROBANDO: `motion` desde `from`; contra algo fijo (una pared, el techo, el borde de arriba de una pared), se
## desliza y pierde la velocidad que iba contra eso. Lo
## que se mueve (lo suelto, la gente) no la frena: se saltea, y el motor lo empuja al moverla.
func _slide(from: Vector3, motion: Vector3) -> Vector3:
	if motion.length_squared() < 0.0000001:
		return from
	var params := PhysicsTestMotionParameters3D.new()
	params.from = Transform3D(global_basis, from)
	params.motion = motion
	params.margin = 0.02
	var skip: Array[RID] = []
	for rider: Variant in _riders.keys():
		if is_instance_valid(rider):
			skip.append((rider as CollisionObject3D).get_rid())
	for attempt in 8:
		params.exclude_bodies = skip
		var result := PhysicsTestMotionResult3D.new()
		if not PhysicsServer3D.body_test_motion(get_rid(), params, result):
			return from + params.motion
		var other := result.get_collider()
		if other is StaticBody3D and not other is AnimatableBody3D:
			var normal := result.get_collision_normal()
			var into := _velocity.dot(normal)
			if into < 0.0:
				_velocity -= normal * into
			var done := result.get_travel()
			params.from.origin += done
			params.motion = (params.motion - done).slide(normal)
			from = params.from.origin
			if params.motion.length_squared() < 0.0000001:
				return from
		else:
			skip.append(result.get_collider_rid())
	return from


## EL PISO debajo de `point`, a lo más `reach` para abajo (lo fijo; lo que se mueve no es piso).
func _floor_at(point: Vector3, reach: float) -> Variant:
	var query := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 2.0, point + Vector3.DOWN * reach)
	query.collision_mask = 1
	var skip: Array[RID] = [get_rid()]
	for attempt in 8:
		query.exclude = skip
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty():
			return null
		if hit["collider"] is StaticBody3D and not hit["collider"] is AnimatableBody3D:
			return (hit["position"] as Vector3).y
		skip.append(hit["rid"])
	return null


## LA CAJA NO CHOCA CON LOS QUE VAN ADENTRO (ver MechCabin.ride). Y LO SUELTO QUE SALIÓ (un cubo despedido) deja el
## marco: la gente lo decide sola (ver MotionFrame.around); lo suelto, acá.
func _ride() -> void:
	for body: RigidBody3D in _carried.duplicate():
		if not is_instance_valid(body):
			_carried.erase(body)
		elif not frame.contains(body.global_position, MotionFrame.MARGIN):
			frame.leave(body)
			_carried.erase(body)
	var inside := {}
	for body: Variant in frame._members.keys():
		if is_instance_valid(body) and body is PhysicsBody3D:
			inside[body] = true
			if not _riders.has(body):
				add_collision_exception_with(body as PhysicsBody3D)
	for body: Variant in _riders.keys():
		if not inside.has(body) and is_instance_valid(body):
			remove_collision_exception_with(body as PhysicsBody3D)
	_riders = inside


## ── LAS PIERNAS (dibujo, para ver dónde está el apoyo): dos pies que se turnan para quedar a los costados ──────────

func _step_feet(k: BodySettings, delta: float) -> void:
	var turn := Basis(Vector3.UP, _yaw)
	var standing := state == State.STANDING and not airborne
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var home := _support + turn * Vector3(side * STANCE, 0.0, 0.0) + _support_speed * 0.25
		if not standing:
			home = _centre + turn * Vector3(side * STANCE, -_rod() + 1.0, 0.0)
			_feet[i] = home
		elif _swing < 0 and Vector2(home.x - _feet[i].x, home.z - _feet[i].z).length() > k.settle_gap:
			_swing = i
			_swing_from = _feet[i]
			_swing_clock = 0.0
	if _swing >= 0 and standing:
		var side := -1.0 if _swing == 0 else 1.0
		var home := _support + turn * Vector3(side * STANCE, 0.0, 0.0) + _support_speed * 0.25
		_swing_clock += delta
		var time := clampf(2.0 * k.step_reach / maxf(_support_speed.length(), 0.1), k.step_fastest, k.step_slowest)
		var share := clampf(_swing_clock / time, 0.0, 1.0)
		_feet[_swing] = _swing_from.lerp(home, smoothstep(0.0, 1.0, share)) + Vector3.UP * sin(share * PI) * k.step_height
		if share >= 1.0:
			_feet[_swing].y = home.y
			_swing = -1
	var waist := global_transform * Transform3D(Basis(), Vector3(0.0, -SIZE.y * 0.5, 0.0))
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var hip := waist * Vector3(side * STANCE * 0.8, -0.6, 0.0)
		var ground := _feet[i]
		var reach := MechBody.THIGH + MechBody.SHIN - 0.3
		if (ground + Vector3.UP * MechBody.ANKLE - hip).length() > reach:
			ground = hip + (ground + Vector3.UP * MechBody.ANKLE - hip).normalized() * reach - Vector3.UP * MechBody.ANKLE
		_legs[i].pose(MechBody.leg(hip, ground, turn, -turn.z + turn.x * side * 0.2))


## ── LA RUTINA (la K): para mirarla parado adentro ────────────────────────────────────────────────────────────────

## Camina, salta cargado, dash de costado en lo alto, aterriza, se corre un poco, da media vuelta rápida, corre y frena.
func routine() -> void:
	_routine = [
		[2.0, Vector2(0.0, 1.0), false, false, false, 0.0],
		[0.5, Vector2(0.0, 1.0), false, true, false, 0.0],
		[0.7, Vector2.ZERO, false, false, false, 0.0],
		[0.15, Vector2(1.0, 0.0), false, false, true, 0.0],
		[2.0, Vector2.ZERO, false, false, false, 0.0],
		[1.2, Vector2(-1.0, 0.0), false, false, false, 0.0],
		[1.0, Vector2.ZERO, false, false, false, 0.0],
		[2.2, Vector2.ZERO, false, false, false, PI],
		[3.0, Vector2(0.0, 1.0), true, false, false, 0.0],
		[2.0, Vector2.ZERO, false, false, false, 0.0],
	]
	_routine_clock = 0.0
	aim_yaw = _yaw


func _read(delta: float) -> void:
	if not _routine.is_empty():
		var step: Array = _routine[0]
		if _routine_clock == 0.0:
			aim_yaw = _yaw + float(step[5])
		move = step[1]
		sprint = step[2]
		jump = step[3]
		dash = step[4]
		_routine_clock += delta
		if _routine_clock >= float(step[0]):
			_routine.pop_front()
			_routine_clock = 0.0
		return
	var mine := _driving and UIState.gameplay_active()
	move = Vector2(MechKeys.axis(KEY_D, KEY_A), MechKeys.axis(KEY_W, KEY_S)) if mine else Vector2.ZERO
	sprint = mine and Input.is_physical_key_pressed(KEY_SHIFT)
	crouch = mine and Input.is_physical_key_pressed(KEY_CTRL)
	jump = mine and Input.is_physical_key_pressed(KEY_SPACE)
	dash = mine and Input.is_physical_key_pressed(KEY_SHIFT)


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if not _driving or motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	aim_yaw -= motion.relative.x * 0.0025 * GameOptions.mouse_sensitivity
	get_viewport().set_input_as_handled()


## ── POSEERLA (ver SandboxPossession) ─────────────────────────────────────────────────────────────────────────────

func possess_name() -> String:
	return "Meca cinemática"


func possess_controls() -> PackedStringArray:
	return PackedStringArray([
		"W/S adelante y atrás · A/D de costado · mouse gira",
		"Shift corre · Ctrl se agacha",
		"espacio: mantener carga el salto, soltar salta; en el aire, propulsor",
		"Shift en el aire: dash",
	])


func possess_status() -> String:
	return "inclinación %.0f° · propulsor %d %% · caídas %d" % [tilt, roundi(fuel * 100.0), falls]


func possess_begin() -> void:
	_driving = true
	_chase_yaw = _yaw


func possess_end() -> void:
	_driving = false


func possess_camera(first: bool, delta: float) -> Transform3D:
	if first:
		return global_transform * Transform3D(Basis(), Vector3(0.0, -SIZE.y * 0.5 + WALL + 1.7, 2.0))
	_chase_yaw = lerp_angle(_chase_yaw, _yaw, 1.0 - exp(-4.0 * delta))
	var from := _centre + Basis(Vector3.UP, _chase_yaw) * Vector3(0.0, 14.0, 34.0)
	return Transform3D(Basis(), from).looking_at(_centre + Vector3(0.0, 2.0, 0.0), Vector3.UP)
