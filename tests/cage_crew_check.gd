extends Node

## LA MECA JAULA PARA 1, 2 Y 3 JUGADORES, PARA VERLA Y PROBARLA (CageShape.crew, CageBoards, DriveHandle, MechShield):
## las tres una al lado de la otra, con sus sillas y sus piezas; la de 1 manejada con el teclado desde el manubrio del
## techo (WASD, espacio, el clic derecho); y el escudo del brazo derecho de la de 3 frenando un golpe de frente, con el
## parry, y no uno de atrás. La hoja: las tres de afuera, adentro de la de 1 con el manubrio plegado y traído, y la de 3
## con el escudo levantado (de afuera y desde adentro) y bajado.
##   tools/godot_ventana.sh res://tests/cage_crew_check.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const GAP := 14.0

var _folder := ""
var _eye: Camera3D = null
var _shots: Array = []


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
	# LAS TRES: de 1, de 2 y de 3, mirando hacia −Z, una al lado de la otra.
	var form := CageShape.current
	var was := form.crew
	var mechs: Array[CageMech] = []
	for crew in 3:
		form.crew = crew
		var mech := CageMech.new()
		mech.equipment = CageMechArchetype.ROW
		# La de 3, con el escudo en el brazo derecho (el canje: un arma menos).
		if crew == 2:
			mech.loadout = [ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.CANNON, true),
				ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.SHIELD, true)]
		mech.position = Vector3((crew - 1) * GAP, Mech.standing_height(mech.cabin_shape), 0.0)
		add_child(mech)
		mechs.append(mech)
	form.crew = was
	await get_tree().create_timer(1.0).timeout
	for crew in 3:
		var cabin := mechs[crew].cabin as CageCabin
		var names := PackedStringArray()
		for chair in cabin.chairs:
			names.append(str(chair.name).trim_prefix("Asiento "))
		print("DE ", crew + 1, ": sillas ", ", ".join(names), " · bloque de arriba ",
			"sí" if cabin.find_child("Bloque de arriba", true, false) != null else "no", " · torre ",
			"sí" if cabin.find_child("Torre", true, false) != null else "no", " · manubrio ",
			"sí" if CageBoards.piece_of(cabin, "manejo") != null else "no", " · palancas de arriba ",
			"sí" if CageBoards.piece_of(cabin, "acelerador") != null else "no", " · escudo de arriba ",
			"sí" if CageBoards.piece_of(cabin, "escudo") != null else "no")
		for seat in CageCabin.SEAT_NAMES.size():
			cabin.evict(seat)
	await get_tree().create_timer(0.5).timeout
	await _shot(Vector3(-8.0, 9.0, 22.0), Vector3(0.0, 3.0, 0.0), 50.0)
	# ── LA DE 1: EL MANUBRIO ──
	var solo := mechs[0]
	var cabin := solo.cabin as CageCabin
	var shape := CageCabin.shape()
	var handle := FoldingArmArchetype.arm_of(CageBoards.piece_of(cabin, "manejo")) as DriveHandle
	var seat := cabin.board_root().global_transform * CageCabin.driver_eye(shape)
	var forward := -solo.global_basis.z
	await _shot(seat, seat + forward * 0.6 + Vector3.UP * 0.5, 85.0)
	handle.enter_mode()
	await get_tree().create_timer(0.6).timeout
	await _shot(seat, seat + forward - Vector3.UP * 0.25, 85.0)
	var cockpit := (solo.keys as ToolMechKeys).cockpit
	# W un segundo: camina adelante.
	var from := solo.global_position
	_key(KEY_W, true)
	await get_tree().create_timer(1.0).timeout
	_key(KEY_W, false)
	var went := solo.global_position - from
	print("MANEJO, W un segundo: pidió ", snapped(cockpit.move, Vector2.ONE * 0.01), " y caminó ",
		snappedf(went.dot(forward), 0.01), " m adelante")
	await get_tree().create_timer(1.0).timeout
	print("  soltada la W, pide ", snapped(cockpit.move, Vector2.ONE * 0.01))
	# Espacio: salta.
	var floor_y := solo.global_position.y
	var highest := floor_y
	_key(KEY_SPACE, true)
	for i in 60:
		await get_tree().physics_frame
		highest = maxf(highest, solo.global_position.y)
	_key(KEY_SPACE, false)
	print("  espacio: subió ", snappedf(highest - floor_y, 0.01), " m")
	await get_tree().create_timer(1.5).timeout
	# 2: el modo del cañón; el clic derecho mantenido medio segundo: la piña cargada.
	_key(KEY_2, true)
	await get_tree().create_timer(0.1).timeout
	_key(KEY_2, false)
	print("  la tecla 2: el cañón en ", CannonTip.Mode.keys()[solo.cannon.mode])
	handle.mode_use_alt(true)
	await get_tree().create_timer(0.5).timeout
	handle.mode_use_alt(false)
	print("  clic derecho medio segundo: la piña sale a ", snappedf(solo.melee.punch_pace, 0.01), "× la velocidad (",
		MechArm.Punch.keys()[solo.melee.punching], ")")
	await get_tree().create_timer(1.0).timeout
	handle.exit_mode()
	print("  soltado el manubrio: pide ", snapped(cockpit.move, Vector2.ONE * 0.01), ", escudo ", cockpit.shield)
	await get_tree().create_timer(1.0).timeout
	# ── EL ESCUDO, en la de 3: en el brazo derecho; frena lo de frente, no lo de atrás ──
	var trio := mechs[2]
	var energy := trio.energy
	energy.level = 1.0
	var front := trio.global_position - trio.global_basis.z * 2.5
	var behind := trio.global_position + trio.global_basis.z * 2.5
	# Como un jefe: primero avisa el golpe una vez, con dónde pega (block_hit; si lo frena el escudo, se da por usado), y
	# si no, pega.
	var hit := func(at: Vector3) -> bool:
		if trio.block_hit(at):
			return false
		return HitReaction.land(trio, 10.0, "prueba", HitReaction.Kind.FLINCH, Vector3.FORWARD, 0.0, at)
	print("ESCUDO: el brazo derecho lleva ", "el escudo" if trio.guard != null else "OTRA COSA", "; el de las piñas: ",
		"ninguno" if trio.melee == null else str(trio.melee.name))
	(trio.keys as ToolMechKeys).cockpit.shield = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	var after_start := energy.level
	var landed: bool = hit.call(front)
	print("  prender gastó ", snappedf(1.0 - after_start, 0.01), "; un golpe de frente enseguida ", "entró" if landed
		else "no entró", " y la energía volvió a ", snappedf(energy.level, 0.01), " (el parry)")
	await get_tree().create_timer(0.6).timeout
	landed = hit.call(front)
	print("  de frente, después: ", "entró" if landed else "no entró", " · ", trio.guard.status())
	landed = hit.call(behind)
	print("  de atrás: ", "entró" if landed else "no entró")
	await get_tree().create_timer(0.5).timeout
	await _shot(trio.global_position + Vector3(7.0, 1.5, -10.5), trio.global_position + Vector3(0.5, 0.0, -1.0), 50.0)
	var trio_seat := (trio.cabin as CageCabin).board_root().global_transform * CageCabin.driver_eye(CageCabin.shape())
	await _shot(trio_seat, trio_seat - trio.global_basis.z, 85.0)
	(trio.keys as ToolMechKeys).cockpit.shield = false
	await get_tree().create_timer(0.6).timeout
	landed = hit.call(front)
	print("  bajado: de frente ", "entró" if landed else "no entró", " · ", trio.guard.status())
	await _shot(trio.global_position + Vector3(7.0, 1.5, -10.5), trio.global_position + Vector3(0.5, 0.0, -1.0), 50.0)
	_save()
	get_tree().quit()


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


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
	var path := "%s/meca_de_1_2_3.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
