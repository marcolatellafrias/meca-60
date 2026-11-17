extends Node

## LA MECA DE TRES, PARA MIRARLA (unos 25 segundos, sin el sandbox): la parcela de la Meca de tres (ToolMechArchetype)
## en un piso fijo, manejada por código: el cañón tira en sus cuatro modos (simple y súper a la de práctica, ráfaga y
## barrido a las cajas) y el taladro carga y le pega a la de práctica. Imprime la energía, cuánto se corrió la de
## práctica y cuántas cajas se movieron. Con ventana, una hoja de capturas.
##   tools/godot_ventana.sh res://tests/tool_mech_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)

var _folder := ""
var _mech: ToolMech = null
var _target: Mech = null
var _crates: Array[RigidBody3D] = []
var _eye: Camera3D = null
var _title: Label = null
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
	world.environment.ambient_light_energy = 0.6
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	var holder := Node3D.new()
	add_child(holder)
	ToolMechArchetype.new().build(0, holder)
	for found in holder.find_children("*", "Mech", true, false):
		if found is ToolMech:
			_mech = found
		else:
			_target = found
	for child in holder.get_child(0).get_children():
		if child is RigidBody3D and not child is Mech:
			_crates.append(child)
	# La maneja este test, no sus teclas.
	_mech.scripted = true
	await _seconds(3.0)
	var crate_rest: Array[Vector3] = []
	for crate in _crates:
		crate_rest.append(crate.global_position)
	var target_rest := _target.global_position
	_view_side()
	await _shot("1. la meca de tres")
	# EL CAÑÓN, SIMPLE: tres tiros a la de práctica, adelante.
	var cannon := _mech.cannon
	cannon.mode = CannonTip.Mode.SIMPLE
	cannon.lever = Vector2(6.0, -6.0)
	await _seconds(1.0)
	for i in 3:
		cannon.trigger = true
		await _seconds(0.05)
		if i == 1:
			await _shot("2. cañón simple")
		cannon.trigger = false
		await _seconds(0.4)
	print("SIMPLE: energía %.2f · la de práctica se corrió %.2f m" % [_mech.energy.level, _target.global_position.distance_to(target_rest)])
	# RÁFAGA a las cajas (a la derecha).
	cannon.mode = CannonTip.Mode.BURST
	cannon.lever = Vector2(25.0, -15.0)
	await _seconds(1.2)
	cannon.trigger = true
	await _seconds(0.6)
	await _shot("3. ráfaga a las cajas")
	await _seconds(0.6)
	cannon.trigger = false
	print("RÁFAGA: energía %.2f · cajas movidas %d" % [_mech.energy.level, _moved(crate_rest)])
	await _seconds(2.0)
	# BARRIDO: el rayo, barriendo de las cajas hacia adelante.
	cannon.mode = CannonTip.Mode.BEAM
	cannon.trigger = true
	for i in 30:
		cannon.lever.x -= 1.0
		await _seconds(0.04)
		if i == 12:
			await _shot("4. barrido")
	cannon.trigger = false
	print("BARRIDO: energía %.2f · cajas movidas %d" % [_mech.energy.level, _moved(crate_rest)])
	await _seconds(3.0)
	# SÚPER: carga a fondo y tira a la de práctica.
	target_rest = _target.global_position
	cannon.mode = CannonTip.Mode.SUPER
	cannon.lever = Vector2(6.0, -6.0)
	await _seconds(1.0)
	cannon.trigger = true
	await _seconds(1.0)
	await _shot("5. súper, cargando")
	await _seconds(0.3)
	var charged := cannon.charge
	cannon.trigger = false
	await _seconds(0.12)
	await _shot("6. súper, el retroceso")
	await _seconds(1.0)
	print("SÚPER: cargado %.2f · energía %.2f · la de práctica se corrió %.2f m" % [charged, _mech.energy.level,
		_target.global_position.distance_to(target_rest)])
	await _seconds(3.0)
	# EL TALADRO: carga y le pega a la de práctica (se acerca primero).
	_mech.mover.put(Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(_target.global_position.x + 11.0, 0.0, 0.0)))
	await _seconds(1.0)
	target_rest = _target.global_position
	var drill := _mech.drill
	drill.charging = true
	await _seconds(1.5)
	var spun := drill.spin
	await _shot("7. taladro cargado")
	drill.charging = false
	var struck := drill.strike()
	await _seconds(0.35)
	await _shot("8. taladro, el golpe")
	await _seconds(1.5)
	print("TALADRO: giraba %.2f · pegó %s · la de práctica se corrió %.2f m · energía %.2f · aturdida %s" % [spun, struck,
		_target.global_position.distance_to(target_rest), _mech.energy.level, not _mech.energy.able()])
	_save()
	get_tree().quit()


func _moved(rest: Array[Vector3]) -> int:
	var count := 0
	for index in _crates.size():
		if _crates[index].global_position.distance_to(rest[index]) > 0.3:
			count += 1
	return count


## La cámara: atrás de la meca, arriba y a su izquierda, mirando hacia la de práctica y las cajas.
func _view_side() -> void:
	var at := _mech.global_position
	_eye.fov = 60.0
	_eye.global_position = at + Vector3(22.0, 10.0, 22.0)
	_eye.look_at(at + Vector3(-18.0, -2.0, -6.0), Vector3.UP)


func _shot(name_of: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_view_side()
	_title.text = name_of
	await RenderingServer.frame_post_draw
	_shots.append(get_viewport().get_texture().get_image())


func _save() -> void:
	if _shots.is_empty():
		return
	var first: Image = _shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(_shots.size() / 2.0), false, first.get_format())
	for index in _shots.size():
		var shot: Image = _shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/meca_de_tres.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)


func _seconds(time: float) -> void:
	await get_tree().create_timer(time, true, true).timeout
