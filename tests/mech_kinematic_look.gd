extends Node

## LA MECA CINEMÁTICA, PARA MIRARLA (unos 40 segundos, sin el sandbox): la meca de siempre —brazos, cabina, sillas con
## maniquíes, escalera, toberas— movida por el controlador de personaje del motor (KinematicMover), con DOS CUBOS SUELTOS adentro, una PARED a la derecha y
## una PILA ALTA adelante. Camina hacia la pila, salta, dash de costado contra la pared, se corre, da media vuelta, corre,
## y frena. Imprime lo que más importa: cuánto se mueven contra la meca los cubos y los maniquíes (la
## regla: lo de adentro, como si estuviera quieta), si las sillas giran con ella, si la pared la frena, cuánto despide a
## la pila, y la inclinación y las caídas. *El golpe fuerte se sacó el 13/11/2026: con movimiento discreto, falta decidir qué le hace un golpe.* Con ventana, capturas numeradas.
##   tools/godot_ventana.sh res://tests/mech_kinematic_look.tscn -- --salida=C:/carpeta

const CUBE := 0.63

var _folder := ""
var _mech: Mech = null
var _cubes: Array[RigidBody3D] = []
var _pile: Array[RigidBody3D] = []
var _eye: Camera3D = null
var _title: Label = null
var _rest := {}
var _moved := {}
var _pushed := 0.0
var _deepest := -100.0
var _tilt := 0.0


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	for i in range(-40, 41):
		Clay.box(ground, Vector3(800, 0.02, 0.25), Vector3(0, 0.0, i * 5.0), Color(0.7, 0.68, 0.64))
	# UNA PARED alta a la derecha, para el dash.
	Clay.solid(ground, Vector3(2.0, 40.0, 80.0), Vector3(30.0, 20.0, -10.0), Clay.METAL.lightened(0.2))
	# Lo fijo del mundo: contra esto frena el controlador de la cinemática (ver PhysicsLayers.FIXED).
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 205.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.85)
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	var holder := Node3D.new()
	add_child(holder)
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.POSE
	_mech.kinematic = true
	_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
	holder.add_child(_mech)
	# LA PILA, alta: la caja va a la altura de la cintura (7 m) y pasa por arriba de lo bajo.
	for i in 16:
		_pile.append(_cube(holder, Vector3((i % 2) * 1.7 - 0.85, 0.8 + floor(i / 2.0) * 1.6, -19.0), 1.6, Clay.YELLOW))
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	_mech.keys.driving = true
	await _seconds(3.0)
	# DOS CUBOS SUELTOS en el piso del medio, contra las paredes de los costados (lejos de las sillas y los maniquíes).
	var floor_y := CabinGrid.floor_top() + CUBE * 0.5 + 0.02
	for x: float in [-1.0, 1.0]:
		var at := Vector3(x * (CabinGrid.INNER - 1.2), floor_y, CabinGrid.line(3))
		_cubes.append(_cube(holder, _mech.global_transform * at, CUBE, Clay.RED))
	await _seconds(1.0)
	var inside := 0
	for cube in _cubes:
		if MotionFrame.frame_of(cube) == _mech.cabin.frame:
			inside += 1
	print("ADOPTADOS: %d de %d cubos sueltos entraron al marco" % [inside, _cubes.size()])
	for thing in _things():
		_rest[thing] = _mech.global_transform.affine_inverse() * thing.global_transform
		_moved[thing] = 0.0
	var seat_turn := _seat_yaw()
	_look(Vector3(-22.0, 6.0, 18.0))
	await _shot("1. la meca cinemática con los maniquíes y dos cubos adentro", "1_adentro")
	# LA RUTINA.
	_press(KEY_W, true)
	await _watch(2.5)
	_now("después de caminar")
	_press(KEY_SPACE, true)
	await _watch(0.6)
	_press(KEY_SPACE, false)
	_press(KEY_W, false)
	await _until(func() -> bool: return _mech.airborne and _mech.velocity().y < 0.0, 3.0)
	_now("subiendo el salto")
	_look(Vector3(-30.0, 4.0, 20.0))
	await _shot("2. en lo alto del salto", "2_salto")
	_press(KEY_D, true)
	_press(KEY_SHIFT, true)
	await _watch(0.12)
	_press(KEY_SHIFT, false)
	await _watch(0.3)
	_press(KEY_D, false)
	await _until(func() -> bool: return not _mech.airborne, 4.0)
	_now("después del dash contra la pared")
	_look(Vector3(-30.0, 22.0, 26.0))
	await _shot("3. el dash de costado, contra la pared", "3_dash_pared")
	await _watch(1.5)
	_press(KEY_A, true)
	await _watch(1.5)
	_press(KEY_A, false)
	await _watch(1.0)
	_now("antes del primer giro")
	_mech.aim_yaw += PI * 0.5
	await _watch(2.5)
	var turned := rad_to_deg(angle_difference(seat_turn, _seat_yaw()))
	_now("después del primer giro")
	_look(Vector3(-24.0, 16.0, 22.0))
	await _shot("4. después de girar 90°: las sillas giraron con ella", "4_giro")
	_mech.aim_yaw += PI * 0.5
	await _watch(2.5)
	_now("después de la media vuelta")
	_press(KEY_W, true)
	_press(KEY_SHIFT, true)
	await _watch(3.0)
	_press(KEY_W, false)
	_press(KEY_SHIFT, false)
	await _watch(3.0)
	_now("después de correr y frenar")
	print("RUTINA: inclinación más grande %.0f° · caídas %d" % [_tilt, _mech.falls])
	_report("lo de adentro, en la rutina")
	print("SILLAS: la meca giró 90° y las sillas %.0f°" % turned)
	print("PARED: la caja se metió en la pared %.2f m (negativo: no la tocó)" % _deepest)
	print("PILA: salió despedida a %.1f m/s como mucho · achatadas %d de %d" % [_pushed, _mech.mover.flattened +
		(_mech.stomp.flattened if _mech.stomp != null else 0), _pile.size()])
	get_tree().quit()


## Los cubos y los maniquíes (su cápsula).
func _things() -> Array[Node3D]:
	var out: Array[Node3D] = []
	for cube in _cubes:
		out.append(cube)
	for dummy in _mech.cabin.dummies:
		if is_instance_valid(dummy):
			out.append(dummy.char_rigidbody)
	return out


## Cuánto se corrió cada cosa de adentro contra la meca, lo más.
func _report(title: String) -> void:
	var cubes := 0.0
	var dummies := 0.0
	for thing: Node3D in _moved.keys():
		if thing is CharacterRigidBody3D:
			dummies = maxf(dummies, float(_moved[thing]))
		else:
			cubes = maxf(cubes, float(_moved[thing]))
	print("ADENTRO (%s): los cubos se corrieron contra la meca hasta %.2f m · los maniquíes hasta %.2f m" % [title, cubes,
		dummies])


## Espera `seconds` mirando todo en cada paso.
func _watch(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		_measure()


func _until(done: Callable, most: float) -> void:
	var clock := 0.0
	while clock < most and not bool(done.call()):
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		_measure()


## Cuánto se corrió cada cubo AHORA (no lo más): para saber en qué parte de la rutina.
func _now(title: String) -> void:
	var inverse := _mech.global_transform.affine_inverse()
	var parts := PackedStringArray()
	for cube in _cubes:
		var now := inverse * cube.global_transform
		parts.append("%s" % (now.origin - (_rest[cube] as Transform3D).origin).snapped(Vector3.ONE * 0.01))
	print("  · ", title, ": los cubos, a ", ", ".join(parts), " m de donde estaban")


func _measure() -> void:
	_tilt = maxf(_tilt, _mech.tilt)
	var inverse := _mech.global_transform.affine_inverse()
	for thing: Node3D in _rest.keys():
		if is_instance_valid(thing):
			var now := inverse * thing.global_transform
			_moved[thing] = maxf(float(_moved[thing]), now.origin.distance_to((_rest[thing] as Transform3D).origin))
	for cube in _pile:
		if is_instance_valid(cube):
			_pushed = maxf(_pushed, cube.linear_velocity.length())
	_deepest = maxf(_deepest, _mech.global_position.x + CabinGrid.HALF - 29.0)


## Hacia dónde mira la primera silla (en el mundo).
func _seat_yaw() -> float:
	var forward := -_mech.cabin.chairs[0].global_basis.z
	return atan2(-forward.x, -forward.z)


func _cube(holder: Node3D, at: Vector3, side: float, color: Color) -> RigidBody3D:
	var cube := RigidBody3D.new()
	cube.mass = 60.0 if side < 1.0 else 300.0
	holder.add_child(cube)
	cube.global_position = at
	Clay.solid(cube, Vector3.ONE * side, Vector3.ZERO, color)
	return cube


func _look(offset: Vector3) -> void:
	var at := _mech.global_position + Vector3(0.0, -2.0, 0.0)
	_eye.global_position = at + offset
	_eye.look_at(at)


func _press(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
