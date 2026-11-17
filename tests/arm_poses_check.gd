extends Node

## EL PANEL DE POSES, PARA PROBARLO (unos 8 segundos, sin el sandbox): la parcela de la meca jaula y el panel
## (ArmPosesPanel) abierto; elige la guardia baja para el palo, la L alta para el cañón y el mazazo, lo aplica como el
## panel y tira el golpe. Tres fotos: el panel con la meca, desde adentro, y el mazazo.
##   tools/godot_ventana.sh res://tests/arm_poses_check.tscn -- --salida=C:/carpeta

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
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var holder := Node3D.new()
	add_child(holder)
	CageMechArchetype.new().build(0, holder)
	var mech: CageMech = null
	for found in holder.find_children("*", "CageMech", true, false):
		mech = found
	mech.scripted = true
	var panel := ArmPosesPanel.new()
	add_child(panel)
	panel.side = TunerPanel.SIDE_LEFT
	panel.setup_panel()
	await get_tree().create_timer(1.5).timeout
	ArmPoseTrial.current.fist_rest = 2
	ArmPoseTrial.current.cannon_rest = 11
	ArmPoseTrial.current.strike = 1
	panel.rebuild()
	ArmPoseIdeas.apply_all(get_tree())
	print("PALO descansa en ", mech.melee.rest_point, " · CAÑÓN palanca ", mech.cannon.lever, " estira ",
		mech.cannon.stretch, " codo ", mech.cannon.arm.elbow_hint, " · GOLPE ", mech.melee.main_punch)
	await get_tree().create_timer(2.5).timeout
	var at := mech.global_position
	var forward := -mech.global_basis.z
	var right := mech.global_basis.x
	panel.visible = true
	await _shot(at + forward * 7.0 - right * 3.0 + Vector3.UP * 1.0, at + Vector3.DOWN * 0.4 - right * 1.2, 50.0)
	panel.visible = false
	(mech.cabin as CageCabin).evict(CageCabin.DRIVER)
	await get_tree().create_timer(0.3).timeout
	var eye: Vector3 = mech.global_transform * (mech.cabin.top_seat() + Vector3(0.0, SeatInteractable.STATION_EYE_HEIGHT, 0.0))
	await _shot(eye, eye + forward * 10.0 + Vector3.DOWN, 75.0)
	mech.melee.main_strike()
	await get_tree().create_timer(0.75 / mech.melee._punch_speed()).timeout
	await _shot(at + forward * 6.0 + right * 7.0 + Vector3.UP * 1.5, at + right * 1.0, 50.0)
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
	var sheet := Image.create(first.get_width() * _shots.size(), first.get_height(), false, first.get_format())
	for index in _shots.size():
		sheet.blit_rect(_shots[index], Rect2i(Vector2i.ZERO, first.get_size()), Vector2i(first.get_width() * index, 0))
	var path := "%s/panel_poses.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
