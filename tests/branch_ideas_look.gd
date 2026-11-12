extends Node3D

## LAS IDEAS DE SUCURSAL, PARA MIRAR (unos 15 segundos, sin el sandbox): arma una por una las seis de BranchIdeas, con
## una meca de bulto estacionada (15 m, con su pasarela de abajo marcada en blanco) y dos personas (1,8 m), y de cada
## una guarda UNA captura con dos vistas: de arriba y a la altura de una persona.
##   tools/godot_ventana.sh res://tests/branch_ideas_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const MECH := Color(0.86, 0.42, 0.14)
const PERSON := Color(0.95, 0.2, 0.55)

var _folder := ""
var _eye: Camera3D
var _title: Label
var _line: Label


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 300.0
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
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = _label(layer, 56, Vector2(24, 12))
	_line = _label(layer, 30, Vector2(24, VIEW.y - 96))
	_line.size = Vector2(VIEW.x - 48, 90)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	for index in BranchIdeas.NAMES.size():
		await _shoot(index)
	get_tree().quit()


func _label(layer: CanvasLayer, font: int, at: Vector2) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font)
	label.add_theme_color_override("font_color", Color.BLACK)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 10)
	layer.add_child(label)
	return label


func _shoot(index: int) -> void:
	var place := BranchIdeas.build(index, self)
	var view := BranchIdeas.viewpoint(index)
	_dummy(place, view[0])
	Clay.box(place, Vector3(0.5, 1.8, 0.3), view[0] * Vector3(1, 0, 1) + Vector3(BranchIdeas.BAY.x * 0.5 + 2.0, 0.9,
		-BranchIdeas.BAY.y * 0.5), PERSON)
	Clay.box(place, Vector3(0.5, 1.8, 0.3), view[0] + Vector3(-2.0, BranchIdeas.DECK + 0.9, 5.2), PERSON)
	_title.text = "%d · %s" % [index + 1, BranchIdeas.NAMES[index]]
	_line.text = BranchIdeas.LINES[index]
	_eye.fov = 42.0
	_eye.global_position = Vector3(0.0, 110.0, 34.0)
	_eye.look_at(Vector3(0.0, 0.0, 6.0))
	var above := await _grab()
	_line.text = ""
	_title.text = "%d · a la altura de una persona" % (index + 1)
	_eye.fov = 70.0
	_eye.global_position = view[1]
	_eye.look_at(view[2])
	var level := await _grab()
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		var sheet := Image.create(above.get_width(), above.get_height() + level.get_height(), false, above.get_format())
		sheet.blit_rect(above, Rect2i(Vector2i.ZERO, above.get_size()), Vector2i.ZERO)
		sheet.blit_rect(level, Rect2i(Vector2i.ZERO, level.get_size()), Vector2i(0, above.get_height()))
		var path := "%s/sucursal_%d.png" % [_folder, index + 1]
		sheet.save_png(path)
		print("CAPTURA ", path)
	place.queue_free()
	await get_tree().process_frame


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


## La meca de bulto, parada en `at` y mirando a −Z (por donde sale): la caja de 8 m con su cara de abajo a 7,4 m, la
## pasarela en U de abajo (atrás y los costados, en blanco), dos piernas y dos brazos.
func _dummy(parent: Node3D, at: Vector3) -> void:
	var deck := BranchIdeas.DECK
	Clay.box(parent, Vector3.ONE * 8.0, at + Vector3(0, deck + 4.0, 0), MECH)
	Clay.box(parent, Vector3(10.2, 0.2, 1.1), at + Vector3(0, deck, 4.55), BranchIdeas.WALK)
	for side: float in [-1.0, 1.0]:
		Clay.box(parent, Vector3(1.1, 0.2, 6.2), at + Vector3(side * 4.55, deck, 0.9), BranchIdeas.WALK)
		Clay.box(parent, Vector3(1.4, deck - 1.0, 1.4), at + Vector3(side * 1.6, (deck - 1.0) * 0.5, 0), MECH.darkened(0.25))
		Clay.box(parent, Vector3(1.4, 6.5, 1.4), at + Vector3(side * 5.6, deck + 4.5, -2.6), MECH.darkened(0.25))
	Clay.box(parent, Vector3(4.0, 1.4, 3.0), at + Vector3(0, deck - 0.7, 0), MECH.darkened(0.25))
