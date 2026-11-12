class_name BoneInstantiator
extends Node3D

## Emitida cuando el jugador activo (re)crea su cámara en initialize_skeleton, para
## que quien la consuma (CharacterSpawner → AreaInstantiator) la reenganche.
signal active_camera_changed(camera: Camera3D)
## Un personaje que no se simula se cayó (ver EL RAGDOLL DE QUIEN NO SE SIMULA): quien lo armó lo rearma.
signal exhibit_fallen

## QUÉ CLASE DE PERSONAJE ES (ver CharacterKind: el jugador, un compañero de red, uno de exhibición, una figura, el ente).
## Se pone ANTES de agregarlo al árbol; sin poner, uno de la calle (`npc`). Reemplaza a `is_active`, `is_puppet`, `is_display` y
## `looks_around` (03/11/2026).
var kind: CharacterKind = CharacterKind.npc()
## LO QUE QUIERE HACER (ver CharacterIntent): lo escribe quien lo maneja —el teclado, la red, el guion— y el cuerpo lo
## hace igual para todos. Reemplaza a `held_target`, `seated_turn` y `head_pitch`.
var intent := CharacterIntent.new()
@export var master_seed: int = 0
## When true (and this character is the active player), unlocks creative mode + the debug panel.
@export var debug_enabled: bool = false
## CUÁNTO MÁS GRANDE SE CONSTRUYE ESTE PERSONAJE (ver SkeletonSizesUtil.size_scale). 1 = tal cual lo pide
## su arquetipo. Se escribe ANTES de `initialize_skeleton`: cambia los tamaños de los que sale todo el
## resto, no una escala de nodo encima. Hoy lo usa la lupa del design sandbox.
@export var size_scale: float = 1.0
## QUÉ FORMA DE CABEZA USA ESTE PERSONAJE (ver HeadForms), o -1 para la de su arquetipo (ver
## CharacterLooks.head_form_for). Se escribe ANTES de `initialize_skeleton`, igual que la escala. Lo usan las capturas
## y los maniquíes del design sandbox (ver HeadArchetype); en el juego queda en -1.
@export var head_slot: int = -1
## EL COLOR DE LA PIEL; transparente es el crema de siempre (ver CharacterBodyVisual.BODY_COLOR).
@export var skin := Color(0, 0, 0, 0)
var entity_instantiation: EntityInstantiation

var player_camera: Camera3D
var entity_archetype: EntityArchetype
var skel_sizes_util: SkeletonSizesUtil
var custom_bones_util: CustomBonesUtil
var char_rigidbody: CharacterRigidBody3D
var ik_util: IkUtil
## LO QUE SE VE del personaje. El rig lógico de CustomBone no dibuja nada: lo dibuja esto, las partes generadas
## (`ProceduralBodyUtil`), el único cuerpo desde el 18/10/2026. Si no hubiera cuerpo (null), lo visible vuelven a ser
## los cuerpos del ragdoll.
## Ver technical/characters.md.
var body_visual: CharacterBodyVisual
var locomotion_signals: LocomotionSignals
var procedural_animator: ProceduralBoneAnimator
var ragdoll_util: RagdollUtil

## Entrada de animación: la llena _update_animation_inputs() cada frame; los módulos de animación
## la leen en vez de char_rigidbody (refactor de desacople, ver technical/character-animation.md).
var animation_inputs: AnimationInputs

var anim_mod: AnimationModifiers
var bone_animations: BoneAnimations
## Capa pasiva: respiración y temblor. Ver passive_animations.gd.
var passive_animations: PassiveAnimations
var passive_state: PassiveState
var arms_controller: ArmsController

var player_controller: PlayerController
## Solo en proxies remotos: lo setea el CharacterSpawner. Se llama al inicio del frame para aplicar
## el transform sincronizado ANTES del solve del esqueleto.
var net_sync: CharacterNetSync
## ── QUIEN PONE ESTA CÁPSULA DESDE AFUERA (05/11/2026) ─────────────────────────────────────────────────────────────
## La red a un compañero (CharacterNetSync), su camino a un peatón (Pedestrian): un objeto con `apply_to_puppet()`, que
## el cuerpo llama al EMPEZAR SU PASO DE FÍSICA, antes del rayo al piso y de la pose. UNA SOLA REGLA PARA TODOS: la
## cápsula que no se simula se pone ahí y en ningún otro lado. *Hasta entonces sólo la red tenía ese lugar, y el salón de
## personas ponía a los suyos entre pasos de física: el servidor les devolvía su lugar viejo, el rayo no encontraba el
## piso y la mitad caminaba sin dar pasos (lo vio el dios del juego).*
var puppeteer: Object = null

@onready var global_targets:   Node3D = $"global_targets"
@onready var local_targets:    Node3D = $"local_targets"
@onready var skel_rigidbodies: Node3D = $"skel_rigidbodies"
@onready var joints:           Node3D = $"joints"

var jump_squat_t: float = 0.0
var crouch_t:     float = 0.0
## CUÁNTO ESTÁ EN EL AIRE, de 0 a 1: va hacia 1 al despegar y hacia 0 al aterrizar, al ritmo de su arquetipo. Lo leen
## los brazos (ver BoneAnimations, LOS BRAZOS EN EL AIRE).
var air_t: float = 0.0
## El giro del torso en el aire, ahora (rad; ver LocomotionCommon, el torso).
var air_lean: float = 0.0
## CUÁNTO SE ECHA ATRÁS CON LO QUE LLEVA (ver LocomotionCommon, EL CUERPO SE ECHA ATRÁS), en radianes, en los ejes de la
## cápsula: x de costado, y adelante (−) y atrás (+). Lo lee la columna (ver BoneAnimations, LO QUE SE LLEVA).
var carry_lean := Vector2.ZERO
## Cuánto de lo que se echa atrás va ahora (0 a 1): mueve la cadera hacia el paquete (ver LocomotionCommon.carry_lean_hips).
var carry_lean_share := 0.0
var _reset_feet_after_recovery: bool = false  # plantar los pies el primer frame tras recuperarse

## Esconde el personaje ENTERO (el cuerpo visible, sea cual sea; ver `set_shown`). Gana sobre la
## primera persona: un cambio de cámara no lo vuelve a mostrar a medias.
var character_hidden: bool = false

var is_seated:    bool = false
var current_seat: Node = null
## Targets de las piernas sentadas, cacheados por _pose_legs_seated para que _repin_legs_seated
## re-resuelva contra los MISMOS. Ver _solve_frame.
var _seated_left_foot:  Vector3 = Vector3.ZERO
var _seated_right_foot: Vector3 = Vector3.ZERO
var _seated_left_pole:  Vector3 = Vector3.ZERO
var _seated_right_pole: Vector3 = Vector3.ZERO

func _ready() -> void:
	if kind.is_local():
		player_controller = PlayerController.new()
		add_child(player_controller)
	initialize_skeleton()

## CONSTRUYE (O RECONSTRUYE) EL PERSONAJE ENTERO desde la seed: tamaños, rig, cápsula, cuerpo visible,
## animación y ragdoll.
##
## ⚠ Y SI YA ESTABA PARADO EN ALGUNA PARTE, VUELVE AHÍ. Eso no es una comodidad: reconstruir CREA una
## cápsula nueva, que nace en el origen del nodo, y los targets de los pies son puntos del MUNDO que
## quedaron donde estaba el cuerpo viejo. El ajuste de pelvis mide cadera↔pie, lee ese déficit y baja la
## raíz para alcanzarlos: el torso termina en el piso con las piernas atravesándolo. Ver `place_at`.
##
## Estaba en cada llamador y en ninguno igual — la parcela del sandbox llamaba a `place_at`, el respawn
## se guardaba la posición a mano, y el toggle de cuerpo del panel no hacía nada y dejaba a todos los
## personajes de la escena hundidos. Es una sola cosa y sabe hacerla el que reconstruye.
##
## ⚠ Y SI ESTABA SENTADO, SE LEVANTA PRIMERO Y SE VUELVE A SENTAR AL FINAL. Reconstruir DESTRUYE la
## cápsula, y de la cápsula cuelga todo lo que el asiento le había puesto al ocupante: el collider
## apagado, el bloqueo en Y y la copia prestada de la silla. La cápsula nueva nace sin nada de eso y el
## asiento se queda creyendo que lo tiene sentado, apuntando a nodos que ya no existen.
##
## Medido moviéndole el largo de la pierna a un maniquí sentado: un error por cuadro —`_fit_visual` con
## la malla prestada ya borrada, que ni siquiera es un error que `is_instance_valid` pueda atajar porque
## salta al pasar el argumento— y la cápsula nueva con los tres flags del sentado en falso.
##
## No es un caso especial que cada perilla tenga que recordar: es la misma idea que la posición de más
## arriba. Lo sabe hacer el que reconstruye, que es el único que sabe que la cápsula se va a morir.
##
## La primera vez no hay nada que recordar: ahí lo ubica quien lo spawnea.
func initialize_skeleton() -> void:
	_initialize_skeleton()


func _initialize_skeleton() -> void:
	var seat: SeatInteractable = null
	if is_seated and is_instance_valid(current_seat):
		seat = current_seat as SeatInteractable
	if is_instance_valid(seat):
		seat.release_occupant_in_place()

	var was_placed := is_instance_valid(char_rigidbody) and skel_sizes_util != null
	var ground := Vector3.ZERO
	var facing := 0.0
	if was_placed:
		# El piso que tenía, despejado de la altura que la cápsula VIEJA se paraba sobre él.
		ground = char_rigidbody.global_position - Vector3.UP * (skel_sizes_util.leg_height
			- skel_sizes_util.distance_from_ground)
		facing = char_rigidbody.rotation.y

	_clear_prior_generations()

	entity_instantiation = EntityInstantiation.create(master_seed)
	# LOS MODIFICADORES (ver WalkModifier): lo del arquetipo —la pose, la respiración, el temblor— al nacer; la caminata,
	# en vivo y propia, si tiene alguno.
	_modifiers = walk_modifiers.duplicate()
	for modifier in _modifiers:
		modifier.apply(entity_instantiation.arch_final)
		modifier.apply(entity_instantiation)
	entity_archetype     = entity_instantiation.arch_final
	# EL ESTILO DE CAMINAR, DE CADA UNO (ver WalkStyle.for_archetype): lo de su arquetipo y encima sus modificadores.
	walk_style = WalkStyle.for_archetype(entity_archetype, _modifiers)
	skel_sizes_util      = SkeletonSizesUtil.create(entity_instantiation, size_scale, head_slot)
	skel_sizes_util.skin = skin
	custom_bones_util    = CustomBonesUtil.create(skel_sizes_util, entity_instantiation)
	ik_util              = IkUtil.create(skel_sizes_util, self)

	var full_height := skel_sizes_util.leg_height + skel_sizes_util.torso_height + skel_sizes_util.head_height
	var charRb      := Vector3(skel_sizes_util.shoulders_width * 2, full_height, skel_sizes_util.hips_width * 2)
	# La cápsula de quien no se simula nace congelada, y la de quien no se toca, fuera de toda capa (ver
	# CharacterRigidBody3D._freeze_for_driver).
	char_rigidbody  = CharacterRigidBody3D.create(charRb, skel_sizes_util.distance_from_ground,
		skel_sizes_util.leg_height, kind, intent, entity_instantiation)
	char_rigidbody.fall_triggered.connect(_on_fall_triggered)
	# Y LOS MODIFICADORES DEL EQUILIBRIO (ver WalkModifier, el ebrio; CharacterRigidBody3D, EL EBRIO).
	for modifier in _modifiers:
		modifier.apply(char_rigidbody)
	char_rigidbody.add_child(custom_bones_util.lower_spine)
	add_child(char_rigidbody)


	if kind.is_touchable():
		_setup_char_grabbable()

	local_targets.add_child(ik_util.left_leg_raycast)
	local_targets.add_child(ik_util.right_leg_raycast)
	ik_util.left_leg_raycast.add_exception(char_rigidbody)
	ik_util.right_leg_raycast.add_exception(char_rigidbody)
	local_targets.add_child(ik_util.left_leg_next_target)
	local_targets.add_child(ik_util.right_leg_next_target)
	local_targets.add_child(ik_util.left_leg_airborne_target)
	local_targets.add_child(ik_util.right_leg_airborne_target)
	global_targets.add_child(ik_util.left_leg_current_target)
	global_targets.add_child(ik_util.right_leg_current_target)

	local_targets.add_child(ik_util.left_arm_ik_target)
	local_targets.add_child(ik_util.right_arm_ik_target)
	local_targets.add_child(ik_util.left_arm_pole)
	local_targets.add_child(ik_util.right_arm_pole)

	# Creamos anim_mod y arms_controller antes del player para que setup los reciba
	anim_mod = AnimationModifiers.new()
	add_child(anim_mod)
	anim_mod.bi = self

	arms_controller = ArmsController.new()
	add_child(arms_controller)
	arms_controller.bi = self
	arms_controller.setup(anim_mod)

	if kind.is_local() and is_instance_valid(player_controller):
		player_camera = Camera3D.new()
		player_camera.current = true
		char_rigidbody.add_child(player_camera)
		player_controller.on_skeleton_built(self, player_camera)
		active_camera_changed.emit(player_camera)

	animation_inputs = AnimationInputs.new()
	_update_animation_inputs()
	locomotion_signals = LocomotionSignals.create(ik_util, animation_inputs, skel_sizes_util)

	ik_util.left_arm_ik_target.position  = skel_sizes_util.left_arm_tip_rest_local
	ik_util.right_arm_ik_target.position = skel_sizes_util.right_arm_tip_rest_local
	ik_util.left_arm_pole.position       = skel_sizes_util.left_arm_pole_rest_local
	ik_util.right_arm_pole.position      = skel_sizes_util.right_arm_pole_rest_local

	# EL REPOSO DE LOS BRAZOS SE RESUELVE DESDE LA CÁPSULA, no desde los nodos de target.
	#
	# ⚠ `local_targets` SOBREVIVE A LA RECONSTRUCCIÓN —es hijo de este nodo, no de la generación— así
	# que al reconstruir todavía tiene el transform que le dejó el último frame del personaje anterior,
	# y el `global_position` de un target recién escrito sale de ahí. O sea: el reposo del brazo dependía
	# de dónde estaba parado el personaje cuando lo reconstruiste. Los datos de reposo son LOCALES a la
	# cápsula (ver SkeletonSizesUtil._compute_arm_tip_local), así que se los lleva al mundo con ella y
	# no hay nada con historia en el medio.
	var to_world := char_rigidbody.global_transform
	ik_util.solve_two_bone_ik(custom_bones_util.left_upper_arm, custom_bones_util.left_lower_arm,
		to_world * skel_sizes_util.left_arm_tip_rest_local,
		to_world * skel_sizes_util.left_arm_pole_rest_local)
	ik_util.solve_two_bone_ik(custom_bones_util.right_upper_arm, custom_bones_util.right_lower_arm,
		to_world * skel_sizes_util.right_arm_tip_rest_local,
		to_world * skel_sizes_util.right_arm_pole_rest_local)

	# Y RECÉN AHORA EL RIG TIENE SU REPOSO: construido en la pose del modelo (brazos en T) y traído a la
	# pose en la que este personaje se para. Congelarlo es lo que hace que hornear una malla no dependa
	# de cuándo se hornea (ver CustomBonesUtil.freeze_rest).
	custom_bones_util.freeze_rest()

	# El cuerpo visible va DESPUÉS del reposo, y para el cuerpo generado eso no es orden: es requisito.
	# Hornea su geometría leyendo el reposo del rig, así que necesita que ya esté congelado. Las
	# cápsulas salen de los tamaños del arquetipo, así que a ellas les da igual.
	body_visual = ProceduralBodyUtil.create(custom_bones_util, skel_sizes_util,
		entity_instantiation.arch_final if entity_instantiation != null else null, char_rigidbody)

	procedural_animator = ProceduralBoneAnimator.create(locomotion_signals)

	bone_animations = BoneAnimations.new()
	add_child(bone_animations)
	bone_animations.bi = self
	# EL ESTILO DE CAMINAR (ver WalkStyle), antes de registrar: el tren superior y las piernas lo leen en vivo.
	ik_util.style = walk_style
	bone_animations.register_all()

	# La capa pasiva va DESPUÉS de la de marcha: registra sobre el mismo animador, y el orden de
	# registro no importa porque todo se suma sobre el reset por frame. Se separa por responsabilidad.
	passive_state = PassiveState.create(master_seed)
	passive_animations = PassiveAnimations.new()
	add_child(passive_animations)
	passive_animations.bi = self
	passive_animations.register_all()

	# ⚠ QUIEN NO SE SIMULA NO LLEVA RAGDOLL DE ENTRADA. Son 19 cuerpos rígidos, uno por hueso, y en una
	# figura no hacen absolutamente nada: nunca se ragdollea —no tiene física propia, está fuera de toda capa
	# de colisión y nadie lo empuja— y ni siquiera se ven, porque lo que se dibuja es `body_visual`, que
	# existe siempre, y con él `show_bodies` queda en false. Uno de exhibición que se puede caer lo arma
	# recién al caerse (ver EL RAGDOLL DE QUIEN NO SE SIMULA); el compañero de red, sí de entrada.
	#
	# Medido en el design sandbox: 44 personajes × 19 = 836 cuerpos rígidos de los 1743 que tenía la
	# escena. Casi la mitad de la física del mundo, toda de adorno.
	#
	# No es un caso especial que haya que recordar: TODO lo que usa `ragdoll_util` ya pregunta por
	# `is_instance_valid` antes de tocarlo, así que no tenerlo es un estado que el personaje ya soportaba.
	if kind.has_ragdoll() and (kind.simulates() or kind.driver == CharacterKind.Driver.NETWORK):
		_make_ragdoll()

	# LOS GIZMOS DE MARCHA, APAGADOS (ver IkUtil.gizmos_visible): sus mallas nacen visibles, y los apagaba la vista de
	# debug del personaje, borrada el 13/11/2026.
	ik_util.set_gizmos_visible(false)

	# Primera persona: se aplica ACÁ, al final. PlayerController.rebind (que corre en
	# on_skeleton_built, bastante más arriba) es quien venía seteando esto, pero el cuerpo visible se
	# crea DESPUÉS de esa llamada — así que en el build y en cada respawn el estado nunca llegaba a sus
	# mallas y la cara se veía hasta que cambiabas de cámara y volvías con numpad 5.
	if kind.is_local() and is_instance_valid(player_controller):
		set_first_person_visibility(player_controller.is_first_person_view())
	refresh_shown()

	jump_squat_t = 0.0
	crouch_t     = 0.0

	# De vuelta donde estaba, con el cuerpo nuevo: la misma `place_at` que usa quien lo spawnea, así que
	# los pies se replantan y el ajuste de pelvis arranca en cero.
	if was_placed:
		place_at(ground, facing)

	# Y DE VUELTA A SU SILLA, si estaba sentado: se la vuelve a poner en la intención y se sienta (ver
	# `_follow_seat`). Salvo al jugador: reconstruirle el esqueleto es un respawn o un toggle del panel, y de los
	# dos se sale parado —volver a sentarlo habría que pedírselo al host, y eso es asincrónico—.
	if is_instance_valid(seat) and not kind.is_local():
		intent.seat = seat
		_follow_seat()

## LLEVA EL PERSONAJE ENTERO a pararse sobre `ground_pos` mirando a `yaw`. Es la forma correcta de
## moverlo de golpe, y no alcanza con escribirle la posición a la cápsula: los targets de los pies son
## puntos del MUNDO, así que quedarían donde estaba el cuerpo antes. El ajuste de pelvis mide
## cadera↔pie, lee ese déficit y baja la raíz metros para alcanzarlos — el esqueleto termina colgando
## por debajo de la cápsula, tanto más abajo cuanto más lejos se lo movió.
##
## `ground_pos` es un punto del PISO: la cápsula se acomoda sola a la altura de este esqueleto.
##
## `yaw` es el giro de la cápsula EN EL MARCO DE SU PADRE —no del mundo: si algo de arriba está girado, se suma— y EL
## PERSONAJE MIRA A −Z DE SU CÁPSULA (como la cámara de Godot). Las dos cosas juntas son fáciles de errar: para que mire
## a una dirección del mundo está `place_facing`, que se ocupa de las dos. Y el giro QUEDA porque un maniquí tiene la
## cápsula estática (ver `initialize_skeleton`); en un proxy lo reescribe la red en cada cuadro. Un local al paso puso al
## que atiende de espaldas a la vereda tres veces: por el eje, por el marco y porque la cápsula kinemática lo perdía.
func place_at(ground_pos: Vector3, yaw: float = 0.0) -> void:
	if not is_instance_valid(char_rigidbody):
		return
	char_rigidbody.global_position = ground_pos + Vector3.UP * (skel_sizes_util.leg_height
		- skel_sizes_util.distance_from_ground)
	char_rigidbody.rotation.y = yaw
	char_rigidbody.linear_velocity = Vector3.ZERO
	char_rigidbody._prev_velocity = Vector3.ZERO  # que frenarlo de golpe no se lea como un golpe (ni como una caída)
	char_rigidbody.puppet_velocity = Vector3.ZERO
	# Y LA MIRADA, para allá: el cuerpo la sigue (ver `_apply_look`), así que si no se la escribe, lo da vuelta.
	if kind.driver != CharacterKind.Driver.NETWORK and char_rigidbody.is_inside_tree():
		char_rigidbody.set_frame(MotionFrame.around(char_rigidbody.global_position, char_rigidbody.frame))
	intent.look_yaw = CharacterIntent.yaw_of(char_rigidbody.frame, -char_rigidbody.global_basis.z)
	_update_animation_inputs()
	_update_local_targets_positions()
	ik_util.plant_feet_under_body(local_targets, ground_pos.y, skel_sizes_util.ankle_height)
	_pelvis_drop_smooth = 0.0
	if is_instance_valid(anim_mod):
		anim_mod.pelvis_drop = 0.0

## LO PARA SOBRE `ground_pos` MIRANDO A `direction`, una dirección DEL MUNDO (solo cuenta lo horizontal). Es la forma
## de orientarlo sin pensar en ejes ni marcos (ver `place_at`).
func place_facing(ground_pos: Vector3, direction: Vector3) -> void:
	var frame := char_rigidbody.get_parent() as Node3D if is_instance_valid(char_rigidbody) else null
	var local := frame.global_basis.inverse() * direction if frame != null else direction
	place_at(ground_pos, yaw_facing(local))


## EL GIRO PARA MIRAR A `direction`, en el mismo marco que el giro (el del padre de la cápsula). El personaje mira a −Z
## de su cápsula, y girar `yaw` en Y lleva −Z a (−sen yaw, 0, −cos yaw).
static func yaw_facing(direction: Vector3) -> float:
	return atan2(-direction.x, -direction.z)


## EL RAGDOLL EN EL AIRE (ver AirStyle): cayendo más rápido que lo pedido, se tira en el aire con la velocidad que traía
## y un giro chico al azar, por la entrada de todos (RagdollUtil.knock_down). Sólo quien se simula acá.
func _maybe_ragdoll_in_air() -> void:
	if not kind.simulates() or is_seated or not is_instance_valid(ragdoll_util) or ragdoll_util.is_active 			or ragdoll_util.is_recovering or not AirStyle.should_ragdoll(self):
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = master_seed + Engine.get_physics_frames()
	var axis := Vector3(rng.randf_range(-1.0, 1.0), 0.0, rng.randf_range(-1.0, 1.0))
	var spin := axis.normalized() * AirStyle.RAGDOLL_SPIN if axis.length_squared() > 0.0001 else Vector3.ZERO
	char_rigidbody.is_snapshot_active = false
	ragdoll_util.knock_down(char_rigidbody, custom_bones_util.lower_spine, Vector3.ZERO, spin)


func _on_fall_triggered(world_dir: Vector3) -> void:
	if is_seated:
		return
	if not kind.simulates() and not _ensure_late_ragdoll():
		return
	# No re-disparar si ya estoy ragdolleando NI levantándome: un impacto espurio durante la
	# recuperación (p.ej. la cápsula asentándose) reiniciaría el ragdoll a mitad de camino y dejaría
	# los huesos desarmados. Ver technical/characters.md.
	if not is_instance_valid(ragdoll_util) or ragdoll_util.is_active or ragdoll_util.is_recovering:
		return
	char_rigidbody.is_snapshot_active = false
	ragdoll_util.activate_with_impact(char_rigidbody, custom_bones_util.lower_spine, world_dir)
	if not kind.simulates():
		# LOS HUESOS ARRANCAN CON LA VELOCIDAD DEL MARCO en su punto, y el golpe encima: la cápsula de quien no se simula
		# está congelada y no tiene velocidad que pasarles, así que arrancaban quietos en el mundo y la nave se les iba
		# —salían volando para atrás, lo vio la nave—.
		var frame := char_rigidbody.frame
		if is_instance_valid(frame):
			for body: RigidBody3D in ragdoll_util._bodies.values():
				if is_instance_valid(body):
					body.linear_velocity += frame.velocity_at(body.global_position)
		exhibit_fallen.emit()


## LOS 19 CUERPOS DEL RAGDOLL, uno por hueso. VAN EN EL MUNDO, no colgados del personaje: si el personaje cuelga de algo
## que se mueve a mano —la nave de las maquetas—, un cuerpo rígido que cuelga de eso se teletransporta con él en cada
## paso; iba con la nave dos veces —por su velocidad y por el arrastre— y, como un teletransporte no choca, atravesaba el
## piso y las paredes (02/11/2026). Lo lleva el marco (ver RagdollUtil.follow_frame); con la detección continua, rápidos
## y finos no cruzan el piso.
func _make_ragdoll() -> void:
	ragdoll_util = RagdollUtil.create(custom_bones_util, skel_rigidbodies, joints)
	ragdoll_util.ik_util = ik_util  # para que el IK de recuperación use el mismo pole que la locomoción
	# Los cuerpos del ragdoll dejan de ser lo visible: quedan invisibles y el cuerpo los sigue vía
	# _sync_body_visual. Solo se muestran si no hay cuerpo que dibujar.
	ragdoll_util.show_bodies = not is_instance_valid(body_visual)
	skel_rigidbodies.top_level = true
	joints.top_level = true
	# EL QUE NO SE TOCA (ver CharacterKind.is_touchable), en una capa que nadie mira —ni lo agarran ni lo empujan— y
	# mirando sólo el piso de la cabina y las cajas (ver MotionFrame.EXHIBIT_RAGDOLL_LAYER).
	if not kind.is_touchable():
		ragdoll_util.layer = MotionFrame.EXHIBIT_RAGDOLL_LAYER
		ragdoll_util.mask = MotionFrame.EXHIBIT_RAGDOLL_MASK
	for body: RigidBody3D in ragdoll_util._bodies.values():
		if is_instance_valid(body):
			body.collision_layer = ragdoll_util.layer
			body.collision_mask = ragdoll_util.mask | SandboxParcel.bound_mask(self)
			body.continuous_cd = true


## ── EL RAGDOLL DE QUIEN NO SE SIMULA (02/11/2026) ──────────────────────────────────────────────────────────────────
## Uno de exhibición no nace con ragdoll (ver initialize_skeleton): se le arma recién cuando se cae, y sólo si su clase
## se cae (`can_fall`) —sentado no se cae nunca, como con cinturón—. No se levanta: a los segundos, quien lo armó lo
## rearma en su puesto (ver `exhibit_fallen`, DisplayCharacter.stand). Lo pidió el dios del juego.
func _ensure_late_ragdoll() -> bool:
	if not kind.can_fall or not is_instance_valid(char_rigidbody):
		return false
	if not is_instance_valid(ragdoll_util):
		_make_ragdoll()
	return true


## Tirado, el ragdoll va en el marco de la cápsula, que va con la pelvis (ver RagdollUtil.follow_frame).
func _follow_ragdoll_frame() -> void:
	if is_instance_valid(ragdoll_util) and ragdoll_util.is_active and is_instance_valid(char_rigidbody):
		ragdoll_util.follow_frame(char_rigidbody.frame)

func _clear_prior_generations() -> void:
	if is_instance_valid(ragdoll_util):
		if ragdoll_util.is_active and is_instance_valid(char_rigidbody):
			char_rigidbody.freeze = false
			char_rigidbody.collider.disabled = false
		ragdoll_util.cleanup()
	ragdoll_util = null

	for child in global_targets.get_children():   child.queue_free()
	for child in local_targets.get_children():    child.queue_free()
	for child in skel_rigidbodies.get_children(): child.queue_free()
	for child in joints.get_children():           child.queue_free()

	if is_instance_valid(char_rigidbody):
		char_rigidbody.queue_free()  # se lleva puesto el body_visual, que cuelga de él
	body_visual = null

	if is_instance_valid(anim_mod):
		anim_mod.queue_free()
		anim_mod = null
	if is_instance_valid(arms_controller):
		arms_controller.queue_free()
		arms_controller = null
	if is_instance_valid(bone_animations):
		bone_animations.queue_free()
		bone_animations = null
	if is_instance_valid(passive_animations):
		passive_animations.queue_free()
		passive_animations = null
	passive_state = null

	player_camera = null

# ── CUÁNDO SE RESUELVE LA POSE ────────────────────────────────────────────────────────────────────
# UNA VEZ POR CUADRO DIBUJADO, en `_process`, y no en cada paso de física: la física corre a 240 Hz y la
# pantalla muestra una pose por cuadro, así que las otras se tiraban (medido: el solve era todo lo que
# costaba un personaje, ~0,35 ms cada uno, y el jugador local hacía cuatro por cuadro a 60 fps). En
# `_process` la física del cuadro ya corrió, así que la pose que se dibuja es la de la cápsula de ahora —la
# misma que daba el último paso— y el delta que se le pasa es todo el tiempo de física desde el último
# solve: los suavizados y la fase de marcha son función de delta (ver technical/character-animation.md).
#
# Lo que TOCA LA FÍSICA sigue en cada paso, en `_physics_process`: la red del proxy, el ragdoll y la
# recuperación enteros, la cápsula sentada clavada al asiento y los cuerpos del ragdoll siguiendo a los
# huesos. Y quien le apaga la física a un personaje (StationSeat congela a su tripulación así) le apaga
# también la pose, como antes.
#
# COMO MUCHO, cada `_solve_every_ticks()` pasos: el jugador local, en cada cuadro; un no jugador, nunca más
# seguido que a 120 Hz (el medio ritmo de antes, que a más de 120 fps sigue ahorrando); y los de lejos, a 30 y
# a 15 Hz.

## LOS DE LEJOS SE MUEVEN A MENOS TASA (decidido por el dios del juego, «15–30 Hz»). El criterio es cuánto
## atrasa en pantalla: a 1080p, con el campo de 75° de la cámara, un metro a `d` metros mide ~700/`d`
## píxeles, y un pie o una mano que se balancean caminando van a ~2,5 m/s. A 30 Hz la pose atrasa como mucho
## un cuadro de 60 (4 cm): a 20 m es 1,4 px. A 15 Hz, tres cuadros (12 cm): a 45 m es 1,9 px. Por debajo de
## dos píxeles el salto no se distingue del borde de la silueta. A menos fps la diferencia se achica sola:
## a 30 fps la franja de 30 Hz ya es cada cuadro.
const POSE_NEAR_M := 20.0
const POSE_FAR_M := 45.0
const POSE_MID_HZ := 30.0
const POSE_FAR_HZ := 15.0
## Cuánto hay que pasarse de un umbral para cambiar de franja, de ida y de vuelta: alguien parado justo en
## el borde no cambia de tasa cada cuadro.
const POSE_BAND_HYSTERESIS_M := 2.0
## Un no jugador cerca: como mucho a esta tasa (el medio ritmo de siempre, uno de cada dos pasos cuando la física
## corría a 240 Hz). En Hz y no en pasos, para que no dependa de la tasa de la física: contado en pasos, a 60 Hz
## habría bajado a 30 (ver optimización, bajar-la-fisica).
const NPC_NEAR_HZ := 120.0

## El tiempo de física desde el último solve (lo que se le pasa como delta).
var _pose_delta := 0.0
## La franja de distancia de este personaje (0 cerca, 1 media, 2 lejos), con su histéresis.
var _pose_band := 0
## El turno del último solve, y el corrimiento de este personaje para que los de una misma franja no
## resuelvan todos en el mismo cuadro.
var _pose_slot := -1
var _pose_phase := -1
## Un proxy mueve los cuerpos de su ragdoll en un paso de cada dos (ver `_physics_process`).
var _ragdoll_sync_skip := false


func _physics_process(delta: float) -> void:
	# QUIEN LA PONE DESDE AFUERA, la pone ahora (ver `puppeteer`): en cada paso, para que la cápsula se mueva suave
	# aunque la pose se resuelva por cuadro. Ver character-animation.md.
	if is_instance_valid(puppeteer):
		puppeteer.call("apply_to_puppet")
	_update_ragdoll_ext_state()
	_follow_ragdoll_frame()
	_follow_seat()
	_apply_look()
	_update_jump(delta)
	_update_crouch()
	_maybe_ragdoll_in_air()

	# RAGDOLL Y RECUPERACIÓN, EN CADA PASO, COMO SIEMPRE: ahí la cápsula sigue a los cuerpos y el blend de
	# recuperación cuenta tiempo; a menos tasa tardaría más y _update_active se atrasaría. El solve pesado ya
	# se saltea solo al ragdollear, así que esto no cuesta.
	if _is_ragdolling():
		_pose_delta = 0.0
		_solve_pose(delta)
		return

	# Sentado, la cápsula va clavada en XZ al asiento en cada paso, no sólo al resolver: la nave se mueve en
	# cada paso, y de la cápsula cuelgan la cámara y el rayo de interacción.
	if is_seated and is_instance_valid(current_seat):
		_pin_capsule_to_seat()
	# Los cuerpos del ragdoll son cinemáticos y empujan lo que tocan (también lo que se tiene agarrado):
	# siguen a los huesos —que cuelgan de la cápsula— a la tasa de antes y no sólo cuando se resuelve la
	# pose: el jugador local en cada paso, un proxy en uno de cada dos (medido: 19 cuerpos cinemáticos por
	# paso son lo que más cuesta de un proxy después del solve).
	_ragdoll_sync_skip = not kind.is_local() and not _ragdoll_sync_skip
	if not _ragdoll_sync_skip:
		_sync_ragdoll_bodies()
	_pose_delta += delta


## ── LA POSE VIVA CON LA FÍSICA CONGELADA (04/11/2026, el dios del juego: «para pausar cuando están cayendo o subiendo y
## ver los cambios directamente») ───────────────────────────────────────────────────────────────────────────────────
## `set_pose_frozen(true)` congela su cápsula —quieta donde está, sin proceso de física, y su guion apagado— pero sigue
## posándolo cada cuadro con lo que traía en ese instante (la velocidad, si sube o cae, cuánto lleva en el aire): lo que
## se toque en los sliders del aire (LocomotionCommon) se ve ya. Lo usa la pausa de los experimentos de locomoción; los demás no
## se enteran. Al soltarlo sigue con la velocidad que tenía.
var pose_frozen := false
## LA VELOCIDAD VERTICAL QUE LEE EL AIRE (m/s; ver LocomotionCommon): la de la cápsula, sin suavizar —en el aire ya es pareja,
## y lo que entra y sale al despegar y aterrizar lo suaviza `air_t`—; congelado, la que traía. *Hasta el 05/11/2026 el
## aire leía una suavizada (LocomotionSignals), que se quedaba atrás: despegando a 2,9 m/s marcaba 1,8; y un rato se
## guardó también la del despegue, para medir la subida.*
var air_vy := 0.0
## La velocidad vertical con la que se separó del piso (m/s): la más alta desde que despegó; 0 en el piso. Con ella la
## subida de las piernas se mide sola (ver LocomotionCommon.leg_tuck).
var takeoff_vy := 0.0
const FROZEN_STEP := 1.0 / 60.0
var _frozen_solve := false
var _frozen_state: Array = []


func set_pose_frozen(on: bool) -> void:
	if on == pose_frozen or not is_instance_valid(char_rigidbody):
		return
	pose_frozen = on
	var rb := char_rigidbody
	if on:
		_frozen_state = [rb.freeze, rb.linear_velocity, rb.angular_velocity]
		rb.freeze = true
		rb.process_mode = Node.PROCESS_MODE_DISABLED
	else:
		rb.process_mode = Node.PROCESS_MODE_INHERIT
		if _frozen_state.size() == 3:
			rb.freeze = _frozen_state[0]
			rb.linear_velocity = _frozen_state[1]
			rb.angular_velocity = _frozen_state[2]
			rb._prev_velocity = rb.linear_velocity  # seguir no es un golpe
		_frozen_state = []
	set_physics_process(not on)


func _process(_delta: float) -> void:
	if pose_frozen:
		if not _is_ragdolling():
			_frozen_solve = true
			_solve_pose(FROZEN_STEP)
			_frozen_solve = false
		return
	if _pose_delta <= 0.0:
		return
	if not is_physics_processing():
		_pose_delta = 0.0  # le apagaron la física: la pose queda donde está, como antes
		return
	if _is_ragdolling():
		return  # empezó entre el último paso y ahora: lo toma el paso que viene
	var every := _solve_every_ticks()
	if _pose_phase < 0:
		_pose_phase = posmod(get_instance_id(), Engine.physics_ticks_per_second)
	var slot := (Engine.get_physics_frames() + _pose_phase) / every
	if slot == _pose_slot:
		return
	_pose_slot = slot
	var step := _pose_delta
	_pose_delta = 0.0
	_solve_pose(step)


func _is_ragdolling() -> bool:
	return is_instance_valid(ragdoll_util) and (ragdoll_util.is_active or ragdoll_util.is_recovering)


## CADA CUÁNTOS PASOS DE FÍSICA, COMO MUCHO, se resuelve la pose (ver «Cuándo se resuelve la pose»). La
## distancia es a la cámara que dibuja, la de esta máquina: es una decisión de cómo se ve, no viaja por la
## red. Sin cámara (los tests headless), cerca.
func _solve_every_ticks() -> int:
	if kind.is_local():
		return 1
	var camera := get_viewport().get_camera_3d()
	if camera == null or not is_instance_valid(char_rigidbody):
		_pose_band = 0
	else:
		var d := camera.global_position.distance_to(char_rigidbody.global_position)
		var band := 0
		if d > POSE_NEAR_M + (POSE_BAND_HYSTERESIS_M if _pose_band < 1 else -POSE_BAND_HYSTERESIS_M):
			band = 1
		if d > POSE_FAR_M + (POSE_BAND_HYSTERESIS_M if _pose_band < 2 else -POSE_BAND_HYSTERESIS_M):
			band = 2
		_pose_band = band
	match _pose_band:
		1:
			return maxi(_ticks_at(NPC_NEAR_HZ), _ticks_at(POSE_MID_HZ))
		2:
			return maxi(_ticks_at(NPC_NEAR_HZ), _ticks_at(POSE_FAR_HZ))
	return _ticks_at(NPC_NEAR_HZ)


## Cuántos pasos de física son un turno a `hz`, como mínimo uno.
static func _ticks_at(hz: float) -> int:
	return maxi(1, roundi(Engine.physics_ticks_per_second / hz))


## EL SOLVE DE LA POSE, con `solve_delta` = el tiempo de física que cubre. También va a
## `animation_inputs.delta`: hasta el 11/10/2026 los no jugadores le pasaban un solo paso aunque resolvieran
## uno de cada dos, y la nivelación del pie, el sondeo del modelo de disparo y la cinta del sandbox corrían
## en ellos a media velocidad.
func _solve_pose(solve_delta: float) -> void:
	# CONGELADO (ver LA POSE VIVA CON LA FÍSICA CONGELADA): lo que trae del cuadro anterior se queda —lo que lee de la
	# cápsula, cuánto lleva en el aire, las señales de la marcha—, y lo del aire sigue a los sliders ya.
	if not _frozen_solve:
		_update_animation_inputs(solve_delta)  # productor: llena animation_inputs desde la cápsula
		_update_carry_lean(solve_delta)
	var aloft := 0.0 if animation_inputs.grounded or is_seated else 1.0
	var air := LocomotionCommon.base()
	if not _frozen_solve:
		air_t = move_toward(air_t, aloft, solve_delta / maxf(air.blend_s, 0.01))
		# LA VELOCIDAD VERTICAL DEL AIRE (ver `air_vy`).
		air_vy = char_rigidbody.get_motion_velocity().y
		takeoff_vy = 0.0 if aloft <= 0.0 else maxf(takeoff_vy, air_vy)
	# EL TORSO EN EL AIRE, hacia lo que pide su regla a su ritmo (ver LocomotionCommon); congelado, ya.
	air_lean = air.torso_target(self) if _frozen_solve \
		else lerpf(air_lean, air.torso_target(self), 1.0 - exp(-solve_delta / maxf(air.torso_follow_s, 0.01)))
	_ride_floor(solve_delta)
	_update_local_targets_positions()   # consumidor: lee animation_inputs (ya no la cápsula)

	if is_instance_valid(ragdoll_util):
		ragdoll_util.update(solve_delta)
		if ragdoll_util.is_active:
			ik_util.update_ik_raycast(true,  custom_bones_util, skel_sizes_util, animation_inputs)
			ik_util.update_ik_raycast(false, custom_bones_util, skel_sizes_util, animation_inputs)
			# El solve entero se saltea acá, así que el cuerpo visible se sincroniza a mano: si no,
			# se congela en el pose del último frame parado mientras el cuerpo cae.
			_sync_body_visual()
			return
		if ragdoll_util.is_recovering and not ik_util.recovery_targets_locked:
			ik_util.recovery_targets_locked = true
		elif not ragdoll_util.is_recovering and ik_util.recovery_targets_locked:
			ik_util.recovery_targets_locked = false
			char_rigidbody.is_snapshot_active = true
			_reset_feet_after_recovery = true  # plantar los pies bajo el cuerpo, sin catch-up a los pasos

	if not _frozen_solve:
		skel_sizes_util.update(solve_delta, animation_inputs, entity_instantiation, ik_util)

	if is_instance_valid(arms_controller):
		arms_controller.update_arm_compress(jump_squat_t, 1.0 if is_seated else crouch_t)

	if not _frozen_solve:
		locomotion_signals.update(solve_delta)

	ik_util.left_arm_ik_target.position  = skel_sizes_util.left_arm_tip_rest_local
	ik_util.right_arm_ik_target.position = skel_sizes_util.right_arm_tip_rest_local
	# Y EL CODO, LO MISMO, explícito (04/11/2026): `_pose_arms` lee cuánto se corrió de su reposo como lo que le sumó la
	# animación. Lo devolvía a su lugar sólo de rebote, el animador procedural, por tener fórmulas colgadas; cuando se
	# fueron (los brazos del aire), el codo derivaba cuadro a cuadro y los antebrazos quedaban torcidos en reposo.
	ik_util.left_arm_pole.position  = skel_sizes_util.left_arm_pole_rest_local
	ik_util.right_arm_pole.position = skel_sizes_util.right_arm_pole_rest_local

	_solve_frame(solve_delta)



func _update_ragdoll_ext_state() -> void:
	if not is_instance_valid(char_rigidbody) or not is_instance_valid(ragdoll_util):
		return
	if ragdoll_util.is_active:
		char_rigidbody._ext_ragdoll_state = 1
	elif ragdoll_util.is_recovering:
		char_rigidbody._ext_ragdoll_state = 2
	else:
		char_rigidbody._ext_ragdoll_state = 0


# ── Solve del pose: UN solo camino ────────────────────────────────────────────
# Sentado y parado NO son dos pipelines. Es el mismo frame, y lo único que cambia es:
#   1. la RAÍZ    — parado la manda la cápsula; sentado se ancla al asiento.
#   2. las PIERNAS — parado, la marcha con IK contra el piso; sentado, plegadas fijas.
# Todo lo demás (procedural + anim_mod, brazos, sync de los cuerpos del ragdoll) es COMPARTIDO y
# existe una sola vez. Antes eran dos funciones copiadas y derivaron: al sentado le faltaba
# `drive_grab` — los brazos de un proxy sentado nunca llegaban al controllable que manejaba — y
# `sync_to_bones`. Regla: un paso nuevo va al bloque compartido; si ramificás, tiene que ser raíz o
# piernas. Ver technical/character-animation.md.
#
# El ORDEN de las piernas es lo único que difiere entre modos, y no es negociable:
#   - Parado van ANTES del procedural: los raycasts de pie salen de las caderas, y el procedural
#     anima las caderas con señales de pie (FOOT_SPREAD_*) → resolverlas después realimenta la marcha.
#   - Sentado van DESPUÉS, porque cuelgan de la raíz ya anclada al asiento.
func _solve_frame(delta: float) -> void:
	var seated := is_seated and is_instance_valid(current_seat)
	# PARADO A BORDO, COMO SENTADO (ver PLANTADO EN LA NAVE): los pies, clavados al final; ni marcha ni bajada de pelvis.
	var planted := not seated and _is_planted()

	if planted:
		# Los pies, a sus puntos de la nave; y la pelvis baja lo que haga falta para alcanzarlos, como en tierra.
		_place_planted_targets()
		_update_pelvis_drop(delta)
	elif not seated:
		_pose_legs_standing()
		# Con los pies ya colocados se puede medir si las piernas llegan. Va acá, entre colocarlos y la
		# capa procedural: el resultado lo aplica _apply_root_offsets, que corre dentro de _pose_procedural.
		_update_pelvis_drop(delta)

	_pose_root(seated)
	_pose_procedural(delta)
	_pose_root(seated)         # el procedural mueve el spine: re-anclarlo al asiento

	if seated:
		_pose_legs_seated()

	_pose_arms(delta)

	# ── LAS PIERNAS SE CLAVAN AL FINAL, DESPUÉS DE TODO LO QUE MUEVA LA RAÍZ ──────────────────────
	# INVARIANTE: el tren inferior NO lo maneja el tren superior. Los pies siguen la IK a un punto
	# FIJO DEL MUNDO, y todo lo que mueva la raíz —bajada de pelvis, agacharse, squat, y sobre todo la
	# inclinación de torso del agarre— tiene que resolverse volviendo a clavar las piernas a esos
	# MISMOS puntos, nunca dejando que la pierna acompañe a la cadera.
	#
	# Este repin ya existía, pero corría ANTES de _pose_arms — o sea antes de la única cosa que todavía
	# movía la raíz. La pierna se quedaba con la solución vieja y giraba con la cadera, como si el pie
	# no estuviera apoyado. Sentado el bug no aparecía porque el caso sentado sí re-clava después de los
	# brazos (era este mismo comentario, dos líneas más abajo).
	if seated:
		_repin_legs_seated()
	elif planted:
		_pose_legs_planted()
	else:
		_repin_legs_standing()

	_sync_ragdoll_bodies()
	_sync_body_visual()

## Raíz. Sentado: clava el spine en el asiento, fija la cápsula en XZ y gira la malla del asiento con
## el ocupante. Parado: nada, la raíz la manda la cápsula. Es idempotente a propósito (se llama antes
## y después del procedural, y sus entradas —asiento + yaw de la cápsula— no cambian entre medio).
func _pose_root(seated: bool) -> void:
	if not seated:
		return
	current_seat.update_seated_visual(self, char_rigidbody.global_rotation.y)
	custom_bones_util.lower_spine.global_position = _seat_pelvis_point()
	_pin_capsule_to_seat()

## Sentado, la cápsula va clavada sobre el asiento, en la línea de su arriba (ver LOS EJES DE LA SILLA). Corre en cada
## paso de física, no sólo al resolver la pose (ver «Cuándo se resuelve la pose»): la altura la lleva el asiento
## (SeatInteractable._carry_occupant).
func _pin_capsule_to_seat() -> void:
	var seat_pos : Vector3 = current_seat.global_position
	var up := _seat_up()
	char_rigidbody.global_position = seat_pos + up * (char_rigidbody.global_position - seat_pos).dot(up)

## ── LOS EJES DE LA SILLA (02/11/2026) ─────────────────────────────────────────────────────────────────────────────
## Sentado, todo se arma en los ejes del asiento y no en los del mundo: su arriba, y adelante —para donde mira el que
## está sentado, sobre el plano del asiento—. La nave cabecea y se ladea, y con la vertical del mundo la pelvis se
## despegaba de la silla (medido: 12 cm para atrás con 20° de cabeceo, 11 cm de costado con 20° de alabeo) y las piernas
## y los pies quedaban armados para un piso derecho. Lo vio el dios del juego cuando la tripulación dejó de congelarse.
func _seat_up() -> Vector3:
	return current_seat.global_basis.y.normalized()

func _seat_forward() -> Vector3:
	var up := _seat_up()
	var forward := -char_rigidbody.global_transform.basis.z
	forward -= up * forward.dot(up)
	return forward.normalized() if forward.length() > 0.001 else -current_seat.global_basis.z.normalized()

## Donde va la base de la columna: arriba del asiento su alto, y atrás lo que dice la silla.
func _seat_pelvis_point() -> Vector3:
	return current_seat.global_position + _seat_up() * current_seat.height \
		- _seat_forward() * current_seat.pelvis_back_of_centre()

## Piernas paradas: la marcha (target aéreo + raycast al piso + IK). Ver el modelo de gait en
## technical/character-animation.md.
func _pose_legs_standing() -> void:
	var tuck := LocomotionCommon.base().leg_tuck(self)
	ik_util.update_airborne_target(true, tuck)
	ik_util.update_airborne_target(false, tuck)

	ik_util.update_ik_raycast(true,  custom_bones_util, skel_sizes_util, animation_inputs)
	ik_util.update_ik_raycast(false, custom_bones_util, skel_sizes_util, animation_inputs)

	if _reset_feet_after_recovery:
		# Ya corrió el raycast (next_target fresco bajo el cuerpo): plantamos ahí el pie, sin catch-up.
		ik_util.reset_step_targets_to_ground()
		_reset_feet_after_recovery = false

## Cuánto de la tibia llega el pie sentado: casi entera (ver `_pose_legs_seated`).
const SEATED_SHIN_REACH := 0.995
## Lo más que se mete la pantorrilla para atrás, sentado (ver `_pose_legs_seated`).
const SEATED_MAX_TUCK := deg_to_rad(55.0)
## Cuánto baja la punta de los pies, sentado (ver `_repin_legs_seated`).
const SEATED_FOOT_POINT := deg_to_rad(18.0)

## Piernas sentadas: plegadas hacia adelante, sin piso ni marcha. Cachea los targets porque
## _repin_legs_seated re-resuelve contra los mismos — recalcularlos después de que los overrides de
## brazos inclinaron el spine arrastraría los pies con el torso.
func _pose_legs_seated() -> void:
	var forward := _seat_forward()
	var down := -_seat_up()

	# ── SENTADO DERECHO (22/10/2026, lo pidió el dios del juego): el muslo recto hacia adelante, horizontal, desde donde
	# nace (el hueso del muslo), y la pantorrilla a 90°, recta para abajo. Antes la pantorrilla iba un poco para atrás y
	# el pie quedaba corto (0,85 de la tibia). Un pelo menos que la tibia entera, para que la IK no quede en el borde.
	var left_hip  := custom_bones_util.left_higher_leg.global_position
	var right_hip := custom_bones_util.right_higher_leg.global_position
	var left_knee  := left_hip  + forward * skel_sizes_util.higher_leg_size.y
	var right_knee := right_hip + forward * skel_sizes_util.higher_leg_size.y
	# LOS PIES ADENTRO (28/10/2026, lo pidió el dios del juego: «que los pies los meta un poquito para adentro de la
	# silla, como en la vida real»): si las rodillas quedan más adelante que lo de siempre, la pantorrilla se va para
	# atrás justo eso, y el pie vuelve a caer donde caía, bajo el borde del asiento.
	var shin_length := skel_sizes_util.lower_leg_size.y * SEATED_SHIN_REACH
	var past: float = current_seat.knees_past_edge(skel_sizes_util.higher_leg_size.y)
	var tuck := asin(clampf(past / shin_length, 0.0, sin(SEATED_MAX_TUCK)))
	var shin := (down * cos(tuck) - forward * sin(tuck)) * shin_length
	_seated_left_foot  = left_knee  + shin
	_seated_right_foot = right_knee + shin
	_seated_left_pole  = left_knee  + forward
	_seated_right_pole = right_knee + forward

	_repin_legs_seated()
	ik_util.left_leg_current_target.global_position  = _seated_left_foot
	ik_util.right_leg_current_target.global_position = _seated_right_foot

## ── PLANTADO EN LA NAVE (02/11/2026) ──────────────────────────────────────────────────────────────────────────────
## Parado a bordo de exhibición ES IGUAL QUE SENTADO, sólo que las piernas van al piso en vez de a la silla (el dios del
## juego: «la inclinación del root bone por inercia o por impacto sucede también cuando están parados; la única
## diferencia es que están con las piernas en el piso en vez de la silla»). La cápsula va fija en su punto de la nave y
## girada con ella (ver CharacterRigidBody3D.ride); los pies, CLAVADOS en dos puntos del piso de la nave guardados en el
## marco de la cápsula (`plant_feet`), así nada de lo que recuerda queda en el mundo. Sin rayos contra el casco —que en
## las maquetas se mueve a mano y salta de a pasos— y sin pasos: el piso lo dice la nave. La pelvis sí baja lo que haga
## falta para alcanzarlos (la respiración la sube unos centímetros), como en tierra. Lo de arriba —la inclinación por inercia o por golpes, la respiración, los brazos— es lo de siempre.
var _planted_feet: Array[Vector3] = []


func _is_planted() -> bool:
	return _planted_feet.size() == 2 and is_instance_valid(char_rigidbody) and char_rigidbody._riding


## CLAVA LOS PIES en el piso que pasa por `floor_point` (un punto del mundo), cada uno bajo su cadera, separados como su
## marcha (`raycast_stance_offset`) y con el tobillo a su alto sobre el piso (`ankle_height`). Se guardan en el marco de
## la cápsula.
func plant_feet(floor_point: Vector3) -> void:
	_planted_feet.clear()
	if not is_instance_valid(char_rigidbody):
		return
	var body := char_rigidbody.global_transform
	var ankle_local := body.affine_inverse() * (floor_point + body.basis.y.normalized() * skel_sizes_util.ankle_height)
	for left: bool in [true, false]:
		var side := -1.0 if left else 1.0
		_planted_feet.append(Vector3(side * skel_sizes_util.raycast_stance_offset, ankle_local.y, 0.0))


## Los blancos de los pies, en sus puntos de la nave: de ellos mide la bajada de pelvis y a ellos van las piernas.
func _place_planted_targets() -> void:
	var body := char_rigidbody.global_transform.orthonormalized()
	ik_util.left_leg_current_target.global_position = body * _planted_feet[0]
	ik_util.right_leg_current_target.global_position = body * _planted_feet[1]


## Las piernas a sus pies clavados, con la rodilla adelante y los pies planos sobre el piso de la nave.
func _pose_legs_planted() -> void:
	_place_planted_targets()
	var body := char_rigidbody.global_transform.orthonormalized()
	var forward := -body.basis.z
	var up := body.basis.y
	var tilt := Basis(Quaternion(Vector3.UP, up))
	var flat := tilt.inverse() * forward
	var yaw := atan2(-flat.x, -flat.z)
	for left: bool in [true, false]:
		var foot := body * _planted_feet[0 if left else 1]
		var upper := custom_bones_util.left_higher_leg if left else custom_bones_util.right_higher_leg
		var lower := custom_bones_util.left_lower_leg if left else custom_bones_util.right_lower_leg
		ik_util.solve_two_bone_ik(upper, lower, foot, foot + up * skel_sizes_util.leg_height * 0.5 + forward)
		var bone: CustomBone = custom_bones_util.left_foot if left else custom_bones_util.right_foot
		if is_instance_valid(bone):
			bone.global_basis = tilt * IkUtil.level_basis(left, yaw)


## Re-resuelve el IK de las piernas sentadas contra los targets ya cacheados (los huesos se movieron
## porque algo tocó el spine después de plantarlas).
func _repin_legs_seated() -> void:
	ik_util.solve_two_bone_ik(custom_bones_util.left_higher_leg,  custom_bones_util.left_lower_leg,  _seated_left_foot,  _seated_left_pole)
	ik_util.solve_two_bone_ik(custom_bones_util.right_higher_leg, custom_bones_util.right_lower_leg, _seated_right_foot, _seated_right_pole)
	# LOS PIES, NIVELADOS (22/10/2026: el dios del juego los vio en posiciones raras al sentarse): sentado nadie los
	# nivelaba (ver IkUtil._level_foot) y colgaban rígidos de la tibia, con su inclinación. Planos, mirando adonde mira.
	# CON LA PUNTA UN POCO PARA ABAJO (29/10/2026, lo pidió el dios del juego: «ahora están como muy rígidos y es medio
	# poco natural la pose»): `SEATED_FOOT_POINT`, girados sobre el eje de costado del cuerpo.
	# Nivelados con el asiento (ver LOS EJES DE LA SILLA): armados como en un piso derecho y llevados a su inclinación.
	var tilt := Basis(Quaternion(Vector3.UP, _seat_up()))
	var flat := tilt.inverse() * _seat_forward()
	var yaw := atan2(-flat.x, -flat.z)
	var point := Basis(Basis(Vector3.UP, yaw) * Vector3.RIGHT, -SEATED_FOOT_POINT)
	for left: bool in [true, false]:
		var foot: CustomBone = custom_bones_util.left_foot if left else custom_bones_util.right_foot
		if is_instance_valid(foot):
			foot.global_basis = tilt * point * IkUtil.level_basis(left, yaw)

## Capa procedural + modificadores de raíz. Igual en los dos modos: sentado, `anim_mod.is_seated`
## hace que _apply_root_offsets no toque el spine y el procedural saltea POS_Y/POS_Z de la raíz, así
## que acá no hay nada que ramificar.
func _pose_procedural(delta: float) -> void:
	_update_passive_state(delta)
	procedural_animator.update()
	if is_instance_valid(anim_mod):
		anim_mod.jump_squat_t = jump_squat_t
		anim_mod.crouch_t     = crouch_t
		anim_mod.apply(delta)

## Brazos, COMPARTIDO: recalcula targets/poles desde el spine ya posado, maneja el agarre de un proxy
## desde el estado sincronizado, aplica los overrides (throw/grab) y resuelve el IK.
## Brazos, COMPARTIDO: recoloca targets y poles desde el spine ya posado, maneja el agarre de un
## proxy desde el estado sincronizado, aplica los overrides y resuelve la IK.
func _pose_arms(delta: float) -> void:
	var rb_basis := custom_bones_util.lower_spine.global_transform.basis

	var left_anim_offset:  Vector3 = ik_util.left_arm_ik_target.position  - skel_sizes_util.left_arm_tip_rest_local
	var right_anim_offset: Vector3 = ik_util.right_arm_ik_target.position - skel_sizes_util.right_arm_tip_rest_local
	var left_pole_offset:  Vector3 = ik_util.left_arm_pole.position  - skel_sizes_util.left_arm_pole_rest_local
	var right_pole_offset: Vector3 = ik_util.right_arm_pole.position - skel_sizes_util.right_arm_pole_rest_local

	ik_util.left_arm_ik_target.global_position  = custom_bones_util.left_upper_arm.global_position  + rb_basis * (skel_sizes_util.left_arm_tip_rest_local  - skel_sizes_util.left_arm_shoulder_rest_local + left_anim_offset)
	ik_util.right_arm_ik_target.global_position = custom_bones_util.right_upper_arm.global_position + rb_basis * (skel_sizes_util.right_arm_tip_rest_local - skel_sizes_util.right_arm_shoulder_rest_local + right_anim_offset)
	ik_util.left_arm_pole.global_position  = custom_bones_util.left_upper_arm.global_position  + rb_basis * (skel_sizes_util.left_arm_pole_rest_local  - skel_sizes_util.left_arm_shoulder_rest_local + left_pole_offset)
	ik_util.right_arm_pole.global_position = custom_bones_util.right_upper_arm.global_position + rb_basis * (skel_sizes_util.right_arm_pole_rest_local - skel_sizes_util.right_arm_shoulder_rest_local + right_pole_offset)

	# EL AGARRE, POR UN SOLO CAMINO para todos: lo que dice la intención (ver CharacterIntent.grab), venga del teclado,
	# de la red o de un guion. Vale igual sentado que parado — uno sentado en un dashboard también tiene que llegar al
	# handle. Con las manos según su clase (el ente, sólo sentado).
	if is_instance_valid(arms_controller):
		var target: Node = animation_inputs.grab_target if kind.uses_hands(is_seated) else null
		arms_controller.drive_grab(delta, target, intent.grab_point)

	if is_instance_valid(arms_controller):
		arms_controller.apply_world_overrides(delta)

	ik_util.solve_two_bone_ik(custom_bones_util.left_upper_arm, custom_bones_util.left_lower_arm,
		ik_util.left_arm_ik_target.global_position, ik_util.left_arm_pole.global_position)
	ik_util.solve_two_bone_ik(custom_bones_util.right_upper_arm, custom_bones_util.right_lower_arm,
		ik_util.right_arm_ik_target.global_position, ik_util.right_arm_pole.global_position)

## Copia el pose de los huesos a los cuerpos del ragdoll mientras NO se está ragdolleando (regla
## sync-before-snapshot). También sentado: antes solo corría parado y los cuerpos quedaban viejos
## todo el rato que estabas en el asiento.
func _sync_ragdoll_bodies() -> void:
	if is_instance_valid(ragdoll_util) and not ragdoll_util.is_recovering:
		ragdoll_util.sync_to_bones()

## Copia el pose del rig lógico al cuerpo visible. Va al FINAL del solve, después de que todo lo demás
## terminó de mover los CustomBone — el cuerpo no anima nada, solo refleja el resultado.
##
## La FUENTE cambia según el estado: parado son los CustomBone; ragdolleando o levantándose son los
## cuerpos rígidos, porque ahí los huesos quedan congelados y lo que se mueve son ellos. Los cuerpos
## del ragdoll van invisibles y el cuerpo visible los sigue, así que el personaje se ve igual de pie
## que tirado en el piso. Ver technical/characters.md.
func _sync_body_visual() -> void:
	if not is_instance_valid(body_visual):
		return
	if is_instance_valid(ragdoll_util) and (ragdoll_util.is_active or ragdoll_util.is_recovering):
		body_visual.sync_from_ragdoll(ragdoll_util.get_bodies())
	else:
		body_visual.sync_from_bones()

## Ubica local_targets (raycasts de pies, targets/poles de brazos) siguiendo el transform del
## personaje. Lee animation_inputs (no la cápsula en vivo): así el facing viene de una sola fuente
## llenada por el productor tras aplicarse el transform (local o de red), sin depender del orden.
func _update_local_targets_positions() -> void:
	if animation_inputs == null:
		return
	local_targets.global_position = animation_inputs.origin
	local_targets.global_rotation = Vector3(0, animation_inputs.basis.get_euler().y, 0)

## Productor de la entrada de animación. Hoy lee la cápsula física (igual que antes lo hacían los
## módulos directo); a futuro un proxy la llenará desde la red. Ver technical/character-animation.md.
func _update_animation_inputs(delta: float = 0.0) -> void:
	if not is_instance_valid(char_rigidbody) or animation_inputs == null:
		return
	var t := char_rigidbody.global_transform
	animation_inputs.velocity     = char_rigidbody.get_motion_velocity()
	animation_inputs.basis        = t.basis
	animation_inputs.origin       = t.origin
	animation_inputs.grounded     = char_rigidbody.is_grounded
	animation_inputs.delta        = delta
	animation_inputs.ground_point = char_rigidbody.get_ground_collision_point()
	animation_inputs.impact_y     = char_rigidbody.impact_y
	animation_inputs.impact_xz    = char_rigidbody.impact_xz
	animation_inputs.crouch_t     = crouch_t
	animation_inputs.jump_squat_t = jump_squat_t
	animation_inputs.taking_off = taking_off or _jump_pending >= 0.0
	# LA MIRADA Y EL AGARRE, DE LA INTENCIÓN (ver CharacterIntent), venga de quien venga. Quien no tiene quien lo maneje
	# mira derecho.
	animation_inputs.head_pitch   = clampf(intent.look_pitch, -0.5, 0.8) if kind.looks() else 0.0
	animation_inputs.grab_target  = intent.grab
	# Reset del pulso de impacto vertical (antes lo hacía locomotion_signals._update_velocity_signals).
	char_rigidbody.impact_y_signed = 0.0

## ── LA SILLA, DE LA INTENCIÓN (03/11/2026) ───────────────────────────────────────────────────────────────────────────
## Una sola silla para todos (ver SeatInteractable): al jugador lo sienta la silla cuando el host se la da, y ella lo
## anota en su intención; a los demás —el compañero de red, el de exhibición— los sienta esto, siguiendo la silla que dice
## su intención. Corre en cada paso: si la silla se va, o el personaje se reconstruye, se acomoda solo.
func _follow_seat() -> void:
	if kind.is_local() or not is_instance_valid(char_rigidbody):
		return
	var wanted: Node = intent.seat if is_instance_valid(intent.seat) and intent.seat.is_inside_tree() else null
	var now: Node = current_seat if is_seated and is_instance_valid(current_seat) else null
	if wanted == now:
		return
	if now != null:
		(now as SeatInteractable).release(self)
	if wanted != null and not _is_ragdolling():
		(wanted as SeatInteractable).sit(self)


## ── LA MIRADA LLEVA EL CUERPO ENTERO (ver characters.md, Where you look is the whole body) ──────────────────────────
## El rumbo de la intención, en los ejes del marco, gira la cápsula derecha. No a quien no tiene quien lo maneje (una
## figura queda como la pusieron), ni tirado, ni al que va fijo en su marco o sentado sin simularse (a ésos los lleva su
## marco o su silla, girados lo mismo: ver CharacterRigidBody3D.ride, SeatInteractable._carry_occupant).
func _apply_look() -> void:
	if not kind.looks() or not is_instance_valid(char_rigidbody):
		return
	if is_instance_valid(ragdoll_util) and ragdoll_util.is_active:
		return
	if char_rigidbody._riding:
		return
	if is_seated and not kind.simulates() and kind.driver != CharacterKind.Driver.NETWORK:
		return
	char_rigidbody.global_rotation.y = CharacterIntent.world_yaw(char_rigidbody.frame, intent.look_yaw)


## ── EL SALTO CARGADO (03/11/2026: era del PlayerController, pasó al cuerpo con la intención) ──────────────────────────
## Al apretar el salto (`intent.jump`) parado en el piso, sin agacharse ni sentarse, empieza a cargar —la pelvis baja,
## `jump_squat_t`— hasta `time_to_max_jump`; al soltarlo salta, de 30 % a 100 % de su `jump_height` según lo cargado (la
## carga interpola ALTURA, no impulso: así la barra es lineal con lo que se ve saltar, y un toque sin cargar sigue siendo
## un saltito útil). Si en el medio deja de poder (en el aire, agachado), se cancela. El mismo para el teclado y el guion.
## Con movimiento directo (el ente) no hay carga: salta ya (ver PlayerController).
var _jump_charge := 0.0
var _jump_charging := false
var _jump_was := false


## Lo cargado, de 0 a 1 (la barra del HUD).
## LO QUE SE ECHA ATRÁS CON LO QUE LLEVA, ahora (ver LocomotionCommon, EL CUERPO SE ECHA ATRÁS): hacia `carry_lean`, a su
## ritmo. Lleva algo si su agarre es una caja que alguien sostiene.
func _update_carry_lean(delta: float) -> void:
	var tuning := LocomotionCommon.base()
	var want := Vector2.ZERO
	var grab := intent.grab as GrabbableInteractable if intent != null else null
	var holding := is_instance_valid(grab) and grab.box_half != Vector3.ZERO and grab.hold_count() > 0 \
		and not is_seated and is_instance_valid(char_rigidbody)
	# EL TIRO (ver LocomotionCommon, TIRAR): al cargar se echa atrás, al empujar se va adelante, alejándose del paquete y hacia
	# él; más rápido que llevar.
	var throwing := holding and is_instance_valid(anim_mod) and anim_mod.throw_with_box
	if throwing:
		var away_box := Vector2(0.0, 1.0)
		var from := grab.get_parent() as Node3D
		if is_instance_valid(from):
			var local := char_rigidbody.global_basis.orthonormalized().inverse() * (char_rigidbody.global_position - from.global_position)
			if Vector2(local.x, local.z).length() > 0.05:
				away_box = Vector2(local.x, local.z).normalized()
		want += away_box * tuning.throw_lean(anim_mod)
	if tuning.carry_lean_mode != 0 and holding:
		var body := grab.get_parent() as RigidBody3D
		var share := 1.0
		if tuning.carry_lean_by_weight and is_instance_valid(body):
			share = clampf(GrabbableInteractable.load_of(body.mass, maxf(grab.total_strength(),
				entity_archetype.strength if entity_archetype != null else 1.0)), 0.0, 1.0)
		if tuning.carry_lean_mode == 2:
			var v := char_rigidbody.linear_velocity
			var top: float = maxf(entity_archetype.speed * entity_archetype.sprint_multiplier \
				* CharacterRigidBody3D.SPEED_SCALE, 0.01) if entity_archetype != null else 1.0
			share *= clampf(Vector2(v.x, v.z).length() / top, 0.0, 1.0)
		# Alejándose del paquete: del paquete hacia el cuerpo, en los ejes de la cápsula; si no, hacia atrás.
		var away := Vector2(0.0, 1.0)
		if tuning.carry_lean_away and is_instance_valid(body):
			var local := char_rigidbody.global_basis.orthonormalized().inverse() * (char_rigidbody.global_position - body.global_position)
			if Vector2(local.x, local.z).length() > 0.05:
				away = Vector2(local.x, local.z).normalized()
		want += away * deg_to_rad(tuning.carry_lean_deg) * share
	var pace := minf(tuning.carry_lean_s, THROW_LEAN_S) if throwing else tuning.carry_lean_s
	carry_lean = carry_lean.lerp(want, 1.0 - exp(-delta / maxf(pace, 0.01) * 3.0))
	carry_lean_share = clampf(carry_lean.length() / maxf(deg_to_rad(tuning.carry_lean_deg), 0.001), 0.0, 1.0)


## Lo que tarda en echarse atrás o adelante con el tiro (s): rápido, es un golpe.
const THROW_LEAN_S := 0.06


func jump_charge() -> float:
	var arch := entity_archetype
	return _jump_charge / maxf(arch.time_to_max_jump, 0.001) if arch != null else 0.0


## EL SALTO SALE AL TERMINAR DE SOLTAR LA CARGA (05/11/2026, el dios del juego: «que empiece a estar en el aire recién
## cuando termine la animación opuesta de cargar el salto… una diferencia bien discreta entre cargar y soltar mientras
## tocás el piso y cuando estás en el aire»): al soltar, la agachada vuelve en `JUMP_RELEASE_S` con los pies en el piso,
## y recién ahí, si sigue en el piso, sale la velocidad del salto. Así en el aire el cuerpo arranca en su postura de
## siempre, y la regla del aire no se mezcla con la agachada. *Hasta entonces el salto salía al soltar, mientras la
## agachada todavía se deshacía.*
const JUMP_RELEASE_S := 0.08
var _jump_pending := -1.0
var _jump_release_left := 0.0
## DESPEGANDO: desde que suelta el salto hasta que deja el piso (como mucho `TAKE_OFF_MAX_S`). Mientras, la marcha no
## arranca un paso nuevo y los dos pies despegan juntos (05/11/2026, el dios del juego: en el salto «un pie empezaba
## antes que el otro»; medido en «caer en loop»: los seis salían con la izquierda ya en el aire, porque arrancaban a
## correr entre soltar el salto y despegar). Ver IkUtil.advance_gait.
var taking_off := false
var _taking_off_t := 0.0
const TAKE_OFF_MAX_S := 0.3


func _update_jump(delta: float) -> void:
	if taking_off:
		_taking_off_t += delta
		if not is_instance_valid(char_rigidbody) or not char_rigidbody.is_grounded or _taking_off_t > TAKE_OFF_MAX_S:
			taking_off = false
	if _jump_pending >= 0.0:
		_jump_release_left -= delta
		if _jump_release_left <= 0.0:
			if is_instance_valid(char_rigidbody) and char_rigidbody.is_grounded:
				char_rigidbody.jump_to_height(_jump_pending)
				taking_off = true
				_taking_off_t = 0.0
			_jump_pending = -1.0
	var want := intent.jump
	var pressed := want and not _jump_was
	_jump_was = want
	if not is_instance_valid(char_rigidbody) or not kind.simulates() or entity_archetype == null:
		return
	var rb := char_rigidbody
	# Con un salto pendiente (ver EL SALTO SALE AL TERMINAR DE SOLTAR LA CARGA) no carga otro: si no, volver a apretar en
	# esos 0,08 s reiniciaba el pendiente y el salto nunca salía (medido: el dummy de «subir y bajar» apretaba y soltaba
	# un cuadro sí y uno no hasta chocar el escalón).
	var can := rb.is_grounded and not is_seated and crouch_t < 0.5 and not rb.creative_mode \
		and kind.motion == CharacterKind.Motion.PHYSICAL and rb.input_enabled and _jump_pending < 0.0
	if pressed and can:
		_jump_charging = true
	if not _jump_charging:
		return
	if not can:
		_cancel_jump()
		return
	var arch := entity_archetype
	if want:
		_jump_charge = minf(_jump_charge + delta, arch.time_to_max_jump)
		jump_squat_t = jump_charge()
		return
	_jump_pending = lerpf(arch.jump_height * 0.3, arch.jump_height, jump_charge())
	_jump_release_left = JUMP_RELEASE_S
	_cancel_jump()


## AGACHARSE (ver CharacterIntent.crouch): baja en `AnimationModifiers.CROUCH_S` y achica la cápsula al terminar de bajar;
## al pararse, la cápsula vuelve ya. Agachado camina más lento —con movimiento directo, `DIRECT_CROUCH_SPEED`—. Sentado
## o volando libre no se agacha. Un proxy de red no: le llega `crouch_t`.
const DIRECT_CROUCH_SPEED := 0.45
const CROUCH_SPEED := 0.6
var _crouched := false


func _update_crouch() -> void:
	if not is_instance_valid(char_rigidbody) or not kind.simulates():
		return
	var rb := char_rigidbody
	var want := intent.crouch and not is_seated and not rb.creative_mode
	if want == _crouched:
		return
	_crouched = want
	var tw := create_tween()
	tw.tween_property(self, "crouch_t", 1.0 if want else 0.0, AnimationModifiers.CROUCH_S)
	if want:
		tw.tween_callback(func() -> void: rb.set_crouched(true))
	else:
		rb.set_crouched(false)
	var slow := DIRECT_CROUCH_SPEED if kind.motion == CharacterKind.Motion.DIRECT else CROUCH_SPEED
	rb.crouch_speed_factor = slow if want else 1.0


func _cancel_jump() -> void:
	_jump_charging = false
	_jump_charge = 0.0
	create_tween().tween_property(self, "jump_squat_t", 0.0, JUMP_RELEASE_S)


## QUÉ SE VE DE ÉL, según su clase (ver CharacterKind.shown): entero, o nada —salvo las manos sentado, si las usa—.
func refresh_shown() -> void:
	if kind.shown == CharacterKind.Shown.WHOLE or not is_instance_valid(body_visual) or character_hidden:
		return
	var hands := is_seated and kind.uses_hands(true)
	body_visual.set_meshes_visible(hands)
	if hands:
		body_visual.set_first_person(true)

func refresh_camera_animations() -> void:
	if is_instance_valid(bone_animations):
		bone_animations.refresh_camera_animations()

## Primera persona: la maneja el cuerpo visible — los CustomBone no dibujan nada. Con las cápsulas por
## hueso vuelve a ser POR HUESO (antebrazos y pies, como siempre); con la malla skinneada solo podía
## ser por malla entera, y esa granularidad se había perdido.
func set_first_person_visibility(first_person: bool) -> void:
	if character_hidden:
		return  # escondido entero (ver `set_shown`): no lo pisa un cambio de cámara
	if not is_instance_valid(body_visual):
		return
	body_visual.set_first_person(first_person)

func _setup_char_grabbable() -> void:
	var grabbable := CharacterGrabbable.new()
	grabbable.owner_bi = self  # para apagarse cuando este personaje ragdolea (no se agarra a un caído)
	grabbable.name = "Grabbable"  # nombre estable para el grab sync entre máquinas
	char_rigidbody.add_child(grabbable)

	var full_height    := skel_sizes_util.leg_height + skel_sizes_util.torso_height + skel_sizes_util.head_height
	var ground_local_y := char_rigidbody._capsule_stand_y_offset - full_height * 0.5
	var handle_y       := ground_local_y + skel_sizes_util.leg_height \
		+ skel_sizes_util.lower_spine_size.y
	var handle_x := skel_sizes_util.shoulders_width * 0.5

	grabbable.add_handle_point_local(Vector3(-handle_x, handle_y, 0.0))
	grabbable.add_handle_point_local(Vector3( handle_x, handle_y, 0.0))
	grabbable.add_grab_point_local(Vector3(0.0, char_rigidbody._capsule_stand_y_offset, 0.0))

func get_interaction_origin() -> Vector3:
	var sizes       := skel_sizes_util
	var full_height := sizes.leg_height + sizes.torso_height + sizes.head_height
	var ground_y    := char_rigidbody.global_position.y + (char_rigidbody._capsule_stand_y_offset - full_height * 0.5)

	if is_seated and is_instance_valid(current_seat):
		return _seat_pelvis_point() + _seat_up() \
			* (sizes.lower_spine_size.y + sizes.higher_spine_size.y + sizes.chest_size.y)

	var chest_tip_y := ground_y + sizes.leg_height \
		+ sizes.lower_spine_size.y + sizes.higher_spine_size.y + sizes.chest_size.y

	chest_tip_y -= AnimationModifiers.crouch_drop(self) * crouch_t

	var at := Vector3(char_rigidbody.global_position.x, chest_tip_y, char_rigidbody.global_position.z)
	# EL PECHO SE ECHA ATRÁS CON LO QUE LLEVA, y el punto de donde sale el agarre con él (04/11/2026, el dios del juego:
	# «que siga al pecho»): lo que el giro de la columna (ver `carry_lean`) corre la punta del pecho desde la cadera, menos
	# lo que la cadera va hacia el paquete (LocomotionCommon.carry_lean_hips). Con él se corren el objetivo de lo que se lleva y
	# el tope del pecho (ver GrabbableInteractable), así la caja se acerca cuando uno se echa atrás y los brazos no se
	# estiran. *Antes el punto quedaba quieto, y al echarse atrás la caja quedaba lejos del pecho.*
	if carry_lean != Vector2.ZERO:
		var rise := sizes.lower_spine_size.y + sizes.higher_spine_size.y + sizes.chest_size.y
		var hips := carry_lean_share * LocomotionCommon.base().carry_lean_hips
		var back := Vector2(sin(carry_lean.x), sin(carry_lean.y)) * rise - carry_lean.normalized() * hips
		at += char_rigidbody.global_basis.orthonormalized() * Vector3(back.x, 0.0, back.y)
	return at

## LO ESCONDE Y LO APAGA (`on` falso), o lo vuelve a mostrar y prender: el personaje entero, sea de la clase que sea. Es
## el único apagar: el de exhibición que se aparta cuando un jugador se sienta en su silla, el ente que se guarda.
func set_active(on: bool) -> void:
	if on == (process_mode != Node.PROCESS_MODE_DISABLED):
		return
	visible = on
	process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	# Y SU CÁPSULA, FUERA DEL MUNDO mientras está apagado: congelada y en ninguna capa —lo que nazca donde estaba no nace
	# adentro de ella—; al prenderlo, como estaba.
	if is_instance_valid(char_rigidbody):
		var rb := char_rigidbody
		if not on:
			_asleep = [rb.collision_layer, rb.collision_mask, rb.freeze]
			rb.collision_layer = 0
			rb.collision_mask = 0
			rb.freeze = true
		elif _asleep.size() == 3:
			rb.collision_layer = _asleep[0]
			rb.collision_mask = _asleep[1]
			rb.freeze = _asleep[2]
			_asleep = []
	if is_instance_valid(player_controller):
		player_controller.set_active(on)


var _asleep: Array = []


## Debug: muestra u oculta el personaje COMPLETO. A diferencia de la primera persona, que deja a la
## vista antebrazos y pies, esto no deja nada — es para mirar la cápsula, el esqueleto o los
## colisionadores sin el cuerpo encima.
func set_character_visible(value: bool) -> void:
	character_hidden = not value
	if not is_instance_valid(body_visual):
		return
	if character_hidden:
		body_visual.set_meshes_visible(false)
		return
	# Al volver a mostrar NO se prende todo a lo bruto: se restaura el estado de primera persona. Si no,
	# cualquier toggle del panel (que pasa por acá con value = true) le devolvía el cuerpo entero al
	# jugador que estaba en primera persona.
	var first_person := kind.is_local() and is_instance_valid(player_controller) and player_controller.is_first_person_view()
	body_visual.set_meshes_visible(true)
	body_visual.set_first_person(first_person)
	refresh_shown()

# ── AJUSTE DE PELVIS ──────────────────────────────────────────────────────────────────────────────
# La pelvis baja SOLO lo que haga falta para que las piernas lleguen a sus pies. Es el patrón estándar
# de foot IK (pelvis adjustment): se mide la distancia cadera↔pie de cada pierna y, si supera lo que
# la pierna estira, se baja la raíz por el peor déficit de las dos.
#
# Es geométrico, no predictivo: no adivina por velocidad, mide. Por eso funciona igual en escaleras,
# pendientes, agachado o cuando te empujan — casos donde una fórmula por velocidad se equivoca.
#
# Y reemplaza a la derivación vieja `stride → altura de pelvis → alcance del pie`, que iba al revés:
# ahora `stride` significa literalmente el largo del paso, y la pelvis es una consecuencia.

## ── LA PELVIS, EN DOS CAPAS (07/11/2026, el dios del juego eligió, entre varias a prueba, «curva: se hunde al pisar» con
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

var _pelvis_drop_smooth: float = 0.0
## El estilo de caminar de este personaje (ver WalkStyle): la base, o la suya si tiene modificadores.
var walk_style: WalkStyle = WalkStyle.plain()
## SUS MODIFICADORES de caminata, pose y quieto (ver WalkModifier). Se ponen antes de `add_child`, como `size_scale`.
var walk_modifiers: Array[WalkModifier] = []
## LOS QUE VALEN: la pose de su arquetipo y después los suyos (ver `initialize_skeleton`).
var _modifiers: Array[WalkModifier] = []

## Mide el déficit de alcance de las dos piernas y deja el resultado suavizado en anim_mod. Corre
## DESPUÉS de colocar los pies (necesita sus targets) y ANTES de la capa procedural (que es la que
## aplica el offset de raíz).
## Avanza el reloj pasivo y el esfuerzo. El esfuerzo sale de la VELOCIDAD, no de la stamina, y eso es
## deliberado: la velocidad ya viaja por la red, así que un proxy lo calcula solo y **los NPC lo tienen
## gratis con el mismo código**. Ver PassiveState.
func _update_passive_state(delta: float) -> void:
	if passive_state == null or not is_instance_valid(char_rigidbody):
		return
	# Contra el piso que pisa: parado en la nave que vuela no es correr (ver CharacterRigidBody3D, EL PISO QUE SE
	# MUEVE). Un proxy sigue leyendo su linear_velocity, como hasta ahora.
	var v := char_rigidbody.get_motion_velocity() if char_rigidbody.kind.simulates() else char_rigidbody.linear_velocity
	var speed: float = Vector2(v.x, v.z).length()
	# El esfuerzo arranca antes del tope de caminata: caminar ligero ya cansa un poco.
	var floor_speed: float = char_rigidbody.max_speed_forward * 0.6
	var top: float = char_rigidbody.max_speed_forward * char_rigidbody.sprint_multiplier
	var effort: float = clampf((speed - floor_speed) / maxf(top - floor_speed, 0.001), 0.0, 1.0)
	passive_state.update(delta, effort)


## LOS PIES VAN CON EL PISO QUE SE MUEVE (ver CharacterRigidBody3D.floor_velocity): parado en la nave en vuelo, los
## puntos donde el paso dejó los pies viajan con ella (ver IKUtil.ground_velocity), lo que pasó desde el último solve
## (`step`: la pose se resuelve una vez por cuadro, y los de lejos menos). Sólo mientras pisa algo que se mueve, y a cero una vez al bajarse: la cinta
## del sandbox escribe lo mismo para caminar en el lugar, y no hay que pisarla.
var _on_moving_floor := false

func _ride_floor(step: float) -> void:
	if not is_instance_valid(ik_util) or not is_instance_valid(char_rigidbody):
		return
	var floor_velocity := char_rigidbody.floor_velocity
	if floor_velocity != Vector3.ZERO:
		ik_util.ground_velocity = floor_velocity
		ik_util.ground_step = step
		_on_moving_floor = true
	elif _on_moving_floor:
		ik_util.ground_velocity = Vector3.ZERO
		ik_util.ground_step = 0.0
		_on_moving_floor = false


func _update_pelvis_drop(delta: float) -> void:
	if not is_instance_valid(anim_mod):
		return
	if is_seated or (is_instance_valid(ragdoll_util) and (ragdoll_util.is_active or ragdoll_util.is_recovering)):
		_pelvis_drop_smooth = 0.0
		anim_mod.pelvis_drop = 0.0
		return

	var max_len: float = skel_sizes_util.leg_height * SkeletonSizesUtil.MAX_EXTENSION
	# NUNCA MÁS QUE UNA PIERNA: un pie que quedó lejos —un piso que se fue de abajo— hacía bajar la pelvis, la cadera
	# bajada quedaba más lejos todavía, y en cada cuadro bajaba más, sin fin (02/11/2026, lo vio la nave a bordo).
	# DESDE LA CADERA SIN BAJAR, Y EN VERTICAL (05/11/2026, el dios del juego: «se supone que yo la zancada la puedo
	# aumentar y que la pelvis se va a bajar para machear la caminata»): la cadera de este momento todavía tiene puesta la
	# bajada del cuadro anterior, así que se le devuelve (`pelvis_drop`) antes de medir; y lo que se pide es cuánto bajar
	# la cadera derecho para abajo para que el pie, a la distancia horizontal que está, quede al alcance (ver
	# `_leg_drop`). *Hasta entonces se medía desde la cadera ya bajada y se pedía lo que faltaba en distancia: la cuenta
	# se equilibraba a mitad de camino —medido corriendo, al final del apoyo la pelvis bajaba 14 cm y a la pierna le
	# seguían faltando 15—, y la pierna de atrás quedaba corta, derecha, con el pie despegado antes de tiempo.*
	# Y SÓLO POR LOS PIES APOYADOS: el que vuela no tiene que llegar a ningún lado. *Medido el 05/11/2026: la pelvis más
	# baja del nene corriendo la pedía un pie recién despegado, todavía al 96 % de la pierna atrás.*
	var applied: float = anim_mod.pelvis_drop
	var deficit: float = minf(maxf(
		0.0 if ik_util.leg_is_swinging(true) else
			_leg_drop(custom_bones_util.left_higher_leg, ik_util.left_leg_current_target, max_len, applied),
		0.0 if ik_util.leg_is_swinging(false) else
			_leg_drop(custom_bones_util.right_higher_leg, ik_util.right_leg_current_target, max_len, applied)),
		skel_sizes_util.leg_height)
	# LA QUE SUBE AL DESPEGAR (ver WalkStyle.bounce_up, la usan modificadores como los saltarines): con un pie en el aire
	# la pelvis se empuja hacia arriba, lo que deje la pierna que apoya sin estirarse de más —si no, el pie apoyado se
	# despegaría del piso—.
	if walk_style.bounce_up > 0.0 and deficit <= 0.0:
		var lift := maxf(ik_util.swing_lift(true, skel_sizes_util), ik_util.swing_lift(false, skel_sizes_util))
		var room := minf(_leg_room(custom_bones_util.left_higher_leg, ik_util.left_leg_current_target, max_len,
				not ik_util.leg_is_swinging(true)),
			_leg_room(custom_bones_util.right_higher_leg, ik_util.right_leg_current_target, max_len,
				not ik_util.leg_is_swinging(false)))
		deficit = -minf(walk_style.bounce_up * skel_sizes_util.leg_height * lift, room)

	# CAPA 1, LA NECESIDAD SUAVE Y ATADA AL PASO (ver arriba). Con `1 − e^(−dt/τ)`: igual con cualquier paso de tiempo.
	var tau := PELVIS_DROP_STILL_S
	if ik_util.step_time() < INF:
		tau = minf(PELVIS_STEP_SHARE * ik_util.step_time(), PELVIS_DROP_MAX_S)
	_pelvis_drop_smooth = lerpf(_pelvis_drop_smooth, deficit, 1.0 - exp(-delta / maxf(tau, 0.001)))
	# CAPA 2, LA HUNDIDA AL PISAR, encima.
	anim_mod.pelvis_drop = _pelvis_drop_smooth + _sink(delta)


## ── LA HUNDIDA AL PISAR (ver LA PELVIS, EN DOS CAPAS) ───────────────────────────────────────────────────────────────
## Cada vez que un pie pisa arranca un reloj, `s`, que cuenta qué parte del paso pasó (0 al pisar, 1 un paso después).
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
var _since_land := 0.0
var _was_swinging := [false, false]


## LO QUE SE HUNDE este cuadro (m, positivo es abajo).
func _sink(delta: float) -> float:
	var landed := false
	for i in 2:
		var swinging := ik_util.leg_is_swinging(i == 0)
		if bool(_was_swinging[i]) and not swinging:
			landed = true
		_was_swinging[i] = swinging
	_since_land = 0.0 if landed else _since_land + delta
	var step := ik_util.step_time()
	if step == INF:
		return 0.0
	var depth := SINK_DEPTH * skel_sizes_util.leg_height * entity_instantiation.root_bounciness * walk_style.bounce_down
	return depth * _bump(_since_land / step, SINK_BOTTOM, SINK_HALF_WIDTH)


## Una loma de 0 a 1 y de vuelta, centrada en `at`, de medio ancho `width`.
static func _bump(s: float, at: float, width: float) -> float:
	var u := clampf((s - at) / maxf(width, 0.001), -1.0, 1.0)
	return pow(cos(u * PI * 0.5), 2.0)


## Cuánto le falta a esta pierna para llegar a su pie, o 0 si llega.
## Cuánto más puede subir la cadera sin que la pierna que apoya en `foot` se estire de más (las que no apoyan no
## cuentan: el infinito).
func _leg_room(hip: CustomBone, foot: Node3D, max_len: float, planted: bool) -> float:
	if not planted or not is_instance_valid(hip) or not is_instance_valid(foot):
		return INF
	return maxf(max_len - hip.global_position.distance_to(foot.global_position), 0.0)


## CUÁNTO BAJAR LA CADERA, DERECHO PARA ABAJO, PARA QUE ESTA PIERNA LLEGUE A `target`: medido desde la cadera sin la
## bajada que ya tiene (`applied`, ver `_update_pelvis_drop`). Con el pie a `x` de la cadera en el plano, la pierna llega
## a `max_len` si la cadera queda a `√(max_len² − x²)` sobre él. Si el pie está más lejos que la pierna en el plano, no
## hay bajada que lo alcance: no se baja nada (un teleport, un pie que quedó en otro lado; el paso lo trae).
func _leg_drop(hip: CustomBone, target: Node3D, max_len: float, applied: float) -> float:
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
## pelvis. Mismo patrón que _repin_legs_seated. Ver technical/character-animation.md.
func _repin_legs_standing() -> void:
	ik_util.solve_two_bone_ik(custom_bones_util.left_higher_leg, custom_bones_util.left_lower_leg,
		ik_util.left_leg_current_target.global_position, ik_util.left_leg_pole.global_position)
	ik_util.solve_two_bone_ik(custom_bones_util.right_higher_leg, custom_bones_util.right_lower_leg,
		ik_util.right_leg_current_target.global_position, ik_util.right_leg_pole.global_position)
