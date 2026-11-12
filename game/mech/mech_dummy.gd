class_name MechDummy
extends Node3D

## LA MECA DE EQUILIBRIO: EL CUERPO DE LA MECA (MechBody: pies, piernas, pelvis, torso y brazos en guardia, el mismo de
## la meca de pelea) que sólo se tambalea, se cae y se levanta. No camina ni pega. Su equilibrio es EL DE LOS PERSONAJES
## DE CHARACTER-PARAMETRIC (`CharacterRigidBody3D` y `RagdollUtil` de allá; ver su docs/technical/characters.md), con dos
## agregados que se prenden y apagan en el panel de la fila (F1 en la fila Equilibrio, ver BalancePanel; lo pidió el usuario
## el 11/11/2026: «nunca es como que le tiro algo y se echa para atrás y como que recobra el equilibrio»):
##
##   1. EL CUERPO ES FÍSICO DE VERDAD: un RigidBody3D parado (no gira), sin fricción, que frena solo (`brake`). Lo que lo
##      golpea (una bola, ver TestBall) le cambia la velocidad: la meca se corre.
##   2. EL GOLPE SE MIDE: cada paso, lo que cambió la velocidad sin que ella lo pidiera. Debajo de `HIT_NOISE` no cuenta.
##   3. LA INCLINACIÓN: un resorte de dos ejes (`lean`; rigidez y amortiguación). Cada golpe vale Δv × `lean_per_ms` /
##      firmeza; la FIRMEZA es el peso sobre el de referencia por la estabilidad del lado de donde viene.
##        · Como allá (`hit_pushes` apagado): el golpe SE SUMA A LA INCLINACIÓN, de una; el resorte la devuelve.
##        · EMPUJA (`hit_pushes`, el agregado): el golpe se suma a la VELOCIDAD de la inclinación (× `push_rate`): la meca
##          se va inclinando, llega a su punto y vuelve; se ve el envión.
##   4. LOS PASOS (`steps`, el agregado): pasada `step_at`, da un paso hacia donde se va (un pie, después el otro): la
##      base se corre debajo del cuerpo y le saca inclinación (`step_catch` por paso). Mientras alcancen los pasos, se
##      recupera trastabillando; si no, se cae.
##   5. LA CAÍDA, al pasar `fall_at`: si un golpe solo ya lo pasa (como allá), en el acto; si se fue acumulando, se ve
##      inclinarse y cae `fall_warning` después. Se cae COMO UN MUÑECO DE VERDAD: cada parte es un cuerpo, unidas por
##      articulaciones con resortes (los músculos) y topes, que salen con la velocidad que traía, más (esto no está allá,
##      que es de una persona) cuanto más altas, como si girara sobre los pies (`topple`).
##   6. LEVANTARSE: en el suelo `down_time`; después cada parte va de donde quedó a la postura parada en `rise_time`.
##
## Los números de allá son de una persona de 60 kg: acá la firmeza 1 es la de esta meca (`REFERENCE_MASS` = su masa), y
## el resorte va más lento (`spring_scale`, `damp_scale`). Todos se tocan en el panel de la fila (MechBalanceSettings) y
## valen para todas las mecas de equilibrio.

signal fell()
signal stood_up()

const MASS := 50000.0
const REFERENCE_MASS := 50000.0
const HIT_NOISE := 0.3

## LAS PERILLAS: las de MechBalanceSettings (una sola copia para todas, la del panel F1 de la fila Equilibrio), por `_k`.
var _k: MechBalanceSettings:
	get:
		return MechBalanceSettings.current

enum State { STANDING, DOWN, RISING }

var state := State.STANDING
## La inclinación (x a la derecha, y adelante, en el espacio de la meca), lo que tumba al pasar `fall_at`.
var lean := Vector2.ZERO
## El último golpe (m/s), la inclinación más grande desde que estaba quieta y lo que pasó, para mirar.
var last_hit := 0.0
var peak_lean := 0.0
var falls := 0
var steps_taken := 0

var _body: RigidBody3D = null
var _yaw := 0.0
var _lean_speed := Vector2.ZERO
var _shown_lean := Vector2.ZERO
var _velocity_after := Vector3.ZERO
var _fall_in := -1.0
var _fall_push := Vector3.ZERO
var _clock := 0.0
var _parts: Array[RigidBody3D] = []
var _fallen: Array[Transform3D] = []
var _joints: Array[Generic6DOFJoint3D] = []
var _label: Label3D = null
## LOS PIES, en el piso del mundo (se quedan donde pisaron), y el paso que se está dando.
var _feet: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _step := {}


func _ready() -> void:
	_yaw = global_rotation.y
	var root := _root_at(global_position)
	_feet = [MechBody.foot_rest(root, -1.0), MechBody.foot_rest(root, 1.0)]
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
	# Nace donde vive (ver Mech, NACE DONDE VIVE).
	_body.transform = root
	var height := MechTorso.top_y()
	Clay.shape_box(_body, Vector3(MechTorso.WIDTH, height, MechTorso.DEPTH), Vector3(0, MechBody.WAIST + height * 0.5, 0))
	Clay.shape_box(_body, Vector3(MechBody.STANCE_X * 2.0 + 2.0, MechBody.WAIST, 3.4), Vector3(0, MechBody.WAIST * 0.5, 0))
	add_child(_body)
	_build_parts()
	_place_standing()
	_label = Label3D.new()
	_label.top_level = true
	_label.font_size = 64
	_label.pixel_size = 0.02
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.outline_size = 14
	_label.modulate = Color(1.0, 0.95, 0.6)
	add_child(_label)


func _root_at(ground: Vector3) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, _yaw), ground)


## ── LAS PARTES: el dibujo parado y el muñeco caído son los mismos cuerpos ───────────────────────────────────────────
## Parada, son cinemáticas, no chocan (choca el cuerpo) y van adonde dice la postura (MechBody). Caída, son cuerpos sueltos
## que chocan con el mundo y no entre ellas (como el muñeco de character-parametric: capa 2, que mira la 1).

enum Part { PELVIS, TORSO, THIGH_LEFT, SHIN_LEFT, FOOT_LEFT, THIGH_RIGHT, SHIN_RIGHT, FOOT_RIGHT, UPPER_LEFT,
	FOREARM_LEFT, UPPER_RIGHT, FOREARM_RIGHT }
const PART_MASS := [6000.0, 22000.0, 3000.0, 2500.0, 1000.0, 3000.0, 2500.0, 1000.0, 1500.0, 1500.0, 1500.0, 1500.0]


func _build_parts() -> void:
	var pose := _standing_pose(Vector2.ZERO)
	for i in PART_MASS.size():
		var part := RigidBody3D.new()
		part.name = String(Part.keys()[i]).capitalize()
		part.top_level = true
		part.mass = PART_MASS[i]
		part.continuous_cd = true
		part.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		part.freeze = true
		part.collision_layer = 0
		part.collision_mask = 0
		part.transform = pose[i]
		add_child(part)
		_parts.append(part)
	var height := MechTorso.top_y()
	Clay.solid(_parts[Part.PELVIS], MechBody.PELVIS_SIZE, Vector3.ZERO, Clay.METAL.darkened(0.15))
	var torso := _parts[Part.TORSO]
	Clay.solid(torso, Vector3(MechTorso.WIDTH, height, MechTorso.DEPTH), Vector3.ZERO, Clay.METAL)
	for floor_index in MechTorso.FLOORS:
		var y := MechTorso.floor_y(floor_index) + 0.9 + 0.95 - height * 0.5
		Clay.box(torso, Vector3(MechTorso.WIDTH - 0.6, 1.9, 0.1), Vector3(0, y, -MechTorso.DEPTH * 0.5 - 0.02), Clay.GLASS)
	var thickness := MechBody.LEG_THICKNESS
	for i: int in [Part.THIGH_LEFT, Part.THIGH_RIGHT]:
		Clay.solid(_parts[i], Vector3(thickness, thickness, MechBody.THIGH), Vector3.ZERO, Clay.METAL.darkened(0.1))
	for i: int in [Part.SHIN_LEFT, Part.SHIN_RIGHT]:
		Clay.solid(_parts[i], Vector3(thickness * 0.9, thickness * 0.9, MechBody.SHIN), Vector3.ZERO,
			Clay.METAL.darkened(0.25))
	for i: int in [Part.FOOT_LEFT, Part.FOOT_RIGHT]:
		Clay.solid(_parts[i], MechBody.FOOT_SIZE, Vector3.ZERO, Clay.DARK)
	for i: int in [Part.UPPER_LEFT, Part.UPPER_RIGHT]:
		Clay.solid(_parts[i], Vector3(MechBody.ARM_THICKNESS, MechBody.ARM_THICKNESS, MechBody.UPPER_ARM), Vector3.ZERO,
			Clay.METAL.darkened(0.1))
	for i: int in [Part.FOREARM_LEFT, Part.FOREARM_RIGHT]:
		Clay.solid(_parts[i], Vector3(MechBody.FOREARM_THICKNESS, MechBody.FOREARM_THICKNESS, MechBody.FOREARM),
			Vector3.ZERO, Clay.METAL.darkened(0.25))
		Clay.solid(_parts[i], Vector3(2.0, 2.0, 2.2), Vector3(0, 0, -MechBody.FOREARM * 0.5), Clay.RED)


## LA POSTURA PARADA (MechBody): dónde va cada parte, con el cuerpo inclinado `shown` (la inclinación que se ve) y los
## pies donde pisan (`_feet`, y el que da el paso, en el aire).
func _standing_pose(shown: Vector2) -> Array[Transform3D]:
	var root := _root_at(_body.global_position if is_instance_valid(_body) and _body.is_inside_tree()
		else global_position)
	var waist := MechBody.waist(root, MechBody.WAIST, MechBody.tilt(shown * deg_to_rad(_k.lean_angle)))
	var torso := MechBody.torso(waist, 0.0)
	var pose: Array[Transform3D] = []
	pose.resize(PART_MASS.size())
	pose[Part.PELVIS] = MechBody.pelvis(waist)
	pose[Part.TORSO] = torso * Transform3D(Basis(), Vector3(0, MechTorso.top_y() * 0.5, 0))
	for side_index in 2:
		var side := -1.0 if side_index == 0 else 1.0
		var leg := MechBody.leg(MechBody.hip(waist, side), _foot_ground(side_index), root.basis)
		pose[Part.THIGH_LEFT if side < 0.0 else Part.THIGH_RIGHT] = leg["thigh"]
		pose[Part.SHIN_LEFT if side < 0.0 else Part.SHIN_RIGHT] = leg["shin"]
		pose[Part.FOOT_LEFT if side < 0.0 else Part.FOOT_RIGHT] = leg["foot"]
		var shoulder := torso * MechBody.shoulder_local(side)
		var fist := torso * (MechBody.shoulder_local(side) + MechBody.guard_local(side))
		var arm := MechBody.arm(shoulder, fist, side, torso.basis)
		pose[Part.UPPER_LEFT if side < 0.0 else Part.UPPER_RIGHT] = arm["upper"]
		pose[Part.FOREARM_LEFT if side < 0.0 else Part.FOREARM_RIGHT] = arm["forearm"]
	return pose


## Dónde está el pie `index` (0 el izquierdo): donde pisó, o en el aire si es el que da el paso.
func _foot_ground(index: int) -> Vector3:
	if _step.is_empty() or int(_step["foot"]) != index:
		return _feet[index]
	var share := clampf(float(_step["clock"]) / float(_step["time"]), 0.0, 1.0)
	var from: Vector3 = _step["from"]
	var to: Vector3 = _step["to"]
	return from.lerp(to, share) + Vector3.UP * sin(share * PI) * Mech.LIFT


func _place_standing() -> void:
	var pose := _standing_pose(_shown_lean)
	for i in _parts.size():
		_parts[i].global_transform = pose[i]


## ── CADA PASO ───────────────────────────────────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	var above := MechBody.WAIST + MechTorso.top_y() + 4.0 if state != State.DOWN else 10.0
	_label.global_position = body_position() + Vector3(0, above, 0)
	_label.text = "%s · inclinación %d %% (pico %d %%)\núltimo golpe %.1f m/s · pasos %d · caídas %d" % [state_name(),
		roundi(lean.length() * 100.0), roundi(peak_lean * 100.0), last_hit, steps_taken, falls]
	match state:
		State.STANDING:
			_measure_hit()
			_spring(delta)
			_stepping(delta)
			_brake(delta)
			_shown_lean = _shown_lean.lerp(lean, 1.0 - exp(-14.0 * delta))
			_place_standing()
			if _fall_in >= 0.0:
				_fall_in -= delta
				if _fall_in < 0.0:
					_fall()
		State.DOWN:
			_clock += delta
			if _clock >= _k.down_time:
				_start_rising()
		State.RISING:
			_clock += delta
			var share := ease(clampf(_clock / _k.rise_time, 0.0, 1.0), -2.0)
			var pose := _standing_pose(Vector2.ZERO)
			for i in _parts.size():
				_parts[i].global_transform = _fallen[i].interpolate_with(pose[i], share)
			if _clock >= _k.rise_time:
				_finish_rising()


## EL GOLPE: lo que cambió la velocidad desde el paso anterior sin que lo pidiera ella (su freno y sus pasos ya están
## descontados: se mide contra la velocidad que dejó ella misma). La gravedad y el piso son verticales y no cuentan.
func _measure_hit() -> void:
	var now := _body.linear_velocity
	var change := now - _velocity_after
	var flat := Vector3(change.x, 0.0, change.z)
	if flat.length() <= HIT_NOISE:
		return
	last_hit = flat.length()
	var local := Basis(Vector3.UP, _yaw).inverse() * flat
	var add := Vector2(local.x, -local.z) * _k.lean_per_ms / _firmness(local)
	_fall_push = flat
	if _k.hit_pushes:
		_lean_speed += add * _k.push_rate
		return
	lean = (lean + add).limit_length(1.0)
	peak_lean = maxf(peak_lean, lean.length())
	if add.length() >= _k.fall_at:
		# Un golpe seco que solo ya pasa el umbral: cae en el acto.
		_fall()
	elif lean.length() >= _k.fall_at and _fall_in < 0.0:
		_fall_in = _k.fall_warning


## La firmeza en la dirección del golpe: el peso sobre el de referencia por la estabilidad de ese lado (mezclada entre
## costado y adelante o atrás según el golpe; −Z es el frente, así que z < 0 es empujada hacia adelante: le pegaron de
## atrás).
func _firmness(local: Vector3) -> float:
	var ax := absf(local.x)
	var az := absf(local.z)
	var total := ax + az
	var stability := _k.stability_sideways
	if total > 0.001:
		var side_share := ax / total
		var along := _k.stability_forward if local.z < 0.0 else _k.stability_backward
		stability = _k.stability_sideways * side_share + along * (1.0 - side_share)
	return maxf(MASS / REFERENCE_MASS * stability, 0.05)


func _spring(delta: float) -> void:
	var accel := -lean * _k.stiffness * _k.spring_scale - _lean_speed * _k.damping * _k.damp_scale
	_lean_speed += accel * delta
	lean += _lean_speed * delta
	peak_lean = maxf(peak_lean, lean.length())
	if lean.length() >= _k.fall_at and _fall_in < 0.0:
		_fall_in = _k.fall_warning
	if lean.length() < 0.02 and _lean_speed.length() < 0.02 and _step.is_empty():
		peak_lean = 0.0


## LOS PASOS (ver arriba): pasada `step_at`, un pie va hacia donde se inclina, la base lo sigue y la inclinación baja; al
## pisar, el otro pie vuelve a su lugar al lado. Mientras dure el paso el cuerpo lo lleva su paso, no su freno.
func _stepping(delta: float) -> void:
	if not _step.is_empty():
		_step["clock"] = float(_step["clock"]) + delta
		var share := delta / float(_step["time"])
		if bool(_step["leading"]):
			lean -= (_step["catch"] as Vector2) * share
			_lean_speed *= exp(-3.0 * delta)
		if float(_step["clock"]) >= float(_step["time"]):
			_feet[int(_step["foot"])] = _step["to"]
			var leading := bool(_step["leading"])
			_step = {}
			if leading:
				_follow_step()
		return
	if _k.steps and lean.length() >= _k.step_at and lean.length() < _k.fall_at:
		_lead_step()


## EL PASO QUE MANDA: hacia donde se inclina, más largo cuanto más se inclina. Va el pie de ese lado (o, si es derecho
## adelante o atrás, el que quedó más lejos de ahí).
func _lead_step() -> void:
	var toward_local := lean.normalized()
	var toward := Basis(Vector3.UP, _yaw) * Vector3(toward_local.x, 0.0, -toward_local.y)
	var length := _k.step_length * clampf(lean.length() / _k.fall_at, 0.4, 1.0)
	var foot := 0 if toward_local.x < -0.3 else (1 if toward_local.x > 0.3 else
		(0 if _feet[0].dot(toward) < _feet[1].dot(toward) else 1))
	var side := -1.0 if foot == 0 else 1.0
	var new_root := _root_at(_body.global_position + toward * length)
	_step = {"foot": foot, "from": _feet[foot], "to": MechBody.foot_rest(new_root, side), "clock": 0.0,
		"time": _k.step_time, "leading": true, "catch": toward_local * minf(_k.step_catch, lean.length()),
		"move": toward * length / _k.step_time}
	steps_taken += 1


## EL OTRO PIE vuelve al lado, debajo de la base nueva.
func _follow_step() -> void:
	var foot := 0 if (_feet[0] - _body.global_position).length() > (_feet[1] - _body.global_position).length() else 1
	var other := 1 - foot
	var side := -1.0 if foot == 0 else 1.0
	var root := _root_at(_body.global_position)
	var target := MechBody.foot_rest(root, side)
	# Al lado del que pisó, no debajo del cuerpo: así queda parada sobre los dos.
	target += _feet[other] - MechBody.foot_rest(root, -side)
	target.y = 0.0
	if target.distance_to(_feet[foot]) < 0.3:
		return
	_step = {"foot": foot, "from": _feet[foot], "to": target, "clock": 0.0, "time": _k.step_time * 0.7,
		"leading": false, "catch": Vector2.ZERO, "move": Vector3.ZERO}


## Parada, sus pies la frenan; dando el paso que manda, la lleva el paso. Lo que deja es contra lo que se mide el
## próximo golpe.
func _brake(delta: float) -> void:
	var velocity := _body.linear_velocity
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	if not _step.is_empty() and bool(_step["leading"]):
		flat = flat.move_toward(_step["move"] as Vector3, _k.brake * 3.0 * delta)
	else:
		flat = flat.move_toward(Vector3.ZERO, _k.brake * delta)
	_body.linear_velocity = Vector3(flat.x, velocity.y, flat.z)
	_velocity_after = _body.linear_velocity


## ── LA CAÍDA ────────────────────────────────────────────────────────────────────────────────────────────────────

func _fall() -> void:
	if state != State.STANDING:
		return
	state = State.DOWN
	_clock = 0.0
	_fall_in = -1.0
	_step = {}
	falls += 1
	var velocity := _body.linear_velocity
	var direction := _fall_push.normalized()
	if direction.length_squared() < 0.01:
		var toward := lean.normalized()
		direction = Basis(Vector3.UP, _yaw) * Vector3(toward.x, 0.0, -toward.y)
	var push := direction * maxf(_fall_push.length(), 1.0)
	_body.freeze = true
	_body.collision_layer = 0
	_body.collision_mask = 0
	var top := MechBody.WAIST + MechTorso.top_y()
	var ground := _body.global_position.y
	for part in _parts:
		part.collision_layer = 2
		part.collision_mask = 1
		part.freeze = false
		var height := clampf((part.global_position.y - ground) / top, 0.0, 1.0)
		part.linear_velocity = velocity + push * _k.topple * height
		part.angular_velocity = Vector3.ZERO
	var pelvis := _parts[Part.PELVIS]
	_join(Part.PELVIS, Part.TORSO, pelvis.global_transform * Vector3(0, MechBody.PELVIS_SIZE.y * 0.5, 0), 25.0, 30.0, 25.0)
	for side_index in 2:
		var thigh: int = Part.THIGH_LEFT if side_index == 0 else Part.THIGH_RIGHT
		var shin: int = Part.SHIN_LEFT if side_index == 0 else Part.SHIN_RIGHT
		var foot: int = Part.FOOT_LEFT if side_index == 0 else Part.FOOT_RIGHT
		var upper: int = Part.UPPER_LEFT if side_index == 0 else Part.UPPER_RIGHT
		var forearm: int = Part.FOREARM_LEFT if side_index == 0 else Part.FOREARM_RIGHT
		_join(Part.PELVIS, thigh, _start(thigh, MechBody.THIGH), 70.0, 25.0, 35.0)
		_join(thigh, shin, _end(thigh, MechBody.THIGH), 110.0, 8.0, 8.0)
		_join(shin, foot, _end(shin, MechBody.SHIN), 35.0, 10.0, 20.0)
		_join(Part.TORSO, upper, _start(upper, MechBody.UPPER_ARM), 80.0, 80.0, 80.0)
		_join(upper, forearm, _end(upper, MechBody.UPPER_ARM), 120.0, 10.0, 10.0)
	lean = Vector2.ZERO
	_lean_speed = Vector2.ZERO
	_shown_lean = Vector2.ZERO
	fell.emit()


func _start(index: int, length: float) -> Vector3:
	return _parts[index].global_transform * Vector3(0, 0, length * 0.5)


func _end(index: int, length: float) -> Vector3:
	return _parts[index].global_transform * Vector3(0, 0, -length * 0.5)


## UNA ARTICULACIÓN como las del muñeco de character-parametric (`RagdollUtil._create_joint`): sin juego lineal, con
## topes de giro (grados, en los ejes de la meca: x de costado, y vertical, z adelante) y un resorte en cada eje (el
## músculo) que la tira hacia como estaba parada. Los músculos van por la masa: con los números de una persona, un
## cuerpo de 3 t ni los sentiría.
func _join(a: int, b: int, at: Vector3, swing: float, twist: float, roll: float) -> void:
	var joint := Generic6DOFJoint3D.new()
	joint.top_level = true
	add_child(joint)
	joint.global_transform = Transform3D(Basis(Vector3.UP, _yaw), at)
	joint.node_a = joint.get_path_to(_parts[a])
	joint.node_b = joint.get_path_to(_parts[b])
	var muscle := 30.0 * (PART_MASS[b] as float)
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
	for part in _parts:
		_fallen.append(part.global_transform)
		part.freeze = true
		part.collision_layer = 0
		part.collision_mask = 0
	# El cuerpo, debajo de donde quedó el torso, mirando para el mismo lado que antes; los pies, a su lado.
	var torso := _parts[Part.TORSO].global_position
	_body.global_transform = _root_at(Vector3(torso.x, 0.0, torso.z))
	_body.linear_velocity = Vector3.ZERO
	var root := _root_at(Vector3(torso.x, 0.0, torso.z))
	_feet = [MechBody.foot_rest(root, -1.0), MechBody.foot_rest(root, 1.0)]


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
	_place_standing()
	stood_up.emit()


## Dónde está ahora (el cuerpo, en el suelo), para la prueba y la cámara.
func body_position() -> Vector3:
	return _body.global_position if state != State.DOWN else _parts[Part.TORSO].global_position


func state_name() -> String:
	return ["parada", "EN EL SUELO", "levantándose"][state]


## ── CUÁNTO HAY QUE EMPUJARLA ─────────────────────────────────────────────────────────────────────────────────────
## Lo que la hace llegar a la inclinación `target` con un golpe de frente, sin contar los pasos: el empuje (N·s) de algo
## que llega a `speed` m/s y se queda pegado. Sale de las perillas de ahora (ver MechBalanceSettings): con el empuje
## prendido, la inclinación más alta del resorte por cada unidad de golpe se calcula paso a paso (como la corre
## `_spring`); apagado, el golpe es la inclinación. Lo usa la bola (ver TestBall) para que sus fuerzas sigan a los
## umbrales de la meca (lo pidió el usuario el 11/11/2026: «que sean acordes al threshold de la nave»).
static func push_for_lean(target: float, speed: float) -> float:
	var settings := MechBalanceSettings.current
	var per_hit := 1.0
	if settings.hit_pushes:
		per_hit = settings.push_rate * _spring_peak(1.0, 1.0 / 240.0)
	var hit := target / maxf(per_hit, 0.0001)
	var delta_v := hit * maxf(MASS / REFERENCE_MASS * settings.stability_backward, 0.05) / settings.lean_per_ms
	# Algo de masa m a `speed` que se queda pegado a la meca: Δv = m·speed / (MASS + m).
	if delta_v >= speed:
		return INF
	return MASS * delta_v * speed / (speed - delta_v)


## La inclinación más alta del resorte que arranca quieto con velocidad `kick`, corrido como en `_spring`.
static func _spring_peak(kick: float, step: float) -> float:
	var settings := MechBalanceSettings.current
	var lean_now := 0.0
	var speed_now := kick
	var peak := 0.0
	for i in 2400:
		speed_now += (-lean_now * settings.stiffness * settings.spring_scale
			- speed_now * settings.damping * settings.damp_scale) * step
		lean_now += speed_now * step
		peak = maxf(peak, lean_now)
		if speed_now < 0.0:
			break
	return peak
