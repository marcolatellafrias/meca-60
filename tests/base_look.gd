extends Node3D

## LA BASE, PARA MIRAR (unos 10 segundos, sin el sandbox): arma la parcela de la base, deja que la meca se asiente en el
## elevador y saca capturas: desde arriba con la compuerta del techo abierta, adentro de la esclusa (cerrada y, después
## de apretar el botón, abierta), lo que se ve al salir y la franja con los contratos.
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
	# Una persona de 1,8 m en la franja, para la escala.
	Clay.box(self, Vector3(0.5, 1.8, 0.3), BaseLayout.at(15.0, 12.5, 0.9), Color(0.95, 0.5, 0.1))
	var eye := Camera3D.new()
	eye.fov = 60.0
	eye.far = 1000.0
	add_child(eye)
	eye.make_current()
	await get_tree().create_timer(5.0).timeout
	var strip := BaseLayout.strip
	var airlock := base.get_node("Plano/Esclusa") as BaseAirlock
	(base.get_node("Plano/Compuerta") as BaseHatch).snap_open()
	# desde afuera, arriba, sin el techo a la vista: la compuerta abierta deja ver la meca
	eye.global_position = BaseLayout.at(34.0, 34.0, 26.0)
	eye.look_at(BaseLayout.at(14.0, 9.0, 2.0))
	await _shot("base_arriba")
	# adentro de la esclusa, mirando la compuerta de adelante (cerrada, luz roja)
	eye.global_position = BaseLayout.at(BaseLayout.LENGTH + strip - 0.7, BaseLayout.NAVE + strip * 0.5 + 0.8, 1.7)
	eye.look_at(BaseLayout.at(BaseLayout.LENGTH, BaseLayout.NAVE + strip * 0.5, 1.4))
	await _shot("base_esclusa_cerrada")
	# se aprieta el botón: se abre
	airlock._on_front_pressed()
	await get_tree().create_timer(2.0).timeout
	await _shot("base_esclusa_abierta")
	# lo que se ve al salir: la franja, el gimnasio y la meca
	eye.global_position = BaseLayout.at(BaseLayout.LENGTH - 0.6, BaseLayout.NAVE + strip * 0.5, 1.7)
	eye.look_at(BaseLayout.at(8.0, 7.0, 2.5))
	await _shot("base_al_salir")
	# desde la franja, mirando los contratos y la meca detrás
	eye.global_position = BaseLayout.at(19.0, BaseLayout.NAVE + strip - 1.5, 1.7)
	eye.look_at(BaseLayout.at(10.0, BaseLayout.NAVE + 2.0, 1.6))
	await _shot("base_contratos")
	# desde el gimnasio, mirando la meca en el elevador
	eye.global_position = BaseLayout.at(20.0, 8.5, 1.7)
	eye.look_at(BaseLayout.at(5.0, 5.0, 3.5))
	await _shot("base_gimnasio")
	for node in base.find_children("*", "Mech", true, false):
		print("la meca, en ", (node as Node3D).global_position)
	get_tree().quit()


func _shot(file: String) -> void:
	await get_tree().create_timer(0.5).timeout
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/" + file + ".png")
		print("CAPTURA ", _folder + "/" + file + ".png")
