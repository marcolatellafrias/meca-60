class_name InteractionController
extends Node

## EL TIRO Y EL EMPUJÓN, DE UN MISMO NÚMERO DE CADA UNO (04/11/2026, el usuario: «es preferible tener un valor
## normalizado que afecte a las dos en vez de que una afecte a la otra»): la FUERZA DE BRAZOS del arquetipo
## (`throw_strength`, 1 lo normal; se ajusta en la F3, Movimiento) por dos perillas de todos, en la F1 (pestaña TIRAR):
## `LocomotionCommon.throw_per_arm` (N·s de impulso al tirar a carga entera) y `LocomotionCommon.push_per_arm` (m/s que le da el
## empujón a quien recibe). *Antes, 70 N·s y 7 m/s por unidad, fijos en el código; el 04/11 el tiro subió a 105 y 120 y
## el empujón quedó colgado de él.*

## El cuerpo de quien interactúa: el del personaje o el ente del sandbox. Solo se usa para excluirlo del
## rayo y para preguntarle a su BoneInstantiator, si lo tiene, dónde nace la interacción.
var char_rigidbody: CollisionObject3D
## EL OJO DE QUIEN INTERACTÚA (05/11/2026): de dónde sale la mirada y hacia dónde va (−Z). La cámara del jugador, o la
## cabeza de quien no tiene cámara (ver ExhibitOperator): sólo se le pide dónde está y hacia dónde mira. *Hasta entonces
## pedía una Camera3D, y por eso el guion tenía su propia copia de agarrar, empujar y tirar.*
var player_camera:  Node3D
var arms_controller: ArmsController
var anim_mod: AnimationModifiers

## Fuerza del agarre, normalizada (= `strength` del arquetipo). La física del agarre la resuelve
## GrabbableInteractable juntando todas las manos; acá sólo aportamos con cuánta fuerza tira ésta.
var grab_strength:            float = 0.5
var show_grab_curve:          bool  = true
## EL RAYO DE DEPURACIÓN, para todos los controladores a la vez. Lo apaga el sandbox mientras está abierto (ver
## DesignSandbox._ready): ahí tapaba los controles que se estaban probando.
static var debug_line: bool = true
var grab_cone_half_angle:     float = 120.0
## Impulso de lanzamiento (N·s) a carga completa para OBJETOS. Impulso fijo → Δv = impulso/masa:
## lo liviano vuela, lo pesado apenas se despega. Se sobreescribe por arquetipo
## (ver EL TIRO Y EL EMPUJÓN, arriba).
## El impulso del tiro a carga entera (N·s) y el empujón (m/s), de su fuerza de brazos (ver EL TIRO Y EL EMPUJÓN).
func _throw_impulse() -> float:
	return _arm() * LocomotionCommon.base().throw_per_arm

func _push_speed() -> float:
	return _arm() * LocomotionCommon.base().push_per_arm

func _arm() -> float:
	return _entity_instantiation.arch_final.throw_strength if is_instance_valid(_entity_instantiation) else 1.0
## Velocidad de knockback (m/s) a carga completa al EMPUJAR a un compañero. Basado en velocidad
## (impulso = masa·vel) para que trastabille parecido sin importar cuánto pese.
## EL TIRO DE UNA CAJA ESPERA AL EMPUJÓN (ver LocomotionCommon, TIRAR): lo que se va a soltar, con qué impulso, y cuánto falta.
var _throw_pending: RigidBody3D = null
var _throw_pending_impulse := Vector3.ZERO
var _throw_pending_s := 0.0
var scroll_sensitivity:       float = 0.15
var effort_cone_fraction:     float = 0.6
var effort_time_threshold:    float = 0.5

var _grabbed:               RigidBody3D = null
var _grabbed_grab_point:    Node3D      = null
var _is_rotating:           bool        = false

var _line_mesh:         MeshInstance3D = null
var _is_charging_throw: bool           = false
var _throw_charge:      float          = 0.0
var _effort_timer:      float          = 0.0
var _is_high_effort:    bool           = false

var _controlled:           ControllableInteractable = null
## Lo que se sostiene (el manual, el teléfono): se toma con un clic y se suelta con otro, o por irse de rango.
var _held:                 HeldInteractable         = null
var _entity_instantiation: EntityInstantiation      = null

var detector: InteractionDetector = null

var interact_dist_max: float = 0.0
var grab_dist_max:     float = 0.0
var grip_dist_max:     float = 0.0
var grab_dist_min:     float = 0.0

signal high_effort_started()
signal high_effort_ended()

## De quién son las manos: su intención trae los botones (ver CharacterIntent, LAS MANOS) y en ragdoll no se interactúa.
var who: BoneInstantiator = null
var _was_use := false
var _was_throw := false
var _was_turn := false


func setup(rb: CollisionObject3D, cam: Node3D, arms: ArmsController, anim: AnimationModifiers, max_reach: float, inst: EntityInstantiation, owner_bi: BoneInstantiator = null) -> void:
	who = owner_bi
	char_rigidbody        = rb
	player_camera         = cam
	arms_controller       = arms
	anim_mod              = anim
	_entity_instantiation = inst
	_update_grab_strength()

	detector = InteractionDetector.new()
	add_child(detector)
	detector.setup(rb, cam, rb.get_parent() as BoneInstantiator)
	detector.can_use = _can_use

	set_reach(max_reach)

## Re-apunta el IC (persistente) a un esqueleto nuevo tras un respawn/switch: refs de cápsula,
## cámara, brazos, anim y el detector. El IC y su detector sobreviven; solo se re-vinculan.
func rebind(rb: CollisionObject3D, cam: Node3D, arms: ArmsController, anim: AnimationModifiers, max_reach: float, inst: EntityInstantiation, owner_bi: BoneInstantiator = null) -> void:
	if owner_bi != null:
		who = owner_bi
	char_rigidbody        = rb
	player_camera         = cam
	arms_controller       = arms
	anim_mod              = anim
	_entity_instantiation = inst
	_update_grab_strength()
	set_reach(max_reach)
	if is_instance_valid(detector):
		detector.rebind(rb, cam, rb.get_parent() as BoneInstantiator)

func set_reach(max_reach: float) -> void:
	interact_dist_max = max_reach * 0.85
	grab_dist_max     = max_reach * 0.9
	grab_dist_min     = max_reach * 0.1
	grip_dist_max     = max_reach * 1.0
	if is_instance_valid(detector):
		detector.set_reach(interact_dist_max)

func set_entity_instantiation(inst: EntityInstantiation) -> void:
	_entity_instantiation = inst
	_update_grab_strength()

## Lo que tiene en la mano, sea lo que sea —algo que sostiene, un control, el cuerpo que agarra—, o null.
func engaged() -> Node:
	if is_instance_valid(_held):
		return _held
	if is_instance_valid(_controlled):
		return _controlled
	if is_instance_valid(_grabbed):
		return _grabbed
	return null

func get_camera_sensitivity_factor() -> float:
	if is_instance_valid(_controlled):
		return _controlled.camera_sensitivity_factor
	if is_instance_valid(_held):
		return _held.look_scale()
	return 1.0

func get_hovered_rb() -> RigidBody3D:
	var h := detector.get_hovered() if is_instance_valid(detector) else null
	if h is GrabbableInteractable:
		return h.get_parent() as RigidBody3D
	return null

func get_throw_charge_normalized() -> float:
	return _throw_charge / LocomotionCommon.base().throw_charge_s

func is_charging_throw() -> bool:
	return _is_charging_throw

## LOS BOTONES DE LAS MANOS (ver CharacterIntent, LAS MANOS): lo que cambió desde el cuadro anterior. En ragdoll no se
## agarra, ni se carga, ni se activa (ver character-parametric:docs/technical/characters.md); soltar sí.
func _read_intent() -> void:
	if not is_instance_valid(who) or who.intent == null:
		return
	var intent := who.intent
	var able := not who._is_ragdolling()
	if intent.use != _was_use:
		_was_use = intent.use
		if not intent.use:
			release_interact()
		elif able:
			try_interact()
	if intent.throw != _was_throw:
		_was_throw = intent.throw
		if not intent.throw:
			release_throw()
		elif able:
			start_throw_charge()
	if intent.turn_held != _was_turn:
		_was_turn = intent.turn_held
		set_rotating(intent.turn_held)
	if intent.hand_motion != Vector2.ZERO:
		apply_grab_rotation(intent.hand_motion)
		apply_controlled_motion(intent.hand_motion)
		intent.hand_motion = Vector2.ZERO
	while absf(intent.reach_steps) >= 1.0:
		var step := signf(intent.reach_steps)
		adjust_distance(step)
		intent.reach_steps -= step
	if intent.activate:
		intent.activate = false
		if able:
			try_activate(who)


func update(delta: float) -> void:
	_read_intent()
	if is_instance_valid(detector):
		if not is_instance_valid(_grabbed) and not is_instance_valid(_controlled) and not is_instance_valid(_held):
			detector.update()

	_show_push_box()
	if _is_charging_throw:
		_throw_charge = min(_throw_charge + delta, LocomotionCommon.base().throw_charge_s)
		if is_instance_valid(anim_mod):
			anim_mod.set_throw_charge(_throw_charge / LocomotionCommon.base().throw_charge_s,
				-player_camera.global_transform.basis.z, is_instance_valid(_grabbed))
	# AL FINAL DEL EMPUJÓN, la suelta con el impulso.
	if is_instance_valid(_throw_pending):
		_throw_pending_s -= delta
		if _throw_pending_s <= 0.0:
			var thrown := _throw_pending
			_throw_pending = null
			if _grabbed == thrown:
				_stop_grab()
			_launch(thrown, _throw_pending_impulse)
			return

	# LO QUE SALIÓ DEL ÁRBOL SE SUELTA, antes de pedirle dónde está: se borra en este cuadro (una parcela del sandbox
	# que se rearma con eso en la mano) y no tiene posición ni red.
	if is_instance_valid(_held) and not _held.is_inside_tree():
		_held.release()  # `dropped` limpia
	if is_instance_valid(_controlled) and not _controlled.is_inside_tree():
		_stop_control()

	if is_instance_valid(_held):
		var origin := _get_interaction_origin()
		if _held.is_out_of_range(origin, grip_dist_max):
			_held.release()  # se le escapa de la mano; `dropped` limpia
			return
		_want_grab(_held, _held.get_nearest_handle_point(origin))
		return

	if is_instance_valid(_controlled):
		var handle     := _controlled.get_nearest_handle_point(_get_interaction_origin())
		var ctrl_world := handle.global_position if is_instance_valid(handle) else _controlled.global_position
		if _controlled != _mode and _is_out_of_reach(ctrl_world):
			_stop_control()
			return
		_want_grab(_controlled, handle)
		_update_debug_line()
		return

	if not is_instance_valid(_grabbed):
		_reset_effort()
		return

	_update_hold()
	if not is_instance_valid(_grabbed):
		return
	_update_carry_speed()
	_update_effort_zone(delta)
	var grabbable := _get_grabbable(_grabbed)
	if is_instance_valid(grabbable):
		_want_grab(grabbable, _grabbed_grab_point)
	_update_debug_line()

func stop_all() -> void:
	_throw_pending = null
	_stop_grab()
	_stop_control()
	_stop_held()
	if is_instance_valid(detector):
		detector.force_clear()
	cancel_throw()

func cancel_throw() -> void:
	_is_charging_throw = false
	_throw_charge      = 0.0
	if is_instance_valid(anim_mod):
		anim_mod.cancel_throw()

# ── Control ───────────────────────────────────────────────────────────────────

func _start_control(ctrl: ControllableInteractable) -> void:
	_controlled = ctrl
	if not ctrl.control_lost.is_connected(_on_control_lost):
		ctrl.control_lost.connect(_on_control_lost)
	var origin := _get_interaction_origin()
	var handle := ctrl.get_nearest_handle_point(origin)
	# Con qué mira y qué agarró: el control lee el mouse como intención desde ahí (ver ControllableInteractable).
	ctrl.grab_view = player_camera
	ctrl.grab_point = handle
	_controlled.start_control()
	_want_grab(ctrl, handle, true)  # y que los proxies muevan los brazos al handle

func _stop_control() -> void:
	if is_instance_valid(_mode) and _mode == _controlled:
		var leaving := _mode
		_mode = null
		leaving.exit_mode()
	if is_instance_valid(_controlled):
		if _controlled.control_lost.is_connected(_on_control_lost):
			_controlled.control_lost.disconnect(_on_control_lost)
		_controlled.stop_control()
	_controlled = null
	if is_instance_valid(_line_mesh):
		_line_mesh.queue_free()
		_line_mesh = null
	_want_grab(null, null, true)

## El host me negó el control (perdí la carrera por el mismo control): soltar.
func _on_control_lost() -> void:
	_stop_control()

# ── Held (manual, teléfono) ───────────────────────────────────────────────────

## Toma el objeto y le manda las manos. ⚠ No avisa a los proxies (`send_grab`): en las otras máquinas la
## pieza no viaja todavía, y sus brazos irían a buscarla a su lugar.
func _start_held(held: HeldInteractable) -> void:
	if not held.take(player_camera):
		return
	_held = held
	held.dropped.connect(_on_held_dropped, CONNECT_ONE_SHOT)
	var origin := _get_interaction_origin()
	_want_grab(held, held.get_nearest_handle_point(origin))

## Lo suelta. La limpieza es la de `_on_held_dropped`, que es por donde salen también el rango y el host.
func _stop_held() -> void:
	if is_instance_valid(_held):
		_held.release()

func _on_held_dropped() -> void:
	_held = null
	_want_grab(null, null)

# ── Grab ──────────────────────────────────────────────────────────────────────

func _start_grab(grabbable: GrabbableInteractable) -> void:
	var rb := grabbable.get_parent() as RigidBody3D
	if not is_instance_valid(rb):
		return
	_grabbed = rb
	_grab_turn = Vector2.ZERO
	# Si el objeto está sincronizado, avisamos que lo agarramos (el host maneja autoridad/co-grabbers).
	var net := _net_body_of(rb)
	if is_instance_valid(net):
		net.begin_grab()
	var origin          := _get_interaction_origin()
	_grabbed_grab_point  = grabbable.get_nearest_grab_point(origin)
	_grabbed.sleeping      = false
	GrabbableInteractable.ignore_holder(_grabbed, char_rigidbody, true)
	if not grabbable.struck.is_connected(_on_struck):
		grabbable.struck.connect(_on_struck)
	_want_grab(grabbable, _grabbed_grab_point, true)  # y que los proxies muevan los brazos

## LO QUE LLEVO LO GOLPEARON: me llega a mí (ver GrabbableInteractable, LOS GOLPES A LO QUE SE LLEVA).
func _on_struck(impulse: Vector3) -> void:
	GrabbableInteractable.strike_holder(char_rigidbody, impulse)

func _stop_grab() -> void:
	_reset_effort()
	if is_instance_valid(_grabbed):
		# Soltamos la mano en el solver: local si simulamos el cuerpo, o avisándole al que lo simula
		# (si no, seguiría tirando hasta que la mano expire por timeout).
		var grabbable := _get_grabbable(_grabbed)
		var net := _net_body_of(_grabbed)
		if is_instance_valid(net) and multiplayer.has_multiplayer_peer() and not net.is_multiplayer_authority():
			net.send_grab_release()
		elif is_instance_valid(grabbable):
			grabbable.clear_hold(_hold_key())
		if is_instance_valid(grabbable) and grabbable.struck.is_connected(_on_struck):
			grabbable.struck.disconnect(_on_struck)
		GrabbableInteractable.ignore_holder(_grabbed, char_rigidbody, false)
		# Avisamos que soltamos (el host promueve autoridad al que quede, o vuelve al host).
		if is_instance_valid(net):
			net.end_grab()
	_grabbed            = null
	_grabbed_grab_point = null
	_is_rotating        = false
	_set_carry_speed(1.0)
	if is_instance_valid(_line_mesh):
		_line_mesh.queue_free()
		_line_mesh = null
	_want_grab(null, null, true)

## No aplicamos fuerzas: registramos nuestra MANO (dónde agarramos y hacia dónde tiramos) y el
## solver del grabbable las junta todas y resuelve una vez. Si el cuerpo está sincronizado y no
## somos su autoridad, la mano viaja como intención a quien lo simula.
func _update_hold() -> void:
	if not is_instance_valid(_grabbed):
		_grabbed = null
		return
	var grabbable := _get_grabbable(_grabbed)
	if not is_instance_valid(grabbable):
		_stop_grab()
		return
	var origin     := _get_interaction_origin()
	var cam_fwd    := -player_camera.global_transform.basis.z
	# A LA DISTANCIA DE TODOS (ver LocomotionCommon.hold_reach), y lo que cuenta para soltarlo es por donde se lleva (ver
	# GrabbableInteractable.held_world).
	var target_pos := origin + GrabbableInteractable.held_aim(cam_fwd) * LocomotionCommon.base().held_reach(anim_mod)
	var grab_world := _grabbed_grab_point.global_position if is_instance_valid(_grabbed_grab_point) else _grabbed.global_position
	var held_at := grabbable.held_world(_hold_key())
	if not held_at.is_finite():
		held_at = grab_world
	var in_cone := grabbable.cone_point(_hold_key())
	if _is_out_of_reach(held_at) or (in_cone.is_finite()
			and GrabbableInteractable.outside_carry_cone(char_rigidbody, origin, cam_fwd, in_cone)):
		_stop_grab()
		return

	# El origen (pecho) viaja con la mano: el solver lo usa para orientar el objeto de modo que la
	# parte que agarraste quede de frente al agarrador.
	var offset := _grabbed.to_local(grab_world)

	var net := _net_body_of(_grabbed)
	if is_instance_valid(net) and multiplayer.has_multiplayer_peer() and not net.is_multiplayer_authority():
		net.send_grab_intent(offset, target_pos, origin, grab_strength)
		return
	grabbable.set_hold(_hold_key(), offset, target_pos, origin, grab_strength)
	grabbable.set_turn(_hold_key(), _grab_turn)

## LO QUE LLEVO ME FRENA, según la carga: el peso del objeto contra la fuerza de todas las manos que lo
## sostienen (dos que lo llevan juntos van más rápido). ⚠ En red la suma la conoce sólo quien simula el
## cuerpo; las otras máquinas no tienen las manos y cuentan sólo la propia, así que entre dos de ellas cada
## uno se frena como si lo llevara solo (pendiente del agarre en red).
func _update_carry_speed() -> void:
	var strength := maxf(_get_grabbable(_grabbed).total_strength(), grab_strength)
	_set_carry_speed(GrabbableInteractable.carry_speed_factor(
		GrabbableInteractable.load_of(_grabbed.mass, strength)))

## SOLTAR VALE CON EL CUERPO YA BORRADO: un personaje que se rearma (un panel del sandbox que lo reconstruye) suelta lo
## que llevaba después de que su cuerpo viejo se fue (ver ExhibitOperator._hands_ready), así que lo que el soltar le hace
## al cuerpo —frenarlo, avisarle a la red— se salta si ya no está.
func _set_carry_speed(factor: float) -> void:
	if is_instance_valid(char_rigidbody) and char_rigidbody is CharacterRigidBody3D:
		(char_rigidbody as CharacterRigidBody3D).carry_speed_factor = factor

## DE QUIÉN ES LA MANO en el solver de lo que se agarra (ver GrabbableInteractable.set_hold): 0, la del jugador de esta
## máquina (su id de red); un guion pone la de su personaje (ver ExhibitOperator, LAS MANOS), así dos que llevan lo mismo
## son dos manos.
var hand_key := 0

## Identifica nuestra mano en el registro del grabbable.
func _hold_key() -> int:
	if hand_key != 0:
		return hand_key
	return multiplayer.get_unique_id() if multiplayer.has_multiplayer_peer() else GrabbableInteractable.LOCAL_HOLD

func _release_throw() -> void:
	var dir := -player_camera.global_transform.basis.z
	var t   := _throw_charge / LocomotionCommon.base().throw_charge_s

	# Objetivo: lo que tengo agarrado (throw); con las manos vacías, todo lo de la caja del empujón (ver EL EMPUJÓN).
	var target: RigidBody3D = _grabbed
	if not is_instance_valid(target):
		_push_all(dir, t)
		if is_instance_valid(anim_mod):
			anim_mod.trigger_throw_push(dir)
		_is_charging_throw = false
		_throw_charge      = 0.0
		return

	# UNA CAJA EN LAS MANOS: el pase de pecho, la empuja y la suelta al final (ver LocomotionCommon, TIRAR).
	if is_instance_valid(target) and target == _grabbed and not (target is CharacterRigidBody3D) \
			and is_instance_valid(anim_mod):
		_throw_pending = target
		_throw_pending_impulse = dir * _throw_impulse() * t
		_throw_pending_s = LocomotionCommon.base().throw_push_s
		anim_mod.trigger_throw_push(dir, true)
		_is_charging_throw = false
		_throw_charge      = 0.0
		return
	_stop_grab()  # soltar el grab (si había): la autoridad de la caja vuelve al host antes de lanzar
	if is_instance_valid(target):
		var impulse: Vector3
		if target is CharacterRigidBody3D:
			# Empujar a un compañero: knockback por VELOCIDAD (impulso = masa·vel) → trastabilla
			# parecido sin importar su peso. Un empujón lo despide un poco para atrás.
			impulse = dir * target.mass * _push_speed() * t
		else:
			# Lanzar un OBJETO: impulso FIJO (esfuerzo del brazo). Δv = impulso/masa → lo liviano
			# vuela lejos, lo pesado apenas se despega y cae cerca. throw_strength lo escala.
			impulse = dir * _throw_impulse() * t
		_launch(target, impulse)

	if is_instance_valid(anim_mod):
		anim_mod.trigger_throw_push(dir)
	_is_charging_throw = false
	_throw_charge      = 0.0

## ── EL EMPUJÓN: UNA CAJA ADELANTE (04/11/2026, el usuario: «una zona que empuja al frente tuyo donde estás
## mirando… mucho más permisiva»; «directamente una caja»; «todo lo que está adentro») ─────────────────────────────
## Con las manos vacías, la R empuja TODO lo que haya en una caja delante del pecho, hacia donde mira en el plano:
## `PUSH_BOX_WIDTH` de ancho, el alcance más `PUSH_BOX_EXTRA` de largo, `PUSH_BOX_HEIGHT` de alto. A cada uno lo mismo,
## sin repartir: a un personaje, el cambio de velocidad de siempre (`_push_speed`: el liviano sale más despedido sin
## agregar nada); a lo suelto —un paquete—, el impulso del tiro por `PUSH_OBJECT_SHARE`. No a un caído. Mientras se
## carga, la caja se dibuja en el piso (`push_box_view`). Lo mismo para el jugador y los dummies (ExhibitOperator.push).
## *Hasta entonces empujaba sólo al que tenía en la mira, con el contorno puesto.*
const PUSH_BOX_WIDTH := 1.0
const PUSH_BOX_EXTRA := 0.3
const PUSH_BOX_HEIGHT := 1.9
const PUSH_OBJECT_SHARE := 0.5


## La caja del empujón de quien tiene el pecho en `origin` y mira hacia `look`: su transform (en el centro) y su tamaño.
static func push_box(origin: Vector3, look: Vector3, reach: float) -> Array:
	var flat := Vector3(look.x, 0.0, look.z)
	flat = flat.normalized() if flat.length_squared() > 0.0001 else Vector3.FORWARD
	var size := Vector3(PUSH_BOX_WIDTH, PUSH_BOX_HEIGHT, reach + PUSH_BOX_EXTRA)
	var center := origin + flat * (size.z * 0.5) + Vector3.DOWN * (PUSH_BOX_HEIGHT * 0.5 - 0.35)
	return [Transform3D(Basis.looking_at(flat), center), size]


## Lo que se puede empujar adentro de la caja: personajes de pie y cuerpos sueltos; sin `exclude` (el que empuja).
static func bodies_in_push_box(world: World3D, box: Array, exclude: Array[RID]) -> Array[RigidBody3D]:
	var shape := BoxShape3D.new()
	shape.size = box[1]
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = box[0]
	query.collision_mask = 0xFFFFFFFF
	query.exclude = exclude
	var out: Array[RigidBody3D] = []
	for hit: Dictionary in world.direct_space_state.intersect_shape(query, 32):
		var rb := hit.collider as RigidBody3D
		if rb == null or out.has(rb) or rb.freeze:
			continue
		if rb is CharacterRigidBody3D:
			var who := rb.get_parent() as BoneInstantiator
			if is_instance_valid(who) and who._is_ragdolling():
				continue
		elif _part_of_a_character(rb):
			continue
		out.append(rb)
	return out


## Si `body` es un hueso del ragdoll de alguien (esos no se empujan: se empuja al personaje).
static func _part_of_a_character(body: Node) -> bool:
	var at := body.get_parent()
	while at != null:
		if at is BoneInstantiator:
			return true
		at = at.get_parent()
	return false


## La caja del empujón, dibujada en el piso: una placa de su tamaño, translúcida. Quien la usa la pone y la saca.
static func push_box_view() -> MeshInstance3D:
	var view := MeshInstance3D.new()
	var plate := BoxMesh.new()
	plate.size = Vector3(1.0, 0.02, 1.0)
	view.mesh = plate
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.55, 0.2, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	view.material_override = mat
	view.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	view.top_level = true
	view.visible = false
	return view


## Pone la placa de `view` en el piso de la caja `box`.
static func place_push_box_view(view: MeshInstance3D, box: Array, floor_y: float) -> void:
	var xform: Transform3D = box[0]
	var size: Vector3 = box[1]
	view.global_transform = Transform3D(xform.basis.scaled(Vector3(size.x, 1.0, size.z)),
		Vector3(xform.origin.x, floor_y + 0.02, xform.origin.z))


## EL EMPUJÓN DEL JUGADOR (ver EL EMPUJÓN): todo lo de su caja, con lo cargado `t`.
func _push_all(dir: Vector3, t: float) -> void:
	for body in bodies_in_push_box(char_rigidbody.get_world_3d(), _my_push_box(), _my_rids()):
		var flat := Vector3(dir.x, 0.0, dir.z).normalized()
		if body is CharacterRigidBody3D:
			_launch(body, flat * body.mass * _push_speed() * t)
		else:
			_launch(body, flat * _throw_impulse() * PUSH_OBJECT_SHARE * t)


func _my_push_box() -> Array:
	return push_box(_get_interaction_origin(), -player_camera.global_transform.basis.z, grip_dist_max)


## El cuerpo propio y los huesos de su ragdoll: lo que el empujón no se lleva.
func _my_rids() -> Array[RID]:
	var out: Array[RID] = [char_rigidbody.get_rid()]
	var bi := char_rigidbody.get_parent() as BoneInstantiator
	if is_instance_valid(bi) and is_instance_valid(bi.ragdoll_util):
		for rid in bi.ragdoll_util._ragdoll_rids:
			out.append(rid)
	return out


## La caja del empujón, a la vista mientras se carga con las manos vacías.
var _push_view: MeshInstance3D = null

func _show_push_box() -> void:
	var charging := _is_charging_throw and not is_instance_valid(_grabbed) and is_instance_valid(char_rigidbody)
	if charging and not is_instance_valid(_push_view):
		_push_view = push_box_view()
		add_child(_push_view)
	if not is_instance_valid(_push_view):
		return
	_push_view.visible = charging
	if charging:
		var bi := char_rigidbody.get_parent() as BoneInstantiator
		var floor_y := char_rigidbody.global_position.y - 1.0
		if is_instance_valid(bi):
			var s := bi.skel_sizes_util
			floor_y = bi.get_interaction_origin().y - (s.leg_height + s.torso_height) * (1.0 - 0.35 * bi.crouch_t)
		place_push_box_view(_push_view, _my_push_box(), floor_y)


## Aplica un impulso al objetivo, ruteando según qué es: caja sincronizada (sobrevive el handoff),
## compañero (se lo mando a su máquina), o cuerpo suelto/offline (impulso directo). Ver multiplayer.md (B).
func _launch(rb: RigidBody3D, impulse: Vector3) -> void:
	if not is_instance_valid(rb):
		return
	var net := _net_body_of(rb)
	if is_instance_valid(net):
		net.throw_body(impulse)
		return
	if rb is CharacterRigidBody3D:
		var target_bi := rb.get_parent() as BoneInstantiator
		if is_instance_valid(target_bi) and is_instance_valid(target_bi.net_sync):
			target_bi.net_sync.push(impulse)
			return
	rb.apply_central_impulse(impulse)
	if rb is CharacterRigidBody3D:
		(rb as CharacterRigidBody3D).push(impulse / rb.mass)  # adentro de la meca, con nombre (ver EL MARCO)

func _get_interaction_origin() -> Vector3:
	var bi := char_rigidbody.get_parent() as BoneInstantiator
	if not is_instance_valid(bi):
		return player_camera.global_position
	return bi.get_interaction_origin()

func _get_grabbable(rb: RigidBody3D) -> GrabbableInteractable:
	for child in rb.get_children():
		if child is GrabbableInteractable:
			return child as GrabbableInteractable
	return null

func _net_body_of(rb: RigidBody3D) -> NetBody:
	for child in rb.get_children():
		if child is NetBody:
			return child as NetBody
	return null

## LAS MANOS, A `target` (o a ninguna parte): como cualquier personaje, por su intención (ver CharacterIntent.grab); los
## brazos los mueve el cuerpo. `point`, el punto de agarre que eligió. `tell`, avisarle a los proxies.
func _want_grab(target: Node, point: Node3D, tell := false) -> void:
	var bi := char_rigidbody.get_parent() as BoneInstantiator if is_instance_valid(char_rigidbody) else null
	if is_instance_valid(bi):
		bi.intent.grab = target
		bi.intent.grab_point = point
	if tell:
		var ns := _char_net_sync()
		if is_instance_valid(ns):
			ns.send_grab(target)


func _char_net_sync() -> CharacterNetSync:
	if not is_instance_valid(char_rigidbody):
		return null
	var bi := char_rigidbody.get_parent() as BoneInstantiator
	return bi.net_sync if is_instance_valid(bi) else null

# ── Debug line ────────────────────────────────────────────────────────────────

func _get_reach_color(dist: float) -> Color:
	if dist <= interact_dist_max: return Color(0.0, 1.0, 0.0)
	if dist <= grab_dist_max:     return Color(1.0, 1.0, 0.0)
	if dist <= grip_dist_max:     return Color(1.0, 0.5, 0.0)
	return Color(1.0, 0.0, 0.0)

func _update_debug_line() -> void:
	if is_instance_valid(_line_mesh):
		_line_mesh.queue_free()
		_line_mesh = null
	if not show_grab_curve or not debug_line:
		return
	var origin := _get_interaction_origin()
	var target := Vector3.ZERO
	if is_instance_valid(_grabbed):
		target = _grabbed_grab_point.global_position if is_instance_valid(_grabbed_grab_point) else _grabbed.global_position
	elif is_instance_valid(_controlled):
		var handle := _controlled.get_nearest_handle_point(origin)
		target = handle.global_position if is_instance_valid(handle) else _controlled.global_position
	else:
		return
	var color := _get_reach_color(origin.distance_to(target))
	_line_mesh = DebugUtil.create_debug_path3d([
		{ "pos": origin, "in": Vector3.ZERO, "out": Vector3.ZERO },
		{ "pos": target, "in": Vector3.ZERO, "out": Vector3.ZERO }
	], 2, color, 0.01)
	get_tree().current_scene.add_child(_line_mesh)

# ── Effort ────────────────────────────────────────────────────────────────────

func _update_effort_zone(delta: float) -> void:
	var origin     := _get_interaction_origin()
	var cam_fwd    := -player_camera.global_transform.basis.z
	var grab_world := _grabbed_grab_point.global_position if is_instance_valid(_grabbed_grab_point) else _grabbed.global_position
	var to_grab    := (grab_world - origin).normalized()
	if to_grab.dot(cam_fwd) >= cos(deg_to_rad(grab_cone_half_angle * effort_cone_fraction)):
		_reset_effort()
	else:
		_effort_timer += delta
		if not _is_high_effort and _effort_timer >= effort_time_threshold:
			_is_high_effort = true
			high_effort_started.emit()

func _reset_effort() -> void:
	_effort_timer = 0.0
	if _is_high_effort:
		_is_high_effort = false
		high_effort_ended.emit()

func _update_grab_strength() -> void:
	if not is_instance_valid(_entity_instantiation):
		return
	var arch       := _entity_instantiation.arch_final
	grab_strength  = arch.strength

func _is_outside_cone(world_pos: Vector3) -> bool:
	var origin  := _get_interaction_origin()
	var cam_fwd := -player_camera.global_transform.basis.z
	var to_pos  := world_pos - origin
	if to_pos.length() <= 0.001:
		return false
	return to_pos.normalized().dot(cam_fwd) < cos(deg_to_rad(grab_cone_half_angle))

## A TIRO DE CLIC ES A TIRO DE USARLO (lo pidió el usuario, 11/10/2026): el detector sólo deja apuntar a lo que
## pasa esto, que es lo mismo que en `update` lo hace soltar. Había un rango intermedio donde el clic agarraba y en el
## cuadro siguiente se soltaba —sonaba el «alzar» y no venía nada—: un objeto que se sostiene se apuntaba hasta el
## 85 % del alcance desde la punta del pecho, y se soltaba a más de 1 m de su base (hoy, de su alcance); en el genérico ese
## 85 % llega a 0,96–1,12 m. Un control y lo que se agarra se sueltan pasando el alcance o fuera del cono, que el clic
## no miraba.
func _can_use(found: Interactable, point: Vector3) -> bool:
	if found is HeldInteractable:
		return not (found as HeldInteractable).is_out_of_range(_get_interaction_origin(), grip_dist_max)
	return not _is_out_of_reach(point)

func _is_out_of_reach(world_pos: Vector3) -> bool:
	var origin := _get_interaction_origin()
	var to_pos := world_pos - origin
	var dist   := to_pos.length()
	if dist > grip_dist_max:
		return true
	if dist <= 0.001:
		return false
	var cam_fwd := -player_camera.global_transform.basis.z
	return to_pos.normalized().dot(cam_fwd) < cos(deg_to_rad(grab_cone_half_angle))

# ── Input API ─────────────────────────────────────────────────────────────────

func try_interact() -> void:
	# Con algo en la mano, el clic es para soltarlo.
	if is_instance_valid(_held):
		_stop_held()
		return
	var hovered := detector.get_hovered() if is_instance_valid(detector) else null
	if not is_instance_valid(hovered): return
	if hovered is HeldInteractable:
		_start_held(hovered as HeldInteractable)
	elif hovered is GrabbableInteractable:
		_start_grab(hovered as GrabbableInteractable)
	elif hovered is ControllableInteractable:
		_start_control(hovered as ControllableInteractable)

func release_interact() -> void:
	_stop_grab()
	_stop_control()

## GIRAR LO QUE LLEVO (04/11/2026, el usuario: «meté lo de poder girar paquetes»): con el clic derecho apretado,
## el mouse gira lo que llevo en vez de la cámara —de costado lo gira alrededor de la vertical, para arriba y abajo lo
## da vuelta— (ver GrabbableInteractable, GIRAR LO QUE SE LLEVA). Lo girado se queda al soltar el clic, relativo a mí,
## y vuelve a cero al agarrar otra cosa. ⚠ En red sólo gira quien simula la caja: el giro no viaja con la intención.
const GRAB_TURN_PER_PX := 0.008
var _grab_turn := Vector2.ZERO

func set_rotating(value: bool) -> void:
	_is_rotating = value and is_instance_valid(_grabbed)
	_set_mode(value)


## ── EL MODO DE UN CONTROL (ver ControllableInteractable.has_mode) ─────────────────────────────────────────────────
## El clic derecho mantenido sobre un control con modo —el que se maneja o el que se mira— lo agarra (la mano va a él) y
## lo pone en su modo; al soltarlo sale y lo suelta. Mientras está, no se lo suelta por lejos ni por fuera del cono: él
## mismo se trae a la mano.
var _mode: ControllableInteractable = null


func _set_mode(on: bool) -> void:
	if on:
		if is_instance_valid(_mode) or is_instance_valid(_grabbed) or is_instance_valid(_held):
			return
		var found: Node = _controlled if is_instance_valid(_controlled) else (detector.get_hovered() if is_instance_valid(detector) else null)
		var ctrl := found as ControllableInteractable
		if ctrl == null or not ctrl.has_mode():
			return
		if ctrl != _controlled:
			_stop_control()
			_start_control(ctrl)
		_mode = ctrl
		ctrl.enter_mode()
	elif is_instance_valid(_mode):
		var leaving := _mode
		_mode = null
		leaving.exit_mode()
		if leaving == _controlled:
			_stop_control()


## Adónde se va la mirada: la del control en su modo; INF, libre.
func mode_look() -> Vector3:
	return _mode.mode_look() if is_instance_valid(_mode) else Vector3.INF

func apply_grab_rotation(relative: Vector2) -> void:
	if _is_rotating and is_instance_valid(_grabbed):
		_grab_turn += relative * GRAB_TURN_PER_PX

## EL MOUSE, PARA LO QUE SE TIENE EN LA MANO (ver HeldInteractable.handle_look): cuánto de él le queda a la vista, de 0 a
## 1; sin nada en la mano, todo.
func held_look(relative: Vector2) -> float:
	if is_instance_valid(_held):
		return _held.handle_look(relative)
	return 1.0

## EL CLIC DERECHO, PARA LO QUE SE TIENE EN LA MANO (ver HeldInteractable.handle_zoom).
func held_zoom(pressed: bool) -> void:
	if is_instance_valid(_held):
		_held.handle_zoom(pressed)

func apply_controlled_motion(relative: Vector2) -> void:
	if is_instance_valid(_controlled):
		_controlled.handle_mouse_motion(relative)

## LA RUEDITA: mueve un control o lo que se tiene en la mano. Lo que se lleva no (04/11/2026, el usuario: «eso yo
## pensé que lo había eliminado… habría que alargar los brazos excesivamente»): va a la distancia de todos (ver
## LocomotionCommon.hold_reach).
func adjust_distance(dir: float) -> void:
	if is_instance_valid(_controlled):
		_controlled.handle_scroll(dir)
	elif is_instance_valid(_held):
		_held.handle_scroll(dir)

func try_activate(bi: Node) -> void:
	var seated : bool = is_instance_valid(bi) and bi.is_seated
	if seated and is_instance_valid(bi.current_seat):
		bi.current_seat.activate(bi)
		return
	var hovered := detector.get_hovered() if is_instance_valid(detector) else null
	if hovered is ActivatableInteractable:
		(hovered as ActivatableInteractable).activate(bi)

func start_throw_charge() -> void:
	if _is_charging_throw: return
	_is_charging_throw = true
	_throw_charge = 0.0

func release_throw() -> void:
	if _is_charging_throw:
		_release_throw()
