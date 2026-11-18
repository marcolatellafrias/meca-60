class_name MechBody
extends RefCounted

## EL CUERPO DE LA MECA, DEFINIDO UNA SOLA VEZ (11/11/2026): sus medidas, sus partes y cómo se arma su postura. Lo usa
## la meca (las piernas las dibuja MechLeg; los brazos, MechArm y los suyos). *Nació para que la
## meca de pelea y la de equilibrio, las dos borradas el 13/11/2026, fueran el mismo cuerpo: la segunda tenía su propia
## copia de las piernas, armada de memoria, con el pie pegado a la canilla (lo vio el usuario: «no tiene bien los pies
## plantados… siendo que supuestamente es el mismo sistema»).*
##
## LAS PARTES, de abajo para arriba:
##   · los PIES: planos sobre el piso, mirando hacia donde miran las piernas; el TOBILLO, `ANKLE` arriba del piso.
##   · las CANILLAS y los MUSLOS, del tobillo a la cadera; la RODILLA sale de los dos largos (la IK común, IkUtil.bend_point), hacia adelante.
##   · la PELVIS, donde van las piernas (lo pidió el usuario: «la pelvis… que gira independiente del torso, que es donde
##     van conectadas las piernas… ahora… es monolítico»): mira hacia donde caminan las piernas y se inclina con el
##     equilibrio, colgada de la CINTURA.
##   · el TORSO, encima de la cintura: gira aparte sobre la pelvis (`twist`). Su origen es el piso de abajo.
##   · los BRAZOS, del HOMBRO (en el torso) al PUÑO; el CODO sale de los dos largos, hacia afuera y abajo.
##
## LA POSTURA se arma de afuera hacia adentro: la RAÍZ (la meca en el suelo: su lugar y hacia dónde caminan las piernas),
## la altura de la cintura, la inclinación (`tilt`, del equilibrio), el giro del torso y dónde están los pies y los puños.
## Todo en el mundo.

## LAS MEDIDAS SE ELIGEN (el usuario, 13/11/2026: «tenga unos ciertos tamaños discretos, chico, mediano, grande… el
## ancho global y el largo de los brazos como cosas independientes… el ancho va a cambiar… la mano… los hombros, las
## articulaciones, los pies, y el largo va a cambiar solamente el largo de los conectores»; el ancho, uno para brazos y
## piernas; los largos, separados). Las pone `dress`: cada medida de abajo es la de siempre (`BASE`) por el factor de
## su tamaño (`SIZES`). *Del 13/11/2026 a la tarde, todo iba con el lado de la caja; el usuario: «prefiero que no
## dependa tanto de la caja».*
const BASE := {
	"WAIST": 7.4, "HIP_X": 2.7, "HIP_DROP": 1.2, "THIGH": 4.4, "SHIN": 4.4, "LEG_THICKNESS": 2.1,
	"FOOT_SIZE": Vector3(2.2, 0.7, 3.4), "FOOT_AHEAD": 0.4, "UPPER_ARM": 5.5, "FOREARM": 5.5,
}
## LO MÁS QUE SE ESTIRA UNA PIERNA: de la cadera al tobillo, en partes de su largo (muslo y canilla). Una sola regla para
## el tope y para el `stretch` de parada, en partes y no en metros, así vale igual para la meca grande y para la jaula al
## 30 % (16/11/2026, el usuario: «cuando no se agacha [los pies] están flotando… lo de distancia de piernas al máximo aún
## tiene las piernas re dobladas»). *Hasta ese día el tope era el largo menos 0,5 m: en la jaula, un 19 % de la pierna, y
## con el estirado al máximo (0,9) los pies quedaban colgando 24 cm.*
const STRAIGHTEST := 0.98
## LAS ARTICULACIONES: su radio, en partes del grosor de la pierna; el tobillo, una esfera algo más chica.
const JOINT_SHARE := 0.62
const ANKLE_SHARE := 0.85
## Chico, mediano (el de siempre) y grande.
const SIZES: Array[float] = [0.75, 1.0, 1.25]
## UN CUERPO ES UN OBJETO DE MEDIDAS (15/11/2026; el usuario, de la meca del vórtice: «cada panel de la meca original
## debería poder tener como varias variaciones si se le cambia algo estructural… después de todo es solamente
## información»): cada meca lleva el suyo (BalanceBody.measures, que le da su cabina en Mech.cabin_kit: el de la forma
## de la jaula, `from_shape`, achicado). *Hasta el 15/11/2026 eran medidas estáticas, una para todas; hasta el
## 17/11/2026 había también uno común (`current`), el del F2 de la cabina cuadrada de la meca grande, borrada ese día.*


## UN CUERPO CON LAS MEDIDAS de una forma guardada que tenga los cinco campos del cuerpo (`thickness`, `arm_length`,
## `leg_length`, `leg_stretch`, `shoulder_out`: CageShape).
static func from_shape(shape: Resource) -> MechBody:
	var body := MechBody.new()
	body.dress(shape.get("thickness"), shape.get("arm_length"), shape.get("leg_length"), shape.get("leg_stretch"),
		shape.get("shoulder_out"))
	return body


## LO ACHICA PAREJO: todas sus medidas y sus factores (el ancho, el alcance y el paso) por `k`. La meca jaula va al 30 %
## de lo que digan sus perillas de «Brazos y piernas» (el usuario, 16/11/2026: «mantener estos grosores y estos largos
## de brazos que me gustan»; «los paneles deberían ser los mismos que la meca común»). *Hasta ese día la jaula tenía
## un cuerpo fijo, `scaled`, sin esas perillas.*
func shrink(k: float) -> void:
	thick *= k
	reach *= k
	stride *= k
	WAIST *= k
	HIP_X *= k
	HIP_DROP *= k
	LEG_THICKNESS *= k
	JOINT_RADIUS *= k
	PELVIS_SIZE *= k
	ANKLE *= k
	FOOT_SIZE *= k
	FOOT_AHEAD *= k
	STANCE_X *= k
	THIGH *= k
	SHIN *= k
	UPPER_ARM *= k
	FOREARM *= k


## LO QUE SE ELIGIÓ: el tamaño (0, 1, 2) del ancho, del largo de los brazos y del de las piernas, y cuánto se estiran
## las piernas paradas (de la cadera al tobillo, en partes del largo de la pierna; con 0,64 queda la de siempre).
var thick_size := 1
var arm_size := 1
var leg_size := 1
var stretch := 0.64
## Cuánto salen los hombros del costado de la caja (m, con el ancho de siempre; ver Mech.shoulder).
var shoulder_out := 1.0
## Sus factores: el ancho (`thick`, para las manos, el puño y las articulaciones), el largo de los brazos (`reach`, para
## las posturas y las piñas) y el de las piernas (`stride`).
var thick := 1.0
var reach := 1.0
var stride := 1.0
## La cintura: dónde se apoya el torso, sobre el suelo, parada.
var WAIST := 7.4
## Las caderas, a los costados de la pelvis y debajo de la cintura.
var HIP_X := 2.7
var HIP_DROP := 1.2
var THIGH := 4.4
var SHIN := 4.4
## Las piernas, macizas (lo pidió el usuario el 12/11/2026: «más chunky»), y sus ARTICULACIONES —cadera, rodilla,
## tobillo—, discos de ese mismo grosor, con el eje de costado.
var LEG_THICKNESS := 2.1
var JOINT_RADIUS := LEG_THICKNESS * JOINT_SHARE
## La pelvis, entre los dos discos de las caderas: corta, para darles lugar.
var PELVIS_SIZE := Vector3(HIP_X * 2.0 - LEG_THICKNESS, 1.8, 3.6)
## El color de las articulaciones y de los pies: un poco más oscuro que la pierna, no negro.
const JOINT_COLOR := Color(0.36, 0.375, 0.4)
var ANKLE := 2.1 * JOINT_SHARE * ANKLE_SHARE
var FOOT_SIZE := Vector3(2.2, 0.7, 3.4)
## Cuánto va el pie adelante del tobillo.
var FOOT_AHEAD := 0.4
## Dónde se paran los pies, a cada lado.
var STANCE_X := HIP_X + 0.3
var UPPER_ARM := 5.5
var FOREARM := 5.5
## Hacia dónde dobla el codo, en el espacio del torso (`x` del lado derecho): afuera, abajo y un poco atrás.
const ELBOW_HINT := Vector3(1.0, -0.8, 0.5)


## PONE LAS MEDIDAS: el ancho (`thickness`), el largo de los brazos y de las piernas (0 chico, 1 mediano, 2 grande) y
## cuánto se estiran las piernas paradas. LA CINTURA SALE DE AHÍ —el tobillo, la caída de la cadera y lo estirada que
## está la pierna—, y es la altura de la caja sobre el piso (Mech la toma al armarse: BalanceBody.hover); el paso del F1
## lo escalan las piernas con `stride` al leerlo. NO ESCRIBE NINGUNA PERILLA (cada número, un solo dueño). Lo que se armó
## antes no cambia (ver Mech.rebuild_all).
func dress(thickness: int, arm_length: int, leg_length: int, leg_stretch: float, shoulder := 1.0) -> void:
	shoulder_out = shoulder
	thick_size = clampi(thickness, 0, SIZES.size() - 1)
	arm_size = clampi(arm_length, 0, SIZES.size() - 1)
	leg_size = clampi(leg_length, 0, SIZES.size() - 1)
	stretch = leg_stretch
	thick = SIZES[thick_size]
	reach = SIZES[arm_size]
	stride = SIZES[leg_size]
	HIP_X = BASE["HIP_X"] * thick
	HIP_DROP = BASE["HIP_DROP"] * thick
	LEG_THICKNESS = BASE["LEG_THICKNESS"] * thick
	JOINT_RADIUS = LEG_THICKNESS * JOINT_SHARE
	PELVIS_SIZE = Vector3(HIP_X * 2.0 - LEG_THICKNESS, 1.8 * thick, 3.6 * thick)
	ANKLE = MechBody.ankle_for(LEG_THICKNESS)
	FOOT_SIZE = (BASE["FOOT_SIZE"] as Vector3) * thick
	FOOT_AHEAD = BASE["FOOT_AHEAD"] * thick
	STANCE_X = HIP_X + 0.3 * thick
	THIGH = BASE["THIGH"] * stride
	SHIN = BASE["SHIN"] * stride
	UPPER_ARM = BASE["UPPER_ARM"] * reach
	FOREARM = BASE["FOREARM"] * reach
	WAIST = MechBody.waist_for(thickness, leg_length, leg_stretch)


## EL ALTO DEL TOBILLO sobre el piso: el radio de su esfera, así apoya en el piso sin atravesarlo; el pie (más fino)
## queda debajo. LA CINTURA SE MIDE DESDE AHÍ: tobillo, piernas (de la esfera del tobillo a la de la cadera, ver
## `STRAIGHTEST`) y la caída de la cadera (16/11/2026, el usuario: «que su punto de referencia realmente sean las esferas
## de la pelvis… tomar en cuenta grosor de pies»). *Hasta ese día el tobillo iba a 0,6 m (en la grande) y su esfera,
## de 1,1 m, se hundía medio metro en el piso.*
static func ankle_for(leg_thickness: float) -> float:
	return leg_thickness * JOINT_SHARE * ANKLE_SHARE


## Lo más lejos que llega el tobillo desde la cadera (ver `STRAIGHTEST`).
func leg_reach() -> float:
	return (THIGH + SHIN) * STRAIGHTEST


## LA CINTURA que sale de un ancho, un largo de pierna y un estirado (sin ponerlos): para mostrarla antes de guardar.
static func waist_for(thickness: int, leg_length: int, leg_stretch: float) -> float:
	var t := SIZES[clampi(thickness, 0, SIZES.size() - 1)]
	var l := SIZES[clampi(leg_length, 0, SIZES.size() - 1)]
	return MechBody.ankle_for(float(BASE["LEG_THICKNESS"]) * t) + float(BASE["HIP_DROP"]) * t \
		+ (float(BASE["THIGH"]) + float(BASE["SHIN"])) * l * leg_stretch


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
func pelvis(waist_transform: Transform3D) -> Transform3D:
	return waist_transform * Transform3D(Basis(), Vector3(0.0, -PELVIS_SIZE.y * 0.5, 0.0))


## EL TORSO (su origen, el piso de abajo): sobre la cintura, girado `twist` sobre la pelvis.
static func torso(waist_transform: Transform3D, twist: float) -> Transform3D:
	return waist_transform * Transform3D(Basis(Vector3.UP, twist), Vector3.ZERO)


## La cadera de `side`, en el mundo.
func hip(waist_transform: Transform3D, side: float) -> Vector3:
	return waist_transform * Vector3(side * HIP_X, -HIP_DROP, 0.0)


## Dónde se para el pie de `side` con la meca quieta: el punto del piso, en el mundo.
func foot_rest(root: Transform3D, side: float) -> Vector3:
	return root * Vector3(side * STANCE_X, 0.0, 0.0)


## UNA PIERNA, de la cadera `hip` al pie apoyado en `ground` (el punto del piso bajo el tobillo, en el mundo; con el pie
## en el aire, más arriba), con el pie mirando según `facing` (sólo cuenta su giro). La rodilla dobla hacia `knee_way`
## (por defecto, hacia donde mira el pie). Devuelve las partes (`thigh`, `shin`, `foot`: su centro y orientación; los
## largos van por −Z) y las articulaciones (`knee`, `ankle`).
func leg(hip_point: Vector3, ground: Vector3, facing: Basis, knee_way := Vector3.ZERO) -> Dictionary:
	var forward := -facing.z
	forward.y = 0.0
	forward = forward.normalized() if forward.length_squared() > 0.0001 else Vector3.FORWARD
	var flat := Basis.looking_at(forward, Vector3.UP)
	var ankle := ground + Vector3.UP * ANKLE
	var bend := knee_way if knee_way.length_squared() > 0.0001 else forward
	var knee := IkUtil.bend_point(hip_point, ankle, THIGH, SHIN, bend)
	var to_ankle := (ankle - hip_point).limit_length(leg_reach())
	var end := hip_point + to_ankle
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
func arm(shoulder_point: Vector3, fist: Vector3, side: float, torso_basis: Basis, elbow_hint := Vector3.ZERO) -> Dictionary:
	var toward := ELBOW_HINT if elbow_hint == Vector3.ZERO else elbow_hint
	var hint := torso_basis * Vector3(side * toward.x, toward.y, toward.z)
	var elbow := IkUtil.bend_point(shoulder_point, fist, UPPER_ARM, FOREARM, hint)
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
