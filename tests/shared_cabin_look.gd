extends Node3D

## LA MECA DE TRES CON LA CABINA COMÚN, BOCETO DE ARCILLA (15/11/2026, el usuario, después de las cabinas separadas: «por
## ahora… de tres jugadores. Uno un brazo, el otro brazo. Un brazo siempre va a ser para cosas a distancia… el otro es
## para melee… que estén todos en el mismo espacio cerrado. Así pueden verse entre ellos y comunicarse mejor… un
## escalonado en el que los dos brazos estén a un nivel más alto, y abajo está el de las piernas, pero los tres están
## mirando hacia adelante, y el cuadrado es un cuadrado común solamente con una cara vidriada… las piernas y los brazos
## serían iguales, pero sin artillería»).
## El torso es una caja con el frente de vidrio; adentro, LOS TRES EN LA MISMA LÍNEA, ADELANTE, A DISTINTO ALTO (el
## usuario corrigió el primer escalonado: «los tres estaban al mismo nivel en el eje de profundidad, pero en el eje
## vertical estaban desfasados y los escalones estaban solamente en esa sección delantera»): al centro, en el piso, el
## de las piernas; a los costados, sobre tarimas, los de los brazos. Atrás, el piso común (para las baterías, las
## municiones y la reparación, en la ronda que sigue). El brazo izquierdo, a distancia (un
## cañón); el derecho, cuerpo a cuerpo (una sierra). El torso, girado sobre el aro de la cintura como en las cabinas
## separadas. Vistas: afuera en diagonal, de frente, de costado en corte y la planta desde arriba (sin techo).
##   tools/godot_ventana.sh res://tests/shared_cabin_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
const WALL := 0.15
const WAIST := 3.9
## La caja del torso, por fuera.
const BOX := Vector3(3.6, 3.4, 3.8)
## El nivel de arriba: su alto sobre el piso de abajo y desde dónde empieza (z, desde el frente hacia atrás).
const UPPER_RISE := 1.0
const UPPER_FROM := 1.6
const TWIST := -20.0
const RING := Vector2(1.35, 0.35)
const BATTERY := 0.63

const METAL := Color(0.55, 0.57, 0.6)
const DARK_METAL := Color(0.3, 0.31, 0.34)
const FLOOR := Color(0.68, 0.69, 0.71)
const SKIN := Color(0.86, 0.66, 0.5)
const SEAT := Color(0.25, 0.42, 0.7)
const CELL := Color(0.36, 0.58, 0.36)
const CORE := Color(0.95, 0.8, 0.3)
const LIMIT := Color(0.8, 0.22, 0.18)
const FREE := Color(0.85, 0.8, 0.55)
const ACCENT := {"walk": Color(0.3, 0.45, 0.75), "ranged": Color(0.93, 0.75, 0.16), "melee": Color(0.8, 0.25, 0.2)}

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _glass := StandardMaterial3D.new()
## Las paredes y el techo de la caja: se vuelven transparentes para los cortes.
var _shell := StandardMaterial3D.new()
var _roof: MeshInstance3D = null
var _upper := Node3D.new()
## Los hombros y los brazos: se esconden en los cortes, para ver adentro.
var _arms := Node3D.new()


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_glass.albedo_color = Color(0.7, 0.85, 0.95, 0.15)
	_glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_glass.roughness = 0.1
	_shell.albedo_color = METAL
	_shell.roughness = 0.85
	_shell.cull_mode = BaseMaterial3D.CULL_DISABLED
	_stage()
	add_child(_upper)
	_upper.add_child(_arms)
	_upper.rotation_degrees.y = TWIST
	_legs()
	_torso()
	PeopleArchetype.spawn(self, EntityArchetype.Archetype.fat_man, Vector3(4.6, 0.0, -3.4), -PI * 0.7)
	await get_tree().create_timer(3.0).timeout
	_title.text = "10. la cabina común de tres, escalonada"
	var top := WAIST + BOX.y
	var middle := top * 0.5
	var turn := Basis(Vector3.UP, deg_to_rad(TWIST))
	var inside := Vector3(0.0, WAIST + 1.4, 0.0)
	var shots: Array = []
	_look(Vector3(-8.0, 7.0, -12.0), Vector3(0.0, middle, 0.0), 45.0)
	shots.append(await _grab())
	_look(turn * Vector3(0.0, WAIST + 2.2, -9.0), turn * Vector3(0.0, WAIST + 1.6, 0.0), 40.0)
	shots.append(await _grab())
	# Los cortes: la caja medio transparente.
	_shell.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_shell.albedo_color = Color(METAL, 0.18)
	_arms.visible = false
	_look(turn * Vector3(9.0, WAIST + 1.8, 0.4), turn * inside, 38.0)
	shots.append(await _grab())
	_roof.visible = false
	_look(turn * Vector3(0.0, WAIST + 11.0, 0.6), turn * inside, 38.0, turn * Vector3.FORWARD)
	shots.append(await _grab())
	_save(shots)
	get_tree().quit()


## ── LAS PIERNAS (iguales a las de las cabinas separadas) ──────────────────────────────────────────────────────────────

func _legs() -> void:
	Clay.cylinder(self, RING.x, RING.y, Vector3(0.0, WAIST - RING.y * 0.5, 0.0), DARK_METAL)
	_tick(0.0, CORE)
	_tick(90.0, LIMIT)
	_tick(-90.0, LIMIT)
	var plate := Vector3(2.8, 0.6, 1.8)
	var hip := WAIST - RING.y - plate.y
	Clay.box(self, plate, Vector3(0.0, hip + plate.y * 0.5, 0.0), METAL)
	for side: float in [-1.0, 1.0]:
		var from := Vector3(side * 1.05, hip + 0.1, 0.0)
		var foot := Vector3(side * 1.15, 0.4, 0.0)
		var knee := Vector3(foot.x, (from.y + foot.y) * 0.5, -0.4)
		_bar(self, from, knee, 0.85, METAL)
		_bar(self, knee, foot, 0.75, METAL)
		Clay.box(self, Vector3(0.95, 0.95, 0.95), knee, DARK_METAL)
		Clay.box(self, Vector3(1.0, 0.4, 1.6), Vector3(foot.x, 0.2, -0.3), DARK_METAL)


func _tick(degrees: float, color: Color) -> void:
	var angle := deg_to_rad(degrees)
	var out := Vector3(-sin(angle), 0.0, -cos(angle))
	var mark := Clay.box(self, Vector3(0.18, RING.y + 0.04, 0.3), out * RING.x + Vector3(0.0, WAIST - RING.y * 0.5,
		0.0), color)
	mark.basis = Basis(Vector3.UP, angle)


## ── EL TORSO: LA CAJA, ADENTRO Y LOS BRAZOS ───────────────────────────────────────────────────────────────────────

func _torso() -> void:
	var up := _upper
	var half := BOX * 0.5
	var center := Vector3(0.0, WAIST + half.y, 0.0)
	var front := -half.z
	# El piso, el fondo, los costados y el techo, de metal; el frente, vidrio entero con un marco.
	Clay.box(up, Vector3(BOX.x, WALL, BOX.z), Vector3(0.0, WAIST + WALL * 0.5, 0.0), FLOOR)
	_wall(Vector3(BOX.x, BOX.y, WALL), center + Vector3(0.0, 0.0, half.z - WALL * 0.5))
	for side: float in [-1.0, 1.0]:
		_wall(Vector3(WALL, BOX.y, BOX.z), center + Vector3(side * (half.x - WALL * 0.5), 0.0, 0.0))
	_roof = _wall(Vector3(BOX.x, WALL, BOX.z), center + Vector3(0.0, half.y - WALL * 0.5, 0.0))
	var pane := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(BOX.x - 0.3, BOX.y - 0.4, 0.04)
	pane.mesh = mesh
	pane.material_override = _glass
	pane.position = center + Vector3(0.0, 0.05, front + 0.05)
	up.add_child(pane)
	for side: float in [-1.0, 1.0]:
		Clay.box(up, Vector3(0.15, BOX.y, 0.15), center + Vector3(side * (half.x - 0.075), 0.0, front + 0.075), METAL)
	Clay.box(up, Vector3(BOX.x, 0.25, 0.15), Vector3(0.0, WAIST + 0.125, front + 0.075), METAL)
	Clay.box(up, Vector3(BOX.x, 0.15, 0.15), Vector3(0.0, WAIST + BOX.y - 0.075, front + 0.075), METAL)
	# LOS TRES EN LA MISMA LÍNEA, ADELANTE, A DISTINTO ALTO: al centro, en el piso, el de las piernas; a los costados,
	# sobre dos tarimas que ocupan sólo la franja de adelante (UPPER_FROM de fondo), los de los brazos. Cada tarima
	# tiene sus escalones atrás, que bajan al piso común.
	var floor_y := WAIST + WALL
	var deck_y := floor_y + UPPER_RISE
	var inner := BOX.x - WALL * 2.0
	var deck_width := inner / 3.0
	var seat_z := front + 0.85
	for side: float in [-1.0, 1.0]:
		var x := side * deck_width
		Clay.box(up, Vector3(deck_width, UPPER_RISE, UPPER_FROM), Vector3(x, floor_y + UPPER_RISE * 0.5,
			front + UPPER_FROM * 0.5), FLOOR)
		for step in 2:
			var rise := UPPER_RISE * (step + 1) / 3.0
			Clay.box(up, Vector3(0.7, rise, 0.3), Vector3(x + side * (deck_width * 0.5 - 0.35), floor_y + rise * 0.5,
				front + UPPER_FROM + 0.15 + (1 - step) * 0.3), FLOOR)
	_station(Vector3(0.0, floor_y, seat_z), "walk")
	# El izquierdo, a distancia; el derecho, cuerpo a cuerpo.
	_station(Vector3(-deck_width, deck_y, seat_z), "ranged")
	_station(Vector3(deck_width, deck_y, seat_z), "melee")
	# El piso común, atrás de los escalones, marcado: para las baterías, la munición y la reparación.
	var free_from := front + UPPER_FROM + 0.7
	Clay.box(up, Vector3(inner - 0.2, 0.02, half.z - WALL - free_from - 0.1), Vector3(0.0, floor_y + 0.01,
		(free_from + half.z - WALL) * 0.5), FREE)
	# Los hombros, macizos, y los brazos.
	for side: float in [-1.0, 1.0]:
		var shoulder := Vector3(side * (half.x + 0.7), WAIST + 2.5, 0.0)
		Clay.box(_arms, Vector3(1.4, 1.4, 1.7), shoulder, METAL)
		var from := shoulder + Vector3(side * 0.2, -0.7, 0.2)
		var elbow := Vector3(from.x + side * 0.3, from.y - 2.2, 0.4)
		var hand := elbow + Vector3(0.0, -0.3, -1.5)
		_bar(_arms, from, elbow, 0.75, METAL)
		_bar(_arms, elbow, hand, 0.7, METAL)
		if side < 0.0:
			# A distancia: un cañón.
			Clay.box(_arms, Vector3(0.9, 0.9, 1.0), hand, DARK_METAL)
			Clay.box(_arms, Vector3(0.4, 0.4, 2.0), hand + Vector3(0.0, 0.0, -1.4), DARK_METAL)
			Clay.box(_arms, Vector3(0.5, 0.5, 0.2), hand + Vector3(0.0, 0.0, -2.4), ACCENT["ranged"])
		else:
			# Cuerpo a cuerpo: una sierra.
			Clay.box(_arms, Vector3(0.9, 0.9, 1.0), hand, DARK_METAL)
			Clay.cylinder(_arms, 1.0, 0.12, hand + Vector3(0.0, 0.0, -1.1), ACCENT["melee"], Vector3(0.0, 0.0, 90.0))
	# Las baterías de afuera, en la espalda, como en las cabinas separadas.
	Clay.box(up, Vector3(1.7, 1.7, 0.12), Vector3(0.0, WAIST + 1.6, half.z + 0.06), DARK_METAL)
	for x: float in [-0.4, 0.4]:
		for y: float in [-0.4, 0.4]:
			Clay.box(up, Vector3.ONE * BATTERY, Vector3(x, WAIST + 1.6 + y, half.z + 0.12 + BATTERY * 0.5), CELL)


func _wall(size: Vector3, at: Vector3) -> MeshInstance3D:
	var part := Clay.box(_upper, size, at, METAL)
	part.material_override = _shell
	return part


## UN PUESTO: el asiento con su piloto sentado mirando adelante, una consola delante, y la franja de su color en el
## respaldo. `at`, el piso debajo del asiento.
func _station(at: Vector3, role: String) -> void:
	var up := _upper
	Clay.box(up, Vector3(0.55, 0.1, 0.5), at + Vector3(0.0, 0.42, 0.05), SEAT)
	Clay.box(up, Vector3(0.55, 0.75, 0.1), at + Vector3(0.0, 0.82, 0.32), SEAT)
	Clay.box(up, Vector3(0.57, 0.1, 0.12), at + Vector3(0.0, 1.15, 0.32), ACCENT[role])
	Clay.box(up, Vector3(0.08, 0.42, 0.08), at + Vector3(0.0, 0.21, 0.05), DARK_METAL)
	Clay.box(up, Vector3(0.38, 0.55, 0.24), at + Vector3(0.0, 0.76, 0.14), SKIN)
	Clay.sphere(up, 0.12, at + Vector3(0.0, 1.17, 0.12), SKIN)
	Clay.box(up, Vector3(0.34, 0.14, 0.42), at + Vector3(0.0, 0.54, -0.1), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(up, Vector3(0.12, 0.42, 0.12), at + Vector3(side * 0.1, 0.27, -0.28), SKIN)
		Clay.box(up, Vector3(0.1, 0.1, 0.38), at + Vector3(side * 0.24, 0.8, -0.12), SKIN)
	# La consola: un pie y un tablero inclinado.
	Clay.box(up, Vector3(0.1, 0.6, 0.1), at + Vector3(0.0, 0.3, -0.55), DARK_METAL)
	var desk := Clay.box(up, Vector3(0.7, 0.06, 0.3), at + Vector3(0.0, 0.66, -0.5), DARK_METAL)
	desk.basis = Basis(Vector3.RIGHT, deg_to_rad(25.0))


func _bar(parent: Node3D, a: Vector3, b: Vector3, thick: float, color: Color) -> void:
	var part := Clay.box(parent, Vector3(thick, thick, a.distance_to(b)), (a + b) * 0.5, color)
	part.basis = Basis.looking_at(b - a, Vector3.RIGHT if absf((b - a).normalized().y) > 0.9 else Vector3.UP)


func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52.0, -40.0, 0.0)
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
	_eye.far = 1000.0
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


func _look(from: Vector3, to: Vector3, fov: float, up := Vector3.UP) -> void:
	_eye.fov = fov
	_eye.global_position = from
	_eye.look_at(to, up)


func _save(shots: Array) -> void:
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
	var path := "%s/cabina_comun.png" % _folder
	sheet.save_png(path)
	print("CAPTURA ", path)


func _grab() -> Image:
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
