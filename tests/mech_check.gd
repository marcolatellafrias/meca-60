extends Node

## LA MECA, PROBADA POR CÓDIGO: arma el sandbox, sube al que camina a la meca (la U), se sienta en las piernas (E),
## camina con las flechas hacia el bicho, pega con el puño y dispara (F y G), y empuja el equilibrio hasta que la meca
## se cae y se levanta. Imprime lo que mide, y con ventana saca capturas.
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
	print("PARTES del bicho: ", ", ".join(_arena.beast.parts.map(func(p: BeastPart) -> String:
		return "%s %d" % [p.part_name, p.health])))
	# Desde afuera, de costado: la meca, el bicho y la arena.
	var eye := Camera3D.new()
	add_child(eye)
	eye.global_position = _arena.global_position + Vector3(0, 70, 85)
	eye.look_at(_arena.global_position + Vector3(0, 4, 0))
	eye.make_current()
	await _shot("La arena: la meca y el bicho de prueba", "1_arena")
	eye.global_position = mech.torso.global_transform * Vector3(-14, 4, 26)
	eye.look_at(mech.torso.global_transform * Vector3(0, 3, 4))
	await _shot("La meca de atrás: escalera de incendio y montacargas", "2_meca_atras")
	# Subirse y sentarse en las piernas.
	mech.board()
	await _seconds(0.5)
	print("SUBIÓ: el que camina en %s (torso en %s)" % [_walker.global_position, mech.torso.global_position])
	await _key(KEY_E)
	print("SENTADO: %s" % (mech._seat.name if mech._seat != null else "no"))
	await _shot("Sentado en el puesto de las piernas", "3_puesto_piernas")
	var start := mech.global_position
	await _hold(KEY_UP, 3.0)
	print("CAMINÓ 3 s: %.1f m · equilibrio %.2f" % [start.distance_to(mech.global_position), mech.stability.length()])
	await _shot("Caminando hacia el bicho", "4_caminando")
	# Pegar y disparar.
	var health_before := _beast_health()
	await _hold(KEY_UP, 2.0)
	await _seconds(1.5)
	print("DISTANCIA al bicho: %.1f m" % mech.global_position.distance_to(_arena.beast.global_position))
	for shot in 4:
		await _key(KEY_G)
		await _seconds(0.8)
	await _key(KEY_F)
	await _seconds(0.12)
	await _shot("El puño de resorte, estirado", "5_puno")
	await _seconds(1.0)
	print("VIDA del bicho: %d → %d · equilibrio del bicho %.2f · estado %d" % [health_before, _beast_health(),
		_arena.beast.stability.length(), _arena.beast.state])
	# Tirar al bicho: empujones fuertes.
	for i in 3:
		_arena.beast.push(Vector3(1, 0, 0), 1.2)
		await _seconds(0.2)
	await _seconds(1.5)
	print("BICHO empujado: estado %d (0 parado, 1 cayéndose, 2 en el suelo)" % _arena.beast.state)
	eye.global_position = _arena.beast.global_position + Vector3(-10, 14, 34)
	eye.look_at(_arena.beast.global_position + Vector3(0, 4, 0))
	eye.make_current()
	await _shot("El bicho, caído", "6_bicho_caido")
	# Hacer caer a la meca: empujones hacia adelante.
	for i in 3:
		mech.push(-mech.global_basis.z, 2.0)
		await _seconds(0.1)
	await _seconds(1.6)
	print("MECA empujada: estado %d · cayó: %s" % [mech.state, mech.state != Mech.State.STANDING])
	eye.global_position = mech.global_position + Vector3(20, 14, 26)
	eye.look_at(mech.global_position + Vector3(0, 4, 0))
	await _shot("La meca, caída", "7_meca_caida")
	await _seconds(6.0)
	print("MECA después: estado %d (0 = parada otra vez)" % mech.state)
	# EL MOUSE SENTADO: mover el mouse gira la cabeza (en piernas) y clic izquierdo tira el puño (en brazos).
	var legs_seat := mech.torso.seats[0]
	var before := legs_seat.camera.rotation
	await _mouse_motion(Vector2(200, 0))
	print("MOUSE en piernas: la cabeza giró %.1f° (tiene que ser distinto de 0)" % rad_to_deg(
		legs_seat.camera.rotation.y - before.y))
	await _key(KEY_E)
	_walker.global_position = mech.torso.seats[1].global_position + mech.torso.global_basis * Vector3(0, 0.2, 0.6)
	await _seconds(0.3)
	await _key(KEY_E)
	await _seconds(0.8)
	var arms_ready := mech.fist.ready_to_use()
	await _click(MOUSE_BUTTON_LEFT)
	print("MOUSE en brazos: clic izquierdo tiró el puño: %s (listo antes: %s)" % [not mech.fist.ready_to_use(), arms_ready])
	# La vigía: la cámara de afuera.
	await _key(KEY_E)
	_walker.global_position = mech.torso.seats[2].global_position + mech.torso.global_basis * Vector3(0, 0.2, 0.6)
	await _seconds(0.3)
	await _key(KEY_E)
	print("VIGÍA: %s" % (mech._seat.name if mech._seat != null else "no"))
	await _shot("Desde la vigía: la cámara de afuera", "8_vigia")
	get_tree().quit()


func _beast_health() -> int:
	var total := 0.0
	for part in _arena.beast.parts:
		total += part.health
	return roundi(total)


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


func _click(button: MouseButton) -> void:
	var centre := get_viewport().get_visible_rect().size * 0.5
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = button
		click.pressed = pressed
		click.position = centre
		click.global_position = centre
		Input.parse_input_event(click)
		await _frames(1)
