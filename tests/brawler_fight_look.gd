extends Node

## LA PELEA CON EL LUCHADOR (con ventana, unos 60 s, sin el sandbox), con la meca cinemática quieta mirándolo: te rodea
## y te embiste (cuántas veces, cuántas te alcanzó, la vida); se estrella contra el borde de la arena; y con el horno
## abierto, dos piñas en el horno (cuánto le sacan). Imprime los números; con ventana, capturas numeradas.
##   tools/godot_ventana.sh res://tests/brawler_fight_look.tscn -- --salida=C:/carpeta

const FIGHT := 35.0

var _folder := ""
var _boss: Brawler = null
var _brain: BrawlerBrain = null
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
	BrawlerArchetype.thinking = true
	BrawlerArchetype.mech_kind = BrawlerArchetype.Kind.KINEMATIC
	var root := BrawlerArchetype.new().build(0, parent)
	_boss = root.get_node("Luchador") as Brawler
	_brain = _boss.get_node("Cabeza") as BrawlerBrain
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await _wait(0.5)
	var mech := _brain.target as Mech
	mech.scripted = true
	# LA PELEA: la meca quieta, mirándolo.
	var clock := 0.0
	var last := ""
	var seen := {}
	while clock < FIGHT:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		_face(mech)
		if _brain.stage != last:
			last = _brain.stage
			print("%5.1f s · %s, a %.0f m" % [clock, last, _gap(mech)])
			if not seen.has(last) and (last.contains("horno") or last.contains("arranca") or last.contains("estrell")):
				seen[last] = true
				await _shot(last, _boss.global_position + Vector3(70, 45, 50), (_boss.global_position + _ground(mech)) * 0.5
					+ Vector3.UP * 10)
	print("en %.0f s: embistió %d, te alcanzó %d, se estrelló %d · la meca quedó con %.0f de vida" % [FIGHT,
		_brain.charges, _brain.landed, _brain.crashes, Health.of(mech).left])
	# CONTRA EL BORDE: la meca cerca del borde, el jefe de frente a ella; embiste y se estrella.
	var crashes := _brain.crashes
	var arena := _boss.arena
	_brain.awake = false
	await _wait(0.2)
	mech.put(Transform3D(Basis(), Vector3(0.0, Mech.standing_height(), -(arena.radius - 8.0))))
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, -(arena.radius - 75.0))))
	Health.of(mech).left = BrawlerArchetype.MECH_HEALTH
	_brain.awake = true
	clock = 0.0
	while _brain.crashes == crashes and clock < 20.0:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		_face(mech)
	await _wait(0.4)
	print("contra el borde: se estrelló %s, a %.1f m del medio; aturdido: «%s»" % ["sí" if _brain.crashes > crashes else "no",
		arena.distance(_boss.global_position), _brain.stage])
	await _shot("se estrelló contra el borde: aturdido, con el horno abierto", _boss.global_position + Vector3(60, 35, 40),
		_boss.global_position + Vector3.UP * 12)
	# LAS PIÑAS EN EL HORNO: el jefe quieto con el horno abierto, la meca enfrente.
	_brain.awake = false
	await _wait(0.2)
	_boss.put(Transform3D(Basis(), Vector3(0.0, 0.0, 20.0)))
	_boss.furnace = true
	var front := _boss.global_position + _boss.heading() * 35.0
	mech.put(Transform3D(Basis(Vector3.UP, PI), Vector3(front.x, Mech.standing_height(), front.z)))
	await _wait(1.0)
	# Camina hacia él hasta toparse.
	for i in 900:
		await get_tree().physics_frame
		_face(mech)
		mech.move = Vector2(0.0, 1.0)
	mech.move = Vector2.ZERO
	await _wait(0.5)
	var before := Health.of(_boss).left
	for arm in mech.arms:
		arm.punch_at(_boss.furnace_point())
	var closest := 999.0
	for i in 300:
		await get_tree().physics_frame
		for hand: Node3D in mech.find_children("*", "MechHand", true, false):
			closest = minf(closest, hand.global_position.distance_to(_boss.furnace_point()))
	print("los puños: lo más cerca del horno, %.1f m (el horno, a %.1f m del piso; la meca, a %.1f m del jefe)" % [closest,
		_boss.furnace_point().y, _gap(mech)])
	print("dos piñas al horno abierto: %d en el horno, %d en el cuerpo · le sacaron %.0f" % [_brain.furnace_hits,
		_brain.body_hits, before - Health.of(_boss).left])
	await _shot("piñas al horno abierto", _boss.global_position + Vector3(45, 25, -30), _boss.furnace_point())
	get_tree().quit()


func _face(mech: Mech) -> void:
	var to_boss := _boss.global_position - _ground(mech)
	mech.aim_yaw = atan2(-to_boss.x, -to_boss.z)
	mech.move = Vector2.ZERO


func _ground(mech: Mech) -> Vector3:
	return mech.mover.global_position if mech.mover != null else mech.global_position


func _gap(mech: Mech) -> float:
	var gap := _ground(mech) - _boss.global_position
	gap.y = 0.0
	return gap.length()


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
