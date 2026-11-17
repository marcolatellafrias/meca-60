extends Node

## LA MECA JAULA, PARA MIRARLA Y VERLA ANDAR (unos 15 segundos, sin el sandbox): la parcela (CageMechArchetype) en un
## piso fijo. Con ventana, una hoja: de afuera (de frente a la izquierda, de frente, de atrás), desde los ojos del que
## maneja, caminando, pegando con el palo y tirando con el cañón. Imprime la caja, los hombros, las sillas y lo que mide.
##   tools/godot_ventana.sh res://tests/cage_mech_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)

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
	var holder := Node3D.new()
	add_child(holder)
	CageMechArchetype.new().build(0, holder)
	var mech: CageMech = null
	for found in holder.find_children("*", "CageMech", true, false):
		mech = found
	mech.scripted = true
	await get_tree().create_timer(3.0).timeout
	print("CAJA ", CageCabin.box(), " · HOMBRO ", Mech.shoulder(Mech.Cabin.CAGE), " · PARADA A ", mech.global_position,
		" · CINTURA ", mech.measures.WAIST)
	for chair in mech.cabin.chairs:
		print("SILLA ", chair.name, " en ", chair.global_position)
	var at := mech.global_position
	var forward := -mech.global_basis.z
	var right := mech.global_basis.x
	await _shot("la meca jaula", at + forward * 8.0 - right * 6.0 + Vector3.UP * 2.5, at + Vector3.UP * 0.3, 50.0)
	await _shot("de frente", at + forward * 9.0 + Vector3.UP * 0.8, at + Vector3.UP * 0.3, 45.0)
	# CORTADA AL MEDIO, DE COSTADO: el que maneja en su silla curva (la cámara no ve lo que está más cerca que el medio).
	_eye.near = 12.0 - 0.3
	var pod: Vector3 = mech.global_transform * (mech.cabin.top_seat() + Vector3(0.0, SeatInteractable.STATION_EYE_HEIGHT, 0.0))
	await _shot("cortada al medio: el que maneja", pod + right * 12.0, pod, 11.0)
	_eye.near = 0.05
	await _shot("de atrás", at - forward * 8.0 + right * 5.0 + Vector3.UP * 3.0, at + Vector3.UP * 0.6, 50.0)
	# El que maneja desaloja a su maniquí (como al poseerla), y vuelve al soltarla.
	var cage := mech.cabin as CageCabin
	print("MANIQUÍES ", cage.dummies.size())
	cage.evict(CageCabin.DRIVER)
	await get_tree().create_timer(0.3).timeout
	print("MANIQUÍES AL TOMAR EL PUESTO ", cage.dummies.size())
	var eye: Vector3 = mech.global_transform * (mech.cabin.top_seat() + Vector3(0.0, SeatInteractable.STATION_EYE_HEIGHT, 0.0))
	await _shot("desde los ojos del que maneja", eye, eye + forward * 10.0 + Vector3.DOWN * 1.0, 80.0)
	await _shot("desde los ojos, a la izquierda: los controles", eye, eye - right * 10.0 + forward * 3.0 + Vector3.DOWN * 3.0, 90.0)
	cage.seat_back(CageCabin.DRIVER)
	print("MANIQUÍES AL DEJARLO ", cage.dummies.size())
	# CAMINA hacia adelante dos segundos.
	var start := mech.global_position
	mech.move = Vector2(0.0, 1.0)
	await get_tree().create_timer(1.2).timeout
	var now := mech.global_position
	await _shot("caminando", now + right * 9.0 + Vector3.UP * 1.5, now + Vector3.DOWN * 0.5, 50.0)
	await get_tree().create_timer(0.8).timeout
	mech.move = Vector2.ZERO
	print("CAMINÓ ", start.distance_to(mech.global_position), " m en 2 s")
	await get_tree().create_timer(1.0).timeout
	# EL PALO: un directo.
	now = mech.global_position
	mech.melee.punch(MechArm.Punch.STRAIGHT)
	await get_tree().create_timer(0.62).timeout
	await _shot("el palo: un directo", now + forward * 6.0 + right * 5.0 + Vector3.UP * 2.0, now + forward * 1.0, 50.0)
	print("PALO: la mano llegó a ", (mech.melee as MuscleArm).top_speed, " m/s")
	await get_tree().create_timer(1.0).timeout
	# EL CAÑÓN: un tiro simple.
	mech.cannon.mode = CannonTip.Mode.SIMPLE
	mech.cannon.trigger = true
	await get_tree().create_timer(0.15).timeout
	mech.cannon.trigger = false
	await get_tree().create_timer(0.1).timeout
	await _shot("el cañón: un tiro", now + forward * 5.0 - right * 6.0 + Vector3.UP * 2.0, now + forward * 3.0, 55.0)
	print("ENERGÍA ", mech.energy.bar())
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
	var path := "%s/meca_jaula.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
