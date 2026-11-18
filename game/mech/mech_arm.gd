class_name MechArm
extends Node3D

## UN BRAZO DE LA MECA: LO QUE SE LE PIDE, escrito una sola vez. Los dos caminos de la meca (el usuario, 13/11/2026:
## «bifurcar el progreso… un approach más físico o más discreto») comparten esto y difieren en cómo lo cumplen:
##   · MuscleArm, EL FÍSICO: el brazo y el antebrazo son cuerpos con músculos que persiguen la pose; chocan, se traban,
##     ceden. Para la arena entre dos grupos.
##   · PoseArm, EL DISCRETO: el brazo se dibuja en la pose pedida, sin cuerpos; atraviesa lo que haya y, al conectar una
##     piña, le da un impulso a lo que tocó. Para las peleas contra jefes.
##
## LO QUE SE PIDE es DÓNDE VA EL PUÑO en cada momento, desde el hombro, en el espacio de lo que lo sostiene (`anchor`):
##   · LAS POSTURAS (`stance`), donde descansa: NORMAL, el brazo al costado y la mano abierta; CUBRIÉNDOSE, los puños
##     cerrados adelante y arriba; RECOGIDO, la mano contra el hombro (cuando lo que lo sostiene se cae). Pasa de una a
##     otra de corrido. Lo pidió el usuario el 12/11/2026 («una cubriendo y otra normal… la cubriendo… con los puños
##     cerrados»).
##   · LAS PIÑAS (`punch`): cada una, unos pocos puntos por los que pasa el puño, con sus tiempos: se arma atrás, PEGA,
##     se queda un instante y vuelve a su postura (ver `stage`).
## De ahí, LA POSE (`_target`): el codo y la muñeca salen de la IK del cuerpo de la meca (MechBody.arm), y cada pieza va
## con su −Z a lo largo y su Y sobre EL EJE DEL CODO. Y LA MANO (`_mount_hand`), montada por regla.
##
## LO QUE VA EN LA PUNTA (`tip`, un ArmTip) Y LA PLACA (`plated`), APARTE DE CÓMO SE MUEVE (16/11/2026, el usuario:
## «unificar el sistema de los brazos… qué cosas se equipan»; que cada brazo elija discreto o con músculos): el puño, el
## palo, el taladro, la sierra o el cañón se montan igual en un brazo discreto o en uno con músculos (ver ArmLoadout).
## EL GOLPE, UNA SOLA REGLA PARA LOS DOS (`_strike`; 17/11/2026, el usuario: que la piña lo atraviese, «pero que le
## pegue y mostrar que le pegó»): mientras PEGA (ver `stage`), lo que golpea de la punta (ArmTip.strike_points: el puño,
## o el palo entero) barre su camino en el mundo desde donde estaba el paso anterior —así cuenta lo que se movió la meca:
## una piña en pleno dash pega más fuerte—, y a cada cuerpo suelto que toca le pega una vez por piña (EnergyBolt.lands:
## el empujón y, si es un jefe, el daño), con un destello en el punto. Lo fijo (paredes, el cuerpo del jefe) no lo frena:
## lo atraviesa. *Hasta ese día sólo lo hacía el brazo discreto, y sin daño; el de músculos pegaba sólo por choque, y a
## un jefe no le sacaba vida.*
##
## *Hasta ese día el cañón, el taladro y el palo eran clases de brazo (CannonArm, CageCannonArm, DrillArm, PoleArm): el
## cañón no podía tener músculos ni el palo ser discreto, y el cañón de la jaula llevaba otra armadura que el palo.*

enum Punch { NONE, STRAIGHT, HOOK, UPPERCUT, HAMMER }
enum Stance { NORMAL, COVER, TUCKED }
## En qué parte de una piña está: armándose, pegando, quieto en la punta, volviendo.
enum Stage { IDLE, WINDUP, STRIKE, HOLD, RETURN }

const NAMES := ["quieto", "directo", "gancho", "uppercut", "desde arriba"]
const STANCE_NAMES := ["normal", "cubriéndose", "recogido"]
## El grosor de las piezas: el de las piernas (el usuario, 12/11/2026: «más gruesos, y todos del mismo grosor»).
## DÓNDE DESCANSA EL PUÑO en cada postura, desde el hombro, en el espacio de lo que lo sostiene (`x` hacia afuera del
## cuerpo; adentro es negativo).
const STANCES := {
	Stance.NORMAL: Vector3(0.4, -6.2, -4.4),
	Stance.COVER: Vector3(-1.6, -1.5, -6.6),
	Stance.TUCKED: Vector3(0.3, -1.4, -1.8),
}
## A qué velocidad pasa el puño de una postura a otra (m/s) y en cuánto vuelve a su postura después de una piña (s).
const STANCE_SPEED := 16.0
const RETURN_TIME := 0.6
## LAS PIÑAS: por dónde se pide que pase el puño (como `STANCES`) y en cuánto llega a cada punto desde el anterior (s):
## se arma atrás, pega y se queda un instante. Después vuelve a su postura.
const PUNCHES := {
	Punch.STRAIGHT: [[0.45, Vector3(-0.8, -1.8, -2.6)], [0.26, Vector3(-2.6, -0.6, -10.6)], [0.2, Vector3(-2.6, -0.6, -10.6)]],
	Punch.HOOK: [[0.5, Vector3(3.8, -1.2, -3.2)], [0.3, Vector3(-5.4, -0.8, -7.4)], [0.2, Vector3(-5.4, -0.8, -7.4)]],
	Punch.UPPERCUT: [[0.5, Vector3(-0.6, -6.8, -3.4)], [0.28, Vector3(-2.0, 3.6, -7.6)], [0.2, Vector3(-2.0, 3.6, -7.6)]],
	Punch.HAMMER: [[0.55, Vector3(-0.4, 6.6, -2.2)], [0.28, Vector3(-1.6, -5.0, -8.2)], [0.2, Vector3(-1.6, -5.0, -8.2)]],
}

## De qué lado va (−1 izquierdo, 1 derecho), lo que lo sostiene y dónde está el hombro en su espacio. Se ponen antes de
## agregarlo al árbol.
var side := 1.0
var anchor: PhysicsBody3D = null
var shoulder_local := Vector3.ZERO
## LAS MEDIDAS DEL CUERPO QUE LO LLEVA (ver MechBody, BalanceBody.measures): el largo del brazo y del antebrazo, el de
## las posturas y las piñas, y el ancho de la mano. Las pone la meca. Se ponen antes de agregarlo.
var measures := MechBody.new()
## La postura pedida, y la piña que está tirando.
var stance := Stance.COVER
var punching := Punch.NONE

var _clock := 0.0
var _from := Vector3.ZERO
## Dónde descansa el puño ahora (va hacia el de la postura pedida) y lo que lo corrió quien lo lleva a mano.
var _rest := Vector3.ZERO
var _offset := Vector3.ZERO
var _hand: MechHand = null
## LO QUE VA EN LA PUNTA (ver ArmTip; sin nada, el puño común) y si lleva LAS PLACAS DEL ACORAZADO en el brazo y el
## antebrazo (ArmoryParts.plate). Se ponen antes de agregarlo.
var tip: ArmTip = null
var plated := false
## DÓNDE DESCANSA EL PUÑO EN LA POSTURA NORMAL (como `STANCES`, en el largo del brazo): cero, el de `STANCES`. Y EL
## GOLPE PRINCIPAL (el del clic izquierdo, `main_strike`): la piña y, si va por otro camino, sus puntos (como `PUNCHES`).
## Los cambia el panel de poses para probar (ArmPosesPanel, ver ArmPoseIdeas).
var rest_point := Vector3.ZERO
var main_punch := Punch.STRAIGHT
var main_path: Array = []
## HACIA DÓNDE DOBLA EL CODO (x afuera, y arriba, z atrás; ver MechBody.arm): cero, el de siempre (afuera, abajo y atrás).
## Lo cambian las maquetas de reposo (tests/arm_rest_look): el codo pegado al cuerpo.
var elbow_hint := Vector3.ZERO
## La piel del antebrazo (el cilindro, sin la bola del codo): lo que esconde una punta que lo reemplaza (el cañón).
var forearm_skin: Node3D = null
## Los puntos de la piña tirada hacia un lugar (ver `punch_at`); vacío, la piña va por los suyos (`PUNCHES`).
var _aimed: Array = []
## El eje de la bisagra del codo, en el mundo: sale del brazo y el antebrazo pedidos; con el brazo estirado no se puede
## calcular y queda el último.
var _hinge := Vector3.RIGHT
## LO QUE GOLPEA (ver `_strike`): la última piña, a qué velocidad conectó (0 si no tocó nada) y a qué; lo que ya tocó
## en esta piña; y dónde estaban los puntos que golpean el paso anterior.
var last_hit_speed := 0.0
var last_hit: Node = null
var _struck := {}
var _strike_was := PackedVector3Array()
var _sphere := SphereShape3D.new()


## LA PIÑA CARGADA (17/11/2026, el usuario: «mientras más tiempo hacés clic, más tarda la animación y más pega, pero
## más difícil es de pegarle porque dura más y te exponés más»): la que se está tirando va `punch_pace` de rápida (×) y
## pega `punch_strength` de fuerte (×). Las pone `charged_strike`; al terminar la piña vuelven a 1.
var punch_pace := 1.0
var punch_strength := 1.0


## TIRA EL GOLPE PRINCIPAL CARGADO `power` (0 a 1): de la de siempre (0) a la más lenta (`slowest` de la velocidad) y
## más fuerte (`strongest` del golpe). Devuelve si lo tiró.
func charged_strike(power: float, slowest: float, strongest: float) -> bool:
	if punching != Punch.NONE:
		return false
	punch_pace = lerpf(1.0, slowest, clampf(power, 0.0, 1.0))
	punch_strength = lerpf(1.0, strongest, clampf(power, 0.0, 1.0))
	if not main_strike():
		punch_pace = 1.0
		punch_strength = 1.0
		return false
	return true


## Tira una piña (si no está en otra). Devuelve si la tiró.
func punch(kind: Punch) -> bool:
	if punching != Punch.NONE or kind == Punch.NONE:
		return false
	_from = _wanted()
	punching = kind
	_clock = 0.0
	_aimed = []
	_struck.clear()
	last_hit_speed = 0.0
	last_hit = null
	return true


## TIRA UN DIRECTO HACIA `point` (en el mundo; lo pidió Tableros el 14/11/2026 para la mira del panel del brazo): se
## arma como el directo y pega donde se apunta, recortado a lo que estira el directo desde el hombro. Devuelve si la tiró.
func punch_at(point: Vector3) -> bool:
	var base := anchor.global_transform
	var straight: Array = PUNCHES[Punch.STRAIGHT]
	var strike: Vector3 = straight[1][1]
	var aim := _local(base.basis.inverse() * (point - base * shoulder_local) / reach()).limit_length(strike.length())
	if not punch(Punch.STRAIGHT):
		return false
	_aimed = [straight[0], [straight[1][0], aim], [straight[2][0], aim]]
	return true


## Por dónde pasa el puño en la piña que está tirando.
func _steps() -> Array:
	return _aimed if not _aimed.is_empty() else PUNCHES[punching]


## Cuánto más rápidas van las piñas (×): cada camino tiene su perilla.
func _punch_speed() -> float:
	return 1.0


## AVANZA LO QUE SE PIDE un paso: el reloj de la piña, el descanso hacia su postura, y la mano (el puño, cerrado mientras
## tira una piña y cubriéndose; abierta en lo demás).
func _advance(delta: float) -> void:
	if punching != Punch.NONE:
		_clock += delta
		if _clock >= _punch_time():
			punching = Punch.NONE
			punch_pace = 1.0
			punch_strength = 1.0
	_rest = _rest.move_toward(stance_at(stance), STANCE_SPEED * reach() * delta)
	if _hand != null:
		_hand.fist = punching != Punch.NONE or stance == Stance.COVER
	if tip != null:
		tip.step(delta)


## Un punto de las piñas o la guardia, en el espacio de lo que lo sostiene: `x` va hacia afuera de su lado.
func _local(point: Vector3) -> Vector3:
	return Vector3(side * point.x, point.y, point.z)


## DÓNDE DESCANSA EL PUÑO en la postura `which` (ver `STANCES`), con el largo de este brazo.
func stance_at(which: Stance) -> Vector3:
	if which == Stance.NORMAL and rest_point != Vector3.ZERO:
		return rest_point * reach()
	return (STANCES[which] as Vector3) * reach()


## TIRA EL GOLPE PRINCIPAL (`main_punch`, por `main_path` si tiene). Devuelve si lo tiró.
func main_strike() -> bool:
	if not punch(main_punch):
		return false
	if not main_path.is_empty():
		_aimed = main_path
	return true


## EL LARGO DE ESTE BRAZO: el factor de las posturas y las piñas (el `reach` de sus medidas), y el brazo y el antebrazo
## (m).
func reach() -> float:
	return measures.reach


func upper_length() -> float:
	return measures.UPPER_ARM


func forearm_length() -> float:
	return measures.FOREARM


## DÓNDE SE PIDE EL PUÑO AHORA, desde el hombro (como `STANCES`): lo que diga la punta (el cañón apunta con su palanca)
## sobre lo que piden las piñas y las posturas (`_moves`).
func _wanted() -> Vector3:
	var asked := _moves()
	return tip.wanted(asked) if tip != null else asked


## Lo que piden las piñas y las posturas: a lo largo de la piña y de vuelta a su postura, o en su postura más lo que lo
## corrieron a mano.
func _moves() -> Vector3:
	var home := _rest + _offset
	if punching == Punch.NONE:
		return home
	var speed := _punch_speed()
	var clock := _clock
	var from := _from
	for step: Array in _steps():
		var time := float(step[0]) / speed
		if clock <= time:
			return from.lerp((step[1] as Vector3) * reach(), smoothstep(0.0, 1.0, clock / time))
		clock -= time
		from = (step[1] as Vector3) * reach()
	return from.lerp(home, smoothstep(0.0, 1.0, clock / (RETURN_TIME / speed)))


## En qué parte de la piña está.
func stage() -> Stage:
	if punching == Punch.NONE:
		return Stage.IDLE
	var clock := _clock * _punch_speed()
	var steps := _steps()
	for index in steps.size():
		clock -= float(steps[index][0])
		if clock <= 0.0:
			return (Stage.WINDUP + index) as Stage
	return Stage.RETURN


func _punch_time() -> float:
	var total := RETURN_TIME
	for step: Array in _steps():
		total += float(step[0])
	return total / (_punch_speed() * punch_pace)


## ── LA POSE ──────────────────────────────────────────────────────────────────────────────────────────────────────

## LA POSE QUE SE PIDE AHORA, en el mundo (ver `_pose`).
func _target() -> Dictionary:
	var base := anchor.global_transform
	var shoulder := base * shoulder_local
	return _pose(shoulder, shoulder + base.basis * _local(_wanted()), base.basis)


## LA POSE con el puño en `fist` (mundo): el codo y la muñeca salen de la IK del cuerpo de la meca (MechBody.arm); las
## dos piezas, con su −Z a lo largo y su Y sobre EL EJE DEL CODO (el que es perpendicular al brazo y al antebrazo): así
## el giro del brazo sobre su largo es el que pone al antebrazo donde va, como con una bisagra.
func _pose(shoulder: Vector3, fist: Vector3, torso: Basis) -> Dictionary:
	var arm := measures.arm(shoulder, fist, side, torso, elbow_hint)
	var elbow: Vector3 = arm["elbow"]
	var wrist: Vector3 = arm["wrist"]
	var across := (elbow - shoulder).cross(wrist - elbow)
	if across.length() > 0.5:
		_hinge = across.normalized()
	return {
		"shoulder": shoulder,
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


## LA MANO, en la punta de `forearm` (una pieza con los ejes de `_along`), POR REGLA Y NO A OJO. El Y de la pieza es el
## eje del codo (brazo × antebrazo) y su X, la parte del brazo perpendicular al antebrazo; o sea que SU −X SIEMPRE MIRA
## HACIA DONDE DOBLA EL CODO (hacia el hombro), en los dos brazos, y su Y mira hacia afuera en el derecho y hacia adentro
## en el izquierdo (un producto cruz no se espeja). Como en un cuerpo con el antebrazo sin girar: EL PULGAR, HACIA DONDE
## DOBLA EL CODO; LA PALMA, HACIA EL CUERPO. La mano trae el pulgar en +Y y la palma en −side·X (ver MechHand): un
## cuarto de vuelta sobre Z lleva su Y al −X de la pieza y su X al Y, y la palma queda en −side·Y: hacia adentro.
func _mount_hand(forearm: Node3D) -> void:
	if tip == null:
		tip = ArmTip.new()
	add_child(tip)
	tip.mount(self, forearm)


## EL PUÑO COMÚN, en la punta de `forearm` (ver `_mount_hand`): lo que monta la punta de siempre (ArmTip).
func mount_common_hand(forearm: Node3D) -> void:
	_hand = MechHand.build(forearm, side)
	# La escala, después de la transformación (que la pisaría): la mano del ancho del brazo. *Hasta el 16/11/2026 iba
	# antes y la mano quedaba siempre de 1; con el ancho mediano no se notaba, en la jaula (al 30 %) era enorme.*
	_hand.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0, -forearm_length() * 0.5))
	_hand.scale = Vector3.ONE * measures.thick


## LAS PLACAS DEL ACORAZADO (si `plated`) en `upper` y `forearm`, del lado de afuera del brazo; en el antebrazo, si la
## punta lo deja (el cañón, que lo reemplaza, no). Con las piezas ya en su pose.
func _dress(upper: Node3D, forearm: Node3D) -> void:
	if not plated:
		return
	var out := anchor.global_basis * Vector3.RIGHT * side
	ArmoryParts.plate(upper, out, measures.thick, float(MechBody.BASE["UPPER_ARM"]) * 0.75)
	if tip == null or tip.plates_forearm():
		ArmoryParts.plate(forearm, out, measures.thick, float(MechBody.BASE["FOREARM"]) * 0.7)


## ── EL GOLPE (ver arriba) ────────────────────────────────────────────────────────────────────────────────────────

## Con qué choca lo que golpea: el mundo (la capa 1, la de los cuerpos sueltos y la caja donde se le pega a un jefe).
const HIT_MASK := 1
## Más que esto en un paso no es un golpe que se mueve: es la meca que reapareció (m).
const JUMP := 30.0


## UN PASO DEL GOLPE: los puntos que golpean de la punta barren su camino desde el paso anterior (mientras pega), y le
## pegan a lo suelto que tocan. `skip`, lo que no se golpea (lo que lo sostiene, sus propias piezas).
func _strike(delta: float, skip: Array[RID]) -> void:
	var now := tip.strike_points() if tip != null else PackedVector3Array()
	var was := _strike_was
	_strike_was = now
	# Pega mientras pega y mientras se queda en la punta: el brazo con músculos llega un poco después que la pose.
	if not (stage() == Stage.STRIKE or stage() == Stage.HOLD) or was.size() != now.size() or delta <= 0.0:
		return
	_sphere.radius = strike_radius()
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _sphere
	query.collision_mask = HIT_MASK
	var space := get_world_3d().direct_space_state
	for index in now.size():
		var motion := now[index] - was[index]
		if motion.length() < 0.001 or motion.length() > JUMP:
			continue
		query.exclude = skip.duplicate()
		# Lo que no se golpea se saltea y se sigue barriendo: el brazo atraviesa.
		for attempt in 6:
			query.transform = Transform3D(Basis(), was[index])
			query.motion = motion
			var fractions := space.cast_motion(query)
			if fractions[1] >= 1.0:
				break
			query.transform = Transform3D(Basis(), was[index] + motion * fractions[1])
			query.motion = Vector3.ZERO
			var info := space.get_rest_info(query)
			if info.is_empty():
				break
			var body := instance_from_id(int(info["collider_id"])) as RigidBody3D
			if body != null and not _struck.has(body.get_instance_id()):
				_hit(body, info["point"], motion / delta)
			query.exclude = query.exclude + [info["rid"]]
		# Y lo que ya tiene adentro donde quedó (si arrancó adentro, el barrido no lo ve).
		query.transform = Transform3D(Basis(), now[index])
		query.motion = Vector3.ZERO
		for found in space.intersect_shape(query, 8):
			var inside := found["collider"] as RigidBody3D
			if inside != null and not _struck.has(inside.get_instance_id()):
				_hit(inside, now[index], motion / delta)


## LE PEGA a `body` en `at` con lo que golpea yendo a `velocity` (mundo): una vez por piña, lo que haga la punta (el
## taladro y la sierra, ver SpinTip.hit) o el golpe de siempre (EnergyBolt.lands: el empujón, y si es un jefe, el daño),
## y un destello donde pegó.
func _hit(body: RigidBody3D, at: Vector3, velocity: Vector3) -> void:
	_struck[body.get_instance_id()] = true
	if tip == null or not tip.hit(body, at, velocity):
		EnergyBolt.lands(body, velocity * PoseArmSettings.current.hit_mass * punch_strength, at, "golpe")
	EnergyBolt.flash(get_tree().current_scene, at, strike_radius() * 1.2, Color(1.0, 0.93, 0.7))
	last_hit_speed = velocity.length()
	last_hit = body


## El radio de lo que golpea (m): el del puño, a la medida de esta meca.
func strike_radius() -> float:
	return PoseArmSettings.current.fist_radius * measures.thick
