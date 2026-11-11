class_name Mech
extends Node3D

## LA MECA DEL BOCETO: un torso de tres pisos (MechTorso) sobre dos piernas (MechLeg), con un puño de resorte a la
## izquierda (MechFist) y un cañón a la derecha (MechCannon), y un montacargas atrás (MechLift). Se maneja desde
## adentro: uno camina por el torso, sube por la escalera de incendio y se sienta en un puesto (E).
##
## LA RAÍZ es la meca en el suelo: su lugar y hacia dónde mira (−Z). No se inclina. El torso cuelga de ella a la altura
## de la cadera y se inclina con el equilibrio; las piernas van de la cadera al suelo.
##
## ── LOS PUESTOS Y LAS TECLAS ────────────────────────────────────────────────────────────────────────────────────
## Cada puesto maneja lo suyo con las teclas de siempre, y MIENTRAS SE PRUEBA DE A UNO, desde cualquier puesto se
## alcanzan los de los demás con teclas aparte (lo pidió el usuario el 11/11/2026: «estoy yo solo… unas teclas del
## teclado para controlar otras cosas»):
##   Piernas: W/S camina, A/D gira, Shift se afirma (más firme, más lenta) · desde cualquiera: flechas y B.
##   Brazos: el mouse apunta, clic izquierdo el puño, clic derecho el cañón · desde cualquiera: F y G (apuntan adonde
##     mire el que esté sentado).
##   Vigía: una cámara de afuera, que gira con el mouse, para leer cómo se mueve la meca.
## E se sienta en el puesto más cercano y se levanta; parado en el montacargas, E lo manda a la otra punta.
##
## ── EL EQUILIBRIO ───────────────────────────────────────────────────────────────────────────────────────────────
## Un resorte de dos ejes (`stability`: x a la derecha, y adelante; 1 es el límite). Lo empujan pegar (hacia donde se
## pega), disparar (para atrás), acelerar, doblar caminando y lo que le peguen. Afirmarse lo endurece. El torso se
## inclina con él, y el nivel de cada consola lo muestra. Si pasa de 1, LA MECA SE CAE para ese lado, queda en el
## suelo y se levanta sola.

signal fell()

const PELVIS := 7.4
const HIP_X := 2.7
const WALK_SPEED := 6.0
const BACK_SPEED := 3.0
const ACCEL := 3.5
const TURN_SPEED := 0.75
const RADIUS := 6.0
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

enum State { STANDING, FALLING, DOWN, RISING }

## Si el lugar está libre para pararse (lo pone la arena): `func(at: Vector3, radius: float) -> bool`.
var can_stand: Callable = Callable()
var torso: MechTorso = null
var lift: MechLift = null
var fist: MechFist = null
var cannon: MechCannon = null
var stability := Vector2.ZERO
var state := State.STANDING

var _stability_speed := Vector2.ZERO
var _speed := 0.0
var _turn := 0.0
var _braced := false
var _phase := 0.0
var _legs: Array[MechLeg] = []
var _fall_direction := Vector2.ZERO
var _fall_clock := 0.0
var _fall_from := Vector2.ZERO
var _walker: SandboxWalker = null
var _seat: MechSeat = null
var _outside: Camera3D = null
var _outside_yaw := 0.0
var _outside_pitch := deg_to_rad(-18.0)
var _hud: MechHud = null
var _aim_point := Vector3.ZERO


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
	fist = MechFist.new()
	fist.name = "Brazo del puño"
	fist.position = Vector3(-MechTorso.WIDTH * 0.5 - 1.2, shoulder_y, -0.6)
	torso.add_child(fist)
	cannon = MechCannon.new()
	cannon.name = "Brazo del cañón"
	cannon.position = Vector3(MechTorso.WIDTH * 0.5 + 1.2, shoulder_y, -0.6)
	torso.add_child(cannon)
	for arm: MechArm in [fist, cannon]:
		arm.kicked.connect(_on_kick)
	_outside = Camera3D.new()
	_outside.name = "Cámara de afuera"
	_outside.top_level = true
	_outside.far = 2000.0
	add_child(_outside)
	_hud = MechHud.new()
	add_child(_hud)
	_place_body(0.0)
	_place_body.call_deferred(0.0)


## EL QUE CAMINA (el del sandbox), buscado una vez.
func _walker_node() -> SandboxWalker:
	if _walker == null or not is_instance_valid(_walker):
		var found := get_tree().root.find_children("*", "SandboxWalker", true, false)
		_walker = found[0] as SandboxWalker if not found.is_empty() else null
	return _walker


## Si alguien está sentado en un puesto de esta meca.
func is_crewed() -> bool:
	return _seat != null


## Lleva al que camina al piso de abajo, frente al puesto de las piernas (la U del sandbox).
func board() -> void:
	var walker := _walker_node()
	if walker == null:
		return
	if _seat != null:
		_stand_up()
	walker.set_creative(false)
	walker.velocity = Vector3.ZERO
	# Detrás de la silla de las piernas, a un paso: E y ya está sentado.
	walker.global_position = torso.global_transform * Vector3(0.0, MechTorso.floor_y(0) + 0.2, -MechTorso.DEPTH * 0.5 + 2.6)
	walker.global_rotation = Vector3(0.0, global_rotation.y, 0.0)


## ── LA ENTRADA ──────────────────────────────────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo:
		if key.physical_keycode == KEY_E:
			if _interact():
				get_viewport().set_input_as_handled()
			return
		if _seat == null:
			return
		match key.physical_keycode:
			KEY_F:
				_use(fist)
			KEY_G:
				_use(cannon)
			_:
				return
		get_viewport().set_input_as_handled()
		return
	if _seat == null:
		return
	var motion := event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _seat.station == MechSeat.Station.LOOKOUT:
			var sensitivity := 0.0025 * GameOptions.mouse_sensitivity
			_outside_yaw -= motion.relative.x * sensitivity
			_outside_pitch = clampf(_outside_pitch - motion.relative.y * sensitivity, deg_to_rad(-70.0), deg_to_rad(10.0))
		else:
			_seat.look(motion.relative)
		get_viewport().set_input_as_handled()
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed and _seat.station == MechSeat.Station.ARMS:
		if click.button_index == MOUSE_BUTTON_LEFT:
			_use(fist)
		elif click.button_index == MOUSE_BUTTON_RIGHT:
			_use(cannon)
		get_viewport().set_input_as_handled()


## E: levantarse, sentarse en el puesto más cercano o mandar el montacargas. Devuelve si hizo algo.
func _interact() -> bool:
	var walker := _walker_node()
	if walker == null:
		return false
	if _seat != null:
		_stand_up()
		return true
	var nearest: MechSeat = null
	var best := 1.8
	for seat in torso.seats:
		var distance := seat.global_position.distance_to(walker.global_position)
		if distance < best:
			best = distance
			nearest = seat
	if nearest != null:
		_sit(nearest)
		return true
	if lift.carries(walker.global_position):
		lift.toggle()
		return true
	return false


func _sit(seat: MechSeat) -> void:
	var walker := _walker_node()
	_seat = seat
	walker.seated = true
	walker.velocity = Vector3.ZERO
	walker.collision_layer = 0
	walker.collision_mask = 0
	walker.set_physics_process(false)
	seat.reset_look()
	if seat.station == MechSeat.Station.LOOKOUT:
		_outside_yaw = global_rotation.y
		_outside.make_current()
	else:
		seat.camera.fov = GameOptions.field_of_view
		seat.camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _stand_up() -> void:
	var walker := _walker_node()
	var seat := _seat
	_seat = null
	if walker == null:
		return
	walker.collision_layer = 1
	walker.collision_mask = 1
	walker.set_physics_process(true)
	walker.velocity = Vector3.ZERO
	walker.global_position = seat.global_transform * Vector3(0.0, 0.15, 0.9)
	walker.global_rotation = Vector3(0.0, seat.global_rotation.y, 0.0)
	walker.seated = false


func _use(arm: MechArm) -> void:
	if state == State.STANDING:
		arm.use()


func _on_kick(direction: Vector3, amount: float) -> void:
	push(direction, amount)


## UN EMPUJÓN al equilibrio: `direction` en el mundo, `amount` en unidades de equilibrio por segundo.
func push(direction: Vector3, amount: float) -> void:
	var local := global_basis.inverse() * direction
	_stability_speed += Vector2(local.x, -local.z).limit_length(1.0) * amount


## ── CADA PASO ───────────────────────────────────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	var throttle := 0.0
	var steer := 0.0
	_braced = false
	if _seat != null and state == State.STANDING and not get_tree().paused:
		var at_legs := _seat.station == MechSeat.Station.LEGS
		throttle = _axis(KEY_UP, KEY_DOWN) + (_axis(KEY_W, KEY_S) if at_legs else 0.0)
		steer = _axis(KEY_LEFT, KEY_RIGHT) + (_axis(KEY_A, KEY_D) if at_legs else 0.0)
		_braced = Input.is_physical_key_pressed(KEY_B) or (at_legs and Input.is_physical_key_pressed(KEY_SHIFT))
	_walk(clampf(throttle, -1.0, 1.0), clampf(steer, -1.0, 1.0), delta)
	_balance(delta)
	_place_body(delta)
	_aim(delta)
	_carry_seated()
	for seat in torso.seats:
		seat.show_stability(stability)
	_hud.show_state(self, _seat)


static func _axis(positive: Key, negative: Key) -> float:
	return (1.0 if Input.is_physical_key_pressed(positive) else 0.0) - (1.0 if Input.is_physical_key_pressed(negative) else 0.0)


## LA MARCHA: velocidad y giro con su inercia; afirmada va a un tercio. Lo que acelera y dobla empuja el equilibrio.
func _walk(throttle: float, steer: float, delta: float) -> void:
	var top := WALK_SPEED if throttle >= 0.0 else BACK_SPEED
	if _braced:
		top *= 0.35
	var wanted := throttle * top
	var before := _speed
	_speed = move_toward(_speed, wanted, ACCEL * delta)
	_turn = move_toward(_turn, steer * TURN_SPEED * (0.5 if _braced else 1.0), 1.5 * delta)
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


## EL RESORTE DEL EQUILIBRIO, y la caída si se pasa.
func _balance(delta: float) -> void:
	match state:
		State.STANDING:
			var spring := BRACED_SPRING if _braced else SPRING
			var damping := BRACED_DAMPING if _braced else DAMPING
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


## EL CUERPO EN SU LUGAR: el torso inclinado sobre la cadera, el montacargas, las piernas y la cámara de afuera.
func _place_body(delta: float) -> void:
	var pose := _lean()
	var lean: Vector2 = pose["lean"]
	var pelvis: float = pose["pelvis"]
	var tilt := Basis()
	if lean.length() > 0.0001:
		var toward := Vector3(lean.x, 0.0, -lean.y).normalized()
		tilt = Basis(Vector3.UP.cross(toward).normalized(), lean.length())
	var hips := global_transform * Transform3D(Basis(), Vector3(0.0, pelvis, 0.0))
	torso.global_transform = hips * Transform3D(tilt, Vector3.ZERO)
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
	# La cámara de afuera: alrededor del torso, de lejos.
	var centre := torso.global_transform * Vector3(0.0, MechTorso.top_y() * 0.5, 0.0)
	var orbit := Basis.from_euler(Vector3(_outside_pitch, _outside_yaw, 0.0))
	_outside.global_position = centre + orbit * Vector3(0.0, 0.0, 42.0)
	_outside.look_at(centre + Vector3(0, 4.0, 0), Vector3.UP)


## Los brazos apuntan adonde mira el que está sentado (o al frente, si no hay nadie).
func _aim(delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if _seat == null or camera == null:
		_aim_point = torso.global_transform * Vector3(0.0, MechTorso.floor_y(1) + 1.6, -60.0)
	else:
		var from := camera.global_position
		var to := from - camera.global_basis.z * 400.0
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [torso.get_rid(), lift.get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		_aim_point = hit["position"] if not hit.is_empty() else to
	fist.aim(_aim_point, delta)
	cannon.aim(_aim_point, delta)


## El que está sentado va con su silla.
func _carry_seated() -> void:
	if _seat == null:
		return
	var walker := _walker_node()
	if walker != null:
		walker.global_position = _seat.global_transform * Vector3(0.0, 0.3, 0.0)
