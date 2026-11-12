extends Node

## EL CUBO FLOTANTE, PROBADO POR CÓDIGO: arma el sandbox, mira cómo se asienta, le tira las tres bolas de frente (ver
## TestBall) y mide cuánto sube y baja, cuánto se inclina y si se cae; después lo voltea con un empujón grande y sigue la
## recuperación (tirado, sube, se endereza, flota) con capturas de las toberas.
##   headless:     godot --headless --path . res://tests/hover_check.tscn
##   con capturas: tools/godot_ventana.sh res://tests/hover_check.tscn -- --salida=C:/carpeta

var _folder := ""
var _balance := false
var _cube: HoverCube = null
var _parcel: SandboxParcel = null
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		# `--cubo=equilibrio`: el cubo con equilibrio (BalanceCube) en vez del flotante.
		if argument == "--cubo=equilibrio":
			_balance = true
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
		if (parcel.archetype is BalanceCubeArchetype) if _balance else (parcel.archetype is HoverCubeArchetype):
			_parcel = parcel
	_cube = _parcel.find_children("*", "HoverCube", true, false)[0] as HoverCube
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	# SE ASIENTA: de dónde nace a la altura de flotar.
	var heights := await _watch(3.0)
	print("ASENTARSE 3 s: altura %.2f a %.2f m (flota a %.1f) · al final %.2f · estado %d" % [heights.x, heights.y,
		HoverCubeSettings.current.hover_height, _cube.height, _cube.state])
	_side_view()
	await _shot("El cubo flotando", "1_flotando")
	# LOS CUATRO TIROS DEL CUBO, de frente (ver HoverCubeArchetype.ball_shots).
	var ball_shots := _parcel.archetype.ball_shots()
	for index in ball_shots.size():
		var chosen: Dictionary = ball_shots[index]
		# Cada tiro, con el cubo recién armado y quieto (si no, el anterior lo deja deslizándose y se le erra).
		_parcel.regenerate(_parcel.seed_value)
		await _frames(2)
		_cube = _parcel.find_children("*", "HoverCube", true, false)[0] as HoverCube
		await _seconds(2.0)
		_aim()
		await _frames(2)
		var falls := _cube.falls
		var start := _cube.global_position
		_track_start()
		TestBall.throw_from_camera(_parcel, float(chosen["push"]), float(chosen["speed"]))
		var watched := await _watch(4.0, true)
		print("TIRO %s (%s N·s a %d m/s): inclinación pico %.0f° · se cayó %s · %s" % [chosen["name"],
			String.num_int64(roundi(float(chosen["push"]))), roundi(float(chosen["speed"])), watched.z,
			_cube.falls > falls, _track_text(start, Vector3.RIGHT)])
	# LOS BOTONES DEL PANEL CHICO: volcarlo suave y fuerte; que se caiga, se recupere y no salga de su parcela.
	for strong: bool in [false, true]:
		await _wait_hover()
		await _seconds(1.5)
		var falls := _cube.falls
		var start := _cube.global_position
		var push_side := _cube.global_basis.x
		push_side.y = 0.0
		_track_start()
		_cube.knock(strong)
		var most := 0.0
		var farthest := 0.0
		var clock := 0.0
		while clock < 30.0 and not (_cube.falls > falls and _cube.state == HoverCube.State.HOVER):
			await get_tree().physics_frame
			clock += 1.0 / 240.0
			most = maxf(most, _cube.tilt)
			_track_step()
			var local := _parcel.to_local(_cube.global_position)
			farthest = maxf(farthest, maxf(absf(local.x), absf(local.z)))
		print("VOLCAR %s: inclinación pico %.0f° · se cayó %s · de vuelta flotando %s a los %.1f s · lo más lejos del centro %.1f m (borde a %.0f) · %s" % [
			"fuerte" if strong else "suave", most, _cube.falls > falls, _cube.state == HoverCube.State.HOVER, clock, farthest,
			_parcel.size.x * 0.5, _track_text(start, push_side.normalized())])
	# EL REBOTE: soltarlo de 4 m más arriba.
	await _wait_hover()
	await _seconds(1.0)
	_cube.global_position += Vector3.UP * 4.0
	_cube.linear_velocity = Vector3.ZERO
	var bounce := await _watch(4.0)
	print("SOLTADO 4 m más arriba: baja hasta %.2f m, sube hasta %.2f m (flota a %.1f)" % [bounce.x, bounce.y,
		HoverCubeSettings.current.hover_height])
	# VOLTEARLO: un empujón de costado arriba, y seguir la recuperación.
	await _wait_hover()
	await _seconds(1.0)
	_cube.apply_impulse(Vector3(0, 0, 1) * HoverCube.CUBE_MASS * 30.0, _cube.global_basis * Vector3(0, HoverCube.SIZE * 0.5, 0))
	var seen := {}
	var clock := 0.0
	var shots := 0
	while clock < 25.0:
		await get_tree().physics_frame
		clock += 1.0 / 240.0
		if not seen.has(_cube.state):
			seen[_cube.state] = clock
			print("  a los %.1f s: %s" % [clock, ["flota", "tirado", "sube", "se endereza"][_cube.state]])
			if _cube.state != HoverCube.State.HOVER or shots > 0:
				_side_view()
				await _shot("Volteado: %s (%.1f s)" % [["flota", "tirado", "sube", "se endereza"][_cube.state], clock],
					"2_%d_%s" % [shots, ["flota", "tirado", "sube", "endereza"][_cube.state]])
				shots += 1
		# Durante la recuperación, una cada medio segundo.
		if _cube.state in [HoverCube.State.LIFT, HoverCube.State.RIGHT] and fmod(clock, 0.5) < 1.0 / 240.0 and shots < 12:
			_side_view()
			await _shot("Recuperándose: %s (%.1f s)" % [["flota", "tirado", "sube", "se endereza"][_cube.state], clock],
				"3_%02d" % shots)
			shots += 1
		if seen.has(HoverCube.State.RIGHT) and _cube.state == HoverCube.State.HOVER:
			print("RECUPERADO a los %.1f s · inclinación %.0f° · altura %.2f m" % [clock, _cube.tilt, _cube.height])
			break
	if _cube.state != HoverCube.State.HOVER:
		print("NO se recuperó en 25 s (estado %d, inclinación %.0f°, altura %.1f)" % [_cube.state, _cube.tilt, _cube.height])
	await _seconds(2.0)
	print("DESPUÉS: altura %.2f · inclinación %.0f° · estado %d" % [_cube.height, _cube.tilt, _cube.state])
	get_tree().quit()


## ── PARA QUÉ LADO SE CAE: dónde quedó cuando tocó el piso caído, y cuánto giró sobre sí mismo hasta ahí ──
var _landed := Vector3.INF
var _turned := 0.0
var _last_basis := Basis()


func _track_start() -> void:
	_landed = Vector3.INF
	_turned = 0.0
	_last_basis = _cube.global_basis


func _track_step() -> void:
	_turned += rad_to_deg((_last_basis.inverse() * _cube.global_basis).get_rotation_quaternion().get_angle())
	_last_basis = _cube.global_basis
	var lying := _cube.state == HoverCube.State.LIMP and _cube.tilt > 60.0 and _cube.linear_velocity.y > -0.5
	if _landed == Vector3.INF and lying:
		_landed = _cube.global_position


func _track_text(start: Vector3, side: Vector3) -> String:
	if _landed == Vector3.INF:
		return "no llegó a caer"
	return "cayó %.1f m hacia el lado del golpe (%.1f m de costado) · giró %.0f° en total" % [
		(_landed - start).dot(side), (_landed - start).length(), _turned]


## Mira `seconds`: la altura más baja y más alta, y la inclinación más grande (x, y, z).
func _watch(seconds: float, _ignore := false) -> Vector3:
	var low := INF
	var high := -INF
	var most := 0.0
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / 240.0
		_track_step()
		low = minf(low, _cube.height)
		high = maxf(high, _cube.height)
		most = maxf(most, _cube.tilt)
	return Vector3(low, high, most)


func _wait_hover() -> void:
	for i in 6000:
		if _cube.state == HoverCube.State.HOVER:
			return
		await get_tree().physics_frame


func _aim() -> void:
	var at := _cube.global_position
	# A la parte de arriba: un golpe en el centro lo empuja sin hacerlo cabecear.
	_eye.global_position = at + Vector3(-28.0, HoverCube.HIT_ARM, 0.0)
	_eye.look_at(at + Vector3(0.0, HoverCube.HIT_ARM, 0.0))


func _side_view() -> void:
	var at := _cube.global_position
	_eye.global_position = at + Vector3(-26.0, 6.0, 18.0)
	_eye.look_at(at)


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
