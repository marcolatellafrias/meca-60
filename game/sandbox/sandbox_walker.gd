class_name SandboxWalker
extends CharacterBody3D

## EL QUE CAMINA POR EL SANDBOX: una cápsula con cámara en primera persona. WASD, mouse para mirar, shift corre,
## espacio salta. Si el mouse quedó suelto, un clic lo vuelve a capturar (Escape es la pausa, ver PauseMenu). Mientras uno escribe (`typing`), no se mueve.
##
## EL MODO CREATIVO (V), como el del sandbox de character-parametric (CreativeFlight y SandboxEntity de allá): vuelo
## libre y SIN COLISIÓN, para meterse adentro de una pieza o ver la maqueta desde arriba. Espacio sube, Ctrl baja, Shift
## va al doble, y Shift apretado dos veces rápido y mantenido, un turbo cuatro veces más rápido (también caminando).

const WALK_SPEED := 4.0
const RUN_SPEED := 8.0
const JUMP_SPEED := 4.5
const EYE_HEIGHT := 1.6
const MOUSE_SENSITIVITY := 0.0025
const FLY_SPEED := 12.0
const SPRINT_MULTIPLIER := 2.0
const TURBO_MULTIPLIER := 4.0
## Cuánto puede pasar entre los dos toques de Shift para que el segundo, mantenido, sea turbo (en segundos).
const DOUBLE_TAP_S := 0.3
const CREATIVE_KEY := KEY_V

## Volando (el modo creativo, V).
var creative := false
var _turbo := false
var _last_shift_ms := -100000

## Lo prende quien tiene el teclado (la caja de texto de la conversación).
var typing := false
## Sentado en algo (la cabina del taxi, ver CabView): ni camina ni mira con el mouse; la cámara es la del asiento.
var seated := false:
	set(on):
		seated = on
		if not on and _camera != null:
			_camera.make_current()

var _camera: Camera3D = null


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	_camera = Camera3D.new()
	_camera.position.y = EYE_HEIGHT
	_camera.fov = 75.0
	add_child(_camera)
	_camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func camera() -> Camera3D:
	return _camera


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if motion != null and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not seated:
		var sensitivity := MOUSE_SENSITIVITY * GameOptions.mouse_sensitivity
		rotate_y(-motion.relative.x * sensitivity)
		_camera.rotation.x = clampf(_camera.rotation.x - motion.relative.y * sensitivity, -1.5, 1.5)
	var click := event as InputEventMouseButton
	# Sentado (manejando, o con las pantallas del juego encima) el mouse es de lo que esté delante: un clic suelto no
	# lo captura (un clic apurado al fundir el resumen dejaba la tienda de la mañana sin mouse).
	if click != null and click.pressed and not seated:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var key := event as InputEventKey
	if key != null and key.pressed and not key.echo and not typing and not seated:
		if key.physical_keycode == CREATIVE_KEY:
			set_creative(not creative)
			get_viewport().set_input_as_handled()
		elif key.physical_keycode == KEY_SHIFT:
			var now := Time.get_ticks_msec()
			_turbo = now - _last_shift_ms <= int(DOUBLE_TAP_S * 1000.0)
			_last_shift_ms = now


## Prende o apaga el vuelo: sin colisión mientras vuela; al apagarlo cae donde esté (o sube al piso, si quedó abajo).
func set_creative(on: bool) -> void:
	creative = on
	collision_layer = 0 if on else 1
	collision_mask = 0 if on else 1
	velocity = Vector3.ZERO
	# Si se apaga debajo del piso del sandbox (que está a la altura 0), vuelve arriba: si no, caería para siempre.
	if not on and global_position.y < 0.0:
		global_position.y = 0.05


func _physics_process(delta: float) -> void:
	var wish := Vector2.ZERO
	if not typing and not seated:
		if Input.is_physical_key_pressed(KEY_W):
			wish.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S):
			wish.y += 1.0
		if Input.is_physical_key_pressed(KEY_A):
			wish.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D):
			wish.x += 1.0
	var shift := Input.is_physical_key_pressed(KEY_SHIFT)
	if not shift:
		_turbo = false
	var direction := (transform.basis * Vector3(wish.x, 0.0, wish.y)).normalized()
	if creative:
		var fly := FLY_SPEED * (TURBO_MULTIPLIER if _turbo else (SPRINT_MULTIPLIER if shift else 1.0))
		var vertical := 0.0
		if not typing and not seated:
			if Input.is_physical_key_pressed(KEY_SPACE):
				vertical += 1.0
			if Input.is_physical_key_pressed(KEY_CTRL):
				vertical -= 1.0
		velocity = direction * fly + Vector3.UP * vertical * fly
		move_and_slide()
		return
	var speed := WALK_SPEED * TURBO_MULTIPLIER if _turbo else (RUN_SPEED if shift else WALK_SPEED)
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	if is_on_floor():
		if not typing and not seated and Input.is_physical_key_pressed(KEY_SPACE):
			velocity.y = JUMP_SPEED
	else:
		velocity.y -= 9.8 * delta
	move_and_slide()
