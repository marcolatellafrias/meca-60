extends Node

## LAS PUNTAS DE LOS BRAZOS, PARA MIRARLAS (unos 10 segundos, sin el sandbox): una meca jaula por punta (ArmLoadout.Tip),
## en fila, con el brazo izquierdo discreto y el derecho con músculos, los dos con la placa. Lo que gira, girando. Una
## hoja numerada, una foto de frente por meca.
##   tools/godot_ventana.sh res://tests/arm_tips_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const GAP := 7.0

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
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
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	var mechs: Array[CageMech] = []
	for tip in ArmLoadout.TIP_NAMES.size():
		var mech := CageMech.new()
		mech.scripted = true
		mech.loadout = [ArmLoadout.of(ArmLoadout.Motion.POSE, tip, true),
			ArmLoadout.of(ArmLoadout.Motion.MUSCLE, tip, true)]
		mech.position = Vector3(tip * GAP, Mech.standing_height(Mech.Cabin.CAGE), 0.0)
		add_child(mech)
		mechs.append(mech)
	await get_tree().create_timer(2.5).timeout
	for mech in mechs:
		for arm in mech.arms:
			var spinning := arm.tip as SpinTip
			if spinning != null:
				spinning.charging = true
	await get_tree().create_timer(0.8).timeout
	for index in mechs.size():
		var at := mechs[index].global_position
		print("%d. %s: brazos %s" % [index + 1, ArmLoadout.TIP_NAMES[index], mechs[index].arms.size()])
		await _shot("%d. %s (izq. discreto, der. con músculos)" % [index + 1, ArmLoadout.TIP_NAMES[index]],
			at + Vector3(2.0, 0.6, -9.5), at + Vector3(0.0, -0.7, 0.0), 50.0)
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
	var path := "%s/puntas_de_brazos.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
