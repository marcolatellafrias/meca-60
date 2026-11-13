extends Node3D

## LAS LLAMAS DE TOBERA PARA ELEGIR (ThrusterFlame.Style), sin el sandbox: por cada una, una tobera como las de la meca
## (la rótula y la campana) echando para abajo con su humo, con todo y a medias. Unos 25 segundos.
##   tools/godot_ventana.sh res://tests/thruster_flame_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(200, 1, 200), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -60.0, 0.0)
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	add_child(world)
	_eye = Camera3D.new()
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 44)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)
	var shots: Array = []
	for style in ThrusterFlame.NAMES.size():
		var nozzle := _nozzle(style)
		for throttle: float in [1.0, 0.5]:
			(nozzle["flame"] as ThrusterFlame).throttle = throttle
			await get_tree().create_timer(1.6).timeout
			_title.text = "%d. %s · %s" % [style + 1, ThrusterFlame.NAMES[style], "con todo" if throttle > 0.9 else "a medias"]
			if throttle > 0.9:
				_eye.global_position = Vector3(5.0, 4.2, 0.3)
				_eye.look_at(Vector3(0, 3.6, 0))
			else:
				_eye.global_position = Vector3(3.2, 2.2, 3.2)
				_eye.look_at(Vector3(0, 4.5, 0))
			shots.append(await _grab())
		(nozzle["root"] as Node3D).free()
	_save(shots, "llamas")
	get_tree().quit()


## Una tobera como las de la meca (ver BodyNozzles._build_shown), colgada a 6,5 m, echando para abajo, con su humo.
func _nozzle(style: int) -> Dictionary:
	var root := Node3D.new()
	root.position = Vector3(0, 6.5, 0)
	add_child(root)
	Clay.box(root, Vector3(1.7, 0.3, 1.7), Vector3(0, -0.15, 0), Color(0.3, 0.31, 0.34))
	var ball := Node3D.new()
	ball.position = Vector3(0, -0.55, 0)
	root.add_child(ball)
	ball.basis = Basis.looking_at(Vector3.DOWN, Vector3.FORWARD)
	Clay.sphere(ball, 0.55, Vector3.ZERO, Color(0.3, 0.31, 0.34))
	var bell := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.72
	cone.bottom_radius = 0.5
	cone.height = 0.7
	bell.mesh = cone
	bell.material_override = Clay.material(Clay.DARK)
	bell.rotation_degrees = Vector3(-90, 0, 0)
	bell.position = Vector3(0, 0, -0.55)
	ball.add_child(bell)
	var flame := ThrusterFlame.new()
	flame.shape = style
	flame.position = Vector3(0, 0, -0.9)
	ball.add_child(flame)
	var smoke := ParticleSystems.thruster_smoke(ParticleMeshes.Kind.SPHERE, BodyNozzles.SMOKE_SIZE)
	smoke.position = Vector3(0, 0, -0.9 - ThrusterFlame.LENGTH)
	ball.add_child(smoke)
	smoke.emitting = not OS.get_cmdline_user_args().has("--sin-humo")
	return {"root": root, "flame": flame}


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
