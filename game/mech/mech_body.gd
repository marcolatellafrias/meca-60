class_name MechBody
extends RefCounted

## EL CUERPO DE LA MECA, DEFINIDO UNA SOLA VEZ (11/11/2026): sus medidas, sus partes y cómo se arma su postura. Lo usan
## los cubos con piernas y la meca (las piernas las dibuja MechLeg; los brazos, MechArm y los suyos). *Nació para que la
## meca de pelea y la de equilibrio, las dos borradas el 13/11/2026, fueran el mismo cuerpo: la segunda tenía su propia
## copia de las piernas, armada de memoria, con el pie pegado a la canilla (lo vio el usuario: «no tiene bien los pies
## plantados… siendo que supuestamente es el mismo sistema»).*
##
## LAS PARTES, de abajo para arriba:
##   · los PIES: planos sobre el piso, mirando hacia donde miran las piernas; el TOBILLO, `ANKLE` arriba del piso.
##   · las CANILLAS y los MUSLOS, del tobillo a la cadera; la RODILLA sale de los dos largos (ver `joint`), hacia adelante.
##   · la PELVIS, donde van las piernas (lo pidió el usuario: «la pelvis… que gira independiente del torso, que es donde
##     van conectadas las piernas… ahora… es monolítico»): mira hacia donde caminan las piernas y se inclina con el
##     equilibrio, colgada de la CINTURA.
##   · el TORSO, encima de la cintura: gira aparte sobre la pelvis (`twist`). Su origen es el piso de abajo.
##   · los BRAZOS, del HOMBRO (en el torso) al PUÑO; el CODO sale de los dos largos, hacia afuera y abajo.
##
## LA POSTURA se arma de afuera hacia adentro: la RAÍZ (la meca en el suelo: su lugar y hacia dónde caminan las piernas),
## la altura de la cintura, la inclinación (`tilt`, del equilibrio), el giro del torso y dónde están los pies y los puños.
## Todo en el mundo.

## LAS MEDIDAS VAN CON LA CAJA (el usuario, 13/11/2026: «si achico el cubo de 4x4 a 2x2, se achicarían a la mitad los
## brazos y las piernas»): `scale` es el lado de la caja sobre el de siempre (8,03 m, ver CabinGrid.shape) y cada medida
## de abajo es la de siempre (`BASE`) por ese número. Las pone `scale_to`.
const BASE := {
	"WAIST": 7.4, "HIP_X": 2.7, "HIP_DROP": 1.2, "THIGH": 4.4, "SHIN": 4.4, "LEG_THICKNESS": 2.1, "ANKLE": 0.6,
	"FOOT_SIZE": Vector3(2.2, 0.7, 3.4), "FOOT_AHEAD": 0.4, "UPPER_ARM": 5.5, "FOREARM": 5.5,
}
static var scale := 1.0
## La cintura: dónde se apoya el torso, sobre el suelo, parada.
static var WAIST := 7.4
## Las caderas, a los costados de la pelvis y debajo de la cintura.
static var HIP_X := 2.7
static var HIP_DROP := 1.2
static var THIGH := 4.4
static var SHIN := 4.4
## Las piernas, macizas (lo pidió el usuario el 12/11/2026: «más chunky»), y sus ARTICULACIONES —cadera, rodilla,
## tobillo—, discos de ese mismo grosor, con el eje de costado.
static var LEG_THICKNESS := 2.1
static var JOINT_RADIUS := LEG_THICKNESS * 0.62
## La pelvis, entre los dos discos de las caderas: corta, para darles lugar.
static var PELVIS_SIZE := Vector3(HIP_X * 2.0 - LEG_THICKNESS, 1.8, 3.6)
## El color de las articulaciones y de los pies: un poco más oscuro que la pierna, no negro.
const JOINT_COLOR := Color(0.36, 0.375, 0.4)
static var ANKLE := 0.6
static var FOOT_SIZE := Vector3(2.2, 0.7, 3.4)
## Cuánto va el pie adelante del tobillo.
static var FOOT_AHEAD := 0.4
## Dónde se paran los pies, a cada lado.
static var STANCE_X := HIP_X + 0.3
static var UPPER_ARM := 5.5
static var FOREARM := 5.5
## Hacia dónde dobla el codo, en el espacio del torso (`x` del lado derecho): afuera, abajo y un poco atrás.
const ELBOW_HINT := Vector3(1.0, -0.8, 0.5)


## PONE LAS MEDIDAS PARA UNA CAJA `k` veces la de siempre. Lo que se armó antes no cambia (ver CabinShapePanel, que
## rearma las mecas). La altura y los pasos de las perillas (BodySettings) van en la misma proporción.
static func scale_to(k: float) -> void:
	if is_equal_approx(k, scale):
		return
	var knobs := BodySettings.current
	var ratio := k / scale
	for name: String in ["hover_height", "step_reach", "step_height", "settle_gap"]:
		knobs.set(name, float(knobs.get(name)) * ratio)
	scale = k
	WAIST = BASE["WAIST"] * k
	HIP_X = BASE["HIP_X"] * k
	HIP_DROP = BASE["HIP_DROP"] * k
	THIGH = BASE["THIGH"] * k
	SHIN = BASE["SHIN"] * k
	LEG_THICKNESS = BASE["LEG_THICKNESS"] * k
	JOINT_RADIUS = LEG_THICKNESS * 0.62
	PELVIS_SIZE = Vector3(HIP_X * 2.0 - LEG_THICKNESS, 1.8 * k, 3.6 * k)
	ANKLE = BASE["ANKLE"] * k
	FOOT_SIZE = (BASE["FOOT_SIZE"] as Vector3) * k
	FOOT_AHEAD = BASE["FOOT_AHEAD"] * k
	STANCE_X = HIP_X + 0.3 * k
	UPPER_ARM = BASE["UPPER_ARM"] * k
	FOREARM = BASE["FOREARM"] * k


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
## en el aire, más arriba), con el pie mirando según `facing` (sólo cuenta su giro). La rodilla dobla hacia `knee_way`
## (por defecto, hacia donde mira el pie). Devuelve las partes (`thigh`, `shin`, `foot`: su centro y orientación; los
## largos van por −Z) y las articulaciones (`knee`, `ankle`).
static func leg(hip_point: Vector3, ground: Vector3, facing: Basis, knee_way := Vector3.ZERO) -> Dictionary:
	var forward := -facing.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length_squared() > 0.0001 else Vector3.FORWARD
	var flat := Basis.looking_at(forward, Vector3.UP)
	var ankle := ground + Vector3.UP * ANKLE
	var bend := knee_way if knee_way.length_squared() > 0.0001 else forward
	var knee := joint(hip_point, ankle, THIGH, SHIN, bend)
	var reach := (ankle - hip_point).limit_length(THIGH + SHIN - 0.01)
	var end := hip_point + reach
	return {
		"thigh": segment(hip_point, knee, bend),
		"shin": segment(knee, end, bend),
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
