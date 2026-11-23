extends Node

## LA CÁMARA ISOMÉTRICA Y LAS TECLAS COMPARTIDAS (con ventana, unos 10 s): el jugador mira la meca, sube con la E, la mueve
## con W, gira su frente con la flecha y una segunda máquina aprieta la misma W: se tiene que frenar. Imprime cada paso y
## termina con ISO OK o ISO MAL.
##   tools/godot_ventana.sh res://tests/iso_crew_check.tscn -- --salida=C:/carpeta

const PLAYER := "res://game/character/player.tscn"

var local_player: BoneInstantiator = null
var _folder := ""
var _bad := 0


func _ready() -> void:
	# Esta prueba es de las teclas: no depende de lo que el usuario tenga guardado en el F6.
	MatchSettings.current.controls = MatchSettings.Controls.KEYS
	add_to_group("character_spawner")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 205.0, 0.0)
	add_child(sun)
	var mech := CageMech.new()
	mech.position = Vector3(0.0, Mech.standing_height(mech.cabin_shape), 0.0)
	add_child(mech)
	add_child(IsoView.new())
	local_player = (load(PLAYER) as PackedScene).instantiate() as BoneInstantiator
	local_player.kind = CharacterKind.player()
	add_child(local_player)
	local_player.place_at(Vector3(0.0, 0.0, 2.4), 0.0)
	_run(mech)


func _run(mech: CageMech) -> void:
	await _wait(1.0)
	_check("sin maniquíes", mech.cabin.dummies.is_empty())
	var controller := local_player.player_controller
	# El rumbo lo pone esta prueba: que no lo pise el mouse de verdad.
	controller._shown = false
	_check("la cámara activa es la isométrica", get_viewport().get_camera_3d() is IsoView)
	controller.camera_yaw = 0.0
	await _wait(0.3)
	var hovered := controller.interaction_controller.detector.get_hovered()
	_check("mirándola, la E la tiene a tiro", hovered is CageBoarding)
	await _shot("1_afuera")
	local_player.intent.activate = true
	await _wait(0.8)
	_check("sentado arriba", local_player.is_seated and mech.cabin.chairs.has(local_player.current_seat))
	var crew := mech.get_node("Tripulacion") as MechCrew
	var from := mech.global_position
	_key(KEY_W, true)
	await _wait(1.2)
	await _shot("2_W_anda")
	var moved := mech.global_position - from
	moved.y = 0.0
	var up := IsoSettings.current.screen_to_world(Vector2(0.0, 1.0))
	print("W: se movió %.2f m, alineado con la pantalla %.3f" % [moved.length(), moved.normalized().dot(up)])
	_check("W la mueve hacia arriba de la pantalla", moved.length() > 1.0 and moved.normalized().dot(up) > 0.95)
	crew._store(999, 1 << MechCrew.W)
	await _wait(1.5)
	_check("dos en la W: bloqueada", crew.counts[MechCrew.W] == 2 and not crew.works(MechCrew.W))
	await _shot("3_W_bloqueada")
	var still := mech.mover.global_position
	await _wait(0.4)
	print("bloqueada: se movió %.3f m" % still.distance_to(mech.mover.global_position))
	_check("bloqueada no se mueve", still.distance_to(mech.mover.global_position) < 0.02)
	crew._store(999, 0)
	_key(KEY_W, false)
	await _wait(0.8)
	var yaw_was := mech.yaw()
	_key(KEY_LEFT, true)
	await _wait(0.8)
	_key(KEY_LEFT, false)
	await _wait(0.5)
	print("flecha: giró %.1f°; las piernas a %.1f° del frente" % [rad_to_deg(angle_difference(yaw_was, mech.yaw())),
		rad_to_deg(absf(angle_difference(mech.legs.facing_yaw, mech.yaw())))])
	_check("la flecha gira el frente", absf(angle_difference(yaw_was, mech.yaw())) > 0.2)
	_check("las piernas van al frente", absf(angle_difference(mech.legs.facing_yaw, mech.yaw())) < 0.35)
	local_player.intent.activate = true
	await _wait(0.6)
	_check("la E lo baja", not local_player.is_seated)
	print("ISO OK" if _bad == 0 else "ISO MAL (%d)" % _bad)
	get_tree().quit(_bad)


func _key(code: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = down
	Input.parse_input_event(event)


func _check(what: String, ok: bool) -> void:
	print(("ok   " if ok else "MAL  ") + what)
	_bad += 0 if ok else 1


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_folder, title])
