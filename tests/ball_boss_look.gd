extends Node

## EL JEFE BOLA (unos 60 s, sin el sandbox): quieto de frente y de costado, caminando, agachado, en lo alto de un
## salto, girando en el lugar, el cañón por la rendija, contra la pared y al lado del edificio. Imprime el centro, la velocidad y los pasos; con
## ventana, capturas numeradas.
##   tools/godot_ventana.sh res://tests/ball_boss_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _boss: BallBoss = null
var _eye: Camera3D = null
var _title: Label = null
var _shots := 0
var _blasts: Array[String] = []


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
	Clay.shape_box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
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
	add_child(world)
	var parent := Node3D.new()
	add_child(parent)
	var root := BallBossArchetype.new().build(0, parent)
	_boss = root.get_node("Bola") as BallBoss
	(root.get_node("Proyectiles") as ProjectileField).exploded.connect(func(at: Vector3, kind: Missile.Kind) -> void:
		_blasts.append("%s a %.0f m" % [Missile.Kind.keys()[kind], Vector2(at.x - _boss.global_position.x,
			at.z - _boss.global_position.z).length()]))
	# Un cubo de 18 m, el alto de la meca, para comparar.
	Clay.box(root, Vector3(6.0, 18.0, 6.0), Vector3(-22.0, 9.0, 50.0), Clay.RED.lightened(0.2))
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await _wait(1.5)
	_report("quieta")
	await _shot("quieta, de frente (el cubo rojo mide lo que la meca: 18 m)", Vector3(-30, 25, -70), Vector3(0, 18, 30))
	await _shot("quieta, de costado", Vector3(90, 28, 75), Vector3(0, 18, 30))
	# CAMINAR para adelante.
	_boss.move = Vector2(0, 1)
	await _wait(3.0)
	_report("caminando 3 s")
	await _shot("caminando para adelante", _boss.global_position + Vector3(70, 25, 65), _boss.global_position + Vector3.UP * 18)
	await _wait(2.0)
	_boss.move = Vector2.ZERO
	await _wait(2.0)
	_report("frenó")
	# AGACHARSE: sólo baja la bola.
	_boss.crouch = true
	await _wait(2.5)
	_report("agachada")
	await _shot("agachada: sólo baja la bola, los tentáculos se doblan solos", _boss.global_position + Vector3(75, 15, 75),
		_boss.global_position + Vector3.UP * 12)
	_boss.crouch = false
	await _wait(2.5)
	# SALTAR.
	var floor_y := _boss.global_position.y
	var highest := 0.0
	_boss.jump = true
	var clock := 0.0
	var shot_taken := false
	while clock < 2.5:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		highest = maxf(highest, _boss.global_position.y - floor_y)
		if not shot_taken and _boss.velocity.y < 0.0 and not _boss.grounded:
			shot_taken = true
			await _shot("en lo alto del salto", _boss.global_position + Vector3(75, 10, 75), _boss.global_position + Vector3.UP * 20)
	_boss.jump = false
	print("salto: subió %.1f m" % highest)
	await _wait(1.0)
	_report("cayó")
	# GIRAR en el lugar.
	var steps_before := _boss.legs.steps
	_boss.aim_yaw = _boss.rotation.y + PI * 0.5
	await _wait(4.0)
	print("giro de 90°: quedó a %.0f°, %d pasos" % [rad_to_deg(_boss.rotation.y), _boss.legs.steps - steps_before])
	await _shot("giró 90° en el lugar (la marca amarilla es el frente)", _boss.global_position + Vector3(0, 40, 80),
		_boss.global_position + Vector3.UP * 15)
	# EL CAÑÓN por la rendija: adelante, a 45°, al cielo, atrás y abajo.
	_boss.aim_yaw = _boss.rotation.y
	for angle: float in [0.0, 45.0, 90.0, 180.0, -45.0]:
		_boss.aim_pitch = deg_to_rad(angle)
		await _wait(3.5)
		print("cañón: pedido %.0f°, llegó a %.0f°" % [angle, rad_to_deg(_boss.cannon.pitch)])
		await _shot("el cañón a %.0f° (0 adelante, 90 al cielo)" % angle, _boss.global_position
			+ Basis(Vector3.UP, _boss.rotation.y) * Vector3(75, 25, 0), _boss.global_position + Vector3.UP * 20)
	# LOS TIROS: el simple, un poco para abajo, y los del cielo, uno tras otro.
	_boss.aim_pitch = deg_to_rad(-20.0)
	await _wait(2.0)
	_blasts.clear()
	_boss.fire = true
	await _wait(0.15)
	_boss.fire = false
	await _shot("el tiro simple, derecho adonde apunta", _boss.global_position
		+ Basis(Vector3.UP, _boss.rotation.y) * Vector3(70, 30, -30), _boss.global_position + Basis(Vector3.UP,
		_boss.rotation.y) * Vector3(0, 10, -30))
	await _wait(1.5)
	print("tiro simple: ", _blasts)
	_blasts.clear()
	_boss.barrage = true
	await _wait(0.15)
	_boss.barrage = false
	await _wait(3.2)
	await _shot("los del cielo: el cañón arriba, salen uno tras otro", _boss.global_position
		+ Basis(Vector3.UP, _boss.rotation.y) * Vector3(110, 45, -40), _boss.global_position + Basis(Vector3.UP,
		_boss.rotation.y) * Vector3(0, 25, -55))
	await _wait(1.2)
	await _shot("los del cielo: caen en fila, cada uno con su marca", _boss.global_position
		+ Basis(Vector3.UP, _boss.rotation.y) * Vector3(110, 45, -40), _boss.global_position + Basis(Vector3.UP,
		_boss.rotation.y) * Vector3(0, 10, -75))
	await _wait(4.0)
	print("del cielo: ", _blasts, " · salieron %d tiros en total" % _boss.cannon.fired)
	_boss.aim_pitch = 0.0
	# HECHA BOLA: se pliega, rueda contra las cajas, dobla y se abre.
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, 40.0)))
	await _wait(1.0)
	_boss.curl = true
	await _wait(0.4)
	await _shot("plegándose: las patas se meten", _boss.global_position + Vector3(60, 20, 45),
		_boss.global_position + Vector3.UP * 12)
	await _wait(1.0)
	print("hecha bola: centro a %.1f m, plegada %.2f" % [_boss.center_height, _boss.roll.fold])
	await _shot("hecha bola: las patas y el cañón adentro", _boss.global_position + Vector3(-30, 20, -60),
		_boss.global_position + Vector3.UP * 12)
	var crates: Array[RigidBody3D] = []
	for crate in _boss.get_parent().get_node("Cajas").get_children():
		crates.append(crate as RigidBody3D)
	_boss.move = Vector2(0, 1)
	var fastest := 0.0
	var crate_fastest := 0.0
	clock = 0.0
	var rolled_shot := false
	while clock < 5.0:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		fastest = maxf(fastest, Vector2(_boss.velocity.x, _boss.velocity.z).length())
		for crate in crates:
			crate_fastest = maxf(crate_fastest, crate.linear_velocity.length())
		if not rolled_shot and _boss.roll.hits > 0:
			rolled_shot = true
			await _shot("rodando contra las cajas: pega al tocar", _boss.global_position + Vector3(70, 25, 10),
				_boss.global_position + Vector3(0, 8, -15))
	print("rodando: hasta %.1f m/s, pegó %d veces, la caja más rápida salió a %.1f m/s" % [fastest, _boss.roll.hits,
		crate_fastest])
	# Dobla con A/D.
	var yaw_before := _boss.rotation.y
	_boss.move = Vector2(1, 1)
	await _wait(2.5)
	print("doblando 2,5 s con D: giró %.0f°" % rad_to_deg(wrapf(_boss.rotation.y - yaw_before, -PI, PI)))
	await _shot("rodando, doblando", _boss.global_position + Vector3(0, 60, 70), _boss.global_position)
	_boss.move = Vector2.ZERO
	await _wait(2.5)
	_boss.curl = false
	await _wait(0.5)
	await _shot("abriéndose: las patas salen a su lugar", _boss.global_position + Vector3(60, 25, 50),
		_boss.global_position + Vector3.UP * 12)
	await _wait(1.5)
	print("abierta: centro a %.1f m" % _boss.center_height)
	# EL BARRIDO, al lado de las cajas (que vuelven a su lugar).
	var holder := _boss.get_parent().get_node("Cajas")
	for i in holder.get_child_count():
		var crate := holder.get_child(i) as RigidBody3D
		crate.linear_velocity = Vector3.ZERO
		crate.angular_velocity = Vector3.ZERO
		crate.global_transform = Transform3D(Basis(), Vector3((i - 3.5) * 5.0, 1.5, -15.0))
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, 10.0)))
	await _wait(1.5)
	_boss.sweep = true
	await _wait(0.1)
	_boss.sweep = false
	await _wait(0.5)
	await _shot("el barrido: las paletas giran y dan la vuelta", _boss.global_position + Vector3(50, 40, 70),
		_boss.global_position + Vector3.UP * 6)
	await _wait(1.5)
	print("barrido: pegó %d veces, %d pasos después" % [_boss.legs.sweep_hits, _boss.legs.steps])
	await _wait(1.0)
	await _shot("después del barrido: las cajas, desparramadas", _boss.global_position + Vector3(50, 40, 70),
		_boss.global_position + Vector3.UP * 6)
	# CONTRA LA PARED (en x = 50, de 2 m): camina de costado hacia ella.
	_boss.put(Transform3D(Basis(), Vector3(20.0, 0.0, 0.0)))
	await _wait(1.0)
	_boss.move = Vector2(1, 0)
	await _wait(6.0)
	print("contra la pared: el centro quedó a %.2f m de su cara (el cilindro mide %.1f)" % [
		49.0 - _boss.global_position.x, BallBoss.REACH])
	await _shot("contra la pared", _boss.global_position + Vector3(-60, 30, 70), _boss.global_position + Vector3(8, 15, 0))
	# AL LADO DEL EDIFICIO (de 12 m, su cara en x = -35): los pies pisan su techo.
	_boss.move = Vector2.ZERO
	_boss.put(Transform3D(Basis(), Vector3(-20.0, 0.0, -10.0)))
	await _wait(1.0)
	_boss.move = Vector2(-1, 0)
	await _wait(4.0)
	_boss.move = Vector2.ZERO
	await _wait(1.5)
	var tips := []
	for tentacle in _boss.legs.tentacles:
		tips.append("%.1f" % tentacle.rotor.global_position.y)
	print("al lado del edificio: el alto de cada pie ", tips)
	await _shot("al lado del edificio: un pie en el techo", _boss.global_position + Vector3(10, 30, 85),
		_boss.global_position + Vector3(-12, 12, 0))
	get_tree().quit()


func _report(what: String) -> void:
	print("%s: centro a %.1f m, %.1f m/s, %d pasos" % [what, _boss.center_height,
		Vector2(_boss.velocity.x, _boss.velocity.z).length(), _boss.legs.steps])


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
