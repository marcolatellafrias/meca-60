class_name ToolMechKeys
extends MechKeys

## LAS TECLAS DE LA MECA CON HERRAMIENTAS (ToolMech, la base de la jaula; nacieron para la Meca de tres), poseyéndola
## desde afuera: todo lo que después van a hacer los tres puestos de adentro (las piernas, el cañón, el taladro), desde
## un teclado. Como las de siempre, el único lugar que lee teclas.
##   LAS PIERNAS: W/S adelante y atrás · A/D de costado · mouse gira · Ctrl se agacha · espacio salta y, en el aire,
##     otra vez: levita · Shift con una dirección: dash. El dash, el salto y levitar gastan energía.
##   LO QUE LLEVA EN LOS BRAZOS (ToolMech.cannon, drill y melee; lo que no lleva, nada):
##     EL TALADRO O LA SIERRA: clic derecho mantenido, carga · clic izquierdo, descarga (un golpe al frente).
##     SI NO, EL BRAZO DE LAS PIÑAS (un puño o el palo): clic izquierdo, un directo · clic derecho, un gancho.
##     EL CAÑÓN: las flechas mueven la palanca (queda donde la dejás) · 1 simple, 2 ráfaga, 3 barrido, 4 súper · F, el
##     gatillo (mantenido en ráfaga y barrido; en súper, mantener carga y soltar tira).
## Aturdida (sin energía), no hace nada.
## *Las piñas con el clic eran sólo de la meca jaula (CageMechKeys) hasta el 16/11/2026; desde que los brazos se
## equipan, van con lo que lleve cada meca. Hasta el 17/11/2026, G / X subían y bajaban el ascensor de la meca grande,
## borrada ese día.*

## Lo que gastan el salto y el dash, y levitar por segundo. El dash, caro (el usuario, 15/11/2026: «diseñar todo para
## un dash… que cueste más energía»; «me parece mucho 40%… va a estar moviéndose, haciendo ataques… tal vez 25%»): un
## cuarto de la barra. Entre dash y dash, la espera de la cinemática (KinematicSettings.dash_cooldown): con energía de
## sobra, tampoco salen dos seguidos.
const JUMP_COST := 0.05
const DASH_COST := 0.25
const FLY_COST := 0.22
const MODE_KEYS := {KEY_1: CannonTip.Mode.SIMPLE, KEY_2: CannonTip.Mode.BURST, KEY_3: CannonTip.Mode.BEAM,
	KEY_4: CannonTip.Mode.SUPER}

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
	if shift and not _shift_was and mech.move.length() > 0.1 and mech.mover != null and mech.mover.dash_ready():
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
	if tool.drill != null:
		tool.drill.charging = mine and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
	if tool.cannon == null:
		return
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
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and tool.drill != null:
		tool.drill.strike()
		get_viewport().set_input_as_handled()
		return
	if click != null and tool.drill == null and tool.melee != null and click.button_index in [MOUSE_BUTTON_LEFT,
			MOUSE_BUTTON_RIGHT]:
		if click.pressed and tool.energy.able():
			if click.button_index == MOUSE_BUTTON_LEFT:
				tool.melee.main_strike()
			else:
				tool.melee.punch(MechArm.Punch.HOOK)
		get_viewport().set_input_as_handled()
		return
	if click != null and click.button_index == MOUSE_BUTTON_RIGHT:
		get_viewport().set_input_as_handled()
		return
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if MODE_KEYS.has(key.physical_keycode) and tool.cannon != null:
		tool.cannon.mode = MODE_KEYS[key.physical_keycode]
		tool.cannon.charge = 0.0
	else:
		return
	get_viewport().set_input_as_handled()


func controls() -> PackedStringArray:
	var tool := mech as ToolMech
	var lines := PackedStringArray([
		"PIERNAS: WASD · mouse gira · Shift+dirección dash · espacio salta, y en el aire levita · Ctrl se agacha"])
	if tool.drill != null:
		lines.append("%s: clic derecho mantenido carga · clic izquierdo descarga" % tool.drill._hit_name().to_upper())
	elif tool.melee != null:
		lines.append("PIÑAS: clic izquierdo directo · clic derecho gancho")
	if tool.cannon != null:
		lines.append("CAÑÓN: flechas la palanca · 1 simple, 2 ráfaga, 3 barrido, 4 súper · F el gatillo")
	lines.append("todo gasta la energía común; vacía, la meca queda aturdida")
	return lines
