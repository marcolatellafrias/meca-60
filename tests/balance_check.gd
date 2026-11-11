extends Node

## LA MECA DE EQUILIBRIO, PROBADA POR CÓDIGO: arma el sandbox, se para frente a la meca de equilibrio y le tira bolas de
## cada fuerza (J, con K y L), de frente y de costado; imprime cuánto se inclinó y si se cayó, espera que se levante, y
## con ventana saca capturas del tambaleo, la caída y el levantarse.
##   headless:     godot --headless --path . res://tests/balance_check.tscn
##   con capturas: tools/godot_ventana.sh res://tests/balance_check.tscn -- --salida=C:/carpeta

var _folder := ""
var _dummy: MechDummy = null
var _parcel: SandboxParcel = null
var _archetype: BalanceTestArchetype = null
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
			_archetype = parcel.archetype as BalanceTestArchetype
	_dummy = _parcel.find_children("*", "MechDummy", true, false)[0] as MechDummy
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await _seconds(1.0)
	# DE FRENTE: cada fuerza, una bola, esperando que se aquiete.
	for level in TestBall.SPEEDS.size():
		await _throw(level, Vector3.FORWARD, "de frente")
	# DE COSTADO: la fuerza del medio.
	await _throw(2, Vector3.RIGHT, "de costado")
	await _throw(3, Vector3.RIGHT, "de costado")
	# DOS SEGUIDAS de frente, de 20 m/s (sola no la tira): ¿se acumula?
	_aim_from(Vector3.FORWARD)
	_archetype.level = 1
	TestBall.throw_from_camera(_parcel, 1)
	await _seconds(0.5)
	TestBall.throw_from_camera(_parcel, 1)
	await _seconds(1.5)
	print("DOS SEGUIDAS de 20 m/s: pico %d %% · caídas %d" % [roundi(_dummy.peak_lean * 100.0), _dummy.falls])
	await _wait_standing()
	get_tree().quit()


## Pone la cámara a 25 m de la meca, del lado `side` (en el espacio de la meca: FORWARD es su frente), mirándola.
func _aim_from(side: Vector3) -> void:
	var at := _dummy.body_position()
	var basis := Basis(Vector3.UP, _dummy.global_rotation.y)
	_eye.global_position = at + basis * (side * 25.0) + Vector3(0, 12.0, 0)
	_eye.look_at(at + Vector3(0, 12.0, 0))


func _throw(level: int, side: Vector3, label: String) -> void:
	_aim_from(side)
	await _frames(2)
	var falls := _dummy.falls
	TestBall.throw_from_camera(_parcel, level)
	var shot := false
	var peak := 0.0
	for i in 150:
		await get_tree().physics_frame
		peak = maxf(peak, _dummy.lean.length())
		if not shot and (_dummy.lean.length() > 0.3 or _dummy.falls > falls) and i > 25:
			shot = true
			await _shot("Bola de %d m/s %s" % [roundi(float(TestBall.SPEEDS[level])), label],
				"golpe_%d_%s" % [level, label.replace(" ", "_")])
	print("BOLA %d m/s %s: golpe medido %.1f m/s · inclinación pico %d %% · se cayó %s" % [
		roundi(float(TestBall.SPEEDS[level])), label, _dummy.last_hit, roundi(peak * 100.0), _dummy.falls > falls])
	if _dummy.falls > falls:
		await _seconds(1.5)
		_aim_from(side + Vector3(0.6, 0, 0))
		await _shot("Caída (%d m/s %s)" % [roundi(float(TestBall.SPEEDS[level])), label],
			"caida_%d_%s" % [level, label.replace(" ", "_")])
		await _wait_standing()
	else:
		await _seconds(1.0)


func _wait_standing() -> void:
	var captured := false
	for i in 600:
		if _dummy.state == MechDummy.State.STANDING:
			if captured:
				print("  se levantó")
			return
		if _dummy.state == MechDummy.State.RISING and not captured:
			captured = true
			await _seconds(1.0)
			await _shot("Levantándose", "levantandose")
		await _frames(1)
	print("  NO se levantó en 10 s (estado %s)" % _dummy.state_name())


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await _frames(3)
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
