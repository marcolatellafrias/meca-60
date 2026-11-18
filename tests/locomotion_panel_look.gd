extends Node

## EL PANEL DE LOCOMOCIÓN (F3) EN EL SANDBOX (con ventana, unos 10 segundos): el jugador en la fila Locomoción abre el F3
## y saca dos capturas, con un arquetipo elegido arriba y con «todos».
##   tools/godot_ventana.sh res://tests/locomotion_panel_look.tscn -- --salida=C:/carpeta

func _ready() -> void:
	var folder := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			folder = argument.trim_prefix("--salida=")
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate() as DesignSandbox
	add_child(sandbox)
	await get_tree().create_timer(1.5).timeout
	for node in sandbox.find_children("*", "SandboxParcel", true, false):
		if (node as SandboxParcel).category == "Locomoción":
			sandbox.local_player.place_at((node as SandboxParcel).global_position, 0.0)
			break
	await get_tree().create_timer(1.0).timeout
	var event := InputEventKey.new()
	event.keycode = KEY_F3
	event.physical_keycode = KEY_F3
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().create_timer(0.8).timeout
	var tuner: LocomotionTuner = null
	for entry in sandbox._tuners:
		if entry["tuner"] is LocomotionTuner and (entry["tuner"] as LocomotionTuner).visible:
			tuner = entry["tuner"]
	print("PANEL abierto: %s" % (tuner != null))
	if not folder.is_empty():
		get_viewport().get_texture().get_image().save_png(folder + "/f3_arquetipo.png")
	if tuner != null:
		tuner._pick_all()
		await get_tree().create_timer(0.5).timeout
		if not folder.is_empty():
			get_viewport().get_texture().get_image().save_png(folder + "/f3_todos.png")
	get_tree().quit()
