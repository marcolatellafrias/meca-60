extends Node

## EL TALLER DE JEFES (con ventana, unos 10 segundos, sin el sandbox): el cuerpo modular (BossParts, BossRecipe,
## BossFrame). Capturas del que se arma con tres recetas (una que encaja, otra de cuatro brazos y una que no encaja) y
## de los ejemplos de atrás; imprime de cada una si encaja y qué puntos y zonas de golpe ofrece. Guarda en
## la carpeta de --fotos= (si no, en user://).

var _eye: Camera3D = null
var _folder := "user://"


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--fotos="):
			_folder = argument.trim_prefix("--fotos=")
	var ground := StaticBody3D.new()
	Clay.box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, 205.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.8, 0.82, 0.85)
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	var parent := Node3D.new()
	add_child(parent)
	BossWorkshopArchetype.new().build(0, parent)
	await _wait(0.5)
	_look(Vector3(0.0, 9.0, -75.0), Vector3(0.0, 30.0, 25.0))
	await _shot("0_ejemplos")
	var tries := [["orugas", "ancho", "puno", "visor", "pinza"], ["cuatro", "cuatro", "canon", "antena", "pinza"],
		["bipedo", "angosto", "puno", "ninguna", "pinza"]]
	for index in tries.size():
		var each: Array = tries[index]
		BossWorkshopArchetype.recipe = BossRecipe.of(each[0], each[1], each[2], each[3], each[4])
		BossWorkshopArchetype.refresh()
		await _wait(0.3)
		var made := BossWorkshopArchetype.recipe
		print("%s · %s" % [made.title(), "encaja" if made.problems().is_empty() else "NO ENCAJA: " + "; ".join(made.problems())])
		print("   puntos: %s · zonas de golpe: %s" % [", ".join(made.points()), ", ".join(made.zones())])
		_look(Vector3(0.0, 13.0, -20.0), Vector3(22.0, 20.0, 22.0))
		await _shot("%d_armado" % (index + 1))
	get_tree().quit()


func _look(at: Vector3, from: Vector3) -> void:
	_eye.global_transform = Transform3D(Basis(), from).looking_at(at, Vector3.UP)


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_folder.path_join("taller_%s.png" % name))


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
