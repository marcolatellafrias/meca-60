class_name BlockShape
extends Resource

## ── LA FORMA DE BLOQUES DE UN ARQUETIPO (31/10/2026, sesión de siluetas de los personajes) ─────────────────────────
## El sistema nuevo de proporciones, de cero, sobre el mismo esqueleto: unos pocos números en metros por arquetipo, de
## los que salen los huesos y el cuerpo de cajas y cápsulas (ver BlockBody). Lo pidió el usuario: «quiero cambiar
## bastante las proporciones y jugar con eso… quedarme de cualquier forma con el sistema viejo me va a limitar». El viejo
## —la forma del torso con sus loop cuts, la malla— quedó archivado y su malla se borró el 07/11/2026; la postura
## (la joroba, el encorvado del cuello, los hombros) sigue siendo del arquetipo, porque es de los huesos.
##
## ── LAS CINCO REGLAS (las aprobó el usuario) ────────────────────────────────────────────────────────────────
##   1. EL HOMBRO VA EN EL COSTADO DEL PECHO: la articulación, un radio de brazo debajo del tope de la caja del pecho y
##      justo en su costado, así con el brazo colgando se ve la mitad de su domo, afuera de la caja, y el tope del domo
##      queda al ras del tope del pecho. El ancho de hombros sale de ahí. (31/10/2026, el usuario: «si los brazos
##      estuvieran apuntando hacia abajo… se vería la mitad de la articulación». Iba un radio adentro del costado, y el
##      brazo salía de adentro del torso.)
##   2. LA CADERA, IGUAL: el muslo nace un radio de pierna adentro del costado y arriba del fondo de la caja de abajo. La
##      separación de las piernas sale de ahí.
##   3. EL TOBILLO VA ADENTRO DEL PIE: el pie mide de alto el radio de la pierna, y el tobillo está a esa altura.
##   4. EL CUELLO SALE DEL TORSO: del centro del tope de la caja del pecho, donde termina la columna.
##   5. EL ATLAS ES UN NÚMERO: a qué altura de la cabeza gira, en fracción de su alto. El cuello termina ahí.
## Un ancho por miembro: el brazo y el antebrazo miden lo mismo, y el muslo y la pierna también.
##
## Sin nada guardado, cada arquetipo arranca con su forma de fábrica, de proporciones realistas (ver FACTORY); lo que
## el F1 guarda (ver BlockShapes) manda. Las medidas del personaje salen de acá (ver SkeletonSizesUtil).

@export_group("Piernas")
@export_range(0.2, 2.0, 0.005, "suffix:m") var leg_length := 0.85
## Dónde cae la rodilla, en fracción de la pierna desde la cadera.
@export_range(0.2, 0.8, 0.01) var knee_at := 0.45
@export_range(0.03, 0.5, 0.005, "suffix:m") var leg_width := 0.14

@export_group("Torso")
@export_range(0.2, 1.5, 0.005, "suffix:m") var torso_height := 0.6
## Las tres cajas de la columna, de abajo arriba: la de la cadera, la del medio y la del pecho.
@export_range(0.1, 1.5, 0.005, "suffix:m") var lower_width := 0.36
@export_range(0.05, 1.2, 0.005, "suffix:m") var lower_depth := 0.24
@export_range(0.1, 1.5, 0.005, "suffix:m") var middle_width := 0.36
@export_range(0.05, 1.2, 0.005, "suffix:m") var middle_depth := 0.24
@export_range(0.1, 1.5, 0.005, "suffix:m") var chest_width := 0.42
@export_range(0.05, 1.2, 0.005, "suffix:m") var chest_depth := 0.26

@export_group("Brazos")
@export_range(0.2, 1.8, 0.005, "suffix:m") var arm_length := 0.7
## Dónde cae el codo, en fracción del brazo desde el hombro.
@export_range(0.2, 0.8, 0.01) var elbow_at := 0.45
## EL BRAZO, NUNCA FINITO (01/11/2026, el usuario: «quiero que se sientan un poco más chunky, a pesar de que sean
## flacos… que la baseline sea un brazo de grosor más o menos gruesito»): el piso del rango es ese grosor. La mano sale
## de acá: su muñeca es el ancho del brazo (ver TubeHand, la de bloques).
@export_range(0.09, 0.4, 0.005, "suffix:m") var arm_width := 0.115
## CUÁNTO SE ABREN LOS BRAZOS en reposo, en grados, puesto a ojo por arquetipo (01/11/2026, el usuario: «que
## simplemente sea un valor hecho a mano a ojo»). Es la única apertura: la de la pose se fue (03/11/2026).
## 0 ES ROZANDO EL TORSO (03/11/2026, lo pidió el usuario: el torso se le comía los brazos al flaco alto): el
## hombro va un radio de brazo afuera del costado del pecho, así colgando derecho el brazo apenas lo toca, y se cuenta
## desde el ángulo en que tampoco entra en la panza ni en la cadera, si son más anchas (ver `_touch_angle`). *Antes el
## hombro iba en el costado del pecho y se contaba desde la vertical: la mitad del brazo quedaba adentro del torso.*
@export_range(0.0, 30.0, 0.5, "suffix:°") var arm_open := 6.0

@export_group("Cuello y cabeza")
## Lo que se ve del cuello, del tope del pecho al fondo de la cabeza.
@export_range(0.0, 0.5, 0.005, "suffix:m") var neck_length := 0.05
@export_range(0.02, 0.4, 0.005, "suffix:m") var neck_width := 0.1
## EL ALTO DE LA CABEZA: todo lo que la forma de bloques dice de ella. El ancho y el fondo son los de su forma de cabeza
## (ver HeadForm), llevada a este alto (ver SkeletonSizesUtil._head). *Hasta el 13/11/2026 la cabeza era una caja con su ancho y
## su fondo; lo guardado de entonces se ignora (ver `_set`).*
@export_range(0.08, 0.8, 0.005, "suffix:m") var head_height := 0.26
## A qué altura de la cabeza gira: 0 desde su base, 0,3 desde adentro.
@export_range(0.0, 0.8, 0.01) var atlas := 0.25
## EL CUELLO NACE ADELANTE (02/11/2026, el usuario: «que sea un toggle, que la cabeza salga desde ahí, y que lo de
## encorvado sea otra cosa»): apagado, nace en el centro de la tapa del pecho (regla 4); prendido, pegado a su cara de
## adelante, con el frente del cuello al ras del frente del pecho. El encorvado (la pose) lo inclina aparte.
@export var neck_forward := false

## EL PIE, SÓLO SU LARGO (31/10/2026, el usuario: «sacaría tanto la variable de ancho como la de talón… y la de
## alto que sea proporcional siempre al ancho»): de ancho, el de la pierna; de alto, su radio (regla 3); y arranca atrás
## en la línea de la cápsula, sin escalón (ver BlockBody._foot).
@export_group("Pies")
@export_range(0.05, 0.6, 0.005, "suffix:m") var foot_length := 0.26

## Cómo se llama cada número en la pestaña Cuerpo del panel de locomoción (ver LocomotionTuner), y sus grupos, en orden.
const LABELS := {
	"leg_length": "largo", "knee_at": "rodilla", "leg_width": "ancho",
	"torso_height": "alto", "lower_width": "cadera, ancho", "lower_depth": "cadera, fondo",
	"middle_width": "medio, ancho", "middle_depth": "medio, fondo", "chest_width": "pecho, ancho",
	"chest_depth": "pecho, fondo",
	"arm_length": "largo", "elbow_at": "codo", "arm_width": "ancho", "arm_open": "apertura",
	"neck_length": "cuello, largo", "neck_width": "cuello, ancho",
	"head_height": "cabeza, alto", "atlas": "atlas",
	"neck_forward": "cuello adelante",
	"foot_length": "largo",
}
const GROUPS := ["Piernas", "Torso", "Brazos", "Cuello y cabeza", "Pies"]


## LO GUARDADO DE ANTES que ya no existe se acepta y se ignora (el ancho y el fondo de la cabeza de caja).
func _set(property: StringName, _value: Variant) -> bool:
	return property in [&"head_width", &"head_depth"]


func copy() -> BlockShape:
	return duplicate() as BlockShape


## CÓMO SE SIENTA (ver SeatInteractable, CÓMO SE SIENTA): x, cuánto arriba del asiento va la pelvis —un radio de pierna:
## el fondo de la caja de la cadera apoya—; y, cuánto adelante del respaldo —media caja de torso, la más honda: la espalda
## apoya—. En metros sin lupa.
func seat_fit() -> Vector2:
	return Vector2(leg_width * 0.5, maxf(lower_depth, maxf(middle_depth, chest_depth)) * 0.5)


## ── EL HOMBRO METIDO EN EL TORSO (04/11/2026, el usuario: «los brazos dejaron de posicionarse pensando en que su
## domo estuviera mitad metido en el torso, así cuando se dobla no se nota la costura… haría que eso sea un toggle en el
## F1») ─────────────────────────────────────────────────────────────────────────────────────────────────────────────
## Prendido, como antes del 03/11: el hombro en el costado del pecho —la mitad del domo del brazo adentro del torso— y
## `arm_open` desde la vertical. Apagado, el brazo rozando (ver `arm_open`). Para todos; cambiarlo rearma a los
## personajes (ver LocomotionCommonKnobs, «todos» en el F3). Es de todos: LocomotionCommon.shoulder_inside.

## EL ÁNGULO DEL BRAZO ROZANDO EL TORSO (ver `arm_open`): colgando derecho, el brazo toca el costado del pecho (el
## hombro va un radio afuera). Lo que hay que abrir para que tampoco entre en la panza —que empieza a un tercio de la
## columna— ni en la cadera —a dos tercios—, si son más anchas que el pecho; el mayor. Medido de frente: la profundidad
## y la postura no cuentan.
func _touch_angle(chain: float, u: float) -> float:
	var third := maxf(chain / 3.0, 0.01)
	var out := 0.0
	for part: Vector2 in [Vector2(middle_width, third), Vector2(lower_width, 2.0 * third)]:
		var inside := (part.x - chest_width) * 0.5 * u
		if inside > 0.0:
			out = maxf(out, asin(clampf(inside / part.y, 0.0, 1.0)))
	return out


## ── LAS DE FÁBRICA: PROPORCIONES REALISTAS (01/11/2026) ────────────────────────────────────────────────────────────
## El arranque de cada arquetipo sin nada guardado. Lo pidió el usuario: «las proporciones en general de todos los
## personajes están muy cartoony… unas proporciones un poco más realistas»; y «en todos los arquetipos haría la misma
## profundidad en todas las cajas del torso» (por eso `depth` es uno solo). La joroba no es de acá: es postura del
## arquetipo y queda como estaba.
## Medidas en metros. Alto total = piernas + torso + cuello + cabeza (el tobillo y el fondo del torso se compensan).
## De referencia, un adulto de 1,80: cabeza 1/7,5 del alto, la cadera a la mitad, la punta de los dedos a medio muslo,
## el codo a la cintura.
const FACTORY := {
	# 1,80: el adulto de referencia.
	"generic": {"legs": 0.88, "knee": 0.5, "leg_w": 0.14, "torso": 0.625, "lower": 0.34, "middle": 0.30, "chest": 0.34,
		"depth": 0.21, "arm": 0.60, "elbow": 0.56, "arm_w": 0.115, "open": 6, "neck": 0.06, "neck_w": 0.12,
		"head_h": 0.235, "atlas": 0.3, "foot": 0.26},
	# 1,97: largo de piernas y de brazos, angosto y chato.
	"lanky": {"legs": 1.0, "knee": 0.5, "leg_w": 0.115, "torso": 0.66, "lower": 0.31, "middle": 0.28, "chest": 0.35,
		"depth": 0.18, "arm": 0.68, "elbow": 0.56, "arm_w": 0.1, "open": 4, "neck": 0.075, "neck_w": 0.13,
		"head_h": 0.28, "atlas": 0.3, "foot": 0.28},
	# 1,87: pecho ancho, cintura que baja, brazos y cuello gruesos.
	"buff": {"legs": 0.9, "knee": 0.5, "leg_w": 0.17, "torso": 0.68, "lower": 0.35, "middle": 0.34, "chest": 0.44,
		"depth": 0.26, "arm": 0.62, "elbow": 0.56, "arm_w": 0.16, "open": 12, "neck": 0.05, "neck_w": 0.19,
		"head_h": 0.265, "atlas": 0.3, "foot": 0.28},
	# 1,75: la panza tan ancha como el pecho (más ancha, los brazos le quedan en A), piernas cortas y gruesas, casi sin
	# cuello.
	"fat_man": {"legs": 0.8, "knee": 0.5, "leg_w": 0.19, "torso": 0.665, "lower": 0.44, "middle": 0.47, "chest": 0.47,
		"depth": 0.34, "arm": 0.58, "elbow": 0.56, "arm_w": 0.15, "open": 16, "neck": 0.04, "neck_w": 0.18,
		"head_h": 0.27, "atlas": 0.3, "foot": 0.27},
	# 1,85: el gordo atlético: pesado pero de hombros, el pecho manda.
	"fat_athletic": {"legs": 0.86, "knee": 0.5, "leg_w": 0.19, "torso": 0.7, "lower": 0.42, "middle": 0.44,
		"chest": 0.46, "depth": 0.32, "arm": 0.62, "elbow": 0.56, "arm_w": 0.17, "open": 14, "neck": 0.04,
		"neck_w": 0.2, "head_h": 0.275, "atlas": 0.3, "foot": 0.29},
	# 1,70: los hombros caídos y angostos, la cintura que se ensancha, flaco de miembros.
	"old": {"legs": 0.8, "knee": 0.5, "leg_w": 0.12, "torso": 0.62, "lower": 0.33, "middle": 0.32, "chest": 0.33,
		"depth": 0.22, "arm": 0.58, "elbow": 0.56, "arm_w": 0.1, "open": 7, "neck": 0.05, "neck_w": 0.14,
		"head_h": 0.28, "atlas": 0.3, "foot": 0.26, "neck_fwd": true},
	# 1,55: un chico de doce años, más grande que uno real para que no contraste tanto con los adultos (02/11/2026, el
	# usuario: «hay demasiado contraste de tamaño»): la cabeza grande, el torso corto, finito.
	"kid": {"legs": 0.74, "knee": 0.5, "leg_w": 0.11, "torso": 0.53, "lower": 0.30, "middle": 0.28, "chest": 0.31,
		"depth": 0.18, "arm": 0.52, "elbow": 0.55, "arm_w": 0.095, "open": 6, "neck": 0.045, "neck_w": 0.12,
		"head_h": 0.28, "atlas": 0.3, "foot": 0.23},
}


## La de fábrica de `archetype` (ver FACTORY), o null si no tiene.
static func factory(archetype: int) -> BlockShape:
	if archetype < 0 or archetype >= EntityArchetype.Archetype.size():
		return null
	var row: Dictionary = FACTORY.get(EntityArchetype.Archetype.keys()[archetype], {})
	if row.is_empty():
		return null
	var out := BlockShape.new()
	out.leg_length = row.legs
	out.knee_at = row.knee
	out.leg_width = row.leg_w
	out.torso_height = row.torso
	out.lower_width = row.lower
	out.middle_width = row.middle
	out.chest_width = row.chest
	out.lower_depth = row.depth
	out.middle_depth = row.depth
	out.chest_depth = row.depth
	out.arm_length = row.arm
	out.elbow_at = row.elbow
	out.arm_width = row.arm_w
	out.arm_open = row.open
	out.neck_length = row.neck
	out.neck_width = row.neck_w
	out.head_height = row.head_h
	out.atlas = row.atlas
	out.foot_length = row.foot
	out.neck_forward = bool(row.get("neck_fwd", false))
	return out
