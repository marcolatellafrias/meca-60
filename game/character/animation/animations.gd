class_name BoneAnimations
extends Node

var bi: BoneInstantiator

## Cuánto se recuesta el tronco sentado, desde la pelvis, por cada radián que mira para arriba.
const SEATED_LOOK_UP_LEAN := 0.3
## CUÁNTO GIRA LA BASE DE LA COLUMNA por unidad de `impact_xz` (los golpes y la inercia): lo usa también la cámara para
## seguir el sacudón de los golpes (ver PlayerController._hit_sway).
const IMPACT_LEAN := 1.35

## LA COLUMNA QUE GIRA, EN 1 (ver `twist`): cuánto gira cada vértebra y cuánto acompaña la cadera, por unidad de paso.
const TWIST_SPINE := -0.2
const TWIST_HIPS := 0.1
## ── EL BRAZO SE ABRE DEL CUERPO, APARTE DEL BRACEO (07/11/2026, el usuario: «separar el braceo en dos perillas:
## adelante y atrás, y se abre del cuerpo») ───────────────────────────────────────────────────────────────────────────
## Cuánto gira el brazo hacia afuera, en radianes, por el cuadrado de en qué punto del paso está y qué tan rápido va
## (`foot_spread_unified.y × speed_norm`): cero con los pies juntos, lo más en los extremos del paso, y más corriendo. La
## escala la perilla de todos (WalkStyle.arm_open); el braceo ya no la mueve. *Hasta entonces salía del mismo braceo
## —lo que un péndulo del largo del brazo sube en lo que la mano iba adelante—, así que más braceo era también más
## abierto. 0,48 es lo que daba eso para un arquetipo promedio, así arranca parecido.*
const ARM_OPEN := 0.48


func _ready() -> void:
	bi = get_parent() as BoneInstantiator

func register_all() -> void:
	var PA := ProceduralBoneAnimator
	var ls := bi.locomotion_signals

	var shoulder_swing   := bi.entity_instantiation.shoulder_swing
	# EL ESTILO DE CAMINAR (ver WalkStyle): cada grupo de abajo se escala con su número, leído en cada cuadro.
	var style := bi.walk_style
	var sway := func() -> float: return style.hip_sway
	var twist := func() -> float: return style.twist
	var shoulders := func() -> float: return style.shoulders


	var right_hip      := bi.custom_bones_util.right_hip
	var left_hip       := bi.custom_bones_util.left_hip
	var lower_spine    := bi.custom_bones_util.lower_spine
	var higher_spine    := bi.custom_bones_util.higher_spine
	var chest          := bi.custom_bones_util.chest
	var right_shoulder := bi.custom_bones_util.right_shoulder
	var left_shoulder  := bi.custom_bones_util.left_shoulder
	var pa             := bi.procedural_animator

	# ─── HIPS ───────────────────────────────────────────────────────────────────

	# LA CADERA QUE SE MECE: sólo `hip_sway` (ver EntityArchetype, UNA PERILLA, UN MOVIMIENTO).
	pa.register(right_hip, PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_Z,  0.6, null, sway)
	pa.register(left_hip,  PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_Z,  0.6, null, sway)
	pa.register(right_hip, PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_X, -0.1, null, sway)
	pa.register(left_hip,  PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_X, -0.1, null, sway)

	# LA COLUMNA QUE GIRA CONTRA LAS PIERNAS, toda con `twist`: la cadera acompaña un poco y cada vértebra gira lo mismo.
	pa.register(right_hip, PA.Axis.ROT_X, PA.SignalType.FOOT_SPREAD_UNIFIED_Z, -TWIST_HIPS, null, twist)
	pa.register(left_hip,  PA.Axis.ROT_X, PA.SignalType.FOOT_SPREAD_UNIFIED_Z,  TWIST_HIPS, null, twist)

	# ─── SPINE ──────────────────────────────────────────────────────────────────

	# El rebote vertical de cadera YA NO se registra acá. Era un peso artístico contra la separación de
	# pies — la idea correcta, pero desacoplada de la geometría: podía pelearse con lo que la pierna
	# necesitaba y despegar el pie del piso. Ahora la pelvis baja lo que la pierna pide
	# (BoneInstantiator._update_pelvis_drop) y `root_bounciness` es el MULTIPLICADOR que exagera esa
	# bajada. Misma variable, mismo look, pero imposible de romper. Ver character-parametric:docs/technical/character-animation.md.

	# La inclinación de costado de lower_spine por el ancho de los pies; su perilla, `spine_roll` (ver WalkStyle).
	pa.register_formula(lower_spine, PA.Axis.ROT_Z,
		func(): return ls.foot_spread_unified.x * (0.01 + 0.04 * ls.speed_norm) * style.spine_roll,
		1.0)

	for bone: CustomBone in [lower_spine, higher_spine, chest]:
		pa.register(bone, PA.Axis.ROT_Y, PA.SignalType.FOOT_SPREAD_UNIFIED_Z, TWIST_SPINE, null, twist)

	# ─── SPINE BOW ───────────────────────────────────────────────────────────────

	var bow_w := 0.15
	# El arco, con su perilla (`spine_bow`, ver EntityArchetype, UNA PERILLA, UN MOVIMIENTO).
	var bow := func() -> float: return style.spine_bow
	# La curva del bow repartida en tres en vez de cuatro: `middle` aportaba +1.0 y su mitad se fue a
	# cada vecino, así que la suma sigue dando cero y el torso no queda torcido en neto.
	pa.register(lower_spine,  PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_Z,  bow_w * 1.0, null, bow)
	pa.register(higher_spine, PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_Z, -bow_w * 0.5, null, bow)
	pa.register(chest,        PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_Z, -bow_w * 0.5, null, bow)
	pa.register(lower_spine,  PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_Z,  0.03, null, bow)

	# ─── SPINE TILT ──────────────────────────────────────────────────────────────

	# SIGNO INVERTIDO respecto de la versión original: el torso se inclinaba HACIA EL LADO CONTRARIO al
	# que corre. Provisorio — cuando lo detallemos, esto probablemente quiera depender de la aceleración
	# y no de la velocidad (inclinarse al arrancar y al frenar, no mientras se corre a velocidad pareja).
	# El peso es el `lean` del estilo (0,05 de siempre).
	var lean := func() -> float: return style.lean
	pa.register(lower_spine, PA.Axis.ROT_X, PA.SignalType.H_VEL_Z, 1.0, null, lean)
	pa.register(lower_spine, PA.Axis.ROT_Z, PA.SignalType.H_VEL_X, 1.0, null, lean)
	# LO QUE SE LLEVA: el cuerpo se echa atrás (ver BoneInstantiator.carry_lean, LocomotionCommon). Con el mismo signo que la
	# de la velocidad: hacia donde apunta `carry_lean` (atrás es +).
	# DÓNDE SE DOBLA (LocomotionCommon.carry_lean_spread): en la base de la columna, o repartido en las tres vértebras; y LA
	# CADERA ADELANTE, hacia el paquete (`carry_lean_hips`).
	var at_base := func() -> float: return 1.0 - LocomotionCommon.base().carry_lean_spread * 2.0 / 3.0
	var up_spine := func() -> float: return LocomotionCommon.base().carry_lean_spread / 3.0
	pa.register_formula(lower_spine, PA.Axis.ROT_X, func(): return bi.carry_lean.y * at_base.call(), 1.0)
	pa.register_formula(lower_spine, PA.Axis.ROT_Z, func(): return bi.carry_lean.x * at_base.call(), 1.0)
	for bone: CustomBone in [higher_spine, chest]:
		pa.register_formula(bone, PA.Axis.ROT_X, func(): return bi.carry_lean.y * up_spine.call(), 1.0)
		pa.register_formula(bone, PA.Axis.ROT_Z, func(): return bi.carry_lean.x * up_spine.call(), 1.0)
	pa.register_formula(lower_spine, PA.Axis.POS_Z,
		func(): return -bi.carry_lean_share * LocomotionCommon.base().carry_lean_hips * signf(bi.carry_lean.y + 0.0001), 1.0)

	# ─── SHOULDERS ───────────────────────────────────────────────────────────────

	# ── EL GIRO ADELANTE Y ATRÁS DEL HOMBRO VA AL BRAZO; EL CAMBIO DE ÁNGULO SE QUEDA (04/11/2026, el usuario: «lo
	# que me molesta es esa rotación en ese sentido, pero me gusta el movimiento del hombro, el cambio de ángulo») ──────
	# Desde que el pecho está partido en dos —cada mitad pegada a su hombro, ver BlockBody._split_chest—, el balanceo
	# alternado del hombro (ROT_Y, −0,95 por `shoulder_swing`) giraba la mitad del pecho adelante y atrás, y con
	# `shoulder_swing` en 2 (el gordo, el fornido) se veía muchísimo: ése pasa al braceo de los brazos (ver ARM SWING,
	# ver EntityArchetype, UNA PERILLA, UN MOVIMIENTO: desde el 07/11/2026 está sumado al `arm_swing` de cada arquetipo). Lo que inclina el hombro arriba y abajo (ROT_Z) sigue en el hueso.
	#
	# `shoulder_swing`: 1.0 = el andar de referencia; por debajo de 1 el hombro se apaga (el viejo), por encima se exagera.
	pa.register(right_shoulder, PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_X,  shoulder_swing * 0.05, null, shoulders)
	pa.register(left_shoulder,  PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_X,  shoulder_swing * 0.05, null, shoulders)
	# Subida y bajada de hombros al caminar. Los dos con el mismo signo, o sea que suben y bajan JUNTOS
	# con la zancada. Estaba en -0.3 y se leía como un rebote antinatural.
	pa.register(right_shoulder, PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_Z, shoulder_swing * -0.12, null, shoulders)
	pa.register(left_shoulder,  PA.Axis.ROT_Z, PA.SignalType.FOOT_SPREAD_UNIFIED_Z, shoulder_swing * -0.12, null, shoulders)

	# ─── HEAD / NECK PITCH ───────────────────────────────────────────────────────

	_register_camera_pitch_animations()

	# ─── ARM SWING ───────────────────────────────────────────────────────────────

	var arm_swing  := bi.entity_instantiation.arch_final.arm_swing
	var arm_total  := bi.skel_sizes_util.upper_arm_size.y + bi.skel_sizes_util.lower_arm_size.y
	# El braceo del arquetipo (con sus modificadores ya aplicados, ver WalkStyle, UN NOMBRE, UN LUGAR): lo lee cada fórmula de abajo.
	# Más lo que antes hacía el balanceo de hombro (ver EL BALANCEO DE HOMBRO VA AL BRAZO).
	var arm_weight := func() -> float: return arm_swing * arm_total
	var ik         := bi.ik_util

	# ── EL BRACEO GIRA EN EL HOMBRO, Y EL CODO LO ACOMPAÑA (07/11/2026, el usuario: «cuando tengo personajes con
	# brazos muy largos… en algunas partes se vuelve como más recto, en otras se dobla más»; eligió «b y c») ──────────
	# La mano no se corre por partes —adelante, arriba, afuera— sino que GIRA ALREDEDOR DEL HOMBRO a la distancia que
	# tiene en reposo: no se acerca ni se aleja de él, así que el codo guarda su doblez todo el braceo. El punto hacia
	# donde se dobla el codo (el pole) gira con el mismo giro, así el codo apunta siempre para el mismo lado del brazo.
	# Cuánto: el mismo adelante de antes (`d`, la mano contraria a la pierna de su lado) hecho ángulo sobre esa
	# distancia; y hacia afuera, su propia abertura (ver ARM_OPEN). *Hasta entonces se le sumaba a la mano adelante `d`, arriba lo que sube un péndulo del brazo ESTIRADO más
	# un 40 % de `d`, y afuera lo mismo que el péndulo: con el codo doblado en reposo, la distancia al hombro cambiaba
	# en el braceo y el codo se estiraba y se doblaba —en los brazos largos, hasta quedar recto—.*
	# EL CODO AL CORRER (ver WalkStyle.run_elbow): la mano a su distancia de reposo hasta la velocidad de caminar de este
	# personaje, y de ahí a su sprint, de a poco, hasta `1 − run_elbow` de esa distancia. Relativo a SU rango (los dos
	# extremos son suyos), así cada uno dobla el codo cuando él corre, sea cual sea su velocidad.
	var walk_share := 1.0 / maxf(bi.entity_archetype.sprint_multiplier, 1.001)
	var closer := func() -> float:
		return 1.0 - style.run_elbow * smoothstep(walk_share, 1.0, bi.skel_sizes_util.current_speed_t)
	for left: bool in [true, false]:
		var side := 1.0 if left else -1.0
		var sizes := bi.skel_sizes_util
		var shoulder: Vector3 = sizes.left_arm_shoulder_rest_local if left else sizes.right_arm_shoulder_rest_local
		var tip: Vector3 = sizes.left_arm_tip_rest_local if left else sizes.right_arm_tip_rest_local
		var pole: Vector3 = sizes.left_arm_pole_rest_local if left else sizes.right_arm_pole_rest_local
		var reach := maxf((tip - shoulder).length(), 0.01)
		# EL GIRO de este cuadro: adelante (sobre el eje de costado; + lleva la mano hacia −Z, adelante) y afuera
		# (sobre el eje de adelante; + abre el brazo izquierdo hacia −X, `side` da vuelta el derecho).
		var turn := func() -> Basis:
			var s: float = ls.foot_spread_unified.y * ls.speed_norm
			var d: float = side * s * arm_weight.call()
			# SE ABRE DEL CUERPO, APARTE DEL BRACEO (ver ARM_OPEN): en los extremos del paso, más corriendo.
			var out := ARM_OPEN * style.arm_open * s * s
			return Basis(Vector3.FORWARD, side * out) * Basis(Vector3.RIGHT, d / reach)
		# Lo que se corre un punto (la mano o el codo) por ese giro, alrededor del hombro, en un eje. LA MANO, además, se
		# acerca al hombro al correr (`closer`): el codo se dobla más.
		for each: Array in [[ik.left_arm_ik_target if left else ik.right_arm_ik_target, tip, true],
				[ik.left_arm_pole if left else ik.right_arm_pole, pole, false]]:
			var node: Node3D = each[0]
			var from: Vector3 = each[1] - shoulder
			var hand: bool = each[2]
			for axis: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
				pa.register_node_formula(node, axis, func() -> float:
					var at := from * (closer.call() as float) if hand else from
					return ((turn.call() as Basis) * at - from).dot(axis), 1.0)

	# ─── EN EL AIRE: UNA REGLA POR PARTE (ver LocomotionCommon, los sliders de la F1) ───────────────────────────────
	# El torso, adelante al subir y atrás al caer (`BoneInstantiator.air_lean`, que lo acompaña a su ritmo). Los brazos,
	# con sus dos poses, en ArmsController (`_apply_air_arms`); las piernas, en IkUtil.update_airborne_target.
	pa.register_formula(lower_spine, PA.Axis.ROT_X, func(): return bi.air_lean, 1.0)

	# ─── ARM COMPRESS ────────────────────────────────────────────────────────────

	var arm_forward_scale := bi.arms_controller.ARM_FORWARD_SCALE
	var arm_bend_scale    := bi.arms_controller.ARM_BEND_SCALE

	pa.register_node_formula(ik.left_arm_ik_target, Vector3.FORWARD,
		func(): return bi.locomotion_signals.arm_compress, arm_forward_scale)
	pa.register_node_formula(ik.right_arm_ik_target, Vector3.FORWARD,
		func(): return bi.locomotion_signals.arm_compress, arm_forward_scale)
	pa.register_node_formula(ik.left_arm_ik_target, Vector3.UP,
		func(): return bi.locomotion_signals.arm_compress, arm_bend_scale)
	pa.register_node_formula(ik.right_arm_ik_target, Vector3.UP,
		func(): return bi.locomotion_signals.arm_compress, arm_bend_scale)

	# ─── LANDING ─────────────────────────────────────────────────────────────────

	var impact_y_weight := 0.9
	# Cuánto se hunde, de todos (LocomotionCommon, Aterrizaje).
	var land := func() -> float: return maxf(0.0, ls.impact_y_signed_smooth / 10.0) * LocomotionCommon.base().landing_depth

	pa.register_formula(lower_spine, PA.Axis.POS_Y, land, -impact_y_weight * 2)
	pa.register_formula(lower_spine, PA.Axis.POS_Z, land, impact_y_weight)
	pa.register_formula(lower_spine, PA.Axis.ROT_X, land, -impact_y_weight * 3)

	pa.register_formula(right_shoulder, PA.Axis.ROT_Z, land, -impact_y_weight * 0.5)
	pa.register_formula(left_shoulder, PA.Axis.ROT_Z, land, impact_y_weight * 0.5)

	# ─── XZ IMPACT ───────────────────────────────────────────────────────────────

	pa.register_formula(lower_spine, PA.Axis.ROT_X,
		func(): return ls.impact_xz_smooth.y, IMPACT_LEAN)
	pa.register_formula(lower_spine, PA.Axis.ROT_Z,
		func(): return ls.impact_xz_smooth.x, IMPACT_LEAN)


func _register_camera_pitch_animations() -> void:
	if not bi.kind.looks():
		return  # el que tiene quien lo maneje (ver CharacterKind.looks); los NPCs puros no miran con la cámara
	var pa             := bi.procedural_animator
	var PA             := ProceduralBoneAnimator
	var pitch_callable := _make_pitch_callable()

	# ─── HEAD / NECK / SPINE PITCH (ambas direcciones) ───────────────────────
	pa.register_formula(bi.custom_bones_util.head,         PA.Axis.ROT_X, pitch_callable, 0.50)
	if is_instance_valid(bi.custom_bones_util.neck):
		pa.register_formula(bi.custom_bones_util.neck,     PA.Axis.ROT_X, pitch_callable, 0.25)
	pa.register_formula(bi.custom_bones_util.chest,        PA.Axis.ROT_X, pitch_callable, 0.12)
	pa.register_formula(bi.custom_bones_util.higher_spine,  PA.Axis.ROT_X, pitch_callable, 0.08)

	# ─── EXTRA SPINE BEND SOLO AL MIRAR ABAJO ────────────────────────────────
	var look_down_extra := 0.12
	var lower_spine     := bi.custom_bones_util.lower_spine
	var higher_spine     := bi.custom_bones_util.higher_spine
	var chest           := bi.custom_bones_util.chest
	var down_callable   := func() -> float: return -min(0.0, pitch_callable.call())
	pa.register_formula(lower_spine,  PA.Axis.ROT_X, down_callable, -look_down_extra * 0.4)
	pa.register_formula(higher_spine,  PA.Axis.ROT_X, down_callable, -look_down_extra * 1.0)
	pa.register_formula(chest,        PA.Axis.ROT_X, down_callable, -look_down_extra * 0.5)
	pa.register_formula(lower_spine,  PA.Axis.POS_Y, down_callable, -look_down_extra * 0.6)
	pa.register_formula(lower_spine,  PA.Axis.POS_Z, down_callable,  look_down_extra * 0.4)

	# ─── SENTADO, AL MIRAR ARRIBA SE RECUESTA (28/10/2026, lo pidió el usuario) ───────
	# «Que tengan la espalda apoyada en el respaldar y que se doble cuando miran para arriba»: el tronco se va para atrás
	# desde la pelvis, que es donde gira el respaldo (al pie del almohadón), así la espalda no se le despega.
	var seated_up := func() -> float: return maxf(0.0, pitch_callable.call()) if bi.is_seated else 0.0
	pa.register_formula(lower_spine, PA.Axis.ROT_X, seated_up, SEATED_LOOK_UP_LEAN)


func refresh_camera_animations() -> void:
	if not bi.kind.looks():
		return
	var PA := ProceduralBoneAnimator
	var bones := [
		bi.custom_bones_util.head,
		bi.custom_bones_util.neck,
		bi.custom_bones_util.chest,
		bi.custom_bones_util.higher_spine,
	]
	for bone in bones:
		if is_instance_valid(bone):
			bi.procedural_animator.unregister_bone(bone)
	_register_camera_pitch_animations()


func _make_pitch_callable() -> Callable:
	# El pitch ya viene clampeado en AnimationInputs (productor local / owner antes de enviar).
	var bi_ref := bi
	return func() -> float:
		return bi_ref.animation_inputs.head_pitch if bi_ref.animation_inputs != null else 0.0
