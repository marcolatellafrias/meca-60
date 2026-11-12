class_name Mech
extends Node3D

## LA MECA DEL BOCETO: un torso de tres pisos (MechTorso) sobre dos piernas (MechLeg), con dos brazos comunes que
## pegan piñas cargadas (MechArm; el derecho lleva el cañón encima del antebrazo) y un montacargas atrás (MechLift).
##
## LA RAÍZ es la meca en el suelo: su lugar y hacia dónde caminan las piernas (−Z). No se inclina. El torso cuelga de
## ella a la altura de la cadera, GIRADO APARTE (`torso_aim`, con su velocidad de giro), e inclinado con el equilibrio.
##
## ── LAS PALANCAS ────────────────────────────────────────────────────────────────────────────────────────────────
## Lo que maneja la meca, sea un jugador o el rival sin piloto (MechBrain): la marcha (`throttle`, `steer`), afirmarse
## (`braced`), hacia dónde quiere mirar el torso en el mundo (`torso_aim`), adónde apuntan los brazos (`aim_point`), y
## cargar y soltar cada brazo.
##
## ── LOS QUE LA MANEJAN ──────────────────────────────────────────────────────────────────────────────────────────
## EL QUE LA TRIPULA ES EL PERSONAJE DE CHARACTER-PARAMETRIC (el jugador local, ver DesignSandbox.player_of): va
## adentro del torso, que es un marco (MotionFrame), y se sienta en las sillas de los puestos con la E de allá (ver
## MechSeat). La meca sólo mira en qué silla está sentado; mira con su cabeza.
## Desde adentro, sentado en un puesto:
##   Piernas: W/S camina, A/D gira las piernas, Shift se afirma.
##   Brazos: los brazos apuntan adonde se mira; clic izquierdo y derecho, mantener carga y soltar pega; mientras la piña
##     viaja, el mouse la dobla. Z/X giran el torso. G el cañón.
##   Vigía: una cámara de afuera que gira con el mouse.
##   Desde cualquier puesto, para probar de a uno: flechas caminan, B se afirma, Z/X giran el torso, F y H los brazos
##   (mantener y soltar), G el cañón.
## DESDE AFUERA (O; lo pidió el usuario: «que se pueda controlar la nave yo viéndole de afuera… así yo veo cómo se ve de
## afuera mientras se está moviendo»): una cámara atrás del torso y todo junto: WASD las piernas, el mouse el torso y
## las piñas como en el puesto de los brazos, Shift se afirma, G el cañón. O o E vuelve. T pasa a PRIMERA PERSONA (los
## ojos en el frente del torso, a la altura de los hombros) y vuelve a la de atrás; los controles son los mismos.
##
## ── EL EQUILIBRIO ───────────────────────────────────────────────────────────────────────────────────────────────
## Un resorte de dos ejes (`stability`: x a la derecha, y adelante, en el espacio de las piernas; 1 es el límite). Lo
## empujan soltar una piña (hacia donde se pega), el cañón (para atrás), acelerar, doblar caminando y lo que le peguen.
## Un golpe empuja más si llega DE COSTADO o DE ATRÁS DEL TORSO (`SIDE_WEAKNESS`, `BACK_WEAKNESS`): por eso importa
## girar a tiempo. Afirmarse lo endurece. Si pasa de 1, LA MECA SE CAE para ese lado, queda en el suelo y se levanta.

signal fell()

const PELVIS := 7.4
const HIP_X := 2.7
const WALK_SPEED := 6.0
const BACK_SPEED := 3.0
const ACCEL := 3.5
const TURN_SPEED := 0.75
const RADIUS := 5.5
const STRIDE := 5.0
const LIFT := 1.4
## Cuánto se inclina el torso con el equilibrio a 1, en radianes.
const TILT := deg_to_rad(13.0)
const SPRING := 5.0
const DAMPING := 2.6
const BRACED_SPRING := 11.0
const BRACED_DAMPING := 6.0
const FALL_TIME := 1.3
const DOWN_TIME := 3.0
const RISE_TIME := 2.5
const FALLEN_ANGLE := deg_to_rad(68.0)
## EL GIRO DEL TORSO: a qué velocidad gira sobre las piernas (rad/s; una mejora, más adelante) y hasta dónde.
const TORSO_TURN_SPEED := 1.3
const TORSO_LIMIT := deg_to_rad(110.0)
## Cuánto más empuja un golpe de costado y uno de atrás (sobre 1, de frente).
const SIDE_WEAKNESS := 0.4
const BACK_WEAKNESS := 0.9
## La cámara de afuera: a qué distancia va atrás del torso y cuánto se puede mirar arriba y abajo.
const CHASE_DISTANCE := 30.0
## Por sobre el hombro derecho y arriba, para que el propio torso no tape al otro.
const CHASE_SHOULDER := Vector3(9.0, 10.0, 0.0)
const CHASE_PITCH_MIN := deg_to_rad(-35.0)
const CHASE_PITCH_MAX := deg_to_rad(15.0)

enum State { STANDING, FALLING, DOWN, RISING }

## Si el lugar está libre para pararse (lo pone la arena): `func(at: Vector3, radius: float) -> bool`.
var can_stand: Callable = Callable()
## El color de los puños, para distinguir las dos mecas.
var glove_color := Clay.RED
## El rival sin piloto, si esta meca no la maneja un jugador.
var brain: MechBrain = null
## La otra meca (para mostrar su estado en pantalla).
var opponent: Mech = null
var torso: MechTorso = null
var lift: MechLift = null
var left_arm: MechArm = null
var right_arm: MechArm = null
var stability := Vector2.ZERO
var state := State.STANDING
## Las palancas (ver arriba).
var throttle := 0.0
var steer := 0.0
var braced := false
var torso_aim := 0.0
var aim_point := Vector3.ZERO
## Los golpes recibidos y cuánto empujó de más el último por llegar de costado o de atrás.
var hits_taken := 0
var last_weakness := 1.0

var _stability_speed := Vector2.ZERO
var _speed := 0.0
var _turn := 0.0
var _twist := 0.0
var _phase := 0.0
var _legs: Array[MechLeg] = []
var _fall_direction := Vector2.ZERO
var _fall_clock := 0.0
var _fall_from := Vector2.ZERO
var _seat: MechSeat = null
var _from_outside := false
var _camera: Camera3D = null
var _orbit_yaw := 0.0
var _orbit_pitch := deg_to_rad(-18.0)
var _chase_yaw := 0.0
var _chase_pitch := deg_to_rad(-12.0)
var _first_person := false
var _hud: MechHud = null


func _ready() -> void:
	torso = MechTorso.new()
	torso.top_level = true
	add_child(torso)
	lift = MechLift.new()
	add_child(lift)
	lift.set_range(-PELVIS + 0.15, MechTorso.floor_y(0))
	for side: float in [-1.0, 1.0]:
		var leg := MechLeg.new()
		leg.name = "Pierna izquierda" if side < 0.0 else "Pierna derecha"
		add_child(leg)
		_legs.append(leg)
	var shoulder_y := MechTorso.floor_y(1) + 1.6
	for side: float in [-1.0, 1.0]:
		var arm := MechArm.new()
		arm.name = "Brazo izquierdo" if side < 0.0 else "Brazo derecho"
		arm.side = side
		arm.has_cannon = side > 0.0
		arm.glove_color = glove_color
		arm.position = Vector3(side * (MechTorso.WIDTH * 0.5 + 1.3), shoulder_y, -0.6)
		arm.exclude = [torso.get_rid(), lift.get_rid()]
		arm.own_body = torso
		torso.add_child(arm)
		arm.kicked.connect(_on_kick)
		if side < 0.0:
			left_arm = arm
		else:
			right_arm = arm
	_camera = Camera3D.new()
	_camera.name = "Cámara de afuera"
	_camera.top_level = true
	_camera.far = 2000.0
	add_child(_camera)
	_hud = MechHud.new()
	add_child(_hud)
	torso_aim = global_rotation.y
	_chase_yaw = torso_aim
	_place_body(0.0)
	_place_body.call_deferred(0.0)


## EL JUGADOR LOCAL (el personaje de character-parametric), el que puede tripularla.
func _player() -> BoneInstantiator:
	return DesignSandbox.player_of(get_tree())


## Si la maneja un jugador (sentado en un puesto o desde afuera).
func is_crewed() -> bool:
	return _seat != null or _from_outside


func driven_from_outside() -> bool:
	return _from_outside


## Lleva al jugador al piso de abajo, detrás de la silla de las piernas (la U del sandbox): E y ya está sentado.
func board() -> void:
	var player := _player()
	if player == null:
		return
	if _from_outside:
		_leave_outside()
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	var feet := torso.global_transform * Vector3(0.0, MechTorso.floor_y(0) + 0.05, -MechTorso.DEPTH * 0.5 + 2.8)
	player.place_at(feet, torso_yaw())


## MANEJARLA DESDE AFUERA (la O del sandbox), o volver. El jugador se apaga mientras tanto (`set_active`: ni se ve ni
## lee teclas) y queda donde estaba; si estaba sentado, se levanta antes.
func toggle_outside() -> void:
	if _from_outside:
		_leave_outside()
		return
	var player := _player()
	if player == null:
		return
	if player.is_seated and player.current_seat is SeatInteractable:
		(player.current_seat as SeatInteractable).release_occupant_in_place()
	_from_outside = true
	add_to_group("driving")
	player.set_active(false)
	_chase_yaw = torso_yaw()
	_camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _leave_outside() -> void:
	_from_outside = false
	remove_from_group("driving")
	left_arm.cancel()
	right_arm.cancel()
	var player := _player()
	if player == null:
		return
	player.set_active(true)
	if is_instance_valid(player.player_camera):
		player.player_camera.make_current()


## ── LA ENTRADA ──────────────────────────────────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not UIState.gameplay_active():
		return
	var key := event as InputEventKey
	if key != null and not key.echo:
		if key.pressed and key.physical_keycode == KEY_E:
			if _from_outside:
				_leave_outside()
				get_viewport().set_input_as_handled()
			else:
				_toggle_lift()
			return
		if not is_crewed():
			return
		match key.physical_keycode:
			KEY_F:
				_arm_key(left_arm, key.pressed)
			KEY_H:
				_arm_key(right_arm, key.pressed)
			KEY_G:
				if key.pressed and state == State.STANDING:
					right_arm.fire(aim_point)
			KEY_T:
				if key.pressed and _from_outside:
					_first_person = not _first_person
			_:
				return
		get_viewport().set_input_as_handled()
		return
	if not is_crewed():
		return
	var motion := event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_mouse(motion.relative)
		get_viewport().set_input_as_handled()
		return
	var click := event as InputEventMouseButton
	if click != null and (_from_outside or _seat.station == MechSeat.Station.ARMS):
		if click.button_index == MOUSE_BUTTON_LEFT:
			_arm_key(left_arm, click.pressed)
		elif click.button_index == MOUSE_BUTTON_RIGHT:
			_arm_key(right_arm, click.pressed)
		get_viewport().set_input_as_handled()


## Apretar carga, soltar pega.
func _arm_key(arm: MechArm, pressed: bool) -> void:
	if pressed:
		if state == State.STANDING:
			arm.hold()
	else:
		arm.let_go(aim_point)


## EL MOUSE: desde afuera gira el torso y mira arriba y abajo, salvo que una piña esté saliendo: entonces la dobla. En
## los brazos sólo dobla la piña (se mira con la cabeza); en la vigía gira la cámara de afuera.
func _mouse(relative: Vector2) -> void:
	var sensitivity := 0.0025 * GameOptions.mouse_sensitivity
	if not _from_outside and _seat.station == MechSeat.Station.LOOKOUT:
		_orbit_yaw -= relative.x * sensitivity
		_orbit_pitch = clampf(_orbit_pitch - relative.y * sensitivity, deg_to_rad(-70.0), deg_to_rad(10.0))
		return
	for arm: MechArm in [left_arm, right_arm]:
		if arm.is_striking():
			arm.bend(Vector2(relative.x, -relative.y))
			return
	if _from_outside:
		torso_aim -= relative.x * sensitivity
		_chase_pitch = clampf(_chase_pitch - relative.y * sensitivity, CHASE_PITCH_MIN, CHASE_PITCH_MAX)


## E parado en el montacargas: lo manda a la otra punta.
func _toggle_lift() -> void:
	var player := _player()
	if player == null or player.is_seated or not is_instance_valid(player.char_rigidbody):
		return
	if lift.carries(player.char_rigidbody.global_position):
		lift.toggle()


## EN QUÉ PUESTO ESTÁ SENTADO EL JUGADOR (o en ninguno). Al sentarse en la vigía se pasa a la cámara de afuera, y al
## levantarse de ella vuelve la de su cabeza.
func _find_seat() -> void:
	var player := _player()
	var now: MechSeat = null
	for seat in torso.seats:
		if seat.holds(player):
			now = seat
	if now == _seat:
		return
	var was := _seat
	_seat = now
	if now == null:
		left_arm.cancel()
		right_arm.cancel()
	if now != null and now.station == MechSeat.Station.LOOKOUT:
		_orbit_yaw = torso_yaw()
		_camera.make_current()
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif was != null and was.station == MechSeat.Station.LOOKOUT and is_instance_valid(player) \
			and is_instance_valid(player.player_camera):
		player.player_camera.make_current()


func _on_kick(direction: Vector3, amount: float) -> void:
	push(direction, amount)


## UN EMPUJÓN al equilibrio: `direction` en el mundo, `amount` en unidades de equilibrio por segundo.
func push(direction: Vector3, amount: float) -> void:
	var local := global_basis.inverse() * direction
	_stability_speed += Vector2(local.x, -local.z).limit_length(1.0) * amount


## UN GOLPE de otra meca o de una bala: empuja el equilibrio hacia `direction`, más si llega de costado o de atrás del
## torso. `_amount` (la velocidad del golpe) no se descuenta de ninguna vida: acá todo es equilibrio.
func take_hit(_amount: float, direction: Vector3, push_amount: float) -> void:
	var forward := -torso.global_basis.z
	forward.y = 0.0
	var flat := Vector3(direction.x, 0.0, direction.z)
	hits_taken += 1
	if forward.length_squared() < 0.0001 or flat.length_squared() < 0.0001:
		last_weakness = 1.0
		push(direction, push_amount)
		return
	forward = forward.normalized()
	flat = flat.normalized()
	# Un golpe de atrás empuja hacia adelante del torso.
	var from_behind := maxf(flat.dot(forward), 0.0)
	var from_side := absf(flat.cross(forward).y)
	last_weakness = 1.0 + SIDE_WEAKNESS * from_side + BACK_WEAKNESS * from_behind
	push(direction, push_amount * last_weakness)


## ── CADA PASO ───────────────────────────────────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if brain == null:
		_find_seat()
	if is_crewed():
		_read_keys(delta)
	elif brain != null:
		brain.think(self, delta)
	else:
		throttle = 0.0
		steer = 0.0
		braced = false
	if state != State.STANDING:
		throttle = 0.0
		steer = 0.0
		braced = false
		left_arm.cancel()
		right_arm.cancel()
	_walk(clampf(throttle, -1.0, 1.0), clampf(steer, -1.0, 1.0), delta)
	_turn_torso(delta)
	_balance(delta)
	_place_body(delta)
	if is_crewed():
		_aim_from_camera()
	elif brain == null:
		aim_point = torso.global_transform * Vector3(0.0, MechTorso.floor_y(1) + 1.6, -60.0)
	for seat in torso.seats:
		seat.show_stability(stability)
	_hud.show_state(self, _seat)


## Las teclas del que la maneja (las del mouse llegan por `_unhandled_input`).
func _read_keys(delta: float) -> void:
	throttle = 0.0
	steer = 0.0
	braced = false
	if not UIState.gameplay_active():
		return
	var at_legs := _from_outside or _seat.station == MechSeat.Station.LEGS
	throttle = _axis(KEY_UP, KEY_DOWN) + (_axis(KEY_W, KEY_S) if at_legs else 0.0)
	steer = _axis(KEY_LEFT, KEY_RIGHT) + (_axis(KEY_A, KEY_D) if at_legs else 0.0)
	braced = Input.is_physical_key_pressed(KEY_B) or (at_legs and Input.is_physical_key_pressed(KEY_SHIFT))
	torso_aim += _axis(KEY_Z, KEY_X) * TORSO_TURN_SPEED * delta


static func _axis(positive: Key, negative: Key) -> float:
	return (1.0 if Input.is_physical_key_pressed(positive) else 0.0) - (1.0 if Input.is_physical_key_pressed(negative) else 0.0)


## LA MARCHA: velocidad y giro con su inercia; afirmada va a un tercio. Lo que acelera y dobla empuja el equilibrio.
func _walk(p_throttle: float, p_steer: float, delta: float) -> void:
	var top := WALK_SPEED if p_throttle >= 0.0 else BACK_SPEED
	if braced:
		top *= 0.35
	var wanted := p_throttle * top
	var before := _speed
	_speed = move_toward(_speed, wanted, ACCEL * delta)
	_turn = move_toward(_turn, p_steer * TURN_SPEED * (0.5 if braced else 1.0), 1.5 * delta)
	var accel := (_speed - before) / maxf(delta, 0.0001)
	# Acelerar tira el torso para atrás; frenar, para adelante. Doblar caminando, hacia afuera de la curva.
	_stability_speed += Vector2(_turn * _speed * 0.05, -accel * 0.07) * delta * 6.0
	rotate_y(_turn * delta)
	var step := -global_basis.z * _speed * delta
	if step.length_squared() > 0.0:
		var next := global_position + step
		if not can_stand.is_valid() or bool(can_stand.call(next, RADIUS)):
			global_position = next
		else:
			_stability_speed.y -= signf(_speed) * 0.8
			_speed = 0.0
	_phase = fposmod(_phase + (absf(_speed) / STRIDE + absf(_turn) * 0.6) * delta, 1.0)


## EL TORSO GIRA HACIA `torso_aim` a su velocidad, con un tope sobre las piernas. Si el que maneja pide más que el tope,
## el pedido se queda en el tope (no se acumula).
func _turn_torso(delta: float) -> void:
	var legs_yaw := global_rotation.y
	var wanted := clampf(wrapf(torso_aim - legs_yaw, -PI, PI), -TORSO_LIMIT, TORSO_LIMIT)
	torso_aim = legs_yaw + wanted
	_twist = move_toward(_twist, wanted, TORSO_TURN_SPEED * delta)


## Hacia dónde mira el torso en el mundo (sin la inclinación).
func torso_yaw() -> float:
	return global_rotation.y + _twist


## EL RESORTE DEL EQUILIBRIO, y la caída si se pasa.
func _balance(delta: float) -> void:
	match state:
		State.STANDING:
			var spring := BRACED_SPRING if braced else SPRING
			var damping := BRACED_DAMPING if braced else DAMPING
			_stability_speed += (-stability * spring - _stability_speed * damping) * delta
			stability += _stability_speed * delta
			if stability.length() > 1.0:
				_fall()
		State.FALLING, State.DOWN, State.RISING:
			_fall_clock += delta
			if state == State.FALLING and _fall_clock >= FALL_TIME:
				state = State.DOWN
				_fall_clock = 0.0
			elif state == State.DOWN and _fall_clock >= DOWN_TIME:
				state = State.RISING
				_fall_clock = 0.0
			elif state == State.RISING and _fall_clock >= RISE_TIME:
				state = State.STANDING
				stability = Vector2.ZERO
				_stability_speed = Vector2.ZERO


func _fall() -> void:
	state = State.FALLING
	_fall_clock = 0.0
	_fall_direction = stability.normalized()
	_fall_from = stability
	_speed = 0.0
	_turn = 0.0
	fell.emit()


## Cuánto está inclinado el torso ahora (dirección en el plano de la meca y ángulo), y la altura de la cadera.
func _lean() -> Dictionary:
	var lean := stability * TILT
	var pelvis := PELVIS - absf(sin(_phase * TAU)) * 0.35 * clampf(absf(_speed) / WALK_SPEED + absf(_turn), 0.0, 1.0)
	match state:
		State.FALLING:
			# Se va cayendo cada vez más rápido, como algo pesado.
			var share := ease(clampf(_fall_clock / FALL_TIME, 0.0, 1.0), 2.4)
			lean = _fall_direction * lerpf(_fall_from.length() * TILT, FALLEN_ANGLE, share)
			pelvis = lerpf(PELVIS, 3.2, share)
		State.DOWN:
			lean = _fall_direction * FALLEN_ANGLE
			pelvis = 3.2
		State.RISING:
			var share := ease(clampf(_fall_clock / RISE_TIME, 0.0, 1.0), -2.0)
			lean = _fall_direction * lerpf(FALLEN_ANGLE, 0.0, share)
			pelvis = lerpf(3.2, PELVIS, share)
	return {"lean": lean, "pelvis": pelvis}


## EL CUERPO EN SU LUGAR: el torso girado e inclinado sobre la cadera, el montacargas, las piernas y la cámara de afuera.
func _place_body(delta: float) -> void:
	var pose := _lean()
	var lean: Vector2 = pose["lean"]
	var pelvis: float = pose["pelvis"]
	var tilt := Basis()
	if lean.length() > 0.0001:
		var toward := Vector3(lean.x, 0.0, -lean.y).normalized()
		tilt = Basis(Vector3.UP.cross(toward).normalized(), lean.length())
	var hips := global_transform * Transform3D(Basis(), Vector3(0.0, pelvis, 0.0))
	torso.global_transform = hips * Transform3D(tilt * Basis(Vector3.UP, _twist), Vector3.ZERO)
	lift.place(torso.global_transform, MechTorso.lift_centre(), delta)
	# Las piernas: de la cadera (abajo del torso, inclinada con él) al pie, que va y viene con la marcha.
	var moving := clampf(absf(_speed) / WALK_SPEED + absf(_turn) * 1.5, 0.0, 1.0)
	var direction := -1.0 if _speed < -0.05 else 1.0
	for i in _legs.size():
		var side := -1.0 if i == 0 else 1.0
		var hip := Vector3(0.0, pelvis, 0.0) + tilt * Vector3(side * HIP_X, -0.3, 0.0)
		var angle := (_phase + 0.5 * i) * TAU
		var foot := Vector3(side * (HIP_X + 0.3), maxf(0.0, sin(angle)) * LIFT * moving,
			direction * cos(angle) * STRIDE * 0.5 * moving)
		if state != State.STANDING:
			foot = Vector3(side * (HIP_X + 0.3), 0.0, 0.0)
		_legs[i].pose(hip, foot, Vector3.FORWARD)
	_place_camera(delta)


## LA CÁMARA DE AFUERA. Manejando desde afuera: en primera persona (T), en el frente del torso; si no, atrás del torso,
## por sobre el hombro, siguiéndolo con un poco de atraso (así se ve cuánto tarda en girar). En la vigía: alrededor
## del torso y de lejos.
func _place_camera(delta: float) -> void:
	var centre := global_position + Vector3(0.0, PELVIS + MechTorso.top_y() * 0.5, 0.0)
	if _from_outside and _first_person:
		var eyes := Vector3(0.0, MechTorso.floor_y(1) + 1.6, -MechTorso.DEPTH * 0.5 - 0.6)
		_camera.global_transform = torso.global_transform * Transform3D(Basis.from_euler(Vector3(_chase_pitch, 0.0, 0.0)), eyes)
		_chase_yaw = torso_yaw()
		return
	if _from_outside:
		var follow := 1.0 - exp(-5.0 * delta) if delta > 0.0 else 1.0
		_chase_yaw = lerp_angle(_chase_yaw, torso_yaw(), follow)
		var view := Basis.from_euler(Vector3(_chase_pitch, _chase_yaw, 0.0))
		_camera.global_transform = Transform3D(view, centre + Basis(Vector3.UP, _chase_yaw) * CHASE_SHOULDER
			+ view * Vector3(0.0, 0.0, CHASE_DISTANCE))
		return
	var orbit := Basis.from_euler(Vector3(_orbit_pitch, _orbit_yaw, 0.0))
	_camera.global_position = centre + orbit * Vector3(0.0, 0.0, 42.0)
	_camera.look_at(centre + Vector3(0, 4.0, 0), Vector3.UP)


## Adónde apunta el que la maneja: lo que está en el medio de su pantalla.
func _aim_from_camera() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var from := camera.global_position
	var to := from - camera.global_basis.z * 400.0
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [torso.get_rid(), lift.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	aim_point = hit["position"] if not hit.is_empty() else to


