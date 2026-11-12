extends Node3D

## LA MANO DE LA MECA, PARA MIRARLA (unos 5 segundos): una abierta y una en puño, de los dos lados. Con ventana, capturas.
##   tools/godot_ventana.sh res://tests/hand_look.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 150.0, 0.0)
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.78, 0.84, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.87, 0.9)
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	# Dos manos derechas (cierran hacia −X): la abierta y el puño, con un pedazo de antebrazo detrás.
	for index in 2:
		var holder := Node3D.new()
		holder.position = Vector3(index * 4.0 - 2.0, 0.0, 0.0)
		add_child(holder)
		Clay.box(holder, Vector3(1.3, 1.3, 2.0), Vector3(0, 0, 1.0), Clay.METAL.darkened(0.2))
		var hand := MechHand.build(holder, 1.0)
		hand.fist = index == 1
	var eye := Camera3D.new()
	add_child(eye)
	eye.make_current()
	await get_tree().create_timer(0.8).timeout
	eye.global_position = Vector3(-5.5, 2.5, -6.5)
	eye.look_at(Vector3(0.0, 0.0, -1.0))
	await _shot("1_del_lado_de_la_palma")
	eye.global_position = Vector3(5.5, 2.5, -6.5)
	eye.look_at(Vector3(0.0, 0.0, -1.0))
	await _shot("2_del_dorso")
	eye.global_position = Vector3(0.0, 9.0, -1.0)
	eye.look_at(Vector3(0.0, 0.0, -1.2), Vector3.FORWARD)
	await _shot("3_de_arriba")
	get_tree().quit()


func _shot(file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
