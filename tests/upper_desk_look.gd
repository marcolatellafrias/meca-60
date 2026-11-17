extends Node3D

## EL TABLERO DE ARRIBA DE LA JAULA: CÓMO SE PUEDE ENTENDER (16/11/2026, el usuario: «muéstrame las posibles
## interpretaciones de cómo es el tablero de arriba… tal vez sea necesario mostrar en ángulo y en 3D»). Maquetas de
## arcilla sobre el módulo de abajo de 3,2 m de lado, con el más alto sentado en el medio (los ojos a 1,38 m de la losa).
## Cada cara de controles mira a los ojos (lo que menos deforma). Cada una: de atrás y arriba, y cortada al medio de
## costado.
##   tools/godot_ventana.sh res://tests/upper_desk_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const L := 3.2
const HALF := L * 0.5
const EYE := 1.38
const RAIL := 1.0
const VARIANTS := [
	"1 · el tablero ES la baranda: en el octógono, contra el borde",
	"2 · un anillo cerca de la silla, la baranda aparte",
	"3 · un anillo cerca que sigue en mesa hasta la baranda",
	"4 · media corona adelante, abierta atrás",
	"5 · el bloque lleno con el pozo tallado",
]
const SHELL := Color(0.6, 0.61, 0.63)
const METAL := Color(0.5, 0.52, 0.55)
const DESK := Color(0.32, 0.33, 0.36)
const BODY := Color(0.85, 0.55, 0.35)
const RED := Color(0.78, 0.18, 0.15)
const YELLOW := Color(0.95, 0.75, 0.15)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	var only := 0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--variante="):
			only = int(argument.trim_prefix("--variante="))
	for index in VARIANTS.size():
		var root := Node3D.new()
		root.position = Vector3(0.0, 0.0, index * 30.0)
		add_child(root)
		_build(root, index + 1)
	for index in VARIANTS.size():
		if only > 0 and index + 1 != only:
			continue
		var at := Vector3(0.0, 0.0, index * 30.0)
		_title.text = VARIANTS[index]
		var shots: Array[Image] = []
		_eye.near = 0.05
		shots.append(await _view(at + Vector3(3.6, 5.2, 4.8), at + Vector3(0.0, 0.5, 0.0), 45.0))
		# Cortada al medio: la cámara de costado no ve lo que está más cerca que el plano del medio.
		_eye.near = 10.0 - 0.12
		shots.append(await _view(at + Vector3(10.0, 0.7, 0.0), at + Vector3(0.0, 0.7, 0.0), 0.0, 4.6))
		if index + 1 == 5:
			_eye.near = 0.05
			shots.append(await _view(at + Vector3(0.0, EYE, 0.05), at + Vector3(0.0, EYE - 0.55, -0.8), 75.0))
			shots.append(await _view(at + Vector3(-4.0, 3.2, -4.6), at + Vector3(0.0, 0.3, 0.0), 45.0))
		_save(shots, index + 1)
	get_tree().quit()


func _build(root: Node3D, kind: int) -> void:
	# El módulo de abajo, de lejos: un cubo con la losa arriba.
	Clay.box(root, Vector3(L, L, L), Vector3(0.0, -L * 0.5 - 0.15, 0.0), SHELL)
	Clay.box(root, Vector3(L, 0.15, L), Vector3(0.0, -0.075, 0.0), METAL)
	_seated(root)
	if kind == 5:
		_pit(root)
		return
	_square_rail(root)
	match kind:
		1:
			_ring(root, HALF - 0.1 - 0.45, 0.75, 0.5, range(8), true, 0.0)
		2:
			_ring(root, 0.55, 0.8, 0.35, [0, 1, 2, 3, 5, 6, 7], false, 0.0)
		3:
			_ring(root, 0.55, 0.8, 0.35, [0, 1, 2, 3, 5, 6, 7], true, HALF - 0.1)
		4:
			_ring(root, 0.55, 0.8, 0.35, [0, 1, 2, 6, 7], false, 0.0)


## EL BLOQUE CON EL POZO (DeskPit), con unos controles en cada cara del tablero.
func _pit(root: Node3D) -> void:
	var pit := DeskPit.new()
	pit.side = L
	pit.eye = EYE
	var shape := MeshInstance3D.new()
	shape.mesh = pit.mesh(SHELL)
	# Las dos caras, para que el corte de costado lo muestre macizo.
	var paint := Clay.material(SHELL).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	shape.material_override = paint
	root.add_child(shape)
	var t := deg_to_rad(pit.tilt)
	for k in 8:
		var angle := TAU * k / 8.0
		var out := Vector3(sin(angle), 0.0, -cos(angle))
		var tangent := Vector3.UP.cross(out).normalized()
		var normal := (Vector3.UP * cos(t) - out * sin(t)).normalized()
		var panel := Node3D.new()
		panel.basis = Basis(tangent, normal, tangent.cross(normal))
		panel.position = out * (pit.radius + DeskPit.DEPTH * 0.5 * cos(t)) + Vector3.UP * (pit.low() + DeskPit.DEPTH * 0.5 * sin(t))
		root.add_child(panel)
		var width := 2.0 * pit.radius * tan(PI / 8.0)
		Clay.cylinder(panel, 0.05, 0.05, Vector3(-width * 0.25, 0.02, 0.0), RED)
		Clay.cylinder(panel, 0.05, 0.05, Vector3(0.0, 0.02, 0.05), YELLOW)
		Clay.sphere(panel, 0.045, Vector3(width * 0.25, 0.04, -0.05), RED)


## UN ANILLO OCTOGONAL de caras de controles: la orilla de adentro a `inner` del centro y a `low` de alto, cada cara de
## `depth` de largo y mirando a los ojos. `walls`: macizo hasta el piso; si no, en patas. `counter`: sigue en mesa
## chata hasta ese apotema.
func _ring(root: Node3D, inner: float, low: float, depth: float, sides: Array, walls: bool, counter: float) -> void:
	var eye := Vector3(0.0, EYE, 0.0)
	for i: int in sides:
		var angle := TAU * i / 8.0
		var out := Vector3(sin(angle), 0.0, -cos(angle))
		var tangent := Vector3.UP.cross(out).normalized()
		var tilt := deg_to_rad(50.0)
		var center := Vector3.ZERO
		var normal := Vector3.UP
		for _pass in 3:
			center = out * (inner + 0.5 * depth * cos(tilt)) + Vector3.UP * (low + 0.5 * depth * sin(tilt))
			normal = (eye - center).normalized()
			tilt = acos(normal.y)
		var width := 2.0 * (inner + 0.5 * depth * cos(tilt)) * tan(PI / 8.0)
		var panel := Node3D.new()
		panel.basis = Basis(tangent, normal, tangent.cross(normal))
		panel.position = center
		root.add_child(panel)
		Clay.box(panel, Vector3(width, 0.05, depth), Vector3.ZERO, DESK)
		Clay.cylinder(panel, 0.05, 0.05, Vector3(-width * 0.25, 0.04, 0.0), RED)
		Clay.cylinder(panel, 0.05, 0.05, Vector3(0.0, 0.04, 0.05), YELLOW)
		Clay.sphere(panel, 0.045, Vector3(width * 0.25, 0.06, -0.05), RED)
		var outer := inner + depth * cos(tilt)
		var high := low + depth * sin(tilt)
		if walls:
			var w_in := 2.0 * inner * tan(PI / 8.0)
			_slab(root, out, tangent, inner, Vector3(w_in, low, 0.05), low * 0.5)
			if counter <= 0.0:
				var w_out := 2.0 * outer * tan(PI / 8.0)
				_slab(root, out, tangent, outer, Vector3(w_out, high, 0.05), high * 0.5)
		else:
			for s: float in [-1.0, 1.0]:
				Clay.cylinder(root, 0.03, low, out * (inner + 0.05) + tangent * s * width * 0.35 + Vector3.UP * low * 0.5,
					METAL)
		if counter > 0.0:
			var reach := counter - outer
			var w_mid := 2.0 * (outer + counter) * 0.5 * tan(PI / 8.0)
			_slab(root, out, tangent, (outer + counter) * 0.5, Vector3(w_mid, 0.05, reach), high)
			var w_end := 2.0 * counter * tan(PI / 8.0)
			_slab(root, out, tangent, counter, Vector3(w_end, high, 0.05), high * 0.5)


## Una caja de frente a `out`, a `distance` del centro y a `height` de alto.
func _slab(root: Node3D, out: Vector3, tangent: Vector3, distance: float, size: Vector3, height: float) -> void:
	var holder := Node3D.new()
	holder.basis = Basis(tangent, Vector3.UP, -out)
	holder.position = out * distance + Vector3.UP * height
	root.add_child(holder)
	Clay.box(holder, size, Vector3.ZERO, DESK.lightened(0.25))


## LA BARANDA DEL CUADRADO: postes y caño arriba, al borde de la losa.
func _square_rail(root: Node3D) -> void:
	var edge := HALF - 0.05
	for s: float in [-1.0, 1.0]:
		Clay.box(root, Vector3(L, 0.05, 0.05), Vector3(0.0, RAIL, s * edge), METAL)
		Clay.box(root, Vector3(0.05, 0.05, L), Vector3(s * edge, RAIL, 0.0), METAL)
		for t: float in [-1.0, -0.5, 0.0, 0.5, 1.0]:
			Clay.box(root, Vector3(0.04, RAIL, 0.04), Vector3(t * edge, RAIL * 0.5, s * edge), METAL)
			Clay.box(root, Vector3(0.04, RAIL, 0.04), Vector3(s * edge, RAIL * 0.5, t * edge), METAL)


## EL MÁS ALTO SENTADO, mirando al frente (−Z), con la silla.
func _seated(root: Node3D) -> void:
	var pelvis := EYE - 0.82
	Clay.box(root, Vector3(0.5, 0.06, 0.5), Vector3(0.0, pelvis - 0.1, 0.05), METAL)
	Clay.box(root, Vector3(0.5, 0.6, 0.06), Vector3(0.0, pelvis + 0.25, 0.3), METAL)
	Clay.cylinder(root, 0.05, pelvis - 0.1, Vector3(0.0, (pelvis - 0.1) * 0.5, 0.05), METAL)
	_limb(root, Vector3(0.0, pelvis, 0.12), Vector3(0.0, EYE - 0.22, 0.12), 0.16)
	Clay.sphere(root, 0.12, Vector3(0.0, EYE, 0.05), BODY)
	for s: float in [-1.0, 1.0]:
		var hip := Vector3(s * 0.11, pelvis, 0.05)
		var knee := Vector3(s * 0.12, pelvis + 0.02, -0.4)
		_limb(root, hip, knee, 0.07)
		_limb(root, knee, Vector3(s * 0.12, 0.05, -0.47), 0.06)
		var shoulder := Vector3(s * 0.2, EYE - 0.3, 0.1)
		var elbow := Vector3(s * 0.26, EYE - 0.55, -0.1)
		_limb(root, shoulder, elbow, 0.05)
		_limb(root, elbow, Vector3(s * 0.22, EYE - 0.55, -0.4), 0.045)


func _limb(root: Node3D, a: Vector3, b: Vector3, radius: float) -> void:
	var holder := Clay.limb(root, radius, a.distance_to(b), Vector3.ZERO, BODY)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)


func _stage() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
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


func _view(from: Vector3, to: Vector3, fov: float, ortho := 0.0) -> Image:
	if fov > 0.0:
		_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
		_eye.fov = fov
	else:
		_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		_eye.size = ortho
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array[Image], number: int) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var first := shots[0]
	var w := first.get_width()
	var h := first.get_height()
	var sheet := Image.create(w * 2, h * ceili(shots.size() / 2.0), false, first.get_format())
	for index in shots.size():
		sheet.blit_rect(shots[index], Rect2i(Vector2i.ZERO, shots[index].get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/tablero_%d.png" % [_folder, number]
	sheet.save_png(path)
	print("CAPTURA ", path)
