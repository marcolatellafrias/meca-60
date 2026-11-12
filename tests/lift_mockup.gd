extends Node3D

## LAS MAQUETAS DEL ASCENSOR DE LA PELVIS, NUMERADAS (ver MechLiftMockup): por variante, una meca con el ascensor bajado
## (de afuera) y otra con el ascensor subido (desde adentro del piso de abajo: el recorte, su baranda y la jaula).
##   tools/godot_ventana.sh res://tests/lift_mockup.tscn -- --salida=C:/carpeta

const GAP := 34.0

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
	world.environment.ambient_light_color = Color(0.85, 0.87, 0.9)
	world.environment.ambient_light_energy = 0.9
	add_child(world)
	var mechs: Array = []
	for variant in MechLiftMockup.NAMES.size():
		var pair: Array[PendulumMech] = []
		for raised: bool in [false, true]:
			var mech := PendulumMech.new()
			mech.floor_cutout = MechLiftMockup.HOLE
			mech.position = Vector3(variant * GAP, PendulumMechSettings.tuned.hover_height + HoverCube.SIZE * 0.5,
				-60.0 if raised else 0.0)
			add_child(mech)
			MechLiftMockup.build(mech._look, variant, raised)
			pair.append(mech)
		mechs.append(pair)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await get_tree().create_timer(1.5).timeout
	for pair: Array in mechs:
		for mech: PendulumMech in pair:
			mech._label.visible = false
			mech._pelvis.visible = false
	var floor_at := PendulumMech.floor_y(0) + PendulumMech.SLAB * 0.5
	for variant in mechs.size():
		var title := "%d · %s" % [variant + 1, MechLiftMockup.NAMES[variant]]
		var low := (mechs[variant][0] as PendulumMech).global_position
		_eye.fov = 50.0
		_eye.global_position = low + Vector3(11.0, -8.6, 13.0)
		_eye.look_at(low + Vector3(0.0, -6.2, 0.0))
		await _shot(title + " — bajado", "%d_bajado" % (variant + 1))
		var high := (mechs[variant][1] as PendulumMech).global_position
		_eye.fov = 78.0
		_eye.global_position = high + Vector3(3.1, floor_at + 2.25, -3.0)
		_eye.look_at(high + Vector3(-0.3, floor_at + 0.5, 1.2))
		await _shot(title + " — subido, desde adentro (la puerta, al fondo)", "%d_subido" % (variant + 1))
	# De afuera, subido: la pelvis redonda y las caderas.
	var one := (mechs[0][1] as PendulumMech).global_position
	_eye.fov = 50.0
	_eye.global_position = one + Vector3(13.0, -7.0, 15.0)
	_eye.look_at(one + Vector3(0.0, -5.2, 0.0))
	await _shot("La pelvis redonda, con el ascensor subido", "5_pelvis")
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
