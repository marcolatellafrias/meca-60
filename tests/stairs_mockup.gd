extends Node3D

## LAS ESCALERAS DE ATRÁS DE LA MECA PÉNDULO, NUMERADAS, PARA ELEGIR (ver MechExterior.NAMES): una meca por variante, con
## la altura libre medida de cada una en el título. De cada una, una captura de atrás y una de costado.
##   tools/godot_ventana.sh res://tests/stairs_mockup.tscn -- --salida=C:/carpeta

const GAP := 32.0

var _folder := ""
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
	var chosen := MechExterior.variant
	var mechs: Array[PendulumMech] = []
	var free: Array[float] = []
	for which in MechExterior.NAMES.size():
		MechExterior.variant = which
		var mech := PendulumMech.new()
		mech.position = Vector3(which * GAP, PendulumMechSettings.tuned.hover_height + HoverCube.SIZE * 0.5, 0.0)
		add_child(mech)
		mechs.append(mech)
		# Una persona de 1,8 m en la pasarela de atrás, para la escala.
		Clay.box(mech, Vector3(0.5, 1.8, 0.3), Vector3(-4.3, MechExterior._floor_y(0) + 0.9, MechExterior.HALF + 0.55), Color(0.95, 0.5, 0.1))
		free.append(MechExterior.headroom(MechExterior.surfaces(which)))
		print("ESCALERA %d · %s: altura libre %.2f m (hacen falta %.2f)" % [which + 1, MechExterior.NAMES[which], free[which],
			MechExterior.CLEAR])
	MechExterior.variant = chosen
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await get_tree().create_timer(1.5).timeout
	for mech in mechs:
		mech._label.visible = false
	for which in mechs.size():
		var at := mechs[which].global_position
		for other in mechs.size():
			mechs[other].visible = other == which
		var title := "%d · %s · altura libre %.1f m" % [which + 1, MechExterior.NAMES[which], free[which]]
		_eye.global_position = at + Vector3(2.5, 1.5, 17.0)
		_eye.look_at(at + Vector3(0.0, -0.5, 4.0))
		await _shot(title, "%d_atras" % (which + 1))
		_eye.global_position = at + Vector3(12.0, 3.5, 14.5)
		_eye.look_at(at + Vector3(0.0, -0.5, 4.5))
		await _shot(title, "%d_tres_cuartos" % (which + 1))
	get_tree().quit()


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
