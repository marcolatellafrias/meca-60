class_name CharacterPelvis
extends RefCounted

## LA PELVIS Y LAS PIERNAS PARADO: cuánto baja para que las piernas lleguen, la hundida al pisar, y el piso que se
## mueve. Una pieza de BoneInstantiator (ver su comentario): se partió el 13/11/2026; el estado público sigue en el
## personaje (`bi`).

var bi: BoneInstantiator = null

## ── AJUSTE DE PELVIS ──────────────────────────────────────────────────────────────────────────────
## La pelvis baja SOLO lo que haga falta para que las piernas lleguen a sus pies. Es el patrón estándar
## de foot IK (pelvis adjustment): se mide la distancia cadera↔pie de cada pierna y, si supera lo que
## la pierna estira, se baja la raíz por el peor déficit de las dos.
##
## Es geométrico, no predictivo: no adivina por velocidad, mide. Por eso funciona igual en escaleras,
## pendientes, agachado o cuando te empujan — casos donde una fórmula por velocidad se equivoca.
##
## Y reemplaza a la derivación vieja `stride → altura de pelvis → alcance del pie`, que iba al revés:
## ahora `stride` significa literalmente el largo del paso, y la pelvis es una consecuencia.
##
## ── LA PELVIS, EN DOS CAPAS (07/11/2026, el usuario eligió, entre varias a prueba, «curva: se hunde al pisar» con
## el suavizado de cadera al 50 %; «dejar el código limpio») ─────────────────────────────────────────────────────────
## 1. LA NECESIDAD, SUAVE Y ATADA AL PASO: lo que la pierna apoyada pide para llegar a su pie (ver `_leg_drop`), seguido
##    sin saltos. Tarda `PELVIS_STEP_SHARE` de lo que dura el paso de un pie (ver IkUtil.step_time): corriendo, los pasos
##    duran menos y la cadera reacciona más rápido, así que llega a bajar. Nunca tarda más de `PELVIS_DROP_MAX_S`
##    —caminando, ya es eso— y parado, `PELVIS_DROP_STILL_S`. *Hasta entonces bajaba de golpe en el cuadro y subía
##    suave: la pelvis se caía de repente. Un suavizado fijo en segundos, en cambio, la dejaba plana corriendo.*
## 2. LA HUNDIDA AL PISAR, encima: una forma fija sobre el paso, NO suavizada (ver `_sink`). Cuánto, por arquetipo: su
##    `root_bounciness` (1 es la de referencia) por el `bounce_down` del estilo.
## *A prueba hubo un selector con otras: sin rebote, el rebote de antes (la necesidad multiplicada por
## `root_bounciness`), otra curva y cuatro resortes; se fueron.*
const PELVIS_STEP_SHARE := 0.5
const PELVIS_DROP_STILL_S := 0.1
const PELVIS_DROP_MAX_S := 0.25
## LOS PIES VAN CON EL PISO QUE SE MUEVE (ver CharacterRigidBody3D.floor_velocity): parado en la meca en vuelo, los
## puntos donde el paso dejó los pies viajan con ella (ver IKUtil.ground_velocity), lo que pasó desde el último solve
## (`step`: la pose se resuelve una vez por cuadro, y los de lejos menos). Sólo mientras pisa algo que se mueve, y a cero una vez al bajarse: la cinta
## del sandbox escribe lo mismo para caminar en el lugar, y no hay que pisarla.
var on_moving_floor := false
## LA HUNDIDA AL PISAR (ver LA PELVIS, EN DOS CAPAS). Cada vez que un pie pisa arranca un reloj, `s`, que cuenta qué parte del paso pasó (0 al pisar, 1 un paso después).
## Con él la pelvis dibuja una loma para abajo (`_bump`, un coseno al cuadrado), honda `SINK_DEPTH` largos de pierna:
##   · EL GOLPE: en el cuadro en que el pie toca, ya está a la MITAD de lo hondo, de una vez. Es a propósito —se lee
##     como el impacto del pie— y sale de dónde está la loma: el fondo a `SINK_BOTTOM` del paso y medio ancho
##     `SINK_HALF_WIDTH`, así que al pisar está a 0,15 / 0,3 = medio medio ancho del fondo, y cos²(45°) = 0,5.
##     ⚠ Mover el fondo o el ancho cambia el golpe: con el fondo en 0 no hay golpe, y la hundida arranca en lo hondo.
##   · EL FONDO, a `SINK_BOTTOM` del paso.
##   · VUELVE a cero a `SINK_BOTTOM + SINK_HALF_WIDTH` (0,45) y el resto del paso no suma nada.
## Parado no hay hundida.
const SINK_DEPTH := 0.04
const SINK_BOTTOM := 0.15
const SINK_HALF_WIDTH := 0.3
var since_land := 0.0
var was_swinging := [false, false]


func _init(owner: BoneInstantiator) -> void:
	bi = owner


## Piernas paradas: la marcha (target aéreo + raycast al piso + IK). Ver el modelo de gait en
## character-parametric:docs/technical/character-animation.md.
func pose_legs_standing() -> void:
	var tuck := LocomotionCommon.base().leg_tuck(bi)
	bi.ik_util.update_airborne_target(true, tuck)
	bi.ik_util.update_airborne_target(false, tuck)

	bi.ik_util.update_ik_raycast(true,  bi.custom_bones_util, bi.skel_sizes_util, bi.animation_inputs)
	bi.ik_util.update_ik_raycast(false, bi.custom_bones_util, bi.skel_sizes_util, bi.animation_inputs)

	if bi._reset_feet_after_recovery:
		# Ya corrió el raycast (next_target fresco bajo el cuerpo): plantamos ahí el pie, sin catch-up.
		bi.ik_util.reset_step_targets_to_ground()
		bi._reset_feet_after_recovery = false


func ride_floor(step: float) -> void:
	if not is_instance_valid(bi.ik_util) or not is_instance_valid(bi.char_rigidbody):
		return
	var floor_velocity := bi.char_rigidbody.floor_velocity
	if floor_velocity != Vector3.ZERO:
		bi.ik_util.ground_velocity = floor_velocity
		bi.ik_util.ground_step = step
		on_moving_floor = true
	elif on_moving_floor:
		bi.ik_util.ground_velocity = Vector3.ZERO
		bi.ik_util.ground_step = 0.0
		on_moving_floor = false


## Mide el déficit de alcance de las dos piernas y deja el resultado suavizado en anim_mod. Corre
## DESPUÉS de colocar los pies (necesita sus targets) y ANTES de la capa procedural (que es la que
## aplica el offset de raíz).
func update_pelvis_drop(delta: float) -> void:
	if not is_instance_valid(bi.anim_mod):
		return
	if bi.is_seated or (is_instance_valid(bi.ragdoll_util) and (bi.ragdoll_util.is_active or bi.ragdoll_util.is_recovering)):
		bi._pelvis_drop_smooth = 0.0
		bi.anim_mod.pelvis_drop = 0.0
		return

	var max_len: float = bi.skel_sizes_util.leg_height * SkeletonSizesUtil.MAX_EXTENSION
	# NUNCA MÁS QUE UNA PIERNA: un pie que quedó lejos —un piso que se fue de abajo— hacía bajar la pelvis, la cadera
	# bajada quedaba más lejos todavía, y en cada cuadro bajaba más, sin fin (02/11/2026, lo vio la nave a bordo).
	# DESDE LA CADERA SIN BAJAR, Y EN VERTICAL (05/11/2026, el usuario: «se supone que yo la zancada la puedo
	# aumentar y que la pelvis se va a bajar para machear la caminata»): la cadera de este momento todavía tiene puesta la
	# bajada del cuadro anterior, así que se le devuelve (`pelvis_drop`) antes de medir; y lo que se pide es cuánto bajar
	# la cadera derecho para abajo para que el pie, a la distancia horizontal que está, quede al alcance (ver
	# `_leg_drop`). *Hasta entonces se medía desde la cadera ya bajada y se pedía lo que faltaba en distancia: la cuenta
	# se equilibraba a mitad de camino —medido corriendo, al final del apoyo la pelvis bajaba 14 cm y a la pierna le
	# seguían faltando 15—, y la pierna de atrás quedaba corta, derecha, con el pie despegado antes de tiempo.*
	# Y SÓLO POR LOS PIES APOYADOS: el que vuela no tiene que llegar a ningún lado. *Medido el 05/11/2026: la pelvis más
	# baja del nene corriendo la pedía un pie recién despegado, todavía al 96 % de la pierna atrás.*
	var applied: float = bi.anim_mod.pelvis_drop
	var deficit: float = minf(maxf(
		0.0 if bi.ik_util.leg_is_swinging(true) else
			leg_drop(bi.custom_bones_util.left_higher_leg, bi.ik_util.left_leg_current_target, max_len, applied),
		0.0 if bi.ik_util.leg_is_swinging(false) else
			leg_drop(bi.custom_bones_util.right_higher_leg, bi.ik_util.right_leg_current_target, max_len, applied)),
		bi.skel_sizes_util.leg_height)
	# LA QUE SUBE AL DESPEGAR (ver WalkStyle.bounce_up, la usan modificadores como los saltarines): con un pie en el aire
	# la pelvis se empuja hacia arriba, lo que deje la pierna que apoya sin estirarse de más —si no, el pie apoyado se
	# despegaría del piso—.
	if bi.walk_style.bounce_up > 0.0 and deficit <= 0.0:
		var lift := maxf(bi.ik_util.swing_lift(true, bi.skel_sizes_util), bi.ik_util.swing_lift(false, bi.skel_sizes_util))
		var room := minf(leg_room(bi.custom_bones_util.left_higher_leg, bi.ik_util.left_leg_current_target, max_len,
				not bi.ik_util.leg_is_swinging(true)),
			leg_room(bi.custom_bones_util.right_higher_leg, bi.ik_util.right_leg_current_target, max_len,
				not bi.ik_util.leg_is_swinging(false)))
		deficit = -minf(bi.walk_style.bounce_up * bi.skel_sizes_util.leg_height * lift, room)

	# CAPA 1, LA NECESIDAD SUAVE Y ATADA AL PASO (ver arriba). Con `1 − e^(−dt/τ)`: igual con cualquier paso de tiempo.
	var tau := PELVIS_DROP_STILL_S
	if bi.ik_util.step_time() < INF:
		tau = minf(PELVIS_STEP_SHARE * bi.ik_util.step_time(), PELVIS_DROP_MAX_S)
	bi._pelvis_drop_smooth = lerpf(bi._pelvis_drop_smooth, deficit, 1.0 - exp(-delta / maxf(tau, 0.001)))
	# CAPA 2, LA HUNDIDA AL PISAR, encima.
	bi.anim_mod.pelvis_drop = bi._pelvis_drop_smooth + sink(delta)


## LO QUE SE HUNDE este cuadro (m, positivo es abajo).
func sink(delta: float) -> float:
	var landed := false
	for i in 2:
		var swinging := bi.ik_util.leg_is_swinging(i == 0)
		if bool(was_swinging[i]) and not swinging:
			landed = true
		was_swinging[i] = swinging
	since_land = 0.0 if landed else since_land + delta
	var step := bi.ik_util.step_time()
	if step == INF:
		return 0.0
	var depth := SINK_DEPTH * bi.skel_sizes_util.leg_height * bi.entity_instantiation.root_bounciness * bi.walk_style.bounce_down
	return depth * bump(since_land / step, SINK_BOTTOM, SINK_HALF_WIDTH)


## Una loma de 0 a 1 y de vuelta, centrada en `at`, de medio ancho `width`.
static func bump(s: float, at: float, width: float) -> float:
	var u := clampf((s - at) / maxf(width, 0.001), -1.0, 1.0)
	return pow(cos(u * PI * 0.5), 2.0)


## Cuánto le falta a esta pierna para llegar a su pie, o 0 si llega.
## Cuánto más puede subir la cadera sin que la pierna que apoya en `foot` se estire de más (las que no apoyan no
## cuentan: el infinito).
func leg_room(hip: CustomBone, foot: Node3D, max_len: float, planted: bool) -> float:
	if not planted or not is_instance_valid(hip) or not is_instance_valid(foot):
		return INF
	return maxf(max_len - hip.global_position.distance_to(foot.global_position), 0.0)


## CUÁNTO BAJAR LA CADERA, DERECHO PARA ABAJO, PARA QUE ESTA PIERNA LLEGUE A `target`: medido desde la cadera sin la
## bajada que ya tiene (`applied`, ver `_update_pelvis_drop`). Con el pie a `x` de la cadera en el plano, la pierna llega
## a `max_len` si la cadera queda a `√(max_len² − x²)` sobre él. Si el pie está más lejos que la pierna en el plano, no
## hay bajada que lo alcance: no se baja nada (un teleport, un pie que quedó en otro lado; el paso lo trae).
func leg_drop(hip: CustomBone, target: Node3D, max_len: float, applied: float) -> float:
	if not (is_instance_valid(hip) and is_instance_valid(target)):
		return 0.0
	var from := hip.global_position + Vector3.UP * applied
	var to := target.global_position
	var x := Vector2(from.x - to.x, from.z - to.z).length()
	if x >= max_len:
		return 0.0
	return maxf(from.y - to.y - sqrt(max_len * max_len - x * x), 0.0)


## Re-resuelve la IK de las piernas contra los MISMOS targets de piso, después de que los offsets de
## raíz movieron la pelvis. Sin esto los pies se despegan del suelo exactamente lo que bajó la
## pelvis. Mismo patrón que _repin_legs_seated. Ver character-parametric:docs/technical/character-animation.md.
func repin_legs_standing() -> void:
	bi.ik_util.solve_two_bone_ik(bi.custom_bones_util.left_higher_leg, bi.custom_bones_util.left_lower_leg,
		bi.ik_util.left_leg_current_target.global_position, bi.ik_util.left_leg_pole.global_position)
	bi.ik_util.solve_two_bone_ik(bi.custom_bones_util.right_higher_leg, bi.custom_bones_util.right_lower_leg,
		bi.ik_util.right_leg_current_target.global_position, bi.ik_util.right_leg_pole.global_position)
