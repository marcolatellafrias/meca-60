extends Node

## EL LUCHADOR DE ORUGAS (con ventana, unos 50 s, sin el sandbox): quieto de tres cuartos y de costado; las orugas
## (cuánto tarda en llegar a la tope, cuánto sigue soltando, cuánto tarda en frenar), girar en el lugar, andar mirando
## para otro lado (la cintura aparte), el horno abierto, la ira y contra el borde de la arena. Imprime los números; con
## ventana, capturas numeradas.
##   tools/godot_ventana.sh res://tests/brawler_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _boss: Brawler = null
var _eye: Camera3D = null
var _title: Label = null
var _shots := 0


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	PhysicsLayers.mark_fixed(ground)
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
	world.environment.ambient_light_energy = 0.6
	world.environment.glow_enabled = true
	add_child(world)
	var parent := Node3D.new()
	add_child(parent)
	# Lo maneja el test: la cabeza, apagada; enfrente, la meca jaula (hasta el 17/11/2026, la simplificada).
	BrawlerArchetype.thinking = false
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await _wait(1.0)
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, 40.0)))
	await _wait(1.0)
	var at := _boss.global_position
	await _shot("quieto, de tres cuartos", at + Vector3(38, 30, -55), at + Vector3(0, 15, 0))
	await _shot("de costado", at + Vector3(70, 18, 0), at + Vector3(0, 15, 0))
	# LAS ORUGAS: adelante a fondo, soltar, y frenar.
	var k := BrawlerSettings.current
	_boss.move = Vector2(0, 1)
	var clock := 0.0
	var reached := -1.0
	while clock < 4.0:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		if reached < 0.0 and _boss.speed >= k.speed * 0.9:
			reached = clock
	print("orugas: llega a %.1f m/s, al 90 %% a los %.2f s" % [_boss.speed, reached])
	await _shot("andando adelante", _boss.global_position + Vector3(60, 25, 40), _boss.global_position + Vector3(0, 12, 0))
	var from := _boss.global_position
	_boss.move = Vector2.ZERO
	await _wait(3.0)
	print("soltando: siguió %.1f m (ahora a %.1f m/s)" % [from.distance_to(_boss.global_position), _boss.speed])
	_boss.move = Vector2(0, 1)
	await _wait(3.0)
	_boss.move = Vector2(0, -1)
	clock = 0.0
	while _boss.speed > 0.2 and clock < 5.0:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
	_boss.move = Vector2.ZERO
	print("frenando con S desde la tope: paró en %.2f s" % clock)
	# GIRAR EN EL LUGAR.
	await _wait(1.0)
	var yaw_was := _boss.hull_yaw
	_boss.move = Vector2(1, 0)
	await _wait(2.0)
	_boss.move = Vector2.ZERO
	await _wait(0.6)
	print("girando las orugas 2 s: %.0f°" % rad_to_deg(absf(wrapf(_boss.hull_yaw - yaw_was, -PI, PI))))
	# LA CINTURA APARTE: anda para un lado mirando 90° para otro.
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, 40.0)))
	_boss.aim_yaw = PI * 0.5
	_boss.move = Vector2(0, 0.6)
	await _wait(2.5)
	print("la cintura: las orugas a %.0f°, la cintura a %.0f°" % [rad_to_deg(_boss.hull_yaw), rad_to_deg(_boss.waist_yaw)])
	await _shot("anda para adelante mirando de costado (la cintura gira aparte)", _boss.global_position + Vector3(45, 40, -45),
		_boss.global_position + Vector3(0, 14, 0))
	_boss.move = Vector2.ZERO
	# EL HORNO.
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, 40.0)))
	await _wait(0.5)
	_boss.furnace = true
	await _wait(1.0)
	var mouth := _boss.furnace_point()
	print("el horno: abierto %.0f %%, la boca a %.1f m del piso" % [_boss.opened * 100.0, mouth.y - _boss.global_position.y])
	await _shot("el horno abierto: la puerta para arriba", _boss.global_position + Vector3(14, 16, -40), mouth + Vector3.UP * 2)
	_boss.furnace = false
	await _wait(1.0)
	await _shot("el horno cerrado", _boss.global_position + Vector3(14, 16, -40), mouth + Vector3.UP * 2)
	# LA IRA.
	_boss.rage = true
	_boss.move = Vector2(0.4, 0.5)
	await _wait(3.0)
	_boss.move = Vector2.ZERO
	await _wait(0.5)
	await _shot("con ira: humo negro por las chimeneas", _boss.global_position + Vector3(50, 30, -50),
		_boss.global_position + Vector3(0, 22, 0))
	_boss.rage = false
	# CONTRA EL BORDE DE LA ARENA.
	var arena := _boss.arena
	_boss.put(Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(arena.radius - 50.0, 0.0, 0.0)))
	_boss.move = Vector2(0, 1)
	await _wait(9.0)
	print("contra el borde: quedó a %.1f m del medio (el borde, a %.0f; su caja mide %.0f de ancho)" % [
		arena.distance(_boss.global_position), arena.radius, Brawler.box().x])
	await _shot("contra el borde de la arena", _boss.global_position + Vector3(-60, 40, 60), _boss.global_position + Vector3(0, 12, 0))
	get_tree().quit()


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second


func _shot(title: String, from: Vector3, at: Vector3) -> void:
	_eye.global_transform = Transform3D(Basis(), from).looking_at(at, Vector3.UP)
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_shots += 1
	_title.text = "%d. %s" % [_shots, title]
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%02d.png" % [_folder, _shots]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
