extends Node3D

## LA CABINA CUADRADA DEL CAÑÓN, UNA SOLA MAQUETA (15/11/2026, sesión Tableros). Sigue a las alternativas de
## tests/square_cabin_controls_look; el usuario: «el mando principal… tiene que tener una gran jerarquía y ocupar una
## gran parte del espacio… volver el concepto de los brazos articulados que apuntan hacia el que está sentado, con cubos
## de pantalla… con un poco más de criterio» (nada atraviesa nada).
##   · AL CENTRO, EL MANDO DEL CAÑÓN: grande, sobre un pie del piso; dos empuñaduras con su gatillo y, arriba, la
##     energía (la munición del cañón) a la vista.
##   · A LA IZQUIERDA, EL CUBO DE LOS MODOS en un brazo articulado desde la esquina de atrás: ráfaga (se traba),
##     barrido y súper, cada uno con su carga.
##   · A LA DERECHA, EL CUBO DEL ESTADO, en otro brazo igual: la meca de frente.
##   · ARRIBA ADELANTE, EYECTAR: la manija rayada que cuelga del techo.
##   tools/godot_ventana.sh res://tests/square_cabin_station_look.tscn -- --salida=C:/carpeta

const CELL := Vector3(1.4, 2.0, 1.6)
const EYE := Vector3(0, 1.15, 0.28)
const STATUS := preload("res://tests/radial_seat_play.gd")

const WALL := Color(0.27, 0.28, 0.29)
const STEEL := Color(0.4, 0.41, 0.43)
const LINK := Color(0.6, 0.62, 0.64)
const JOINT := Color(0.17, 0.17, 0.18)
const DARK := Color(0.12, 0.12, 0.13)
const CREAM := Color(0.86, 0.83, 0.74)
const INK := Color(0.08, 0.08, 0.08)
const GREEN := Color(0.35, 1.0, 0.45)
const AMBER := Color(1.0, 0.6, 0.18)
const OFF := Color(0.3, 0.22, 0.14)
const RED := Color(0.85, 0.15, 0.12)
const ACCENT := Color(0.95, 0.75, 0.15)
const GLASS := Color(0.7, 0.82, 0.86, 0.12)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _hide: Array[Node3D] = []
var _person: Node3D = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	_world()
	_cabin()
	_main_control()
	_modes_cube()
	_status_cube()
	_eject()
	_sit_person()
	_eye = Camera3D.new()
	_eye.fov = 82.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 680)
	_title.add_theme_font_size_override("font_size", 22)
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 6)
	layer.add_child(_title)
	await get_tree().process_frame
	_person.visible = false
	_from(EYE, EYE + Vector3(0, -0.45, -1))
	await _shot("1. Desde la silla: el mando del cañón al centro; los modos a la izquierda y el estado a la derecha", "1")
	_from(EYE, EYE + Vector3(-0.8, -0.3, -0.6))
	await _shot("2. Girando la cabeza a la izquierda: el cubo de los modos", "2")
	_from(EYE, EYE + Vector3(0.8, -0.1, -0.6))
	await _shot("3. A la derecha: el cubo del estado", "3")
	_person.visible = true
	for piece in _hide:
		piece.visible = false
	_from(Vector3(1.5, 1.7, -1.4), Vector3(0, 0.95, 0.05))
	await _shot("4. Cortada, con alguien sentado", "4")
	_from(Vector3(1.9, 1.3, 0.3), Vector3(0, 0.95, 0.0))
	await _shot("5. Cortada, de costado", "5")
	get_tree().quit()


func _world() -> void:
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -140.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.62, 0.6, 0.57)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.66, 0.66, 0.7)
	world.environment.ambient_light_energy = 0.6
	world.environment.fog_enabled = true
	world.environment.fog_light_color = Color(0.62, 0.6, 0.57)
	world.environment.fog_density = 0.012
	add_child(world)
	Clay.box(self, Vector3(400, 1, 400), Vector3(0, -6.5, 0), Color(0.44, 0.41, 0.37))
	var boss := Color(0.2, 0.19, 0.2)
	Clay.box(self, Vector3(6, 7, 4), Vector3(3, 2, -34), boss)
	Clay.box(self, Vector3(3, 0.5, 0.3), Vector3(3, 3.5, -31.9), AMBER)


# ── LA CABINA: piso, techo y pared de atrás macizos; vidrio adelante y a los costados ────────────────────────────
func _cabin() -> void:
	var half := CELL * 0.5
	Clay.box(self, Vector3(CELL.x + 0.2, 0.1, CELL.z + 0.2), Vector3(0, -0.05, 0), WALL)
	_hide.append(Clay.box(self, Vector3(CELL.x + 0.2, 0.12, CELL.z + 0.2), Vector3(0, CELL.y + 0.06, 0), WALL))
	# Atrás, abierta: sólo el canto del techo y el del piso.
	Clay.box(self, Vector3(CELL.x + 0.2, 0.07, 0.07), Vector3(0, CELL.y, half.z + 0.06), DARK)
	Clay.box(self, Vector3(CELL.x, CELL.y, 0.02), Vector3(0, half.y, -half.z), GLASS)
	_hide.append(Clay.box(self, Vector3(0.02, CELL.y, CELL.z), Vector3(half.x, half.y, 0), GLASS))
	Clay.box(self, Vector3(0.02, CELL.y, CELL.z), Vector3(-half.x, half.y, 0), GLASS)
	for x: float in [-half.x, half.x]:
		var post := Clay.box(self, Vector3(0.07, CELL.y, 0.07), Vector3(x, half.y, -half.z), DARK)
		if x > 0.0:
			_hide.append(post)
	for y: float in [0.035, CELL.y - 0.035]:
		Clay.box(self, Vector3(CELL.x, 0.07, 0.07), Vector3(0, y, -half.z), DARK)
	# La silla.
	Clay.cylinder(self, 0.08, 0.36, Vector3(0, 0.18, 0.45), DARK)
	Clay.box(self, Vector3(0.5, 0.1, 0.5), Vector3(0, 0.42, 0.45), STEEL)
	Clay.box(self, Vector3(0.5, 0.75, 0.1), Vector3(0, 0.82, 0.7), STEEL)
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.07, 0.05, 0.36), Vector3(side * 0.28, 0.66, 0.5), DARK)


func _glow(color: Color, energy := 1.8) -> StandardMaterial3D:
	var made := StandardMaterial3D.new()
	made.albedo_color = color
	made.emission_enabled = true
	made.emission = color
	made.emission_energy_multiplier = energy
	return made


## Un eslabón: un tubo entre dos puntos.
func _link(from: Vector3, to: Vector3, radius: float, color := LINK, parent: Node3D = null) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = from.distance_to(to)
	mesh.radial_segments = 12
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = Clay.material(color)
	(parent if parent != null else self).add_child(piece)
	var up := (to - from).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	piece.transform = Transform3D(Basis(side, up, side.cross(up)).orthonormalized(), (from + to) * 0.5)


## UN BRAZO ARTICULADO: de una placa en la pared, por sus codos, hasta el módulo. Cada codo, una rótula.
func _arm(points: Array[Vector3], radius := 0.028) -> void:
	var base: Vector3 = points[0]
	Clay.box(self, Vector3(0.14, 0.14, 0.03), base, DARK)
	for k in points.size() - 1:
		_link(points[k], points[k + 1], radius)
		Clay.sphere(self, radius * 1.7, points[k + 1], JOINT)
	Clay.sphere(self, radius * 1.7, base, JOINT)


## UN BRAZO DESDE EL PISO, en una esquina de adelante: una columna que sube pegada al vidrio y un codo que lleva el
## cubo hacia la silla, tomado por detrás.
func _floor_arm(foot: Vector3, to: Vector3) -> void:
	Clay.cylinder(self, 0.09, 0.04, foot + Vector3(0, 0.02, 0), DARK)
	var top := Vector3(foot.x, to.y - 0.12, foot.z)
	_link(foot, top, 0.035, STEEL)
	Clay.sphere(self, 0.055, top, JOINT)
	var elbow := top.lerp(to, 0.5) + Vector3(0, 0.08, 0)
	_link(top, elbow, 0.028)
	Clay.sphere(self, 0.045, elbow, JOINT)
	_link(elbow, to, 0.028)
	Clay.sphere(self, 0.045, to, JOINT)


## El punto detrás de un módulo en `at` (del lado contrario a los ojos), donde se toma su brazo.
func _behind(at: Vector3, depth: float) -> Vector3:
	return at + (at - EYE).normalized() * depth


## Un módulo en `at` que mira a los ojos: su +Z hacia quien está sentado.
func _facing(at: Vector3) -> Node3D:
	var spot := Node3D.new()
	add_child(spot)
	spot.position = at
	spot.look_at(EYE, Vector3.UP)
	spot.rotate_object_local(Vector3.UP, PI)
	return spot


func _lamp(parent: Node3D, at: Vector3, on: bool, radius := 0.014) -> void:
	var lamp := Clay.sphere(parent, radius, at, AMBER if on else OFF)
	if on:
		lamp.material_override = _glow(AMBER)


func _lights(parent: Node3D, at: Vector3, count: int, lit: int, color: Color, cell := Vector2(0.022, 0.03)) -> void:
	var step := cell.x + 0.006
	var length := count * step + 0.012
	Clay.box(parent, Vector3(length, cell.y + 0.012, 0.008), at, INK)
	for k in count:
		var piece := Clay.box(parent, Vector3(cell.x, cell.y, 0.004), at + Vector3(-length * 0.5 + 0.006 + step * (k + 0.5), 0, 0.005),
			Color(color.r * 0.18, color.g * 0.18, color.b * 0.18))
		if k < lit:
			piece.material_override = _glow(color)


func _text(parent: Node3D, text: String, at: Vector3, height: float, color := INK) -> void:
	var label := StrokeLabel.make(text, height, color)
	label.position = at
	parent.add_child(label)


# ── EL MANDO DEL CAÑÓN: lo principal, grande y al centro ─────────────────────────────────────────────────────────
func _main_control() -> void:
	# El pie: sale del piso adelante, entre los pies, y sube hasta la altura de las manos.
	Clay.cylinder(self, 0.16, 0.05, Vector3(0, 0.025, -0.5), DARK)
	_link(Vector3(0, 0.05, -0.5), Vector3(0, 0.62, -0.42), 0.07, STEEL)
	Clay.sphere(self, 0.1, Vector3(0, 0.62, -0.42), JOINT)
	_link(Vector3(0, 0.62, -0.42), Vector3(0, 0.78, -0.2), 0.06, STEEL)
	# El cuerpo del mando, que mira a quien está sentado, con su franja amarilla.
	var body := _facing(Vector3(0, 0.84, -0.17))
	Clay.box(body, Vector3(0.5, 0.17, 0.2), Vector3.ZERO, DARK)
	Clay.box(body, Vector3(0.5, 0.025, 0.205), Vector3(0, -0.06, 0.0), ACCENT)
	# La energía, la munición del cañón: una tira fina y apagada en el canto de arriba, siempre a la vista pero sin gritar.
	var strip := Node3D.new()
	body.add_child(strip)
	strip.position = Vector3(0, 0.066, 0.103)
	for k in 16:
		var piece := Clay.box(strip, Vector3(0.016, 0.01, 0.004), Vector3(-0.135 + k * 0.018, 0, 0), Color(0.06, 0.14, 0.08))
		if k < 11:
			piece.material_override = _glow(GREEN, 0.6)
	# Las dos empuñaduras, a los costados, con el gatillo rojo arriba (el clic derecho).
	for side: float in [-1.0, 1.0]:
		Clay.box(body, Vector3(0.05, 0.08, 0.08), Vector3(side * 0.27, 0.0, 0.0), JOINT)
		var handle := Clay.cylinder(body, 0.032, 0.17, Vector3(side * 0.3, 0.1, 0.02), INK)
		handle.rotation_degrees = Vector3(-14, 0, 0)
		for k in 3:
			Clay.cylinder(body, 0.034, 0.012, Vector3(side * 0.3, 0.05 + k * 0.035, 0.02 - k * 0.008), JOINT)
		Clay.box(body, Vector3(0.05, 0.025, 0.06), Vector3(side * 0.3, 0.19, 0.0), RED)
	Clay.box(body, Vector3(0.24, 0.05, 0.004), Vector3(0, 0.015, 0.102), INK)
	_text(body, "CAÑÓN", Vector3(0, 0.015, 0.106), 0.026, CREAM)


# ── LOS CUBOS EN SUS BRAZOS ──────────────────────────────────────────────────────────────────────────────────────
## Un cubo de módulo: chapa, con su cara de trabajo hacia quien está sentado.
func _cube(at: Vector3, size: Vector3) -> Node3D:
	var cube := _facing(at)
	Clay.box(cube, size, Vector3(0, 0, -size.z * 0.5), STEEL)
	Clay.box(cube, Vector3(size.x + 0.01, size.y + 0.01, 0.01), Vector3(0, 0, -size.z + 0.005), DARK)
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			Clay.cylinder(cube, 0.007, 0.006, Vector3(sx * (size.x * 0.5 - 0.016), sy * (size.y * 0.5 - 0.016), 0.002), LINK,
				Vector3(90, 0, 0))
	return cube


## LOS MODOS, a la izquierda: un cubo con tres botones grandes; ráfaga se traba (puesta), barrido y súper se cargan.
func _modes_cube() -> void:
	var at := Vector3(-0.47, 1.08, -0.22)
	_floor_arm(Vector3(-0.55, 0.0, -0.62), _behind(at, 0.13))
	var cube := _cube(at, Vector3(0.3, 0.24, 0.14))
	Clay.box(cube, Vector3(0.3, 0.045, 0.004), Vector3(0, 0.098, 0.002), INK)
	_text(cube, "MODO", Vector3(0, 0.098, 0.005), 0.018, CREAM)
	# Botones grandes que se prenden, con el nombre adentro: ráfaga se traba (prendida mientras tira); barrido y súper se
	# cargan mientras se los aprieta, con su barra abajo (el súper sale más fuerte cuanto más se lo carga).
	var names := ["RÁFAGA", "BARRIDO", "SÚPER"]
	var lit := [true, false, true]
	for k in names.size():
		var x := -0.093 + k * 0.093
		var on: bool = lit[k]
		Clay.box(cube, Vector3(0.086, 0.1, 0.012), Vector3(x, 0.0, 0.004), DARK)
		var cap := Clay.box(cube, Vector3(0.076, 0.09, 0.012 if k == 0 else 0.024), Vector3(x, 0.0, 0.012 if k == 0 else 0.018),
			CREAM)
		cap.material_override = _glow(Color(1.0, 0.82, 0.5), 1.2) if on else Clay.material(Color(0.55, 0.5, 0.42))
		var depth := 0.019 if k == 0 else 0.031
		var name_label := StrokeLabel.make(names[k], 0.012, INK)
		name_label.max_width = 0.068
		name_label.position = Vector3(x, 0.0, depth)
		cube.add_child(name_label)
		if k > 0:
			_lights(cube, Vector3(x, -0.076, 0.004), 5, 3 if k == 2 else 0, AMBER, Vector2(0.012, 0.012))


## EL ESTADO, a la derecha: un cubo con la pantalla de la meca de frente (formas llenas).
func _status_cube() -> void:
	var at := Vector3(0.47, 1.12, -0.22)
	_floor_arm(Vector3(0.55, 0.0, -0.62), _behind(at, 0.15))
	var cube := _cube(at, Vector3(0.3, 0.28, 0.16))
	var drawing: Control = STATUS._StatusDrawing.new()
	var view := SubViewport.new()
	view.size = Vector2i(360, 330)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	drawing.size = Vector2(view.size)
	view.add_child(drawing)
	cube.add_child(view)
	var sheet := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(0.26, 0.24)
	sheet.mesh = quad
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_texture = view.get_texture()
	sheet.material_override = look
	sheet.position = Vector3(0, 0, 0.003)
	cube.add_child(sheet)


## EYECTAR: una manija rayada que cuelga del techo, adelante a la derecha, fuera del camino de la vista.
func _eject() -> void:
	var at := Vector3(0.38, 1.78, -0.45)
	for dx: float in [-0.09, 0.09]:
		_link(Vector3(at.x + dx, CELL.y, at.z), Vector3(at.x + dx, at.y + 0.02, at.z), 0.006, INK)
	for k in 6:
		Clay.box(self, Vector3(0.04, 0.04, 0.04), Vector3(at.x - 0.1 + k * 0.04, at.y, at.z), ACCENT if k % 2 else INK)
	var tag := StrokeLabel.make("EYECTAR", 0.022, CREAM)
	tag.position = Vector3(at.x, at.y - 0.06, at.z + 0.02)
	add_child(tag)
	Clay.box(self, Vector3(0.16, 0.035, 0.005), Vector3(at.x, at.y - 0.06, at.z + 0.015), INK)


# ── ALGUIEN SENTADO (para las cortadas) ──────────────────────────────────────────────────────────────────────────
func _sit_person() -> void:
	_person = Node3D.new()
	add_child(_person)
	var suit := Color(0.32, 0.36, 0.42)
	var skin := Color(0.78, 0.62, 0.5)
	Clay.box(_person, Vector3(0.34, 0.48, 0.22), Vector3(0, 0.72, 0.56), suit)
	Clay.sphere(_person, 0.11, Vector3(0, 1.08, 0.5), skin)
	for side: float in [-1.0, 1.0]:
		Clay.box(_person, Vector3(0.13, 0.13, 0.42), Vector3(side * 0.1, 0.5, 0.32), suit)
		Clay.box(_person, Vector3(0.12, 0.42, 0.12), Vector3(side * 0.1, 0.27, 0.12), suit)
		# Los brazos, a las empuñaduras del mando.
		var shoulder := Vector3(side * 0.2, 0.92, 0.55)
		var hand := Vector3(side * 0.29, 0.95, -0.12)
		var elbow := Vector3(side * 0.27, 0.78, 0.25)
		_link(shoulder, elbow, 0.045, suit, _person)
		_link(elbow, hand, 0.04, suit, _person)
		Clay.sphere(_person, 0.045, hand, skin)


func _from(eye: Vector3, target: Vector3) -> void:
	_eye.global_position = eye
	_eye.look_at(target, Vector3.UP)


func _shot(title: String, file_name: String) -> void:
	_title.text = title
	for i in 6:
		await get_tree().process_frame
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
