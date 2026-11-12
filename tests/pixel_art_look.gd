extends Node3D

## EL FLUJO DE PÍXELES, PARA MIRAR (unos 15 segundos, sin el sandbox; ver docs/pixel-art.md): el cubo de 63 cm armado en
## código y la caja de Blender; cuántas caras recta detecta en cada uno; los pinta con un dibujo que depende de la
## posición en el modelo (una franja que da la vuelta, para ver las costuras), guarda, los vuelve a armar desde el
## archivo, cambia la caja por su versión 2 con la misma pintura (cuánto sobrevivió), abre el panel plano y compara
## tres resoluciones. Guarda en user://, no en el repo. Capturas numeradas.
##   tools/godot_ventana.sh res://tests/pixel_art_look.tscn -- --salida=C:/carpeta

const MODELS := "res://game/pixel_art/models/"
const SAVE := "user://pixel_art_prueba/"

var _folder := ""
var _eye: Camera3D = null
var _shown: Array[Node] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	_world()
	DirAccess.make_dir_recursive_absolute(SAVE)
	for file in DirAccess.get_files_at(SAVE):
		DirAccess.remove_absolute(SAVE + file)
	# 1. Sin pintar: las caras que detecta.
	var models := _build("caja")
	for model in models:
		print("CARAS %s: %d · atlas %d × %d" % [model.paint_name, model.faces.size(), model.atlas_side, model.atlas_side])
		for face in model.faces:
			print("   cara normal %s · %d × %d píxeles · %d triángulos" % [face.normal.snapped(Vector3.ONE * 0.01),
				face.width, face.height, face.colors.size()])
	await _shot("1_sin_pintar")
	# 1b. Las caras detectadas, cada una de un color.
	for model in models:
		for index in model.faces.size():
			var face := model.faces[index]
			var tint := Color.from_hsv(fmod(index * 0.618, 1.0), 0.45, 0.85)
			for y in face.height:
				for x in face.width:
					model.paint(face, x, y, tint)
		model.refresh()
	await _shot("2_caras_detectadas")
	for model in models:
		model.painted.clear()
	# 3. Pintadas con el dibujo y guardadas.
	for model in models:
		_pattern(model)
		model.save()
	_clear()
	models = _build("caja")
	await _shot("3_pintadas_y_releidas")
	for model in models:
		print("RELEÍDO %s: %s de lo guardado encontró lugar" % [model.paint_name, model.matched()])
	_eye.global_position = Vector3(1.05, 1.15, 0.75)
	_eye.look_at(Vector3(0.6, 0.35, 0.3))
	await _shot("4_costuras_de_cerca")
	# 5. La versión 2 de la caja, con la misma pintura.
	_clear()
	models = _build("caja_v2")
	_view()
	print("VERSIÓN 2: %s de lo guardado encontró lugar" % [models[1].matched()])
	await _shot("5_version_2_misma_pintura")
	# 6. El panel plano, con la cara del frente de la caja.
	var panel := PixelPaintPanel.new()
	add_child(panel)
	panel.side = TunerPanel.SIDE_LEFT
	panel.setup_panel()
	UIState.open_only("pixeles")
	var front: PixelFace = null
	for face in models[1].faces:
		if face.normal.z > 0.9 and (front == null or face.width * face.height > front.width * front.height):
			front = face
	panel.select(models[1], front)
	await _shot("6_panel_plano")
	UIState.close("pixeles")
	panel.queue_free()
	# 7. Tres resoluciones: 8, 16 y 32 píxeles por cubo.
	_clear()
	for index in 3:
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * PixelModel.CELL
		var model := PixelModel.new()
		model.pixels_per_cell = [8, 16, 32][index]
		model.folder = SAVE
		model.from_mesh(cube, SupplyLook.CRATE, "resolucion_%d" % model.pixels_per_cell)
		model.position = Vector3((index - 1) * 0.9, PixelModel.CELL * 0.5, 0.0)
		_pattern(model)
		add_child(model)
		_shown.append(model)
	_eye.global_position = Vector3(0.9, 1.3, 2.4)
	_eye.look_at(Vector3(0.0, 0.3, 0.0))
	await _shot("7_resoluciones_8_16_32")
	get_tree().quit()


func _build(box_file: String) -> Array[PixelModel]:
	var cube := BoxMesh.new()
	cube.size = Vector3.ONE * PixelModel.CELL
	var plain := PixelModel.new()
	plain.folder = SAVE
	plain.from_mesh(cube, SupplyLook.CRATE, "cubo")
	plain.position = Vector3(-0.5, PixelModel.CELL * 0.5, 0.0)
	var box := PixelModel.new()
	box.folder = SAVE
	box.from_scene(load(MODELS + box_file + ".glb") as PackedScene, "caja")
	box.position = Vector3(0.5, 0.0, 0.0)
	for model: PixelModel in [plain, box]:
		add_child(model)
		_shown.append(model)
	return [plain, box]


func _clear() -> void:
	for node in _shown:
		node.queue_free()
	_shown.clear()


## UN DIBUJO DE CAJA DE MUNICIÓN que depende sólo de la posición en el modelo: el borde de cada cara más oscuro, una
## franja ocre que da la vuelta a la altura del medio (si las costuras andan, sigue de una cara a la otra), una etiqueta
## crema con tres rayas en el frente y unos remaches en las esquinas.
func _pattern(model: PixelModel) -> void:
	var px := model.pixel
	var low := INF
	var high := -INF
	for face in model.faces:
		for point in face.triangles:
			low = minf(low, point.y)
			high = maxf(high, point.y)
	var middle := lerpf(low, high, 0.45)
	for face in model.faces:
		var side := absf(face.normal.y) < 0.5
		for y in face.height:
			for x in face.width:
				if not face.inside(x, y):
					continue
				var at := face.centre(x, y, px)
				var base := face.base[y * face.width + x]
				var color := base.lightened(0.06) if (x + y) % 5 == 0 else base
				if side and absf(at.y - middle) < px * 1.5:
					color = SupplyLook.MUSTARD
				if face.normal.z > 0.9 and face.width >= 10 and absf(at.y - middle) > px * 2.0:
					var u := float(x) / face.width
					var v := float(y) / face.height
					if u > 0.2 and u < 0.8 and v > 0.12 and v < 0.38:
						color = SupplyLook.CREAM
						if y % 2 == 0 and u > 0.27 and u < 0.73 and v > 0.18 and v < 0.33:
							color = SupplyLook.SOOT
				var edge := not face.inside(x - 1, y) or not face.inside(x + 1, y) or not face.inside(x, y - 1) \
					or not face.inside(x, y + 1)
				if edge:
					color = color.darkened(0.3)
				if (x == 1 or x == face.width - 2) and (y == 1 or y == face.height - 2) and face.width >= 8:
					color = SupplyLook.LEAD
				model.paint(face, x, y, color)
	model.refresh()


func _world() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(40, 1, 40), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -35.0, 0.0)
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
	_eye = Camera3D.new()
	_eye.fov = 40.0
	add_child(_eye)
	_eye.make_current()
	_view()


func _view() -> void:
	_eye.global_position = Vector3(1.3, 1.5, 2.6)
	_eye.look_at(Vector3(0.0, 0.3, 0.0))


func _shot(file: String) -> void:
	for frame in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if not _folder.is_empty() and DisplayServer.get_name() != "headless":
		get_viewport().get_texture().get_image().save_png(_folder + "/" + file + ".png")
		print("CAPTURA ", _folder + "/" + file + ".png")
