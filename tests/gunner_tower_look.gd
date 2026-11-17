extends Node3D

## LA TORRE DEL ARTILLERO SOBRE EL BLOQUE DE ARRIBA (DeskPit), MAQUETAS (16/11/2026, el usuario: «tiene que ir en el
## cuadrado que se genera en la parte de atrás… si agrando mucho el octógono va a quedar muy finita la torre… distintas
## formas de mostrarla… no puede ser más larga la profundidad que el ancho… y que no sobresalga del cuadrado general si lo
## ves desde arriba»). Cada una, con el octógono chico (radio 0,6 m) y grande (0,9 m), vista de atrás y arriba.
##   tools/godot_ventana.sh res://tests/gunner_tower_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const L := 3.2
const EDGE := L * 0.5
const EYE := 1.38
## Lo alto de la torre sobre el piso de arriba, y los ojos del artillero sobre ella.
const TOWER_TOP := 1.6
const GUNNER_EYE := 1.15
## El lado (o el diámetro) del plato de arriba en las de columna fina.
const PLATFORM := 0.9
const RADII := [0.6, 0.9]
const OPTIONS := [
	"1 · cuadrada, en la franja de atrás",
	"2 · redonda, en la franja de atrás",
	"3 · cuadrada, en una esquina de atrás",
	"4 · columna fina con plato cuadrado arriba",
	"5 · columna fina con plato redondo arriba",
	"6 · a lo ancho: toda la franja de atrás",
]
const SHELL := Color(0.6, 0.61, 0.63)
const TOWER := Color(0.5, 0.52, 0.56)
const METAL := Color(0.4, 0.42, 0.45)
const DARK := Color(0.25, 0.26, 0.28)
const BODY := Color(0.85, 0.55, 0.35)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	for option in OPTIONS.size():
		for state in RADII.size():
			var root := Node3D.new()
			root.position = _spot(option, state)
			add_child(root)
			_build(root, option + 1, RADII[state])
	for option in OPTIONS.size():
		var shots: Array[Image] = []
		for state in RADII.size():
			_title.text = "%s · octógono de %.1f m" % [OPTIONS[option], RADII[state]]
			var at := _spot(option, state)
			shots.append(await _view(at + Vector3(3.4, 4.6, 5.2), at + Vector3(0.0, 0.7, 0.3)))
		_save(shots, option + 1)
	get_tree().quit()


func _spot(option: int, state: int) -> Vector3:
	return Vector3(state * 30.0, 0.0, option * 30.0)


func _build(root: Node3D, kind: int, radius: float) -> void:
	Clay.box(root, Vector3(L, L, L), Vector3(0.0, -L * 0.5 - 0.15, 0.0), SHELL)
	Clay.box(root, Vector3(L, 0.15, L), Vector3(0.0, -0.075, 0.0), METAL)
	var pit := DeskPit.new()
	pit.side = L
	pit.radius = radius
	pit.eye = EYE
	var shape := MeshInstance3D.new()
	shape.mesh = pit.mesh(SHELL)
	root.add_child(shape)
	_seated(root, Vector3.ZERO, EYE)
	var top := pit.top()
	var rim := pit.rim()
	# La franja de atrás: el ancho de la cara de atrás del octógono y lo que queda hasta el borde.
	var width := 2.0 * rim * tan(PI / 8.0)
	var depth := EDGE - rim
	var strip := minf(width, depth)
	var seat_at := Vector3(0.0, TOWER_TOP, EDGE - strip * 0.5)
	match kind:
		1:
			_prism(root, _square(Vector2(0.0, EDGE - strip * 0.5), strip), top, TOWER_TOP)
		2:
			_column(root, Vector2(0.0, EDGE - strip * 0.5), strip * 0.5, top, TOWER_TOP)
		3:
			var side := EDGE - rim / sqrt(2.0)
			var center := Vector2(EDGE - side * 0.5, EDGE - side * 0.5)
			_prism(root, _square(center, side), top, TOWER_TOP)
			seat_at = Vector3(center.x, TOWER_TOP, center.y)
		4, 5:
			var thin := minf(strip, 0.45)
			_column(root, Vector2(0.0, EDGE - strip * 0.5), thin * 0.5, top, TOWER_TOP - 0.12)
			var middle := Vector2(0.0, EDGE - PLATFORM * 0.5)
			if kind == 4:
				_prism(root, _square(middle, PLATFORM), TOWER_TOP - 0.12, TOWER_TOP)
			else:
				_column(root, middle, PLATFORM * 0.5, TOWER_TOP - 0.12, TOWER_TOP)
			seat_at = Vector3(0.0, TOWER_TOP, middle.y)
		6:
			# El trapecio entre las dos diagonales de atrás, hasta el borde.
			var half_rim := rim * tan(PI / 8.0)
			_prism(root, PackedVector2Array([Vector2(-half_rim, rim), Vector2(half_rim, rim),
				Vector2(half_rim + depth, EDGE), Vector2(-half_rim - depth, EDGE)]), top, TOWER_TOP)
			seat_at = Vector3(0.0, TOWER_TOP, EDGE - depth * 0.5)
	_gunner(root, seat_at)


## EL ARTILLERO sentado arriba, con el arma en su pie al frente.
func _gunner(root: Node3D, at: Vector3) -> void:
	_seated(root, at, GUNNER_EYE)
	Clay.cylinder(root, 0.05, 0.75, at + Vector3(0.0, 0.375, -0.45), DARK)
	Clay.box(root, Vector3(0.22, 0.2, 0.45), at + Vector3(0.0, 0.8, -0.5), DARK)
	Clay.cylinder(root, 0.03, 0.7, at + Vector3(0.0, 0.8, -1.0), DARK, Vector3(90.0, 0.0, 0.0))


## UN PRISMA de caras propias: el contorno convexo `outline` (x, z), de `from` a `to` de alto.
func _prism(root: Node3D, outline: PackedVector2Array, from: float, to: float) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var low: Array = []
	var high: Array = []
	for point in outline:
		low.append(Vector3(point.x, from, point.y))
		high.append(Vector3(point.x, to, point.y))
	CageMesh.face(tool, high, Vector3.UP)
	var center := Vector2.ZERO
	for point in outline:
		center += point / outline.size()
	for i in outline.size():
		var j := (i + 1) % outline.size()
		var middle := (outline[i] + outline[j]) * 0.5 - center
		CageMesh.face(tool, [low[i], low[j], high[j], high[i]], Vector3(middle.x, 0.0, middle.y).normalized())
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	mesh.material_override = Clay.material(TOWER)
	root.add_child(mesh)


func _column(root: Node3D, center: Vector2, radius: float, from: float, to: float) -> void:
	Clay.cylinder(root, radius, to - from, Vector3(center.x, (from + to) * 0.5, center.y), TOWER)


static func _square(center: Vector2, side: float) -> PackedVector2Array:
	var h := side * 0.5
	return PackedVector2Array([center + Vector2(-h, -h), center + Vector2(h, -h), center + Vector2(h, h),
		center + Vector2(-h, h)])


## UNO SENTADO sobre `base`, mirando al frente (−Z), con los ojos a `eye`, y su silla.
func _seated(root: Node3D, base: Vector3, eye: float) -> void:
	var pelvis := eye - 0.82
	Clay.box(root, Vector3(0.5, 0.06, 0.5), base + Vector3(0.0, pelvis - 0.1, 0.05), METAL)
	Clay.box(root, Vector3(0.5, 0.6, 0.06), base + Vector3(0.0, pelvis + 0.25, 0.3), METAL)
	Clay.cylinder(root, 0.05, pelvis - 0.1, base + Vector3(0.0, (pelvis - 0.1) * 0.5, 0.05), METAL)
	_limb(root, base + Vector3(0.0, pelvis, 0.12), base + Vector3(0.0, eye - 0.22, 0.12), 0.16)
	Clay.sphere(root, 0.12, base + Vector3(0.0, eye, 0.05), BODY)
	for s: float in [-1.0, 1.0]:
		var knee := base + Vector3(s * 0.12, pelvis + 0.02, -0.4)
		_limb(root, base + Vector3(s * 0.11, pelvis, 0.05), knee, 0.07)
		_limb(root, knee, base + Vector3(s * 0.12, maxf(pelvis - 0.5, 0.05), -0.47), 0.06)
		var elbow := base + Vector3(s * 0.26, eye - 0.55, -0.1)
		_limb(root, base + Vector3(s * 0.2, eye - 0.3, 0.1), elbow, 0.05)
		_limb(root, elbow, base + Vector3(s * 0.22, eye - 0.55, -0.4), 0.045)


func _limb(root: Node3D, a: Vector3, b: Vector3, radius: float) -> void:
	var holder := Clay.limb(root, radius, a.distance_to(b), Vector3.ZERO, BODY)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)


func _stage() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, 145.0, 0.0)
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
	_eye.far = 1000.0
	_eye.fov = 45.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 34)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


func _view(from: Vector3, to: Vector3) -> Image:
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array[Image], number: int) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var w := shots[0].get_width()
	var sheet := Image.create(w * 2, shots[0].get_height(), false, shots[0].get_format())
	for index in shots.size():
		sheet.blit_rect(shots[index], Rect2i(Vector2i.ZERO, shots[index].get_size()), Vector2i(w * index, 0))
	var path := "%s/torre_%d.png" % [_folder, number]
	sheet.save_png(path)
	print("CAPTURA ", path)
