extends Node3D

## LA CABINA SOBRE SU TRAMA, PARA MIRAR (unos 10 segundos por forma, sin el sandbox): por cada forma, una meca discreta
## parada, de frente; de costado, cortada (sin la pared izquierda, el techo ni el vidrio); desde la silla del movimiento,
## arriba; y desde arriba, sin techo. Imprime las medidas (ver CabinGrid).
##   tools/godot_ventana.sh res://tests/cabin_grid_look.tscn -- --salida=C:/carpeta --celdas=13,11
## `--celdas=13,11`: las celdas de trama (en celdas chicas) que mira; sin eso, la guardada. Y, si se quiere, la misma
## forma con otro vidrio, tarima o marco: `--costados=9 --techo=6 --tarima=1.8 --marco=2 --ascensor_cuadrado=1` (ver CabinShape).
## La cabeza: `--cabeza=1` (en rampa) `--frente=73 --alto=96` (los altos libres, en celdas chicas) y `--zocalo=12`.
## Afuera, además del de frente, de perfil y de tres cuartos de atrás.

const VIEW := Vector2i(1280, 720)

var _folder := ""
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null
var _cells: Array[int] = []
var _changes := {}


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--celdas="):
			for each in argument.trim_prefix("--celdas=").split(","):
				_cells.append(int(each))
		for knob: String in ["costados:side_glass", "techo:roof_glass", "tarima:platform_height", "marco:frame_kind",
				"ascensor_cuadrado:lift_square", "cabeza:head", "frente:front_height_cells", "alto:height_cells", "zocalo:sill_cells",
				"chanfle:chamfer", "interior:interior", "pelvis:base_cells", "esquinas:corner_cells"]:
			var parts := knob.split(":")
			if argument.begins_with("--%s=" % parts[0]):
				_changes[parts[1]] = float(argument.trim_prefix("--%s=" % parts[0]))
	if _cells.is_empty():
		_cells.append(CabinGrid.TRAMA_CELLS)
	get_window().size = VIEW
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -60.0, 0.0)
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
	var shots: Array = []
	for cell in _cells:
		var form := CabinGrid.current()
		form.cell = cell
		for knob: String in _changes:
			var value: Variant = _changes[knob] if knob == "platform_height" else int(_changes[knob])
			form.set(knob, value == 1 if knob == "lift_square" else value)
		CabinGrid.shape(form)
		var name_of := "celda de %d cm · %.2f m por dentro · %.2f m libres" % [roundi(CabinGrid.TRAMA * 100.0),
			CabinGrid.INNER * 2.0, CabinGrid.CLEAR]
		print("TRAMA %s · caja de %.2f × %.2f m · ascensor de %.2f m de radio · sillas: %d" % [name_of, CabinGrid.SIZE,
			CabinGrid.HEIGHT, PelvisLift.hole(), CabinGrid.front_seats().size() + 1])
		_mech = Mech.new()
		_mech.arms_kind = Mech.Arms.POSE
		_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
		add_child(_mech)
		await get_tree().create_timer(2.5).timeout
		_mech.freeze = true
		if _mech.label != null:
			_mech.label.visible = false
		var k := CabinGrid.SIZE / 6.6
		_title.text = name_of
		_look(Vector3(-11.0, 1.5, -15.0) * k, Vector3(0.0, -0.5 * k, 0.0), 42.0)
		shots.append(await _grab())
		_title.text = "De perfil"
		_look(Vector3(-20.0, 0.5, 0.0) * k, Vector3(0.0, -0.5 * k, 0.0), 42.0)
		shots.append(await _grab())
		_title.text = "De tres cuartos, de atrás"
		_look(Vector3(-12.0, 4.0, 14.0) * k, Vector3(0.0, -0.5 * k, 0.0), 42.0)
		shots.append(await _grab())
		_title.text = "De frente, de cerca"
		_look(Vector3(-3.0, 1.0, -11.0) * k, Vector3(0.0, 0.0, 0.0), 42.0)
		shots.append(await _grab())
		var cut := _hide_left_and_roof()
		_title.text = "De costado, cortada"
		_look(Vector3(-24.0, 0.5, 0.0) * k, Vector3(0.0, -0.3, 0.0), 30.0)
		shots.append(await _grab())
		for dummy in find_children("*", "BoneInstantiator", true, false):
			(dummy as Node3D).visible = false
		_title.text = "Desde la silla del movimiento"
		var top := _mech.cabin.top_seat()
		_look(top + Vector3(0.0, 1.25, 0.1), top + Vector3(0.0, 0.2, -4.0), 80.0)
		shots.append(await _grab())
		_title.text = "Desde arriba, sin techo"
		_look(Vector3(-2.0, CabinGrid.HALF_HEIGHT + 9.0, -5.0), Vector3(0.0, CabinGrid.floor_top(), 0.3), 50.0)
		shots.append(await _grab())
		for part in cut:
			part.visible = true
		for dummy in find_children("*", "BoneInstantiator", true, false):
			dummy.free()
		_mech.free()
	_save(shots, "cabina_trama")
	get_tree().quit()


## Esconde la pared izquierda, el techo, el vidrio y el brazo izquierdo: lo que tapa.
func _hide_left_and_roof() -> Array[Node3D]:
	var hidden: Array[Node3D] = []
	for part in _mech.cabin.get_children():
		var mesh := part as MeshInstance3D
		if mesh == null:
			continue
		if mesh.name.begins_with("Vidrio") or mesh.name.begins_with("Techo") or mesh.position.x < -CabinGrid.HALF + 0.5 or mesh.position.y > CabinGrid.ceiling():
			mesh.visible = false
			hidden.append(mesh)
	if not _mech.arms.is_empty():
		_mech.arms[0].visible = false
		hidden.append(_mech.arms[0])
	return hidden


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _mech.global_transform * from
	_eye.look_at(_mech.global_transform * to, Vector3.UP)


## Dos columnas, a la mitad: cada forma, dos filas.
func _save(shots: Array, file: String) -> void:
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
	var path := "%s/%s.png" % [_folder, file]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
