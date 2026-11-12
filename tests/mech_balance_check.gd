extends Node

## EL CUBO PÉNDULO, PROBADO POR CÓDIGO: se asienta; una escala de golpes al centro y arriba (dónde se cae); contra la
## pared a varias velocidades (no tiene que caer); cuánto se inclina al arrancar y al frenar; el giro; un golpe
## descentrado (cuánto lo gira y si vuelve); sus cuatro tiros; el F2 y la recuperación. Con ventana, capturas.
##   headless:     godot --headless --path . res://tests/pendulum_check.tscn
##   con capturas: tools/godot_ventana.sh res://tests/pendulum_check.tscn -- --salida=C:/carpeta

var _folder := ""
var _parcel: SandboxParcel = null
var _cube: Mech = null
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
		if parcel.archetype is MechArchetype:
			_parcel = parcel
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var knobs := MechSettings.current
	await _fresh()
	print("ASENTARSE: altura %.2f · inclinación %.1f° · estado %d" % [_cube.height, _cube.tilt, _cube.state])
	_view()
	await _shot("Parado", "1_parado")
	# LA ESCALA: golpes en el centro y arriba.
	for at: float in [0.0, Mech.SIZE * 0.5]:
		for change: float in [3.0, 5.0, 8.0, 11.0, 14.0, 18.0]:
			await _fresh()
			_cube.apply_impulse(_cube.global_basis.x * Mech.MASS * change, Vector3(0, at, 0))
			var seen := await _watch(5.0)
			print("GOLPE %.0f m/s %s: inclinación pico %.0f° · se cayó %s · se corrió %.1f m · pasos %d" % [change,
				"arriba" if at > 0.0 else "en el centro", seen.x, _cube.falls > 0, seen.y, _cube.legs.steps_taken])
			if at > 0.0 and change == 8.0:
				_view()
	# CONTRA LA PARED, a varias velocidades: no tiene que caer.
	var usual := knobs.walk_speed
	for speed: float in [8.0, 14.0, 20.0]:
		knobs.walk_speed = speed
		await _fresh()
		_cube.keys.driving = true
		_press(KEY_W, true)
		var crash := await _watch(7.0)
		var reached := crash.z
		_view()
		await _shot("Contra la pared a %.0f m/s" % speed, "2_pared_%d" % roundi(speed))
		_press(KEY_W, false)
		_cube.keys.driving = false
		print("PARED a %.0f m/s (llegó a %.1f): inclinación pico %.0f° · se cayó %s · último golpe %.1f m/s [%s]" % [speed,
			reached, crash.x, _cube.falls > 0, _cube.last_hit, _cube.last_hit_kind])
	knobs.walk_speed = usual
	# ARRANCAR Y FRENAR.
	await _fresh()
	_cube.keys.driving = true
	_press(KEY_W, true)
	var going := await _watch(0.7)
	_view()
	await _shot("Arrancando (W)", "3_arranca")
	going = going.max(await _watch(1.8))
	await _watch(0.8)
	var cruise := _cube.tilt
	_press(KEY_W, false)
	var start := _cube.global_position
	var stopping := await _watch(4.0)
	_cube.keys.driving = false
	print("MANEJAR: se inclina %.0f° al arrancar · %.1f° a velocidad (%.1f m/s) · %.0f° al frenar, en %.1f m · se cayó %s · pasos %d" % [
		going.x, cruise, going.z, stopping.x, (_cube.global_position - start).length(), _cube.falls > 0, _cube.legs.steps_taken])
	# EL GIRO: pedirle 90°.
	await _fresh()
	var from := _cube.yaw()
	_cube.aim_yaw = from + PI * 0.5
	var clock := 0.0
	while clock < 6.0 and absf(wrapf(_cube.aim_yaw - _cube.yaw(), -PI, PI)) > deg_to_rad(3.0):
		await get_tree().physics_frame
		clock += 1.0 / 240.0
	_view()
	await _shot("Girando: las piernas alcanzan al torso", "4_giro")
	print("GIRO de 90°: %.1f s · pasos %d" % [clock, _cube.legs.steps_taken])
	# UN GOLPE DESCENTRADO: cuánto lo gira, y si vuelve.
	await _fresh()
	from = _cube.yaw()
	_cube.apply_impulse(_cube.global_basis.x * Mech.MASS * 6.0, _cube.global_basis * Vector3(0, 0, -Mech.SIZE * 0.5))
	var most_turn := 0.0
	clock = 0.0
	while clock < 4.0:
		await get_tree().physics_frame
		clock += 1.0 / 240.0
		most_turn = maxf(most_turn, absf(wrapf(_cube.yaw() - from, -PI, PI)))
	print("GOLPE DESCENTRADO 6 m/s: lo giró %.0f° · quedó a %.1f° de donde miraba · se cayó %s" % [rad_to_deg(most_turn),
		rad_to_deg(absf(wrapf(_cube.yaw() - from, -PI, PI))), _cube.falls > 0])
	# LOS CUATRO TIROS.
	for chosen: Dictionary in _parcel.archetype.ball_shots():
		await _fresh()
		var at := _cube.global_position
		_eye.global_position = at + Vector3(-28.0, 2.0, 0.0)
		_eye.look_at(at + Vector3(0.0, 2.0, 0.0))
		await _frames(2)
		TestBall.throw_from_camera(_parcel, float(chosen["push"]), float(chosen["speed"]))
		var seen := await _watch(5.0)
		print("TIRO %s [%s]: inclinación pico %.0f° · se cayó %s · se corrió %.1f m" % [chosen["name"],
			_cube.last_hit_kind, seen.x, _cube.falls > 0, seen.y])
	# EL F2 Y LA RECUPERACIÓN.
	for strong: bool in [false, true]:
		await _fresh()
		_cube.knock(strong)
		clock = 0.0
		var most := 0.0
		var shots := 0
		while clock < 20.0 and (clock < 4.0 or _cube.state != Mech.State.STANDING):
			await get_tree().physics_frame
			clock += 1.0 / 240.0
			most = maxf(most, _cube.tilt)
			if strong and fmod(clock, 0.5) < 1.0 / 240.0 and shots < 9:
				_view()
				await _shot("F2 fuerte: %s (%.1f s)" % [["parado", "tirado", "sube", "se endereza"][_cube.state], clock],
					"5_%02d" % shots)
				shots += 1
		print("F2 %s: inclinación pico %.0f° · se cayó %s · parado otra vez %s a los %.1f s" % ["fuerte" if strong else "suave",
			most, _cube.falls > 0, _cube.state == Mech.State.STANDING, clock])
	await _seconds(1.0)
	print("DESPUÉS: inclinación %.1f° · altura %.2f · estado %d" % [_cube.tilt, _cube.height, _cube.state])
	get_tree().quit()


## El cubo recién armado y quieto.
func _fresh() -> void:
	_parcel.regenerate(_parcel.seed_value)
	await _frames(2)
	_cube = _parcel.find_children("*", "Mech", true, false)[0] as Mech
	# Sola: sin la de práctica adelante, que es contra la pared de la parcela que se la prueba.
	for other: Mech in _parcel.find_children("*", "Mech", true, false):
		if other != _cube:
			other.free()
	await _seconds(2.0)


## Mira `seconds`: la inclinación más grande, lo más que se corrió y la velocidad más alta (x, y, z).
func _watch(seconds: float) -> Vector3:
	var start := _cube.global_position
	var most := 0.0
	var farthest := 0.0
	var fastest := 0.0
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / 240.0
		most = maxf(most, _cube.tilt)
		var moved := _cube.global_position - start
		farthest = maxf(farthest, Vector2(moved.x, moved.z).length())
		fastest = maxf(fastest, Vector2(_cube.linear_velocity.x, _cube.linear_velocity.z).length())
	return Vector3(most, farthest, fastest)


func _view() -> void:
	var at := _cube.global_position
	_eye.global_position = at + Vector3(-8.0, -2.0, 30.0)
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
