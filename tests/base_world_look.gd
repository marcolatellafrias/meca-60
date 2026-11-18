extends Node3D

## LA BASE DEL JUEGO, PARA MIRAR (unos 8 s): carga la escena de la partida (BaseWorld) con la sesión de siempre (sola,
## o con --host-local) y saca una captura desde los ojos del jugador, que nace en la esclusa, y otra después de abrir
## la compuerta (apretando el botón por código).
##   tools/godot_ventana.sh res://tests/base_world_look.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	# lo que hace «crear partida» en el menú (sin Steam, una sesión local)
	SessionManager.host()
	var world := (load("res://game/base/base_world.tscn") as PackedScene).instantiate()
	add_child(world)
	await get_tree().create_timer(5.0).timeout
	var spawner := world.get_node("CharacterSpawner") as CharacterSpawner
	print("el jugador: ", spawner.local_player.char_rigidbody.global_position if is_instance_valid(spawner.local_player) else "no está")
	await _shot("partida_1_esclusa")
	var airlock := world.get_node("Base/Plano/Esclusa") as BaseAirlock
	airlock._on_front_pressed()
	await get_tree().create_timer(2.0).timeout
	await _shot("partida_2_compuerta_abierta")
	get_tree().quit()


func _shot(file: String) -> void:
	await get_tree().create_timer(0.5).timeout
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/" + file + ".png")
		print("CAPTURA ", _folder + "/" + file + ".png")
