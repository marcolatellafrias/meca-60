extends Node

## POSEER, PROBADO POR CÓDIGO (unos 15 segundos; ver SandboxPossession): el jugador mira el cubo péndulo, la O lo posee,
## la T pasa por las tres vistas, la O lo suelta, y la O sin mirarlo lo retoma. Con ventana, capturas del cartel.
##   tools/godot_ventana.sh res://tests/possess_check.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate() as DesignSandbox
	add_child(sandbox)
	await _frames(10)
	var possession := SandboxPossession.of(get_tree())
	var cube := sandbox.find_children("*", "PendulumCube", true, false)[0] as PendulumCube
	var player := sandbox.local_player
	# El jugador, a la altura del cubo, mirándolo.
	player.place_at(cube.global_position + Vector3(0.0, -1.0, 34.0), 0.0)
	await _seconds(0.6)
	print("MIRÁNDOLO: apunta a %s" % [possession._aimed.call("possess_name") if possession._aimed != null else "nada"])
	await _shot("1_pista")
	await _key(KEY_O)
	print("O: posee %s · vista %s · jugador apagado %s · cámara %s" % [_name(possession), SandboxPossession.VIEW_NAMES[possession.view],
		player.process_mode == Node.PROCESS_MODE_DISABLED, get_viewport().get_camera_3d().name])
	await _seconds(0.5)
	await _shot("2_tercera")
	await _key(KEY_T)
	await _seconds(0.3)
	print("T: vista %s · cámara %s" % [SandboxPossession.VIEW_NAMES[possession.view], get_viewport().get_camera_3d().name])
	await _shot("3_primera")
	await _key(KEY_T)
	await _seconds(0.3)
	print("T: vista %s · cámara del jugador %s" % [SandboxPossession.VIEW_NAMES[possession.view],
		get_viewport().get_camera_3d() == player.player_camera])
	await _shot("4_libre")
	# Poseído, las teclas son suyas: W lo mueve.
	var start := cube.global_position
	await _hold(KEY_W, 1.5)
	print("W poseído: el cubo se movió %.1f m · el jugador %.1f m" % [(cube.global_position - start).length(), 0.0])
	await _key(KEY_O)
	print("O: suelta · posee %s · jugador prendido %s · cámara del jugador %s" % [_name(possession),
		player.process_mode != Node.PROCESS_MODE_DISABLED, get_viewport().get_camera_3d() == player.player_camera])
	# Mirando para otro lado, la O lo retoma.
	player.place_at(cube.global_position + Vector3(20.0, -1.0, 34.0), PI)
	await _seconds(0.5)
	print("MIRANDO PARA OTRO LADO: apunta a %s" % ["algo" if possession._aimed != null else "nada"])
	await _shot("5_retomar")
	await _key(KEY_O)
	print("O sin mirarlo: posee %s" % _name(possession))
	await _key(KEY_O)
	print("SCRIPT sin errores hasta el final · posee %s" % _name(possession))
	get_tree().quit()


func _name(possession: SandboxPossession) -> String:
	return str(possession.target.call("possess_name")) if possession.target != null else "nada"


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)


func _hold(code: Key, seconds: float) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await _seconds(seconds)
	event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = false
	Input.parse_input_event(event)
	await _frames(2)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	await _frames(2)
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
