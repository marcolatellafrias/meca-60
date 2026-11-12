extends Node3D

## LAS MAQUETAS DEL AFUERA DE LA MECA PÉNDULO, NUMERADAS (ver MechExteriorMockup): una meca por variante, en fila; de cada
## una, una captura de atrás y de costado, y una de todas juntas; y la del ascensor con la meca agachada. Para elegir.
##   tools/godot_ventana.sh res://tests/exterior_mockup.tscn -- --salida=C:/carpeta

const GAP := 30.0

var _folder := ""
var _mechs: Array[PendulumMech] = []
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
	_title.add_theme_font_size_override("font_size", 30)
	_title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0))
	Clay.box(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, 35.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	var count := MechExteriorMockup.NAMES.size()
	for variant in count:
		var mech := PendulumMech.new()
		mech.position = Vector3(variant * GAP, PendulumMechSettings.tuned.hover_height + HoverCube.SIZE * 0.5, 0.0)
		add_child(mech)
		MechExteriorMockup.build(mech._look, variant)
		var number := Label3D.new()
		number.text = str(variant + 1)
		number.font_size = 420
		number.pixel_size = 0.02
		number.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		number.outline_size = 40
		number.modulate = Color(1.0, 0.9, 0.3)
		number.position = Vector3(variant * GAP, 22.0, 0.0)
		add_child(number)
		_mechs.append(mech)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await get_tree().create_timer(1.5).timeout
	for mech in _mechs:
		mech._label.visible = false
	var middle := Vector3((count - 1) * GAP * 0.5, 9.0, 0.0)
	_eye.fov = 38.0
	_eye.global_position = middle + Vector3(0.0, 22.0, 150.0)
	_eye.look_at(middle)
	await _shot("Todas, de atrás", "0_todas")
	_eye.fov = 50.0
	for variant in count:
		var at := _mechs[variant].global_position
		var title := "%d · %s" % [variant + 1, MechExteriorMockup.NAMES[variant]]
		_eye.global_position = at + Vector3(15.0, 4.0, 22.0)
		_eye.look_at(at + Vector3(0.0, -2.5, 1.0))
		await _shot(title + " (de atrás)", "%d_atras" % (variant + 1))
		_eye.global_position = at + Vector3(27.0, 1.0, 5.0)
		_eye.look_at(at + Vector3(0.0, -2.5, 1.5))
		await _shot(title + " (de costado)", "%d_costado" % (variant + 1))
	# EL ASCENSOR: parada queda lejos del piso; agachada, a un salto.
	var mech := _mechs[1]
	var below := mech.global_position + Vector3(2.2, 0.0, 0.0)
	below.y = 0.0
	var scale := Node3D.new()
	scale.position = below
	add_child(scale)
	MechExteriorMockup._person(scale, Vector3.ZERO)
	_eye.global_position = mech.global_position + Vector3(8.0, -8.5, 17.0)
	_eye.look_at(Vector3(mech.global_position.x, 3.2, 0.0))
	await _shot("El ascensor, parada: su piso queda a %.1f m del suelo" % _lift_gap(mech), "6_ascensor_parada")
	mech.driving = true
	var press := InputEventKey.new()
	press.physical_keycode = KEY_CTRL
	press.keycode = KEY_CTRL
	press.pressed = true
	Input.parse_input_event(press)
	await get_tree().create_timer(1.6).timeout
	await _shot("El ascensor, agachada: su piso queda a %.1f m del suelo" % _lift_gap(mech), "7_ascensor_agachada")
	print("ASCENSOR: agachada, su piso a %.2f m del suelo" % _lift_gap(mech))
	get_tree().quit()


func _lift_gap(mech: PendulumMech) -> float:
	return (mech.global_transform * Vector3(0.0, MechExteriorMockup.LIFT_FLOOR, 0.0)).y


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
