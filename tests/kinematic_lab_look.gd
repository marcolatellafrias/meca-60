extends Node

## EL LABORATORIO CINEMÁTICO, MEDIDO (unos 2 minutos, sin el sandbox). Con cada configuración de cajas, el cubo entra
## caminando, salta y se agacha y se para: imprime lo más rápido que salió una caja de costado (las patadas) y cuándo, y
## cuántas acható. Después, la lluvia de cajas encima; y contra lo fijo: camina contra el edificio (no se mete), gira
## media vuelta pegado a él (nada lo traba) y se desliza a lo largo de la pared. Con ventana, capturas numeradas.
##   tools/godot_ventana.sh res://tests/kinematic_lab_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _pillar: KinematicPillar = null
var _holder: Node3D = null
var _eye: Camera3D = null
var _title: Label = null
var _fastest := 0.0
var _phase := ""
var _fastest_when := ""


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
	print("cajas: la más rápida de costado (m/s, y cuándo) · achatadas (de cuántas) · el cubo avanzó (m)")
	for which in KinematicLabArchetype.Boxes.size():
		await _walk_in(which as KinematicLabArchetype.Boxes)
	await _rain()
	await _fixed()
	get_tree().quit()


## Lo pone en `at` mirando a `yaw`, con las cajas de `which`.
func _reset(which: KinematicLabArchetype.Boxes, at: Vector3, yaw: float) -> void:
	KinematicLabArchetype.lay_out(_holder, which)
	_pillar.move = Vector2.ZERO
	_pillar.crouch = false
	_pillar.jump = false
	_pillar.put(Transform3D(Basis(Vector3.UP, yaw), _holder.global_transform * at))
	await _wait(1.5)
	_fastest = 0.0
	_fastest_when = ""


func _flattened() -> int:
	return _pillar.flattened + _pillar.feet.flattened


## ENTRA CAMINANDO: 4 s hacia las cajas, salta, se agacha y se para.
func _walk_in(which: KinematicLabArchetype.Boxes) -> void:
	await _reset(which, KinematicLabArchetype.START, 0.0)
	var start := _pillar._at
	var boxes := _holder.get_child_count()
	var before := _flattened()
	_phase = "caminando"
	_pillar.move = Vector2(0.0, 1.0)
	await _wait(3.2)
	_look(Vector3(-22.0, 6.0, 20.0))
	await _shot("%d. caminando entre %s" % [which + 1, KinematicLabArchetype.BOX_NAMES[which]], "%d_cajas" % (which + 1))
	await _wait(0.8)
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
	print("%s: %.1f (%s) · %d de %d · %.1f" % [KinematicLabArchetype.BOX_NAMES[which], _fastest, _fastest_when,
		_flattened() - before, boxes, (_pillar._at - start).length()])


## LA LLUVIA con las medianas: caen encima; se agacha, se para y salta debajo.
func _rain() -> void:
	await _reset(KinematicLabArchetype.Boxes.PILE, KinematicLabArchetype.START, 0.0)
	for child in _holder.get_children():
		_holder.remove_child(child)
		child.queue_free()
	await _wait(0.2)
	var before := _flattened()
	_phase = "cayendo encima"
	KinematicLabArchetype.rain(_holder, _pillar, KinematicLabArchetype.Boxes.PILE)
	await _wait(3.0)
	_look(Vector3(-20.0, 10.0, 16.0))
	await _shot("5. la lluvia encima", "5_lluvia")
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
	print("LLUVIA: la más rápida de costado %.1f m/s (%s) · achatadas %d de %d" % [_fastest, _fastest_when,
		_flattened() - before, KinematicLabArchetype.RAIN])


## CONTRA LO FIJO: el edificio de la izquierda (su cara está en x = −18) y la pared de la derecha (en x = 23).
func _fixed() -> void:
	await _reset(KinematicLabArchetype.Boxes.SMALL, Vector3(-6.0, 0.0, 6.0), PI * 0.5)
	for child in _holder.get_children():
		_holder.remove_child(child)
		child.queue_free()
	_pillar.move = Vector2(0.0, 1.0)
	await _wait(3.0)
	_pillar.move = Vector2.ZERO
	var gap := _pillar._at.x - (-18.0)
	var yaw := _pillar.global_rotation.y
	# Media vuelta, de a dos cuartos (el pedido de giro no se adelanta más de 108°).
	_pillar.aim_yaw += PI * 0.5
	await _wait(1.5)
	_look(Vector3(14.0, 16.0, 24.0))
	await _shot("6. pegado al edificio: gira sin trabarse", "6_edificio")
	_pillar.aim_yaw += PI * 0.5
	await _wait(2.5)
	var turned := rad_to_deg(absf(angle_difference(yaw, _pillar.global_rotation.y)))
	print("EDIFICIO: el eje del cubo quedó a %.2f m de su cara (el cilindro mide %.1f) · pegado a él giró %.0f° de 180°" % [
		gap, KinematicPillar.RADIUS, turned])
	# De costado y adelante contra la pared de la derecha: se desliza a lo largo.
	_pillar.put(Transform3D(Basis(), Vector3(14.0, 0.0, 16.0)))
	await _wait(1.0)
	var from := _pillar._at
	_pillar.move = Vector2(1.0, 1.0)
	await _wait(3.0)
	_pillar.move = Vector2.ZERO
	print("PARED: yendo en diagonal contra ella avanzó %.1f m a lo largo · su eje quedó a %.2f m de la pared" % [
		absf(_pillar._at.z - from.z), 23.0 - _pillar._at.x])


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


func _look(offset: Vector3) -> void:
	var at := _pillar._at + Vector3.UP * 7.0
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
