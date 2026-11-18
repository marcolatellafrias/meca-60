extends Node3D

## LOS MENÚS EN EL ESTILO MONOCROMO, PARA MIRAR (unos 5 s, sin el juego): el menú principal, su ventana de «unirse con
## código», las opciones y la pausa. Una captura de cada uno.
##   tools/godot_ventana.sh res://tests/menus_look.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var layer := CanvasLayer.new()
	add_child(layer)
	var menu := (load("res://game/ui/main_menu.tscn") as PackedScene).instantiate() as Control
	layer.add_child(menu)
	await get_tree().create_timer(0.8).timeout
	await _shot("menu_1_principal")
	menu.call("_open_join")
	await get_tree().process_frame
	(menu.get("_code_field") as MonoField).edit.text = "4f7k"
	(menu.get("_code_field") as MonoField).queue_redraw()
	await _shot("menu_2_unirse")
	menu.call("_close_join")
	menu.call("_on_options")
	await _shot("menu_3_opciones")
	menu.queue_free()
	var pause: CanvasLayer = (load("res://game/ui/pause_menu.gd") as GDScript).new()
	add_child(pause)
	await get_tree().process_frame
	UIState.open(UIState.PAUSE)
	await _shot("menu_4_pausa")
	get_tree().quit()


func _shot(file: String) -> void:
	await get_tree().create_timer(0.5).timeout
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/" + file + ".png")
		print("CAPTURA ", _folder + "/" + file + ".png")
