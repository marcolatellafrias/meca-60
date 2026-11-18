class_name LocomotionCommon
extends Resource

## ── LO DE TODOS LOS ARQUETIPOS, POR LAS PESTAÑAS DEL F3 (07/11/2026, el usuario: «que el código refleje un poco más
## esta estructura… caminata, pose, movimiento, equilibrio, salto, cuerpo»; eligió dos paneles con las mismas pestañas) ─
## Lo de cada arquetipo está en su arquetipo (ver EntityArchetype, el F3 de Personajes); lo que vale igual para todos está
## acá, con las mismas pestañas, y lo edita el F1 de los Experimentos de locomoción (ver LocomotionPanel), con un solo
## «Guardar». Lo leen el agarre, el cuerpo en el aire, la caída y el cuerpo de bloques, en vivo.
## *Hasta entonces eran tres lugares: CarryTuning (llevar, echarse atrás y tirar), AirTuning (el cuerpo en el aire) y
## BodyDefaults (interruptores sueltos en RagdollUtil, CharacterRigidBody3D, BlockShape, SkeletonSizesUtil y AirStyle). Lo
## guardado se pasó acá tal cual.*

@export_group("Pose")
## ── EL CUERPO SE ECHA ATRÁS CON LO QUE LLEVA (04/11/2026, el usuario: «cuando agarran un paquete se deberían
## inclinar hacia atrás… tiene que tener un límite… dejá todas las variaciones en F1 así pruebo») ───────────────────
## `carry_lean_mode`: 0 nada; 1 FIJA mientras lo lleva —quieto se echa atrás todo, y la de correr la compensa—; 2 CON LA
## VELOCIDAD, la de correr dada vuelta: más rápido, más atrás, y quieto derecho. `carry_lean_by_weight`: por la carga que
## es para quienes lo llevan (de 0 a 1, ver GrabbableInteractable.load_of), o siempre el ángulo entero. `carry_lean_away`:
## alejándose del paquete (de a dos de costado, hacia el otro lado) o hacia atrás del cuerpo. Nunca más que
## `carry_lean_deg`; va y viene en `carry_lean_s` (ver BoneInstantiator.carry_lean).
@export_enum("nada", "fija", "con la velocidad") var carry_lean_mode := 1
@export var carry_lean_by_weight := true
@export var carry_lean_away := true
@export_range(0.0, 45.0, 0.5) var carry_lean_deg := 22.0
@export_range(0.05, 1.5, 0.05) var carry_lean_s := 0.3
## (04/11/2026, el usuario: «se tiran para atrás muy poquito… es como si no tuviera peso»; tope de 12° a 22°.)
## DÓNDE SE DOBLA: 0, todo en la base de la columna (el torso entero, recto, se va para atrás); 1, repartido en las tres
## vértebras (la espalda se curva, como quien carga). Y LA CADERA ADELANTE (m): la pelvis se va hacia el paquete, lo
## que hace el cuerpo de contrapeso; con la espalda atrás se lee el peso.
@export_range(0.0, 1.0, 0.05) var carry_lean_spread := 0.5
@export_range(0.0, 0.25, 0.01) var carry_lean_hips := 0.08

@export_group("Movimiento")
## ── LLEVAR ALGO (04/11/2026, lo pidió el usuario: «algo global de todos los personajes») ───────────────────
## Los números del agarre que valen igual para todos los arquetipos —el cono no se lee a la vista, así que distinto por
## arquetipo se sentiría injusto—. Los lee GrabbableInteractable en cada cuadro.
## CUÁNTO ABAJO DE LA MIRADA va lo que se lleva (°), y a cuántos grados mirando abajo esa diferencia ya se desvaneció
## (ver GrabbableInteractable.held_aim).
@export_range(0.0, 45.0, 1.0) var hold_drop_deg := 18.0
@export_range(10.0, 90.0, 1.0) var hold_drop_fade_deg := 50.0
## A QUÉ DISTANCIA DEL PECHO va el punto por donde se lleva (m), en la dirección de la mirada: la misma para todos; los
## brazos largos y los cortos la alcanzan doblando más o menos los codos.
@export_range(0.15, 0.9, 0.01) var hold_reach := 0.4
## EL TOPE DEL PECHO (m): lo que se lleva nunca queda más cerca que esto de la pared invisible que tiene adelante quien
## lo lleva (ver GrabbableInteractable, EL TOPE DEL PECHO).
@export_range(0.0, 0.5, 0.01) var chest_clear := 0.18
## EL CONO DE LO QUE SE LLEVA (°) y cuánto queda de él justo antes de caerse por un golpe (ver
## GrabbableInteractable.carry_cone_deg).
@export_range(10.0, 120.0, 1.0) var carry_cone_deg := 60.0
@export_range(0.1, 1.0, 0.05) var carry_cone_at_fall := 0.35
## LO PESADO SE LLEVA MÁS BLANDO: cuántas veces más tarda el agarre en llegar con una carga de 1 (ver
## GrabbableInteractable._softness).
@export_range(1.0, 6.0, 0.1) var heavy_softness := 3.0
## QUÉ TAN RÁPIDO SE MUDA EL PUNTO de cada uno cuando se suma o se va otro (m/s; ver GrabbableInteractable, CADA UNO
## LLEVA EL CENTRO DE SU PARTE).
@export_range(0.2, 5.0, 0.1) var share_shift_speed := 1.2
## ── TIRAR LO QUE SE LLEVA: EL PASE DE PECHO (04/11/2026, el usuario: «agarra el paquete, lo carga hacia atrás,
## como un resorte, y después lo suelta de golpe… que el pecho se vaya para atrás y eso le dé lugar a que los brazos se
## compriman»; eligió el pase de pecho y el empujón físico) ─────────────────────────────────────────────────────────
## AL CARGAR (`throw_charge_s` hasta lo máximo), el pecho se echa atrás hasta `throw_lean_deg` —el mismo echarse atrás de
## llevar algo, así el tope del pecho y adonde va la caja lo siguen (ver BoneInstantiator.get_interaction_origin)— y la
## caja viene hacia el pecho, a `throw_draw` de la distancia de llevar: los brazos se comprimen. AL SOLTAR, en
## `throw_push_s` las manos la empujan hasta `throw_extend` m más allá de la distancia de llevar —la mano la arrastra, con
## su fuerza: lo pesado acompaña menos— y el pecho se va adelante hasta `throw_follow_deg`; recién ahí la suelta, con el
## impulso del tiro (su fuerza de brazos × `throw_per_arm`, ver InteractionController, EL TIRO Y EL EMPUJÓN: lo liviano
## vuela lejos, lo pesado cae cerca).
@export_range(0.1, 2.0, 0.05) var throw_charge_s := 0.5
@export_range(0.0, 45.0, 0.5) var throw_lean_deg := 18.0
@export_range(0.0, 1.0, 0.05) var throw_draw := 0.35
@export_range(0.05, 0.6, 0.01) var throw_push_s := 0.16
@export_range(0.0, 0.8, 0.01) var throw_extend := 0.45
@export_range(0.0, 30.0, 0.5) var throw_follow_deg := 12.0
## EL TIRO Y EL EMPUJÓN, DOS PERILLAS DE TODOS sobre la fuerza de brazos de cada uno (`throw_strength`, 1 lo normal; ver
## InteractionController, EL TIRO Y EL EMPUJÓN): el impulso del tiro a carga entera (N·s) y el cambio de velocidad que le
## da el empujón a quien lo recibe (m/s). Una no mueve a la otra (el usuario: «un valor normalizado que afecte a
## las dos en vez de que una afecte a la otra»).
@export_range(10.0, 200.0, 1.0) var throw_per_arm := 70.0
## EL EMPUJÓN (N·s a carga entera por cada 1 de fuerza de brazos). 210 es lo de antes para uno de 60 kg (3,5 m/s).
@export_range(20.0, 600.0, 5.0) var push_per_arm := 210.0
## EL RESORTE DE LOS GOLPES DE COSTADO, de todos (18/11/2026; antes de cada arquetipo): qué tan duro se endereza y cuánto
## frena el rebote (ver HitSpring).
@export_range(5.0, 80.0, 1.0) var impact_spring := 25.0
@export_range(1.0, 20.0, 0.5) var impact_damp := 6.0
## EL ALCANCE PARA INTERACTUAR (m, desde la punta del pecho; × la escala del cuerpo, ver BlockShape.apply_to). Con 1,00:
## el botón más bajo del alcance (a 0,2 m) pide agacharse a los seis; agachado lo alcanzan todos menos el flaco alto (le
## hacen falta 1,06). Un solo número en metros no logra las dos cosas para los seis: el kid parado llega a 1,02.
@export_range(0.8, 1.3, 0.01) var interaction_reach := 1.0

@export_group("Equilibrio")
## LA EXAGERACIÓN DE LA CAÍDA (ver RagdollUtil.activate_with_impact): cuántas veces el empujón que recibió. 1 es la física
## tal cual (03/11/2026: «que la base esté limpia; después, si hace falta, le metemos algo encima»).
@export_range(0.5, 3.0, 0.1) var impact_fall_linear := 1.0
## AL ATERRIZAR, FRENA EL CUERPO (ver CharacterRigidBody3D, AL ATERRIZAR, FRENA EL CUERPO): el golpe de aterrizar le saca
## velocidad horizontal según qué tan fuerte cayó.
@export var landing_brake := false
## EL RAGDOLL EN EL AIRE (04/11/2026, el usuario: «si tu personaje está cayendo desde hace cierto tiempo, ragdolea
## en el aire directamente»): cayendo más rápido que `ragdoll_speed` m/s, se tira en el aire —por la velocidad de caída y
## no por el tiempo, así un salto muy alto hacia arriba no lo dispara— (ver AirStyle).
@export var ragdoll_in_air := false
@export_range(4.0, 20.0, 0.5) var ragdoll_speed := 10.0

@export_group("Salto")
## ── EL CUERPO EN EL AIRE, UNA REGLA POR PARTE (04/11/2026, el usuario: «va más con sliders»; «por ahora algo
## universal, que no quiero que varíe por arquetipo»; «un toggle por sistema») ─────────────────────────────────────────
## Cada parte tiene UNA regla con su interruptor, en DOS PUNTOS: lo de EN EL AIRE —desde que despega hasta la cima, y
## también al salir de un borde— y lo de CAYENDO, al que llega `…_fall_s` segundos después de la cima (`t × g` de la
## velocidad vertical de la cápsula, `BoneInstantiator.air_vy`). Todo pesa con `air_t` (de 0, en el piso, a 1, en el
## aire, en `blend_s`): nada salta; lo que cambia crece desde cero.
## Lo que tarda el cuerpo en pasar de la pose del piso a la del aire al despegar, y de vuelta al aterrizar (s).
@export_range(0.02, 1.0, 0.01) var blend_s := 0.17
## EL TORSO: cuánto se inclina en el aire y cayendo (°; adelante +, atrás −), y un suavizado (s).
@export var torso_on := true
@export_range(-40.0, 40.0, 0.5) var torso_apex_deg := 0.0
@export_range(0.05, 3.0, 0.01) var torso_fall_s := 0.6
@export_range(-40.0, 40.0, 0.5) var torso_fall_deg := -10.0
@export_range(0.01, 1.0, 0.01) var torso_follow_s := 0.15
## LAS PIERNAS, UNA SOLA REGLA POR LA VELOCIDAD VERTICAL (05/11/2026, el usuario: «extender piernas cuando se
## despega, flexionarlas un poco mid-air y cuando se está cayendo que las estire de vuelta»): rápido —al despegar, y
## cayendo— la flexión de `legs_fast_bend`, quieto en el aire la de `legs_still_bend`. Subiendo va de una a otra a lo largo
## de toda la subida (la velocidad de ahora sobre la del despegue, `BoneInstantiator.takeoff_vy`); cayendo, vuelve a la de
## rápido en `legs_fall_s`. Sin despegue —cayendo de un borde— arranca en la de quieto. Apagadas, rectas.
@export var legs_on := true
@export_range(0.0, 1.0, 0.05) var legs_still_bend := 0.25
@export_range(0.0, 1.0, 0.05) var legs_fast_bend := 0.0
@export_range(0.05, 2.0, 0.01) var legs_fall_s := 0.2
## LOS BRAZOS EN EL AIRE (04 y 05/11/2026, el usuario: «cuando van cayendo se van abriendo»; «controlar hacia dónde
## apuntan… qué tanto se quiebran»): una pose en el aire y otra cayendo, desde el brazo colgando al lado del torso (los
## dos en 0): ADELANTE (−45° atrás, 90° horizontal, 180° arriba por delante); AFUERA (−20° hacia adentro, 90° horizontal,
## 180° arriba por el costado); y el QUIEBRE (0 recto, 1 bien doblado). Lo que se agarra manda sobre ella (ver
## ArmsController). *Los de adelante se llaman `…_front_deg` y no `…_forward_deg`, que fue otra cosa: con el mismo nombre,
## lo guardado se leía con el significado nuevo.*
@export var arms_on := true
@export_range(-45.0, 180.0, 1.0) var apex_front_deg := 20.0
@export_range(-20.0, 180.0, 1.0) var apex_out_deg := 32.0
@export_range(0.0, 1.0, 0.05) var apex_bend := 0.35
@export_range(0.05, 3.0, 0.01) var arms_fall_s := 0.8
@export_range(-45.0, 180.0, 1.0) var fall_front_deg := 30.0
@export_range(-20.0, 180.0, 1.0) var fall_out_deg := 60.0
@export_range(0.0, 1.0, 0.05) var fall_bend := 0.2
## LA AGACHADA DE LA CARGA (05/11/2026, el usuario: «aumentar el windup del salto, qué tanto se agacha»): × la de
## siempre —lo que baja la pelvis, lo que va adelante y lo que se inclina, juntos—.
@export_range(0.0, 3.0, 0.05) var jump_squat := 1.0
## EL ATERRIZAJE (05/11/2026, el usuario: «no me interesa cambiar la animación, sólo su intensidad»): × lo que se
## hunde; más cuanto más rápido cae, del todo a `LANDING_FULL_SPEED`. Lo que sí es de cada arquetipo es el golpe que lo
## tumba (`landing_tolerance`, en la F3).
@export_range(0.0, 4.0, 0.05) var landing_depth := 2.0
## PASITOS CORTOS AL ATERRIZAR (ver SkeletonSizesUtil, AL ATERRIZAR, LOS PASOS VUELVEN A ARRANCAR): lo que tardan los
## pasos en volver a los de su velocidad desde que toca el piso (s); 0, sin pasitos.
@export_range(0.0, 2.0, 0.05) var landing_steps_s := 0.6

@export_group("Cuerpo")
## EL HOMBRO METIDO EN EL TORSO (04/11/2026, el usuario: «haría que eso sea un toggle en el F1»): prendido, el
## hombro en el costado del pecho —la mitad del domo del brazo adentro del torso— y `arm_open` desde la vertical;
## apagado, el brazo rozando (ver BlockShape.arm_open). Cambiarlo rearma a los personajes.
@export var shoulder_inside := false


const LANDING_FULL_SPEED := 10.0
const LANDING_SPRING := 25.0
const LANDING_DAMP := 6.0
## La gravedad con la que un tiempo desde la cima se vuelve velocidad vertical (m/s²).
const G := 9.8
## Lo estirada que va la pierna «recta» en el aire: apenas menos que el largo entero, así la IK no queda en el límite y la
## rodilla no tiembla.
const LEG_REACH_SHARE := 0.99


## ── GUARDADO ────────────────────────────────────────────────────────────────────────────────────
const PATH := "res://game/character/locomotion_common.tres"
static var _base: LocomotionCommon = null


## Lo de todos, guardado o lo de siempre. Una sola instancia: el panel la edita y el juego la lee en el mismo cuadro.
static func base() -> LocomotionCommon:
	if _base == null:
		if ResourceLoader.exists(PATH):
			_base = ResourceLoader.load(PATH, "LocomotionCommon", ResourceLoader.CACHE_MODE_IGNORE) as LocomotionCommon
		if _base == null:
			_base = LocomotionCommon.new()
	return _base


## VUELVE A LO GUARDADO (o a lo de siempre, si no hay nada guardado), en la misma instancia: el panel la sigue editando.
static func restore() -> void:
	var saved: LocomotionCommon = null
	if ResourceLoader.exists(PATH):
		saved = ResourceLoader.load(PATH, "LocomotionCommon", ResourceLoader.CACHE_MODE_IGNORE) as LocomotionCommon
	if saved == null:
		saved = LocomotionCommon.new()
	var live := base()
	for property in live.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			live.set(property["name"], saved.get(property["name"]))


static func store() -> bool:
	var err := ResourceSaver.save(base(), PATH)
	if err != OK:
		push_warning("[LocomotionCommon] No se pudo guardar %s (%d)" % [PATH, err])
	return err == OK


## ── MOVIMIENTO: LLEVAR Y TIRAR ──────────────────────────────────────────────────────────────────
## A QUÉ DISTANCIA DEL PECHO va lo que se lleva (m), con el tiro de `anim` si es con una caja.
func held_reach(anim: AnimationModifiers) -> float:
	if anim == null or not anim.throw_with_box:
		return hold_reach
	var push := anim.throw_push_progress()
	if push < 0.0:
		return hold_reach * lerpf(1.0, throw_draw, anim.throw_t)
	return lerpf(hold_reach * lerpf(1.0, throw_draw, anim.throw_from), hold_reach + throw_extend,
		smoothstep(0.0, 1.0, push))


## CUÁNTO SE ECHA ATRÁS POR EL TIRO (rad; negativo, adelante), con `anim`.
func throw_lean(anim: AnimationModifiers) -> float:
	if anim == null or not anim.throw_with_box:
		return 0.0
	var push := anim.throw_push_progress()
	if push < 0.0:
		return deg_to_rad(throw_lean_deg) * anim.throw_t
	return lerpf(deg_to_rad(throw_lean_deg) * anim.throw_from, -deg_to_rad(throw_follow_deg), smoothstep(0.0, 1.0, push))


## ── SALTO: EL CUERPO EN EL AIRE ─────────────────────────────────────────────────────────────────
## LO DE DOS PUNTOS: `apex` en el aire hasta la cima, y de ahí a `fall` a `fall_s` segundos o más después.
static func two_points(bi: BoneInstantiator, apex: float, fall: float, fall_s: float) -> float:
	return lerpf(apex, fall, clampf(-bi.air_vy / maxf(fall_s * G, 0.01), 0.0, 1.0))


## EL TORSO: el giro de la base de la columna que se busca ahora (rad; atrás +, ver Animations, ECHARSE ATRÁS).
func torso_target(bi: BoneInstantiator) -> float:
	if not torso_on:
		return 0.0
	return -deg_to_rad(two_points(bi, torso_apex_deg, torso_fall_deg, torso_fall_s)) * bi.air_t


## LAS PIERNAS: cuánto baja el pie bajo su punto neutro (m). La flexión se mide con la pierna de verdad: el pie va a
## `largo × (1 − flexión)` bajo la cadera en reposo, así 0 es la pierna estirada justo y 1 el pie en la cadera.
func leg_tuck(bi: BoneInstantiator) -> float:
	var sizes := bi.skel_sizes_util
	var fast := 0.0
	if bi.air_vy >= 0.0:
		fast = clampf(bi.air_vy / bi.takeoff_vy, 0.0, 1.0) if bi.takeoff_vy > 0.05 else 0.0
	else:
		fast = clampf(-bi.air_vy / maxf(legs_fall_s * G, 0.01), 0.0, 1.0)
	var bend := lerpf(legs_still_bend, legs_fast_bend, fast) if legs_on else 0.0
	return (sizes.higher_leg_size.y + sizes.lower_leg_size.y) * (1.0 - bend) * LEG_REACH_SHARE - sizes.raycast_start_y_offset


## La pose de los brazos ahora: [adelante (rad), afuera (rad), quiebre].
func arm_pose(bi: BoneInstantiator) -> Vector3:
	return Vector3(
		deg_to_rad(two_points(bi, apex_front_deg, fall_front_deg, arms_fall_s)),
		deg_to_rad(two_points(bi, apex_out_deg, fall_out_deg, arms_fall_s)),
		two_points(bi, apex_bend, fall_bend, arms_fall_s))
