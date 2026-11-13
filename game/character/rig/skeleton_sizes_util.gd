class_name SkeletonSizesUtil

## ── LAS MEDIDAS DE UN PERSONAJE (rehecho de cero el 13/11/2026) ──────────────────────────────────────────────────────
## Todo lo que mide un personaje —los largos de hueso, la cadera, los hombros, la cabeza, la cápsula, la marcha, el
## alcance— sale de DOS cosas y nada más:
##   · SU FORMA DE BLOQUES (ver BlockShape): unos pocos números en metros por arquetipo, la guardada o la de fábrica. Es
##     el cuerpo que se ve (ver BlockBody), así que el esqueleto y la malla dicen lo mismo por construcción.
##   · SU POSTURA Y SU ANDAR, del arquetipo (ver EntityArchetype): el encorvado, la espalda, los hombros, la flexión de
##     las piernas, la zancada.
## Y al final todo se escala por la lupa y el tamaño del arquetipo (ver `size_scale`).
##
## *Hasta el 13/11/2026 esto calculaba un cuerpo entero a la manera vieja —del rig de Blender (`ReferenceRig`), la
## forma del torso con sus loop cuts (`TorsoShape`) y una escala horneada— y después la forma de bloques pisaba casi
## todo. Se rehízo para que salga sólo de la forma de bloques; los seis personajes quedaron iguales (medido con
## tests/sizes_check.tscn, ver docs/technical/analisis-personaje.md).*

## CUÁNTO MÁS GRANDE ES ESTE PERSONAJE, como múltiplo de lo que pide su forma: la lupa del sandbox por el tamaño del
## arquetipo (ver EntityArchetype.body_scale). Escalar el nodo no sirve —la IK planta los pies en metros del mundo y el
## personaje se hunde—, así que se escalan las medidas (ver `_scale_to`), y con ellas la marcha.
var size_scale : float = 1.0
## QUÉ ARQUETIPO ES este cuerpo (ver EntityArchetype.Archetype), −1 si no se sabe.
var archetype : int = -1

## Los tres tramos del alto, en metros: del tobillo a la cadera, de la cadera al tope del torso, y lo que sobresale
## arriba (el cuello y la cabeza).
var leg_height : float
var torso_height : float
var head_height : float
## Alto total, en metros. Es un RESULTADO: el tobillo, la pierna, el torso y la cabeza.
var total_height : float
## Medio ancho de cadera y de hombros: de la columna a donde nace la pierna y el brazo.
var hips_width : float
var shoulders_width : float
## Largo del brazo (hombro → muñeca), en metros.
var arm_reach : float
## Hasta dónde llega a agarrar, en metros: el mismo para todos (ver LocomotionCommon.interaction_reach).
var interaction_reach : float
## Cuánto estira el brazo al agarrar, en múltiplos de su reposo (ver EntityArchetype.arm_stretch).
var arm_stretch : float
## LA FORMA DE LA CABEZA, ya del alto que dice la forma de bloques (ver HeadForm, CharacterLooks.head_form_for).
var head_form: HeadForm = null
## LA FORMA DE BLOQUES que dio todo esto, y su escala (los números de la forma son metros sin lupa; los del personaje,
## esos por `block_unit`). La lee BlockBody para dibujar el cuerpo.
var block_shape: BlockShape = null
var block_unit := 1.0
## La muñeca de la mano, en metros (ver TubeHand.REFERENCE_WIDTH): el ancho del brazo.
var hand_width := 0.1
## LA PIEL (ver CharacterLook.skin); transparente es el crema de siempre.
var skin := Color(0, 0, 0, 0)

## ── LOS HUESOS ─────────────────────────────────────────────────────────────────────────────────────────────────────
## Cada Vector3 es un hueso: `.y` su largo (es lo único que lee el esqueleto) y `.x`/`.z` el ancho y el fondo de lo que
## lo rodea, de donde el ragdoll saca el radio de su cápsula (ver RagdollUtil).
var lower_spine_size: Vector3
var higher_spine_size: Vector3
var chest_size: Vector3
var neck_size: Vector3
var head_size: Vector3
var shoulder_width: Vector3
var upper_arm_size: Vector3
var lower_arm_size: Vector3
var hip_size: Vector3
var higher_leg_size: Vector3
var lower_leg_size: Vector3
var foot_size: Vector3
## CUÁNTO BAJA TODO LO DE LA CABEZA en el marco de su hueso, por el atlas (ver BlockShape.atlas): lo que el cuello se
## alargó para llegar hasta ahí.
var head_drop := 0.0
## DÓNDE NACE EL CUELLO, desde la punta del pecho (−Z es el frente): un radio de brazo arriba (la punta del pecho está a
## la altura de los hombros), y adelante si el cuello nace adelante (ver BlockShape.neck_forward).
var neck_anchor := Vector3.ZERO

## ── LA POSTURA, en radianes (del arquetipo) ────────────────────────────────────────────────────────────────────────
## EL ENCORVADO ES SÓLO EL CUELLO: `slouch` lo inclina hacia adelante, hasta el cuarto de vuelta (ver `NECK_SLOUCH_MAX`).
## La cabeza no hereda la inclinación: se queda derecha mientras el cuello se tumba (ver CustomBone.create).
var slouchiness_neck: float
const NECK_SLOUCH_MAX := PI * 0.5
## LA CURVA DE LA ESPALDA, que no es el encorvado: el pecho adelante y la lumbar atrás de contrapeso (ver
## EntityArchetype.spine_bend). Van como POSTURA DE POSE (ver CustomBone.set_local_posture), así que deforman el torso.
const SPINE_BEND_CHEST_MAX := 0.42
const SPINE_BEND_LOWER_MAX := 0.10
var spine_bend_chest: float
var spine_bend_lower: float
## LA POSTURA DE HOMBRO: adelantado (sobre la vertical) y caído (sobre el eje frontal), espejados entre lados. Con signo:
## negativo es hombros atrás o levantados.
const SHOULDER_FORWARD_MAX := 0.12
const SHOULDER_DROP_MAX := 0.10
var shoulder_forward: float
var shoulder_drop: float

## ── LOS BRAZOS EN REPOSO ───────────────────────────────────────────────────────────────────────────────────────────
## Cuánto se abren (radianes, negativo hacia afuera) y cuánto se doblan (0 derechos, 1 la mano en el hombro).
var arm_openness_angle: float
var arm_bentness: float
## Hacia dónde apunta el codo, 0..1 (0 = adentro, 0.5 = atrás, 1 = afuera).
const ELBOW_POLE_DIRECTION := 0.7
## Extensión máxima del brazo en reposo, en fracción de su cadena. NUNCA 1.0: con el codo colineal el plano de flexión
## se indefine y la mano sale dada vuelta.
const ARM_REST_EXTENSION := 0.99
## Techo del estirón al agarrar, en múltiplos del largo en reposo: una red de seguridad; la perilla es del arquetipo.
const MAX_ARM_STRETCH := 2.5
## Dónde cae la mano, el codo y el hombro en reposo, respecto del pivote de la pelvis (ver los `_compute_*`).
var left_arm_tip_rest_local: Vector3
var right_arm_tip_rest_local: Vector3
var left_arm_pole_rest_local: Vector3
var right_arm_pole_rest_local: Vector3
var left_arm_shoulder_rest_local: Vector3
var right_arm_shoulder_rest_local: Vector3

## ── LAS PIERNAS Y LA MARCHA ────────────────────────────────────────────────────────────────────────────────────────
## Extensión máxima de la pierna, en fracción de su largo: el techo de la IK. Pasado esto el pie no llega y la pelvis
## baja (ver BoneInstantiator._update_pelvis_drop). TIENE QUE SER ≥ `STAND_EXTENSION_STRAIGHT`, o el reposo es
## inalcanzable y el que pide la pierna más recta termina más agachado.
const MAX_EXTENSION := 0.995
## Cuánto de su largo usa la pierna parada, y de ahí la flexión de rodilla en reposo; el arquetipo elige dónde dentro de
## esta banda con `leg_bentness`. La curva es muy poco lineal: 0,995 → ~12°, 0,99 → 16°, 0,95 → 37°, 0,90 → ~52°.
const STAND_EXTENSION_STRAIGHT := 0.995
const STAND_EXTENSION_BENT := 0.90
## Altura del TOBILLO sobre el piso: el alto del pie, un radio de pierna (ver BlockShape, regla 3).
var ankle_height: float
## Altura de la pelvis parado, en metros sobre el piso, y cuánto le falta a la pierna para estar estirada.
var standing_pelvis_height: float
var distance_from_ground: float
## Medio ancho entre los pies parado (la cadera por `stance_width`).
var raycast_stance_offset: float
var raycast_leg_length: float
var raycast_start_y_offset: float = 0.0
var pole_distance: float
var step_height: float
var axis_weight_lateral:  float = 0.6
var axis_weight_forward:  float = 0.8
var axis_weight_backward: float = 1.0
## El hueso del cuello más corto que se arma, en metros.
const NECK_MIN := 0.005

## ── LA ZANCADA MANDA (03/11/2026) ──────────────────────────────────────────────────────────────────────────────────
## El paso caminando mide `stride` × `STEP_LEGS` piernas, y los pasos por segundo son la consecuencia: velocidad / paso.
const STEP_LEGS := 0.8
const MIN_STRIDE := 0.1
## LA ZANCADA MÁS CORTA de 0 a 1 (ver EntityArchetype.stride_reach): con 0 los pies se deslizarían.
const MIN_STRIDE_REACH := 0.03
## Duty factor: fracción del ciclo que el pie pasa APOYADO. Caminando >0,5 (doble apoyo); corriendo <0,5 (vuelo).
const DUTY_WALK := 0.62
const DUTY_RUN  := 0.40
## Excursión del pie desde la cadera caminando, en metros: una elección (sale de la zancada); la pelvis se acomoda.
var foot_reach: float
## LA ZANCADA, DE 0 A 1, y el largo de pierna contra el que se mide (m): lo que la pierna alcanza estirada.
var stride_reach := 0.5
var leg_reach := 0.0
## El ciclo entero caminando (dos pasos), en metros.
var walk_stride: float
## EXCURSIÓN del pie de este frame (A, metros): el pie pisa en +A y despega en −A.
var current_excursion: float
## ZANCADA de este frame (S, metros): lo que avanza el cuerpo en un ciclo. Con el pie fijo durante el apoyo, S = 2A/D.
var current_stride: float
var current_duty: float
## Velocidad de este frame en fracción de la máxima (0 quieto, 1 a fondo).
var current_speed_t: float = 0.0
## CUÁNTO SE CORRE PARA ADELANTE el lugar donde pisa, en metros (ver WalkStyle.lead).
var current_lead: float = 0.0
## El adelanto del estilo que no corre nada.
const LEAD_BASE := 0.25


## LAS MEDIDAS DE `inst`. `scale` es la lupa (ver `size_scale`); `head_slot` fuerza una forma de cabeza (ver
## HeadForms) en vez de la de su arquetipo, −1 la del arquetipo.
static func create(inst: EntityInstantiation, scale: float = 1.0, head_slot: int = -1) -> SkeletonSizesUtil:
	var s := SkeletonSizesUtil.new()
	var stats := inst.arch_final
	s.archetype = int(inst.archetype_type)
	var shape := BlockShapes.for_archetype(s.archetype)
	if shape == null:
		shape = BlockShape.factory(s.archetype)
	if shape == null:
		push_error("[SkeletonSizesUtil] El arquetipo %d no tiene forma de bloques (ver BlockShape.FACTORY)." % s.archetype)
		shape = BlockShape.new()
	s.block_shape = shape
	s._posture(stats)
	s._bones(shape, stats)
	s._head(shape, stats, head_slot)
	s._gait(shape, stats, inst)
	s.left_arm_tip_rest_local = _compute_arm_tip_local(true, s)
	s.right_arm_tip_rest_local = _compute_arm_tip_local(false, s)
	s.left_arm_pole_rest_local = _compute_arm_pole_local(true, s)
	s.right_arm_pole_rest_local = _compute_arm_pole_local(false, s)
	s.left_arm_shoulder_rest_local = _compute_arm_shoulder_local(true, s)
	s.right_arm_shoulder_rest_local = _compute_arm_shoulder_local(false, s)
	s._scale_to(scale * stats.body_scale)
	return s


## LA POSTURA, del arquetipo: el encorvado, la espalda, los hombros y los brazos.
func _posture(stats: EntityArchetype) -> void:
	slouchiness_neck = lerp_range(0.0, NECK_SLOUCH_MAX, stats.slouch)
	spine_bend_chest = lerp_range(0.0, SPINE_BEND_CHEST_MAX, stats.spine_bend)
	spine_bend_lower = lerp_range(0.0, SPINE_BEND_LOWER_MAX, stats.spine_bend)
	shoulder_forward = clampf(stats.shoulders_forward, -1.0, 1.0) * SHOULDER_FORWARD_MAX
	shoulder_drop = clampf(stats.shoulders_drop, -1.0, 1.0) * SHOULDER_DROP_MAX
	arm_bentness = stats.arm_bentness


## ── LOS HUESOS, DE LA FORMA DE BLOQUES (ver las cinco reglas en BlockShape) ───────────────────────────────────────
func _bones(shape: BlockShape, stats: EntityArchetype) -> void:
	var r_leg := shape.leg_width * 0.5
	var r_arm := shape.arm_width * 0.5
	# LA COLUMNA: del nudo de la cadera (un radio de pierna sobre el fondo de la caja de abajo, regla 2) a los hombros
	# (un radio de brazo debajo del tope del pecho, regla 1), en tres vértebras iguales.
	var chain := maxf(shape.torso_height - r_leg - r_arm, 0.06)
	lower_spine_size = Vector3(shape.lower_width, chain / 3.0, shape.lower_depth)
	higher_spine_size = Vector3(shape.middle_width, chain / 3.0, shape.middle_depth)
	chest_size = Vector3(shape.chest_width, chain / 3.0, shape.chest_depth)
	torso_height = shape.torso_height
	# LA CADERA, adentro de su caja (regla 2), nunca tan juntas que las piernas se crucen; LOS HOMBROS, un radio de brazo
	# afuera del costado del pecho, así el brazo lo roza (ver BlockShape.arm_open), o en el costado si el hombro va
	# metido en el torso (ver LocomotionCommon.shoulder_inside).
	var inside := LocomotionCommon.base().shoulder_inside
	hips_width = maxf(shape.lower_width * 0.5 - r_leg, r_leg)
	hip_size = Vector3(shape.leg_width, hips_width, shape.leg_width)
	raycast_stance_offset = hips_width * stats.stance_width
	shoulders_width = maxf(shape.chest_width * 0.5 + (0.0 if inside else r_arm), 0.02)
	shoulder_width = Vector3(shape.arm_width, shoulders_width, shape.arm_width)
	# LOS MIEMBROS: un ancho por miembro; el codo y la rodilla, en su fracción.
	upper_arm_size = Vector3(shape.arm_width, shape.arm_length * shape.elbow_at, shape.arm_width)
	lower_arm_size = Vector3(shape.arm_width, shape.arm_length * (1.0 - shape.elbow_at), shape.arm_width)
	higher_leg_size = Vector3(shape.leg_width, shape.leg_length * shape.knee_at, shape.leg_width)
	lower_leg_size = Vector3(shape.leg_width, shape.leg_length * (1.0 - shape.knee_at), shape.leg_width)
	foot_size = Vector3(shape.leg_width, shape.foot_length, shape.leg_width)
	leg_height = shape.leg_length
	hand_width = shape.arm_width
	arm_reach = shape.arm_length
	arm_stretch = minf(stats.arm_stretch, MAX_ARM_STRETCH)
	interaction_reach = LocomotionCommon.base().interaction_reach
	arm_openness_angle = -((0.0 if inside else shape._touch_angle(chain, 1.0)) + deg_to_rad(shape.arm_open))


## ── EL CUELLO Y LA CABEZA (reglas 4 y 5) ───────────────────────────────────────────────────────────────────────────
## El cuello nace en el tope del pecho —un radio de brazo arriba de la punta de la columna— y llega hasta el atlas. La
## cabeza es la forma de su arquetipo (o la forzada), llevada al alto de la forma de bloques.
func _head(shape: BlockShape, stats: EntityArchetype, head_slot: int) -> void:
	var r_arm := shape.arm_width * 0.5
	var form := HeadForms.form_for(head_slot if head_slot >= 0 else CharacterLooks.head_form_for(archetype))
	head_form = form.scaled(shape.head_height / maxf(form.total_height(), 0.01))
	var wide := maxf(head_form.bottom_width, head_form.top_width)
	if stats.has_neck:
		head_drop = shape.atlas * shape.head_height
		# Adelante es −Z del pecho.
		var forward := maxf((shape.chest_depth - shape.neck_width) * 0.5, 0.0) if shape.neck_forward else 0.0
		neck_anchor = Vector3(0.0, r_arm, -forward)
		neck_size = Vector3(shape.neck_width, maxf(shape.neck_length + head_drop, NECK_MIN), shape.neck_width)
	else:
		head_drop = 0.0
		neck_anchor = Vector3.ZERO
		neck_size = Vector3.ZERO
	head_size = Vector3(wide, maxf(shape.head_height - head_drop, 0.01), wide)
	head_height = cos(slouchiness_neck) * neck_size.y + head_size.y + (r_arm if not stats.has_neck else 0.0)


## ── EL PIE Y LA MARCHA ─────────────────────────────────────────────────────────────────────────────────────────────
## El tobillo a un radio de pierna (regla 3); la pelvis parada, lo que la pierna alcanza con la flexión del arquetipo.
func _gait(shape: BlockShape, stats: EntityArchetype, inst: EntityInstantiation) -> void:
	var legs := shape.leg_length
	ankle_height = shape.leg_width * 0.5
	total_height = ankle_height + legs + torso_height - ankle_height + head_height
	standing_pelvis_height = ankle_height + legs * lerp_range(STAND_EXTENSION_STRAIGHT, STAND_EXTENSION_BENT,
		stats.leg_bentness)
	distance_from_ground = legs - standing_pelvis_height
	set_stride(legs, inst.stride)
	current_duty = DUTY_WALK
	current_excursion = 0.0
	current_stride = 0.0
	step_height = legs * inst.step_height
	pole_distance = legs
	raycast_start_y_offset = legs * 0.35
	raycast_leg_length = legs


## MULTIPLICA TODO LO QUE ESTÁ EN METROS, y nada más (ver `size_scale`): los radianes y las fracciones no se tocan.
func _scale_to(factor: float) -> void:
	if is_equal_approx(factor, 1.0):
		return
	size_scale = factor
	for field: String in ["leg_height", "torso_height", "head_height", "total_height", "hips_width", "shoulders_width",
			"arm_reach", "interaction_reach", "block_unit", "hand_width", "head_drop", "neck_anchor",
			"lower_spine_size", "higher_spine_size", "chest_size", "neck_size", "head_size", "shoulder_width",
			"upper_arm_size", "lower_arm_size", "hip_size", "higher_leg_size", "lower_leg_size", "foot_size",
			"ankle_height", "standing_pelvis_height", "distance_from_ground", "raycast_stance_offset",
			"raycast_leg_length", "raycast_start_y_offset", "pole_distance", "step_height", "foot_reach", "leg_reach",
			"walk_stride", "current_excursion", "current_stride", "left_arm_tip_rest_local", "right_arm_tip_rest_local",
			"left_arm_pole_rest_local", "right_arm_pole_rest_local", "left_arm_shoulder_rest_local",
			"right_arm_shoulder_rest_local"]:
		set(field, get(field) * factor)
	if head_form != null:
		head_form = head_form.scaled(factor)


## DONDE QUEDA EL HOMBRO respecto del pivote de la pelvis, siguiendo la cadena hueso por hueso. Con la POSTURA de hombro:
## es pose, pero el reposo del brazo tiene que estar donde el hombro mira, o la IK le tira la mano para atrás.
static func _compute_arm_shoulder_local(left: bool, s: SkeletonSizesUtil) -> Vector3:
	return _chest_tip_local(s) + CustomBonesUtil.shoulder_posture(left, s) * _shoulder_arm_local(left, s)


## El tope del pecho respecto del pivote de la pelvis: la cadena entera de la columna.
static func _chest_tip_local(s: SkeletonSizesUtil) -> Vector3:
	return Vector3(0, s.lower_spine_size.y + s.higher_spine_size.y + s.chest_size.y, 0)


## Del tope del pecho al nacimiento del brazo, sin la postura: el hueso de hombro, de costado.
static func _shoulder_arm_local(left: bool, s: SkeletonSizesUtil) -> Vector3:
	return Vector3(-s.shoulder_width.y if left else s.shoulder_width.y, 0.0, 0.0)


## LA MANO EN REPOSO: colgando, abierta `arm_openness_angle` y doblada `arm_bentness`, sin estirar nunca del todo (ver
## `ARM_REST_EXTENSION`).
static func _compute_arm_tip_local(left: bool, s: SkeletonSizesUtil) -> Vector3:
	var sign_x := -1.0 if left else 1.0
	var arm_length := (s.upper_arm_size.y + s.lower_arm_size.y) * ARM_REST_EXTENSION
	var actual_distance: float = lerp(arm_length, 0.0, s.arm_bentness)
	var arm_dir := Basis(Vector3.FORWARD, s.arm_openness_angle * sign_x) * Vector3.DOWN
	return _chest_tip_local(s) + CustomBonesUtil.shoulder_posture(left, s) \
		* (_shoulder_arm_local(left, s) + arm_dir * actual_distance)


## EL POLO DEL CODO en reposo: atrás y un poco afuera del codo (ver `ELBOW_POLE_DIRECTION`).
static func _compute_arm_pole_local(left: bool, s: SkeletonSizesUtil) -> Vector3:
	var sign_x := -1.0 if left else 1.0
	var arm_dir := Basis(Vector3.FORWARD, s.arm_openness_angle * sign_x) * Vector3.DOWN
	var posture := CustomBonesUtil.shoulder_posture(left, s)
	var elbow := _chest_tip_local(s) + posture * (_shoulder_arm_local(left, s) + arm_dir * s.upper_arm_size.y)
	var backward := Vector3(0, 0, 1)
	var outward  := Vector3(sign_x, 0, 0)
	var pole_dir: Vector3
	if ELBOW_POLE_DIRECTION >= 0.5:
		pole_dir = backward.lerp(outward,  (ELBOW_POLE_DIRECTION - 0.5) * 2.0).normalized()
	else:
		pole_dir = backward.lerp(-outward, (0.5 - ELBOW_POLE_DIRECTION) * 2.0).normalized()
	return elbow + pole_dir * s.upper_arm_size.y * 0.8 + Vector3(0, 0, 0.5)


## ── AL ATERRIZAR, LOS PASOS VUELVEN A ARRANCAR (04/11/2026) ────────────────────────────────────────────────────────
## En el aire la velocidad que mira el paso se corta a cero y, desde que toca el piso, vuelve a la de verdad en
## `LocomotionCommon.landing_steps_s` (0, apagado): pasitos cortos que se alargan. Lo que tiene que estar en el aire (s)
## para contar como un salto: corriendo, el piso parpadea unos cuadros.
const AIR_MIN_S := 0.12
var _gait_share := 1.0
var _air_time := 0.0


func update(delta: float, inputs: AnimationInputs, inst: EntityInstantiation, ik_util: IkUtil) -> void:
	_air_time = _air_time + delta if not inputs.grounded else 0.0
	var restart := LocomotionCommon.base().landing_steps_s
	if restart <= 0.0:
		_gait_share = 1.0
	elif _air_time > AIR_MIN_S:
		_gait_share = 0.0
	else:
		_gait_share = minf(_gait_share + delta / restart, 1.0)
	_update_gait(inputs, inst.arch_final, ik_util.style if ik_util.style != null else WalkStyle.plain())
	ik_util.advance_gait(delta, self, inputs)


## EL PASO DE `stride` en una pierna de `leg` (ver LA ZANCADA MANDA): el ciclo caminando y la excursión caminando.
func set_stride(leg: float, stride: float) -> void:
	stride_reach = clampf(stride, 0.0, 1.0)
	leg_reach = leg * MAX_EXTENSION
	# Hasta el primer paso (ver `_update_gait`), con el estilo y el sprint de siempre.
	_set_walk_stride(WalkStyle.plain(), 2.2)


## EL PASO DE LA ZANCADA DE 0 A 1: el ciclo a la velocidad de caminar —`walk_stride`— tal que, a toda velocidad
## (`sprint` veces la de caminar), el pie llegue a `stride_reach` largos de pierna de la cadera. `foot_reach` es la
## excursión caminando.
func _set_walk_stride(ws: WalkStyle, sprint: float) -> void:
	var walk_duty := clampf(1.0 - ws.swing_share, 0.05, 0.95)
	var top_duty := minf(DUTY_RUN, walk_duty)
	var top_cycle := 2.0 * maxf(stride_reach, MIN_STRIDE_REACH) * leg_reach / maxf(top_duty, 0.01)
	walk_stride = top_cycle / maxf(pow(maxf(sprint, 1.0), maxf(ws.stride_growth, 0.0)), 0.001) * ws.stride_scale
	foot_reach = walk_stride * walk_duty * 0.5


## Excursión, duty y zancada de este frame, en función de la velocidad. El ciclo es el de caminar por
## `(v / caminar) ^ crecimiento`: llega a cero parado —así quieto no hay pasos— y se alarga corriendo. El duty baja de
## caminata a carrera. La excursión sale del ciclo y del apoyo (`A = S·D/2`) para que el pie apoyado no patine.
func _update_gait(inputs: AnimationInputs, entity_stats: EntityArchetype, ws: WalkStyle) -> void:
	var instant_speed := Vector2(inputs.velocity.x, inputs.velocity.z).length() * _gait_share
	var max_speed: float = entity_stats.speed * entity_stats.sprint_multiplier * CharacterRigidBody3D.SPEED_SCALE
	var t: float = clamp(instant_speed / max(max_speed, 0.01), 0.0, 1.0)
	current_speed_t = t
	var walk_duty: float = clampf(1.0 - ws.swing_share, 0.05, 0.95)
	current_duty = lerp_range(walk_duty, minf(DUTY_RUN, walk_duty), t)
	var walk_speed: float = maxf(entity_stats.speed * CharacterRigidBody3D.SPEED_SCALE, 0.01)
	_set_walk_stride(ws, entity_stats.sprint_multiplier)
	current_stride = walk_stride * pow(instant_speed / walk_speed, maxf(ws.stride_growth, 0.0))
	# NUNCA MÁS LEJOS QUE LA PIERNA: más rápido que el sprint (el turbo del ente) el paso no pasa de un largo de pierna.
	current_excursion = minf(current_stride * current_duty * 0.5, leg_reach)
	current_lead = (ws.lead - LEAD_BASE) * current_stride


static func lerp_range(min_val: float, max_val: float, t: float) -> float:
	return min_val + (max_val - min_val) * clamp(t, 0.0, 1.0)
