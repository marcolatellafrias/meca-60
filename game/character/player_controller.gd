class_name PlayerController
extends Node

## ── EL JUGADOR DE ESTA MÁQUINA ──────────────────────────────────────────────────────────────────────────────────────
## El teclado y el mouse a la intención del cuerpo (ver CharacterIntent), la cámara en los ojos, la estamina, el HUD y la
## mira (sin estamina desde el 17/11/2026: la velocidad se gana acelerando, ver CharacterRigidBody3D); el ente del sandbox (movimiento directo) y el vuelo libre. Lo de prueba —el panel de depuración, tirarse,
## volver a nacer, los spawns— está en PlayerDebug, sólo con depuración.

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


var _was_ragdoll_active: bool = false


var _hud: PlayerHUD = null

var interaction_controller: InteractionController = null
var arms_controller: ArmsController = null

var _creative: bool = false
## Lo de prueba (ver PlayerDebug), sólo en un personaje con depuración.
var debug: PlayerDebug = null
## El puntito blanco del centro de la pantalla (ver Crosshair).
var _crosshair: Crosshair = null

## CADA VEZ QUE SE ARMA EL CUERPO (al nacer y al volver a nacer; lo llama BoneInstantiator.initialize_skeleton): lo que
## vive en el controlador se arma una sola vez (las manos, la mira, lo de prueba) y todo se vuelve a atar al cuerpo nuevo.
## El modo del mouse lo maneja UIState.
func on_skeleton_built(target: BoneInstantiator, cam: Camera3D) -> void:
	player_camera = cam
	if not is_ready:
		_construct_persistent(target, cam)
		is_ready = true
	rebind(target)
	take_camera()
	if target.debug_enabled:
		if not is_instance_valid(debug):
			debug = PlayerDebug.new()
			debug.controller = self
			add_child(debug)
		debug.on_skeleton_built()

## Lo que vive en el controlador y sobrevive a volver a nacer: las manos y la mira.
func _construct_persistent(target: BoneInstantiator, cam: Camera3D) -> void:
	interaction_controller = InteractionController.new()
	add_child(interaction_controller)
	var max_reach := target.skel_sizes_util.interaction_reach
	interaction_controller.setup(target.char_rigidbody, cam, target.arms_controller, target.anim_mod, max_reach, target.entity_instantiation, target)
	_crosshair = Crosshair.new()
	add_child(_crosshair)


## Re-vincula el controlador (persistente) al esqueleto target: refs de cápsula/brazos/anim, el
## InteractionController, reparenta la cámara y recrea el HUD. Único lugar donde se re-cablea:
## compartido por on_skeleton_built (nacer y volver a nacer) y PlayerDebug.switch_to (pasarse a otro cuerpo).
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

func _get_bi() -> BoneInstantiator:
	return char_rigidbody.get_parent() as BoneInstantiator if is_instance_valid(char_rigidbody) else null


func _get_arch() -> EntityArchetype:
	var bi := _get_bi()
	return bi.entity_instantiation.arch_final if is_instance_valid(bi) else null


func _get_ragdoll() -> RagdollUtil:
	var bi := _get_bi()
	return bi.ragdoll_util if is_instance_valid(bi) and is_instance_valid(bi.ragdoll_util) else null


func _is_ragdoll_active() -> bool:
	var rd := _get_ragdoll()
	return rd != null and (rd.is_active or rd.is_recovering)


func _input(event: InputEvent) -> void:
	if not is_ready:
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
				# La F, la G y la P (pasarse a otro cuerpo, tirarse, volver a nacer) son de prueba: ver PlayerDebug.

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

## LA CÁMARA DEL JUGADOR, la activa, y su cuerpo escondido en primera persona.
func take_camera() -> void:
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


## DE PIE, SIN NADA APRETADO: sin agacharse ni cargar el salto. Después de cambiar de cuerpo o de volver a nacer.
func reset_locomotion() -> void:
	_set_crouch(false)
	_drop_jump()
	_was_ragdoll_active = false
	if is_instance_valid(char_rigidbody):
		char_rigidbody.crouch_speed_factor = 1.0


## ── EL ENTE (ver CharacterKind.ente) ────────────────────────────────────────────────────────────────────────────────
## Con movimiento directo el teclado hace lo que hacía el ente del sandbox: turbo, salto sin carga, agachado más lento,
## y sentado mira con tope (`SEAT_LOOK`: hasta ahí gira la cabeza, la silla con ella). Sin las teclas de depuración.
const TURBO_TAP := 0.3
const SEAT_LOOK := Vector2(2.4, 1.3)
var _last_sprint_tap := -1.0
var _sprint_taps := 0


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


func apply_camera_pitch(pitch: float) -> void:
	camera_pitch = pitch
	if is_instance_valid(player_camera):
		player_camera.rotation.x = camera_pitch


# ── EL VUELO LIBRE ──────────────────────────────────────────────────────────────────────────────────────────────────

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
