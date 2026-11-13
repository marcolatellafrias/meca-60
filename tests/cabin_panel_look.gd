extends Node3D

## EL PANEL F2 DE LA FORMA DE LA MECA (CabinShapePanel), abierto, para mirarlo: una captura. Unos 5 segundos.
##   tools/godot_ventana.sh res://tests/cabin_panel_look.tscn -- --salida=C:/carpeta

func _ready() -> void:
	var folder := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 1000)
	var panel := CabinShapePanel.new()
	add_child(panel)
	panel.setup_panel()
	panel.toggle()
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not folder.is_empty():
		get_viewport().get_texture().get_image().save_png(folder + "/panel_f2.png")
	get_tree().quit()
