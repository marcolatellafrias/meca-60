extends Node3D

## LOS PASOS NUEVOS DE LA MECA (LegSettings, el sistema clásico de piernas con IK), PARA MIRARLOS: la meca simplificada
## camina derecho, gira en el lugar, frena y sube a un escalón. Imprime el largo de los pasos en el mundo, si alguna vez
## estuvieron los dos pies en el aire, cuánto quedan corridos de su lugar después de frenar y a qué altura pisa arriba
## del escalón. Con ventana, capturas numeradas. Unos 20 segundos.
##   tools/godot_ventana.sh res://tests/mech_steps_look.tscn -- --salida=C:/carpeta

const STEP_UP := 1.5

var _folder := ""
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null
var _last: Array[Vector3] = []
var _lengths: Array[float] = []
var _landings: Array[float] = []


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
	Clay.shape_box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	for i in range(-40, 41):
		Clay.box(ground, Vector3(400, 0.02, 0.25), Vector3(0, 0.0, i * 5.0), Color(0.7, 0.68, 0.64))
	# EL ESCALÓN, a la derecha del recorrido: la meca pasa con un pie arriba y otro abajo.
	Clay.solid(ground, Vector3(6.0, STEP_UP, 60.0), Vector3(4.5, STEP_UP * 0.5, -70.0), Clay.METAL.lightened(0.3))
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
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.NONE
	# Con «--fisica», la física (sin cilindro contra lo fijo: pasa al lado del escalón).
	_mech.kinematic = not OS.get_cmdline_user_args().has("--fisica")
	_mech.has_cabin = false
	_mech.scripted = true
	# Con «--redonda», la caja de la cabina redonda.
	if OS.get_cmdline_user_args().has("--redonda"):
		_mech.cabin_shape = Mech.Cabin.ROUND
	_mech.position = Vector3(0.0, Mech.standing_height(_mech.cabin_shape), 0.0)
	add_child(_mech)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await _watch(1.0)
	print("PASOS NUEVOS: %s · largo del paso %.1f m (piernas medianas ×%.2f)" % [LegSettings.current.new_steps,
		LegSettings.current.stride, MechBody.stride])
	# CAMINA DERECHO.
	_mech.move = Vector2(0.0, 1.0)
	await _watch(2.0)
	_look(Vector3(-18.0, 4.0, 6.0))
	await _shot("1. caminando derecho: un pie en el aire por vez", "1_caminando")
	await _watch(1.0)
	_report("CAMINANDO")
	# FRENA.
	_mech.move = Vector2.ZERO
	await _watch(2.0)
	print("FRENADA: los pies quedaron a %.2f m y %.0f° de su lugar · pasos %d" % [_off(), _turned(), _mech.legs.steps_taken])
	_look(Vector3(-14.0, 6.0, 14.0))
	await _shot("2. frenada: los pies vuelven a su lugar", "2_frenada")
	# GIRA EN EL LUGAR.
	var before := _mech.legs.steps_taken
	_mech.aim_yaw += PI * 0.5
	await _watch(1.0)
	_look(Vector3(-16.0, 8.0, 12.0))
	await _shot("3. girando en el lugar: da pasos solo", "3_girando")
	await _watch(2.0)
	if OS.has_environment("PASOS_DEBUG"):
		for i in 2:
			print("  pie ", i, " ", _mech.legs._feet[i].snapped(Vector3.ONE * 0.01), " lugar ", _mech.legs._home(i, _mech.yaw(), 0.0).snapped(Vector3.ONE * 0.01), " apoyo ", _mech.support.snapped(Vector3.ONE * 0.01), " vel ", _mech.support_speed.snapped(Vector3.ONE * 0.01))
	print("GIRO DE 90° EN EL LUGAR: %d pasos · después, a %.2f m y %.0f° de su lugar" % [_mech.legs.steps_taken - before,
		_off(), _turned()])
	# EL ESCALÓN: vuelve a mirar adelante y camina por al lado, con el pie derecho arriba.
	_mech.aim_yaw -= PI * 0.5
	await _watch(1.5)
	_lengths.clear()
	_landings.clear()
	_mech.move = Vector2(0.0, 1.0)
	await _until(func() -> bool: return _mech.support.z < -60.0, 12.0)
	_look(Vector3(-16.0, 5.0, 8.0))
	await _shot("4. al lado del escalón: el pie derecho pisa arriba", "4_escalon")
	var tops := 0
	for y in _landings:
		if absf(y - STEP_UP) < 0.05:
			tops += 1
	print("ESCALÓN: de %d pisadas del pie derecho, %d arriba (a %.1f m)" % [_landings.size(), tops, STEP_UP])
	get_tree().quit()


func _report(title: String) -> void:
	var total := 0.0
	var least := INF
	var most := 0.0
	for length in _lengths:
		total += length
		least = minf(least, length)
		most = maxf(most, length)
	print("%s: %d pasos · largo en el mundo %.2f m en promedio (de %.2f a %.2f) · velocidad %.1f m/s" % [title,
		_lengths.size(), total / maxf(_lengths.size(), 1), least, most, Vector2(_mech.support_speed.x, _mech.support_speed.z).length()])


## Cuánto quedaron corridos los pies de su lugar, lo más (m) y lo más girados (°).
func _off() -> float:
	var most := 0.0
	for i in 2:
		var off: Vector3 = _mech.legs._feet[i] - _mech.legs._home(i, _mech.yaw(), 0.0)
		off.y = 0.0
		most = maxf(most, off.length())
	return most


func _turned() -> float:
	var most := 0.0
	for i in 2:
		most = maxf(most, absf(rad_to_deg(angle_difference(_mech.legs._feet_yaw[i], _mech.yaw()))))
	return most


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


## Cada pisada: cuánto se movió ese pie desde la anterior, y a qué altura pisó el derecho.
func _measure() -> void:
	var feet: Array[Vector3] = _mech.legs._feet
	if _last.is_empty():
		_last.assign(feet)
		return
	for i in 2:
		if feet[i].distance_to(_last[i]) > 0.01:
			_lengths.append(Vector2(feet[i].x - _last[i].x, feet[i].z - _last[i].z).length())
			if i == 1:
				_landings.append(feet[i].y)
				if OS.has_environment("PASOS_DEBUG"):
					print("  pisada derecha ", feet[i].snapped(Vector3.ONE * 0.01), " meca ", _mech.support.snapped(Vector3.ONE * 0.01), " yaw ", snappedf(rad_to_deg(_mech.yaw()), 1))
			_last[i] = feet[i]


func _look(offset: Vector3) -> void:
	var at := _mech.support + Vector3(0.0, 4.0, 0.0)
	_eye.global_position = at + offset
	_eye.look_at(at)


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
