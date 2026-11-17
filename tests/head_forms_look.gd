extends Node3D

## LAS FORMAS DE CABEZA (con ventana, unos segundos): arma la parcela sola (ver HeadFormsArchetype) y saca una captura.
##   tools/godot_ventana.sh res://tests/head_forms_look.tscn -- --salida=C:/carpeta

func _ready() -> void:
	var folder := ""
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			folder = argument.trim_prefix("--salida=")
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40.0, 30.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.82, 0.86, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.86)
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	(HeadFormsArchetype.catalogue()[0] as HeadFormsArchetype).build(0, self)
	var eye := Camera3D.new()
	eye.fov = 45.0
	add_child(eye)
	eye.make_current()
	eye.global_position = Vector3(0.0, 2.2, 9.5)
	eye.look_at(Vector3(0.0, 1.4, 0.0))
	for i in 10:
		await get_tree().process_frame
	if not folder.is_empty():
		get_viewport().get_texture().get_image().save_png(folder + "/formas_de_cabeza.png")
	get_tree().quit()
