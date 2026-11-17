extends Node

## EL BRAZO PLEGABLE, PARA VERLO ANDAR (FoldingArm, CageBoards): la meca jaula, los dos plegados; el de la derecha en su
## modo (traído) y adónde mandaría la mirada; cuánto queda cada mando del pecho del que maneja (el alcance es 1 m).
##   tools/godot_ventana.sh res://tests/folding_arm_check.tscn -- --salida=C:/carpeta

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
	CageMechArchetype.new().build(0, holder)
	var mech: CageMech = null
	for found in holder.find_children("*", "CageMech", true, false):
		if found.arms_kind != Mech.Arms.NONE or mech == null:
			mech = found
	mech.scripted = true
	var form := CageCabin.shape()
	await get_tree().create_timer(1.0).timeout
	var cabin := mech.cabin as CageCabin
	for seat in CageCabin.SEAT_NAMES.size():
		cabin.evict(seat)
	var root := cabin.board_root()
	var arms := mech.find_children("*", "FoldingArm", true, false)
	var eye := root.global_transform * CageCabin.driver_eye(form)
	var chest := eye + root.global_basis.y * -0.35
	print("BRAZOS ", arms.size())
	for arm: FoldingArm in arms:
		print("  mando plegado a ", snappedf(arm.get_parent().global_position.distance_to(chest), 0.01), " m del pecho")
	var right: FoldingArm = null
	for arm: FoldingArm in arms:
		if (root.global_transform.affine_inverse() * arm.get_parent().global_position).x > 0.0:
			right = arm
	var forward := -root.global_basis.z
	var side := root.global_basis.x
	await _shot(eye, eye + side * 0.75 + forward * 0.42 - root.global_basis.y * 0.32, 95.0)
	await _shot(eye, eye - side * 0.75 + forward * 0.42 - root.global_basis.y * 0.32, 95.0)
	right.enter_mode()
	await get_tree().create_timer(0.6).timeout
	print("TRAÍDO: mando a ", snappedf(right.get_parent().global_position.distance_to(chest), 0.01), " m del pecho · la mirada va ",
		snapped(root.global_transform.affine_inverse() * right.mode_look(), Vector3.ONE * 0.01))
	await _shot(eye, eye + side * 0.75 + forward * 0.42 - root.global_basis.y * 0.32, 95.0)
	await _shot(eye, right.mode_look(), 85.0)
	right.exit_mode()
	await get_tree().create_timer(0.15).timeout
	await _shot(eye, eye + side * 0.75 + forward * 0.42 - root.global_basis.y * 0.32, 95.0)
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
	var path := "%s/brazo_plegable.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
