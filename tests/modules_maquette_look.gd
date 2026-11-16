extends Node3D

## LA MAQUETA CAMINABLE DE LA MECA POR MÓDULOS (ModulesMaquette), mirada como la ve uno parado adentro.
##   tools/godot_ventana.sh res://tests/modules_maquette_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _eye: Camera3D = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	add_child(world)
	_eye = Camera3D.new()
	add_child(_eye)
	_eye.make_current()
	ModulesMaquette.build(self)
	var body := MechBody.current
	var floor_y := (body.WAIST - body.HIP_DROP) * ModulesMaquette.LIMBS + 0.66 + ModulesMaquette.SILL
	var shift := ModulesMaquette.shift()
	print("PISO ", floor_y)
	await get_tree().create_timer(2.0).timeout
	var shots: Array = []
	shots.append(await _view(Vector3(-15.0, 13.0, -17.0), Vector3(0.0, floor_y - 2.0, 0.0), 45.0))
	var stand := Vector3(0.0, floor_y + 1.65, ModulesMaquette.LOBBY_LONG - 0.3 + shift)
	shots.append(await _view(stand, stand + Vector3(0.0, -0.2, -1.0), 80.0))
	shots.append(await _view(Vector3(-40.0, floor_y, 0.0), Vector3(0.0, floor_y, 0.0), 0.0, 9.0))
	var seat := Vector3(0.55, floor_y + 1.2, -ModulesMaquette.FRONT_LONG + 0.95 + shift)
	shots.append(await _view(seat, seat + Vector3(-1.0, -0.1, 0.2), 80.0))
	_save(shots)
	get_tree().quit()


func _view(from: Vector3, to: Vector3, fov: float, ortho := 0.0) -> Image:
	if fov > 0.0:
		_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
		_eye.fov = fov
	else:
		_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		_eye.size = ortho
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.FORWARD)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array) -> void:
	if _folder.is_empty():
		return
	var first: Image = shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * 2, false, first.get_format())
	for index in shots.size():
		var shot: Image = shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	sheet.save_png("%s/maqueta_modulos.png" % _folder)
	print("CAPTURA")
