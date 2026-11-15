extends Node3D

## LA BASE, PARA MIRAR (unos 8 segundos, sin el sandbox): arma la parcela de la base, deja que la meca se asiente en el
## elevador y saca tres capturas: desde afuera con el techo y la compuerta abierta, desde la franja de las consolas
## mirando la meca, y desde el piso del gimnasio hacia la compuerta.
##   tools/godot_ventana.sh res://tests/base_look.tscn -- --salida=C:/carpeta

var _folder := ""


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(300, 1, 300), Vector3(0, -0.9, 0), Color(0.5, 0.48, 0.45))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	var base := BaseArchetype.new().build(0, self)
	# Una persona de 1,8 m frente a las consolas, para la escala.
	Clay.box(self, Vector3(0.5, 1.8, 0.3), BaseLayout.at(38.0, 27.0, 0.9), Color(0.95, 0.5, 0.1))
	var eye := Camera3D.new()
	eye.fov = 50.0
	eye.far = 1000.0
	add_child(eye)
	eye.make_current()
	await get_tree().create_timer(5.0).timeout
	(base.get_node("Plano/Compuerta") as BaseHatch).snap_open()
	eye.global_position = BaseLayout.at(70.0, 62.0, 60.0)
	eye.look_at(BaseLayout.at(30.0, 14.0, 10.0))
	await _shot("base_arriba")
	eye.global_position = BaseLayout.at(57.0, 28.0, 1.7)
	eye.look_at(BaseLayout.at(20.0, 14.0, 6.0))
	await _shot("base_desde_las_consolas")
	eye.global_position = BaseLayout.at(40.0, 20.0, 1.7)
	eye.look_at(BaseLayout.at(12.0, 12.0, 22.0))
	await _shot("base_la_compuerta")
	# lo que hace el F1 al guardar: otras medidas (sin guardarlas) y la base se vuelve a armar en su lugar
	BaseSettings.current.strip_depth = 18.0
	BaseSettings.current.strip_height = 10.0
	BaseSettings.current.nave_height = 28.0
	BaseLayout.rebuild(base.get_node("Plano") as Node3D)
	eye.global_position = BaseLayout.at(70.0, 62.0, 60.0)
	eye.look_at(BaseLayout.at(30.0, 14.0, 10.0))
	await _shot("base_otras_medidas")
	get_tree().quit()


func _shot(file: String) -> void:
	await get_tree().create_timer(0.5).timeout
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/" + file + ".png")
		print("CAPTURA ", _folder + "/" + file + ".png")
