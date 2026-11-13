extends Node

## EL SALTO Y EL DASH DE LA MECA, PARA MIRARLOS (unos 30 segundos, sin el sandbox): un toque, el salto cargado, un dash
## de costado en lo alto, un dash adelante corriendo y un dash atrás. Imprime cuánto sube, cuánto dura en el aire, cuánto
## se corre el dash y si al aterrizar se inclina o se cae. Con ventana, capturas.
##   tools/godot_ventana.sh res://tests/mech_jump_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null


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
	Clay.shape_box(ground, Vector3(2000, 1, 2000), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(2000, 1, 2000), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	for i in range(-40, 41):
		Clay.box(ground, Vector3(2000, 0.02, 0.25), Vector3(0, 0.0, i * 5.0), Color(0.7, 0.68, 0.64))
		Clay.box(ground, Vector3(0.25, 0.02, 2000), Vector3(i * 5.0, 0.0, 0), Color(0.7, 0.68, 0.64))
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
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.POSE
	_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_mech)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	_mech.keys.driving = true
	await _seconds(1.5)
	var standing := _mech.global_position.y
	# UN TOQUE Y EL SALTO CARGADO.
	for hold: float in [0.06, 0.6]:
		_press(KEY_SPACE, true)
		await _seconds(hold)
		var charged := _mech.moves.jump_charge
		_press(KEY_SPACE, false)
		await _flight("SALTO cargado %d %%" % roundi(charged * 100.0), standing, "", "",
			"1_salto" if hold > 0.5 else "")
		await _seconds(1.0)
	# DASH DE COSTADO EN LO ALTO (D + Shift).
	_press(KEY_SPACE, true)
	await _seconds(0.6)
	_press(KEY_SPACE, false)
	await _until_falling()
	await _flight("DASH DE COSTADO en lo alto", standing, "D", "2_dash_costado", "")
	await _seconds(1.5)
	# DASH ADELANTE CORRIENDO.
	_press(KEY_W, true)
	_press(KEY_SHIFT, true)
	await _seconds(4.0)
	_press(KEY_SHIFT, false)
	_press(KEY_SPACE, true)
	await _seconds(0.3)
	_press(KEY_SPACE, false)
	await _seconds(0.25)
	await _flight("DASH ADELANTE corriendo", standing, "W", "3_dash_adelante", "")
	_press(KEY_W, false)
	await _seconds(3.0)
	# DASH ATRÁS.
	_press(KEY_SPACE, true)
	await _seconds(0.3)
	_press(KEY_SPACE, false)
	await _seconds(0.25)
	await _flight("DASH ATRÁS", standing, "S", "", "")
	await _seconds(2.0)
	get_tree().quit()


## Sigue un vuelo hasta que aterriza y un segundo más. Si `dash` no está vacío, apenas empieza aprieta esa tecla con
## Shift (el dash). Imprime cuánto subió, cuánto duró en el aire, cuánto se corrió de costado y lo más que se inclinó
## después de aterrizar.
func _flight(title: String, standing: float, dash: String, dash_shot: String, apex_shot: String) -> void:
	var wait := 0.0
	while not _mech.airborne and wait < 2.0:
		await get_tree().physics_frame
		wait += 1.0 / Engine.physics_ticks_per_second
	var start := _mech.global_position
	var top := start.y
	var clock := 0.0
	var dashed_at := Vector3.INF
	if not dash.is_empty():
		var key: Key = {"W": KEY_W, "S": KEY_S, "D": KEY_D, "A": KEY_A}[dash]
		_press(key, true)
		await _seconds(0.05)
		dashed_at = _mech.global_position
		_press(KEY_SHIFT, true)
		await _seconds(0.1)
		_press(KEY_SHIFT, false)
		if dash != "W":
			await _seconds(0.1)
			_press(key, false)
		if not dash_shot.is_empty():
			_from(Vector3(-30.0, 2.0, 24.0))
			await _shot("%s: las toberas del otro lado" % title, dash_shot)
	var shot := apex_shot.is_empty()
	while _mech.airborne and clock < 8.0:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		top = maxf(top, _mech.global_position.y)
		if not shot and _mech.linear_velocity.y < 0.0:
			shot = true
			_from(Vector3(-34.0, 2.0, -14.0))
			await _shot("%s, en lo más alto" % title, apex_shot)
	var landed := _mech.global_position
	var most := 0.0
	var after := 0.0
	while after < 1.5:
		await get_tree().physics_frame
		after += 1.0 / Engine.physics_ticks_per_second
		most = maxf(most, _mech.tilt)
	var side := "" if dashed_at == Vector3.INF else " · el dash la corrió %.1f m hasta aterrizar" % \
		Vector2(landed.x - dashed_at.x, landed.z - dashed_at.z).length()
	print("%s: sube %.1f m · %.2f s en el aire%s · al aterrizar se inclina %.0f° · caídas %d · propulsor %d %%" % [
		title, top - standing, clock, side, most, _mech.falls, roundi(_mech.moves.fuel * 100.0)])


func _until_falling() -> void:
	var clock := 0.0
	while clock < 5.0 and not (_mech.airborne and _mech.linear_velocity.y < 0.0):
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second


func _from(offset: Vector3) -> void:
	_eye.global_position = _mech.global_position + offset
	_eye.look_at(_mech.global_position + Vector3(0.0, -3.0, 0.0))


func _press(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or file_name.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
