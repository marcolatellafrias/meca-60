class_name PoseShape
extends Resource

## LA POSTURA Y EL ANDAR DE UN ARQUETIPO — las perillas que deciden cómo se para y cómo camina, sacadas
## del código a un dato que el panel del sandbox edita y guarda (ver PoseShapes, TorsoTuner).
##
## ── POR QUÉ SON LAS MISMAS PERILLAS Y NO UNAS NUEVAS ────────────────────────────────────────────
## Nada de esto se inventa acá: son los knobs que `EntityArchetype` ya tenía escritos a mano en
## `archetypes.gd`, con los mismos nombres y los mismos rangos. Esto es una CAPA DE OVERRIDE encima —el
## código sigue teniendo el defecto de cada arquetipo— y por eso se aplica donde el arquetipo nace (ver
## `apply_to`): de ahí para abajo todo funciona igual, incluidos los multiplicadores de especie, la mezcla
## de dos arquetipos y la variación por individuo.
##
## Afinar una postura o un andar es exactamente el caso del panel: hay que mover un número, mirar, volver.
## Con los números en el código cada prueba es editar, guardar, recompilar y volver a caminar hasta la
## parcela.
##
## ── DOS GRUPOS, QUE SON DOS PESTAÑAS ────────────────────────────────────────────────────────────
## `Pose` es lo que se ve PARADO y quieto; `Caminata` es lo que se ve al CAMINAR. La división no es
## cosmética: el panel filtra por grupo (ver PropertyTuner `include`), así que una perilla nueva aparece en
## su pestaña por el solo hecho de estar declarada en su grupo.

@export_group("Pose")

## ENCORVADO, 0..1, y es SOLO EL CUELLO: lo inclina hacia adelante (ver
## SkeletonSizesUtil.slouchiness_neck). Con el cuello naciendo metido en el torso, eso solo ya lee como
## hombros encogidos y cabeza adelantada.
@export_range(0.0, 1.0, 0.05) var slouch := 0.0

## CURVA DE LA ESPALDA, 0..1, y es OTRA COSA que el encorvado: el pecho se va adelante y la lumbar atrás de
## contrapeso (ver SkeletonSizesUtil.spine_bend_chest). Va como postura de pose, así que deforma el torso.
@export_range(0.0, 1.0, 0.05) var spine_bend := 0.0

## FLEXIÓN DE RODILLA EN REPOSO, 0..1: 0 son piernas casi rectas (~12°) y 1 bien flexionadas (~52°). No es
## una pose escrita en un hueso — sale de cuánto de su largo usa la pierna parada, o sea de la altura de
## pelvis, y la IK acomoda rodilla y pie sola.
@export_range(0.0, 1.0, 0.05) var leg_bentness := 0.0

## HOMBROS, −1..1 cada uno y el signo importa: `adelante` es +encorvado / −pecho abierto, y `caídos` es
## +vencido / −levantados. Son giros chicos (ver SkeletonSizesUtil.SHOULDER_FORWARD_MAX): pasarse se lee
## como brazos cruzados y no como postura.
@export_range(-1.0, 1.0, 0.05) var shoulders_forward := 0.0
@export_range(-1.0, 1.0, 0.05) var shoulders_drop := 0.0

## FLEXIÓN DE CODO EN REPOSO, 0..1. Es el equivalente de `leg_bentness` para el brazo.
@export_range(0.0, 1.0, 0.05) var arm_bentness := 0.3

## SEPARACIÓN DE LOS PIES, en múltiplos del ancho de cadera: 1 es un pie bajo cada cadera.
@export_range(0.0, 2.0, 0.05) var stance_width := 1.0

## QUIETO: RESPIRA Y TIEMBLA (07/11/2026, el dios del juego: «los permanentes quisiera poder elegirlos del panel… dejarlos
## con un valor bien alto… y cambio el slider, que es qué factor de esa constante usa ese arquetipo»). De 0 a 1, una parte
## del techo de cada uno (ver PassiveState: TREMOR_MAX, BREATH_DEPTH_MAX, BREATH_RATE_MAX).
@export_range(0.0, 1.0, 0.01) var tremor := 0.0
@export_range(0.0, 1.0, 0.01) var breath_depth := 0.0
@export_range(0.0, 1.0, 0.01) var breath_rate := 0.0


@export_group("Caminata")

## ZANCADA: el largo del paso de este personaje caminando, 1 = 0,8 de su pierna (ver SkeletonSizesUtil, LA ZANCADA
## MANDA). De acá salen los pasos por segundo —velocidad / paso, sin techo— y la altura de pelvis que hace falta para
## que el pie llegue. Llega a 3: un paso exagerado es una decisión de personaje; la IK lo sigue resolviendo y lo que se
## ve decide.
@export_range(0.0, 1.0, 0.01) var stride_reach := 0.5

## ALTURA DEL ARCO DEL PASO, en fracción del largo de pierna.
@export_range(0.0, 1.0, 0.05) var step_height := 0.5

## CUÁNTO SE HUNDE LA PELVIS AL PISAR, 1 la de referencia (ver BoneInstantiator, LA HUNDIDA AL PISAR). *Hasta el
## 07/11/2026 exageraba la bajada que pide la pierna, y cada arquetipo tenía la suya (0,5 a 0,8); al cambiar de sentido
## todos arrancaron en 1, para que se vieran como cuando se eligió.*
@export_range(0.0, 2.0, 0.05) var root_bounciness := 1.0

## LOS BALANCEOS DE LOS HOMBROS Y DEL BRAZO, donde **1 es el andar de referencia y no el máximo**: el hombro sólo los
## hombros, y el braceo, el brazo entero (ver animations.gd). *Hasta el 07/11/2026 había un `hip_swing` que movía la
## cadera y también cuánto giraba la columna, y el hombro sumaba braceo; ver EntityArchetype, UNA PERILLA, UN MOVIMIENTO.* *El cuarto, `side_swing` («balanceo lateral»), no lo leía ninguna animación: se borró el
## 07/11/2026.*
@export_range(0.0, 2.0, 0.05) var shoulder_swing := 1.0
@export_range(0.0, 2.0, 0.05) var arm_swing := 0.5
## LO QUE ERA DE TODOS, DE CADA UNO (ver EntityArchetype, EL ANDAR QUE ERA DE TODOS; WalkStyle.ARCHETYPE_KNOBS).
@export_range(0.0, 3.0, 0.05) var walk_twist := 1.0
@export_range(0.0, 3.0, 0.05) var walk_spine_bow := 1.0
@export_range(0.0, 3.0, 0.05) var walk_spine_roll := 1.0
@export_range(-0.3, 0.3, 0.01) var walk_lean := 0.03
@export_range(-0.5, 0.5, 0.01) var walk_posture_lean := 0.0
@export_range(0.0, 3.0, 0.05) var walk_hip_sway := 1.0
@export_range(0.0, 0.08, 0.005) var walk_bounce_up := 0.0
@export_range(0.0, 3.0, 0.05) var walk_arm_open := 1.0
@export_range(0.0, 0.6, 0.01) var walk_run_elbow := 0.3
@export_range(0.0, 1.0, 0.05) var walk_stride_growth := 0.5
@export_range(0.15, 0.6, 0.01) var walk_swing_share := 0.38
@export_range(0.0, 0.6, 0.01) var walk_lead := 0.25

## ── EL CUERPO: MOVIMIENTO, EQUILIBRIO Y SALTO (03/11/2026, el panel de locomoción, ver LocomotionTuner) ────────────
## Los mismos números que `EntityArchetype` ya tenía, con los mismos nombres: la capa los pisa donde el arquetipo nace.
@export_group("Movimiento")
## LA VELOCIDAD DE CAMINAR (× la escala del juego), y cuánto de ella yendo para atrás y de costado.
@export_range(0.05, 1.0, 0.01) var speed := 0.3
@export_range(0.2, 1.5, 0.05) var back_speed_factor := 1.0
@export_range(0.2, 1.5, 0.05) var lateral_speed_factor := 1.0
## CUÁNTAS VECES LA DE CAMINAR LLEGA CORRIENDO.
@export_range(1.0, 4.0, 0.05) var sprint_multiplier := 2.2
## LA ACELERACIÓN (× su peso × la escala del juego).
@export_range(0.1, 8.0, 0.05) var acceleration := 0.6
## LA FUERZA: contra el peso de lo que lleva, cuánto lo frena (ver GrabbableInteractable.load_of); de a varios, se suma.
@export_range(0.1, 2.5, 0.05) var strength := 1.0
## LA FUERZA DE BRAZOS, aparte de la de llevar (04/11/2026, el dios del juego: «quiero tener un independiente»; «un valor
## normalizado que afecte a las dos»): 1 lo normal. El tiro y el empujón (R) son esto por sus perillas de todos (ver
## InteractionController, EL TIRO Y EL EMPUJÓN).
@export_range(0.1, 2.5, 0.05) var throw_strength := 1.0

@export_group("Equilibrio")
## EL PESO (kg): cuánto cuesta moverlo; en un choque, el liviano se lleva el cambio de velocidad.
@export_range(20.0, 200.0, 1.0) var weight := 80.0
## LA ESTABILIDAD adelante, atrás y de costado: con el peso, la firmeza que divide los golpes y la inercia.
@export_range(0.1, 3.0, 0.05) var forward_stability := 1.0
@export_range(0.1, 3.0, 0.05) var backwards_stability := 1.0
@export_range(0.1, 3.0, 0.05) var sideways_stability := 1.0
## QUÉ TAN DURO SE ENDEREZA y cuánto frena el rebote (más, rebota menos).
@export_range(0.1, 3.0, 0.05) var stability_spring := 1.0
@export_range(0.1, 3.0, 0.05) var stability_damp := 1.0
## EL GOLPE VERTICAL QUE LO TUMBA AL ATERRIZAR (m/s; 9 es caer de unos 4 m).
@export_range(3.0, 25.0, 0.5) var landing_tolerance := 9.0
## CUÁNTO TARDA EN LEVANTARSE (s).
@export_range(0.5, 8.0, 0.1) var time_to_standup := 1.5

## (El cuerpo en el aire, el despegue y el aterrizaje son de todos desde el 04 y el 05/11/2026: LocomotionCommon, en la F1 de
## los experimentos. Hasta entonces había un grupo «Aire» por arquetipo.)

@export_group("Salto")
## LA ALTURA DEL SALTO CARGADO ENTERO (m) y cuánto tarda en cargarse (s).
@export_range(0.1, 3.0, 0.02) var jump_height := 1.12
@export_range(0.1, 3.0, 0.05) var time_to_max_jump := 1.0


## Los nombres de las perillas, uno por grupo. Es lo que hace que agregar una perilla sea declararla y
## nada más: el que la aplica y el que la copia la leen de acá.
const POSE_KNOBS: Array[String] = ["slouch", "spine_bend", "leg_bentness",
	"shoulders_forward", "shoulders_drop", "arm_bentness", "stance_width", "tremor", "breath_depth", "breath_rate"]
const WALK_KNOBS: Array[String] = ["stride_reach", "step_height", "root_bounciness", "shoulder_swing",
	"arm_swing", "walk_twist", "walk_spine_bow", "walk_spine_roll", "walk_lean",
	"walk_posture_lean", "walk_hip_sway", "walk_bounce_up", "walk_arm_open", "walk_run_elbow", "walk_stride_growth",
	"walk_swing_share", "walk_lead"]
const MOVE_KNOBS: Array[String] = ["speed", "back_speed_factor", "lateral_speed_factor", "sprint_multiplier",
	"acceleration", "strength", "throw_strength"]
const BALANCE_KNOBS: Array[String] = ["weight", "forward_stability", "backwards_stability", "sideways_stability",
	"stability_spring", "stability_damp", "landing_tolerance", "time_to_standup"]
## (La carga del salto es la misma para todos desde el 04/11/2026: EntityArchetype.JUMP_WINDUP_S.)
const JUMP_KNOBS: Array[String] = ["jump_height"]



## Todas, en orden.
static func knobs() -> Array[String]:
	return POSE_KNOBS + WALK_KNOBS + MOVE_KNOBS + BALANCE_KNOBS + JUMP_KNOBS

## Cómo se llama cada grupo. El panel filtra por esto (ver PropertyTuner `include`).
const POSE_GROUP := "Pose"
const WALK_GROUP := "Caminata"
const MOVE_GROUP := "Movimiento"
const BALANCE_GROUP := "Equilibrio"
const JUMP_GROUP := "Salto"


## LA POSTURA QUE EL CÓDIGO DESCRIBE para un arquetipo: se le leen las perillas tal como están escritas en
## `archetypes.gd`. Es el defecto del que parte el panel, y es a lo que vuelve Olvidar.
static func from_archetype(arch: EntityArchetype) -> PoseShape:
	var out := PoseShape.new()
	if arch == null:
		return out
	for knob in knobs():
		out.set(knob, arch.get(knob))
	return out


## ESCRIBE ESTAS PERILLAS EN UN ARQUETIPO. Se llama donde el arquetipo NACE, así que todo lo que pasa
## después —la mezcla con un segundo arquetipo, los multiplicadores de especie, la variación del
## individuo— se calcula sobre estos números igual que se calculaba sobre los del código.
func apply_to(arch: EntityArchetype) -> void:
	if arch == null:
		return
	for knob in knobs():
		arch.set(knob, get(knob))


func copy() -> PoseShape:
	var out := PoseShape.new()
	for knob in knobs():
		out.set(knob, get(knob))
	return out


## Si las dos dicen lo mismo. Lo usa el panel para no escribirle al repo una postura que nadie tocó:
## guardarla congelaría los defectos del código de ese arquetipo sin que nadie lo haya pedido.
func equals(other: PoseShape) -> bool:
	if other == null:
		return false
	for knob in knobs():
		if not is_equal_approx(float(get(knob)), float(other.get(knob))):
			return false
	return true


## Para el cartel del panel y para el portapapeles.
func describe() -> String:
	return "encorvado %.2f · rodilla %.2f · zancada %.2f · paso %.2f" \
		% [slouch, leg_bentness, stride_reach, step_height]
