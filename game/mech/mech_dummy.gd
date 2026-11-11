class_name MechDummy
extends Node3D

## LA MECA DE EQUILIBRIO: una copia de la meca (torso, piernas y brazos en guardia) que sólo se tambalea, se cae y se
## levanta, con EL MISMO SISTEMA QUE LOS PERSONAJES DE CHARACTER-PARAMETRIC (`CharacterRigidBody3D` y `RagdollUtil` de
## allá; ver su docs/technical/characters.md). Lo pidió el usuario el 11/11/2026, para comparar con el resorte de la
## meca de pelea, que se sentía rígido. No camina ni pega.
##
##   1. EL CUERPO ES FÍSICO DE VERDAD: un RigidBody3D parado (no gira), sin fricción, que frena solo (`BRAKE`). Lo que
##      lo golpea (una bola, ver TestBall) le cambia la velocidad: la meca se corre.
##   2. EL GOLPE SE MIDE: cada paso, lo que cambió la velocidad sin que ella lo pidiera (lo que no es su freno). Debajo
##      de `HIT_NOISE` no cuenta.
##   3. LA INCLINACIÓN: un resorte de dos ejes (`lean`; rigidez y amortiguación) al que cada golpe le SUMA, de una,
##      Δv × `LEAN_PER_MS` / firmeza. La FIRMEZA es el peso sobre el de referencia por la estabilidad del lado de donde
##      viene (adelante, atrás, de costado). El torso se inclina con el resorte; las piernas siguen con los pies quietos.
##   4. LA CAÍDA, al pasar `FALL_AT` (0,85): si un golpe solo ya lo pasa, se cae en el acto; si se fue acumulando, se ve
##      inclinarse y cae `FALL_WARNING` después. Se cae COMO UN MUÑECO DE VERDAD: cada pieza es un cuerpo, unidas por
##      articulaciones con resortes (los músculos) y topes, que salen con la velocidad que traía. Además (esto no está
##      en character-parametric, que es de una persona) cada pieza sale con más velocidad cuanto más alta está
##      (`TOPPLE`), como si girara sobre los pies: una meca de 17 m que sólo se deslizara no se leería como caída.
##   5. LEVANTARSE: en el suelo `DOWN_TIME`; después cada pieza va de donde quedó a la postura parada en `RISE_TIME`,
##      con el cuerpo puesto debajo del torso.
##
## Los números de character-parametric son de una persona de 60 kg: acá la firmeza 1 es la de esta meca
## (`REFERENCE_MASS` = su masa), y el resorte va más lento (`SPRING_SCALE`, `DAMP_SCALE`), que es grande.

signal fell()
signal stood_up()

const MASS := 50000.0
const REFERENCE_MASS := 50000.0
const PELVIS := 7.4
const HIP_X := 2.7
const THIGH := 4.4
const SHIN := 4.4
const UPPER_ARM := 5.5
const FOREARM := 5.5
const LIMB := 1.2
## De character-parametric (CharacterRigidBody3D): golpe mínimo (m/s), cuánto inclina cada m/s, dónde cae, el aviso.
const HIT_NOISE := 0.3
const LEAN_PER_MS := 0.3
const FALL_AT := 0.85
const FALL_WARNING := 0.15
const STIFFNESS := 25.0
const DAMPING := 6.0
## Más lento que una persona.
const SPRING_SCALE := 0.35
const DAMP_SCALE := 0.6
## Estabilidad de cada lado (más de 1, cuesta más voltearla por ahí).
const STABILITY_FORWARD := 1.0
const STABILITY_BACKWARD := 0.8
const STABILITY_SIDEWAYS := 0.7
## Cuánto se inclina el torso con la inclinación en 1.
const LEAN_ANGLE := deg_to_rad(20.0)
## Cuánto frena sola, parada (m/s²): sus pies la sostienen.
const BRAKE := 4.0
const TOPPLE := 1.0
const DOWN_TIME := 4.0
const RISE_TIME := 2.5

enum State { STANDING, DOWN, RISING }

var state := State.STANDING
## La inclinación (x a la derecha, y adelante, en el espacio de la meca), lo que tumba al pasar `FALL_AT`.
var lean := Vector2.ZERO
## El último golpe (m/s) y la inclinación más grande desde que estaba quieta, para mirar.
var last_hit := 0.0
var peak_lean := 0.0
var falls := 0

var _body: RigidBody3D = null
var _yaw := 0.0
var _lean_speed := Vector2.ZERO
var _shown_lean := Vector2.ZERO
var _velocity_after := Vector3.ZERO
var _fall_in := -1.0
var _fall_push := Vector3.ZERO
var _clock := 0.0
var _pieces: Array[RigidBody3D] = []
var _fallen: Array[Transform3D] = []
var _joints: Array[Generic6DOFJoint3D] = []
var _label: Label3D = null


func _ready() -> void:
	_yaw = global_rotation.y
	_body = RigidBody3D.new()
	_body.name = "Cuerpo"
	_body.top_level = true
	_body.mass = MASS
	_body.can_sleep = false
	_body.continuous_cd = true
	_body.axis_lock_angular_x = true
	_body.axis_lock_angular_y = true
	_body.axis_lock_angular_z = true
	var slick := PhysicsMaterial.new()
	slick.friction = 0.0
	slick.bounce = 0.0
	_body.physics_material_override = slick
	add_child(_body)
	_body.global_transform = Transform3D(Basis(Vector3.UP, _yaw), global_position)
	var height := MechTorso.top_y()
	Clay.shape_box(_body, Vector3(MechTorso.WIDTH, height, MechTorso.DEPTH), Vector3(0, PELVIS + height * 0.5, 0))
	Clay.shape_box(_body, Vector3(HIP_X * 2.0 + 2.0, PELVIS, 3.4), Vector3(0, PELVIS * 0.5, 0))
	_build_pieces()
	_place_standing(1.0)
	# Arriba, lo que pasa: para mirar.
	_label = Label3D.new()
	_label.top_level = true
	_label.font_size = 64
	_label.pixel_size = 0.02
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.outline_size = 14
	_label.modulate = Color(1.0, 0.95, 0.6)
	add_child(_label)


## ── LAS PIEZAS: el dibujo parado y el muñeco caído son los mismos cuerpos ───────────────────────────────────────────
## Parada, son cinemáticas, no chocan (choca el cuerpo) y van adonde dice la postura. Caída, son cuerpos sueltos que
## chocan con el mundo y no entre ellas (como el muñeco de character-parametric, capa 2 que mira la 1).

const TORSO := 0
const THIGH_LEFT := 1
const SHIN_LEFT := 2
const THIGH_RIGHT := 3
const SHIN_RIGHT := 4
const UPPER_LEFT := 5
const FOREARM_LEFT := 6
const UPPER_RIGHT := 7
const FOREARM_RIGHT := 8
const PIECE_MASS := [26000.0, 3000.0, 3000.0, 3000.0, 3000.0, 1500.0, 1500.0, 1500.0, 1500.0]
const PIECE_NAMES := ["torso", "muslo izquierdo", "canilla izquierda", "muslo derecho", "canilla derecha",
	"brazo izquierdo", "antebrazo izquierdo", "brazo derecho", "antebrazo derecho"]


func _build_pieces() -> void:
	for i in PIECE_MASS.size():
		var piece := RigidBody3D.new()
		piece.name = str(PIECE_NAMES[i]).capitalize()
		piece.top_level = true
		piece.mass = PIECE_MASS[i]
		piece.continuous_cd = true
		piece.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		piece.freeze = true
		piece.collision_layer = 0
		piece.collision_mask = 0
		add_child(piece)
		_pieces.append(piece)
	var height := MechTorso.top_y()
	var torso := _pieces[TORSO]
	Clay.solid(torso, Vector3(MechTorso.WIDTH, height, MechTorso.DEPTH), Vector3.ZERO, Clay.METAL)
	for floor_index in MechTorso.FLOORS:
		var y := MechTorso.floor_y(floor_index) + 0.9 + 0.95 - height * 0.5
		Clay.box(torso, Vector3(MechTorso.WIDTH - 0.6, 1.9, 0.1), Vector3(0, y, -MechTorso.DEPTH * 0.5 - 0.02), Clay.GLASS)
	for i in [THIGH_LEFT, THIGH_RIGHT]:
		Clay.solid(_pieces[i], Vector3(LIMB, LIMB, THIGH), Vector3.ZERO, Clay.METAL.darkened(0.1))
	for i in [SHIN_LEFT, SHIN_RIGHT]:
		Clay.solid(_pieces[i], Vector3(LIMB * 0.9, LIMB * 0.9, SHIN), Vector3.ZERO, Clay.METAL.darkened(0.25))
		# El pie, al final de la canilla, mirando adelante (la canilla tiene su +Y hacia adelante, ver `_segment`).
		Clay.solid(_pieces[i], Vector3(2.2, 3.4, 0.7), Vector3(0, 0.4, -SHIN * 0.5 - 0.6), Clay.DARK)
	for i in [UPPER_LEFT, UPPER_RIGHT]:
		Clay.solid(_pieces[i], Vector3(1.3, 1.3, UPPER_ARM), Vector3.ZERO, Clay.METAL.darkened(0.1))
	for i in [FOREARM_LEFT, FOREARM_RIGHT]:
		Clay.solid(_pieces[i], Vector3(1.1, 1.1, FOREARM), Vector3.ZERO, Clay.METAL.darkened(0.25))
		Clay.solid(_pieces[i], Vector3(2.0, 2.0, 2.2), Vector3(0, 0, -FOREARM * 0.5), Clay.RED)


## LA POSTURA PARADA: dónde va cada pieza, con el torso inclinado por `shown` (la inclinación que se ve).
func _standing_pose(shown: Vector2) -> Array[Transform3D]:
	var root := Transform3D(Basis(Vector3.UP, _yaw), Vector3(_body.global_position.x, _body.global_position.y,
		_body.global_position.z))
	var angle := shown * LEAN_ANGLE
	var tilt := Basis()
	if angle.length() > 0.0001:
		var toward := Vector3(angle.x, 0.0, -angle.y).normalized()
		tilt = Basis(Vector3.UP.cross(toward).normalized(), angle.length())
	var height := MechTorso.top_y()
	var hips := root * Transform3D(Basis(), Vector3(0, PELVIS, 0))
	var torso := hips * Transform3D(tilt, Vector3.ZERO)
	var pose: Array[Transform3D] = []
	pose.resize(PIECE_MASS.size())
	pose[TORSO] = torso * Transform3D(Basis(), Vector3(0, height * 0.5, 0))
	var forward := root.basis * Vector3.FORWARD
	for side_index in 2:
		var side := -1.0 if side_index == 0 else 1.0
		var hip := hips * (tilt * Vector3(side * HIP_X, -0.3, 0.0))
		var ankle := root * Vector3(side * (HIP_X + 0.3), 0.6, 0.0)
		var knee := MechLeg.joint(hip, ankle, THIGH, SHIN, forward)
		pose[THIGH_LEFT if side < 0.0 else THIGH_RIGHT] = _segment(hip, knee, forward)
		pose[SHIN_LEFT if side < 0.0 else SHIN_RIGHT] = _segment(knee, ankle, forward)
		var shoulder := torso * Vector3(side * (MechTorso.WIDTH * 0.5 + 1.3), MechTorso.floor_y(1) + 1.6, -0.6)
		var fist := torso * Vector3(side * (MechTorso.WIDTH * 0.5 + 1.3) - side * 1.8, MechTorso.floor_y(1) + 1.9, -6.1)
		var elbow := MechLeg.joint(shoulder, fist, UPPER_ARM, FOREARM, torso.basis * Vector3(side, -0.8, 0.5))
		pose[UPPER_LEFT if side < 0.0 else UPPER_RIGHT] = _segment(shoulder, elbow, Vector3.UP)
		pose[FOREARM_LEFT if side < 0.0 else FOREARM_RIGHT] = _segment(elbow, fist, Vector3.UP)
	return pose


## Una pieza larga entre dos puntos: su −Z va de `from` a `to` y su +Y, hacia `up`.
static func _segment(from: Vector3, to: Vector3, up: Vector3) -> Transform3D:
	var along := (to - from).normalized()
	var hint := up if absf(along.dot(up.normalized())) < 0.95 else Vector3.BACK
	return Transform3D(Basis.looking_at(along, hint), (from + to) * 0.5)


func _place_standing(_weight: float) -> void:
	var pose := _standing_pose(_shown_lean)
	for i in _pieces.size():
		_pieces[i].global_transform = pose[i]


## ── CADA PASO ───────────────────────────────────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	var above := PELVIS + MechTorso.top_y() + 4.0 if state != State.DOWN else 10.0
	_label.global_position = body_position() + Vector3(0, above, 0)
	_label.text = "%s · inclinación %d %% (pico %d %%)\núltimo golpe %.1f m/s · caídas %d" % [state_name(),
		roundi(lean.length() * 100.0), roundi(peak_lean * 100.0), last_hit, falls]
	match state:
		State.STANDING:
			_measure_hit()
			_spring(delta)
			_brake(delta)
			_shown_lean = _shown_lean.lerp(lean, 1.0 - exp(-14.0 * delta))
			_place_standing(1.0)
			if _fall_in >= 0.0:
				_fall_in -= delta
				if _fall_in < 0.0:
					_fall()
		State.DOWN:
			_clock += delta
			if _clock >= DOWN_TIME:
				_start_rising()
		State.RISING:
			_clock += delta
			var share := ease(clampf(_clock / RISE_TIME, 0.0, 1.0), -2.0)
			var pose := _standing_pose(Vector2.ZERO)
			for i in _pieces.size():
				_pieces[i].global_transform = _fallen[i].interpolate_with(pose[i], share)
			if _clock >= RISE_TIME:
				_finish_rising()


## EL GOLPE: lo que cambió la velocidad desde el paso anterior sin que lo pidiera ella (su freno ya está descontado:
## se mide contra la velocidad que dejó ella misma). La gravedad y el piso son verticales y no cuentan.
func _measure_hit() -> void:
	var now := _body.linear_velocity
	var change := now - _velocity_after
	var flat := Vector3(change.x, 0.0, change.z)
	if flat.length() <= HIT_NOISE:
		return
	last_hit = flat.length()
	var local := Basis(Vector3.UP, _yaw).inverse() * flat
	var add := Vector2(local.x, -local.z) * LEAN_PER_MS / _firmness(local)
	lean = (lean + add).limit_length(1.0)
	_fall_push = flat
	peak_lean = maxf(peak_lean, lean.length())
	if add.length() >= FALL_AT:
		# Un golpe seco que solo ya pasa el umbral: cae en el acto.
		_fall()
	elif lean.length() >= FALL_AT and _fall_in < 0.0:
		_fall_in = FALL_WARNING


## La firmeza en la dirección del golpe: el peso sobre el de referencia por la estabilidad de ese lado (mezclada entre
## costado y adelante o atrás según el golpe; −Z es el frente, así que z < 0 es empujada hacia adelante: le pegaron de
## atrás).
func _firmness(local: Vector3) -> float:
	var ax := absf(local.x)
	var az := absf(local.z)
	var total := ax + az
	var stability := STABILITY_SIDEWAYS
	if total > 0.001:
		var side_share := ax / total
		var along := STABILITY_FORWARD if local.z < 0.0 else STABILITY_BACKWARD
		stability = STABILITY_SIDEWAYS * side_share + along * (1.0 - side_share)
	return maxf(MASS / REFERENCE_MASS * stability, 0.05)


func _spring(delta: float) -> void:
	var accel := -lean * STIFFNESS * SPRING_SCALE - _lean_speed * DAMPING * DAMP_SCALE
	_lean_speed += accel * delta
	lean += _lean_speed * delta
	if lean.length() < 0.02 and _lean_speed.length() < 0.02:
		peak_lean = 0.0


## Parada, sus pies la frenan. Lo que deja es contra lo que se mide el próximo golpe.
func _brake(delta: float) -> void:
	var velocity := _body.linear_velocity
	var flat := Vector3(velocity.x, 0.0, velocity.z).move_toward(Vector3.ZERO, BRAKE * delta)
	_body.linear_velocity = Vector3(flat.x, velocity.y, flat.z)
	_velocity_after = _body.linear_velocity


## ── LA CAÍDA ────────────────────────────────────────────────────────────────────────────────────────────────────

func _fall() -> void:
	if state != State.STANDING:
		return
	state = State.DOWN
	_clock = 0.0
	_fall_in = -1.0
	falls += 1
	var velocity := _body.linear_velocity
	var push := _fall_push.normalized() * maxf(_fall_push.length(), 1.0)
	_body.freeze = true
	_body.collision_layer = 0
	_body.collision_mask = 0
	var top := PELVIS + MechTorso.top_y()
	var ground := _body.global_position.y
	for piece in _pieces:
		piece.collision_layer = 2
		piece.collision_mask = 1
		piece.freeze = false
		var height := clampf((piece.global_position.y - ground) / top, 0.0, 1.0)
		piece.linear_velocity = velocity + push * TOPPLE * height
		piece.angular_velocity = Vector3.ZERO
	_join(TORSO, THIGH_LEFT, _hip_point(-1.0), 70.0, 25.0, 35.0)
	_join(TORSO, THIGH_RIGHT, _hip_point(1.0), 70.0, 25.0, 35.0)
	_join(THIGH_LEFT, SHIN_LEFT, _end(THIGH_LEFT, THIGH), 110.0, 8.0, 8.0)
	_join(THIGH_RIGHT, SHIN_RIGHT, _end(THIGH_RIGHT, THIGH), 110.0, 8.0, 8.0)
	_join(TORSO, UPPER_LEFT, _start(UPPER_LEFT, UPPER_ARM), 80.0, 80.0, 80.0)
	_join(TORSO, UPPER_RIGHT, _start(UPPER_RIGHT, UPPER_ARM), 80.0, 80.0, 80.0)
	_join(UPPER_LEFT, FOREARM_LEFT, _end(UPPER_LEFT, UPPER_ARM), 120.0, 10.0, 10.0)
	_join(UPPER_RIGHT, FOREARM_RIGHT, _end(UPPER_RIGHT, UPPER_ARM), 120.0, 10.0, 10.0)
	lean = Vector2.ZERO
	_lean_speed = Vector2.ZERO
	_shown_lean = Vector2.ZERO
	fell.emit()


func _start(index: int, length: float) -> Vector3:
	return _pieces[index].global_transform * Vector3(0, 0, length * 0.5)


func _end(index: int, length: float) -> Vector3:
	return _pieces[index].global_transform * Vector3(0, 0, -length * 0.5)


func _hip_point(side: float) -> Vector3:
	return _start(THIGH_LEFT if side < 0.0 else THIGH_RIGHT, THIGH)


## UNA ARTICULACIÓN como las del muñeco de character-parametric (`RagdollUtil._create_joint`): sin juego lineal, con
## topes de giro (grados, en los ejes de la meca: x de costado, y vertical, z adelante) y un resorte en cada eje (el
## músculo) que la tira hacia como estaba parada. Los músculos van por la masa: con los números de una persona, un
## cuerpo de 3 t ni los sentiría.
func _join(a: int, b: int, at: Vector3, swing: float, twist: float, roll: float) -> void:
	var joint := Generic6DOFJoint3D.new()
	joint.top_level = true
	add_child(joint)
	joint.global_transform = Transform3D(Basis(Vector3.UP, _yaw), at)
	joint.node_a = joint.get_path_to(_pieces[a])
	joint.node_b = joint.get_path_to(_pieces[b])
	var muscle := 30.0 * (PIECE_MASS[b] as float)
	for axis in 3:
		var limit := deg_to_rad([swing, twist, roll][axis] as float)
		_axis_param(joint, axis, Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, 0.0)
		_axis_param(joint, axis, Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, 0.0)
		_axis_param(joint, axis, Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, -limit)
		_axis_param(joint, axis, Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, limit)
		_axis_param(joint, axis, Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS, muscle)
		_axis_param(joint, axis, Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING, muscle * 0.15)
		_axis_flag(joint, axis, Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, true)
		_axis_flag(joint, axis, Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
		_axis_flag(joint, axis, Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, true)
	_joints.append(joint)


static func _axis_param(joint: Generic6DOFJoint3D, axis: int, param: Generic6DOFJoint3D.Param, value: float) -> void:
	match axis:
		0:
			joint.set_param_x(param, value)
		1:
			joint.set_param_y(param, value)
		_:
			joint.set_param_z(param, value)


static func _axis_flag(joint: Generic6DOFJoint3D, axis: int, flag: Generic6DOFJoint3D.Flag, value: bool) -> void:
	match axis:
		0:
			joint.set_flag_x(flag, value)
		1:
			joint.set_flag_y(flag, value)
		_:
			joint.set_flag_z(flag, value)


## ── LEVANTARSE ──────────────────────────────────────────────────────────────────────────────────────────────────

func _start_rising() -> void:
	state = State.RISING
	_clock = 0.0
	for joint in _joints:
		joint.queue_free()
	_joints.clear()
	_fallen.clear()
	for piece in _pieces:
		_fallen.append(piece.global_transform)
		piece.freeze = true
		piece.collision_layer = 0
		piece.collision_mask = 0
	# El cuerpo, debajo de donde quedó el torso, mirando para el mismo lado que antes.
	var torso := _pieces[TORSO].global_position
	_body.global_transform = Transform3D(Basis(Vector3.UP, _yaw), Vector3(torso.x, 0.0, torso.z))
	_body.linear_velocity = Vector3.ZERO


func _finish_rising() -> void:
	state = State.STANDING
	_clock = 0.0
	_body.freeze = false
	_body.collision_layer = 1
	_body.collision_mask = 1
	_body.linear_velocity = Vector3.ZERO
	_velocity_after = Vector3.ZERO
	lean = Vector2.ZERO
	_lean_speed = Vector2.ZERO
	peak_lean = 0.0
	_place_standing(1.0)
	stood_up.emit()


## Dónde está ahora (el cuerpo, en el suelo), para la prueba y la cámara.
func body_position() -> Vector3:
	return _body.global_position if state != State.DOWN else _pieces[TORSO].global_position


func state_name() -> String:
	return ["parada", "EN EL SUELO", "levantándose"][state]
