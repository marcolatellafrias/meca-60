class_name MuscleArm
extends MechArm

## UN BRAZO CON MÚSCULOS: EL CAMINO FÍSICO de los brazos de la meca (12/11/2026; lo que se le pide —posturas, piñas, la
## pose—, en MechArm), en su propia fila para tunearlo solo. El usuario: «deberíamos tomar el approach de el hueso que intenta hacer algo y que todo el cuerpo, al menos los
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
## LAS POSTURAS (`stance`), donde descansa el puño: NORMAL, el brazo al costado y la mano abierta; CUBRIÉNDOSE, los puños
## cerrados adelante y arriba; y RECOGIDO, la mano contra el hombro (cuando lo que lo sostiene se cae). Pasa de una a
## otra de corrido. Lo pidió el usuario el 12/11/2026 («cambiar de postura, una cubriendo y otra normal… la normal
## estaría más a los costados… la cubriendo… con los puños cerrados»).
## LAS PIÑAS (`punch`): cada una, unos pocos puntos por los que se pide que pase el puño, con sus tiempos (se arma atrás,
## pega, se queda un instante y vuelve a su postura). A MANO (poseído, cuando va solo): el mouse lleva el puño de costado
## y arriba y abajo, y W/S adelante y atrás.
##
## VA SOLO (en su fila, `standalone`) O MONTADO en algo que se mueve (la meca): el músculo del hombro empuja
## contra lo que lo sostiene, así que una piña lo sacude.
##
## Las perillas, en MuscleArmSettings (la pestaña «Con músculos» del F3 de la meca jaula).
## *Su fila, Brazo (MuscleArmArchetype, que lo probaba solo: `standalone`, poseíble a mano y con su cartel), se borró con
## la meca grande el 17/11/2026; el modo solo quedó, sin quien lo use.*

const UPPER_MASS := 2200.0
const FOREARM_MASS := 2000.0
## Cuánto pesa, en partes de `UPPER_MASS` y `FOREARM_MASS` (montado en la meca, menos: que una piña no la dé vuelta), y si
## va solo en su fila (se lo puede poseer y lleva su cartel). También antes de agregarlo.
var weight := 1.0
var standalone := false
var upper: RigidBody3D = null
var forearm: RigidBody3D = null
## Lo que mide, para mirar: la velocidad de la mano (m/s) y la más alta de la última piña, y lo lejos que está la mano
## de donde se la pide (m).
var hand_speed := 0.0
var top_speed := 0.0
var off_target := 0.0
## A mano (poseído): por dónde corrió el puño el mouse, desde la guardia.
var manual := false

var _label: Label3D = null
var _chase_yaw := 0.0
## La pose pedida el paso anterior (de cada pieza): de ahí sale a qué velocidad gira la pose (ver `follow`).
var _last_upper := Basis()
var _last_forearm := Basis()
var _has_last := false
## Dónde estaba el hombro el paso anterior: si saltó más que lo que se mueve una meca (la pusieron en otro lado), las
## piezas van de un salto a la pose (ver `_snap`).
var _last_shoulder := Vector3.ZERO

## Con qué choca lo que golpea (ver StrikeSettings): lo fijo del mundo (paredes, el cuerpo de un jefe) y lo suelto (la
## caja donde se le pega a un jefe).
const SOLID_MASK := 1 | PhysicsLayers.FIXED
## Lo más rápido que se le pide girar a una pieza por seguir la pose (rad/s): un salto de la IK no es una velocidad.
const FOLLOW_MOST := 40.0


func _ready() -> void:
	if standalone:
		add_to_group(SandboxPossession.GROUP)
	_rest = stance_at(stance)
	var base := anchor.global_transform
	var shoulder := base * shoulder_local
	var pose := _pose(shoulder, shoulder + base.basis * _local(_rest), base.basis)
	upper = _piece("Brazo", UPPER_MASS * weight, Vector3(measures.LEG_THICKNESS, measures.LEG_THICKNESS, upper_length()), pose["upper"],
		Clay.METAL.darkened(0.1))
	forearm = _piece("Antebrazo", FOREARM_MASS * weight, Vector3(measures.LEG_THICKNESS, measures.LEG_THICKNESS, forearm_length()),
		pose["forearm"], Clay.METAL.darkened(0.2))
	# El hombro y el codo, esferas en la punta de arriba de cada pieza; la mano, en la de abajo del antebrazo, con su
	# forma de choque (el puño).
	Clay.sphere(upper, measures.LEG_THICKNESS * 0.78, Vector3(0, 0, upper_length() * 0.5), MechBody.JOINT_COLOR)
	Clay.sphere(forearm, measures.LEG_THICKNESS * 0.66, Vector3(0, 0, forearm_length() * 0.5), MechBody.JOINT_COLOR)
	forearm_skin = forearm.get_meta("skin")
	_mount_hand(forearm)
	_dress(upper, forearm)
	Clay.shape_box(forearm, Vector3(MechHand.PALM.y, MechHand.PALM.x * 2.2, MechHand.length() * 0.8) * measures.thick,
		Vector3(0, 0, -forearm_length() * 0.5 - MechHand.length() * measures.thick * 0.4))
	# LO QUE CHOCA (ver StrikeSettings): sólo lo que golpea —el puño (la caja de recién) y lo de la punta—; el brazo y el
	# antebrazo, nunca.
	for holder in upper.get_children():
		if holder is CollisionShape3D:
			(holder as CollisionShape3D).disabled = true
	(forearm.get_child(0) as CollisionShape3D).disabled = true
	for solid: Array in (tip.solid_shapes() if tip != null else []):
		var holder := CollisionShape3D.new()
		holder.shape = solid[0]
		holder.transform = solid[1]
		forearm.add_child(holder)
	upper.collision_layer = 0
	upper.collision_mask = 0
	# LO QUE SE VE CUELGA DE LOS HUESOS (MechSkeleton): los cuerpos quedan para empujar y chocar.
	if upper_bone != null:
		MechSkeleton.aim(upper_bone, upper.global_transform)
		MechSkeleton.aim(forearm_bone, forearm.global_transform)
		MechSkeleton.move_drawing(upper, upper_bone)
		MechSkeleton.move_drawing(forearm, forearm_bone)
	forearm.collision_layer = 0
	# El hombro, una bola; el codo, una bisagra sobre su eje (el Z de la articulación).
	var ball := PinJoint3D.new()
	_join(ball, anchor, upper, Transform3D(Basis(), shoulder))
	var hinge := HingeJoint3D.new()
	_join(hinge, upper, forearm, Transform3D(Basis.looking_at(_hinge, (pose["upper"] as Transform3D).basis.z), pose["elbow"]))
	forearm.add_collision_exception_with(anchor)
	if not standalone:
		return
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
	# Choca como una caja; se ve como un cilindro de pocas caras (ver Clay.limb).
	Clay.shape_box(body, size, Vector3.ZERO)
	body.set_meta("skin", Clay.limb(body, size.x * 0.5, size.z, Vector3.ZERO, color))
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


func _exit_tree() -> void:
	manual = false


## ── LO QUE SE LE PIDE ────────────────────────────────────────────────────────────────────────────────────────────

func punch(kind: Punch) -> bool:
	if not super(kind):
		return false
	top_speed = 0.0
	return true


func _punch_speed() -> float:
	return MuscleArmSettings.current.punch_speed


## ── CADA PASO: LOS MÚSCULOS ──────────────────────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	# SUS HUESOS (MechSkeleton) GIRAN COMO SUS CUERPOS, sin moverse de donde nacen (el hombro, la punta del brazo): la
	# unión física puede ceder un poco; el esqueleto, no.
	if upper_bone != null:
		MechSkeleton.aim(upper_bone, upper.global_transform)
		MechSkeleton.aim(forearm_bone, forearm.global_transform)
	var k := MuscleArmSettings.current
	if manual and UIState.gameplay_active():
		_offset.z -= MechKeys.axis(KEY_W, KEY_S) * k.depth_speed * delta
		_offset = _offset.limit_length(upper_length() + forearm_length())
	_advance(delta)
	var base := anchor.global_transform
	var shoulder := base * shoulder_local
	var fist := shoulder + base.basis * _local(_wanted())
	var pose := _pose(shoulder, fist, base.basis)
	if _has_last and shoulder.distance_to(_last_shoulder) > JUMP:
		_snap(pose)
	_last_shoulder = shoulder
	# EL HOMBRO gira el brazo, que lleva al antebrazo en la punta: su resistencia a girar de punta a punta y sobre su
	# largo sale de dónde está el antebrazo ahora (estirado, sobre su largo casi no pesa; doblado, sí).
	var out := forearm.global_position - shoulder
	var length_axis := upper.global_basis.z.normalized()
	var beside := out - length_axis * out.dot(length_axis)
	# Empuja contra lo que lo sostiene: si es un cuerpo suelto (la meca), lo gira para el otro lado.
	var holder := anchor as RigidBody3D
	# LA VELOCIDAD DE LA POSE PEDIDA (ver MuscleArmSettings.follow): cuánto giró cada pieza pedida desde el paso
	# anterior. El freno frena contra eso: así el músculo arranca con la piña y no detrás de ella.
	var upper_wanted := (pose["upper"] as Transform3D).basis
	var forearm_wanted := (pose["forearm"] as Transform3D).basis
	var upper_spin := MuscleArm._spin(_last_upper, upper_wanted, delta) if _has_last else Vector3.ZERO
	var forearm_spin := MuscleArm._spin(_last_forearm, forearm_wanted, delta) if _has_last else Vector3.ZERO
	_last_upper = upper_wanted
	_last_forearm = forearm_wanted
	_has_last = true
	var holder_spin := holder.angular_velocity if holder != null else Vector3.ZERO
	var asked := _asked(upper, upper_wanted, holder_spin.lerp(upper_spin, k.follow), k)
	var rolling := length_axis * asked.dot(length_axis)
	var shoulder_torque := rolling * (float(upper.get_meta("along")) + forearm.mass * beside.length_squared()) \
		+ (asked - rolling) * (float(upper.get_meta("across")) + forearm.mass * out.length_squared())
	upper.apply_torque(shoulder_torque)
	if holder != null:
		holder.apply_torque(-shoulder_torque)
	# EL CODO sólo dobla: sobre el eje de su bisagra, y empujando al brazo para el otro lado.
	var hinge_axis := forearm.global_basis.y.normalized()
	var bend := _asked(forearm, forearm_wanted, upper.angular_velocity.lerp(forearm_spin, k.follow), k)
	var torque := hinge_axis * bend.dot(hinge_axis) * float(forearm.get_meta("across"))
	forearm.apply_torque(torque)
	upper.apply_torque(-torque)
	forearm.collision_mask = SOLID_MASK if _solid() else 0
	_strike(delta, [anchor.get_rid(), upper.get_rid(), forearm.get_rid()])
	# Lo que mide.
	var hand := forearm.global_transform * Vector3(0, 0, -forearm_length() * 0.5)
	hand_speed = (forearm.linear_velocity + forearm.angular_velocity.cross(hand - forearm.global_position)).length()
	top_speed = maxf(top_speed, hand_speed) if punching != Punch.NONE else top_speed
	off_target = hand.distance_to(pose["wrist"] as Vector3)
	if _label == null:
		return
	_label.global_position = shoulder + Vector3(0, 5.0, 0)
	_label.text = "%s (%s) · la mano a %.0f m/s (la última piña llegó a %.0f)\na %.1f m de donde se la pide%s" % [
		NAMES[punching], STANCE_NAMES[stance], hand_speed, top_speed, off_target, " · TRABADO" if off_target > 1.5 else ""]


## SI LO QUE GOLPEA CHOCA AHORA (ver StrikeSettings): chocando lo que golpea, mientras tira un golpe o siempre; y el
## cañón, sólo si el arma también.
func _solid() -> bool:
	var k := StrikeSettings.current
	if not k.strikes_collide or (tip != null and tip.is_weapon() and not k.weapon_collides):
		return false
	return k.collide_at_rest or punching != Punch.NONE


## El que tiene cuerpo lo frena el choque de verdad (ver MechArm.stuck).
func _stops_on_hit() -> bool:
	return false


## LA PUSIERON EN OTRO LADO (ver `_last_shoulder`): las piezas, de un salto a `pose` y quietas. Si no, la articulación
## del hombro las arrastraba de golpe desde donde estaban, a cientos de m/s, y el brazo quedaba revoleado (17/11/2026).
func _snap(pose: Dictionary) -> void:
	for pair: Array in [[upper, pose["upper"]], [forearm, pose["forearm"]]]:
		var piece := pair[0] as RigidBody3D
		piece.global_transform = pair[1]
		piece.linear_velocity = Vector3.ZERO
		piece.angular_velocity = Vector3.ZERO
		PhysicsServer3D.body_set_state(piece.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, pair[1])
	_strike_was = PackedVector3Array()


## LO QUE PIDE UN MÚSCULO: la aceleración de giro (rad/s², ejes del mundo) que lleva a `body` hacia `wanted` (la
## orientación que pide la pose), con su resorte y su freno —medido contra el giro `against`: el de la pieza anterior o,
## siguiendo la pose (`follow`), el de la pose pedida—, hasta su fuerza tope.
func _asked(body: RigidBody3D, wanted: Basis, against: Vector3, k: MuscleArmSettings) -> Vector3:
	var turn := (wanted.orthonormalized() * body.global_basis.orthonormalized().inverse()).get_rotation_quaternion()
	if turn.w < 0.0:
		turn = -turn
	var axis := Vector3(turn.x, turn.y, turn.z)
	var angle := 2.0 * acos(clampf(turn.w, -1.0, 1.0))
	var pull := (axis.normalized() * angle if axis.length() > 0.00001 else Vector3.ZERO) * k.muscle_kp
	return (pull - (body.angular_velocity - against) * k.muscle_kd).limit_length(k.muscle_max)


## A QUÉ VELOCIDAD GIRA (rad/s, ejes del mundo) una orientación que pasó de `from` a `to` en `delta` segundos; con tope.
static func _spin(from: Basis, to: Basis, delta: float) -> Vector3:
	var turn := (to.orthonormalized() * from.orthonormalized().inverse()).get_rotation_quaternion()
	if turn.w < 0.0:
		turn = -turn
	var axis := Vector3(turn.x, turn.y, turn.z)
	if axis.length() < 0.000001 or delta <= 0.0:
		return Vector3.ZERO
	return (axis.normalized() * 2.0 * acos(clampf(turn.w, -1.0, 1.0)) / delta).limit_length(FOLLOW_MOST)


## ── POSEERLO (ver SandboxPossession): llevarlo a mano ────────────────────────────────────────────────────────────

func possess_name() -> String:
	return "Brazo"


func possess_controls() -> PackedStringArray:
	return PackedStringArray([
		"mouse: lleva la mano de costado y arriba y abajo",
		"W/S: la mano adelante y atrás",
		"1 directo · 2 gancho · 3 uppercut · 4 desde arriba · 5 cambia la postura",
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
	_offset = _offset.limit_length(upper_length() + forearm_length())
	get_viewport().set_input_as_handled()
