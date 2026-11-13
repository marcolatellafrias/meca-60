extends Node

## LA MECA CINEMÁTICA, PARA MIRARLA (unos 30 segundos, sin el sandbox): la rutina de la K —camina hacia la pila de
## cubos, salta, dash de costado contra una pared, media vuelta, corre y frena— y después un golpe fuerte. Imprime lo
## que más importa: si los cubos de adentro se despegan del piso o se salen, cuánto despide a los de afuera, si la pared
## la frena, y la inclinación y las caídas. Con ventana, capturas numeradas.
##   tools/godot_ventana.sh res://tests/kinematic_mech_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _mech: KinematicMech = null
var _inside: Array[RigidBody3D] = []
var _outside: Array[RigidBody3D] = []
var _eye: Camera3D = null
var _title: Label = null


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
	for i in range(-30, 31):
		Clay.box(ground, Vector3(600, 0.02, 0.2), Vector3(0, 0.0, i * 5.0), Color(0.7, 0.68, 0.64))
	# UNA PARED a la derecha, para el dash.
	Clay.solid(ground, Vector3(2.0, 40.0, 60.0), Vector3(20.0, 20.0, 10.0), Clay.METAL.lightened(0.2))
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
	var holder := Node3D.new()
	add_child(holder)
	var root := KinematicMechArchetype.new().build(0, holder)
	_mech = root.find_children("*", "KinematicMech", true, false)[0] as KinematicMech
	for cube: RigidBody3D in root.find_children("*", "RigidBody3D", true, false):
		if MotionFrame.frame_of(cube) == _mech.frame:
			_inside.append(cube)
		else:
			_outside.append(cube)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await _seconds(1.5)
	_mech.routine()
	var clock := 0.0
	var most_tilt := 0.0
	var lifted := [0.0, 0.0]
	var loose := [0.0, 0.0]
	var left := [0, 0]
	var thrown := 0.0
	var deepest := 0.0
	var shots := {1.0: ["1. camina hacia la pila", "1_camina", Vector3(-30, 14, 10)],
		3.0: ["2. en el aire, con los cubos adentro", "2_salto", Vector3(-28, 6, 22)],
		3.4: ["3. el dash de costado, contra la pared", "3_dash_pared", Vector3(-26, 22, 26)],
		8.0: ["4. la media vuelta rápida", "4_media_vuelta", Vector3(-24, 26, 20)]}
	while clock < 16.0:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		most_tilt = maxf(most_tilt, _mech.tilt)
		var floor_y := (_mech.global_transform * Vector3(0.0, -KinematicMech.SIZE.y * 0.5 + KinematicMech.WALL, 0.0)).y
		for i in _inside.size():
			var cube := _inside[i]
			# 0: los llevados como la gente; 1: el suelto (el último).
			var which := 1 if i == _inside.size() - 1 else 0
			lifted[which] = maxf(lifted[which], cube.global_position.y - KinematicMechArchetype.CUBE * 0.5 - floor_y)
			loose[which] = maxf(loose[which], (cube.linear_velocity - _mech.frame.velocity_at(cube.global_position)).length())
			if not _mech.frame.contains(cube.global_position, 0.5):
				left[which] += 1
		for cube in _outside:
			thrown = maxf(thrown, cube.linear_velocity.length())
		deepest = maxf(deepest, _mech.global_position.x + KinematicMech.SIZE.x * 0.5 - 19.0)
		for at: float in shots.keys():
			if clock >= at and not (shots[at] as Array).is_empty():
				var shot: Array = shots[at]
				shots[at] = []
				_look(shot[2])
				await _shot(shot[0], shot[1])
	print("RUTINA: inclinación más grande %.0f° · caídas %d" % [most_tilt, _mech.falls])
	for which in 2:
		print("ADENTRO, %s: se despegan del piso hasta %.2f m · se mueven contra la caja hasta %.1f m/s · pasos afuera %d" % [
			["los llevados como la gente", "el suelto, que siente la inercia"][which], lifted[which], loose[which],
			left[which]])
	print("AFUERA: la pila sale despedida a %.1f m/s como mucho" % thrown)
	print("PARED: la caja se metió en la pared %.2f m (negativo: no la tocó)" % deepest)
	# UN GOLPE FUERTE.
	var falls := _mech.falls
	most_tilt = 0.0
	_mech.knock(true)
	clock = 0.0
	var shot_down := false
	while clock < 6.0:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
		most_tilt = maxf(most_tilt, _mech.tilt)
		if not shot_down and _mech.state == KinematicMech.State.DOWN and clock > 1.2:
			shot_down = true
			_look(Vector3(-26, 14, 20))
			await _shot("5. golpe fuerte: se cae (escrito) y se levanta", "5_caida")
	print("GOLPE FUERTE: inclinación %.0f° · caídas %d · ahora %s" % [most_tilt, _mech.falls - falls,
		["parada", "tirada", "levantándose"][_mech.state]])
	get_tree().quit()


func _look(offset: Vector3) -> void:
	var at := _mech.global_position + Vector3(0.0, -4.0, 0.0)
	_eye.global_position = at + offset
	_eye.look_at(at)


func _seconds(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
