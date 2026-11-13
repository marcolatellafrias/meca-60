class_name CharacterPossession
extends Node

## ── POSEER A UN PERSONAJE (13/11/2026) ──────────────────────────────────────────────────────────────────────────────
## Lo pidió el usuario: «ahora mismo no puedo poseer personajes… los dummies que están sentados en las sillas… que sea
## simple el sistema… si yo agarro, me levanto con el dummy y lo dejo ahí tirado en la meca, que si me salgo de la
## posesión, que queda ahí tirado». Con la O del sandbox (ver SandboxPossession) se posee a cualquiera que no sea el
## jugador y se simule —los maniquíes de las sillas, la gente de la fila Locomoción—.
##
## SIMPLE A PROPÓSITO: no se le cambia la clase (ver CharacterKind) ni se le pasa el control del jugador. El teclado y el
## mouse aprietan los botones de su intención (ver CharacterIntent), como hace un guion con CharacterActions, y las manos
## son las de CharacterActions (las del jugador, con un ojo en su cabeza). Por eso sigue siendo lo que era: va en el
## marco de la meca como antes, se choca y se cae igual. Al soltarlo se queda como quedó —parado, tirado o sentado— y
## no vuelve solo a su silla.

## Lo que gira la mirada por píxel de mouse (rad), como el jugador (ver PlayerController).
const MOUSE_RAD := 0.002
const PITCH_MAX := 1.2
## La tercera persona: detrás y arriba de la cabeza (m).
const THIRD_BACK := 3.2
const THIRD_UP := 0.6

var bi: BoneInstantiator = null
var active := false

var _actions: CharacterActions = null
var _view := FirstPersonView.new()
var _first := false
## El levantarse solo mientras se lo posee (como el jugador), y sólo si lo puso esto (ver `end`).
var _get_up: CharacterGetUp = null


## EL DE `who`, creado la primera vez.
static func of(who: BoneInstantiator) -> CharacterPossession:
	for child in who.get_children():
		if child is CharacterPossession:
			return child as CharacterPossession
	var possession := CharacterPossession.new()
	possession.name = "Posesion"
	possession.bi = who
	who.add_child(possession)
	return possession


## ¿Se lo puede poseer? Todo el que se simula y no es el jugador de esta máquina.
static func allowed(who: BoneInstantiator) -> bool:
	return who.kind != null and not who.kind.is_local() and who.kind.simulates()


func begin() -> void:
	active = true
	_actions = CharacterActions.of(bi)
	_actions.stop()
	_actions.drop()
	_actions.manual = true
	var has_get_up := false
	for child in bi.get_children():
		has_get_up = has_get_up or child is CharacterGetUp
	if not has_get_up:
		_get_up = CharacterGetUp.new()
		_get_up.bi = bi
		bi.add_child(_get_up)


## LO SUELTA COMO QUEDÓ: sin teclas apretadas, sin nada en las manos que no esté soltado, sin levantarse solo.
func end() -> void:
	active = false
	var intent := bi.intent
	intent.move = Vector2.ZERO
	intent.sprint = false
	intent.jump = false
	intent.crouch = false
	intent.use = false
	intent.throw = false
	intent.turn_held = false
	if is_instance_valid(_actions):
		_actions.manual = false
	if is_instance_valid(_get_up):
		_get_up.queue_free()
	_get_up = null
	if _first:
		_first = false
		bi.set_first_person_visibility(false)


func controls() -> PackedStringArray:
	return PackedStringArray([
		"WASD caminar · shift correr · espacio saltar (mantenido, más alto)",
		"Ctrl agacharse",
		"E sentarse en la silla que mira, o pararse · E usar",
		"clic izquierdo agarrar · R tirar · clic derecho girar lo agarrado · rueda acercar",
	])


## LA CÁMARA: en primera persona, en sus ojos; en tercera, detrás de la cabeza. Mirando hacia donde mira su intención,
## en los ejes de su marco (la meca).
func camera(first: bool, delta: float) -> Transform3D:
	if first != _first:
		_first = first
		bi.set_first_person_visibility(first)
	var rb := bi.char_rigidbody
	var frame_basis := rb.frame.global_basis.orthonormalized() if rb.frame != null else Basis()
	var look := frame_basis * Basis(Vector3.UP, bi.intent.look_yaw) * Basis(Vector3.RIGHT, bi.intent.look_pitch)
	var eye := _view.eye(bi, delta, FirstPersonView.head_bob)
	if first:
		return Transform3D(look, eye)
	var at := eye + look.z * THIRD_BACK + frame_basis.y * THIRD_UP
	return Transform3D(Basis.looking_at(eye - at, frame_basis.y), at)


## ── LAS TECLAS, A SU INTENCIÓN ──────────────────────────────────────────────────────────────────────────────────────
func _unhandled_input(event: InputEvent) -> void:
	if not active or not UIState.gameplay_active() or not is_instance_valid(bi.char_rigidbody):
		return
	var intent := bi.intent
	if event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		var sens := GameOptions.mouse_sensitivity
		if not intent.turn_held:
			intent.look_yaw = wrapf(intent.look_yaw - motion.relative.x * MOUSE_RAD * sens, -PI, PI)
			intent.look_pitch = clampf(intent.look_pitch - motion.relative.y * MOUSE_RAD * sens, -PITCH_MAX, PITCH_MAX)
		intent.hand_motion += motion.relative
		return
	if event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		match button.button_index:
			MOUSE_BUTTON_LEFT:
				intent.use = button.pressed
			MOUSE_BUTTON_RIGHT:
				intent.turn_held = button.pressed
			MOUSE_BUTTON_WHEEL_UP:
				if button.pressed:
					intent.reach_steps -= 1.0
			MOUSE_BUTTON_WHEEL_DOWN:
				if button.pressed:
					intent.reach_steps += 1.0
		return
	var key := event as InputEventKey
	if key == null or key.echo:
		return
	match key.physical_keycode:
		KEY_SPACE:
			intent.jump = key.pressed and not bi.is_seated
		KEY_CTRL:
			intent.crouch = key.pressed and not bi.is_seated
		KEY_R:
			intent.throw = key.pressed
		KEY_E:
			if key.pressed:
				_use()
		_:
			return
	get_viewport().set_input_as_handled()


## LA E: sentado, se para; mirando una silla, se sienta (por su intención: la silla del jugador la pide el host y
## sentaría al jugador, ver SeatInteractable.sit); si no, usa lo que mira.
func _use() -> void:
	if bi.is_seated:
		bi.intent.seat = null
		return
	var hands: InteractionController = _actions._hands if is_instance_valid(_actions) else null
	var hovered: Node = hands.detector.get_hovered() if hands != null and is_instance_valid(hands.detector) else null
	if hovered is SeatInteractable:
		bi.intent.seat = hovered
	else:
		bi.intent.activate = true


func _physics_process(_delta: float) -> void:
	if not active:
		return
	var live := UIState.gameplay_active()
	bi.intent.move = Vector2(Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_backward")) if live and not bi.is_seated else Vector2.ZERO
	bi.intent.sprint = live and Input.is_action_pressed("sprint")
