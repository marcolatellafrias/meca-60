extends Node

## LOS TABLEROS DEL ARTILLERO, DESDE SUS OJOS (18/11/2026; ver GunnerTurret, «Los tres tableros»): la meca jaula de 3,
## la cámara en los ojos del artillero, mirando al tablero del medio (las armas), al de la izquierda (la munición), al de
## la derecha (el estado de la meca) y, de cerca, los tres. Una hoja: tableros_artillero.png.
##   tools/godot_ventana.sh res://tests/gunner_boards_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)

var _folder := ""
var _mech: CageMech = null
var _eye: Camera3D = null
var _title: Label = null
var _shots: Array = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	for k in 8:
		var angle := TAU * k / 8.0
		Clay.box(ground, Vector3(2.0, 4.0, 2.0), Vector3(sin(angle) * 30.0, 2.0, -cos(angle) * 30.0), Color(0.6, 0.35, 0.3))
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
	_eye = Camera3D.new()
	_eye.near = 0.02
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 10)
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	_mech = CageMech.new()
	_mech.scripted = true
	_mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
	add_child(_mech)
	await get_tree().create_timer(2.0).timeout
	for found in get_tree().root.find_children("*", "Label3D", true, false):
		(found as Label3D).visible = false
	var seat := (_mech.cabin as CageCabin).turret.frame.global_transform
	var eye := seat * Vector3(0.0, 1.15, 0.02)
	await _shot("1. al medio: las armas", eye, seat * Vector3(0.0, 0.92, -0.52), 60.0)
	await _shot("2. a la izquierda: la munición", eye, seat * Vector3(-0.36, 0.82, -0.44), 60.0)
	await _shot("3. a la derecha: el estado de la meca", eye, seat * Vector3(0.36, 0.82, -0.44), 60.0)
	await _shot("los tres, desde los ojos", eye, eye + seat.basis * Vector3(0.0, -1.6, -3.0), 85.0)
	_save()
	get_tree().quit()


func _shot(name_of: String, from: Vector3, to: Vector3, fov: float) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	_title.text = name_of
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	_shots.append(get_viewport().get_texture().get_image())


func _save() -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(_shots.size() / 2.0), false, first.get_format())
	for index in _shots.size():
		var shot: Image = _shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/tableros_artillero.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
