extends Node

## LAS PIERNAS DE LA MECA, PARA MIRARLAS (unos 40 segundos, sin el sandbox): parada, caminando, corriendo, de costado,
## girando en el lugar, caminando y girando, y agachada. Imprime cuántos pasos por segundo da, cuánto avanza cada uno y
## lo más cerca que quedaron los pies de costado (negativo: se cruzaron). Con ventana, capturas.
##   tools/godot_ventana.sh res://tests/mech_legs_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null
var _closest := INF


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
	Clay.shape_box(ground, Vector3(2000, 1, 2000), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(2000, 1, 2000), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	# Rayas cada 5 m, para leer cuánto avanza un paso.
	for i in range(-40, 41):
		Clay.box(ground, Vector3(2000, 0.02, 0.25), Vector3(0, 0.0, i * 5.0), Color(0.7, 0.68, 0.64))
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
	var knobs := BodySettings.current
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.NONE
	_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_mech)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	_mech.keys.driving = true
	await _seconds(1.5)
	_side()
	await _shot("1 · Parada", "1_parada")
	# CAMINANDO Y CORRIENDO: de costado, para ver el largo del paso contra las rayas (cada 5 m).
	_press(KEY_W, true)
	await _measure("CAMINANDO", 3.0, "2_caminando", "2 · Caminando (rayas cada 5 m)")
	_press(KEY_SHIFT, true)
	await _measure("CORRIENDO", 4.0, "3_corriendo", "3 · Corriendo")
	_press(KEY_SHIFT, false)
	_press(KEY_W, false)
	await _seconds(3.0)
	await _shot_side("4 · Frenó: los pies se acomodan", "4_freno")
	# DE COSTADO.
	_press(KEY_D, true)
	await _measure("DE COSTADO", 3.0, "5_costado", "5 · De costado (D)", true)
	_press(KEY_D, false)
	await _seconds(2.5)
	# GIRANDO EN EL LUGAR: desde arriba.
	_closest = INF
	_mech.aim_yaw += PI * 0.5
	for index in 4:
		await _watch(0.45)
		_above()
		await _shot("6 · Girando 90° en el lugar (%d)" % (index + 1), "6_giro_%d" % index)
	await _watch(1.5)
	print("GIRO EN EL LUGAR: los pies, lo más cerca de costado %.1f m · pasos %d" % [_closest, _mech.legs.steps_taken])
	# CAMINANDO Y GIRANDO.
	_closest = INF
	_press(KEY_W, true)
	await _watch(1.5)
	_mech.aim_yaw -= PI * 0.75
	for index in 4:
		await _watch(0.4)
		_above()
		await _shot("7 · Caminando y girando 135° (%d)" % (index + 1), "7_camina_gira_%d" % index)
	await _watch(1.5)
	_press(KEY_W, false)
	print("CAMINANDO Y GIRANDO: los pies, lo más cerca de costado %.1f m" % _closest)
	await _seconds(2.5)
	# AGACHADA.
	_press(KEY_CTRL, true)
	await _seconds(1.5)
	_front()
	await _shot("8 · Agachada, de frente", "8_agachada_frente")
	_side()
	await _shot("9 · Agachada, de costado", "9_agachada_costado")
	_press(KEY_W, true)
	await _seconds(1.5)
	await _shot_side("10 · Agachada caminando", "10_agachada_camina")
	_press(KEY_W, false)
	_press(KEY_CTRL, false)
	await _seconds(1.0)
	get_tree().quit()


## Anda `seconds` con lo apretado y mide los pasos por segundo y cuánto avanza el cuerpo por paso; a la mitad, captura.
func _measure(title: String, seconds: float, file_name: String, caption: String, sideways := false) -> void:
	await _watch(1.5)
	var steps := _mech.legs.steps_taken
	var start := _mech.global_position
	var clock := 0.0
	var taken := false
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		_track()
		if not taken and clock > seconds * 0.5:
			taken = true
			if sideways:
				_back()
			else:
				_side()
			await _shot(caption, file_name)
	var done := _mech.legs.steps_taken - steps
	var went := Vector2(_mech.global_position.x - start.x, _mech.global_position.z - start.z).length()
	print("%s: %.1f m/s · %.1f pasos por segundo · el cuerpo avanza %.1f m por paso · caídas %d" % [title,
		went / seconds, done / seconds, went / maxf(done, 1.0), _mech.falls])


func _watch(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		_track()


## Lo más cerca que quedan los pies de costado, contado hacia donde mira la pelvis (negativo: cruzados).
func _track() -> void:
	var legs := _mech.legs
	var yaw := lerp_angle(legs._feet_yaw[0], legs._feet_yaw[1], 0.5)
	var across := Basis(Vector3.UP, yaw).inverse() * (legs._feet[1] - legs._feet[0])
	_closest = minf(_closest, across.x)


func _shot_side(title: String, file_name: String) -> void:
	_side()
	await _shot(title, file_name)


func _side() -> void:
	_legs_from(Vector3(-28.0, 4.0, -3.0))


func _front() -> void:
	_legs_from(Vector3(-8.0, 4.0, -26.0))


func _back() -> void:
	_legs_from(Vector3(8.0, 4.0, 26.0))


func _above() -> void:
	_legs_from(Vector3(-17.0, 3.0, -17.0))


## La cámara mirando las piernas, desde `offset` (en el espacio de hacia donde mira la meca, a ras del piso).
func _legs_from(offset: Vector3) -> void:
	var ahead := -_mech.global_basis.z
	ahead.y = 0.0
	var turn := Basis.looking_at(ahead.normalized(), Vector3.UP)
	var feet := Vector3(_mech.global_position.x, _mech.support.y, _mech.global_position.z)
	_eye.global_position = feet + turn * offset
	_eye.look_at(feet + Vector3.UP * 4.5)


## La cámara, desde `offset` del centro de la meca, mirando `at` (desde el centro).
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
