extends Node

## EL PERSONAJE DE CHARACTER-PARAMETRIC EN LA MECA, PROBADO POR CÓDIGO: arranca el sandbox, mira que el jugador sea el
## personaje de allá (ente), pasa a cuerpo (B), sube a la meca (U), se sienta en la silla de las piernas (como la E de
## allá: `activate`), camina la meca, se levanta y viaja parado adentro mientras la meca camina (el torso es un marco),
## maneja la meca desde afuera (O) y vuelve, y agarra un paquete de la fila Objetos. Imprime lo que mide; con ventana,
## capturas.
##   headless:     godot --headless --path . res://tests/player_check.tscn
##   con capturas: tools/godot_ventana.sh res://tests/player_check.tscn -- --salida=C:/carpeta

var _folder := ""
var _sandbox: DesignSandbox = null
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
	_sandbox = (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate() as DesignSandbox
	add_child(_sandbox)
	await _seconds(1.0)
	var player := _sandbox.local_player
	print("JUGADOR: %s · clase %s · cuerpo %s" % [player.name, "ente" if player.kind.motion == CharacterKind.Motion.DIRECT
		else "jugador", _sandbox.is_body()])
	await _key(KEY_B)
	await _seconds(1.0)
	player = _sandbox.local_player
	print("B: %s · cuerpo %s · %d kg" % [player.name, _sandbox.is_body(), roundi(player.char_rigidbody.mass)])
	await _shot("El cuerpo, en el arranque del sandbox", "1_cuerpo")
	# A LA MECA.
	var arena: TestArena = null
	for parcel: SandboxParcel in _sandbox.find_children("*", "SandboxParcel", true, false):
		if parcel.archetype is MechTestArchetype:
			arena = parcel.root() as TestArena
	var mech := arena.mech
	mech.board()
	await _seconds(1.5)
	var body := player.char_rigidbody
	print("SUBIÓ: marco %s · altura sobre el piso del torso %.2f m" % [MotionFrame.frame_of(body) == mech.torso.frame,
		(mech.torso.global_transform.affine_inverse() * body.global_position).y - MechTorso.floor_y(0)])
	await _shot("Adentro de la meca, parado", "2_adentro")
	# SENTARSE en las piernas, como la E de allá.
	var legs := mech.torso.seats[0]
	legs.chair.activate(player)
	await _seconds(1.5)
	print("SENTADO: %s · puesto de la meca %s" % [player.is_seated, mech._seat.name if mech._seat != null else "ninguno"])
	await _shot("Sentado en las piernas", "3_sentado")
	var start := mech.global_position
	await _hold(KEY_W, 3.0)
	print("CAMINÓ la meca: %.1f m · sigue sentado %s" % [start.distance_to(mech.global_position), player.is_seated])
	# LEVANTARSE y viajar parado: la meca camina sola (las flechas desde la vigía no; acá se la empuja por código).
	legs.chair.activate(player)
	await _seconds(1.5)
	var local_before := mech.torso.global_transform.affine_inverse() * body.global_position
	print("PARADO: sentado %s · marco %s" % [player.is_seated, MotionFrame.frame_of(body) == mech.torso.frame])
	mech.throttle = 1.0
	for i in 600:
		mech.throttle = 1.0
		await get_tree().physics_frame
	var local_after := mech.torso.global_transform.affine_inverse() * body.global_position
	print("VIAJÓ PARADO 2,5 s: se corrió %.2f m adentro del torso · se cayó %s" % [local_before.distance_to(local_after),
		player.ragdoll_util.is_active])
	await _shot("Parado mientras la meca camina", "4_parado_caminando")
	await _seconds(1.0)
	# DESDE AFUERA (O) y vuelta.
	var parcel_of_arena := arena.get_parent() as SandboxParcel
	SandboxPossession.of(get_tree()).possess(mech)
	await _seconds(0.5)
	print("DESDE AFUERA: %s · jugador apagado %s · cámara %s" % [mech.driven_from_outside(),
		player.process_mode == Node.PROCESS_MODE_DISABLED, get_viewport().get_camera_3d().name])
	await _key(KEY_O)
	await _seconds(0.5)
	print("VOLVIÓ: jugador prendido %s · cámara del jugador %s" % [player.process_mode != Node.PROCESS_MODE_DISABLED,
		get_viewport().get_camera_3d() == player.player_camera])
	print("(parcela de la arena: %s)" % parcel_of_arena.name)
	# AGARRAR un paquete: el jugador al lado de la caja, mirándola, clic.
	var box: RigidBody3D = null
	for parcel: SandboxParcel in _sandbox.find_children("*", "SandboxParcel", true, false):
		if parcel.archetype is ObjectLotArchetype and box == null:
			var bodies := parcel.find_children("*", "RigidBody3D", true, false)
			if not bodies.is_empty():
				for each in bodies:
					if each.name == "wardrobe":
						box = each as RigidBody3D
	if box == null:
		print("AGARRAR: no hay paquetes")
	else:
		var toward := Vector3(-0.5, 0, 0)
		player.place_at(Vector3(box.global_position.x, 0.0, box.global_position.z) + toward, -PI * 0.5)
		await _seconds(1.0)
		# Mirar hacia abajo, a la caja, y apretar el clic izquierdo (como un jugador).
		# (Sin foco el mouse de la prueba no queda capturado: la mirada se pone directo en el controlador.)
		var controller := player.player_controller
		var to_box := box.global_position - controller.player_camera.global_position
		controller.camera_yaw = atan2(-to_box.x, -to_box.z)
		controller.apply_camera_pitch(atan2(to_box.y, Vector2(to_box.x, to_box.z).length()))
		await _seconds(0.5)
		var height_before := box.global_position.y
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = true
		Input.parse_input_event(click)
		await _seconds(0.3)
		var ic := player.player_controller.interaction_controller
		var hit := ic.detector.cast_aim_ray()
		var grab := box.find_children("*", "GrabbableInteractable", false, false)
		var near: Vector3 = hit.get("position", box.global_position)
		var point: Node3D = (grab[0] as GrabbableInteractable).get_nearest_handle_point(near) if not grab.is_empty() else null
		print("  clic: intent.use %s · rayo pega en %s · apunta %s · punto %s a %.2f m del pecho (alcance %.2f) · fuera %s" % [
			player.intent.use, (hit.get("collider") as Node).name if not hit.is_empty() else "nada",
			ic.detector.get_hovered(), point != null, (point.global_position.distance_to(ic._get_interaction_origin())
			if point != null else -1.0), ic.grip_dist_max, ic._is_out_of_reach(point.global_position) if point != null else true])
		await _seconds(2.7)
		print("AGARRAR %s: subió %.2f m · lo tiene %s" % [box.name, box.global_position.y - height_before,
			is_instance_valid(player.intent.grab)])
		await _shot("Agarrando un paquete", "5_agarrar")
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		Input.parse_input_event(release)
	get_tree().quit()


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
	var up := event.duplicate() as InputEventKey
	up.pressed = false
	Input.parse_input_event(up)
	await _frames(2)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await _frames(8)
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
