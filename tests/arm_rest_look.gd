extends Node

## DÓNDE DESCANSAN LOS BRAZOS, PARA ELEGIR (16/11/2026; el usuario: «que se lean bien los brazos adentro de la cabina
## que los maneja… inspirarse un poco en los juegos de primera persona, que se les ve las manos… sin tapar demasiado la
## pantalla… una mano melee… diferente pose de reposo»): una meca jaula por idea, en fila, quietas; de cada una, lo que
## ve el que maneja (sin su maniquí) y la meca de frente. Una hoja numerada.
##   `--brazo=pinas` (de entrada): el derecho, el palo en el brazo con músculos; el cañón, como hoy.
##   `--brazo=canon`: el izquierdo, el cañón; el palo, como hoy.
##   `--brazo=canon_l`: el cañón EN L, con el brazo pegado al torso (el usuario: «cómo sería el cañón más en L, con
##   brazo más pegado al torso, pero… que se vea un poco desde adentro… varias interpretaciones»): dónde queda la boca y
##   hacia dónde dobla el codo; la segunda foto, de tres cuartos, para leer la L.
##   tools/godot_ventana.sh res://tests/arm_rest_look.tscn -- --salida=C:/carpeta --brazo=canon

const VIEW := Vector2i(1280, 720)
const GAP := 9.0

## Las ideas, las de ArmPoseIdeas (las mismas que elige el panel de poses, ArmPosesPanel).
const FISTS := ArmPoseIdeas.FISTS
const CANNONS := ArmPoseIdeas.CANNONS
const CANNON_L := ArmPoseIdeas.CANNON_L

var _folder := ""
var _cannon_sheet := false
var _l_sheet := false
var _eye: Camera3D = null
var _title: Label = null
var _shots: Array = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		elif argument == "--brazo=canon":
			_cannon_sheet = true
		elif argument == "--brazo=canon_l":
			_l_sheet = true
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
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	var ideas: Array = CANNON_L if _l_sheet else (CANNONS if _cannon_sheet else FISTS)
	var mechs: Array[CageMech] = []
	for index in ideas.size():
		var mech := CageMech.new()
		mech.scripted = true
		mech.position = Vector3(index * GAP, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
		add_child(mech)
		mechs.append(mech)
	await get_tree().create_timer(0.5).timeout
	for index in ideas.size():
		var idea: Array = ideas[index]
		var mech := mechs[index]
		(mech.cabin as CageCabin).evict(CageCabin.DRIVER)
		if _l_sheet:
			# La palanca va en el espacio del torso (x a la derecha): del lado izquierdo, afuera es −x.
			var point: Vector3 = idea[1]
			var across := mech.cannon.arm.side * point.x
			mech.cannon.lever = Vector2(rad_to_deg(atan2(across, -point.z)),
				rad_to_deg(atan2(point.y, Vector2(across, point.z).length())))
			mech.cannon.stretch = point.length()
			mech.cannon.arm.elbow_hint = idea[2]
		elif _cannon_sheet:
			mech.cannon.lever = idea[1]
			mech.cannon.stretch = idea[2]
		else:
			var arm := mech.melee
			arm._offset = (idea[1] as Vector3) * arm.reach() - arm.stance_at(MechArm.Stance.NORMAL)
	await get_tree().create_timer(2.5).timeout
	for index in ideas.size():
		var mech := mechs[index]
		var label := "%d. %s" % [index + 1, ideas[index][0]]
		var eye: Vector3 = mech.global_transform * (mech.cabin.top_seat() + Vector3(0.0, SeatInteractable.STATION_EYE_HEIGHT, 0.0))
		var forward := -mech.global_basis.z
		await _shot(label + " · desde adentro", eye, eye + forward * 10.0 + Vector3.DOWN * 1.0, 75.0)
		var at := mech.global_position
		if _l_sheet:
			var right := mech.global_basis.x
			await _shot(label + " · de tres cuartos", at + forward * 5.5 - right * 7.0 + Vector3.UP * 1.2,
				at + Vector3.DOWN * 0.5 - right * 0.8, 50.0)
		else:
			await _shot(label + " · de frente", at + forward * 8.0 + Vector3.UP * 1.0, at + Vector3.DOWN * 0.4, 50.0)
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
	var path := "%s/reposo_%s.png" % [_folder, "canon_l" if _l_sheet else ("canon" if _cannon_sheet else "pinas")]
	sheet.save_png(path)
	print("CAPTURA ", path)
