class_name WalkStyle
extends Resource

## ── LA CAMINATA, EN POCOS NÚMEROS ────────────────────────────────────────────────────────────────
## Lo pidió el dios del juego (12/10/2026): «una mejor caminata base, que pueda tweakear con pocos parámetros», con
## modificadores que se le suman a cada personaje (ver el plan de la caminata, en el estado de la locomoción). Esto es la
## BASE: las piernas (la marcha de fase, ver SkeletonSizesUtil._update_gait, que lee estos números) y el tren superior (ver BoneAnimations
## y BoneInstantiator._update_pelvis_drop), separados para probar combinaciones de los dos. Lo de cada arquetipo —su
## `arm_swing`, su `root_bounciness`…— sigue siendo su personalidad, y esto la escala.
##
## Se lee en cada cuadro: el panel (la pestaña Caminata del panel de locomoción, ver LocomotionTuner) y los modificadores lo cambian en vivo.
## Sin guardar, los números de siempre, que son los de antes de que existiera.

@export_group("Piernas")
## LA ZANCADA DE TODOS, × la de cada arquetipo (ver SkeletonSizesUtil, LA ZANCADA MANDA): los pasos por segundo son
## la consecuencia. Y cuánto se alarga con la velocidad: el paso va por `(v / caminar) ^ esto` —0 siempre el mismo
## paso, 1 siempre los mismos pasos por segundo—. *Antes, cadencias y un techo de cadencia, que la zancada no movía.*
@export_range(0.2, 3.0, 0.05) var stride_scale := 1.0
@export_range(0.0, 1.0, 0.05) var stride_growth := 0.5
## Qué parte del ciclo de su pie vuela cada pie.
@export_range(0.15, 0.6, 0.01) var swing_share := 0.38
## Cuánto adelante de la cadera aterriza el pie, en zancadas.
@export_range(0.0, 0.6, 0.01) var lead := 0.25
## (Cuánto sube el pie no está acá: es `step_height` del arquetipo, y los modificadores lo cambian ahí. Ver
## UN NOMBRE, UN LUGAR.)

@export_group("Tren superior")
## Cuánto se hunde la pelvis al pisar (× el `root_bounciness` del arquetipo, ver BoneInstantiator, LA HUNDIDA AL PISAR)
## y cuánto SUBE al despegar el pie, en fracción del largo de la pierna.
@export_range(0.0, 3.0, 0.05) var bounce_down := 1.0
@export_range(0.0, 0.08, 0.005) var bounce_up := 0.0
## La cadera que se mece (sólo left_hip y right_hip), la columna que gira contra las piernas y los hombros, cada uno lo
## suyo (ver EntityArchetype, UNA PERILLA, UN MOVIMIENTO). El braceo es `arm_swing` del arquetipo (ver UN NOMBRE, UN
## LUGAR).
@export_range(0.0, 3.0, 0.05) var hip_sway := 1.0
## LA COLUMNA DE COSTADO, CON PERILLA PROPIA (07/11/2026, el dios del juego: «el lower spine que se swinguea
## lateralmente con los pasos… lo quiero cambiar y no puedo»): el ARCO —lower_spine para un lado, higher_spine y chest
## para el otro—, sólo con su perilla desde el 07/11/2026 (antes lo escalaba también `hip_sway`), y la INCLINACIÓN de
## lower_spine según cuánto se abren los pies a lo ancho.
@export_range(0.0, 3.0, 0.05) var spine_bow := 1.0
@export_range(0.0, 3.0, 0.05) var spine_roll := 1.0
@export_range(0.0, 3.0, 0.05) var twist := 1.0
@export_range(0.0, 3.0, 0.05) var shoulders := 1.0
## EL BRAZO QUE SE ABRE DEL CUERPO en los extremos del paso, aparte del braceo (ver BoneAnimations.ARM_OPEN): 0 nada,
## 1 lo de siempre.
@export_range(0.0, 3.0, 0.05) var arm_open := 1.0
## EL CODO AL CORRER (07/11/2026, el dios del juego: «mientras más rápido vayan… se cambie el ángulo del brazo»; «que sea
## relativo a la velocidad máxima del personaje»): cuánto se acerca la mano al hombro a toda velocidad —o sea, cuánto
## más se dobla el codo—, en fracción de su distancia de reposo. Empieza recién por encima de su caminar y llega entero
## a su sprint (ver BoneAnimations, EL BRACEO GIRA EN EL HOMBRO).
@export_range(0.0, 0.6, 0.01) var run_elbow := 0.3
## Cuánto se inclina el torso con la velocidad (− hacia atrás).
@export_range(-0.3, 0.3, 0.01) var lean := 0.05

@export_group("Pose")
## El cuerpo entero tirado adelante (+) o atrás (−), quieto o caminando, en radianes: lo usan los modificadores de pose
## (ver WalkModifier). Las piernas siguen plantadas.
@export_range(-0.5, 0.5, 0.01) var posture_lean := 0.0


## ── EL DE CADA PERSONAJE (07/11/2026, ver EntityArchetype, EL ANDAR QUE ERA DE TODOS) ──────────────────────────────
## Estas perillas son de cada arquetipo (`walk_` + el nombre): cada personaje arma su estilo con las de su arquetipo y
## encima sus modificadores. Las demás —el largo del paso, la hundida y los hombros— quedan en 1 y sólo las mueven los
## modificadores, como multiplicadores de lo del arquetipo. *Hasta entonces todos leían una
## sola base (la de abajo, `walk_style.tres`), y el panel de locomoción la mostraba bajo el nombre de un arquetipo.*
const ARCHETYPE_KNOBS: Array[String] = ["twist", "spine_bow", "spine_roll", "lean", "posture_lean", "hip_sway",
	"bounce_up", "arm_open", "run_elbow", "stride_growth", "swing_share", "lead"]


## ── UN NOMBRE, UN LUGAR (07/11/2026, el dios del juego eligió arreglarlo) ─────────────────────────────────────────────
## Un modificador cambia cada número que se llame como él donde esté: en el arquetipo, en el individuo y en este estilo.
## `step_height` y `arm_swing` estaban en los dos lados, así que se aplicaban dos veces —«Arrastrando los pies», ×0,15
## del pie, lo dejaba en ×0,02—. Se fueron de acá, y esta regla avisa si un número de este estilo vuelve a llamarse
## como uno del arquetipo o del individuo.
static func _check_names(arch: Object) -> void:
	for prop in WalkStyle.new().get_property_list():
		var field := str(prop["name"])
		if int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE and field in arch:
			push_error("[WalkStyle] «%s» también es del arquetipo: un modificador lo aplicaría dos veces." % field)


static func for_archetype(arch: Object, modifiers: Array[WalkModifier]) -> WalkStyle:
	var out := WalkStyle.new()
	if arch != null:
		if OS.is_debug_build():
			_check_names(arch)
		for knob: String in ARCHETYPE_KNOBS:
			out.set(knob, float(arch.get("walk_" + knob)))
	for modifier in modifiers:
		modifier.apply(out)
	return out


## LA DE SIEMPRE, para quien todavía no tiene la suya (el primer paso, antes de armar el personaje). *Hasta el 07/11/2026
## era una base de todos guardada (`walk_style.tres`), que el panel editaba; desde que las perillas son de cada
## arquetipo nadie la editaba.*
static var _plain: WalkStyle = null


static func plain() -> WalkStyle:
	if _plain == null:
		_plain = WalkStyle.new()
	return _plain
