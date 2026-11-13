extends Node

## EL LABORATORIO CINEMÁTICO, MEDIDO (unos 3 minutos, sin el sandbox). Para cada forma de tratar lo suelto
## (KinematicPillar.Mode) y cada configuración de cajas: el cubo entra caminando, salta y se agacha y se para. Después,
## con la pila, la lluvia de cajas encima mientras se agacha, se para y salta. Con lo que diga el F1 para moverse. Imprime una tabla: lo más rápido que salió
## una caja, cuántas pasaron de 15 m/s, la caja más metida adentro del cubo (m) y cuánto avanzó el cubo.
## Con ventana y --salida, capturas de cada forma contra la pila.
##   tools/godot_ventana.sh res://tests/kinematic_lab_look.tscn -- --salida=C:/carpeta

const FAST := 15.0

var _folder := ""
var _pillar: KinematicPillar = null
var _holder: Node3D = null
var _eye: Camera3D = null
var _title: Label = null
var _fastest := 0.0
var _phase := ""
var _fastest_when := ""
var _too_fast := {}
var _deepest := 0.0


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
	var root := KinematicLabArchetype.new().build(0, parent)
	_pillar = root.get_node("Cubo") as KinematicPillar
	_holder = root.get_node("Cajas") as Node3D
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	print("forma · cajas: la más rápida de costado (m/s, y cuándo) · cajas a más de %.0f m/s no sólo cayendo · la más metida adentro (m) · el cubo avanzó (m)" % FAST)
	for mode in KinematicPillar.Mode.size():
		for which in KinematicLabArchetype.Boxes.size():
			await _walk_in(mode as KinematicPillar.Mode, which as KinematicLabArchetype.Boxes)
	for mode in KinematicPillar.Mode.size():
		await _rain(mode as KinematicPillar.Mode)
	get_tree().quit()


## Lo pone al principio, con las cajas de `which` y la forma `mode`.
func _reset(mode: KinematicPillar.Mode, which: KinematicLabArchetype.Boxes) -> void:
	KinematicLabArchetype.lay_out(_holder, which)
	_pillar.mode = mode
	_pillar.move = Vector2.ZERO
	_pillar.crouch = false
	_pillar.jump = false
	_pillar.velocity = Vector3.ZERO
	_pillar.put(Transform3D(Basis(), _holder.global_transform * KinematicLabArchetype.START))
	await _wait(1.5)
	_fastest = 0.0
	_too_fast.clear()
	_deepest = -100.0


## ENTRA CAMINANDO: camina 4 s hacia las cajas, salta, se agacha y se para.
func _walk_in(mode: KinematicPillar.Mode, which: KinematicLabArchetype.Boxes) -> void:
	await _reset(mode, which)
	var start := _pillar.global_position
	_phase = "corriendo"
	_pillar.move = Vector2(0.0, 1.0)
	await _wait(4.0)
	if which == KinematicLabArchetype.Boxes.PILE:
		_look(Vector3(-24.0, 14.0, 18.0))
		await _shot("%d. %s, contra la pila" % [mode + 1, KinematicPillar.MODE_NAMES[mode]], "%d_pila" % (mode + 1))
	_phase = "saltando"
	_pillar.jump = true
	await _wait(0.1)
	_pillar.jump = false
	await _wait(2.0)
	_phase = "agachándose"
	_pillar.move = Vector2.ZERO
	_pillar.crouch = true
	await _wait(2.0)
	_phase = "parándose"
	_pillar.crouch = false
	await _wait(2.5)
	print("%s · %s: %.1f (%s) · %d · %.2f · %.1f" % [KinematicPillar.MODE_NAMES[mode], KinematicLabArchetype.BOX_NAMES[which],
		_fastest, _fastest_when, _too_fast.size(), maxf(_deepest, 0.0), (_pillar.global_position - start).length()])


## LA LLUVIA con la pila: caen encima; se agacha, se para y salta debajo.
func _rain(mode: KinematicPillar.Mode) -> void:
	await _reset(mode, KinematicLabArchetype.Boxes.PILE)
	for holder_child in _holder.get_children():
		holder_child.queue_free()
	await _wait(0.2)
	_phase = "cayendo encima"
	KinematicLabArchetype.rain(_holder, _pillar, KinematicLabArchetype.Boxes.PILE)
	await _wait(3.0)
	_look(Vector3(-20.0, 10.0, 16.0))
	await _shot("%s: la lluvia encima" % KinematicPillar.MODE_NAMES[mode], "%d_lluvia" % (mode + 1))
	_phase = "agachándose"
	_pillar.crouch = true
	await _wait(2.5)
	_phase = "parándose"
	_pillar.crouch = false
	await _wait(2.5)
	_phase = "saltando"
	_pillar.jump = true
	await _wait(0.1)
	_pillar.jump = false
	await _wait(3.0)
	print("LLUVIA · %s: %.1f (%s) · %d · %.2f · el cubo terminó a %.1f m del piso" % [KinematicPillar.MODE_NAMES[mode],
		_fastest, _fastest_when, _too_fast.size(), maxf(_deepest, 0.0), _pillar.global_position.y])


func _wait(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		for body in _holder.get_children():
			var box := body as RigidBody3D
			if box == null or box.is_queued_for_deletion():
				continue
			# De costado: lo que gana cayendo no cuenta.
			var speed := Vector2(box.linear_velocity.x, box.linear_velocity.z).length()
			if speed > _fastest:
				_fastest = speed
				_fastest_when = _phase
			if box.linear_velocity.length() > FAST and speed > 6.0:
				_too_fast[box] = true
			_deepest = maxf(_deepest, float(_pillar._out_of(box.global_position, 0.0)[1]))


func _look(offset: Vector3) -> void:
	var at := _pillar.global_position + Vector3.UP * 6.0
	_eye.global_position = at + offset
	_eye.look_at(at)


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
