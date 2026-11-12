extends Node

## EL CUBO FÍSICO, PROBADO POR CÓDIGO: se asienta, una escala de golpes al centro y arriba (para medir dónde se cae), los
## cuatro tiros de su fila, el F2, manejarlo (cuánto cabecea al arrancar y frenar) y contra la pared, y la recuperación.
## Con ventana, capturas.
##   headless:     godot --headless --path . res://tests/physical_check.tscn
##   con capturas: tools/godot_ventana.sh res://tests/physical_check.tscn -- --salida=C:/carpeta

var _folder := ""
var _parcel: SandboxParcel = null
var _cube: PhysicalCube = null
var _eye: Camera3D = null
var _title: Label = null


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
		if parcel.archetype is PhysicalCubeArchetype:
			_parcel = parcel
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await _fresh()
	print("ASENTARSE: altura %.2f · inclinación %.1f° · estado %d" % [_cube.height, _cube.tilt, _cube.state])
	_follow()
	await _shot("Parado", "1_parado")
	# LA ESCALA: cambios de velocidad en el centro y arriba.
	for at: float in [0.0, HoverCube.SIZE * 0.5]:
		for change: float in [0.5, 1.0, 1.5, 2.0, 3.0, 4.0]:
			await _fresh()
			var start := _cube.global_position
			_cube.apply_impulse(_cube.global_basis.x * HoverCube.CUBE_MASS * change, Vector3(0, at, 0))
			var seen := await _watch(4.0)
			print("EMPUJÓN %.1f m/s %s: inclinación pico %.0f° · se cayó %s · se corrió %.1f m" % [change,
				"arriba" if at > 0.0 else "en el centro", seen.x, _cube.falls > 0, seen.y if _cube.falls == 0
				else (_cube.global_position - start).length()])
	# LOS CUATRO TIROS.
	var ball_shots := _parcel.archetype.ball_shots()
	for chosen: Dictionary in ball_shots:
		await _fresh()
		var start := _cube.global_position
		var at := _cube.global_position
		_eye.global_position = at + Vector3(-28.0, 2.0, 0.0)
		_eye.look_at(at + Vector3(0.0, 2.0, 0.0))
		await _frames(2)
		TestBall.throw_from_camera(_parcel, float(chosen["push"]), float(chosen["speed"]))
		var seen := await _watch(4.0)
		print("TIRO %s [%s] (%.1f m/s de golpe): inclinación pico %.0f° · se cayó %s · se corrió %.1f m" % [
			chosen["name"], _cube.last_hit_kind, _cube.last_hit, seen.x, _cube.falls > 0,
			(_cube.global_position - start).length()])
	# EL F2.
	for strong: bool in [false, true]:
		await _fresh()
		_cube.knock(strong)
		var seen := await _watch(3.0)
		print("F2 %s: inclinación pico %.0f° · se cayó %s" % ["fuerte" if strong else "suave", seen.x, _cube.falls > 0])
		if strong:
			_follow()
			await _shot("F2 fuerte", "2_f2")
	# MANEJARLO: arranca 2.5 s, suelta; cuánto cabecea.
	await _fresh()
	_cube.driving = true
	_press(KEY_W, true)
	var going := await _watch(2.5)
	_follow()
	await _shot("Arrancando (W)", "3_arranca")
	_press(KEY_W, false)
	var stopping := await _watch(2.5)
	print("MANEJAR: cabecea %.0f° al arrancar y %.0f° al frenar · se cayó %s" % [going.x, stopping.x, _cube.falls > 0])
	# CONTRA LA PARED: W 9 s.
	await _fresh()
	_cube.driving = true
	_press(KEY_W, true)
	var crash := await _watch(9.0)
	_press(KEY_W, false)
	_cube.driving = false
	_follow()
	await _shot("Contra la pared", "4_pared")
	print("PARED: inclinación pico %.0f° · se cayó %s · último golpe %.1f m/s [%s]" % [crash.x, _cube.falls > 0,
		_cube.last_hit, _cube.last_hit_kind])
	# RECUPERARSE.
	await _fresh()
	_cube.knock(true)
	_cube.apply_impulse(_cube.global_basis.x * HoverCube.CUBE_MASS * 6.0, _cube.global_basis * Vector3(0, 4.0, 0))
	var clock := 0.0
	while clock < 20.0 and not (_cube.falls > 0 and _cube.state == HoverCube.State.HOVER):
		await get_tree().physics_frame
		clock += 1.0 / 240.0
	print("RECUPERARSE: se cayó %s · de vuelta parado %s a los %.1f s · inclinación %.0f°" % [_cube.falls > 0,
		_cube.state == HoverCube.State.HOVER, clock, _cube.tilt])
	await _seconds(2.0)
	print("DESPUÉS: inclinación %.1f° · altura %.2f · estado %d" % [_cube.tilt, _cube.height, _cube.state])
	get_tree().quit()


## El cubo recién armado y quieto.
func _fresh() -> void:
	_parcel.regenerate(_parcel.seed_value)
	await _frames(2)
	_cube = _parcel.find_children("*", "PhysicalCube", true, false)[0] as PhysicalCube
	await _seconds(2.0)


## Mira `seconds`: la inclinación más grande y lo más que se corrió (x, y).
func _watch(seconds: float) -> Vector2:
	var start := _cube.global_position
	var most := 0.0
	var farthest := 0.0
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / 240.0
		most = maxf(most, _cube.tilt)
		var moved := _cube.global_position - start
		farthest = maxf(farthest, Vector2(moved.x, moved.z).length())
	return Vector2(most, farthest)


func _follow() -> void:
	var at := _cube.global_position
	_eye.global_position = at + Vector3(-6.0, 4.0, 30.0)
	_eye.look_at(at + Vector3(0, -3.0, 0))


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
