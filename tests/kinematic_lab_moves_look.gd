extends Node

## LA LOCOMOCIÓN DEL CUBO CINEMÁTICO, MEDIDA (unos 25 segundos, sin cajas): un dash de costado en el piso, Q sin
## dirección (no tiene que pasar nada), un dash de costado en lo alto de un salto y el vuelo. Imprime cuánto lo corre
## cada dash, cuánto sube volando y las barras. Con ventana, capturas de las toberas.
##   tools/godot_ventana.sh res://tests/kinematic_lab_moves_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _pillar: KinematicPillar = null
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
	Clay.shape_box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	for i in range(-40, 41):
		Clay.box(ground, Vector3(600, 0.02, 0.2), Vector3(0, 0.0, i * 5.0), Color(0.7, 0.68, 0.64))
		Clay.box(ground, Vector3(0.2, 0.02, 600), Vector3(i * 5.0, 0.0, 0), Color(0.7, 0.68, 0.64))
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
	_pillar = KinematicPillar.new()
	add_child(_pillar)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await _wait(1.0)
	# DASH EN EL PISO, de costado.
	var from := _pillar.global_position
	await _dash(Vector2(1.0, 0.0), "1. dash en el piso, a la derecha: las toberas de la izquierda", "1_dash_piso")
	await _wait(2.5)
	print("DASH EN EL PISO: lo corrió %.1f m · barra del dash %d %%" % [_flat(_pillar.global_position - from),
		roundi(_pillar.dash_fuel * 100.0)])
	# Q SIN DIRECCIÓN.
	from = _pillar.global_position
	var fuel := _pillar.dash_fuel
	await _dash(Vector2.ZERO, "", "")
	await _wait(1.5)
	print("Q SIN DIRECCIÓN: lo corrió %.2f m · gastó barra %s" % [_flat(_pillar.global_position - from),
		_pillar.dash_fuel < fuel - 0.01])
	await _wait(2.0)
	# DASH EN EL AIRE, en lo alto.
	_pillar.jump = true
	await _wait(0.1)
	_pillar.jump = false
	while _pillar.velocity.y > 0.0:
		await _wait(1.0 / Engine.physics_ticks_per_second)
	from = _pillar.global_position
	await _dash(Vector2(-1.0, 0.0), "2. dash en el aire, a la izquierda", "2_dash_aire")
	while not _pillar.grounded:
		await _wait(1.0 / Engine.physics_ticks_per_second)
	await _wait(2.0)
	print("DASH EN EL AIRE: lo corrió %.1f m hasta frenar" % _flat(_pillar.global_position - from))
	# EL VUELO: salta, suelta y vuelve a apretar.
	_pillar.jump = true
	await _wait(0.1)
	_pillar.jump = false
	await _wait(0.3)
	_pillar.jump = true
	var top := 0.0
	var clock := 0.0
	var shot := false
	while _pillar.fly_fuel > 0.0 and clock < 6.0:
		await _wait(1.0 / Engine.physics_ticks_per_second)
		clock += 1.0 / Engine.physics_ticks_per_second
		top = maxf(top, _pillar.global_position.y)
		if not shot and clock > 1.0:
			shot = true
			_look(Vector3(-26.0, -4.0, 18.0))
			await _shot("3. volando: las toberas de abajo", "3_vuelo")
	_pillar.jump = false
	print("VUELO: subió hasta %.1f m en %.1f s, hasta vaciar la barra" % [top, clock])
	await _wait(4.0)
	print("VUELO: la barra, después de 4 s apoyado: %d %%" % roundi(_pillar.fly_fuel * 100.0))
	get_tree().quit()


func _dash(way: Vector2, title: String, file_name: String) -> void:
	_pillar.move = way
	await _wait(0.05)
	_pillar.dash = true
	await _wait(0.06)
	_pillar.dash = false
	if not file_name.is_empty():
		_look(Vector3(-20.0, 10.0, 24.0))
		await _shot(title, file_name)
	await _wait(0.15)
	_pillar.move = Vector2.ZERO


func _flat(change: Vector3) -> float:
	return Vector2(change.x, change.z).length()


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second


func _look(offset: Vector3) -> void:
	var at := _pillar.global_position + Vector3.UP * 8.0
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
