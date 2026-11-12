extends Node

## LA ARENA DE ESQUIVAR, PARA MIRARLA (unos 25 segundos, sin el sandbox): la torre le tira andanadas a la meca, que
## primero se queda quieta y después corre en círculo. Imprime cada misil que cae: a cuánto de la meca, y si la agarró;
## y las caídas. Con ventana, capturas: desde arriba, las marcas en el piso, un misil cayendo y la explosión.
##   tools/godot_ventana.sh res://tests/dodge_arena_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null
var _landed := 0
var _caught := 0


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
	Clay.shape_box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
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
	var holder := Node3D.new()
	add_child(holder)
	var arena := DodgeArenaArchetype.new().build(0, holder)
	_mech = arena.find_children("*", "Mech", true, false)[0] as Mech
	var field := arena.get_node("Proyectiles") as ProjectileField
	field.exploded.connect(_on_exploded)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	_mech.keys.driving = true
	# QUIETA: le caen encima.
	await _seconds(MissileTurret.EVERY + 1.0)
	_eye.global_position = Vector3(-60.0, 150.0, 140.0)
	_eye.look_at(Vector3(0.0, 0.0, 30.0))
	await _shot("1 · Desde arriba: las marcas donde van a caer", "1_arriba")
	_chase()
	await _seconds(0.9)
	_chase()
	await _shot("2 · Los misiles cayendo sobre la meca", "2_cayendo")
	while _landed == 0:
		await get_tree().physics_frame
	await _seconds(0.12)
	_chase()
	await _shot("3 · La explosión", "3_explosion")
	await _seconds(1.5)
	print("QUIETA: cayeron %d · la agarraron %d · caídas %d" % [_landed, _caught, _mech.falls])
	# CORRIENDO EN CÍRCULO: W + Shift y girando de a poco.
	_landed = 0
	_caught = 0
	_press(KEY_W, true)
	_press(KEY_SHIFT, true)
	var clock := 0.0
	var shot := false
	while clock < 12.0:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		_mech.aim_yaw += deg_to_rad(12.0) / Engine.physics_ticks_per_second
		if not shot and clock > 6.0:
			shot = true
			_chase()
			await _shot("4 · Corriendo: los de adelante, donde va a estar", "4_corriendo")
	_press(KEY_W, false)
	_press(KEY_SHIFT, false)
	print("CORRIENDO: cayeron %d · la agarraron %d · caídas %d" % [_landed, _caught, _mech.falls])
	get_tree().quit()


func _on_exploded(at: Vector3, kind: Missile.Kind) -> void:
	_landed += 1
	var far := Vector2(at.x - _mech.global_position.x, at.z - _mech.global_position.z).length()
	var radius: float = Missile.KINDS[kind]["radius"]
	if far < radius + Mech.SIZE * 0.5:
		_caught += 1
	print("  cae a %.1f m de la meca%s · inclinación %.0f°" % [far, " · LA AGARRA" if far < radius + Mech.SIZE * 0.5
		else "", _mech.tilt])


func _chase() -> void:
	var at := _mech.global_position
	var inward := (-at).slide(Vector3.UP).normalized()
	_eye.global_position = at + inward * 45.0 + inward.cross(Vector3.UP) * 18.0 + Vector3.UP * 14.0
	_eye.look_at(at + Vector3(0.0, -2.0, 0.0))


func _press(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)


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
