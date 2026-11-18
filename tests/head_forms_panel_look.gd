extends Node

## EL EDITOR DE LAS FORMAS DE CABEZA EN EL SANDBOX (con ventana, unos 15 segundos; ver HeadFormsPanel): el jugador en la
## fila Cabezas abre el F3, elige la forma 3, prende un corte, aplana las caras y saca capturas de cada pestaña. No
## guarda nada.
##   tools/godot_ventana.sh res://tests/head_forms_panel_look.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate() as DesignSandbox
	add_child(sandbox)
	await get_tree().create_timer(1.5).timeout
	for node in sandbox.find_children("*", "SandboxParcel", true, false):
		if (node as SandboxParcel).archetype is HeadFormsArchetype:
			sandbox.local_player.place_at((node as SandboxParcel).global_position + Vector3(-3.0, 0.0, 4.5), 0.0)
			break
	await get_tree().create_timer(1.5).timeout
	var event := InputEventKey.new()
	event.keycode = KEY_F3
	event.physical_keycode = KEY_F3
	event.pressed = true
	Input.parse_input_event(event)
	await get_tree().create_timer(0.8).timeout
	var panel: HeadFormsPanel = null
	for entry in sandbox._tuners:
		if entry["tuner"] is HeadFormsPanel:
			panel = entry["tuner"]
	print("PANEL abierto: %s" % (panel != null and panel.visible))
	if panel == null:
		get_tree().quit()
		return
	panel._pick(2)
	await _shot("1_forma")
	panel._draft.cuts[3].active = true
	panel._draft.cuts[3].width = 0.2
	panel._changed()
	panel._tab_name = HeadFormsPanel.TAB_CUTS
	panel.rebuild()
	await _shot("2_cortes")
	HeadForms.table().face_flat = 0.7
	panel._flat_changed()
	panel._tab_name = HeadFormsPanel.TAB_ALL
	panel.rebuild()
	await _shot("3_todas_aplanadas")
	print("FORMAS: %d · editando la %d · prueba sin guardar: %s" % [HeadForms.count(), HeadForms.editing + 1,
		HeadForms.preview.has(2)])
	get_tree().quit()


func _shot(file_name: String) -> void:
	await get_tree().create_timer(0.6).timeout
	if not _folder.is_empty():
		get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_folder, file_name])
