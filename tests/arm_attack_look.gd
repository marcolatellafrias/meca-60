extends Node

## LOS ATAQUES DEL PALO, PARA ELEGIR (16/11/2026; el usuario: «en la de pegar con el palo podés hacer 2 alternativas,
## más la base»): una meca jaula por ataque, en fila, que pegan a la vez con el brazo del palo (con músculos). Se para el
## tiempo en tres momentos —armándose, armado, pegando— y se saca de cada una una foto de tres cuartos; pegando, también
## lo que ve el que maneja. Una hoja: una fila por ataque.
##   tools/godot_ventana.sh res://tests/arm_attack_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const GAP := 10.0
const CELL := Vector2i(480, 270)

## Los ataques: el nombre, la piña de MechArm que se tira y, si va por otro camino, sus puntos (como MechArm.PUNCHES:
## en cuánto llega a cada punto y dónde, desde el hombro, en el largo de los brazos: x afuera, y arriba, −z adelante).
const ATTACKS := [
	["1. hoy: el directo", MechArm.Punch.STRAIGHT, []],
	["2. mazazo de arriba", MechArm.Punch.HAMMER, []],
	["3. barrido de costado, abierto y bajo", MechArm.Punch.HOOK,
		[[0.5, Vector3(5.0, -2.0, -1.5)], [0.3, Vector3(-6.0, -2.5, -6.5)], [0.2, Vector3(-6.0, -2.5, -6.5)]]],
]
## Los momentos (s desde que tira, a la velocidad de las piñas) y su nombre.
const MOMENTS := [[0.25, "armándose"], [0.5, "armado"], [0.8, "pegando"]]

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
## Una fila de fotos por ataque.
var _rows: Array = []


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
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 44)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 12)
	layer.add_child(_title)
	var mechs: Array[CageMech] = []
	for index in ATTACKS.size():
		var mech := CageMech.new()
		mech.scripted = true
		mech.position = Vector3(index * GAP, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
		add_child(mech)
		mechs.append(mech)
		_rows.append([])
	await get_tree().create_timer(2.5).timeout
	for mech in mechs:
		(mech.cabin as CageCabin).evict(CageCabin.DRIVER)
	await get_tree().create_timer(0.3).timeout
	var speed := mechs[0].melee._punch_speed()
	for index in ATTACKS.size():
		var arm := mechs[index].melee
		arm.punch(ATTACKS[index][1])
		if not (ATTACKS[index][2] as Array).is_empty():
			arm._aimed = ATTACKS[index][2]
	var clock := 0.0
	for moment: Array in MOMENTS:
		var at := float(moment[0]) / speed
		await get_tree().create_timer(at - clock).timeout
		clock = at
		Engine.time_scale = 0.0
		for index in ATTACKS.size():
			var mech := mechs[index]
			var spot := mech.global_position
			var forward := -mech.global_basis.z
			var right := mech.global_basis.x
			await _shot(index, "%s · %s" % [ATTACKS[index][0], moment[1]],
				spot + forward * 6.0 + right * 7.0 + Vector3.UP * 1.5, spot + right * 1.0, 50.0)
			if moment == MOMENTS.back():
				var eye: Vector3 = mech.global_transform * (mech.cabin.top_seat() + Vector3(0.0, SeatInteractable.STATION_EYE_HEIGHT, 0.0))
				await _shot(index, "%s · desde adentro" % ATTACKS[index][0], eye, eye + forward * 10.0 + Vector3.DOWN, 75.0)
		Engine.time_scale = 1.0
	_save()
	get_tree().quit()


func _shot(row: int, name_of: String, from: Vector3, to: Vector3, fov: float) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	_title.text = name_of
	for i in 3:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(CELL.x, CELL.y, Image.INTERPOLATE_BILINEAR)
	(_rows[row] as Array).append(image)


func _save() -> void:
	if (_rows[0] as Array).is_empty():
		return
	var columns := (_rows[0] as Array).size()
	var first: Image = _rows[0][0]
	var sheet := Image.create(CELL.x * columns, CELL.y * _rows.size(), false, first.get_format())
	for row in _rows.size():
		for column in (_rows[row] as Array).size():
			var shot: Image = _rows[row][column]
			sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, CELL), Vector2i(CELL.x * column, CELL.y * row))
	var path := "%s/ataques_palo.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
