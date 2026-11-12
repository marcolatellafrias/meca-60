extends Node

## EL CUBO CON PIERNAS, PROBADO POR CÓDIGO: arma el sandbox, lo maneja (W adelante, A gira las piernas con el torso
## quieto, W y S), lo vuelca y sigue la recuperación; cuenta los pasos y mira que los pies no queden lejos de las
## caderas. Con ventana, capturas.
##   headless:     godot --headless --path . res://tests/legged_check.tscn
##   con capturas: tools/godot_ventana.sh res://tests/legged_check.tscn -- --salida=C:/carpeta

var _folder := ""
var _cube: LeggedCube = null
var _eye: Camera3D = null
var _title: Label = null
var _worst_foot := 0.0


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate()
	add_child(sandbox)
	await _frames(5)
	for parcel: SandboxParcel in sandbox.find_children("*", "SandboxParcel", true, false):
		if parcel.archetype is LeggedCubeArchetype:
			_cube = parcel.find_children("*", "LeggedCube", true, false)[0] as LeggedCube
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await _seconds(2.0)
	print("PARADO: altura %.2f · estado %d · pies a %.1f m de su lugar" % [_cube.height, _cube.state, _foot_error()])
	_follow()
	await _shot("Parado", "1_parado")
	_cube.driving = true
	# CAMINAR: W 3 s.
	await _drive([KEY_W], 3.0, "2_camina", "Caminando (W)")
	# GIRAR LAS PIERNAS CON EL TORSO QUIETO: A 2 s.
	var aim := _cube.torso_yaw
	await _drive([KEY_A], 2.0, "3_gira", "Girando las piernas (A), el torso quieto")
	print("GIRAR: el torso se movió %.1f° · las piernas giraron %.0f° respecto del torso" % [
		rad_to_deg(absf(wrapf(_cube.torso_yaw - aim, -PI, PI))), rad_to_deg(_cube.twist)])
	# CAMINAR CON EL TORSO GIRADO, y para atrás.
	await _drive([KEY_W], 2.0, "4_camina_girado", "Caminando con el torso girado")
	await _drive([KEY_S], 2.0, "5_atras", "Para atrás (S)")
	_cube.driving = false
	await _seconds(1.5)
	# UN GOLPE QUE NO LO VOLTEA: los pies lo siguen.
	var before := _cube.steps_taken
	_cube.linear_velocity += _cube.global_basis.x * 1.5
	await _watch(2.0, "6_golpe", "Un golpe de costado (no lo voltea)")
	print("GOLPE SUAVE: pasos %d · estado %d" % [_cube.steps_taken - before, _cube.state])
	# VOLCARLO Y QUE SE RECUPERE.
	var falls := _cube.falls
	_cube.knock(true)
	var clock := 0.0
	var shots := 0
	while clock < 20.0 and not (_cube.falls > falls and _cube.state == HoverCube.State.HOVER):
		await get_tree().physics_frame
		clock += 1.0 / 240.0
		if fmod(clock, 0.35) < 1.0 / 240.0 and shots < 12:
			_follow()
			await _shot("Volcado: %s (%.1f s)" % [["flota", "tirado", "sube", "se endereza"][_cube.state], clock],
				"7_%02d" % shots)
			shots += 1
	var _tuck_at_stand := _cube._tuck
	await _seconds(1.0)
	print("VOLCAR: se cayó %s · de vuelta parado %s a los %.1f s (piernas recogidas %.0f %% al quedar derecho) · pies a %.1f m de su lugar" % [_cube.falls > falls,
		_cube.state == HoverCube.State.HOVER, clock, _tuck_at_stand * 100.0, _foot_error()])
	print("PASOS en total %d · lo más lejos que quedó un pie de su lugar parado: %.1f m" % [_cube.steps_taken, _worst_foot])
	get_tree().quit()


## Maneja con `keys` apretadas `seconds`, mirando los pies; una captura a la mitad.
func _drive(keys: Array, seconds: float, file_name: String, title: String) -> void:
	var before := _cube.steps_taken
	for code: Key in keys:
		_press(code, true)
	await _watch(seconds, file_name, title)
	for code: Key in keys:
		_press(code, false)
	print("%s: %d pasos · velocidad %.1f m/s · estado %d" % [title, _cube.steps_taken - before,
		Vector3(_cube.linear_velocity.x, 0, _cube.linear_velocity.z).length(), _cube.state])
	await _seconds(0.8)


func _watch(seconds: float, file_name: String, title: String) -> void:
	var clock := 0.0
	var shot_taken := false
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / 240.0
		if _cube.state == HoverCube.State.HOVER:
			_worst_foot = maxf(_worst_foot, _foot_error())
		if not shot_taken and clock >= seconds * 0.5:
			shot_taken = true
			_follow()
			await _shot(title, file_name)


## Qué tan lejos está el pie más alejado de su lugar debajo de la cadera (en el piso).
func _foot_error() -> float:
	var root := _cube._root()
	var worst := 0.0
	for i in 2:
		var rest := MechBody.foot_rest(root, -1.0 if i == 0 else 1.0)
		var foot := _cube._foot_ground(i)
		worst = maxf(worst, Vector2(rest.x - foot.x, rest.z - foot.z).length())
	return worst


func _follow() -> void:
	var at := _cube.global_position
	_eye.global_position = at + Vector3(-22.0, 2.0, 20.0)
	_eye.look_at(at + Vector3(0, -4.0, 0))


func _press(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await _frames(2)
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
