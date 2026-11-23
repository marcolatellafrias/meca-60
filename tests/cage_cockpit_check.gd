extends Node

## LOS CONTROLES DE LA MECA JAULA PARA 3, PARA VERLOS Y PROBARLOS (CageBoards, MechCockpit): fotos desde la cápsula
## (adelante con las dos pantallas, el mando del cañón con sus botones de modo, el del puño, los mandos traídos) y desde
## arriba (el tablero de adelante, de cerca las dos palancas quietas y movidas, el dash); y cada control apretado como lo
## apretaría la mano, con lo que hace la meca: la palanca de dirección que se queda, cuánto camina con el acelerador a
## fondo y a la mitad, el dash hacia donde apunta (y al medio, nada), el salto, el modo del cañón, la carga, la piña
## cargada y el torso persiguiendo la mirada.
##   tools/godot_ventana.sh res://tests/cage_cockpit_check.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)

var _folder := ""
var _eye: Camera3D = null
var _shots: Array = []
var _mech: CageMech = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
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
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	_eye.near = 0.02
	add_child(_eye)
	_eye.make_current()
	var holder := Node3D.new()
	add_child(holder)
	CageMechArchetype.new().build(0, holder)
	for found in holder.find_children("*", "CageMech", true, false):
		if found.arms_kind != Mech.Arms.NONE or _mech == null:
			_mech = found
	var form := CageCabin.shape()
	await get_tree().create_timer(1.0).timeout
	var cabin := _mech.cabin as CageCabin
	for seat in CageCabin.SEAT_NAMES.size():
		cabin.evict(seat)
	await get_tree().create_timer(0.5).timeout
	var pieces := {}
	for entry: Array in CageBoards.LAYOUT:
		for listed: String in entry[1]:
			for key: String in (["acelerador", "dirección"] if listed == "palancas" else [listed]):
				pieces[key] = CageBoards.piece_of(cabin, key)
				print("PIEZA ", key, " en «", entry[0], "»: ", "sí" if pieces[key] != null else "NO")
	# ── LAS FOTOS ──
	var base := cabin.board_root().global_transform
	var driver := base * CageCabin.driver_eye(form)
	var top := base * Vector3(0.0, form.height() + form.arms_eye, 0.05)
	var forward := -_mech.global_basis.z
	var right := _mech.global_basis.x
	var up := Vector3.UP
	await _shot(driver, driver + forward, 85.0)
	await _shot(driver, driver - right + forward * 0.3 - up * 0.3, 85.0)
	await _shot(driver, driver + right + forward * 0.3 - up * 0.3, 85.0)
	var cannon_arm := FoldingArmArchetype.arm_of(pieces["brazo izquierdo"])
	var fist_arm := FoldingArmArchetype.arm_of(pieces["brazo derecho"])
	cannon_arm.enter_mode()
	fist_arm.enter_mode()
	await get_tree().create_timer(0.6).timeout
	await _shot(driver, driver + forward - up * 0.25, 85.0)
	cannon_arm.exit_mode()
	fist_arm.exit_mode()
	await _shot(top, top + forward - up * 0.9, 85.0)
	var levers: Vector3 = (pieces["acelerador"].global_position + pieces["dirección"].global_position) * 0.5
	await _shot(top, levers, 32.0)
	await _shot(top, pieces["dash"].global_position, 40.0)
	await _shot(top, pieces["agachar"].global_position, 40.0)
	await _shot(top, top + forward + right * 0.6 - up * 0.1, 75.0)
	# ── LO QUE HACE CADA CONTROL ──
	var cockpit := (_mech.keys as ToolMechKeys).cockpit
	var stick: TwoAxisComponent = pieces["dirección"].find_children("*", "TwoAxisComponent", true, false)[0]
	var throttle: OneAxisComponent = pieces["acelerador"].find_children("*", "OneAxisComponent", true, false)[0]
	print("ACELERADOR: arranca en ", throttle.visual_value, ", con el palo hacia adelante ",
		snappedf(throttle.global_basis.z.dot(forward), 0.01), " (1, del todo; −1, hacia atrás)")
	# La de dirección hacia donde quede el frente de la meca en su tablero; sin acelerar, no camina.
	var toward := stick.global_basis.inverse() * forward
	var push := Vector2(toward.x, -toward.y).normalized()
	stick.apply_sync_state(push)
	await get_tree().create_timer(0.6).timeout
	print("DIRECCIÓN: a 0,6 s de soltarla sigue en ", snapped(stick.axis_value, Vector2.ONE * 0.01),
		"; sin acelerar pide ", snapped(cockpit.move, Vector2.ONE * 0.01))
	# El acelerador a fondo y a la mitad.
	for wanted: float in [0.0, 0.5]:
		var from := _mech.global_position
		throttle.apply_sync_state(wanted)
		print("  acelerador en ", wanted, " (palo hacia adelante ", snappedf(throttle.global_basis.z.dot(forward), 0.01),
			"): pide ", snapped(cockpit.move, Vector2.ONE * 0.01))
		if wanted == 0.0:
			var seat := cabin.board_root().global_transform * Vector3(0.0, form.height() + form.arms_eye, 0.05)
			await _shot(seat, (pieces["acelerador"].global_position + pieces["dirección"].global_position) * 0.5, 32.0)
		await get_tree().create_timer(1.2).timeout
		var went := _mech.global_position - from
		print("  caminó ", snappedf(went.length(), 0.01), " m en 1,2 s, hacia adelante ", snappedf(went.dot(forward), 0.01))
	throttle.apply_sync_state(1.0)
	await get_tree().create_timer(1.0).timeout
	# El dash, un botón: hacia donde apunta la de dirección (a la derecha); al medio, no sale.
	var dash := ButtonArchetype.button_of(pieces["dash"])
	var aside := stick.global_basis.inverse() * right
	for way: Vector2 in [Vector2(aside.x, -aside.y).normalized(), Vector2.ZERO]:
		stick.apply_sync_state(way)
		await get_tree().create_timer(0.3).timeout
		var from := _mech.global_position
		dash.pressed.emit()
		var asked := cockpit.dash_way
		await get_tree().create_timer(0.5).timeout
		dash.released.emit()
		var went := _mech.global_position - from
		print("DASH con la de dirección en ", snapped(way, Vector2.ONE * 0.01), ": pide ", snapped(asked, Vector2.ONE * 0.01),
			", movió ", snappedf(went.length(), 0.01), " m (a la derecha ", snappedf(went.dot(right), 0.01), ")")
		await get_tree().create_timer(1.0).timeout
	# Saltar.
	var jump := ButtonArchetype.button_of(pieces["saltar"])
	var floor_y := _mech.global_position.y
	var highest := floor_y
	jump.pressed.emit()
	for i in 40:
		await get_tree().physics_frame
		highest = maxf(highest, _mech.global_position.y)
	jump.released.emit()
	print("SALTAR: subió ", snappedf(highest - floor_y, 0.01), " m")
	await get_tree().create_timer(1.5).timeout
	# Levitar un segundo y caer: sin agacharse, y agachada (baja rápido).
	var levitate := ButtonArchetype.button_of(pieces["levitar"])
	var crouch := ButtonArchetype.button_of(pieces["agachar"])
	var fuel_screen := ScreenArmArchetype.screen_of(pieces["pantalla propulsor"])
	for diving: bool in [false, true]:
		jump.pressed.emit()
		await get_tree().create_timer(0.25).timeout
		jump.released.emit()
		for i in 3:
			await get_tree().physics_frame
		levitate.pressed.emit()
		await get_tree().create_timer(1.0).timeout
		print("LEVITAR un segundo: la barra en ", snappedf(_mech.mover.fly_fuel, 0.01), ", la pantalla dice ",
			snappedf(float(fuel_screen.source.call()), 0.01))
		levitate.released.emit()
		var high := _mech.global_position.y - floor_y
		if diving:
			crouch.pressed.emit()
		var fastest := 0.0
		var time := 0.0
		while not _mech.grounded and time < 6.0:
			await get_tree().physics_frame
			time += 1.0 / Engine.physics_ticks_per_second
			fastest = maxf(fastest, -_mech.mover.velocity.y)
		if diving:
			crouch.released.emit()
		print("  ", "AGACHADA, BAJA RÁPIDO" if diving else "CAE SOLA", ": desde ", snappedf(high, 0.1), " m, a lo más ",
			snappedf(fastest, 0.1), " m/s, al piso en ", snappedf(time, 0.01), " s")
		await get_tree().create_timer(3.5).timeout
		print("  apoyada 3,5 s: la barra en ", snappedf(_mech.mover.fly_fuel, 0.01))
	# Los modos del cañón.
	for key: String in ["modo ráfaga", "modo barrido", "modo súper"]:
		ButtonArchetype.button_of(pieces[key]).pressed.emit()
		print("MODO: ", key, " → el cañón en ", CannonTip.Mode.keys()[_mech.cannon.mode])
	# El súper: cargar con el mando del cañón, la pantalla de la carga.
	var charge_screen := ScreenArmArchetype.screen_of(pieces["pantalla carga"])
	var energy_screen := ScreenArmArchetype.screen_of(pieces["pantalla energía"])
	cannon_arm.enter_mode()
	print("ENERGÍA: la pantalla dice ", snappedf(energy_screen.source.call(), 0.01))
	cannon_arm.mode_use(true)
	await get_tree().create_timer(0.6).timeout
	print("SÚPER: cargando, el cañón en ", snappedf(_mech.cannon.charge, 0.01), ", la pantalla dice ",
		snappedf(charge_screen.source.call(), 0.01))
	cannon_arm.mode_use(false)
	await get_tree().create_timer(0.2).timeout
	print("  soltado: la energía queda en ", snappedf(energy_screen.source.call(), 0.01))
	cannon_arm.exit_mode()
	await get_tree().create_timer(1.0).timeout
	# La piña cargada.
	fist_arm.enter_mode()
	fist_arm.mode_use(true)
	await get_tree().create_timer(0.5).timeout
	print("PUÑO: medio segundo mantenido, la pantalla dice ", snappedf(charge_screen.source.call(), 0.01))
	fist_arm.mode_use(false)
	print("  soltado: la piña sale a ", 1.0, "× la velocidad y ",
		snappedf(_mech.melee.punch_strength, 0.01), "× el golpe (", MechArm.Punch.keys()[_mech.melee.punching], ")")
	await get_tree().create_timer(1.5).timeout
	# El torso persigue la mirada: 50° a la derecha y 20° arriba, con su resorte.
	var k := CageMech.MOVES
	print("GIRO: resorte ", k.turn_spring, " Hz, rebote ", k.turn_bounce, ", tope ", k.turn_speed, "°/s y ", k.turn_accel,
		"°/s², inclinación hasta ", k.pitch_limit, "° · las de la meca son las de la jaula: ", _mech.kinematic_settings() == k)
	var start := _mech.global_rotation.y
	var wanted := start - deg_to_rad(50.0)
	var line := PackedStringArray()
	var ticks := Engine.physics_ticks_per_second
	for i in ticks * 3:
		fist_arm.mode_steer(wanted, deg_to_rad(20.0))
		await get_tree().physics_frame
		if (i + 1) % (ticks / 5) == 0:
			line.append("%d°/%d°" % [roundi(rad_to_deg(start - _mech.global_rotation.y)), roundi(rad_to_deg(_mech.pitch))])
	print("TORSO (giro/inclinación cada 0,2 s, pedido 50°/20°): ", " ".join(line))
	# Soltar: la mirada vuelve a ser libre y el torso deja de inclinarse.
	fist_arm.exit_mode()
	await get_tree().create_timer(1.0).timeout
	print("  soltado: inclinación ", roundi(rad_to_deg(_mech.pitch)), "°")
	_save()
	get_tree().quit()


func _shot(from: Vector3, to: Vector3, fov: float) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	image.resize(VIEW.x / 2, VIEW.y / 2, Image.INTERPOLATE_BILINEAR)
	_shots.append(image)


func _save() -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var columns := 3
	var rows := ceili(_shots.size() / float(columns))
	var sheet := Image.create(first.get_width() * columns, first.get_height() * rows, false, first.get_format())
	for index in _shots.size():
		sheet.blit_rect(_shots[index], Rect2i(Vector2i.ZERO, first.get_size()),
			Vector2i(first.get_width() * (index % columns), first.get_height() * (index / columns)))
	var path := "%s/controles_jaula.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
