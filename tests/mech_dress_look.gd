extends Node3D

## LA FORMA DE LA MECA CON SUS OPCIONES DEL CUERPO (ver CabinShape, CabinGrid.apply, MechBody.dress), sin el sandbox:
## varias combinaciones del piso y el módulo de los hombros, los largos, el ancho y cuánto se estiran las piernas; de
## costado y de frente. Y las sillas por dentro, con sus maniquíes. Unos 40 segundos.
##   tools/godot_ventana.sh res://tests/mech_dress_look.tscn -- --salida=C:/carpeta

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
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 40)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	var shots: Array = []
	for each: Array in _cases():
		var shape: CabinShape = each[1]
		CabinGrid.apply(shape)
		var mech := Mech.new()
		mech.arms_kind = Mech.Arms.POSE
		mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
		add_child(mech)
		await get_tree().create_timer(3.0).timeout
		mech.freeze = true
		if mech.label != null:
			mech.label.visible = false
		var far := maxf(CabinGrid.HEIGHT + MechBody.WAIST, CabinGrid.SIZE) * 1.9
		var middle := (MechBody.WAIST + CabinGrid.HEIGHT) * 0.5
		_title.text = "%s · de costado" % each[0]
		_look(Vector3(-far, middle, -far * 0.15), Vector3(0, middle, 0), 40.0)
		shots.append(await _grab())
		_title.text = "%s · de frente" % each[0]
		_look(Vector3(-far * 0.45, middle, -far * 0.9), Vector3(0, middle, 0), 40.0)
		shots.append(await _grab())
		if each[0].begins_with("1."):
			# Las sillas, por dentro: de costado, con el maniquí sentado, y desde atrás.
			var chair := mech.cabin.chairs[0]
			_title.text = "Las sillas: de costado (ojos a %.2f m)" % CabinGrid.EYE_HEIGHT
			_look_at(chair.global_position + Vector3(-3.0, 1.0, 0.3), chair.global_position + Vector3(0, 0.8, -0.4), 60.0)
			shots.append(await _grab())
			_title.text = "Las sillas: desde atrás"
			_look_at(chair.global_position + Vector3(0.9, 1.9, 2.6), chair.global_position + Vector3(0.0, 0.7, -1.0), 70.0)
			shots.append(await _grab())
		for dummy in find_children("*", "BoneInstantiator", true, false):
			dummy.free()
		mech.free()
	CabinGrid.apply(CabinShape.new())
	_save(shots, "meca_opciones")
	get_tree().quit()


## Las combinaciones: su nombre y su forma.
func _cases() -> Array:
	var all := []
	all.append(["1. la de siempre (hombros del medio)", CabinShape.new()])
	var low := CabinShape.new()
	low.arm_floor = 0
	low.arm_along = 0
	low.leg_length = 2
	low.leg_stretch = 0.82
	all.append(["2. hombros abajo y adelante, piernas largas y estiradas", low])
	var high := CabinShape.new()
	high.arm_floor = 2
	high.arm_along = 2
	high.arm_length = 2
	high.thickness = 2
	all.append(["3. hombros arriba y atrás, brazos largos, ancho grande", high])
	var thin := CabinShape.new()
	thin.thickness = 0
	thin.leg_length = 0
	thin.arm_length = 0
	thin.leg_stretch = 0.5
	all.append(["4. todo chico, piernas muy dobladas", thin])
	var two := CabinShape.new()
	two.modules = 3
	two.floors = 2
	all.append(["5. 3 × 3 y 2 pisos: hombros «del medio»", two])
	return all


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)


func _look_at(from: Vector3, to: Vector3, fov: float) -> void:
	_look(from, to, fov)


## Dos columnas, a la mitad.
func _save(shots: Array, file: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var first: Image = shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(shots.size() / 2.0), false, first.get_format())
	for index in shots.size():
		var shot: Image = shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/%s.png" % [_folder, file]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
