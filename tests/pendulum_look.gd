extends Node

## EL CUBO PÉNDULO, PARA MIRARLO RÁPIDO (unos 10 segundos, sin el sandbox): un piso, el cubo, una captura de cerca de las
## piernas y la caída con la recuperación cuadro a cuadro. No mide: es para ver el aspecto y la secuencia.
##   tools/godot_ventana.sh res://tests/pendulum_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _cube: PendulumCube = null
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
	Clay.shape_box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 215.0, 0.0)
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
	_cube = PendulumCube.new()
	_cube.position = Vector3(0.0, PendulumCubeSettings.shared.hover_height + HoverCube.SIZE * 0.5, 0.0)
	add_child(_cube)
	_eye = Camera3D.new()
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	await _seconds(1.0)
	# De frente y de tres cuartos, de cerca: las piernas, los discos y la pelvis.
	_eye.global_position = Vector3(0.0, 5.0, -24.0)
	_eye.look_at(Vector3(0.0, 5.5, 0.0))
	await _shot("De frente", "1_frente")
	_eye.global_position = Vector3(-17.0, 6.0, -17.0)
	_eye.look_at(Vector3(0.0, 5.0, 0.0))
	await _shot("De tres cuartos", "2_tres_cuartos")
	_eye.global_position = Vector3(-26.0, 4.0, 0.0)
	_eye.look_at(Vector3(0.0, 5.0, 0.0))
	await _shot("De costado", "3_costado")
	# LA CAÍDA Y LA RECUPERACIÓN, cada 0,3 s desde que queda tirado.
	_cube.knock(true)
	var clock := 0.0
	var shots := 0
	var next := 0.0
	while clock < 14.0 and not (_cube.falls > 0 and _cube.state == HoverCube.State.HOVER):
		await get_tree().physics_frame
		clock += 1.0 / 240.0
		if _cube.state in [HoverCube.State.LIFT, HoverCube.State.RIGHT] and clock >= next and shots < 14:
			next = clock + 0.3
			var at := _cube.global_position
			_eye.global_position = at + Vector3(-10.0, 4.0 - at.y * 0.3, -30.0)
			_eye.look_at(Vector3(at.x, 6.0, at.z))
			await _shot("%s · %.1f s · inclinación %.0f° · centro a %.1f m" % [
				"sube y se endereza" if _cube.state == HoverCube.State.LIFT else "termina de enderezarse", clock,
				_cube.tilt, _cube.height], "4_%02d" % shots)
			shots += 1
	print("RECUPERADO a los %.1f s · estado %d" % [clock, _cube.state])
	get_tree().quit()


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
