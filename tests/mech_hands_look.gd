extends Node3D

## LAS MANOS DE LA MECA (la física), PARA MIRAR: que una sea el espejo de la otra, con los pulgares hacia donde dobla el codo
## y las palmas hacia el cuerpo (ver MuscleArm, LA MANO), en reposo y cubriéndose.
##   tools/godot_ventana.sh res://tests/mech_hands_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _mech: Mech = null


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
	sun.rotation_degrees = Vector3(-48.0, 200.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.82, 0.84, 0.87)
	world.environment.ambient_light_energy = 0.8
	add_child(world)
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.MUSCLE
	_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_mech)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	await get_tree().create_timer(3.0).timeout
	_mech.label.visible = false
	await _round("En reposo")
	_mech.covering = true
	await get_tree().create_timer(2.5).timeout
	await _round("Cubriéndose")
	get_tree().quit()


## De frente, y cada mano de cerca desde adelante y afuera.
func _round(what: String) -> void:
	var at := _mech.global_position
	_eye.global_position = at + Vector3(0.0, -1.0, -26.0)
	_eye.look_at(at + Vector3(0.0, -3.0, 0.0))
	await _shot("%s, de frente" % what, "%s_frente" % what.to_lower().replace(" ", "_"))
	for index in 2:
		var arm := _mech.arms[index] as MuscleArm
		var hand := arm.forearm.global_transform * Vector3(0, 0, -arm.forearm_length() * 0.5 - 1.0)
		_eye.global_position = hand + Vector3(arm.side * 5.0, 2.0, -7.0)
		_eye.look_at(hand)
		await _shot("%s: la mano %s" % [what, "izquierda" if arm.side < 0.0 else "derecha"],
			"%s_mano_%d" % [what.to_lower().replace(" ", "_"), index])


func _shot(title: String, file_name: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_title.text = title
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
