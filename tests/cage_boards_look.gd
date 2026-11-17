extends Node

## LOS TABLEROS DE LA JAULA, PARA VERLOS (CageBoards, FaceBoard, FaceMount): la parcela de la meca jaula con la grilla a la
## vista, la lista de caras con sus celdas y fotos desde la silla del que maneja, la del de los brazos y tres caras de
## frente.
##   tools/godot_ventana.sh res://tests/cage_boards_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)

var _folder := ""
var _eye: Camera3D = null
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
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	_eye.near = 0.02
	add_child(_eye)
	_eye.make_current()
	var holder := Node3D.new()
	add_child(holder)
	CageBoards.show_grid = true
	CageMechArchetype.new().build(0, holder)
	var mech: CageMech = null
	for found in holder.find_children("*", "CageMech", true, false):
		if found.arms_kind != Mech.Arms.NONE or mech == null:
			mech = found
	mech.scripted = true
	var form := CageCabin.shape()
	for board: FaceBoard in CageCabin.capsule_boards(form) + CageCabin.upper_boards(form):
		var counts := board.counts()
		print("CARA ", board.name, " ", board.size.x, "×", board.size.y, " · piezas ", counts[FaceBoard.Kind.MODULES],
			" · marco ", counts[FaceBoard.Kind.FRAME], " · nada ", counts[FaceBoard.Kind.NONE])
	var controls := mech.find_children("*", "ControllableInteractable", true, false)
	print("CONTROLES ", controls.size(), " TABLEROS ", mech.find_children("*", "FaceMount", true, false).size())
	await get_tree().create_timer(1.0).timeout
	var cabin := mech.cabin as CageCabin
	for seat in CageCabin.SEAT_NAMES.size():
		cabin.evict(seat)
	await get_tree().create_timer(0.5).timeout
	var base := cabin.board_root().global_transform
	var driver := base * CageCabin.driver_eye(form)
	var arms := base * Vector3(0.0, form.height() + form.arms_eye, 0.05)
	var forward := -mech.global_basis.z
	var right := mech.global_basis.x
	var up := Vector3.UP
	await _shot(driver, driver + right + forward * 0.3, 85.0)
	await _shot(driver, driver - right + forward * 0.3, 85.0)
	await _shot(driver, driver + right * 0.7 + up * 0.8 + forward * 0.2, 85.0)
	await _shot(arms, arms + forward - up * 0.9, 85.0)
	await _shot(arms, arms + forward + right * 1.1 - up * 0.9, 85.0)
	await _shot(arms, arms + forward - right * 1.1 - up * 0.9, 85.0)
	# DE FRENTE Y SIN PERSPECTIVA, para ver si cada control cae en sus celdas.
	for wanted: String in ["cápsula derecha", "cápsula derecha arriba", "tablero adelante derecha"]:
		for board: FaceBoard in CageCabin.capsule_boards(form) + CageCabin.upper_boards(form):
			if board.name == wanted:
				await _straight(base * board.frame, board.size)
	_save()
	get_tree().quit()


func _shot(from: Vector3, to: Vector3, fov: float) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(VIEW.x / 2, VIEW.y / 2, Image.INTERPOLATE_BILINEAR)
	_shots.append(image)


func _straight(face: Transform3D, cells: Vector2i) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var cell := ProceduralDashboard.CELL
	var middle := face * Vector3(cells.x * 0.5 * cell, -cells.y * 0.5 * cell, 0.0)
	_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
	_eye.size = maxf(cells.y, cells.x * VIEW.y / float(VIEW.x)) * cell * 1.15
	_eye.global_transform = Transform3D(face.basis, middle + face.basis.z.normalized() * 1.0)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(VIEW.x / 2, VIEW.y / 2, Image.INTERPOLATE_BILINEAR)
	_shots.append(image)
	_eye.projection = Camera3D.PROJECTION_PERSPECTIVE


func _save() -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var columns := 3
	var rows := ceili(_shots.size() / float(columns))
	var sheet := Image.create(first.get_width() * columns, first.get_height() * rows, false, first.get_format())
	for index in _shots.size():
		sheet.blit_rect(_shots[index], Rect2i(Vector2i.ZERO, first.get_size()),
			Vector2i(first.get_width() * (index % columns), first.get_height() * (index / columns)))
	var path := "%s/tableros_jaula.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
