extends Node

## EL SANDBOX ENTERO, PARA MIRAR: lo arma, imprime sus filas en orden (supercategoría, nombre, parcelas, cuáles se
## armaron y cuáles están lejos) y, con ventana, saca una vista de arriba y otra parado en una parcela (el panel chico).
##   tools/godot_ventana.sh res://tests/sandbox_look.tscn -- --salida=C:/carpeta [--fila=Meca discreta]

var _folder := ""
var _row := "Meca discreta"


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		elif argument.begins_with("--fila="):
			_row = argument.trim_prefix("--fila=")
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate() as DesignSandbox
	add_child(sandbox)
	await get_tree().create_timer(2.0).timeout
	_report(sandbox)
	var eye := Camera3D.new()
	eye.fov = 55.0
	eye.far = 4000.0
	add_child(eye)
	eye.make_current()
	for view: Array in [["sandbox_arriba", Vector3(-45.0, 55.0, 150.0), Vector3(40.0, 0.0, 230.0)],
			["sandbox_arranque", Vector3(-40.0, 45.0, -30.0), Vector3(40.0, 0.0, 60.0)],
			["sandbox_bloques", Vector3(-26.0, 10.0, 715.0), Vector3(-4.0, 0.0, 765.0)],
			["sandbox_archivo", Vector3(-30.0, 40.0, 600.0), Vector3(30.0, 0.0, 680.0)]]:
		eye.global_position = view[1]
		eye.look_at(view[2])
		await get_tree().create_timer(0.5).timeout
		_shot(view[0])
	eye.queue_free()
	var target: SandboxParcel = null
	for parcel in sandbox.find_children("*", "SandboxParcel", true, false):
		if (parcel as SandboxParcel).category == _row:
			target = parcel
			break
	if target != null:
		var rect := target.interaction_rect()
		sandbox.local_player.place_at(Vector3(rect.position.x + 1.0, 0.0, rect.get_center().y), -PI * 0.5)
		await get_tree().create_timer(2.0).timeout
		print("PARADO EN: ", sandbox.current_parcel().name if sandbox.current_parcel() != null else "ninguna")
		_report(sandbox)
		_shot("sandbox_parcela")
		# LA B: corta, el modo creativo; larga, el cuerpo.
		_key(KEY_B, true)
		await get_tree().create_timer(0.1).timeout
		_key(KEY_B, false)
		await get_tree().process_frame
		print("B CORTA: creativo %s · cuerpo %s" % [sandbox.local_player.player_controller.get("_creative"),
			sandbox.is_body()])
		_key(KEY_B, true)
		await get_tree().create_timer(0.7).timeout
		_key(KEY_B, false)
		await get_tree().create_timer(0.5).timeout
		print("B LARGA: cuerpo %s" % sandbox.is_body())
		var mech := target.find_children("*", "Mech", true, false)[0] as Mech
		var before := mech.global_position
		_key(KEY_M, true)
		_key(KEY_M, false)
		await get_tree().create_timer(1.0).timeout
		print("M (pegarle fuerte): la meca se movió %.1f m" % mech.global_position.distance_to(before))
	get_tree().quit()


func _key(keycode: Key, down: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = down
	Input.parse_input_event(event)


func _report(sandbox: DesignSandbox) -> void:
	for node in sandbox.get_children():
		if node is MeshInstance3D and (str(node.name).begins_with("Super") or str(node.name).begins_with("Archiv")):
			print("PISO %s en z %.0f…%.0f" % [node.name, (node as MeshInstance3D).position.z - ((node as MeshInstance3D).mesh as PlaneMesh).size.y * 0.5,
				(node as MeshInstance3D).position.z + ((node as MeshInstance3D).mesh as PlaneMesh).size.y * 0.5])
	for parcel in sandbox.find_children("*", "SandboxParcel", true, false):
		var p := parcel as SandboxParcel
		print("PARCELA %s | %s | grupo «%s» | zona %.1f m | armada %s | lejos %s" % [p.name,
			SandboxSuper.name_of(p.row.super_id), p.group, p.interact_pad, p.built, p.is_far()])


func _shot(file: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_folder, file])
	print("CAPTURA %s/%s.png" % [_folder, file])
