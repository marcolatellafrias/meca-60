extends Node

## POSEER A UN MANIQUÍ DE LA MECA, PROBADO POR CÓDIGO (unos 20 segundos; ver CharacterPossession): mirando su silla la O
## apunta a él (no a la meca); poseído, la E lo para, la W lo hace caminar por la cabina, y al soltarlo se queda parado,
## sin volver a la silla. Con ventana, capturas.
##   tools/godot_ventana.sh res://tests/possess_character.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	MechCabin.dummies_on = true
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate() as DesignSandbox
	add_child(sandbox)
	await _seconds(1.5)
	var possession := SandboxPossession.of(get_tree())
	var dummy: BoneInstantiator = null
	var mech: Mech = null
	for each: Mech in sandbox.find_children("*", "Mech", true, false):
		if each.cabin != null and not each.cabin.dummies.is_empty():
			mech = each
			dummy = each.cabin.dummies[0] as BoneInstantiator
			break
	if dummy == null:
		print("NO HAY MANIQUÍES")
		get_tree().quit()
		return
	await _seconds(1.0)
	var seat := dummy.current_seat as SeatInteractable
	print("MANIQUÍ %s · sentado %s · en el grupo %s" % [dummy.name, dummy.is_seated, dummy.is_in_group(SandboxPossession.GROUP)])
	# MIRANDO SU SILLA: una cámara delante de la silla, apuntándole.
	var eye := Camera3D.new()
	add_child(eye)
	var chair := seat.global_position + seat.global_basis.y * 0.45
	eye.global_position = chair + seat.global_basis.z * 1.0 + seat.global_basis.y * 1.1
	eye.look_at(chair, seat.global_basis.y)
	eye.make_current()
	await _frames(3)
	var aimed := possession._look()
	var query := PhysicsRayQueryParameters3D.create(eye.global_position, chair)
	query.collision_mask = 0xFFFFFFFF & ~PhysicsLayers.PARCEL_BOUND & ~MotionFrame.LAYER
	var hit := eye.get_world_3d().direct_space_state.intersect_ray(query)
	print("RAYO: pega en %s" % [(hit["collider"] as Node).get_path() if not hit.is_empty() else "nada"])
	print("MIRANDO SU SILLA: apunta a %s" % [aimed.name if aimed != null else "nada"])
	eye.queue_free()
	possession.view = SandboxPossession.View.FIRST
	possession.possess(dummy)
	await _seconds(0.5)
	print("O: posee %s" % _name(possession))
	await _shot("1_sentado_primera")
	await _key(KEY_E)
	await _seconds(1.0)
	print("E: sentado %s" % dummy.is_seated)
	# SU INTERFAZ: el puntito y el contorno de lo que mira (ver CharacterPossession). Se da vuelta hacia su silla.
	for i in 3:
		var to_seat := chair - possession._camera.global_position
		dummy.intent.look_yaw = CharacterIntent.yaw_of(dummy.char_rigidbody.frame, to_seat)
		dummy.intent.look_pitch = asin(clampf(to_seat.normalized().y, -1.0, 1.0))
		await _seconds(0.3)
	var hands := CharacterActions.of(dummy)._hands
	var crosshairs := dummy.find_children("*", "Crosshair", true, false).size()
	print("INTERFAZ: puntito %d · contorno prendido %s · mira %s" % [crosshairs,
		hands.detector.watched if hands != null else false,
		hands.detector.get_hovered().name if hands != null and hands.detector.get_hovered() != null else "nada"])
	await _shot("2a_mirando_su_silla")
	possession.view = SandboxPossession.View.THIRD
	await _seconds(0.3)
	await _shot("2_parado_tercera")
	var rb := dummy.char_rigidbody
	var start := mech.to_local(rb.global_position)
	await _hold(KEY_W, 1.2)
	var moved := mech.to_local(rb.global_position) - start
	print("W: anduvo %.2f m dentro de la meca · marco %s · se cayó %s" % [Vector2(moved.x, moved.z).length(),
		rb.frame.name if rb.frame != null else "ninguno", dummy._is_ragdolling()])
	await _shot("3_caminando")
	await _key(KEY_O)
	await _seconds(2.0)
	print("O: suelta · posee %s · sentado %s · intención de silla %s" % [_name(possession), dummy.is_seated, dummy.intent.seat])
	var hands_after := CharacterActions.of(dummy)._hands
	print("SOLTADO: puntito %d · contorno prendido %s" % [dummy.find_children("*", "Crosshair", true, false).size(),
		hands_after.detector.watched if hands_after != null else false])
	await _shot("4_soltado")
	print("SCRIPT sin errores hasta el final")
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
