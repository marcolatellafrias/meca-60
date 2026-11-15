extends Node

## LAS MAQUETAS DE JEFES (con ventana, unos 20 s, sin el sandbox): cada una sola, de frente y de tres cuartos desde
## arriba, con sus dos estados (ver BossMaquettes); las recorribles, también de cerca. Capturas numeradas.
##   tools/godot_ventana.sh res://tests/boss_maquettes_look.tscn -- --salida=C:/carpeta

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _shots := 0


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
	Clay.box(self_3d(), Vector3(600, 1, 600), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
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
	world.environment.glow_enabled = true
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
	add_child(_eye)
	_eye.make_current()
	for i in BossMaquettes.ALL.size():
		var holder := Node3D.new()
		self_3d().add_child(holder)
		BossMaquettes.build(i, holder)
		var name_of := str(BossMaquettes.entry(i)["name"])
		print("%s: %s" % [name_of, " / ".join(BossMaquettes.entry(i)["lines"])])
		if str(BossMaquettes.ALL[i]["kind"]) == "armed":
			# Las de personalidad: cada estado de cerca, de tres cuartos de frente.
			for state: float in [-1.0, 1.0]:
				var at := Vector3(BossMaquettes.APART * state, 0, 0)
				await _shot("%s, %s" % [name_of, BossMaquettes.entry(i)["states"][int(state > 0.0)]],
					at + Vector3(38, 30, -52), at + Vector3(0, 16, 0))
			await _shot("%s, de frente" % name_of, Vector3(-BossMaquettes.APART, 18, -48),
				Vector3(-BossMaquettes.APART, 13, 0))
			holder.queue_free()
			await get_tree().process_frame
			continue
		await _shot("%s, de frente" % name_of, Vector3(0, 32, 118), Vector3(0, 22, 0))
		await _shot("%s, desde arriba" % name_of, Vector3(70, 80, 85), Vector3(0, 10, 0))
		if str(BossMaquettes.ALL[i]["kind"]) in ["hexapod", "quadruped"]:
			# De cerca, las compuertas abiertas y el recorrido: la de la derecha de atrás y la de la izquierda de frente.
			var open := Vector3(BossMaquettes.APART, 0, 0)
			await _shot("%s, abierta, de atrás: el recorrido" % name_of, open + Vector3(38, 52, 62), open + Vector3(0, 26, 0))
			await _shot("%s, abierta, de frente" % name_of, open + Vector3(-35, 30, -60), open + Vector3(0, 22, 0))
			var shut := Vector3(-BossMaquettes.APART, 0, 0)
			await _shot("%s, cerrada, de cerca" % name_of, shut + Vector3(40, 40, 40), shut + Vector3(0, 24, 0))
		holder.queue_free()
		await get_tree().process_frame
	get_tree().quit()


var _root: Node3D = null


func self_3d() -> Node3D:
	if _root == null:
		_root = Node3D.new()
		add_child(_root)
	return _root


func _shot(title: String, from: Vector3, at: Vector3) -> void:
	_eye.global_transform = Transform3D(Basis(), from).looking_at(at, Vector3.UP)
	for i in 3:
		await get_tree().process_frame
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	_shots += 1
	_title.text = "%d. %s" % [_shots, title]
	await get_tree().process_frame
	await get_tree().process_frame
	var path := "%s/%02d.png" % [_folder, _shots]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
