class_name PlayerController
extends Node

var head_bone: CustomBone
var head_size: Vector3
## Lo que el hueso de la cabeza arranca adentro de ella (ver SkeletonSizesUtil.head_drop).
var head_drop := 0.0
var char_rigidbody: CharacterRigidBody3D
var player_camera: Camera3D
var is_ready: bool = false

## ADÓNDE MIRA, que es SU INTENCIÓN (ver CharacterIntent): el mouse la escribe, el cuerpo la sigue y la cámara también.
## El rumbo, en el mundo; la intención lo guarda en los ejes del marco (ver MotionFrame), así viaja solo con la meca.
var camera_pitch: float:
	get:
		var bi := _get_bi()
		return bi.intent.look_pitch if is_instance_valid(bi) else _pitch_alone
	set(value):
		_pitch_alone = value
		var bi := _get_bi()
		if is_instance_valid(bi):
			bi.intent.look_pitch = value
var camera_yaw: float:
	get:
		var bi := _get_bi()
		if not is_instance_valid(bi):
			return _yaw_alone
		return CharacterIntent.world_yaw(char_rigidbody.frame, bi.intent.look_yaw)
	set(value):
		_yaw_alone = value
		var bi := _get_bi()
		if is_instance_valid(bi):
			bi.intent.look_yaw = CharacterIntent.yaw_of(char_rigidbody.frame, Basis(Vector3.UP, value) * Vector3.FORWARD)
## Mientras no tiene cuerpo (entre que nace y se arma), lo que se le escribió.
var _pitch_alone := 0.0
var _yaw_alone := 0.0

## ── STAMINA ───────────────────────────────────────────────────────────────────────────────────────
## Se gasta corriendo y se recupera al soltar, después de `stamina_refractory_time`.
##
## Los números están puestos en TIEMPO, no en unidades: con el máximo en 5.0, el drenaje es
## `5 / segundos_de_sprint` y la regeneración `5 / segundos_de_recarga`.
##
##   sprint continuo  →  10 s        recarga completa  →  10 s
##
## El drenaje estaba en 0.01, o sea **500 segundos** de sprint: la barra existía pero nunca se vaciaba.
var stamina_max: float = 5.0
var stamina_drain_rate: float = 0.5
var stamina_regen_rate: float = 0.5
var stamina_refractory_time: float = 2.0
var _stamina: float = 5.0
## LO QUE OCUPAN LAS HERIDAS de la barra de estamina, de 0 a 1 desde el final, como en Peak: la estamina no puede pasar
## de lo que queda (ver CrewHealth, que lo escribe, y character-parametric:docs/conceptual/hud.md).
var injury: float = 0.0
var _refractory_timer: float = 0.0
var _was_sprinting: bool = false


var _was_ragdoll_active: bool = false


var _hud: PlayerHUD = null
var _impact_debug_hud: ImpactDebugHUD = null
var _prev_fall_rb: CharacterRigidBody3D = null

var interaction_controller: InteractionController = null
var arms_controller: ArmsController = null

var _creative: bool = false
var _debug_panel: DebugPanel = null
## LA TECLA DEL PANEL DE DEBUG: F9, la primera de los paneles globales del sandbox (ver docs/technical/sandbox.md): de
## F1 a F7 son de las filas, y la F8 detiene el juego. *Era la F1, y en una sesión de red chocaba con los paneles de
## fila.* La cambia quien arma el personaje.
var debug_panel_key: Key = KEY_F9
## El puntito blanco del centro de la pantalla (ver Crosshair).
var _crosshair: Crosshair = null

## Punto de entrada único cuando el BoneInstantiator (re)construye el esqueleto del jugador
## activo — tanto el build inicial como cada respawn. Construye lo persistente una sola vez
## (InteractionController, cámara de debug, HUD de impacto) y re-vincula el controlador al
## esqueleto nuevo. Lo llama BoneInstantiator.initialize_skeleton.
func on_skeleton_built(target: BoneInstantiator, cam: Camera3D) -> void:
	player_camera = cam
	if not is_ready:
		_construct_persistent(target, cam)
		is_ready = true
	rebind(target)
	_use_own_camera()
	if target.debug_enabled:
		_setup_debug_panel()  # refleja el personaje nuevo (se recrea adentro)
	# El mouse_mode lo maneja UIState (character-parametric:docs/technical/ui.md); acá no lo tocamos.

## Nodos que viven en el PlayerController y sobreviven a los respawns: se crean una sola vez.
func _construct_persistent(target: BoneInstantiator, cam: Camera3D) -> void:
	interaction_controller = InteractionController.new()
	add_child(interaction_controller)
	var max_reach := target.skel_sizes_util.interaction_reach
	interaction_controller.setup(target.char_rigidbody, cam, target.arms_controller, target.anim_mod, max_reach, target.entity_instantiation, target)

	# El panel de impactos (F1 → Acciones → Ver impactos), apagado hasta que lo prendan. Antes se armaba pero
	# nunca entraba al árbol: se actualizaba cada cuadro y no se veía.
	if not is_instance_valid(_impact_debug_hud):
		_impact_debug_hud = ImpactDebugHUD.create()
		_impact_debug_hud.visible = false
		add_child(_impact_debug_hud)

	# El puntito del centro, uno solo: `_construct_persistent` vuelve a correr en cada respawn.
	if not is_instance_valid(_crosshair):
		_crosshair = Crosshair.new()
		add_child(_crosshair)


## Re-vincula el controlador (persistente) al esqueleto target: refs de cápsula/brazos/anim, el
## InteractionController, reparenta la cámara y recrea el HUD. Único lugar donde se re-cablea:
## compartido por on_skeleton_built (build/respawn) y _switch_to (cambio de cuerpo en creative).
func rebind(target: BoneInstantiator) -> void:
	char_rigidbody  = target.char_rigidbody
	head_bone       = target.custom_bones_util.head
	head_size       = target.skel_sizes_util.head_size
	head_drop       = target.skel_sizes_util.head_drop
	arms_controller = target.arms_controller

	var max_reach := target.skel_sizes_util.interaction_reach
	if is_instance_valid(interaction_controller):
		interaction_controller.rebind(char_rigidbody, player_camera, arms_controller, target.anim_mod, max_reach, target.entity_instantiation, target)

	if is_instance_valid(player_camera):
		if is_instance_valid(player_camera.get_parent()):
			player_camera.get_parent().remove_child(player_camera)
		char_rigidbody.add_child(player_camera)
		target.player_camera   = player_camera
		player_camera.position = Vector3.ZERO
		player_camera.rotation = Vector3(camera_pitch, 0.0, 0.0)
		player_camera.current  = true

	if is_instance_valid(_hud):
		_hud.queue_free()
	_hud = PlayerHUD.create(target.entity_instantiation)
	char_rigidbody.add_child(_hud)

	_connect_fall_signal(char_rigidbody)

func _get_bi() -> BoneInstantiator:
	return char_rigidbody.get_parent() as BoneInstantiator if is_instance_valid(char_rigidbody) else null


func _get_arch() -> EntityArchetype:
	var bi := _get_bi()
	return bi.entity_instantiation.arch_final if is_instance_valid(bi) else null


func _connect_fall_signal(rb: CharacterRigidBody3D) -> void:
	if is_instance_valid(_prev_fall_rb) and is_instance_valid(_impact_debug_hud):
		if _prev_fall_rb.fall_triggered.is_connected(_impact_debug_hud.notify_fall_triggered):
			_prev_fall_rb.fall_triggered.disconnect(_impact_debug_hud.notify_fall_triggered)
	_prev_fall_rb = rb
	if is_instance_valid(_impact_debug_hud):
		rb.fall_triggered.connect(func(_d): _impact_debug_hud.notify_fall_triggered())


func _get_ragdoll() -> RagdollUtil:
	var bi := _get_bi()
	return bi.ragdoll_util if is_instance_valid(bi) and is_instance_valid(bi.ragdoll_util) else null


func _is_ragdoll_active() -> bool:
	var rd := _get_ragdoll()
	return rd != null and (rd.is_active or rd.is_recovering)


func _input(event: InputEvent) -> void:
	if not is_ready:
		return

	# F1 (F8 en el sandbox) abre/cierra el panel de debug — disponible siempre, incluso con overlay abierto.
	if is_instance_valid(_debug_panel) and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == debug_panel_key:
		_debug_panel.toggle()
		return

	# Con cualquier overlay abierto (pausa/menú/consola/debug) se bloquea el input de gameplay.
	if not UIState.gameplay_active():
		return

	var ic     := interaction_controller if is_instance_valid(interaction_controller) else null
	var bi     := _get_bi()
	var seated := is_instance_valid(bi) and bi.is_seated

	# V alterna creative (solo en gameplay; la tecla es CreativeFlight.TOGGLE_KEY, la misma del sandbox).
	if CreativeFlight.toggled(event) and not (seated and _direct()):
		_set_creative(not _creative)
		return

	# EL TURBO (ver CharacterRigidBody3D, MOVIMIENTO DIRECTO): dos toques de shift seguidos (cada uno a menos de
	# `TURBO_TAP` del anterior) dan el turbo, tres el segundo turbo; dura mientras se mantiene. Sólo con movimiento
	# directo, el del ente.
	if is_instance_valid(bi) and event.is_action_pressed("sprint") and not event.is_echo():
		var now := Time.get_ticks_msec() / 1000.0
		_sprint_taps = _sprint_taps + 1 if now - _last_sprint_tap < TURBO_TAP else 1
		_last_sprint_tap = now
		bi.intent.turbo = clampi(_sprint_taps - 1, 0, 2) if _direct() else 0
	elif is_instance_valid(bi) and event.is_action_released("sprint"):
		bi.intent.turbo = 0

	# ── Mouse motion ─────────────────────────────────────────────────────────
	if event is InputEventMouseMotion:
		if not _is_ragdoll_active():
			# La sensibilidad que eligió el jugador en Opciones (GameOptions), por encima de la del control que maneja.
			var sens := (ic.get_camera_sensitivity_factor() if ic else 1.0) * GameOptions.mouse_sensitivity
			if not (ic and (ic._is_rotating or ic.mode_look().is_finite())):
				apply_camera_pitch(clamp(camera_pitch - event.relative.y * 0.002 * sens, -1.2, 1.2))
				camera_yaw -= event.relative.x * 0.002 * sens
				_cap_seated_look(bi)
		# LAS MANOS SON BOTONES DE LA INTENCIÓN (ver CharacterIntent, LAS MANOS): el teclado los aprieta, el controlador los lee.
		if is_instance_valid(bi):
			bi.intent.hand_motion += event.relative

	# ── Mouse buttons ─────────────────────────────────────────────────────────
	elif event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if is_instance_valid(bi): bi.intent.use = event.pressed
			MOUSE_BUTTON_RIGHT:
				if is_instance_valid(bi): bi.intent.turn_held = event.pressed
			# La rueda emite un evento pressed y otro released por cada muesca: sin el guard de
			# pressed cada muesca aplicaría el paso dos veces (rotación y distancia de agarre).
			MOUSE_BUTTON_WHEEL_UP:
				if is_instance_valid(bi) and event.pressed: bi.intent.reach_steps -= 1.0
			MOUSE_BUTTON_WHEEL_DOWN:
				if is_instance_valid(bi) and event.pressed: bi.intent.reach_steps += 1.0

	# ── Keyboard ──────────────────────────────────────────────────────────────
	elif event is InputEventKey and not event.echo:
		if event.pressed:
			match event.keycode:
				# Movimiento
				KEY_SPACE:
					if _direct() and not (is_instance_valid(bi) and bi.intent.crouch) and not seated:
						char_rigidbody.jump_direct()  # el ente salta ya, sin carga
					elif is_instance_valid(bi):
						bi.intent.jump = true  # carga; al soltar, salta (ver BoneInstantiator, EL SALTO CARGADO)
				KEY_CTRL:
					if not seated and not _creative:
						_set_crouch(true)

				# Interacción
				KEY_E:
					if is_instance_valid(bi): bi.intent.activate = true
				# En ragdoll no se interactúa (ni clic, ni E, ni R): la carga no avanzaría —el update de la
				# interacción no corre— y al soltar quedaría el empujón a medias. Ver character-parametric:docs/technical/characters.md.
				KEY_R when not _direct():  # en el sandbox la R regenera la parcela
					if is_instance_valid(bi): bi.intent.throw = true
				# LAS TECLAS DE DEPURACIÓN, sólo con depuración (`debug_enabled`, el jugador del juego): en el sandbox la F es
				# del panel de la fila (ver design-sandbox.md), y ragdoll, respawn y el carnero son del juego.
				KEY_F when _debug_keys():
					if not seated:
						var hovered := ic.get_hovered_rb() if ic else null
						if is_instance_valid(hovered):
							var target_bi := _find_bone_instantiator(hovered)
							if target_bi and target_bi != bi:
								_switch_to(target_bi)

				# Físicas / debug
				KEY_G when _debug_keys(): _toggle_ragdoll()
				KEY_P when _debug_keys(): _respawn()


		else: # released
			match event.keycode:
				KEY_SPACE:
					_drop_jump()
				KEY_CTRL:
					_set_crouch(false)
				KEY_R when not _direct():
					if is_instance_valid(bi): bi.intent.throw = false


## LA CÁMARA SE DIBUJA CON LA CABEZA DEL CUADRO. La pose se resuelve una vez por cuadro dibujado, en el `_process` del
## personaje (ver BoneInstantiator, «Cuándo se resuelve la pose»), así que la cabeza que dejó el último paso de física es
## la del cuadro anterior: esto vuelve a poner la cámara después de todos los personajes (`process_priority`), con la
## cabeza recién resuelta. En `_physics_process` se pone igual, porque de ella sale el rayo de interacción.
func _init() -> void:
	process_priority = 1


func _process(_delta: float) -> void:
	if is_ready and is_instance_valid(head_bone) and is_instance_valid(player_camera) and not _is_ragdoll_active():
		_place_camera_at_head(_delta)


## LA CÁMARA, A LOS OJOS (ver FirstPersonView, la regla de todas las cámaras de primera persona): el ente, sin balanceo.
var _view := FirstPersonView.new()


func _place_camera_at_head(delta := 0.0) -> void:
	var bi := _get_bi()
	if not is_instance_valid(bi) or not is_instance_valid(char_rigidbody):
		return
	player_camera.global_position = _view.eye(bi, delta, 0.0 if _direct() else FirstPersonView.head_bob)


func _physics_process(delta: float) -> void:
	if not is_ready:
		return

	var ragdoll_active := _is_ragdoll_active()

	if ragdoll_active and not _was_ragdoll_active:
		if is_instance_valid(interaction_controller):
			interaction_controller.stop_all()
	_was_ragdoll_active = ragdoll_active

	_update_hud(delta)
	_write_move()

	if ragdoll_active:
		_update_ragdoll_camera(delta)
		return

	char_rigidbody.rotation.y = camera_yaw

	# La cámara del jugador se mueve también en tercera persona, aunque no esté en pantalla: de ella sale
	# el rayo de interacción, que tiene que ser el mismo en las dos vistas.
	_place_camera_at_head()
	_ease_to_mode_look(delta)
	apply_camera_pitch(camera_pitch)

	_process_stamina(delta)

	if is_instance_valid(interaction_controller):
		interaction_controller.update(delta)

	_update_hud_throw_jump()


## ADÓNDE VA, del teclado a su intención (ver CharacterIntent.move): el cuerpo lo hace. Quieto mientras haya un menú
## abierto (pausa, consola, debug): el mundo sigue simulando igual.
func _write_move() -> void:
	var bi := _get_bi()
	if not is_instance_valid(bi):
		return
	var live := UIState.gameplay_active()
	bi.intent.move = Vector2(Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_backward")) if live else Vector2.ZERO
	bi.intent.sprint = live and Input.is_action_pressed("sprint")


func _update_hud(delta: float) -> void:
	if not is_instance_valid(_hud):
		return
	var hvel := Vector3(char_rigidbody.linear_velocity.x, 0.0, char_rigidbody.linear_velocity.z)
	_hud.update_speed(hvel.length())
	_hud.update_stability(char_rigidbody.velocity_indicator, char_rigidbody.impact_xz, char_rigidbody.impact_y)

	if is_instance_valid(_impact_debug_hud) and _impact_debug_hud.visible:
		var bi := _get_bi()
		_impact_debug_hud.update_impact_debug(
			char_rigidbody.impact_xz,
			char_rigidbody.global_transform.basis,
			char_rigidbody.impact_y,
			char_rigidbody.linear_velocity,
			char_rigidbody._last_impact_world_dir,
			char_rigidbody.ragdoll_threshold,
			is_instance_valid(bi) and is_instance_valid(bi.ragdoll_util) and bi.ragdoll_util.is_active,
			is_instance_valid(bi) and is_instance_valid(bi.ragdoll_util) and bi.ragdoll_util.is_recovering,
			char_rigidbody._last_impact_xz_magnitude,
			max(char_rigidbody.max_speed_forward, char_rigidbody.max_speed_side) * char_rigidbody.sprint_multiplier,
			char_rigidbody.ragdoll_threshold,
			char_rigidbody._snapshot_capture_count,
			char_rigidbody._snapshot_flag_at_capture,
			char_rigidbody._snapshot_ragdoll_at_capture,
			char_rigidbody._snapshot_acc_before,
			char_rigidbody._snapshot_acc_after
		)


func _update_hud_throw_jump() -> void:
	if not is_instance_valid(_hud):
		return
	var throw_t  := interaction_controller.get_throw_charge_normalized() if is_instance_valid(interaction_controller) else 0.0
	_hud.update_throw(throw_t)
	var bi := _get_bi()
	_hud.update_jump(bi.jump_charge() if is_instance_valid(bi) else 0.0)


## TIRADO Y LEVANTÁNDOSE, los ojos los pone la misma regla (ver FirstPersonView); la mirada, la del mouse.
func _update_ragdoll_camera(_delta: float) -> void:
	var rd := _get_ragdoll()
	_place_camera_at_head(_delta)
	player_camera.global_rotation = Vector3(camera_pitch, camera_yaw, 0.0)
	if rd != null and rd.is_recovering:
		char_rigidbody.rotation.y = camera_yaw


## true cuando la cámara activa es la del jugador, o sea cuando hay que esconderle la cabeza y el torso. Lo lee
## BoneInstantiator al final de initialize_skeleton. *Hasta el 13/11/2026 había una cámara orbital de debug (el numpad).*
func is_first_person_view() -> bool:
	return true

## La cámara del jugador, la activa, y su cuerpo escondido en primera persona.
func _use_own_camera() -> void:
	if is_instance_valid(player_camera):
		player_camera.current = true
	var bi := _get_bi()
	if is_instance_valid(bi):
		bi.set_first_person_visibility(true)


## Suelta la barra espaciadora: si estaba cargando, salta (lo hace el cuerpo, ver BoneInstantiator, EL SALTO CARGADO).
func _drop_jump() -> void:
	var bi := _get_bi()
	if is_instance_valid(bi):
		bi.intent.jump = false


## AGACHARSE: lo hace el cuerpo (ver CharacterIntent.crouch, BoneInstantiator._update_crouch); el teclado sólo lo pide.
func _set_crouch(on: bool) -> void:
	var bi := _get_bi()
	if is_instance_valid(bi):
		bi.intent.crouch = on


func _toggle_ragdoll() -> void:
	var bi := _get_bi()
	if not is_instance_valid(bi) or not is_instance_valid(bi.ragdoll_util):
		return
	if bi.ragdoll_util.is_active:
		bi.ragdoll_util.deactivate(char_rigidbody, bi.custom_bones_util.lower_spine)
		char_rigidbody.rotation.y = camera_yaw
	elif bi.ragdoll_util.is_recovering:
		return  # ya te estás levantando: no se puede re-ragdollear (nada de G-spam). En el futuro el
				 # levantarse será por timer según arch.time_to_standup, no con G. Ver onfoot-gameplay.md.
	else:
		_leave_seat_in_place(bi)  # sentado y ragdoll son excluyentes: primero salir del asiento
		char_rigidbody.is_snapshot_active = false
		bi.ragdoll_util.activate(char_rigidbody, bi.custom_bones_util.lower_spine)


## Sale del asiento en el lugar, si estaba sentado. Lo llaman los cambios de estado que son
## MUTUAMENTE EXCLUYENTES con estar sentado: el ragdoll (G) y el respawn (P). Sentado, la cápsula
## queda inerte (colisión off, axis lock, input_enabled=false) y el asiento le presta una malla hija, así
## que entrar a cualquiera de esos estados sin salir primero deja un híbrido inválido — ragdollear
## sentado te mandaba a volar con la silla pegada (y los proxies la veían quieta en su lugar).
## El camino por impacto no necesita esto: BoneInstantiator._on_fall_triggered ya se niega a
## ragdollear si estás sentado.
func _leave_seat_in_place(bi: BoneInstantiator) -> void:
	var seat := bi.current_seat as SeatInteractable
	if is_instance_valid(seat):
		seat.release_occupant_in_place()


func _find_bone_instantiator(node: Node) -> BoneInstantiator:
	var current := node.get_parent()
	while current:
		if current is BoneInstantiator:
			return current
		current = current.get_parent()
	return null


func _switch_to(target: BoneInstantiator) -> void:
	var current_bi := _get_bi()
	var yaw := camera_yaw
	# LAS CLASES SE CAMBIAN: el que deja pasa a ser lo que era el otro, y el otro, el jugador (ver CharacterKind).
	var mine := current_bi.kind
	_set_kind(current_bi, target.kind)
	_set_kind(target, mine)
	current_bi.intent.move = Vector2.ZERO
	current_bi.intent.sprint = false

	rebind(target)  # cápsula, IC, cámara, HUD, fall signal — compartido con el respawn
	char_rigidbody.input_enabled = true
	camera_yaw = yaw
	char_rigidbody.rotation.y = camera_yaw
	_was_ragdoll_active = false

	# En primera persona la cabeza/torso los maneja la cámara: sacamos esos bones del animador.
	var bones_to_clear := [
		target.custom_bones_util.head,
		target.custom_bones_util.neck,
		target.custom_bones_util.chest,
		target.custom_bones_util.higher_spine,
	]
	for bone in bones_to_clear:
		if is_instance_valid(bone):
			target.procedural_animator.unregister_bone(bone)
	target.refresh_camera_animations()

	_set_crouch(false)
	_drop_jump()
	char_rigidbody.crouch_speed_factor = 1.0

	_use_own_camera()
	if is_instance_valid(interaction_controller):
		interaction_controller.stop_all()


## ── EL ENTE (ver CharacterKind.ente) ────────────────────────────────────────────────────────────────────────────────
## Con movimiento directo el teclado hace lo que hacía el ente del sandbox: turbo, salto sin carga, agachado más lento,
## y sentado mira con tope (`SEAT_LOOK`: hasta ahí gira la cabeza, la silla con ella). Sin las teclas de depuración.
const TURBO_TAP := 0.3
const SEAT_LOOK := Vector2(2.4, 1.3)
var _last_sprint_tap := -1.0
var _sprint_taps := 0


## Las teclas de depuración del juego (F, G, P, H, el numpad): sólo con depuración.
func _debug_keys() -> bool:
	var bi := _get_bi()
	return is_instance_valid(bi) and bi.debug_enabled


func _direct() -> bool:
	return is_instance_valid(char_rigidbody) and char_rigidbody.kind != null \
		and char_rigidbody.kind.motion == CharacterKind.Motion.DIRECT


## EL MODO DE UN CONTROL (ver ControllableInteractable.has_mode; el usuario, 17/11/2026: «tu cámara hace como un easing
## hacia adelante o hacia la posición en la cual se controla ese control»): mientras está, la mirada se va sola y suave
## hacia donde se lo maneja; el mouse queda para el control.
const MODE_EASE := 6.0


func _ease_to_mode_look(delta: float) -> void:
	if not is_instance_valid(interaction_controller) or not is_instance_valid(player_camera):
		return
	var target := interaction_controller.mode_look()
	if not target.is_finite():
		return
	var dir := (target - player_camera.global_position).normalized()
	var k := 1.0 - exp(-MODE_EASE * delta)
	camera_yaw = lerp_angle(camera_yaw, atan2(-dir.x, -dir.z), k)
	camera_pitch = lerpf(camera_pitch, asin(clampf(dir.y, -1.0, 1.0)), k)
	char_rigidbody.rotation.y = camera_yaw
	_cap_seated_look(_get_bi())


func _cap_seated_look(bi: BoneInstantiator) -> void:
	if not _direct() or not is_instance_valid(bi) or not bi.is_seated or not is_instance_valid(bi.current_seat):
		return
	var front := CharacterIntent.yaw_of(char_rigidbody.frame, -(bi.current_seat as Node3D).global_basis.z)
	bi.intent.look_yaw = front + clampf(angle_difference(front, bi.intent.look_yaw), -SEAT_LOOK.x, SEAT_LOOK.x)
	apply_camera_pitch(clampf(camera_pitch, -SEAT_LOOK.y, SEAT_LOOK.y))


## APAGADO O PRENDIDO (ver BoneInstantiator.set_active): sin cámara, sin mira y sin HUD mientras está apagado.
func set_active(on: bool) -> void:
	if is_instance_valid(player_camera):
		player_camera.current = on
	if is_instance_valid(_crosshair):
		_crosshair.visible = on
	if is_instance_valid(_hud):
		_hud.visible = on


## Le pone a `bi` la clase `kind`, también a su cápsula.
static func _set_kind(bi: BoneInstantiator, kind: CharacterKind) -> void:
	bi.kind = kind
	if is_instance_valid(bi.char_rigidbody):
		bi.char_rigidbody.kind = kind


func _respawn() -> void:
	var bi := _get_bi()
	if not bi:
		return

	# Salir limpio de todo estado que se aferra a la cápsula actual, ANTES de reconstruirla.
	if _creative:
		_set_creative(false)
	_leave_seat_in_place(bi)  # soltar YA (sincrónico) antes de reconstruir
	if is_instance_valid(bi.ragdoll_util) and bi.ragdoll_util.is_active:
		bi.ragdoll_util.deactivate(char_rigidbody, bi.custom_bones_util.lower_spine)
	if is_instance_valid(interaction_controller):
		interaction_controller.stop_all()  # suelta grab/control (y sincroniza grab_target null)

	var prev_pos := Vector3(char_rigidbody.global_position.x, 3.0, char_rigidbody.global_position.z)

	# Reconstruir el esqueleto con seed nueva. initialize_skeleton → on_skeleton_built → rebind
	# re-vincula todo (cápsula, IC, cámara, HUD); acá solo reposicionamos y reseteamos estado.
	bi.master_seed = DebugArchetype.respawn_seed()
	bi.initialize_skeleton()
	if is_instance_valid(bi.net_sync):
		bi.net_sync.broadcast_seed()  # multiplayer: reconstruir mi proxy en las demás máquinas

	char_rigidbody.global_position = prev_pos
	char_rigidbody.rotation.y      = camera_yaw

	# El esqueleto nuevo arranca limpio; reseteamos el estado de locomoción que vive acá.
	_set_crouch(false)
	_drop_jump()
	_was_ragdoll_active = false
	char_rigidbody.crouch_speed_factor = 1.0


func _process_stamina(delta: float) -> void:
	var is_sprinting := Input.is_action_pressed("sprint") \
		and Input.get_axis("move_forward", "move_backward") < 0.0 \
		and char_rigidbody.can_sprint

	var usable := stamina_max * (1.0 - clampf(injury, 0.0, 1.0))
	_stamina = minf(_stamina, usable)
	if is_sprinting:
		_stamina = max(0.0, _stamina - stamina_drain_rate * delta)
		if _stamina == 0.0:
			char_rigidbody.can_sprint = false
		_refractory_timer = stamina_refractory_time
		_was_sprinting = true
	else:
		if _was_sprinting:
			_was_sprinting = false
		if _refractory_timer > 0.0:
			_refractory_timer = max(0.0, _refractory_timer - delta)
		else:
			if not char_rigidbody.can_sprint:
				char_rigidbody.can_sprint = true
			_stamina = min(usable, _stamina + stamina_regen_rate * delta)

	if is_instance_valid(_hud):
		_hud.update_stamina(_stamina / stamina_max, injury, is_sprinting or _stamina < usable - 0.001)
		
func apply_camera_pitch(pitch: float) -> void:
	camera_pitch = pitch
	if is_instance_valid(player_camera):
		player_camera.rotation.x = camera_pitch


# ── Creative / debug ────────────────────────────────────────────────────────

## MUESTRA O ESCONDE EL PANEL DE IMPACTOS (el resorte, el umbral y el último golpe): lo usa el F9 del sandbox (ver
## BodyPanel), que no tiene el panel de depuración.
func show_impacts(on: bool) -> void:
	if is_instance_valid(_impact_debug_hud):
		_impact_debug_hud.visible = on


func impacts_shown() -> bool:
	return is_instance_valid(_impact_debug_hud) and _impact_debug_hud.visible


## PRENDE O APAGA EL VUELO LIBRE desde afuera (la V lo alterna): al subir a la meca con la U se apaga (ver PilotRide).
func set_creative(on: bool) -> void:
	_set_creative(on)


## EL MODO CREATIVO DESDE AFUERA (la B corta del sandbox, ver DesignSandbox): lo mismo que la V.
func toggle_creative() -> void:
	var bi := _get_bi()
	if not UIState.gameplay_active() or (is_instance_valid(bi) and bi.is_seated and _direct()):
		return
	_set_creative(not _creative)


func _set_creative(on: bool) -> void:
	if on == _creative:
		return
	_creative = on
	var bi := _get_bi()
	if on:
		# Force-exit ragdoll before flying (the capsule is frozen while ragdolled).
		if is_instance_valid(bi) and is_instance_valid(bi.ragdoll_util) \
				and (bi.ragdoll_util.is_active or bi.ragdoll_util.is_recovering):
			bi.ragdoll_util.deactivate(char_rigidbody, bi.custom_bones_util.lower_spine)
		if is_instance_valid(interaction_controller):
			interaction_controller.stop_all()
		_set_crouch(false)
		_drop_jump()
		char_rigidbody.set_creative_mode(true)
	else:
		char_rigidbody.set_creative_mode(false)
		char_rigidbody.rotation.y = camera_yaw


func _setup_debug_panel() -> void:
	# Se re-llama en cada respawn (desde on_skeleton_built): recreamos el panel para reflejar
	# el nuevo personaje (y no acumular paneles).
	if is_instance_valid(_debug_panel):
		_debug_panel.queue_free()
	_debug_panel = DebugPanel.new()
	add_child(_debug_panel)

	# ── Info (stats del personaje generado + mundo + red) ──
	var bi := _get_bi()
	if is_instance_valid(bi) and is_instance_valid(bi.entity_instantiation):
		_debug_panel.add_text("Info", _character_stats_text(bi.entity_instantiation))
	_debug_panel.add_info("Red", _net_status_text())

	# ── Acciones ──
	_debug_panel.add_action("Acciones", "Toggle creative (V)",      func(): _set_creative(not _creative))
	_debug_panel.add_action("Acciones", "Toggle ragdoll (G)",       _toggle_ragdoll)
	_debug_panel.add_action("Acciones", "Respawn (P)",              _respawn)
	if is_instance_valid(_impact_debug_hud):
		_debug_panel.add_toggle("Acciones", "Ver impactos", _impact_debug_hud.visible,
			func(on: bool) -> void: _impact_debug_hud.visible = on)
	# ── Arquetipos ──
	# Dos acciones por arquetipo, y son distintas: "Ser" cambia TU personaje y además deja la P pegada
	# a ese arquetipo (apretarla repetido da otra variación del mismo); "Spawnear" deja un NPC al lado
	# sin tocar la selección, para comparar dos siluetas a la vez.
	_debug_panel.add_text("Arquetipos", "P respawnea como: %s" % DebugArchetype.label())
	_debug_panel.add_action("Arquetipos", "Ser: aleatorio", func(): respawn_as(DebugArchetype.NONE))
	for a in EntityArchetype.Archetype.values():
		var be_name := str(EntityArchetype.Archetype.keys()[a])
		_debug_panel.add_action("Arquetipos", "Ser: %s" % be_name, func(): respawn_as(a))
	_debug_panel.add_action("Arquetipos", "Spawnear: aleatorio",
		func(): _debug_spawn_character(DebugArchetype.free_seed()))
	for b in EntityArchetype.Archetype.values():
		var spawn_name := str(EntityArchetype.Archetype.keys()[b])
		_debug_panel.add_action("Arquetipos", "Spawnear: %s" % spawn_name,
			func(): _debug_spawn_character(DebugArchetype.seed_for(b)))

	# ── Spawn ──
	_debug_panel.add_action("Spawn", "Go to start",        _go_to_start)
	_debug_panel.add_action("Spawn", "Character",          _debug_spawn_character)
	_debug_panel.add_action("Spawn", "Caja liviana ▪",     func(): _debug_spawn("box_light_square"))
	_debug_panel.add_action("Spawn", "Caja pesada ▪",      func(): _debug_spawn("box_heavy_square"))
	_debug_panel.add_action("Spawn", "Seat",               func(): _debug_spawn("seat"))
	_debug_panel.add_action("Spawn", "Limpiar spawns",     _clear_spawns)



func _character_stats_text(inst: EntityInstantiation) -> String:
	var arch := inst.arch_final
	var sizes := SkeletonSizesUtil.create(inst)
	var primary := str(EntityArchetype.Archetype.keys()[inst.archetype_type])
	var blend := "arch      (no blend)"
	if inst.archetype_blend > 0.0:
		blend = "secondary %s (%.0f%%)" % [
			str(EntityArchetype.Archetype.keys()[inst.secondary_archetype_type]),
			inst.archetype_blend * 100.0]
	var lines := [
		"seed      %d" % inst.master_seed,
		"arch      %s" % primary,
		blend,
		"%s  |  age %d" % [EntitySpecie.Specie.keys()[inst.specie_type], inst.age],
		"",
		# height y reach son DERIVADOS del modelo (SkeletonSizesUtil), ya no campos del arquetipo.
		"height    %.2f m" % sizes.total_height,
		"weight    %.1f kg" % arch.weight,
		"speed     %.1f" % arch.speed,
		"strength  %.2f" % arch.strength,
		"jump      %.2fm" % arch.jump_height,
		"arm       %.2f m  (reach %.2f)  k %.2f" % [sizes.arm_reach, sizes.interaction_reach, arch.arms_length],
		"leg       %.2f m                k %.2f" % [sizes.leg_height, arch.legs_length],
		"fatness   %.2f" % arch.fatness,
		"muscle    %.2f" % arch.muscularity,
	]
	return "\n".join(lines)


func _debug_spawn_pos() -> Vector3:
	var fwd := -player_camera.global_transform.basis.z
	return char_rigidbody.global_position + fwd * 2.5 + Vector3.UP


## Elige el arquetipo con el que respawnea la P, y respawnea ya. La elección QUEDA PEGADA: después
## alcanza con apretar P para ver otra variación del mismo arquetipo, que es el bucle de autoría.
## CAMBIARSE DE CUERPO a un arquetipo puntual, en el lugar. Es el camino de la P con el arquetipo
## elegido a mano, y es público porque lo usan los botones del panel de debug, que si lo reimplementaran
## perderían la limpieza del respawn — salir del asiento, desactivar el ragdoll, soltar lo que se tenga
## en la mano — y se irían separando de él en silencio.
func respawn_as(archetype: int) -> void:
	DebugArchetype.selected = archetype
	_respawn()


func _go_to_start() -> void:
	var spawner := get_tree().get_first_node_in_group("character_spawner")
	if spawner and spawner.has_method("respawn_local_at_start"):
		spawner.respawn_local_at_start()


func _net_status_text() -> String:
	if SessionManager.is_host and SessionManager.lobby_code != "":
		return "Host — código %s" % SessionManager.lobby_code
	if SessionManager.is_host:
		return "Host"
	if SessionManager.session_started and SessionManager.local_peer_id != 1:
		return "Cliente"
	return "Solo (local)"


## Deja un NPC parado al lado. No pasa por NetSpawner a propósito: es una ayuda de autoría para mirar
## dos siluetas juntas, no un objeto de la partida.
##
## Sin seed explícita usa la del arquetipo elegido en el panel; los botones "Spawnear: X" pasan la de
## un arquetipo puntual, que NO cambia la selección — así podés ser `kid` y rodearte de `buff`.
func _debug_spawn_character(character_seed: int = -1) -> void:
	var scene := load("res://game/character/player.tscn") as PackedScene
	if scene == null:
		return
	var inst := scene.instantiate() as BoneInstantiator
	if inst == null:
		return
	inst.master_seed = character_seed if character_seed >= 0 else DebugArchetype.respawn_seed()
	get_tree().current_scene.add_child(inst)
	inst.global_position = _debug_spawn_pos()


func _debug_spawn(type_name: String) -> void:
	var pos := _debug_spawn_pos()
	# El asiento es estático y se apoya en el piso. Las cajas son rigidbodies: caen solas.
	if type_name == "seat":
		pos = _snap_to_ground(pos)
	NetSpawner.request_spawn(type_name, Transform3D(Basis(), pos))

## Limpia todo lo spawneado (ver NetSpawner).
func _clear_spawns() -> void:
	NetSpawner.request_clear_all()

## Baja un punto hasta el piso con un raycast (para spawnear objetos estáticos apoyados).
func _snap_to_ground(from: Vector3) -> Vector3:
	var space := char_rigidbody.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(from + Vector3.UP, from + Vector3.DOWN * 20.0)
	q.exclude = [char_rigidbody.get_rid()]
	var hit := space.intersect_ray(q)
	return hit.position if hit else from
