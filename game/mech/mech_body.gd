class_name MechBody
extends RefCounted

## EL CUERPO DE LA MECA, DEFINIDO UNA SOLA VEZ (11/11/2026): sus medidas, sus partes y cómo se arma su postura. Lo usan
## la meca de pelea (Mech: el torso es su cabina, MechTorso; las piernas las dibuja MechLeg y los brazos MechArm) y la
## meca de equilibrio (MechDummy: una pieza física por parte, que de pie van adonde dice la postura y caídas son su
## muñeco). *Antes la meca de equilibrio tenía su propia copia de las piernas y los brazos, armada de memoria: el pie iba
## pegado a la canilla, sin tobillo, y quedaba inclinado como ella (lo vio el usuario: «no tiene bien los pies
## plantados… siendo que supuestamente es el mismo sistema»).*
##
## LAS PARTES, de abajo para arriba:
##   · los PIES: planos sobre el piso, mirando hacia donde miran las piernas; el TOBILLO, `ANKLE` arriba del piso.
##   · las CANILLAS y los MUSLOS, del tobillo a la cadera; la RODILLA sale de los dos largos (ver `joint`), hacia adelante.
##   · la PELVIS, donde van las piernas (lo pidió el usuario: «la pelvis… que gira independiente del torso, que es donde
##     van conectadas las piernas… ahora… es monolítico»): mira hacia donde caminan las piernas y se inclina con el
##     equilibrio, colgada de la CINTURA.
##   · el TORSO, encima de la cintura: gira aparte sobre la pelvis (`twist`). Su origen es el piso de abajo (como el de
##     MechTorso).
##   · los BRAZOS, del HOMBRO (en el torso) al PUÑO; el CODO sale de los dos largos, hacia afuera y abajo.
##
## LA POSTURA se arma de afuera hacia adentro: la RAÍZ (la meca en el suelo: su lugar y hacia dónde caminan las piernas),
## la altura de la cintura, la inclinación (`tilt`, del equilibrio), el giro del torso y dónde están los pies y los puños.
## Todo en el mundo.

## La cintura: dónde se apoya el torso, sobre el suelo, parada.
const WAIST := 7.4
const PELVIS_SIZE := Vector3(6.6, 1.8, 3.6)
## Las caderas, a los costados de la pelvis y debajo de la cintura.
const HIP_X := 2.7
const HIP_DROP := 1.2
const THIGH := 4.4
const SHIN := 4.4
const LEG_THICKNESS := 1.1
const ANKLE := 0.6
const FOOT_SIZE := Vector3(2.2, 0.7, 3.4)
## Cuánto va el pie adelante del tobillo.
const FOOT_AHEAD := 0.4
## Dónde se paran los pies, a cada lado.
const STANCE_X := HIP_X + 0.3
const UPPER_ARM := 5.5
const FOREARM := 5.5
const ARM_THICKNESS := 1.3
const FOREARM_THICKNESS := 1.1
## El hombro, en el espacio del torso (`x` del lado derecho; el izquierdo, al revés).
const SHOULDER := Vector3(MechTorso.WIDTH * 0.5 + 1.3, 0.0, -0.6)
## Hacia dónde dobla el codo, en el espacio del torso (`x` del lado derecho): afuera, abajo y un poco atrás.
const ELBOW_HINT := Vector3(1.0, -0.8, 0.5)
## El puño en guardia, en el espacio del hombro (`x` del lado derecho: hacia adentro es −x).
const GUARD := Vector3(-1.8, 0.3, -5.5)


## La altura del hombro en el torso (sobre el piso de abajo).
static func shoulder_height() -> float:
	return MechTorso.floor_y(1) + 1.6


## El hombro de `side` (−1 izquierdo, 1 derecho), en el espacio del torso.
static func shoulder_local(side: float) -> Vector3:
	return Vector3(side * SHOULDER.x, shoulder_height(), SHOULDER.z)


## La guardia del puño de `side`, en el espacio de su hombro.
static func guard_local(side: float) -> Vector3:
	return Vector3(side * GUARD.x, GUARD.y, GUARD.z)


## LA INCLINACIÓN: `lean` es el ángulo (radianes) hacia cada lado, x a la derecha e y adelante, en el espacio de la
## raíz. Gira alrededor del eje horizontal que la hace caer para ese lado.
static func tilt(lean: Vector2) -> Basis:
	if lean.length() < 0.0001:
		return Basis()
	var toward := Vector3(lean.x, 0.0, -lean.y).normalized()
	return Basis(Vector3.UP.cross(toward).normalized(), lean.length())


## LA CINTURA en el mundo: sobre la raíz, a `height`, inclinada.
static func waist(root: Transform3D, height: float, lean_basis: Basis) -> Transform3D:
	return root * Transform3D(lean_basis, Vector3(0.0, height, 0.0))


## LA PELVIS (su centro), colgada de la cintura.
static func pelvis(waist_transform: Transform3D) -> Transform3D:
	return waist_transform * Transform3D(Basis(), Vector3(0.0, -PELVIS_SIZE.y * 0.5, 0.0))


## EL TORSO (su origen, el piso de abajo): sobre la cintura, girado `twist` sobre la pelvis.
static func torso(waist_transform: Transform3D, twist: float) -> Transform3D:
	return waist_transform * Transform3D(Basis(Vector3.UP, twist), Vector3.ZERO)


## La cadera de `side`, en el mundo.
static func hip(waist_transform: Transform3D, side: float) -> Vector3:
	return waist_transform * Vector3(side * HIP_X, -HIP_DROP, 0.0)


## Dónde se para el pie de `side` con la meca quieta: el punto del piso, en el mundo.
static func foot_rest(root: Transform3D, side: float) -> Vector3:
	return root * Vector3(side * STANCE_X, 0.0, 0.0)


## UNA PIERNA, de la cadera `hip` al pie apoyado en `ground` (el punto del piso bajo el tobillo, en el mundo; con el pie
## en el aire, más arriba), con el pie mirando según `facing` (sólo cuenta su giro). Devuelve las partes (`thigh`,
## `shin`, `foot`: su centro y orientación; los largos van por −Z) y las articulaciones (`knee`, `ankle`).
static func leg(hip_point: Vector3, ground: Vector3, facing: Basis) -> Dictionary:
	var forward := -facing.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length_squared() > 0.0001 else Vector3.FORWARD
	var flat := Basis.looking_at(forward, Vector3.UP)
	var ankle := ground + Vector3.UP * ANKLE
	var knee := joint(hip_point, ankle, THIGH, SHIN, forward)
	var reach := (ankle - hip_point).limit_length(THIGH + SHIN - 0.01)
	var end := hip_point + reach
	return {
		"thigh": segment(hip_point, knee, forward),
		"shin": segment(knee, end, forward),
		"foot": Transform3D(flat, ground + flat * Vector3(0.0, FOOT_SIZE.y * 0.5, -FOOT_AHEAD)),
		"knee": knee,
		"ankle": end,
	}


## UN BRAZO, del hombro `shoulder_point` al puño `fist` (en el mundo, o en el espacio que sea, con `torso_basis` el del
## torso en ese espacio). Devuelve `upper` y `forearm` (centro y orientación; el largo por −Z), `elbow` y `wrist` (el
## puño, al alcance).
static func arm(shoulder_point: Vector3, fist: Vector3, side: float, torso_basis: Basis) -> Dictionary:
	var hint := torso_basis * Vector3(side * ELBOW_HINT.x, ELBOW_HINT.y, ELBOW_HINT.z)
	var elbow := joint(shoulder_point, fist, UPPER_ARM, FOREARM, hint)
	var wrist := shoulder_point + (fist - shoulder_point).limit_length(UPPER_ARM + FOREARM - 0.01)
	var up := torso_basis * Vector3.UP
	return {
		"upper": segment(shoulder_point, elbow, up),
		"forearm": segment(elbow, wrist, up),
		"elbow": elbow,
		"wrist": wrist,
	}


## UNA PARTE LARGA entre dos puntos: su −Z va de `from` a `to`, su +Y hacia `up` (lo que se pueda), y su origen en el
## medio.
static func segment(from: Vector3, to: Vector3, up: Vector3) -> Transform3D:
	var along := to - from
	if along.length_squared() < 0.000001:
		return Transform3D(Basis(), from)
	along = along.normalized()
	var hint := up.normalized() if absf(along.dot(up.normalized())) < 0.95 else Vector3.BACK
	return Transform3D(Basis.looking_at(along, hint), (from + to) * 0.5)


## LA ARTICULACIÓN DEL MEDIO de dos huesos (`first` desde `root`, `second` hasta `end`): ley del coseno en la raíz,
## doblada hacia `hint` sin la parte que va a lo largo. La rodilla y el codo.
static func joint(root: Vector3, end: Vector3, first: float, second: float, hint: Vector3) -> Vector3:
	var reach := end - root
	var distance := clampf(reach.length(), 0.5, first + second - 0.01)
	var along := reach.normalized()
	var cosine := (first * first + distance * distance - second * second) / (2.0 * first * distance)
	var angle := acos(clampf(cosine, -1.0, 1.0))
	var bend := (hint - along * hint.dot(along)).normalized()
	if bend.length_squared() < 0.01:
		bend = Vector3.FORWARD
	return root + along * cos(angle) * first + bend * sin(angle) * first
