extends Node

## LA MECA DE EQUILIBRIO, PROBADA POR CÓDIGO: arma el sandbox, se para frente a la meca de equilibrio y le tira bolas de
## varias fuerzas (ver TestBall), de frente, en los dos modos (como character-parametric, y con el empuje y los pasos
## prendidos; ver MechDummy); imprime la inclinación más grande, los pasos, cuánto retrocedió y si se cayó. Después, bolas
## a las dos personas de al lado. Con ventana, capturas del trastabillar (una por cuarto de segundo) y de la caída.
##   headless:     godot --headless --path . res://tests/balance_check.tscn
##   con capturas: tools/godot_ventana.sh res://tests/balance_check.tscn -- --salida=C:/carpeta

var _folder := ""
var _dummy: MechDummy = null
var _parcel: SandboxParcel = null
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 14)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var sandbox := (load("res://game/sandbox/sandbox.tscn") as PackedScene).instantiate()
	add_child(sandbox)
	await _frames(5)
	for parcel: SandboxParcel in sandbox.find_children("*", "SandboxParcel", true, false):
		if parcel.archetype is BalanceTestArchetype:
			_parcel = parcel
	_dummy = _parcel.find_children("*", "MechDummy", true, false)[0] as MechDummy
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await _seconds(1.0)
	_report_feet()
	# EL PANEL DE LA FILA (F1 parado en la fila Meca, ver BalancePanel).
	var world := sandbox as DesignSandbox
	world.local_player.place_at(_parcel.global_position + Vector3(-20.0, 0.0, 0.0), PI * 0.5)
	await _seconds(0.5)
	var panel := sandbox.find_children("*", "BalancePanel", true, false)[0] as BalancePanel
	await _key(KEY_F1)
	await _seconds(0.3)
	print("PANEL F1: fila «%s» · abierto %s" % [world.current_category(), panel.visible])
	world.local_player.player_camera.make_current()
	await _shot("F1 en la fila Meca: el panel de la meca de equilibrio", "panel_f1")
	await _key(KEY_F1)
	await _seconds(0.3)
	print("PANEL F1 otra vez: abierto %s" % panel.visible)
	_eye.make_current()
	for pushes: bool in [false, true]:
		MechBalanceSettings.current.hit_pushes = pushes
		MechBalanceSettings.current.steps = pushes
		print("── MODO %s" % ("con empuje y pasos" if pushes else "como character-parametric"))
		for force: int in [6, 7, 8, 9, 10]:
			await _throw(force, pushes and force == 8)
	MechBalanceSettings.current.hit_pushes = true
	MechBalanceSettings.current.steps = true
	# LAS PERSONAS: las fuerzas chicas.
	for person: BoneInstantiator in _parcel.find_children("*", "BoneInstantiator", true, false):
		for force: int in [0, 2]:
			await _throw_at_person(person, force)
	get_tree().quit()


## Los pies, planos: lo que se vio mal el 11/11/2026 (inclinados como la canilla).
func _report_feet() -> void:
	for index: int in [MechDummy.Part.FOOT_LEFT, MechDummy.Part.FOOT_RIGHT]:
		var foot := _dummy._parts[index]
		var up := foot.global_basis * Vector3.UP
		print("PIE %d: inclinado %.1f° · apoyado a %.2f m del piso" % [index, rad_to_deg(up.angle_to(Vector3.UP)),
			foot.global_position.y - MechBody.FOOT_SIZE.y * 0.5])


func _aim() -> void:
	var at := _dummy.body_position()
	var basis := Basis(Vector3.UP, _dummy.global_rotation.y)
	_eye.global_position = at + basis * Vector3(0, 12.0, -25.0)
	_eye.look_at(at + Vector3(0, 10.0, 0))


func _throw(force: int, frames: bool) -> void:
	await _wait_standing()
	await _seconds(1.0)
	_aim()
	await _frames(2)
	var start := _dummy.body_position()
	var falls := _dummy.falls
	var steps := _dummy.steps_taken
	TestBall.throw_from_camera(_parcel, force)
	var peak := 0.0
	var shot := 0
	for i in 480:
		await get_tree().physics_frame
		peak = maxf(peak, _dummy.lean.length())
		if frames and i >= 230 and i % 40 == 30 and shot < 6:
			# Una vista de costado, para que se vea ir para atrás.
			var at := _dummy.body_position()
			_eye.global_position = at + Basis(Vector3.UP, _dummy.global_rotation.y) * Vector3(30.0, 10.0, 0.0)
			_eye.look_at(at + Vector3(0, 9.0, 0))
			await _shot("Fuerza %d: %.2f s después" % [force + 1, i / 240.0], "trastabilla_%d" % shot)
			shot += 1
	print("FUERZA %d (%s N·s): golpe %.1f m/s · inclinación pico %d %% · pasos %d · retrocedió %.1f m · se cayó %s" % [
		force + 1, String.num_int64(roundi(TestBall.push_of(force))), _dummy.last_hit, roundi(peak * 100.0),
		_dummy.steps_taken - steps, start.distance_to(_dummy.body_position()), _dummy.falls > falls])
	if _dummy.falls > falls and frames:
		await _shot("La caída", "caida")


func _throw_at_person(person: BoneInstantiator, force: int) -> void:
	await _seconds(2.0)
	var at := person.char_rigidbody.global_position
	_eye.global_position = at + Vector3(-6.0, 1.2, 0.0)
	_eye.look_at(at + Vector3(0, 1.0, 0))
	await _frames(2)
	TestBall.throw_from_camera(_parcel, force)
	var fell := false
	var peak := 0.0
	for i in 360:
		await get_tree().physics_frame
		peak = maxf(peak, person.char_rigidbody.impact_xz.length())
		if person.ragdoll_util.is_active:
			fell = true
	print("PERSONA %s, fuerza %d (%s N·s): inclinación pico %d %% · se cayó %s" % [person.name, force + 1,
		String.num_int64(roundi(TestBall.push_of(force))), roundi(peak * 100.0), fell])


func _wait_standing() -> void:
	for i in 1200:
		if _dummy.state == MechDummy.State.STANDING:
			return
		await _frames(1)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await _frames(2)
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)


func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await _frames(2)
