extends Node3D

## LA CABINA SOBRE SU GRILLA, PARA MIRAR (unos 10 segundos, sin el sandbox): una meca discreta parada, cortada por el
## costado izquierdo y sin techo, con las líneas de los módulos dibujadas en cada piso (ver CabinGrid); de frente y de
## atrás (la escalera).
## Imprime las medidas que salen de la grilla.
##   tools/godot_ventana.sh res://tests/cabin_grid_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)

var _folder := ""
var _mech: Mech = null
var _eye: Camera3D = null
var _title: Label = null
var _cut: Array[Node3D] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	print("GRILLA: celda %.4f m · módulo %.3f m · caja %.4f m (cubo %s) · piso %.3f m, libre %.3f m · asientos %d" % [
		CabinGrid.CELL, CabinGrid.MODULE, CabinGrid.SIZE, CabinGrid.cube_ok(), CabinGrid.FLOOR_HEIGHT,
		CabinGrid.clear_height(1), CabinGrid.seats().size()])
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
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.POSE
	_mech.position = Vector3(0.0, BodySettings.current.hover_height + Mech.SIZE * 0.5, 0.0)
	add_child(_mech)
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
	await get_tree().create_timer(2.0).timeout
	_mech.freeze = true
	_lines()
	_find_cut()
	_set_cut(true)
	_title.text = "La cabina sobre su grilla: 4 × 4 módulos, 3 pisos"
	_look(Vector3(-30.0, 0.2, 12.0), Vector3(0.3, -0.5, -0.4), 27.0)
	var side := await _grab()
	_title.text = "Desde arriba, sin techo: el piso de arriba y sus módulos"
	_look(Vector3(-0.01, 34.0, 4.0), Vector3(0.0, 0.0, 0.0), 22.0)
	var top := await _grab()
	_set_cut(false)
	_title.text = "De frente: una ventana por módulo"
	_look(Vector3(-9.0, 1.0, -22.0), Vector3(0.0, -0.5, 0.0), 38.0)
	var front := await _grab()
	_title.text = "De atrás: la escalera, con escalones (Stairs)"
	_look(Vector3(-7.0, 0.0, 17.0), Vector3(0.0, -1.0, 4.5), 45.0)
	var back := await _grab()
	_save([side, top, front, back], "cabina_grilla")
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


func _look(from: Vector3, to: Vector3, fov: float) -> void:
	_eye.fov = fov
	_eye.global_position = _mech.global_transform * from
	_eye.look_at(_mech.global_transform * to, Vector3.UP)


func _save(shots: Array, file: String) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var first: Image = shots[0]
	var sheet := Image.create(first.get_width(), first.get_height() * shots.size(), false, first.get_format())
	for index in shots.size():
		var shot: Image = shots[index]
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(0, first.get_height() * index))
	var path := "%s/%s.png" % [_folder, file]
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
