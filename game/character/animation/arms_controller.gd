class_name ArmsController
extends Node

var bi: BoneInstantiator
var anim_mod: AnimationModifiers

const ARM_COMPRESS_CROUCH:       float = 1.35
const ARM_COMPRESS_JUMP:         float = 0.45
const ARM_COMPRESS_IMPACT:       float = 0.30
const ARM_FORWARD_SCALE:         float = 0.25
const ARM_BEND_SCALE:            float = 0.18
const HANDLE_SWITCH_SPEED:       float = 8.0
const GRAB_MIN_BEND_FACTOR:      float = 0.97
## LA IDA DEL BRAZO, AL AGARRAR, SEGÚN LO QUE TIENE QUE RECORRER (como la ley de Fitts: lo cerca se toca enseguida, lo
## lejos tarda un poco más): la mano LLEGA, del todo, en `REACH_BASE` más `REACH_PER_METRE` por cada metro de la mano a lo
## que agarra —0,06 s a 10 cm, 0,1 s a 50 cm—, con un arranque y una llegada suaves (smoothstep). *Era un lerp que llegaba
## al 90 % en 0,08–0,16 s y después se acercaba cada vez más lento sin terminar nunca: el usuario la veía lenta y
## «nunca se le siente como asentada en ese punto» (29/10/2026).* La vuelta, al soltar, en `RELEASE_TIME`.
const REACH_BASE:      float = 0.05
const REACH_PER_METRE: float = 0.1
const RELEASE_TIME:    float = 0.15

## Inclinación del torso al agarrar, en radianes. FORWARD se usa agarrando algo por debajo del pecho,
## BACK por encima — lo maneja la ALTURA del punto agarrado, no su distancia (ver
## _apply_grab_body_adjustments, que explica por qué).
const GRAB_ROOT_TILT_BACK:    float = 0.09
const GRAB_ROOT_TILT_FORWARD: float = 0.13

const GRAB_SHOULDER_Z_UP:      float = 0.65
const GRAB_SHOULDER_Z_DOWN:    float = 0.32
const GRAB_SHOULDER_Y_BACK:    float = 0.65
const GRAB_SHOULDER_Y_FORWARD: float = 0.85

var _grab_left_blend:  float = 0.0
var _grab_right_blend: float = 0.0
var _grab_left_blend_target:  float = 0.0
var _grab_right_blend_target: float = 0.0

## ── LO QUE SE GUARDA DE UN CUADRO AL OTRO, EN EL MARCO DEL CUERPO (02/11/2026) ──────────────────────────────────────
## Los puntos de las manos, de dónde venían, el pecho y el punto agarrado se guardan EN EL MARCO DE LA CÁPSULA
## (`_on_body` al escribir, `_in_world` al leer), no del mundo. Guardados en el mundo, en la meca que vuela se quedaban
## donde estaban: al soltar, la mano volvía hacia un punto que la meca ya había dejado atrás, y el brazo se iba para atrás
## unos cuadros (lo vio el usuario: «todo lo de los personajes a bordo relativo… prolijo, simple y bien
## explicado»). Caminando pasaba igual, más chico. Lo que se agarra todavía se lee en el mundo cada cuadro, de su nodo.
var _grab_left_handle_local:  Vector3 = Vector3.ZERO
var _grab_right_handle_local: Vector3 = Vector3.ZERO
var _grab_left_handle_node:   Node3D  = null
var _grab_right_handle_node:  Node3D  = null
var _grab_left_blend_t:  float = 1.0
var _grab_right_blend_t: float = 1.0
var _grab_left_prev_local:  Vector3 = Vector3.ZERO
var _grab_right_prev_local: Vector3 = Vector3.ZERO


var _grab_dist_min:         float   = 0.0
var _grab_dist_max:         float   = 1.0
var _grab_chest_rest_local: Vector3 = Vector3.ZERO
var _grab_point_local:      Vector3 = Vector3.ZERO
## Lo que se está agarrando, para saber cómo se toma (ver Interactable.Grip).
var _grab_interactable: Interactable = null
## Para qué se eligieron las manos que hay (ver `_kept_handles`).
var _handles_for: Interactable = null

const GRAB_POLE_SIDE_OFFSET: float = 3.0
## Cuánto adelante cuelga el codo (ver EL CODO CUELGA), respecto de lo que cuelga para abajo: sólo se nota con la mano
## arriba del hombro, donde lo de abajo se va con la línea del brazo.
const ELBOW_FORWARD: float = 0.3

## Un punto del mundo, al marco de la cápsula; y de vuelta (ver LO QUE SE GUARDA DE UN CUADRO AL OTRO).
func _on_body(world: Vector3) -> Vector3:
	return bi.char_rigidbody.global_transform.affine_inverse() * world if is_instance_valid(bi.char_rigidbody) else world

func _in_world(local: Vector3) -> Vector3:
	return bi.char_rigidbody.global_transform * local if is_instance_valid(bi.char_rigidbody) else local

func setup(anim: AnimationModifiers) -> void:
	anim_mod = anim

func update_arm_compress(jump_squat_t: float, crouch_t: float) -> void:
	var rb           := bi.char_rigidbody
	var arm_bentness := bi.entity_instantiation.arch_final.arm_bentness
	var remaining    := 1.0 - arm_bentness
	var raw: float   = jump_squat_t * ARM_COMPRESS_JUMP \
		+ crouch_t * ARM_COMPRESS_CROUCH \
		+ max(0.0, rb.impact_y) * ARM_COMPRESS_IMPACT
	bi.locomotion_signals.arm_compress = clamp(raw * remaining, 0.0, remaining)

func apply_world_overrides(delta: float) -> void:
	_apply_air_arms()
	_apply_throw_arms(delta)
	_apply_grab_arms(delta)


## LOS BRAZOS EN EL AIRE, SUS DOS POSES (ver LocomotionCommon, los brazos): la mano de cada lado va adonde dice la pose —desde
## su hombro, colgando, sube hacia adelante y se abre hacia afuera, y el quiebre la acerca—, pesando con `air_t`; el
## codo, para atrás y un poco abajo, así doblar no abre el brazo. Va antes del tiro y del agarre, que mandan sobre esto.
func _apply_air_arms() -> void:
	var air := LocomotionCommon.base()
	if not air.arms_on or bi.air_t <= 0.0 or not is_instance_valid(bi.ik_util):
		return
	var ik := bi.ik_util
	var cb := bi.custom_bones_util
	var basis := bi.char_rigidbody.global_basis.orthonormalized()
	var up := basis.y
	var forward := -basis.z
	var pose := air.arm_pose(bi)
	var sizes := bi.skel_sizes_util
	var arm_total := sizes.upper_arm_size.y + sizes.lower_arm_size.y
	var reach := arm_total * lerpf(1.0, AIR_BENT_REACH, pose.z)
	for left: bool in [true, false]:
		var side := -basis.x if left else basis.x
		var shoulder: Vector3 = (cb.left_upper_arm if left else cb.right_upper_arm).global_position
		var swung := -up * cos(pose.x) + forward * sin(pose.x)
		var dir := swung * cos(pose.y) + side * sin(pose.y)
		var hand := shoulder + dir * reach
		var elbow := (-forward * 0.8 - up * 0.4 + side * 0.15).normalized()
		var pole := shoulder + dir * reach * 0.5 + elbow * arm_total
		var target := ik.left_arm_ik_target if left else ik.right_arm_ik_target
		var pole_node := ik.left_arm_pole if left else ik.right_arm_pole
		target.global_position = target.global_position.lerp(hand, bi.air_t)
		pole_node.global_position = pole_node.global_position.lerp(pole, bi.air_t)


## Con el quiebre entero, la mano queda a esto del largo del brazo del hombro.
const AIR_BENT_REACH := 0.45

func update_grab_handles(delta: float, interactable: Interactable, chest_rest_world: Vector3, grab_point: Node3D) -> void:
	_grab_chest_rest_local = _on_body(chest_rest_world)
	_grab_interactable = interactable
	if is_instance_valid(grab_point):
		_grab_point_local = _on_body(grab_point.global_position)

	var handles := _kept_handles(interactable)
	var left_h  := handles[0]
	var right_h := handles[1]

	_grab_left_blend_target  = 1.0 if is_instance_valid(left_h)  else 0.0
	_grab_right_blend_target = 1.0 if is_instance_valid(right_h) else 0.0

	if left_h != _grab_left_handle_node:
		_grab_left_prev_local  = _grab_left_handle_local
		_grab_left_handle_node = left_h
		_grab_left_blend_t     = 0.0
	if right_h != _grab_right_handle_node:
		_grab_right_prev_local  = _grab_right_handle_local
		_grab_right_handle_node = right_h
		_grab_right_blend_t     = 0.0

	_grab_left_blend_t  = clamp(_grab_left_blend_t  + delta * HANDLE_SWITCH_SPEED, 0.0, 1.0)
	_grab_right_blend_t = clamp(_grab_right_blend_t + delta * HANDLE_SWITCH_SPEED, 0.0, 1.0)

	if is_instance_valid(left_h):
		_grab_left_handle_local  = _grab_left_prev_local.lerp(_on_body(left_h.global_position),  _grab_left_blend_t)
	if is_instance_valid(right_h):
		_grab_right_handle_local = _grab_right_prev_local.lerp(_on_body(right_h.global_position), _grab_right_blend_t)

func start_grab(interactable: Interactable, chest_rest_world: Vector3, grab_point: Node3D, dist_min: float, dist_max: float) -> void:
	_grab_dist_min         = dist_min
	_grab_dist_max         = dist_max
	_grab_chest_rest_local = _on_body(chest_rest_world)
	_grab_point_local      = _on_body(grab_point.global_position if is_instance_valid(grab_point) else chest_rest_world)
	_grab_interactable     = interactable

	var cb      := bi.custom_bones_util
	var handles := _assign_handles(interactable)
	_handles_for = interactable
	_rolls.clear()
	_anchors.clear()
	var left_h  := handles[0]
	var right_h := handles[1]
	_reach_left  = _reach_speed(cb.left_lower_arm, left_h)
	_reach_right = _reach_speed(cb.right_lower_arm, right_h)

	_grab_left_handle_node  = left_h
	_grab_right_handle_node = right_h
	_grab_left_blend_t      = 1.0
	_grab_right_blend_t     = 1.0
	_grab_left_handle_local  = _on_body(left_h.global_position  if is_instance_valid(left_h)  else cb.left_upper_arm.global_position)
	_grab_right_handle_local = _on_body(right_h.global_position if is_instance_valid(right_h) else cb.right_upper_arm.global_position)
	_grab_left_prev_local    = _grab_left_handle_local
	_grab_right_prev_local   = _grab_right_handle_local

	_grab_left_blend_target  = 1.0 if is_instance_valid(left_h)  else 0.0
	_grab_right_blend_target = 1.0 if is_instance_valid(right_h) else 0.0

## LA MANO SE ELIGE AL AGARRAR Y NO CAMBIA HASTA SOLTAR: las que se eligieron en `start_grab` siguen mientras se agarre
## lo mismo y sus puntos sigan siendo de él. Se elegían de nuevo en cada cuadro —con un solo punto, la del hombro más
## cercano, sin margen—, y con el punto en el medio del pecho, o al girar el cuerpo, la mano se daba vuelta una y otra
## vez; con varios puntos, como el aro de una perilla, cada mano buscaba el más cercano, y como los puntos giran con la
## perilla, las manos saltaban de uno a otro. El punto viaja con el componente y la mano con él.
func _kept_handles(interactable: Interactable) -> Array[Node3D]:
	# UNA CAJA SE VUELVE A MIRAR CADA CUADRO (ver UNA CAJA, CON LAS DOS MANOS): el punto por donde se lleva se muda cuando
	# se suma o se va otro, y las manos lo siguen con el cambio de punto de siempre (HANDLE_SWITCH_SPEED).
	if interactable is GrabbableInteractable and (interactable as GrabbableInteractable).box_half != Vector3.ZERO:
		_handles_for = interactable
		return _box_handles(interactable as GrabbableInteractable)
	if interactable == _handles_for and _still_held(interactable):
		return [_regrip(interactable, true), _regrip(interactable, false)] as Array[Node3D]
	_handles_for = interactable
	_rolls.clear()
	return _assign_handles(interactable)

## ── VOLVER A AGARRAR (29/10/2026, ver GripStyle) ─────────────────────────────────────────────────────────────────
## Lo que gira con varios puntos —un volante, una válvula— se lleva las manos pegadas a sus puntos. Prendido para su
## familia (GripStyle.of, `regrip`), CADA MANO TIENE SU LUGAR en el aro y SE CUENTA EN PUNTOS DEL ARO (los puntos van
## parejos, en orden de su ángulo): cuando el punto que tiene ya está a `regrip_angle` de su lugar —redondeado a puntos
## enteros: en la válvula, de 8 puntos, 90° son dos—, toma otro y viaja ahí como cualquier cambio de punto
## (`HANDLE_SWITCH_SPEED`). Así cada cambio pasa después de girar justo esa cantidad de puntos. Cuál es su lugar y adónde
## vuelve, `regrip_from` (los tres paradigmas, ver GripStyle): su costado —el de su lado con dos manos, lo más cerca de
## su hombro con una—, el arco centrado en él, o donde agarró la primera vez.
## *Se contaba en grados, primero desde que la mano tomaba el punto —lo que tardaba en llegar, con la pieza girando, se
## comía el intervalo siguiente— y después desde su lugar —el punto más cercano a él caía hasta medio punto antes o
## después—: los intervalos no eran iguales (lo vio el usuario en la válvula, 30/10/2026).*
## Lado → dónde agarró la primera vez, desde el centro, en el marco del cuerpo (para «desde donde agarró»; ver LO QUE SE
## GUARDA DE UN CUADRO AL OTRO).
var _anchors := {}

## El punto que sigue teniendo la mano `left` (o la derecha): el mismo, u otro si quedó lejos de su lugar.
func _regrip(interactable: Interactable, left: bool) -> Node3D:
	var node: Node3D = _grab_left_handle_node if left else _grab_right_handle_node
	var points := interactable.handle_points
	var count := points.size()
	if node == null or not is_instance_valid(node) or count < 2:
		return node
	var side := "left" if left else "right"
	var centre := _points_center(interactable)
	var body := bi.char_rigidbody.global_basis.orthonormalized()
	if not _anchors.has(side):
		_anchors[side] = body.inverse() * (node.global_position - centre)
	var style := GripStyle.of(interactable)
	if style == null or not style.regrip:
		return node
	var other: Node3D = _grab_right_handle_node if left else _grab_left_handle_node
	# SU LUGAR, como el punto más cerca de él.
	var home: Node3D = null
	if style.regrip_from == 2:
		home = _nearest_to(interactable, body * (_anchors[side] as Vector3), other)
	elif interactable.hands() == 2:
		home = _side_handle(interactable, left, other)
	else:
		home = interactable.get_nearest_handle_point((bi.custom_bones_util.left_upper_arm if left
			else bi.custom_bones_util.right_upper_arm).global_position, other)
	if home == null:
		return node
	var steps := maxi(1, roundi(style.regrip_angle / (360.0 / float(count))))
	# Cuántos puntos lleva recorridos desde su lugar, con su signo (por el lado más corto del aro).
	var at := points.find(home)
	var gap := posmod(points.find(node) - at + count / 2, count) - count / 2
	if style.regrip_from == 1:
		# CENTRADO: barre de la mitad antes a la mitad después; pasada la mitad de adelante, a la de atrás.
		var ahead := ceili(steps / 2.0)
		if absi(gap) < ahead:
			return node
		var back: Node3D = points[posmod(at - signi(gap) * (steps - ahead), count)]
		return back if back != other else node
	return home if absi(gap) >= steps else node


## El punto de `interactable` cuya dirección desde el centro está más cerca de `direction`, sin `exclude`.
func _nearest_to(interactable: Interactable, direction: Vector3, exclude: Node3D) -> Node3D:
	var centre := _points_center(interactable)
	var best: Node3D = null
	var best_dot := -INF
	for h in interactable.handle_points:
		if h == exclude or not is_instance_valid(h):
			continue
		var d := (h.global_position - centre).normalized().dot(direction.normalized())
		if d > best_dot:
			best = h
			best_dot = d
	return best

func _still_held(interactable: Interactable) -> bool:
	var any := false
	for node in [_grab_left_handle_node, _grab_right_handle_node]:
		if node == null:
			continue
		if not is_instance_valid(node) or not interactable.handle_points.has(node):
			return false
		any = true
	return any

## CUÁNTO LLEGÓ LA MANO, de 0 a 1: el peso del brazo que más llegó a lo que agarra (ver ExhibitOperator).
func hand_on() -> float:
	return maxf(_grab_left_blend, _grab_right_blend) if _grab_interactable != null else 0.0


func stop_grab() -> void:
	_grab_interactable = null
	_handles_for = null
	_rolls.clear()
	_anchors.clear()
	_grab_left_blend_target  = 0.0
	_grab_right_blend_target = 0.0
	_grab_left_handle_node   = null
	_grab_right_handle_node  = null

# Estado del driver de agarre para proxies (detecta transiciones del grab sincronizado).
var _driven_grab_target: Node = null
var _driven_grab_point: Node3D = null

## EL AGARRE, POR UN SOLO CAMINO (03/11/2026, ver CharacterIntent.grab): a partir de lo que agarra (o null), venga del
## teclado, de la red o de un guion, detecta el start/stop/cambio de objeto y llama start_grab/update_grab_handles/
## stop_grab. El origen y los handles se derivan local (el objeto existe en esta máquina); el punto de agarre, el que
## eligió quien lo maneja (`point`, el jugador) o el más cercano al agarrar. Ver character-animation.md (bug 3).
## *Hasta el 03/11/2026 el jugador local manejaba sus brazos directo desde su InteractionController, por otro camino.*
func drive_grab(delta: float, target: Node, point: Node3D = null) -> void:
	if target == _driven_grab_target:
		if is_instance_valid(target):
			if is_instance_valid(point):
				_driven_grab_point = point
			update_grab_handles(delta, target as Interactable, bi.get_interaction_origin(), _driven_grab_point)
		return
	if is_instance_valid(target):
		var interactable := target as Interactable
		var origin := bi.get_interaction_origin()
		_driven_grab_point = point if is_instance_valid(point) else _nearest_interaction_point(interactable, origin)
		var max_reach: float = bi.skel_sizes_util.interaction_reach
		start_grab(interactable, origin, _driven_grab_point, max_reach * 0.1, max_reach * 0.9)
	else:
		_driven_grab_point = null
		stop_grab()
	_driven_grab_target = target

## Punto que el brazo alcanza: grab point si es agarrable, handle point si es un controllable.
func _nearest_interaction_point(interactable: Interactable, origin: Vector3) -> Node3D:
	if interactable is GrabbableInteractable:
		return (interactable as GrabbableInteractable).get_nearest_grab_point(origin)
	return interactable.get_nearest_handle_point(origin)

## El peso de un brazo, en línea recta hacia `target`: de ida en `reach` segundos, de vuelta en `RELEASE_TIME`. Lo
## que se usa es su smoothstep (ver `_apply_grab_arms`).
static func _blend_toward(current: float, target: float, delta: float, reach: float) -> float:
	var time := reach if target > current else RELEASE_TIME
	return move_toward(current, target, delta / maxf(time, 0.001))

## Cuánto tarda la ida de una mano: según su recorrido, desde la punta de su antebrazo hasta el punto (ver REACH_BASE).
var _reach_left := REACH_BASE
var _reach_right := REACH_BASE

static func _reach_speed(lower: CustomBone, point: Node3D) -> float:
	if not is_instance_valid(lower) or not is_instance_valid(point):
		return REACH_BASE
	var hand := lower.global_transform * Vector3(0.0, lower.length, 0.0)
	return REACH_BASE + REACH_PER_METRE * hand.distance_to(point.global_position)

func _apply_grab_arms(delta: float) -> void:
	# EL PESO DE CADA BRAZO va hacia su objetivo una vez por cuadro, acá: de ida según su recorrido, de vuelta con
	# RELEASE_TIME. (También se hacía en update_grab_handles, así que la ida iba al doble.)
	_grab_left_blend  = _blend_toward(_grab_left_blend,  _grab_left_blend_target,  delta, _reach_left)
	_grab_right_blend = _blend_toward(_grab_right_blend, _grab_right_blend_target, delta, _reach_right)

	_apply_grab_body_adjustments()
	var ik    := bi.ik_util
	var cb    := bi.custom_bones_util
	var grip: int = _grab_interactable.grip_kind() if is_instance_valid(_grab_interactable) else Interactable.Grip.NONE
	var left := smoothstep(0.0, 1.0, _grab_left_blend)
	var right := smoothstep(0.0, 1.0, _grab_right_blend)
	# LOS DEDOS: la pose de cómo se toma (ver ProceduralBodyUtil.pose_hand), con el peso del brazo.
	var body := bi.body_visual as ProceduralBodyUtil
	if is_instance_valid(body):
		body.pose_hand("left", grip, left)
		body.pose_hand("right", grip, right)
	_reach_arm(cb.left_upper_arm, cb.left_lower_arm, ik.left_arm_ik_target, ik.left_arm_pole,
		_in_world(_grab_left_handle_local), _grab_left_handle_node, "left", grip, left, _grab_left_blend)
	_reach_arm(cb.right_upper_arm, cb.right_lower_arm, ik.right_arm_ik_target, ik.right_arm_pole,
		_in_world(_grab_right_handle_local), _grab_right_handle_node, "right", grip, right, _grab_right_blend)

## ── EL BRAZO QUE AGARRA (29/10/2026, de cero) ──────────────────────────────────────────────────────────────────────
## LA MANO VA DERECHA, RÍGIDA AL ANTEBRAZO: no hay muñeca que se doble. Lo pidió el usuario al empezar de cero la
## animación de las manos: «me gustaría que el ángulo del antebrazo, muñeca y dedo sean el mismo… pensar todo eso como
## un conjunto». Así, lo que toca la cosa es un punto fijo de la mano —al apretar, los nudillos del puño o la punta del
## índice, las dos maneras que el usuario quiere probar (ver TubeHand.press_with); empuñando, el hueco del puño;
## el medio de la palma en lo demás (ver ProceduralBodyUtil.hand_point)—. La muñeca va a donde ese punto cae justo en
## `handle`: el punto, menos ese desvío girado como queda el antebrazo.
##
## EMPUÑANDO, LA MANO GIRA SOBRE EL ANTEBRAZO —sin dejar de estar alineada con él— hasta que la línea de sus nudillos
## sigue la dirección del punto (el aro del volante, ver Interactable.add_handle_point_local); ese giro se le pasa al
## cuerpo (ProceduralBodyUtil.set_wrist_roll) con el peso del brazo.
##
## ── EL ANTEBRAZO SE PREDICE EN EL MISMO CUADRO ────────────────────────────────────────────────────────────────────
## Cómo queda el antebrazo depende de adónde va la muñeca, y adónde va la muñeca, de cómo queda el antebrazo. Se resuelve
## acá, con LA MISMA CUENTA QUE LA IK (IkUtil.solve_two_bone_ik: los largos de `_arm_lengths`, el codo de `_elbow_dir`,
## la base de CustomBone.pose_from_rest_to), en `PASSES` pasadas: en la última la muñeca y el antebrazo ya coinciden,
## así que con el brazo llegado la punta cae justo en el punto en ese mismo cuadro. *Se usaba el antebrazo del cuadro
## anterior, que el cuerpo corre un poco en cada cuadro —respira, se balancea—: la mano perseguía un blanco que se le
## movía y nunca se asentaba (lo vio el usuario, 29/10/2026).* Sin cuerpo generado (el de cápsulas), la muñeca va
## al punto. `weight` es el peso suavizado del brazo; `raw`, el de verdad, para saber si ya llegó.
const PASSES := 3

func _reach_arm(upper: CustomBone, lower: CustomBone, ik_target: Node3D, pole: Node3D, handle: Vector3,
		node: Node3D, side: String, grip: int, weight: float, raw: float) -> void:
	var sizes := bi.skel_sizes_util
	var is_left := side == "left"
	var body := bi.body_visual as ProceduralBodyUtil
	var shoulder := upper.global_position
	var wrist := handle
	var lengths := _arm_lengths(shoulder.distance_to(wrist))
	var pole_world := shoulder
	var roll := 0.0
	var along := Vector3.ZERO
	if grip == Interactable.Grip.WRAP and is_instance_valid(node) and node.has_meta("axis"):
		var part := node.get_parent_node_3d()
		along = (part.global_basis if part != null else Basis()) * (node.get_meta("axis") as Vector3)
	# UN ARO (lo que gira, ver RotatingComponent): la palma, siempre hacia su centro.
	var rim := _grab_interactable is RotatingComponent
	var inward := _points_center(_grab_interactable) - handle if rim else Vector3.ZERO
	var arrived := raw >= ARRIVED
	for pass_ in PASSES:
		lengths = _arm_lengths(shoulder.distance_to(wrist))
		var reach := lengths.x * 1.5
		pole_world = shoulder + _elbow_dir((wrist - shoulder).normalized(), is_left, reach) * reach
		if not is_instance_valid(body):
			break
		var forearm := _predicted_forearm(upper, shoulder, wrist, pole_world, lengths)
		if along != Vector3.ZERO and rim:
			# EN UN ARO, DE LOS DOS GIROS, EL DE LA PALMA HACIA EL CENTRO: nunca la mano dada vuelta (ver `_rim_roll`).
			roll = _rim_roll(forearm, along, inward, body.hand_across(side), body.hand_palm(side))
		elif along != Vector3.ZERO:
			# EN UNA BARRA, mientras el brazo viaja, el que menos gira; recién llegado, se recuerda (ver `_roll_to`).
			roll = _roll_to(forearm.inverse() * along, body.hand_across(side),
				float(_rolls.get(side, 0.0)) if arrived and _rolls.has(side) else 0.0)
		wrist = handle - forearm * (Basis(Vector3.UP, roll) * body.hand_point(side, grip))
	if arrived and along != Vector3.ZERO:
		_rolls[side] = roll
	if is_instance_valid(body):
		body.set_wrist_roll(side, roll * weight)

	upper.set_length(lerpf(sizes.upper_arm_size.y, lengths.x, weight))
	lower.position = Vector3(0.0, upper.length, 0.0)
	lower.set_length(lerpf(sizes.lower_arm_size.y, lengths.y, weight))
	if weight <= 0.0:
		return
	ik_target.global_position = ik_target.global_position.lerp(wrist, weight)
	pole.global_position = pole.global_position.lerp(pole_world, weight)

## EL ANTEBRAZO COMO LO VA A DEJAR LA IK con la muñeca en `wrist`: la cuenta de IkUtil.solve_two_bone_ik —el codo en
## el plano del pole, los largos `lengths`— y la base de CustomBone.pose_from_rest_to, sin su escala.
static func _predicted_forearm(upper: CustomBone, shoulder: Vector3, wrist: Vector3, pole_world: Vector3,
		lengths: Vector2) -> Basis:
	var line := wrist - shoulder
	var span := clampf(line.length(), 0.001, lengths.x + lengths.y)
	var dir := line.normalized()
	var right := dir.cross((pole_world - shoulder).normalized())
	if right.length() < 1e-6:
		right = IkUtil.get_orthogonal(dir)
	var pole_on_plane := right.normalized().cross(dir).normalized()
	var cos_a := clampf((lengths.x * lengths.x + span * span - lengths.y * lengths.y) / (2.0 * lengths.x * span), -1.0,
		1.0)
	var elbow := shoulder + dir * (cos_a * lengths.x) + pole_on_plane * (sqrt(maxf(0.0, 1.0 - cos_a * cos_a)) * lengths.x)
	return upper.pose_from_rest_to((wrist - elbow).normalized(), pole_on_plane).orthonormalized()

## EL GIRO EN UN ARO (30/10/2026): de los dos que alinean los nudillos con el aro (`along`), el que deja la palma
## (`palm`, en el marco de la muñeca) mirando hacia su centro (`inward`, desde el punto). No depende de cómo estaba la
## mano, así que no puede quedar dada vuelta. *Con la continuidad de las barras, la mano que volvía a agarrar en otro
## punto del aro se quedaba a veces con la palma para afuera (lo vio el usuario en la válvula).*
static func _rim_roll(forearm: Basis, along: Vector3, inward: Vector3, across: Vector3, palm: Vector3) -> float:
	var roll := _roll_to(forearm.inverse() * along, across, 0.0)
	var facing := (forearm * (Basis(Vector3.UP, roll) * palm)).dot(inward)
	return roll if facing >= 0.0 else roll + PI


## EL GIRO SOBRE EL EJE DEL ANTEBRAZO (su Y) que lleva `across` a lo largo de `along` (los dos en el marco del
## antebrazo). Una barra no tiene sentido, así que hay dos giros que la alinean, separados por media vuelta: se toma EL
## MÁS CERCANO AL QUE LA MANO YA TENÍA (`previous`). *Era el que menos giraba, decidido en cada cuadro desde cero: con
## la barra cruzada al antebrazo los dos cuestan lo mismo y la mano daba media vuelta de golpe —y, como el hueco del
## puño no está sobre el eje, la muñeca saltaba unos centímetros y titilaba varios cuadros entre los dos (lo vio el dios
## del juego en el mando de helicóptero; medido: de +1,56 a −1,53 rad y vuelta, cinco veces seguidas)—.* Al agarrar,
## `previous` es 0: arranca por el que menos gira.
var _rolls := {}
## Desde qué peso del brazo se considera que la mano llegó (ver `_reach_arm`).
const ARRIVED := 0.9

static func _roll_to(along: Vector3, across: Vector3, previous := 0.0) -> float:
	var a := Vector2(across.x, across.z)
	var t := Vector2(along.x, along.z)
	# (La barra a lo largo del antebrazo no pide ningún giro: se queda el que tenía.)
	if a.length_squared() < 1e-8 or t.length_squared() < 1e-8:
		return previous
	# Girar sobre +Y lleva (x, z) a (x·cos + z·sen, −x·sen + z·cos): el ángulo de `a` a `t` en ese sentido.
	var angle := atan2(a.y, a.x) - atan2(t.y, t.x)
	# El de los dos (cada media vuelta) más cercano a `previous`.
	return angle + roundf((previous - angle) / PI) * PI

func _apply_grab_body_adjustments() -> void:
	var body_blend :float= max(_grab_left_blend, _grab_right_blend)
	if body_blend <= 0.0:
		return

	var cb    := bi.custom_bones_util
	var sizes := bi.skel_sizes_util

	var dist_l     := cb.left_upper_arm.global_position.distance_to(_in_world(_grab_left_handle_local))
	var dist_r     := cb.right_upper_arm.global_position.distance_to(_in_world(_grab_right_handle_local))
	var dist_range : float = max(_grab_dist_max - _grab_dist_min, 0.001)
	var t_l        : float = clamp((dist_l - _grab_dist_min) / dist_range, 0.0, 1.0) * _grab_left_blend
	var t_r        : float = clamp((dist_r - _grab_dist_min) / dist_range, 0.0, 1.0) * _grab_right_blend
	var t_avg      : float = (t_l + t_r) / max(_grab_left_blend + _grab_right_blend, 0.001)

	# LA ALTURA DE LA COSA, el centro de sus puntos, y no la del punto que agarra: el punto de un volante sube y baja con
	# el aro al girarlo, y el cuerpo entero cabeceaba con él —«como si moviera la cámara arriba y abajo rápido», lo vio
	# el usuario—.
	var lean_at := _points_center(_grab_interactable) if is_instance_valid(_grab_interactable) else _in_world(_grab_point_local)
	var grab_y_rel := lean_at.y - _in_world(_grab_chest_rest_local).y
	var y_norm     : float = clamp(grab_y_rel / max(sizes.torso_height, 0.001), -1.0, 1.0)

	# La inclinación de la raíz sigue la ALTURA del punto agarrado, no su distancia. Agacharse hacia
	# algo bajo inclina adelante; sostener algo alto endereza y echa atrás.
	#
	# Antes seguía la distancia, y eso ponía la POSTURA DEL CUERPO en la ruedita del mouse: el rango de
	# agarre (0.11–1.00 m) es casi exactamente el recorrido de la rueda, así que girarla de un extremo
	# al otro barría los 12.6° enteros de inclinación. Y como `lower_spine` es la raíz del árbol de
	# huesos, lo que se movía era el personaje entero — la cápsula no, de ahí que se leyera como un bug
	# del esqueleto y no de esta línea. Bajar las constantes solo lo hacía más lento, no lo desacoplaba.
	#
	# La altura sí es una razón para inclinarse y NO la toca la rueda: acercar o alejar un objeto no
	# cambia su altura. La rueda sigue moviendo el brazo (el estirón y el giro de hombro), que es lo
	# que se espera que mueva.
	var root_tilt   := lerpf(GRAB_ROOT_TILT_FORWARD, -GRAB_ROOT_TILT_BACK, (y_norm + 1.0) * 0.5)
	var spine       := cb.lower_spine
	var spine_basis := spine.transform.basis
	var parent_basis := (spine.get_parent() as Node3D).global_transform.basis
	var local_world_right := spine_basis.inverse() * parent_basis.inverse() * bi.char_rigidbody.global_transform.basis.x
	spine.transform.basis *= Basis(local_world_right, -root_tilt * body_blend)

	var shoulder_z := y_norm * (GRAB_SHOULDER_Z_UP if y_norm >= 0.0 else GRAB_SHOULDER_Z_DOWN)
	var shoulder_y_l := _grab_shoulder_y(t_l, _rise(cb.left_upper_arm, _in_world(_grab_left_handle_local)))
	var shoulder_y_r := _grab_shoulder_y(t_r, _rise(cb.right_upper_arm, _in_world(_grab_right_handle_local)))

	_apply_shoulder_rotation(cb.left_shoulder,  shoulder_y_l,  shoulder_z,  _grab_left_blend)
	_apply_shoulder_rotation(cb.right_shoulder, -shoulder_y_r, -shoulder_z, _grab_right_blend)

## EL HOMBRO SE ECHA ATRÁS con lo que se tiene cerca (`t` chico) delante del pecho, y adelante con lo que está lejos.
## Lo que se tiene cerca pero ARRIBA del hombro (`rise`, ver `_rise`) —el tubo en la oreja— no lo echa atrás: el codo
## va adelante, y con el hombro echado atrás 37° el brazo se doblaba detrás del cuerpo (lo vio el usuario).
func _grab_shoulder_y(t: float, rise := 0.0) -> float:
	if t < 0.5:
		return lerpf(GRAB_SHOULDER_Y_BACK, 0.0, t * 2.0) * (1.0 - rise)
	else:
		return lerpf(0.0, -GRAB_SHOULDER_Y_FORWARD, (t - 0.5) * 2.0)

## Cuánto sube la línea del hombro a `point`: 0 de horizontal para abajo, 1 desde los 30° para arriba.
static func _rise(upper: CustomBone, point: Vector3) -> float:
	var line := point - upper.global_position
	if line.length_squared() < 1e-6:
		return 0.0
	return smoothstep(0.0, 0.5, line.normalized().y)

func _apply_shoulder_rotation(shoulder: CustomBone, y_angle: float, z_angle: float, blend: float) -> void:
	var local_basis         := shoulder.transform.basis
	var parent_basis        := (shoulder.get_parent() as Node3D).global_transform.basis
	var local_world_up      := local_basis.inverse() * parent_basis.inverse() * Vector3.UP
	var local_world_forward := local_basis.inverse() * parent_basis.inverse() * (-bi.char_rigidbody.global_transform.basis.z)
	shoulder.transform.basis *= Basis(local_world_up,      y_angle * blend)
	shoulder.transform.basis *= Basis(local_world_forward, z_angle * blend)

## LOS LARGOS DEL BRAZO (arriba, abajo) con la mano a `dist` del hombro, del todo agarrando: se estira hasta un techo
## duro. Con la malla de Blender, más allá de eso se veía de goma: el shape key que corregía la silueta estaba autorado
## hasta ahí. `interaction_reach` sale de este mismo tope, así que agarrar algo dentro del cono nunca lo toca; lo que sí
## lo toca es seguir agarrado y ALEJARSE, que el cono no acota.
##
## PEGADO AL CUERPO, EL BRAZO SE DOBLA PAREJO: con la mano a menos de la mitad del brazo del hombro, el brazo y el
## antebrazo se van igualando (el total, el mismo). El antebrazo de estos cuerpos es 6–10 cm más largo que el brazo, y
## con la mano más cerca del hombro que esa diferencia la IK no puede abrir el codo hacia el pole: lo pliega al lado
## opuesto de la mano —con el tubo en la oreja, atrás y adentro del cuerpo, lo vio el usuario—. Parejos, el codo
## va siempre adonde cuelga (ver `_elbow_dir`).
func _arm_lengths(dist: float) -> Vector2:
	var sizes := bi.skel_sizes_util
	var nat_total := sizes.upper_arm_size.y + sizes.lower_arm_size.y
	var total := clampf(dist / GRAB_MIN_BEND_FACTOR, nat_total, nat_total * sizes.arm_stretch)
	var fold := clampf(1.0 - dist / (nat_total * 0.5), 0.0, 1.0)
	var ratio := lerpf(sizes.upper_arm_size.y / nat_total, 0.5, minf(fold * 2.0, 1.0))
	return Vector2(total * ratio, total * (1.0 - ratio))

## EL CODO CUELGA: hacia abajo, un poco afuera y un poco adelante, y de eso lo que queda de costado a la línea del hombro
## a la mano (`line`, normalizada). Agarrando delante del cuerpo queda abajo y afuera, como siempre; con la mano arriba
## del hombro —el tubo en la oreja— lo de abajo se va con la línea y queda adelante y afuera. *Era sólo «abajo, de
## costado a la línea» desde un hombro corrido afuera: con la mano cerca de la cabeza la línea quedaba casi vertical, el
## codo sin plano, y se iba para atrás y el brazo atravesaba el cuerpo (lo vio el usuario con el teléfono).*
func _elbow_dir(line: Vector3, is_left: bool, pole_reach: float) -> Vector3:
	var char_basis := bi.char_rigidbody.global_transform.basis
	var side_dir := char_basis.x * (-1.0 if is_left else 1.0)
	var hang := -char_basis.y + side_dir * (bi.skel_sizes_util.upper_arm_size.x * GRAB_POLE_SIDE_OFFSET / pole_reach) \
		- char_basis.z * ELBOW_FORWARD
	var out := hang - line * hang.dot(line)
	return out.normalized() if out.length_squared() > 1e-6 else -char_basis.z

func _apply_throw_arms(_delta: float) -> void:
	if not is_instance_valid(anim_mod):
		return
	var throw_t      := anim_mod.throw_t
	var throw_push_t := anim_mod.throw_push_t
	if throw_t <= 0.0 and throw_push_t <= 0.0:
		return  # sin throw: los brazos los maneja el IK base (targets de reposo)
	# EL PASE DE PECHO (ver LocomotionCommon, TIRAR): mientras tiene la caja, las manos siguen en ella; ya suelta, el brazo
	# termina estirado y vuelve (el empujón de abajo, con lo que le queda).
	if anim_mod.throw_with_box and bi.intent.grab is GrabbableInteractable:
		return

	var ik         := bi.ik_util
	var sizes      := bi.skel_sizes_util
	var cb         := bi.custom_bones_util
	var rb         := bi.char_rigidbody
	var cam        := bi.player_camera
	var arm_total  := sizes.upper_arm_size.y + sizes.lower_arm_size.y
	var char_basis := rb.global_transform.basis
	var char_right := char_basis.x
	var char_up    := char_basis.y
	var left_shoulder_pos  := cb.left_upper_arm.global_position
	var right_shoulder_pos := cb.right_upper_arm.global_position
	var pitch      := cam.rotation.x if is_instance_valid(cam) else 0.0
	var pitch_norm : float = clamp(pitch / 1.2, -1.0, 1.0)
	var throw_dir  := anim_mod.throw_world_dir

	# Targets de mano y codo en WORLD, recalculados fresco cada frame. Como usan char_right/char_up
	# (que rotan con el cuerpo) y throw_dir (que sigue a la cámara), siguen el yaw correctamente en
	# todo momento. Sin suavizado intermedio guardado (era lo que quedaba raro al girar); el único
	# blend es el lerp final por carga (blend_t).
	var left_hand: Vector3
	var right_hand: Vector3
	var left_pole: Vector3
	var right_pole: Vector3
	var blend_t: float

	if throw_push_t > 0.0:
		var hand_sep  := sizes.shoulders_width * 0.35 * lerpf(1.0, 0.4, abs(pitch_norm))
		var left_dir  := (throw_dir - char_right * (hand_sep / arm_total)).normalized()
		var right_dir := (throw_dir + char_right * (hand_sep / arm_total)).normalized()
		# Tras tirar una caja, el brazo termina a su largo, sin estirarse (ver LocomotionCommon, TIRAR).
		var push_reach := 1.0 if anim_mod.throw_with_box else 1.5
		left_hand  = left_shoulder_pos  + left_dir  * arm_total * push_reach
		right_hand = right_shoulder_pos + right_dir * arm_total * push_reach
		var elbow_drop := -char_up * arm_total * 0.4
		left_pole  = left_hand  + elbow_drop - throw_dir * arm_total * 0.3
		right_pole = right_hand + elbow_drop - throw_dir * arm_total * 0.3
		blend_t = throw_push_t
	else:
		var vertical_shift := pitch * sizes.torso_height * 0.4
		var side_ext       := arm_total * 0.5 * lerpf(1.0, 0.4, abs(pitch_norm))
		var forward_pull   := throw_dir * arm_total * lerpf(0.0, 0.15, throw_t)
		left_hand  = left_shoulder_pos  - char_right * side_ext + forward_pull + char_up * vertical_shift
		right_hand = right_shoulder_pos + char_right * side_ext + forward_pull + char_up * vertical_shift
		var pole_spread : float = arm_total * (0.6 + abs(pitch_norm) * 0.4)
		var elbow_back  := -throw_dir * arm_total * 0.4
		var elbow_down  := -char_up * arm_total * (0.25 + pitch_norm * 0.2)
		left_pole  = left_shoulder_pos  + elbow_back + elbow_down - char_right * pole_spread + char_up * vertical_shift
		right_pole = right_shoulder_pos + elbow_back + elbow_down + char_right * pole_spread + char_up * vertical_shift
		blend_t = throw_t

	ik.left_arm_ik_target.global_position  = ik.left_arm_ik_target.global_position.lerp(left_hand,  blend_t)
	ik.right_arm_ik_target.global_position = ik.right_arm_ik_target.global_position.lerp(right_hand, blend_t)
	ik.left_arm_pole.global_position       = ik.left_arm_pole.global_position.lerp(left_pole,       blend_t)
	ik.right_arm_pole.global_position      = ik.right_arm_pole.global_position.lerp(right_pole,      blend_t)

func _assign_handles(interactable: Interactable) -> Array[Node3D]:
	var cb := bi.custom_bones_util
	# CON UNA MANO (ver Interactable.hands): la del lado donde está —el hombro más cercano a la cosa— y, si tiene varios
	# puntos, el más cercano a ese hombro. SENTADO, EL LADO ES EL DE LA SILLA (02/11/2026, el usuario: en la nave el
	# acelerador y la lenta están a la derecha del piloto y los agarraba con la izquierda): mirar algo gira el cuerpo entero
	# hacia ello, y con los dos hombros a la misma distancia ganaba siempre la izquierda. La silla no gira: de qué lado de
	# ella está la cosa no cambia con la mirada.
	if interactable.hands() == 1 and not interactable.handle_points.is_empty():
		var center := interactable.grip_center()
		var left := cb.left_upper_arm.global_position.distance_to(center) \
			<= cb.right_upper_arm.global_position.distance_to(center)
		if bi.is_seated and bi.current_seat is Node3D:
			var seat := bi.current_seat as Node3D
			left = (center - seat.global_position).dot(seat.global_basis.x) <= 0.0
		var shoulder := (cb.left_upper_arm if left else cb.right_upper_arm).global_position
		var one: Array[Node3D] = [null, null]
		one[0 if left else 1] = interactable.get_nearest_handle_point(shoulder)
		return one
	# CON DOS: CADA MANO, EL PUNTO MÁS HACIA SU LADO de la pieza —el volante de los costados, el yugo de sus cuernos, el
	# libro de sus bordes—. Antes cada una tomaba el más cercano a su hombro, y sentado frente a un volante inclinado esos
	# eran los de abajo (lo vio el usuario).
	if interactable is GrabbableInteractable and (interactable as GrabbableInteractable).box_half != Vector3.ZERO:
		return _box_handles(interactable as GrabbableInteractable)
	var left_h := _side_handle(interactable, true, null)
	var right_h := _side_handle(interactable, false, left_h)
	return [left_h, right_h]


## ── UNA CAJA, CON LAS DOS MANOS DESDE SUS COSTADOS (03/11/2026, lo pidió el usuario) ───────────────────────
## «Con las dos manos, desde sus dos costados», y con los puntos de la caja (el centro de la cara de cada módulo, ver
## GrabbableInteractable, LOS PAQUETES SON MÓDULOS), no con puntos a mano: cada mano, en la cara de la caja que da a su
## lado, el punto más cerca de su hombro. Si esas dos caras quedan más lejos que lo que abren los brazos
## (`BOX_HAND_SPAN`: la alargada tomada de lo largo), las dos van PEGADAS A LA CARA DE ENFRENTE, la que da a su pecho,
## cada una al punto más cerca de su hombro —una por módulo—, como ventosas (04/11/2026, el usuario: «un approach
## un poco más estilizado… que se le peguen las manos»). *Del 03/11 iban a la cara de abajo: los brazos atravesaban la
## caja.*
const BOX_HAND_SPAN := 0.9

func _box_handles(box: GrabbableInteractable) -> Array[Node3D]:
	var cb := bi.custom_bones_util
	var side := bi.char_rigidbody.global_basis.x.normalized()
	var left_at := cb.left_upper_arm.global_position
	var right_at := cb.right_upper_arm.global_position
	var left := _on_face(box, _face_toward(box, -side), left_at, null, _grab_left_handle_node)
	var right := _on_face(box, _face_toward(box, side), right_at, left, _grab_right_handle_node)
	if left != null and right != null and left.global_position.distance_to(right.global_position) > BOX_HAND_SPAN:
		var front := _face_toward(box, bi.char_rigidbody.global_position - box.global_position)
		left = _on_face(box, front, left_at, null, _grab_left_handle_node)
		right = _on_face(box, front, right_at, left, _grab_right_handle_node)
	return [left, right]


## La cara de la caja (local, un eje con signo) que más mira hacia `world_dir`.
static func _face_toward(box: GrabbableInteractable, world_dir: Vector3) -> Vector3:
	var basis := box.global_basis.orthonormalized()
	var best := Vector3.UP
	var best_dot := -INF
	for axis: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.UP, Vector3.DOWN, Vector3.BACK, Vector3.FORWARD]:
		var d := (basis * axis).dot(world_dir)
		if d > best_dot:
			best_dot = d
			best = axis
	return best


## El punto de las manos de la cara `face` de la caja más cerca de `near`, sin `exclude`. EL QUE YA TIENE (`current`) SE
## QUEDA mientras siga en esa cara y no haya otro `HAND_KEEP` más cerca: con la larga de tres, los puntos de dos módulos
## quedaban casi a la misma distancia del hombro, y al caminar la mano saltaba de uno al otro todo el tiempo.
const HAND_KEEP := 0.15

static func _on_face(box: GrabbableInteractable, face: Vector3, near: Vector3, exclude: Node3D,
		current: Node3D = null) -> Node3D:
	var best: Node3D = null
	var best_d := INF
	var current_d := INF
	for h in box.handle_points:
		if h == exclude or not is_instance_valid(h):
			continue
		if GrabbableInteractable.face_of(h.position, box.box_half) != face:
			continue
		var d := h.global_position.distance_to(near)
		if h == current:
			current_d = d
		if d < best_d:
			best_d = d
			best = h
	if current_d < INF and current_d <= best_d + HAND_KEEP:
		return current
	return best

## El punto de `interactable` más hacia el lado de la mano izquierda (o derecha), sin `exclude`.
func _side_handle(interactable: Interactable, is_left: bool, exclude: Node3D) -> Node3D:
	var side := bi.char_rigidbody.global_transform.basis.x * (-1.0 if is_left else 1.0)
	var center := _points_center(interactable)
	var best: Node3D = null
	var best_out := -INF
	for h in interactable.handle_points:
		if h == exclude or not is_instance_valid(h):
			continue
		var out := (h.global_position - center).dot(side)
		if out > best_out:
			best = h
			best_out = out
	return best

## El centro de los puntos de una cosa: el del aro de un volante, el medio entre los cuernos de un yugo.
static func _points_center(interactable: Interactable) -> Vector3:
	var sum := Vector3.ZERO
	var count := 0
	for h in interactable.handle_points:
		if is_instance_valid(h):
			sum += h.global_position
			count += 1
	return sum / float(count) if count > 0 else interactable.global_position
