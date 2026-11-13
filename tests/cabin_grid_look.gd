extends Node3D

## LA CABINA SOBRE SU GRILLA, PARA MIRAR (unos 10 segundos por forma, sin el sandbox): por cada forma, una meca
## discreta parada de frente, cortada por el costado izquierdo y sin techo, desde un asiento y mirando abajo desde el
## vidrio (ver CabinGrid).
## Imprime las medidas que salen de la grilla.
##   tools/godot_ventana.sh res://tests/cabin_grid_look.tscn -- --salida=C:/carpeta --formas=4x3x68x12,2x2x68x12

const VIEW := Vector2i(1280, 720)

var _folder := ""
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null
var _cut: Array[Node3D] = []
## Las formas que mira (módulos por lado, pisos, alto de piso y vidrio en celdas): `--formas=4x3x68x12,2x2x68x12`; sin eso, la guardada.
var _shapes: Array[Vector4i] = [Vector4i(CabinGrid.COLUMNS, CabinGrid.FLOORS, CabinGrid.FLOOR_CELLS, CabinGrid.GLASS_OUT_CELLS)]


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--formas="):
			_shapes.clear()
			for each in argument.trim_prefix("--formas=").split(","):
				var parts := each.split("x")
				_shapes.append(Vector4i(int(parts[0]), int(parts[1]), int(parts[2]), int(parts[3])))
	get_window().size = VIEW
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
	world.environment.ambient_light_energy = 1.0
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 2000.0
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
	for shape: Vector4i in _shapes:
		CabinGrid.shape(shape.x, shape.y, shape.z, shape.w)
		var name_of := "%d × %d módulos, %d pisos de %d celdas" % [shape.x, shape.x, shape.y, shape.z]
		print("GRILLA %s: caja %.2f m de lado, %.2f m de alto · piso %.2f m, libre %.2f m · asientos %d · ascensor %.2f m" % [
			name_of, CabinGrid.SIZE, CabinGrid.HEIGHT, CabinGrid.FLOOR_HEIGHT, CabinGrid.clear_height(0),
			CabinGrid.seats().size(), PelvisLift.hole()])
		_mech = Mech.new()
		_mech.arms_kind = Mech.Arms.POSE
		_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
		add_child(_mech)
		await get_tree().create_timer(2.5).timeout
		_mech.freeze = true
		_cut.clear()
		_find_cut()
		var k := maxf(CabinGrid.SIZE, CabinGrid.HEIGHT) / 8.0
		_title.text = name_of
		_look(Vector3(-11.0, 1.5, -15.0) * k + Vector3(0, 0, -4), Vector3(0.0, -0.5 * k, 0.0), 42.0)
		shots.append(await _grab())
		_set_cut(true)
		_title.text = "De costado, cortada"
		_look(Vector3(-30.0, 0.2, 12.0) * k, Vector3(0.3, -0.5, -0.4) * k, 27.0)
		shots.append(await _grab())
		_set_cut(false)
		_dummies(false)
		_title.text = "Desde el asiento de la izquierda"
		var chair := MechCabin.seat()
		_look_cabin(chair + Vector3(0.0, 1.15, -0.1), chair + Vector3(0.0, 0.3, -3.0), 80.0)
		shots.append(await _grab())
		_title.text = "Mirando abajo, desde el vidrio"
		var edge := Vector3(chair.x, CabinGrid.ground(0) + 1.5, -CabinGrid.HALF + 0.2)
		_look_cabin(edge, edge + Vector3(0.0, -1.6, -1.2), 80.0)
		shots.append(await _grab())
		for dummy in find_children("*", "BoneInstantiator", true, false):
			dummy.free()
		_mech.free()
	_save(shots, "cabina_grilla")
	get_tree().quit()


## Las líneas de los módulos, finas, sobre cada piso.
func _lines() -> void:
	var color := Color(0.15, 0.4, 0.85)
	for index in CabinGrid.FLOORS:
		var y := CabinGrid.ground(index) + 0.01
		for line in CabinGrid.COLUMNS + 1:
			var x := CabinGrid.column_x(line)
			Clay.box(_mech.cabin, Vector3(0.03, 0.01, CabinGrid.INNER * 2.0), Vector3(x, y, 0), color)
		for line in CabinGrid.ROWS + 1:
			var z := CabinGrid.row_z(line)
			Clay.box(_mech.cabin, Vector3(CabinGrid.INNER * 2.0, 0.01, 0.03), Vector3(0, y, z), color)


## Lo que tapa: la pared izquierda de cada piso, el techo, las toberas de esas caras y el brazo izquierdo.
func _find_cut() -> void:
	var edge := CabinGrid.HALF - 0.5
	for part in _mech.cabin.get_children():
		var mesh := part as MeshInstance3D
		if mesh != null and (mesh.position.x < -edge or mesh.position.y > edge):
			_cut.append(mesh)
	for part in _mech.look.get_children():
		var mount := part as Node3D
		if mount != null and mount.get_class() == "Node3D" and (mount.position.x < -3.0 or mount.position.y > 3.0):
			_cut.append(mount)
	if not _mech.arms.is_empty():
		_cut.append(_mech.arms[0])
	if _mech.label != null:
		_mech.label.visible = false


func _set_cut(on: bool) -> void:
	for part in _cut:
		part.visible = not on


func _dummies(on: bool) -> void:
	for dummy in find_children("*", "BoneInstantiator", true, false):
		(dummy as Node3D).visible = on


## Como `_look`, en el espacio de la cabina.
func _look_cabin(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _mech.cabin.global_transform * from
	_eye.look_at(_mech.cabin.global_transform * to, Vector3.UP)


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _mech.global_transform * from
	_eye.look_at(_mech.global_transform * to, Vector3.UP)


## Dos columnas, a la mitad: cada forma, dos filas.
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
