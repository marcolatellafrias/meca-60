extends Node3D

## LAS IDEAS DE MAPA, PARA MIRAR (unos 15 segundos, sin el sandbox): arma una por una las seis de BattlefieldIdeas, con
## una meca de bulto (15 m) y una persona (1,8 m) para la escala, y de cada una guarda UNA captura con dos vistas: de
## arriba y a la altura de la meca.
##   tools/godot_ventana.sh res://tests/map_ideas_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const MECH := Color(0.86, 0.42, 0.14)
const PERSON := Color(0.95, 0.2, 0.55)

var _folder := ""
var _eye: Camera3D
var _title: Label


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 600.0
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 12)
	_title.add_theme_font_size_override("font_size", 56)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 12)
	layer.add_child(_title)
	for index in BattlefieldIdeas.NAMES.size():
		await _shoot(index)
	get_tree().quit()


func _shoot(index: int) -> void:
	var map := BattlefieldIdeas.build(index, self)
	var view := BattlefieldIdeas.viewpoint(index)
	var at := view[0]
	var toward := view[1].normalized()
	_dummy(map, at, toward)
	_title.text = "%d · %s" % [index + 1, BattlefieldIdeas.NAMES[index]]
	_eye.fov = 36.0
	_eye.global_position = Vector3(0.0, 250.0, 150.0)
	_eye.look_at(Vector3(0.0, 0.0, 8.0))
	var above := await _grab()
	_title.text = "%d · desde la meca" % (index + 1)
	_eye.fov = 60.0
	_eye.global_position = at - toward * 30.0 + Vector3.UP * 17.0
	_eye.look_at(at + toward * 40.0 + Vector3.UP * 6.0)
	var level := await _grab()
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		var sheet := Image.create(above.get_width(), above.get_height() + level.get_height(), false, above.get_format())
		sheet.blit_rect(above, Rect2i(Vector2i.ZERO, above.get_size()), Vector2i.ZERO)
		sheet.blit_rect(level, Rect2i(Vector2i.ZERO, level.get_size()), Vector2i(0, above.get_height()))
		var path := "%s/mapa_%d.png" % [_folder, index + 1]
		sheet.save_png(path)
		print("CAPTURA ", path)
	map.queue_free()
	await get_tree().process_frame


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


## La meca de bulto (la caja de 8 m con su cara de abajo a 7,4 m, dos piernas y dos brazos) y una persona al lado.
func _dummy(parent: Node3D, at: Vector3, toward: Vector3) -> void:
	var root := Node3D.new()
	parent.add_child(root)
	root.position = at
	root.basis = Basis.looking_at(toward)
	Clay.box(root, Vector3.ONE * 8.0, Vector3(0, 11.4, 0), MECH)
	Clay.box(root, Vector3(4.0, 1.6, 3.0), Vector3(0, 6.6, 0), MECH.darkened(0.25))
	for side: float in [-1.0, 1.0]:
		Clay.box(root, Vector3(1.4, 6.0, 1.4), Vector3(side * 1.6, 3.0, 0), MECH.darkened(0.25))
		Clay.box(root, Vector3(1.4, 6.5, 1.4), Vector3(side * 4.9, 10.0, 0), MECH.darkened(0.25))
	Clay.box(root, Vector3(0.5, 1.8, 0.3), Vector3(7.0, 0.9, -3.0), PERSON)
