class_name MuscleArm
extends Node3D

## UN BRAZO CON MÚSCULOS: el primer paso de los brazos físicos de la meca (12/11/2026), en su propia fila para tunearlo
## solo. El usuario: «deberíamos tomar el approach de el hueso que intenta hacer algo y que todo el cuerpo, al menos los
## brazos, intentan copiar eso… con músculos y con fuerzas, como… el Puppet Master de Unity»; «en el fondo el Puppet
## Master está tratando de simular lo que hace la IK, o sea, no es que nos vamos a deshacer de la IK».
##
## DOS CAPAS, como PuppetMaster:
##   · LA POSE QUE SE PIDE: dónde quiere el puño (en guardia, a lo largo de una piña, o donde lo lleva el mouse) y, de
##     ahí, cómo van el brazo y el antebrazo: la IK del cuerpo de la meca (MechBody.arm), la misma del dibujo.
##   · EL CUERPO FÍSICO: el BRAZO y el ANTEBRAZO (con la mano en la punta) son cuerpos sueltos. EL HOMBRO es una bola
##     (gira para cualquier lado) y EL CODO una BISAGRA (sólo dobla), como los de verdad. Un MÚSCULO por articulación,
##     con un resorte y un freno (`muscle_kp`, `muscle_kd`) y con FUERZA TOPE (`muscle_max`): el del HOMBRO gira el
##     brazo hacia la orientación pedida —incluido el giro sobre su largo, que es el que lleva el antebrazo de costado—;
##     el del CODO sólo dobla, sobre el eje de su bisagra, y empuja al brazo para el otro lado.
##     *El codo empezó siendo una bola: el músculo del antebrazo hacía girar al brazo sobre sí mismo sin que nada lo
##     frenara, al tope del motor de física (12/11/2026).*
## De ahí sale lo que antes eran reglas a mano en el puño de la meca de pelea: si algo lo traba, se queda ahí empujando
## con su fuerza; si le pegan, cede y vuelve; la fuerza de la piña es la velocidad a la que llegó la mano.
##
## LAS PIÑAS (`punch`): cada una, unos pocos puntos por los que se pide que pase el puño, con sus tiempos (se arma atrás,
## pega, se queda un instante y vuelve a la guardia). A MANO (poseído): el mouse lleva el puño de costado y arriba y
## abajo, y W/S adelante y atrás.
##
## Las perillas, en MuscleArmSettings (el panel F1 de su fila).

enum Punch { NONE, STRAIGHT, HOOK, UPPERCUT, HAMMER }

const NAMES := ["en guardia", "directo", "gancho", "uppercut", "desde arriba"]
const UPPER_MASS := 2200.0
const FOREARM_MASS := 2000.0
const THICKNESS := 1.5
## EL PUÑO, en guardia, desde el hombro, en el espacio de lo que lo sostiene (`x` hacia afuera del cuerpo; adentro es
## negativo).
const GUARD := Vector3(-1.5, -2.6, -6.2)
## LAS PIÑAS: por dónde se pide que pase el puño (como `GUARD`) y en cuánto llega a cada punto desde el anterior (s).
const PUNCHES := {
	Punch.STRAIGHT: [[0.45, Vector3(-0.8, -1.8, -2.6)], [0.26, Vector3(-2.6, -0.6, -10.6)], [0.2, Vector3(-2.6, -0.6, -10.6)],
		[0.6, GUARD]],
	Punch.HOOK: [[0.5, Vector3(3.8, -1.2, -3.2)], [0.3, Vector3(-5.4, -0.8, -7.4)], [0.2, Vector3(-5.4, -0.8, -7.4)],
		[0.6, GUARD]],
	Punch.UPPERCUT: [[0.5, Vector3(-0.6, -6.8, -3.4)], [0.28, Vector3(-2.0, 3.6, -7.6)], [0.2, Vector3(-2.0, 3.6, -7.6)],
		[0.6, GUARD]],
	Punch.HAMMER: [[0.55, Vector3(-0.4, 6.6, -2.2)], [0.28, Vector3(-1.6, -5.0, -8.2)], [0.2, Vector3(-1.6, -5.0, -8.2)],
		[0.6, GUARD]],
}

## De qué lado va (−1 izquierdo, 1 derecho), lo que lo sostiene y dónde está el hombro en su espacio. Se ponen antes de
## agregarlo al árbol.
var side := 1.0
var anchor: PhysicsBody3D = null
var shoulder_local := Vector3.ZERO

var upper: RigidBody3D = null
var forearm: RigidBody3D = null
## Lo que se le pide ahora y lo que mide, para mirar: la piña, la velocidad de la mano (m/s) y la más alta de la última
## piña, y lo lejos que está la mano de donde se la pide (m).
var punching := Punch.NONE
var hand_speed := 0.0
var top_speed := 0.0
var off_target := 0.0
## A mano (poseído): por dónde corrió el puño el mouse, desde la guardia.
var manual := false

var _clock := 0.0
var _from := GUARD
var _offset := Vector3.ZERO
var _label: Label3D = null
var _chase_yaw := 0.0
var _hand: MechHand = null
## El eje de la bisagra del codo, en el mundo: sale del brazo y el antebrazo pedidos; con el brazo estirado no se puede
## calcular y queda el último.
var _hinge := Vector3.RIGHT


func _ready() -> void:
	name = "Brazo"
	add_to_group(SandboxPossession.GROUP)
	var base := anchor.global_transform
	var shoulder := base * shoulder_local
	var pose := _pose(shoulder, shoulder + base.basis * _local(GUARD), base.basis)
	upper = _piece("Brazo", UPPER_MASS, Vector3(THICKNESS, THICKNESS, MechBody.UPPER_ARM), pose["upper"],
		Clay.METAL.darkened(0.1))
	forearm = _piece("Antebrazo", FOREARM_MASS, Vector3(THICKNESS * 0.88, THICKNESS * 0.88, MechBody.FOREARM),
		pose["forearm"], Clay.METAL.darkened(0.2))
	# El hombro y el codo, esferas en la punta de arriba de cada pieza; la mano, en la de abajo del antebrazo, con su
	# forma de choque (el puño).
	Clay.sphere(upper, THICKNESS * 0.78, Vector3(0, 0, MechBody.UPPER_ARM * 0.5), MechBody.JOINT_COLOR)
	Clay.sphere(forearm, THICKNESS * 0.66, Vector3(0, 0, MechBody.FOREARM * 0.5), MechBody.JOINT_COLOR)
	# Sus dedos cierran para el lado que dobla el codo (el Y del antebrazo es el eje de la bisagra).
	_hand = MechHand.build(forearm, 1.0)
	_hand.position = Vector3(0, 0, -MechBody.FOREARM * 0.5)
	Clay.shape_box(forearm, Vector3(MechHand.PALM.x * 2.2, MechHand.PALM.y, MechHand.length() * 0.8),
		Vector3(0, 0, -MechBody.FOREARM * 0.5 - MechHand.length() * 0.4))
	# El hombro, una bola; el codo, una bisagra sobre su eje (el Z de la articulación).
	var ball := PinJoint3D.new()
	_join(ball, anchor, upper, Transform3D(Basis(), shoulder))
	var hinge := HingeJoint3D.new()
	_join(hinge, upper, forearm, Transform3D(Basis.looking_at(_hinge, (pose["upper"] as Transform3D).basis.z), pose["elbow"]))
	forearm.add_collision_exception_with(anchor)
	_label = Label3D.new()
	_label.top_level = true
	_label.font_size = 56
	_label.pixel_size = 0.02
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.outline_size = 12
	_label.modulate = Color(1.0, 0.95, 0.6)
	add_child(_label)


## UNA PIEZA: un cuerpo suelto, en el mundo, con su caja; nace donde va.
func _piece(piece_name: String, piece_mass: float, size: Vector3, at: Transform3D, color: Color) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.name = piece_name
	body.top_level = true
	body.mass = piece_mass
	body.can_sleep = false
	body.continuous_cd = true
	body.transform = at
	add_child(body)
	Clay.solid(body, size, Vector3.ZERO, color)
	# SU RESISTENCIA A GIRAR, que es muy distinta según el eje: de punta a punta, desde la articulación (una barra,
	# m·L²/3), y sobre su propio largo (casi nada). El músculo mide su fuerza con la de cada eje (ver `_muscle`).
	body.set_meta("across", piece_mass * size.z * size.z / 3.0)
	body.set_meta("along", piece_mass * (size.x * size.x + size.y * size.y) / 12.0)
	return body


## UNA ARTICULACIÓN entre dos piezas, en `at`; las dos dejan de chocar entre sí.
func _join(joint: Joint3D, first: PhysicsBody3D, second: PhysicsBody3D, at: Transform3D) -> void:
	joint.top_level = true
	add_child(joint)
	joint.global_transform = at
	joint.node_a = joint.get_path_to(first)
	joint.node_b = joint.get_path_to(second)


## LA POSE QUE SE PIDE, con el puño en `fist` (mundo): el codo y la muñeca salen de la IK del cuerpo de la meca
## (MechBody.arm); las dos piezas, con su −Z a lo largo y su Y sobre EL EJE DEL CODO (el que es perpendicular al brazo y
## al antebrazo): así el giro del brazo sobre su largo es el que pone al antebrazo donde va, como con una bisagra.
func _pose(shoulder: Vector3, fist: Vector3, torso: Basis) -> Dictionary:
	var arm := MechBody.arm(shoulder, fist, side, torso)
	var elbow: Vector3 = arm["elbow"]
	var wrist: Vector3 = arm["wrist"]
	var across := (elbow - shoulder).cross(wrist - elbow)
	if across.length() > 0.5:
		_hinge = across.normalized()
	return {
		"upper": Transform3D(_along(elbow - shoulder), (shoulder + elbow) * 0.5),
		"forearm": Transform3D(_along(wrist - elbow), (elbow + wrist) * 0.5),
		"elbow": elbow,
		"wrist": wrist,
	}


## La orientación de una pieza que va hacia `way`: su −Z para ahí y su Y lo más cerca del eje del codo.
func _along(way: Vector3) -> Basis:
	var back := -way.normalized()
	var up := (_hinge - back * _hinge.dot(back)).normalized()
	return Basis(up.cross(back), up, back)


func _exit_tree() -> void:
	manual = false


## ── LO QUE SE LE PIDE ────────────────────────────────────────────────────────────────────────────────────────────

## Tira una piña (si no está en otra).
func punch(kind: Punch) -> void:
	if punching != Punch.NONE or kind == Punch.NONE:
		return
	_from = _wanted()
	punching = kind
	_clock = 0.0
	top_speed = 0.0


## Un punto de las piñas o la guardia, en el espacio de lo que lo sostiene: `x` va hacia afuera de su lado.
func _local(point: Vector3) -> Vector3:
	return Vector3(side * point.x, point.y, point.z)


## DÓNDE SE PIDE EL PUÑO AHORA, desde el hombro (como `GUARD`): a lo largo de la piña, o la guardia más lo que lo corrió
## el mouse.
func _wanted() -> Vector3:
	if punching == Punch.NONE:
		return GUARD + _offset
	var clock := _clock
	var from := _from
	for step: Array in PUNCHES[punching]:
		var time := float(step[0]) / MuscleArmSettings.current.punch_speed
		if clock <= time:
			return from.lerp(step[1], smoothstep(0.0, 1.0, clock / time))
		clock -= time
		from = step[1]
	return GUARD + _offset


func _punch_time() -> float:
	var total := 0.0
	for step: Array in PUNCHES[punching]:
		total += float(step[0]) / MuscleArmSettings.current.punch_speed
	return total


## ── CADA PASO: LOS MÚSCULOS ──────────────────────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	var k := MuscleArmSettings.current
	if manual and UIState.gameplay_active():
		_offset.z -= HoverCube._axis(KEY_W, KEY_S) * k.depth_speed * delta
		_offset = _offset.limit_length(MechBody.UPPER_ARM + MechBody.FOREARM)
	if punching != Punch.NONE:
		_clock += delta
		if _clock >= _punch_time():
			punching = Punch.NONE
	# EL PUÑO, CERRADO mientras tira una piña (lo discreto); abierta en guardia y a mano.
	_hand.fist = punching != Punch.NONE
	var base := anchor.global_transform
	var shoulder := base * shoulder_local
	var fist := shoulder + base.basis * _local(_wanted())
	var pose := _pose(shoulder, fist, base.basis)
	# EL HOMBRO gira el brazo, que lleva al antebrazo en la punta: su resistencia a girar de punta a punta y sobre su
	# largo sale de dónde está el antebrazo ahora (estirado, sobre su largo casi no pesa; doblado, sí).
	var out := forearm.global_position - shoulder
	var length_axis := upper.global_basis.z.normalized()
	var beside := out - length_axis * out.dot(length_axis)
	var asked := _asked(upper, (pose["upper"] as Transform3D).basis, Vector3.ZERO, k)
	var rolling := length_axis * asked.dot(length_axis)
	upper.apply_torque(rolling * (float(upper.get_meta("along")) + FOREARM_MASS * beside.length_squared())
		+ (asked - rolling) * (float(upper.get_meta("across")) + FOREARM_MASS * out.length_squared()))
	# EL CODO sólo dobla: sobre el eje de su bisagra, y empujando al brazo para el otro lado.
	var hinge_axis := forearm.global_basis.y.normalized()
	var bend := _asked(forearm, (pose["forearm"] as Transform3D).basis, upper.angular_velocity, k)
	var torque := hinge_axis * bend.dot(hinge_axis) * float(forearm.get_meta("across"))
	forearm.apply_torque(torque)
	upper.apply_torque(-torque)
	# Lo que mide.
	var hand := forearm.global_transform * Vector3(0, 0, -MechBody.FOREARM * 0.5)
	hand_speed = (forearm.linear_velocity + forearm.angular_velocity.cross(hand - forearm.global_position)).length()
	top_speed = maxf(top_speed, hand_speed) if punching != Punch.NONE else top_speed
	off_target = hand.distance_to(pose["wrist"] as Vector3)
	_label.global_position = shoulder + Vector3(0, 5.0, 0)
	_label.text = "%s · la mano a %.0f m/s (la última piña llegó a %.0f)\na %.1f m de donde se la pide%s" % [
		NAMES[punching], hand_speed, top_speed, off_target, " · TRABADO" if off_target > 1.5 else ""]


## LO QUE PIDE UN MÚSCULO: la aceleración de giro (rad/s², ejes del mundo) que lleva a `body` hacia `wanted` (la
## orientación que pide la pose), con su resorte y su freno —medido contra el giro `against` de la pieza anterior—, hasta
## su fuerza tope.
func _asked(body: RigidBody3D, wanted: Basis, against: Vector3, k: MuscleArmSettings) -> Vector3:
	var turn := (wanted.orthonormalized() * body.global_basis.orthonormalized().inverse()).get_rotation_quaternion()
	if turn.w < 0.0:
		turn = -turn
	var axis := Vector3(turn.x, turn.y, turn.z)
	var angle := 2.0 * acos(clampf(turn.w, -1.0, 1.0))
	var pull := (axis.normalized() * angle if axis.length() > 0.00001 else Vector3.ZERO) * k.muscle_kp
	return (pull - (body.angular_velocity - against) * k.muscle_kd).limit_length(k.muscle_max)


## ── POSEERLO (ver SandboxPossession): llevarlo a mano ────────────────────────────────────────────────────────────

func possess_name() -> String:
	return "Brazo"


func possess_controls() -> PackedStringArray:
	return PackedStringArray([
		"mouse: lleva la mano de costado y arriba y abajo",
		"W/S: la mano adelante y atrás",
		"1 directo · 2 gancho · 3 uppercut · 4 desde arriba",
	])


func possess_status() -> String:
	return "%s · mano a %.0f m/s · a %.1f m de donde se la pide" % [NAMES[punching], hand_speed, off_target]


func possess_begin() -> void:
	manual = true
	_chase_yaw = anchor.global_rotation.y


func possess_end() -> void:
	manual = false
	_offset = Vector3.ZERO


## La cámara: en primera persona, desde adentro de lo que lo sostiene, mirando al frente; en tercera, atrás y arriba,
## del lado del brazo.
func possess_camera(first: bool, _delta: float) -> Transform3D:
	var base := anchor.global_transform
	if first:
		return base * Transform3D(Basis(), Vector3(0.0, 1.6, -1.0))
	var from := base * Vector3(side * 9.0, 9.0, 24.0)
	return Transform3D(Basis(), from).looking_at(base * Vector3(side * 4.0, 0.0, -8.0), Vector3.UP)


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if not manual or motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var reach := MuscleArmSettings.current.mouse_reach * 0.01 * GameOptions.mouse_sensitivity
	_offset += Vector3(side * motion.relative.x, -motion.relative.y, 0.0) * reach
	_offset = _offset.limit_length(MechBody.UPPER_ARM + MechBody.FOREARM)
	get_viewport().set_input_as_handled()
