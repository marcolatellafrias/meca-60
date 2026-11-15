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
var measures := MechBody.current
## La postura pedida, y la piña que está tirando.
var stance := Stance.COVER
var punching := Punch.NONE

var _clock := 0.0
var _from := Vector3.ZERO
## Dónde descansa el puño ahora (va hacia el de la postura pedida) y lo que lo corrió quien lo lleva a mano.
var _rest := Vector3.ZERO
var _offset := Vector3.ZERO
var _hand: MechHand = null
## Los puntos de la piña tirada hacia un lugar (ver `punch_at`); vacío, la piña va por los suyos (`PUNCHES`).
var _aimed: Array = []
## El eje de la bisagra del codo, en el mundo: sale del brazo y el antebrazo pedidos; con el brazo estirado no se puede
## calcular y queda el último.
var _hinge := Vector3.RIGHT


## Tira una piña (si no está en otra). Devuelve si la tiró.
func punch(kind: Punch) -> bool:
	if punching != Punch.NONE or kind == Punch.NONE:
		return false
	_from = _wanted()
	punching = kind
	_clock = 0.0
	_aimed = []
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
	_rest = _rest.move_toward(stance_at(stance), STANCE_SPEED * reach() * delta)
	if _hand != null:
		_hand.fist = punching != Punch.NONE or stance == Stance.COVER


## Un punto de las piñas o la guardia, en el espacio de lo que lo sostiene: `x` va hacia afuera de su lado.
func _local(point: Vector3) -> Vector3:
	return Vector3(side * point.x, point.y, point.z)


## DÓNDE DESCANSA EL PUÑO en la postura `which` (ver `STANCES`), con el largo de este brazo.
func stance_at(which: Stance) -> Vector3:
	return (STANCES[which] as Vector3) * reach()


## EL LARGO DE ESTE BRAZO: el factor de las posturas y las piñas (el `reach` de sus medidas), y el brazo y el antebrazo
## (m).
func reach() -> float:
	return measures.reach


func upper_length() -> float:
	return measures.UPPER_ARM


func forearm_length() -> float:
	return measures.FOREARM


## DÓNDE SE PIDE EL PUÑO AHORA, desde el hombro (como `STANCES`): a lo largo de la piña y de vuelta a su postura, o en
## su postura más lo que lo corrieron a mano.
func _wanted() -> Vector3:
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
	var arm := measures.arm(shoulder, fist, side, torso)
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
	_hand = MechHand.build(forearm, side)
	_hand.scale = Vector3.ONE * measures.thick
	_hand.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5), Vector3(0, 0, -forearm_length() * 0.5))
