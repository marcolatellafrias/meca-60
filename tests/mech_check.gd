extends Node

## LA PELEA, PROBADA POR CÓDIGO: arma el sandbox, maneja la meca desde afuera (O), camina hacia el rival, gira el torso,
## carga y suelta piñas (sin cargar, cargadas y un gancho doblado con el mouse), tira al rival hasta que se cae y se
## levanta, pasa a primera persona (T), pone al rival agresivo y mira si pega, traba un brazo contra un edificio y, al
## final, adentro, pega sentado en los brazos. Imprime lo que mide, y con ventana saca capturas.
##   headless:     godot --headless --path . res://tests/mech_check.tscn
##   con capturas: tools/godot_ventana.sh res://tests/mech_check.tscn -- --salida=C:/carpeta

var _folder := ""
var _arena: TestArena = null
var _walker: SandboxWalker = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate()
	add_child(sandbox)
	await _frames(5)
	for parcel: SandboxParcel in sandbox.find_children("*", "SandboxParcel", true, false):
		if parcel.archetype is MechTestArchetype:
			_arena = parcel.root() as TestArena
	_walker = sandbox.find_children("*", "SandboxWalker", true, false)[0] as SandboxWalker
	var mech := _arena.mech
	var rival := _arena.rival
	# Desde afuera, de costado: las dos mecas y la arena.
	var eye := Camera3D.new()
	add_child(eye)
	eye.global_position = _arena.global_position + Vector3(0, 60, 75)
	eye.look_at(_arena.global_position + Vector3(0, 8, 0))
	eye.make_current()
	await _shot("La arena: la meca y el rival", "1_arena")
	# MANEJAR DESDE AFUERA (la O; el que camina está en la parcela).
	_walker.global_position = _arena.global_position + Vector3(0, 0.2, 40)
	await _seconds(0.3)
	await _key(KEY_O)
	print("DESDE AFUERA: %s · cámara: %s" % [mech.driven_from_outside(), get_viewport().get_camera_3d().name])
	await _shot("Desde afuera: la cámara atrás del torso", "2_desde_afuera")
	var start := mech.global_position
	await _hold(KEY_W, 6.5)
	await _seconds(3.0)
	print("CAMINÓ: %.1f m · distancia al rival %.1f m · equilibrio %.2f" % [start.distance_to(mech.global_position),
		mech.global_position.distance_to(rival.global_position), mech.stability.length()])
	# EL TORSO GIRA APARTE: el mouse lo pide, y llega a su velocidad.
	var legs_before := mech.global_rotation.y
	await _mouse_motion(Vector2(-300, 0))
	var asked := rad_to_deg(wrapf(mech.torso_aim - mech.global_rotation.y, -PI, PI))
	await _seconds(0.3)
	var after_short := rad_to_deg(wrapf(mech.torso_yaw() - mech.global_rotation.y, -PI, PI))
	await _seconds(1.5)
	print("TORSO: pedido %.0f°, a los 0,3 s va %.0f°, después %.0f° · piernas quietas: %s" % [asked, after_short,
		rad_to_deg(wrapf(mech.torso_yaw() - mech.global_rotation.y, -PI, PI)),
		is_equal_approx(legs_before, mech.global_rotation.y)])
	await _mouse_motion(Vector2(300, 0))
	await _seconds(1.5)
	# PIÑAS: sin cargar y cargada, a la meca rival (quieta).
	await _punch(MOUSE_BUTTON_LEFT, 0.05, Vector2.ZERO)
	var weak := mech.left_arm.last_hit_speed
	await _seconds(1.0)
	await _punch(MOUSE_BUTTON_LEFT, 0.9, Vector2.ZERO)
	var strong := mech.left_arm.last_hit_speed
	print("PIÑA sin cargar: %.0f m/s · cargada: %.0f m/s · equilibrio del rival %.2f · golpes %d" % [weak, strong,
		rival.stability.length(), rival.hits_taken])
	await _seconds(1.5)
	# UN GANCHO: la derecha cargada, doblada hacia la izquierda con el mouse.
	await _punch(MOUSE_BUTTON_RIGHT, 0.7, Vector2(-60, 0))
	await _shot("Un gancho de derecha", "3_gancho")
	print("GANCHO: pegó a %.0f m/s · trabado %s" % [mech.right_arm.last_hit_speed, mech.right_arm.jammed])
	await _seconds(1.5)
	# TIRAR AL RIVAL: piñas cargadas seguidas.
	for i in 8:
		var arm := mech.left_arm if i % 2 == 0 else mech.right_arm
		await _punch(MOUSE_BUTTON_LEFT if i % 2 == 0 else MOUSE_BUTTON_RIGHT, 0.8, Vector2.ZERO)
		print("  piña %d: %.0f m/s · trabada %s · distancia %.1f · equilibrio del rival %.2f" % [i, arm.last_hit_speed,
			arm.jammed, mech.global_position.distance_to(rival.global_position), rival.stability.length()])
		if rival.state != Mech.State.STANDING:
			break
		await _seconds(0.2)
	print("RIVAL: estado %d (0 parado, 1 cayéndose, 2 en el suelo) · golpes %d" % [rival.state, rival.hits_taken])
	await _seconds(1.0)
	eye.global_position = rival.global_position + Vector3(-12, 16, 36)
	eye.look_at(rival.global_position + Vector3(0, 6, 0))
	eye.make_current()
	await _shot("El rival, caído", "4_rival_caido")
	await _seconds(7.0)
	print("RIVAL después: estado %d (0 = parado otra vez)" % rival.state)
	# PRIMERA PERSONA (T).
	await _key(KEY_T)
	await _seconds(0.3)
	mech._camera.make_current()
	print("PRIMERA PERSONA: cámara a %.1f m del frente del torso" % mech._camera.global_position.distance_to(
		mech.torso.global_transform * Vector3(0, MechTorso.floor_y(1) + 1.6, -MechTorso.DEPTH * 0.5)))
	await _shot("Desde afuera, en primera persona", "5_primera_persona")
	await _key(KEY_T)
	# EL RIVAL AGRESIVO: que pegue.
	await _key(KEY_N)
	print("RIVAL modo: %s" % MechBrain.NAMES[rival.brain.mode])
	var taken := mech.hits_taken
	await _seconds(8.0)
	print("RIVAL agresivo: me pegó %d veces · mi estado %d · equilibrio %.2f" % [mech.hits_taken - taken, mech.state,
		mech.stability.length()])
	await _shot("El rival agresivo, peleando", "6_rival_agresivo")
	await _key(KEY_N)
	# EL BRAZO SE TRABA: la meca al lado de un edificio, una piña hacia él.
	var block: Rect2 = _arena._blocks[0]
	var centre := _arena.to_global(Vector3(block.get_center().x, 0, block.get_center().y))
	var out := _arena.global_position - centre
	out.y = 0.0
	out = out.normalized()
	mech.global_position = centre + out * (maxf(block.size.x, block.size.y) * 0.5 + Mech.RADIUS + 3.0)
	var toward := centre - mech.global_position
	mech.global_rotation = Vector3(0, atan2(-toward.x, -toward.z), 0)
	mech.torso_aim = mech.global_rotation.y
	await _seconds(2.0)
	mech.left_arm.hold()
	await _seconds(0.6)
	mech.left_arm.let_go(centre + Vector3(0, 12, 0))
	await _seconds(0.6)
	print("TRABADO contra el edificio: %s · pegó %.0f" % [mech.left_arm.jammed, mech.left_arm.last_hit_speed])
	# ADENTRO: subirse, sentarse en los brazos y pegar con el mouse.
	mech.board()
	await _seconds(0.5)
	_walker.global_position = mech.torso.seats[1].global_position + mech.torso.global_basis * Vector3(0, 0.2, 0.6)
	await _seconds(0.3)
	await _key(KEY_E)
	print("SENTADO: %s" % (mech._seat.name if mech._seat != null else "no"))
	var aim_before := mech.torso_aim
	await _mouse_motion(Vector2(120, 0))
	print("MOUSE en brazos: el torso pidió %.1f°" % rad_to_deg(mech.torso_aim - aim_before))
	await _shot("Sentado en el puesto de los brazos", "7_puesto_brazos")
	await _button(MOUSE_BUTTON_LEFT, true)
	await _seconds(0.4)
	await _button(MOUSE_BUTTON_LEFT, false)
	await _frames(2)
	print("MOUSE en brazos: la piña salió (fase %s)" % MechArm.NAMES[mech.left_arm.phase])
	get_tree().quit()


## Una piña con el mouse: aprieta, carga `seconds`, suelta y dobla con `bend` (píxeles) mientras sale.
func _punch(button: MouseButton, seconds: float, bend: Vector2) -> void:
	await _button(button, true)
	await _seconds(seconds)
	await _button(button, false)
	if bend != Vector2.ZERO:
		await _frames(4)
		await _mouse_motion(bend)
	await _seconds(0.5)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)


func _hold(code: Key, seconds: float) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _seconds(seconds)
	var up := event.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await _frames(8)
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)


func _mouse_motion(relative: Vector2) -> void:
	var centre := get_viewport().get_visible_rect().size * 0.5
	for i in 10:
		var motion := InputEventMouseMotion.new()
		motion.relative = relative / 10.0
		motion.position = centre
		motion.global_position = centre
		Input.parse_input_event(motion)
		await _frames(1)


func _button(button: MouseButton, pressed: bool) -> void:
	var centre := get_viewport().get_visible_rect().size * 0.5
	var click := InputEventMouseButton.new()
	click.button_index = button
	click.pressed = pressed
	click.position = centre
	click.global_position = centre
	Input.parse_input_event(click)
	await _frames(1)
