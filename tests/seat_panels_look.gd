extends Node3D

## LOS PANELES DE LA SILLA, SIN EL SANDBOX (ver SeatPanels): una meca discreta parada, su silla del brazo derecho con
## su maniquí, y la cámara a los ojos de esa silla. Plegado, mirándolo (se ilumina), abierto con la mira, y la piña.
##   tools/godot_ventana.sh res://tests/seat_panels_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var target := StaticBody3D.new()
	Clay.solid(target, Vector3(4, 8, 4), Vector3(3, 4, -16), Clay.RED)
	add_child(target)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -60.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	add_child(world)
	_eye = Camera3D.new()
	_eye.fov = 75.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 10)
	_title.add_theme_font_size_override("font_size", 28)
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var mech := Mech.new()
	mech.arms_kind = Mech.Arms.POSE
	mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(mech)
	await get_tree().create_timer(3.0).timeout
	mech.freeze = true
	if mech.label != null:
		mech.label.visible = false
	var panels := mech.cabin.find_children("*", "SeatPanels", false, false)[0] as SeatPanels
	var chair := panels.chair
	# La silla del panel queda libre para el jugador: acá se sienta uno de los maniquíes.
	var sitter := mech.cabin.dummies[0]
	sitter.intent.seat = chair
	await get_tree().create_timer(1.5).timeout
	var eye := chair.global_transform * Vector3(0, chair.eye_height, -0.12)
	print("SILLA ", chair.name, " ocupada: ", chair.occupant() != null)
	# 1. Desde atrás y arriba: el panel plegado y la tira.
	_eye.global_position = chair.global_position + chair.global_basis * Vector3(-0.6, 2.0, 1.4)
	_eye.look_at(chair.global_transform * Vector3(0.1, 0.6, -0.6))
	await _shot("1. Desde atrás: el panel plegado a la derecha, la tira adelante y abajo", "1")
	# 2. Sentado, mirando al frente.
	_eye.global_position = eye
	_eye.look_at(eye + chair.global_basis * Vector3(0, -0.12, -1))
	await _shot("2. Sentado, mirando al frente: la tira abajo, el panel plegado a la derecha", "2")
	# 3. Mirando el panel: se ilumina y pide la E.
	_eye.look_at(panels._glass.global_position)
	await _shot("3. Mirándolo: se ilumina, «E: abrir»", "3")
	# 4. Abierto, con la mira corrida hacia el bloque.
	var press := InputEventKey.new()
	press.physical_keycode = KEY_E
	press.pressed = true
	panels.handle(press)
	_eye.look_at(eye + chair.global_basis * Vector3(0, -0.05, -1))
	await get_tree().create_timer(0.4).timeout
	var move := InputEventMouseMotion.new()
	move.relative = Vector2(90, 40)
	panels.handle(move)
	await _shot("4. Abierto (E): viene adelante y toma el mouse; la mira se mueve sola por la vista", "4")
	# 5. La piña hacia la mira.
	panels._punch()
	await get_tree().create_timer(0.45).timeout
	await _shot("5. Clic: la piña del brazo derecho", "5")
	print("APUNTA A ", panels._aim_point())
	# 6. Desde afuera: la piña.
	panels._punch()
	await get_tree().create_timer(0.4).timeout
	_eye.global_position = mech.global_position + Vector3(14, 3, -16)
	_eye.look_at(mech.global_position + Vector3(0, 0, -4))
	await _shot("6. Desde afuera, la misma piña", "6")
	get_tree().quit()


func _shot(title: String, file_name: String) -> void:
	_title.text = title
	for i in 4:
		await get_tree().process_frame
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
