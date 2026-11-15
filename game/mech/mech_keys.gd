class_name MechKeys
extends Node

## EL TECLADO Y EL MOUSE DE QUIEN POSEE LA MECA (la O del sandbox, ver SandboxPossession): es el ÚNICO lugar que lee
## teclas. Las traduce a LO QUE SE LE PIDE a la meca (ver Mech) y a sus brazos; el resto de la meca no sabe quién pide.
## En el juego esto lo van a hacer las consolas de adentro.
##   W/S adelante y atrás (hacia donde mira el torso) · A/D de costado · Shift corre · Ctrl se agacha
##   espacio: mantener carga el salto, soltar salta; en el aire, el propulsor
##   mouse: hacia dónde mirar. LA CABEZA del que va sentado mira ahí YA, y el torso la alcanza con su demora (el
##     usuario: «que con delay se gire la meca, pero que yo pueda mirar normalmente»).
##   clic izq. / der.: directo · Q / E: gancho · Z / C: uppercut · 1 / 3: desde arriba · F: la postura · G / X: el ascensor sube / baja
## Y LA CÁMARA de poseerla: en primera persona, la del que va sentado en la silla del movimiento, arriba; en tercera, atrás y arriba.

## Las teclas de las piñas: para el brazo izquierdo y para el derecho.
const PUNCH_KEYS := {
	KEY_Q: [0, MechArm.Punch.HOOK], KEY_E: [1, MechArm.Punch.HOOK],
	KEY_Z: [0, MechArm.Punch.UPPERCUT], KEY_C: [1, MechArm.Punch.UPPERCUT],
	KEY_1: [0, MechArm.Punch.HAMMER], KEY_3: [1, MechArm.Punch.HAMMER],
}

var mech: Mech = null
## Poseída: lee las teclas.
var driving := false

## Hacia dónde mira la cabeza del que va sentado, arriba y abajo (radianes).
var _head_pitch := 0.0
var _chase_yaw := 0.0


## LO QUE SE PIDE EN ESTE PASO. Sin nadie que la posea, nada.
func read() -> void:
	var mine := driving and UIState.gameplay_active()
	mech.move = Vector2(MechKeys.axis(KEY_D, KEY_A), MechKeys.axis(KEY_W, KEY_S)) if mine else Vector2.ZERO
	mech.sprint = mine and Input.is_physical_key_pressed(KEY_SHIFT)
	mech.crouch = mine and Input.is_physical_key_pressed(KEY_CTRL)
	mech.jump = mine and Input.is_physical_key_pressed(KEY_SPACE)
	mech.dash = mine and Input.is_physical_key_pressed(KEY_SHIFT)


func _unhandled_input(event: InputEvent) -> void:
	if not driving:
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		var sensitivity := 0.0025 * GameOptions.mouse_sensitivity
		_head_pitch = clampf(_head_pitch - motion.relative.y * sensitivity, deg_to_rad(-60.0), deg_to_rad(60.0))
		if mech.state == BalanceBody.State.STANDING:
			mech.aim_yaw -= motion.relative.x * sensitivity
		get_viewport().set_input_as_handled()
		return
	if mech.state != BalanceBody.State.STANDING or not UIState.gameplay_active():
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		_punch(0 if click.button_index == MOUSE_BUTTON_LEFT else 1, MechArm.Punch.STRAIGHT)
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if key.physical_keycode == KEY_F:
		mech.covering = not mech.covering
	elif key.physical_keycode == KEY_G and mech.cabin != null:
		mech.cabin.lift.up()
	elif key.physical_keycode == KEY_X and mech.cabin != null:
		mech.cabin.lift.lower()
	elif PUNCH_KEYS.has(key.physical_keycode):
		var pick: Array = PUNCH_KEYS[key.physical_keycode]
		_punch(int(pick[0]), pick[1] as MechArm.Punch)
	else:
		return
	get_viewport().set_input_as_handled()


func _punch(index: int, kind: MechArm.Punch) -> void:
	if index < mech.arms.size():
		mech.arms[index].punch(kind)


## ── POSEERLA ─────────────────────────────────────────────────────────────────────────────────────────────────────

func controls() -> PackedStringArray:
	if mech.kinematic:
		return PackedStringArray([
			"W/S adelante y atrás · A/D de costado · mouse gira (con tope)",
			"Ctrl se agacha (baja de a poco) · espacio salta (sólo para arriba)",
			"en el aire, espacio otra vez: vuela (su barra se llena apoyada)",
			"Shift con una dirección: dash, en el piso y en el aire (su barra se llena sola)",
			"clic izq. / der.: directo · Q / E: gancho · Z / C: uppercut · 1 / 3: desde arriba",
		])
	return PackedStringArray([
		"W/S adelante y atrás · A/D de costado",
		"mouse mira: la cabeza al instante, el torso la alcanza",
		"Shift corre (yendo hacia adelante) · Ctrl se agacha",
		"clic izq. / der.: directo · Q / E: gancho · Z / C: uppercut · 1 / 3: desde arriba",
		"F: postura normal / cubriéndose · G: el ascensor baja / sube",
		"espacio: mantener carga el salto, soltar salta",
		"espacio en el aire: propulsor",
		"Shift en el aire: dash hacia donde apretás (uno por salto)",
	])


func begin() -> void:
	driving = true
	_chase_yaw = _view_yaw()


func end() -> void:
	driving = false


## Cuánto está girada la cabeza del que va sentado respecto de la cabina: lo que el pedido le lleva al torso.
func head_yaw() -> float:
	return wrapf(mech.aim_yaw - mech.yaw(), -PI, PI) if mech.state == BalanceBody.State.STANDING else 0.0


## La cámara. EN PRIMERA PERSONA, LA DEL QUE VA SENTADO (el usuario: «uno de los asientos… como si estuvieras sentado…
## van a ver el vidrio, van a ver los parantes»): los ojos sobre el asiento, fijos a la meca (se inclina y cae con
## ella), y la cabeza mirando con el mouse. En tercera, atrás y arriba, siguiéndola con un poco de atraso.
func camera(first: bool, delta: float) -> Transform3D:
	if first:
		_chase_yaw = _view_yaw()
		# Sin cabina (la simplificada), arriba de la caja, al frente.
		var eyes := mech.cabin.top_seat() + Vector3(0.0, SeatInteractable.STATION_EYE_HEIGHT, 0.0) if mech.cabin != null \
			else Vector3(0.0, mech.size.y * 0.5 + 1.5, -mech.size.z * 0.4)
		return mech.global_transform * Transform3D(Basis(Vector3.UP, head_yaw()) * Basis(Vector3.RIGHT, _head_pitch), eyes)
	_chase_yaw = lerp_angle(_chase_yaw, _view_yaw(), 1.0 - exp(-4.0 * delta))
	var from := mech.global_position + Basis(Vector3.UP, _chase_yaw) * Vector3(0.0, 14.0, 34.0)
	return Transform3D(Basis(), from).looking_at(mech.global_position + Vector3(0.0, 2.0, 0.0), Vector3.UP)


## Hacia dónde mira la cámara de afuera: hacia donde mira la meca (de costado o dada vuelta, hacia donde miraba).
func _view_yaw() -> float:
	var forward := -mech.global_basis.z
	forward.y = 0.0
	return atan2(-forward.x, -forward.z) if forward.length_squared() > 0.01 else _chase_yaw


static func axis(positive: Key, negative: Key) -> float:
	return (1.0 if Input.is_physical_key_pressed(positive) else 0.0) - (1.0 if Input.is_physical_key_pressed(negative) else 0.0)
