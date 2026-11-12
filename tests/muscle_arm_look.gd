extends Node3D

## EL BRAZO CON MÚSCULOS, PARA MIRARLO Y MEDIRLO (unos 30 segundos, sin el sandbox): arma su parcela, lo deja asentarse en
## guardia, tira las cuatro piñas (a qué velocidad llega la mano, cuánto corre el bloque), le pone la pared (si se traba y
## si vuelve), y le tira un empujón (cuánto cede y si vuelve). Con ventana, capturas.
##   tools/godot_ventana.sh res://tests/muscle_arm_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _arm: MuscleArm = null
var _block: RigidBody3D = null
var _eye: Camera3D = null
var _title: Label = null
var _kind := MuscleArmArchetype.new()
var _stage: Node3D = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
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
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	await _fresh()
	_eye.global_position = Vector3(-26.0, 13.0, -2.0)
	_eye.look_at(Vector3(-4.0, 9.5, -7.0))
	await _seconds(2.0)
	print("EN GUARDIA: la mano a %.2f m de donde se la pide · a %.1f m/s" % [_arm.off_target, _arm.hand_speed])
	await _shot("En guardia", "1_guardia")
	# LAS CUATRO PIÑAS, cada una con el brazo y el bloque recién puestos.
	for kind: int in [MuscleArm.Punch.STRAIGHT, MuscleArm.Punch.HOOK, MuscleArm.Punch.UPPERCUT, MuscleArm.Punch.HAMMER]:
		await _fresh()
		await _seconds(1.5)
		var start := _block.global_position
		_arm.punch(kind as MuscleArm.Punch)
		var worst := 0.0
		var clock := 0.0
		var shot_at := float(MuscleArm.PUNCHES[kind][0][0]) + float(MuscleArm.PUNCHES[kind][1][0]) * 0.9
		var taken := false
		while clock < 4.5:
			await get_tree().physics_frame
			clock += 1.0 / 240.0
			worst = maxf(worst, _arm.off_target)
			if not taken and clock >= shot_at:
				taken = true
				await _shot("Piña: %s" % MuscleArm.NAMES[kind], "2_%d_%s" % [kind, MuscleArm.NAMES[kind].replace(" ", "_")])
		print("PIÑA %s: la mano llegó a %.0f m/s · lo más lejos de lo pedido %.1f m · el bloque se corrió %.1f m · vuelve a guardia a %.2f m" % [
			MuscleArm.NAMES[kind], _arm.top_speed, worst, start.distance_to(_block.global_position), _arm.off_target])
	# LA PARED: el directo contra algo fijo.
	await _fresh()
	for wall: StaticBody3D in _stage.find_children("Pared", "StaticBody3D", true, false):
		MuscleArmArchetype._show_wall(wall, true)
	await _seconds(1.5)
	_arm.punch(MuscleArm.Punch.STRAIGHT)
	await _seconds(float(MuscleArm.PUNCHES[MuscleArm.Punch.STRAIGHT][0][0]) + 0.4)
	print("CONTRA LA PARED, pegando: la mano a %.1f m de donde se la pide · %.1f m/s" % [_arm.off_target, _arm.hand_speed])
	await _shot("El directo contra la pared: trabado", "3_pared")
	await _seconds(2.5)
	await _shot("Después de la pared", "4_despues_pared")
	print("CONTRA LA PARED, después: vuelve a guardia a %.2f m · llegó a %.0f m/s" % [_arm.off_target, _arm.top_speed])
	# UN EMPUJÓN AL ANTEBRAZO: cede y vuelve.
	await _fresh()
	await _seconds(1.5)
	_arm.forearm.apply_central_impulse(Vector3(0, 0, 1) * MuscleArm.FOREARM_MASS * 18.0)
	var most := 0.0
	var clock := 0.0
	while clock < 3.0:
		await get_tree().physics_frame
		clock += 1.0 / 240.0
		most = maxf(most, _arm.off_target)
	print("EMPUJÓN de 18 m/s al antebrazo: cedió %.1f m · a los 3 s está a %.2f m de la guardia" % [most, _arm.off_target])
	get_tree().quit()


## La parcela recién armada.
func _fresh() -> void:
	if is_instance_valid(_stage):
		_stage.queue_free()
		await get_tree().process_frame
	_stage = _kind.build(0, self)
	_arm = _stage.find_children("*", "MuscleArm", true, false)[0] as MuscleArm
	_block = _stage.find_child("Bloque", true, false) as RigidBody3D


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
