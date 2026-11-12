extends Node

## LA MECA PÉNDULO, PARA MIRARLA Y PROBAR LO QUE HACE (unos 25 segundos, sin el sandbox): de frente, de atrás (las
## puertas), desde el asiento del medio; y agacharse, cargar y soltar el salto, el propulsor, aterrizar y correr, con
## sus números. Con ventana, capturas.
##   tools/godot_ventana.sh res://tests/pendulum_mech_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _mech: PendulumMech = null
var _eye: Camera3D = null
var _title: Label = null


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
	Clay.shape_box(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
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
	var knobs := PendulumMechSettings.tuned
	_mech = PendulumMech.new()
	_mech.position = Vector3(0.0, knobs.hover_height + HoverCube.SIZE * 0.5, 0.0)
	add_child(_mech)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await _seconds(1.0)
	_from(Vector3(-17.0, 3.0, -24.0))
	await _shot("De frente: tres pisos y los brazos", "1_frente")
	_from(Vector3(16.0, 4.0, 24.0))
	await _shot("De atrás: las puertas", "2_atras")
	_from(Vector3(-11.0, 0.5, -11.5), Vector3(-3.5, -1.2, -6.0))
	await _shot("La mano: la muñeca, los dedos y el pulgar", "3_mano")
	_eye.global_transform = _mech.possess_camera(true, 0.0)
	await _shot("Desde el asiento del medio", "4_asiento")
	# LOS BRAZOS, FÍSICOS: las dos posturas, las piñas de cada uno (cuánto sacuden al torso) y un giro.
	_from(Vector3(-17.0, 3.0, -24.0))
	await _shot("Postura normal: los brazos a los costados", "4b_normal")
	_mech.covering = true
	await _seconds(1.3)
	await _shot("Cubriéndose: los puños cerrados adelante", "4c_cubriendose")
	_eye.global_transform = _mech.possess_camera(true, 0.0)
	await _shot("Cubriéndose, desde el asiento", "4d_cubriendose_asiento")
	_from(Vector3(-17.0, 3.0, -24.0))
	for index in 2:
		for kind: int in [MuscleArm.Punch.STRAIGHT, MuscleArm.Punch.HOOK, MuscleArm.Punch.UPPERCUT, MuscleArm.Punch.HAMMER]:
			var yaw_before := _mech._yaw()
			_mech.arms[index].punch(kind as MuscleArm.Punch)
			var most_tilt := 0.0
			var most_turn := 0.0
			var clock := 0.0
			var taken := false
			while clock < 2.4:
				await get_tree().physics_frame
				clock += 1.0 / 240.0
				most_tilt = maxf(most_tilt, _mech.tilt)
				most_turn = maxf(most_turn, absf(wrapf(_mech._yaw() - yaw_before, -PI, PI)))
				if not taken and index == 0 and clock >= 0.72:
					taken = true
					await _shot("Piña: %s (brazo izquierdo)" % MuscleArm.NAMES[kind], "4e_%d" % kind)
			print("PIÑA %s, brazo %s: la mano a %.0f m/s · el torso se inclina %.1f° y gira %.1f° · caídas %d" % [
				MuscleArm.NAMES[kind], "izquierdo" if index == 0 else "derecho", _mech.arms[index].top_speed, most_tilt,
				rad_to_deg(most_turn), _mech.falls])
	_mech.aim_yaw += PI * 0.5
	var far := 0.0
	var turning := 0.0
	while turning < 2.5:
		await get_tree().physics_frame
		turning += 1.0 / 240.0
		far = maxf(far, maxf(_mech.arms[0].off_target, _mech.arms[1].off_target))
		if absf(turning - 0.6) < 0.003:
			_from(Vector3(-17.0, 6.0, -24.0))
			await _shot("Girando 90°: los brazos van atrás", "4f_girando")
	print("GIRO de 90° cubriéndose: los brazos quedan hasta %.1f m atrás de su lugar · al final a %.2f m · caídas %d" % [far,
		maxf(_mech.arms[0].off_target, _mech.arms[1].off_target), _mech.falls])
	_mech.aim_yaw -= PI * 0.5
	_mech.covering = false
	await _seconds(2.5)
	_mech.driving = true
	# AGACHARSE.
	var standing := _mech.global_position.y
	_press(KEY_CTRL, true)
	await _seconds(1.2)
	_from(Vector3(-24.0, 1.0, -10.0))
	await _shot("Agachada (Ctrl)", "5_agachada")
	print("AGACHADA: el centro baja %.1f m (de %.1f a %.1f) · inclinación %.0f°" % [standing - _mech.global_position.y,
		standing, _mech.global_position.y, _mech.tilt])
	# EL ASCENSOR, agachada: baja hasta quedar a un salto del suelo.
	_mech.lift.toggle()
	await _seconds(2.6)
	_from(Vector3(-15.0, -4.5, 14.0), Vector3(0.0, -5.5, 0.0))
	await _shot("Agachada, con el ascensor bajado: su piso a %.1f m del suelo" % (_mech.global_transform * Vector3(0,
		_mech.lift.position.y, 0)).y, "5b_ascensor")
	_mech.lift.toggle()
	_press(KEY_CTRL, false)
	await _seconds(2.4)
	_from(Vector3(-15.0, -6.5, 14.0), Vector3(0.0, -5.0, 0.0))
	await _shot("La pelvis redonda, con el ascensor subido", "5c_pelvis")
	# EL SALTO: un toque, y cargado entero.
	for hold: float in [0.08, 1.1]:
		_press(KEY_SPACE, true)
		await _seconds(hold)
		var charged := _mech.jump_charge
		if hold > 0.5:
			_from(Vector3(-24.0, 1.0, -10.0))
			await _shot("Cargando el salto (espacio): %d %%" % roundi(charged * 100.0), "6_cargando")
		_press(KEY_SPACE, false)
		var top := await _apex()
		if hold > 0.5:
			_from(Vector3(-34.0, 6.0, -14.0))
			await _shot("En lo más alto del salto cargado", "7_salto")
		var landed := await _land()
		print("SALTO cargado %d %%: sube %.1f m · aterriza a los %.1f s · inclinación %.0f° · caídas %d" % [
			roundi(charged * 100.0), top - standing, landed, _mech.tilt, _mech.falls])
		await _seconds(1.0)
	# EL PROPULSOR: un salto cargado y espacio apretado en el aire.
	_press(KEY_SPACE, true)
	await _seconds(1.1)
	_press(KEY_SPACE, false)
	await _seconds(0.3)
	_press(KEY_SPACE, true)
	await _seconds(1.2)
	_from(Vector3(-36.0, 8.0, -16.0))
	await _shot("El propulsor (espacio en el aire)", "8_propulsor")
	var highest := await _apex()
	_press(KEY_SPACE, false)
	var down := await _land()
	print("PROPULSOR: sube %.1f m · le queda %d %% · aterriza a los %.1f s · caídas %d" % [highest - standing,
		roundi(_mech.fuel * 100.0), down, _mech.falls])
	await _seconds(1.5)
	# CORRER: W, y W con Shift.
	_press(KEY_W, true)
	await _seconds(3.0)
	var walking := _speed()
	_press(KEY_SHIFT, true)
	await _seconds(5.0)
	var running := _speed()
	_from(Vector3(-26.0, 2.0, -8.0))
	await _shot("Corriendo (W + Shift)", "9_corriendo")
	_press(KEY_SHIFT, false)
	await _seconds(3.0)
	print("CORRER: camina a %.1f m/s · corre a %.1f m/s (inclinación %.0f°) · suelta Shift y a los 3 s va a %.1f m/s · caídas %d" % [
		walking, running, _mech.tilt, _speed(), _mech.falls])
	_press(KEY_W, false)
	await _seconds(2.5)
	# LA CAÍDA: los brazos y las piernas se recogen; al enderezarse, se estiran.
	_mech.driving = false
	_mech.knock(true)
	var clock := 0.0
	var shots := 0
	var next := 0.0
	while clock < 14.0 and not (_mech.falls > 0 and _mech.state == HoverCube.State.HOVER):
		await get_tree().physics_frame
		clock += 1.0 / 240.0
		if _mech.state != HoverCube.State.HOVER and clock >= next and shots < 8:
			next = clock + 0.45
			_from(Vector3(-12.0, 5.0 - _mech.global_position.y * 0.3, -30.0), Vector3(0.0, 0.0, 0.0))
			await _shot("Caída: %s · %.1f s" % [["parada", "tirada", "sube y se endereza", "termina de enderezarse"][_mech.state],
				clock], "10_caida_%02d" % shots)
			shots += 1
	print("CAÍDA: parada otra vez a los %.1f s · brazos recogidos %d %%" % [clock, roundi(_mech._tuck * 100.0)])
	get_tree().quit()


func _speed() -> float:
	return Vector2(_mech.linear_velocity.x, _mech.linear_velocity.z).length()


## Espera a lo más alto del salto: devuelve esa altura.
func _apex() -> float:
	var top := _mech.global_position.y
	var clock := 0.0
	while clock < 8.0:
		await get_tree().physics_frame
		clock += 1.0 / 240.0
		top = maxf(top, _mech.global_position.y)
		if clock > 0.2 and _mech.linear_velocity.y < 0.0:
			break
	return top


## Espera a que aterrice: devuelve cuánto tardó.
func _land() -> float:
	var clock := 0.0
	while clock < 10.0 and _mech._airborne:
		await get_tree().physics_frame
		clock += 1.0 / 240.0
	return clock


## La cámara, desde `offset` del centro de la meca, mirándola (o mirando `at`, desde el centro).
func _from(offset: Vector3, at := Vector3(0.0, -3.0, 0.0)) -> void:
	_eye.global_position = _mech.global_position + offset
	_eye.look_at(_mech.global_position + at)


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
