class_name ToolMechKeys
extends MechKeys

## LAS TECLAS DE LA MECA DE TRES (ToolMech), poseyéndola desde afuera: todo lo que después van a hacer los tres puestos
## de adentro (las piernas, el cañón, el taladro), desde un teclado. Como las de siempre, el único lugar que lee teclas.
##   LAS PIERNAS: W/S adelante y atrás · A/D de costado · mouse gira · Ctrl se agacha · espacio salta y, en el aire,
##     otra vez: levita · Shift con una dirección: dash. El dash, el salto y levitar gastan energía.
##   EL TALADRO (brazo derecho): clic derecho mantenido, carga · clic izquierdo, descarga (un golpe al frente).
##   EL CAÑÓN (brazo izquierdo): las flechas mueven la palanca (queda donde la dejás) · 1 simple, 2 ráfaga, 3 barrido,
##     4 súper · F, el gatillo (mantenido en ráfaga y barrido; en súper, mantener carga y soltar tira).
##   G / X: el ascensor sube / baja.
## Aturdida (sin energía), no hace nada.

## Lo que gastan el salto y el dash, y levitar por segundo.
const JUMP_COST := 0.05
const DASH_COST := 0.16
const FLY_COST := 0.22
const MODE_KEYS := {KEY_1: CannonArm.Mode.SIMPLE, KEY_2: CannonArm.Mode.BURST, KEY_3: CannonArm.Mode.BEAM,
	KEY_4: CannonArm.Mode.SUPER}

var _dash_on := false
var _shift_was := false
var _jump_on := false
var _space_was := false
var _flying := false


func read() -> void:
	var tool := mech as ToolMech
	var delta := get_physics_process_delta_time()
	var energy := tool.energy
	var mine := driving and UIState.gameplay_active() and energy.able()
	mech.move = Vector2(MechKeys.axis(KEY_D, KEY_A), MechKeys.axis(KEY_W, KEY_S)) if mine else Vector2.ZERO
	mech.sprint = false
	mech.crouch = mine and Input.is_physical_key_pressed(KEY_CTRL)
	# EL DASH: al apretar Shift con una dirección, si alcanza la energía (y su barra).
	var shift := mine and Input.is_physical_key_pressed(KEY_SHIFT)
	if shift and not _shift_was and mech.move.length() > 0.1 and mech.mover != null \
			and mech.mover.dash_fuel >= KinematicSettings.current.dash_cost:
		_dash_on = energy.spend(DASH_COST)
	if not shift:
		_dash_on = false
	_shift_was = shift
	mech.dash = _dash_on
	# EL SALTO, al apretar apoyada; LEVITAR, mantenido en el aire, gasta de a poco.
	var space := mine and Input.is_physical_key_pressed(KEY_SPACE)
	if mech.grounded:
		_flying = false
		if space and not _space_was:
			_jump_on = energy.spend(JUMP_COST)
	else:
		# En el aire, apretar otra vez levita (como la cinemática): sólo eso gasta.
		if space and not _space_was:
			_flying = true
		if _flying and space:
			_jump_on = energy.drain(FLY_COST, delta)
			_flying = _jump_on
	if not space:
		_jump_on = false
		_flying = false
	_space_was = space
	mech.jump = _jump_on
	# LOS BRAZOS.
	tool.drill.charging = mine and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	tool.cannon.trigger = mine and Input.is_physical_key_pressed(KEY_F)
	if mine:
		tool.cannon.move_lever(Vector2(MechKeys.axis(KEY_RIGHT, KEY_LEFT), MechKeys.axis(KEY_UP, KEY_DOWN)), delta)


func _unhandled_input(event: InputEvent) -> void:
	if not driving:
		return
	var tool := mech as ToolMech
	var motion := event as InputEventMouseMotion
	if motion != null:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		var sensitivity := 0.0025 * GameOptions.mouse_sensitivity
		_head_pitch = clampf(_head_pitch - motion.relative.y * sensitivity, deg_to_rad(-60.0), deg_to_rad(60.0))
		if mech.state == BalanceBody.State.STANDING and tool.energy.able():
			mech.aim_yaw -= motion.relative.x * sensitivity
		get_viewport().set_input_as_handled()
		return
	if not UIState.gameplay_active():
		return
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		tool.drill.strike()
		get_viewport().set_input_as_handled()
		return
	if click != null and click.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if MODE_KEYS.has(key.physical_keycode):
		tool.cannon.mode = MODE_KEYS[key.physical_keycode]
		tool.cannon.charge = 0.0
	elif key.physical_keycode == KEY_G and mech.cabin != null and mech.cabin.lift != null:
		mech.cabin.lift.up()
	elif key.physical_keycode == KEY_X and mech.cabin != null and mech.cabin.lift != null:
		mech.cabin.lift.lower()
	else:
		return
	get_viewport().set_input_as_handled()


func controls() -> PackedStringArray:
	return PackedStringArray([
		"PIERNAS: WASD · mouse gira · Shift+dirección dash · espacio salta, y en el aire levita · Ctrl se agacha",
		"TALADRO (der.): clic derecho mantenido carga · clic izquierdo descarga",
		"CAÑÓN (izq.): flechas la palanca · 1 simple, 2 ráfaga, 3 barrido, 4 súper · F el gatillo",
		"todo gasta la energía común; vacía, la meca queda aturdida · G / X el ascensor",
	])
