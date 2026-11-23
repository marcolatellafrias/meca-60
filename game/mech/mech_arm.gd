class_name MechArm
extends Node3D

## UN BRAZO DE LA MECA: LO QUE SE LE PIDE, escrito una sola vez, y dibujado en su pose por PoseArm. *Hasta el 22/11/2026
## había también un brazo físico, con músculos (MuscleArm): se sacó al pasar a las habilidades por zonas.*
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
## LO QUE VA EN LA PUNTA (`tip`, un ArmTip) Y LA PLACA (`plated`): el puño, el palo, el taladro, la sierra o el cañón.
## EL GOLPE ES SU ZONA (22/11/2026, ver MechSkills): el brazo es la animación. Cuando la piña llega a la punta, la zona de lo
## que lleva le pega a lo que esté adentro, al frente del torso.

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
## SUS HUESOS (MechSkeleton: el brazo y el antebrazo; 18/11/2026): el brazo los escribe y sus piezas cuelgan de ellos.
## Se ponen antes de agregarlo. Sin ellos, como antes.
var upper_bone: CustomBone = null
var forearm_bone: CustomBone = null
## La postura pedida, y la piña que está tirando.
var stance := Stance.COVER
var punching := Punch.NONE
## DESDE CUÁNDO SE ESTÁ CARGANDO UNA PIÑA (s, Time.get_ticks_msec / 1000; −1, no): lo pone quien la carga (el mando de su
## brazo, CageBoards) y lo lee MechSounds.
var charging_since := -1.0

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
## Si la piña de ahora ya pegó.
var _landed := false


## LA PIÑA CARGADA (22/11/2026; el usuario: «más carga, más animación, y cuando libera el golpe, siempre tiene la misma
## velocidad»). Mientras se mantiene, el puño SE VA ARMANDO HACIA ATRÁS según lo cargado (`windup_share`, ver `_windup_at`); al
## soltar sale desde ahí, sin otro armado y con el mismo tiempo siempre. La carga sólo cambia la fuerza (`punch_strength`).
var punch_strength := 1.0
var windup_share := 0.0
## HASTA DÓNDE PUEDE LLEGAR LA CARGA: sin energía para el golpe pesado, se queda en el liviano (MechCrew).
var charge_cap := 1.0
## SI EL GOLPE LO TIRÓ ESTA MÁQUINA: sólo acá destella su zona en el piso (lo escribe MechCrew).
var cast_here := true
## LOS BRAZOS CAÍDOS DEL STUN (0 a 1; lo mueve MechStun): cuelgan del hombro, temblando.
var limp := 0.0
const LIMP_WAY := Vector3(0.14, -0.98, 0.1)
const LIMP_REACH := 0.94
const LIMP_SHAKE := 0.05
## Hasta dónde se echa atrás a fondo, además del armado de su golpe (como `PUNCHES`).
const WINDUP_BACK := Vector3(0.2, 0.15, 1.0)
## Hasta qué parte de ese camino llega a fondo.
const WINDUP_MAX := 0.6
## Cuánto más rápido que una piña común sale al soltarla (×).
const RELEASE_SPEED := 4.0
## Lo que tarda en pasar a su punto de salida: casi nada, porque ya está armado.
const RELEASE_TIME := 0.01


## TIRA EL GOLPE PRINCIPAL CARGADO `power` (0 a 1), hasta `strongest` de fuerte. Devuelve si lo tiró.
func charged_strike(power: float, strongest: float) -> bool:
	if punching != Punch.NONE:
		return false
	punch_strength = lerpf(1.0, strongest, clampf(power, 0.0, 1.0))
	if not main_strike():
		punch_strength = 1.0
		return false
	var steps := _steps()
	_aimed = [[RELEASE_TIME, _from / reach()], [float(steps[1][0]) / RELEASE_SPEED, steps[1][1]], steps[2]]
	windup_share = 0.0
	return true


## DÓNDE QUEDA EL PUÑO ARMADO A FONDO (como `_moves`): el armado de su golpe más lo que se echa atrás.
func _windup_at() -> Vector3:
	var path: Array = main_path
	if path.is_empty() and tip != null:
		path = tip.strike_path()
	if path.is_empty():
		path = PUNCHES[main_punch]
	return ((path[0][1] as Vector3) + WINDUP_BACK) * reach()


## Tira una piña (si no está en otra). Devuelve si la tiró. POR LA RED, en las máquinas que la siguen sólo sale la que
## manda el dueño (MechArmsNet), y el dueño avisa cada una.
func punch(kind: Punch) -> bool:
	if punching != Punch.NONE or kind == Punch.NONE:
		return false
	var net := MechArmsNet.of(self)
	if net != null and not net.allows():
		return false
	if net != null:
		net.announce(self)
	_from = _wanted()
	punching = kind
	_clock = 0.0
	MechSounds.hit(self, MechSounds.SWING, tip.forearm if tip != null else null, randf_range(0.9, 1.1))
	_aimed = []
	_landed = false
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


## LOS PUNTOS DE LA PIÑA de ahora si van por otro camino (vacío, los suyos), y ponerlos: para la red (MechArmsNet).
func aimed_path() -> Array:
	return _aimed


func aim_path(path: Array) -> void:
	_aimed = path


## Por dónde pasa el puño en la piña que está tirando.
func _steps() -> Array:
	return _aimed if not _aimed.is_empty() else PUNCHES[punching]


## Cuánto más rápidas van las piñas (×): cada camino tiene su perilla.
func _punch_speed() -> float:
	return 1.0


## AVANZA LO QUE SE PIDE un paso: el reloj de la piña y el descanso hacia su postura. *Hasta el 22/11/2026 la mano sólo se
## cerraba al pegar y cubrirse; ahora es siempre un puño (ver `mount_common_hand`).*
func _advance(delta: float) -> void:
	if punching != Punch.NONE:
		_clock += delta
		if not _landed and (stage() == Stage.HOLD or stage() == Stage.RETURN):
			_land()
		if _clock >= _punch_time():
			punching = Punch.NONE
			punch_strength = 1.0
	_rest = _rest.move_toward(stance_at(stance), STANCE_SPEED * reach() * delta)
	_follow_charge()
	if tip != null:
		tip.step(delta)


## LO CARGADO AHORA: lo mide quien la simula (`charging_since`); en las demás máquinas llega por la red (MechArmsNet).
func _follow_charge() -> void:
	if charging_since >= 0.0:
		windup_share = clampf((Time.get_ticks_msec() / 1000.0 - charging_since) / CageHandling.current.punch_charge_time, 0.0,
			charge_cap)
		return
	var net := MechArmsNet.of(self)
	if net == null or not net.remote():
		windup_share = 0.0


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
	elif tip != null and not tip.strike_path().is_empty():
		_aimed = tip.strike_path()
	return true


## CUÁNTO VA DE LA PARTE DE LA PIÑA EN QUE ESTÁ (0 a 1; ver `stage`): lo usan las puntas que animan algo propio (el
## golpe de muñeca del palo).
func stage_share() -> float:
	if punching == Punch.NONE:
		return 0.0
	var clock := _clock * _punch_speed()
	for step: Array in _steps():
		var time := float(step[0])
		if clock <= time:
			return clampf(clock / maxf(time, 0.001), 0.0, 1.0)
		clock -= time
	return clampf(clock / RETURN_TIME, 0.0, 1.0)


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
	var wanted := tip.wanted(asked) if tip != null else asked
	if limp <= 0.0:
		return wanted
	var hanging := LIMP_WAY.normalized() * (upper_length() + forearm_length()) * LIMP_REACH
	var shake := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * LIMP_SHAKE * limp
	return wanted.lerp(hanging, smoothstep(0.0, 1.0, limp)) + shake


## Lo que piden las piñas y las posturas: a lo largo de la piña y de vuelta a su postura, o en su postura más lo que lo
## corrieron a mano.
func _moves() -> Vector3:
	var home := _rest + _offset
	if punching == Punch.NONE:
		if windup_share > 0.0:
			return home.lerp(_windup_at(), smoothstep(0.0, 1.0, windup_share) * WINDUP_MAX)
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
	return total / _punch_speed()


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


## HACIA DÓNDE DOBLA EL CODO desde el hombro, en el mundo (la de MechBody.arm: `elbow_hint` o la de siempre, del lado de
## este brazo, en los ejes del torso `torso`).
func elbow_way(torso: Basis) -> Vector3:
	var toward := MechBody.ELBOW_HINT if elbow_hint == Vector3.ZERO else elbow_hint
	return torso * Vector3(side * toward.x, toward.y, toward.z)


## EL BRAZO CON SUS HUESOS (18/11/2026; paso 3 del esqueleto): LA IK COMÚN (IkUtil.solve_two_bone_ik, la de los
## personajes y las piernas) pone el codo y la muñeca, con el codo doblando hacia `elbow_way`; después cada hueso gira
## sobre su largo hasta su eje del codo (`_hinge`, que sale de `pose`), como sus piezas (MechSkeleton.roll). Los huesos
## no se mueven de donde nacen (el hombro, el codo).
func _reach_bones(pose: Dictionary, torso: Basis) -> void:
	var shoulder: Vector3 = pose["shoulder"]
	IkUtil.solve_two_bone_ik(upper_bone, forearm_bone, pose["wrist"], shoulder + elbow_way(torso))
	# Girar el brazo sobre su largo gira también al antebrazo, que cuelga de él: se lo deja donde apuntaba.
	var forearm_was := forearm_bone.global_basis
	MechSkeleton.roll(upper_bone, _hinge)
	forearm_bone.transform.basis = upper_bone.global_basis.orthonormalized().inverse() * forearm_was
	MechSkeleton.roll(forearm_bone, _hinge)


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
	# SIEMPRE UN PUÑO (22/11/2026; el usuario: «debería estar con la mano siempre cerrada»).
	_hand.fist = true
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


## ── EL GOLPE: SU ZONA (ver MechSkills) ──────────────────────────────────────────────────────────────────────────────

## LA PIÑA LLEGÓ: le pega a lo que esté en la zona de lo que lleva, una vez.
func _land() -> void:
	_landed = true
	if tip == null:
		return
	var zone := tip.zone()
	if zone.is_empty():
		return
	var way := -anchor.global_basis.z
	way.y = 0.0
	way = way.normalized()
	var power := punch_strength * tip.zone_power()
	var origin := anchor.global_position
	var floor_at := origin
	if anchor is BalanceBody:
		floor_at.y = (anchor as BalanceBody).support.y
	if cast_here:
		MechSkills.blast(anchor.get_parent(), zone, floor_at, way)
	if MechSkills.land(anchor, zone, origin, way, tip.zone_source(), power, MechSkills.STRIKE_IMPULSE * power) > 0:
		var sounds_node := MechSounds.of(self)
		if sounds_node != null:
			sounds_node.play_at(MechSounds.STRIKE_HIT, origin + way * float(zone["length"]) * 0.5, 1.0, 1.0)
