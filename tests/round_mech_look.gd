extends Node3D

## LA MECA REDONDA DE VERDAD, PARA MIRAR (unos 10 segundos, sin el sandbox; ver RoundCabin, RoundGrid): de frente, de
## costado, de atrás, desde la silla del movimiento, desde atrás de ella, y desde arriba sin techo.
##   tools/godot_ventana.sh res://tests/round_mech_look.tscn -- --salida=C:/carpeta [--domo]

const VIEW := Vector2i(1280, 720)

var _folder := ""
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -40.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	world.environment.ambient_light_energy = 1.0
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	# `--domo`: la forma guardada, con el domo (ver RoundGrid.DOME).
	if OS.get_cmdline_user_args().has("--domo"):
		var form := RoundGrid.current()
		form.dome = true
		RoundGrid.apply(form)
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.POSE
	_mech.cabin_shape = Mech.Cabin.ROUND
	_mech.position = Vector3(0.0, Mech.standing_height(Mech.Cabin.ROUND), 0.0)
	add_child(_mech)
	await get_tree().create_timer(3.0).timeout
	_mech.freeze = true
	if _mech.label != null:
		_mech.label.visible = false
	print("REDONDA: %.2f m de diámetro · %.2f m de alto · %d lados · la caja a %.2f m del piso" % [RoundGrid.OUTER * 2.0,
		RoundGrid.HEIGHT, RoundGrid.SIDES, Mech.standing_height(Mech.Cabin.ROUND)])
	var shots: Array = []
	_title.text = "1. De frente"
	_look(Vector3(-14.0, 0.0, -22.0), Vector3(0.0, -3.5, 0.0), 45.0)
	shots.append(await _grab())
	_title.text = "2. De costado"
	_look(Vector3(-26.0, -2.0, -3.0), Vector3(0.0, -3.5, 0.0), 42.0)
	shots.append(await _grab())
	_title.text = "3. De atrás"
	_look(Vector3(13.0, 0.0, 22.0), Vector3(0.0, -3.5, 0.0), 45.0)
	shots.append(await _grab())
	for dummy in find_children("*", "BoneInstantiator", true, false):
		(dummy as Node3D).visible = false
	_title.text = "4. Desde la silla del movimiento"
	var top := RoundGrid.top_seat()
	_look(top + Vector3(0.0, 1.25, 0.1), top + Vector3(0.0, 0.6, -4.0), 80.0)
	shots.append(await _grab())
	_title.text = "5. Adentro, desde atrás"
	_look(Vector3(0.5, RoundGrid.floor_top() + 1.8, RoundGrid.APOTHEM - 0.4), Vector3(0.0, RoundGrid.floor_top() + 0.6,
		-2.5), 85.0)
	shots.append(await _grab())
	for dummy in find_children("*", "BoneInstantiator", true, false):
		(dummy as Node3D).visible = true
	var roof := _mech.cabin.get_node_or_null("Techo") as Node3D
	if roof != null:
		roof.visible = false
	_title.text = "6. Desde arriba, sin techo"
	_look(Vector3(-2.0, RoundGrid.HALF_HEIGHT + 11.0, 4.0), Vector3(0.0, RoundGrid.floor_top(), -0.3), 50.0)
	shots.append(await _grab())
	_save(shots)
	get_tree().quit()


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _mech.global_transform * from
	_eye.look_at(_mech.global_transform * to, Vector3.UP)


func _save(shots: Array) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var first: Image = shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(shots.size() / 2.0), false, first.get_format())
	for index in shots.size():
		var shot: Image = shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/meca_redonda.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
