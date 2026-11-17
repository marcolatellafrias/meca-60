extends Node3D

## LA POSE DEL QUE MANEJA CON CADA ARQUETIPO (16/11/2026, el usuario: «me gusta la 2, pero no hace falta que la cabeza
## esté tan adelantada… centrada sólo verticalmente, no en profundidad… ¿esto funciona con todos los arquetipos?… ¿puedo
## achicar más la esfera?»). Los seis arquetipos con sus medidas (tests/archetype_bones_measure), cada uno en la misma
## esfera y con la misma pose: los ojos a la altura del centro, `HEAD_BACK` delante de la pared de atrás; el tronco
## recostado `RECLINE`; la cadera en su cuna y la cabeza en su apoyacabezas; las piernas como en gravedad cero.
## La silla se acomoda a cada uno (como hoy SeatInteractable): los ojos siempre en el mismo punto.
##   tools/godot_ventana.sh res://tests/driver_fit_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const RADIUS := 1.0
## De la pared de atrás a los ojos (m).
const HEAD_BACK := 0.35
const RECLINE := 25.0
const THIGH_UP := 30.0
const KNEE := 40.0
## Ojos sobre la pelvis, muslo, canilla, del tobillo a la suela, pie y grosor de la espalda (m).
const KINDS := [
	["gordo", 0.87, 0.43, 0.43, 0.12, 0.29, 0.17],
	["nene", 0.71, 0.37, 0.37, 0.07, 0.23, 0.11],
	["flaco largo", 0.82, 0.5, 0.5, 0.1, 0.28, 0.12],
	["musculoso", 0.76, 0.45, 0.45, 0.1, 0.28, 0.14],
	["viejo", 0.68, 0.4, 0.4, 0.07, 0.26, 0.12],
	["gordo atlético", 0.88, 0.45, 0.45, 0.1, 0.3, 0.15],
]
const BODY := Color(0.85, 0.55, 0.35)
const PAD := Color(0.35, 0.3, 0.28)
const SHELL := Color(0.6, 0.61, 0.63)
const GLASS := Color(0.62, 0.8, 0.92, 0.3)
const DARK := Color(0.3, 0.31, 0.34)
const RED := Color(0.78, 0.18, 0.15)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	for index in KINDS.size():
		var root := Node3D.new()
		root.position = Vector3(0.0, 0.0, index * 40.0)
		add_child(root)
		_sphere(root)
		_figure(root, KINDS[index])
	var shots: Array[Image] = []
	for index in KINDS.size():
		var at := Vector3(0.0, 0.0, index * 40.0)
		_title.text = "%s · esfera de %.2f m" % [KINDS[index][0], RADIUS]
		_eye.near = 10.0 - 0.35
		shots.append(await _view(at + Vector3(10.0, 0.0, 0.0), at + Vector3(0.0, -0.1, 0.0), 2.5))
	_save(shots)
	get_tree().quit()


## UN ARQUETIPO EN LA POSE, en el plano del medio (adelante, arriba), con el centro de la esfera en el origen.
func _figure(root: Node3D, kind: Array) -> void:
	var eye_above: float = kind[1]
	var thigh: float = kind[2]
	var shin: float = kind[3] + kind[4]
	var foot: float = kind[5]
	var thick: float = kind[6]
	var eye := Vector2(-RADIUS + HEAD_BACK, 0.0)
	var lean := deg_to_rad(RECLINE)
	var pelvis := eye + Vector2(sin(lean), -cos(lean)) * eye_above
	var down := (pelvis - eye).normalized()
	var back := Vector2(down.y, -down.x)
	if back.x > 0.0:
		back = -back
	var head := eye + Vector2(-0.08, 0.0)
	var neck := eye + down * 0.25 + back * 0.03
	Clay.sphere(root, 0.11, _at(head, 0.0), BODY)
	_limb(root, _at(head, 0.0), _at(neck, 0.0), 0.06, BODY)
	_limb(root, _at(neck, 0.0), _at(pelvis, 0.0), thick, BODY)
	# La cuna y el respaldo, detrás de la espalda; el apoyacabezas detrás de la cabeza, con su brazo a la pared.
	var shell_top := neck + back * (thick + 0.04)
	var shell_low := pelvis + back * (thick + 0.04) + down * 0.08
	_limb(root, _at(shell_top, 0.0), _at(shell_low, 0.0), 0.04, PAD, 0.5)
	var seat := pelvis + down * (thick * 0.6) + Vector2(0.12, 0.0)
	_limb(root, _at(shell_low, 0.0), _at(seat, 0.0), 0.04, PAD, 0.5)
	var rest := head + Vector2(-0.14, 0.0)
	Clay.box(root, Vector3(0.28, 0.2, 0.07), _at(rest, 0.0), PAD)
	_limb(root, _at(rest + Vector2(-0.03, 0.0), 0.0), _at(Vector2(-RADIUS + 0.02, rest.y), 0.0), 0.035, DARK)
	_limb(root, _at(shell_low, 0.0), _at(shell_low.normalized() * (RADIUS - 0.02), 0.0), 0.05, DARK)
	for s: float in [-1.0, 1.0]:
		var x := s * 0.11
		var knee := pelvis + _dir(THIGH_UP, thigh)
		var ankle := knee + _dir(THIGH_UP - KNEE, shin)
		var toe := ankle + _dir(THIGH_UP - KNEE + 90.0, foot)
		_limb(root, _at(pelvis, x), _at(knee, x), thick * 0.55, BODY)
		_limb(root, _at(knee, x), _at(ankle, x), thick * 0.45, BODY)
		_limb(root, _at(ankle, x), _at(toe, x), 0.045, BODY)
		var hand := eye + Vector2(0.45, -0.42)
		var elbow := (neck + hand) * 0.5 + Vector2(-0.05, -0.1)
		_limb(root, _at(neck, s * 0.2), _at(elbow, s * 0.26), 0.05, BODY)
		_limb(root, _at(elbow, s * 0.26), _at(hand, s * 0.2), 0.045, BODY)
	Clay.box(root, Vector3(0.7, 0.04, 0.25), _at(eye + Vector2(0.5, -0.46), 0.0), DARK)
	_limb(root, _at(eye, 0.0), _at(Vector2(RADIUS, 0.0), 0.0), 0.008, RED)


func _sphere(root: Node3D) -> void:
	for part: Array in [[PI * 0.5, PI, SHELL], [0.0, PI * 0.5, GLASS]]:
		var tool := SurfaceTool.new()
		tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		CageMesh.sphere_band(tool, Vector3.ZERO, RADIUS, part[0], part[1], false)
		var mesh := MeshInstance3D.new()
		mesh.mesh = tool.commit()
		var paint := Clay.material(part[2]).duplicate() as StandardMaterial3D
		paint.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh.material_override = paint
		root.add_child(mesh)
	Clay.sphere(root, 0.03, Vector3.ZERO, RED)


func _at(p: Vector2, x: float) -> Vector3:
	return Vector3(x, p.y, -p.x)


func _dir(degrees: float, length: float) -> Vector2:
	var a := deg_to_rad(degrees)
	return Vector2(cos(a), sin(a)) * length


func _limb(root: Node3D, a: Vector3, b: Vector3, radius: float, color: Color, flat := 1.0) -> void:
	var holder := Clay.limb(root, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)
	if flat != 1.0:
		holder.scale = Vector3(3.0, flat, 1.0)


func _stage() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -60.0, 0.0)
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.82, 0.86, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 1000.0
	_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
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


func _view(from: Vector3, to: Vector3, size: float) -> Image:
	_eye.size = size
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array[Image]) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var w := shots[0].get_width()
	var h := shots[0].get_height()
	var sheet := Image.create(w * 2, h * 3, false, shots[0].get_format())
	for index in shots.size():
		sheet.blit_rect(shots[index], Rect2i(Vector2i.ZERO, shots[index].get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/pose_arquetipos.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)
