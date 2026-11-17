extends Node

## LOS DOS TORSOS DE LA MECA JAULA, PARA VERLOS (CageShape.torso; 17/11/2026, el usuario: «dos torsos distintos para la
## meca y que yo pueda irlos cambiando»): la cuadrada de la forma guardada y tres redondas —el talle a la medida del
## octógono de arriba, a la de la cápsula con su marco, y el chanfle a la mitad—. Cada una se arma con su forma (la de
## todas es una sola, CageShape.current: se cambia un momento para armar cada una y se vuelve a poner). Imprime de cada
## una la caja, el hombro y las sillas, y saca una hoja: de frente, de tres cuartos, desde el que maneja y desde el de los
## brazos.
##   tools/godot_ventana.sh res://tests/cage_torsos_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const SPACING := 18.0
## [nombre, torso, talle, chanfle]
const PLAN := [
	["cuadrada", 0, 1.0, 0.0],
	["redonda, a la medida del octógono", 1, 1.0, 0.0],
	["redonda, a la medida de la cápsula", 1, 0.0, 0.0],
	["redonda, más cuadrada", 1, 1.0, 0.5],
	["redonda, el octógono girado 35°", 1, 1.0, 0.0],
]
## La última, con el módulo de arriba girado a mano (CageCabin.set_upper_yaw): lo que se ve y lo que se pisa.
const TURNED := deg_to_rad(35.0)

var _folder := ""
var _eye: Camera3D = null
var _shots: Array[Image] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	var form := CageShape.current
	var kept := [form.torso, form.body_size, form.body_chamfer]
	var mechs: Array[CageMech] = []
	var heights: Array[float] = []
	for index in PLAN.size():
		var entry: Array = PLAN[index]
		form.torso = entry[1]
		form.body_size = entry[2]
		form.body_chamfer = entry[3]
		var mech := CageMech.new()
		mech.equipment = "Meca jaula"
		mech.scripted = true
		mech.position = Vector3(-index * SPACING, Mech.standing_height(mech.cabin_shape), 0.0)
		add_child(mech)
		mechs.append(mech)
		heights.append(form.height())
		print("%s · CAJA %s · HOMBRO %s · OJOS %s · HUNDE %.2f" % [entry[0], CageCabin.box(), CageCabin.shoulder(),
			CageCabin.driver_eye(form), form.octagon_sink()])
		for chair in mech.cabin.chairs:
			print("   SILLA ", chair.name, " en ", snapped(chair.position, Vector3.ONE * 0.01))
	form.torso = kept[0]
	form.body_size = kept[1]
	form.body_chamfer = kept[2]
	await get_tree().create_timer(1.2).timeout
	for index in mechs.size():
		var cabin := mechs[index].cabin as CageCabin
		for seat in CageCabin.SEAT_NAMES.size():
			cabin.evict(seat)
		for label in mechs[index].find_children("*", "Label3D", true, false):
			(label as Label3D).visible = false
	var turned := mechs[mechs.size() - 1].cabin as CageCabin
	turned.set_upper_yaw(TURNED)
	var block := turned.upper.get_node_or_null("Bloque de arriba") as Node3D
	var solid := turned._upper_colliders[0][0] as CollisionShape3D
	print("GIRADO: el pivote %.1f° · el bloque cuelga de él: %s · su choque %.1f°" % [rad_to_deg(turned.upper.rotation.y),
		block != null, rad_to_deg(solid.transform.basis.get_euler().y)])
	await get_tree().create_timer(0.6).timeout
	for index in mechs.size():
		var mech := mechs[index]
		var cabin := mech.cabin as CageCabin
		var at := mech.global_position + Vector3(0.0, heights[index] * 0.25, 0.0)
		var far := 12.0 + heights[index] * 1.6
		await _shot(at + Vector3(0.0, 1.0, -far), at, 40.0)
		await _shot(at + Vector3(-far * 0.5, far * 0.6, -far * 0.6), at, 40.0)
		var root := cabin.board_root().global_transform
		# Los ojos de cada puesto, armados con la forma de esa meca (la de todas ya volvió a la guardada).
		var entry: Array = PLAN[index]
		form.torso = entry[1]
		form.body_size = entry[2]
		form.body_chamfer = entry[3]
		var driver := root * CageCabin.driver_eye(form)
		var arms := root * Vector3(0.0, form.height() + form.arms_eye, 0.05)
		form.torso = kept[0]
		form.body_size = kept[1]
		form.body_chamfer = kept[2]
		await _shot(driver, driver + Vector3(0.0, -0.15, -1.0), 85.0)
		await _shot(arms, arms + Vector3(0.0, -0.7, -1.0), 85.0)
	_save()
	get_tree().quit()


func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 215.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.85)
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	_eye.near = 0.02
	add_child(_eye)
	_eye.make_current()


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


## La hoja: una fila por meca (de frente, de tres cuartos, el que maneja, el de los brazos).
func _save() -> void:
	if _shots.is_empty():
		return
	var first := _shots[0]
	var columns := 4
	var rows := ceili(_shots.size() / float(columns))
	var sheet := Image.create(first.get_width() * columns, first.get_height() * rows, false, first.get_format())
	for index in _shots.size():
		sheet.blit_rect(_shots[index], Rect2i(Vector2i.ZERO, first.get_size()),
			Vector2i(first.get_width() * (index % columns), first.get_height() * (index / columns)))
	var path := "%s/torsos_jaula.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
