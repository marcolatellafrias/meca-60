extends Node3D

## LOS PUESTOS DE LA CABINA, SIN EL SANDBOX (ver SeatStation, docs/technical/paneles.md): una meca parada con sus
## puestos de adelante, cada uno en su silla. Sentado en la silla del brazo derecho, por encima del hombro con un
## maniquí sentado, y desde atrás.
##   tools/godot_ventana.sh res://tests/seat_station_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _mech: Mech = null


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
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.POSE
	_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_mech)
	await get_tree().create_timer(3.0).timeout
	_mech.freeze = true
	if _mech.label != null:
		_mech.label.visible = false
	var right := _mech.cabin.chairs[2]
	# Si la cabina todavía no los pone (SquareCabin._stations), los pone el test.
	if _mech.cabin.find_children("*", "SeatStation", true, false).is_empty():
		SeatStation.attach(_mech.cabin)
		await get_tree().process_frame
	print("PUESTOS ", _mech.cabin.find_children("*", "SeatStation", true, false).size())
	var seat := _frame(right)
	# 1. Sentado (un poco detrás y arriba de los ojos, para que entre el puesto entero).
	_look(seat * Vector3(0, right.eye_height + 0.06, 0.18), seat * Vector3(0, 1.0, -0.6))
	await _shot("1. Sentado en el brazo derecho: la repisa de la silla, derecha", "1")
	# Un maniquí en la silla, para ver la silla con el puesto.
	_mech.cabin.dummies[0].intent.seat = right
	await get_tree().create_timer(1.5).timeout
	# 2. Por encima del hombro derecho.
	_look(seat * Vector3(0.6, 1.5, 0.95), seat * Vector3(-0.05, 0.9, -0.45))
	await _shot("2. Por encima del hombro: la silla y los módulos, a la altura de la mano", "2")
	# 3. Desde atrás y arriba.
	var middle := _frame(_mech.cabin.chairs[1])
	_look(middle * Vector3(0, 2.4, 2.2), middle * Vector3(0, 0.9, -0.5))
	await _shot("3. Desde atrás: brazo izquierdo, movimiento y brazo derecho", "3")
	get_tree().quit()


## Dónde está la silla y hacia dónde mira, sin escala.
func _frame(chair: SeatInteractable) -> Transform3D:
	return Transform3D(chair.global_basis.orthonormalized(), chair.global_position)


func _look(from: Vector3, to: Vector3) -> void:
	_eye.global_position = from
	_eye.look_at(to)


func _shot(title: String, file_name: String) -> void:
	_title.text = title
	for i in 6:
		await get_tree().process_frame
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
