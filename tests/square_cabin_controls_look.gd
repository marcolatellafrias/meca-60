extends Node3D

## LOS CONTROLES EN LAS CABINAS CUADRADAS Y EN LA CÚPULA (15/11/2026, sesión Tableros). La meca cuadrada de la otra
## sesión (tests/square_niches_look, la 44 en adelante): tres cabinas de uno adelante, de 1,4 de ancho, 2 de alto y 1,6
## de fondo, con vidrio al frente y entre ellas; arriba, una cúpula para el que mueve. Alternativas numeradas:
##   1 a 5 · la cabina del brazo izquierdo (el cañón: apuntar, ráfaga, barrido, súper, la energía, el estado,
##           eyectar), con los controles puestos de cinco maneras;
##   6 a 8 · la cúpula del movimiento (caminar, el dash en ocho direcciones, saltar, levitar, agacharse, el ascensor).
## Cada una: desde los ojos de quien va sentado y cortada desde afuera.
##   tools/godot_ventana.sh res://tests/square_cabin_controls_look.tscn -- --salida=C:/carpeta

const CELL := Vector3(1.4, 2.0, 1.6)
const EYE := Vector3(0, 1.15, 0.3)
const SPACING := 14.0

const STEEL := Color(0.36, 0.37, 0.39)
const WALL := Color(0.27, 0.28, 0.29)
const DARK := Color(0.13, 0.13, 0.14)
const LIGHT := Color(0.62, 0.64, 0.66)
const CREAM := Color(0.86, 0.83, 0.74)
const INK := Color(0.08, 0.08, 0.08)
const GREEN := Color(0.35, 1.0, 0.45)
const SCREEN := Color(0.03, 0.07, 0.04)
const AMBER := Color(1.0, 0.6, 0.18)
const OFF := Color(0.3, 0.22, 0.14)
const RED := Color(0.85, 0.15, 0.12)
const GLASS := Color(0.7, 0.82, 0.86, 0.14)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
## Lo que hay que esconder para la vista cortada (la pared del costado cercano y el techo) de cada alternativa.
var _cutaway: Array[Array] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	_world()
	_eye = Camera3D.new()
	_eye.fov = 88.0
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
	var names := [
		"1. Consola en U, baja: todo a la altura de las rodillas, el vidrio libre",
		"2. Apoyabrazos y techo: la empuñadura en el brazo, los modos y pantallas arriba",
		"3. Columnas en las esquinas de adelante: cada una con lo suyo",
		"4. Todo en la silla: dos consolas en los apoyabrazos y una pantalla colgada",
		"5. La pared de atrás: la silla gira para usarla, adelante sólo la empuñadura",
		"6. Cúpula: un aro a la cintura, el dash en ocho botones en su dirección de verdad",
		"7. Cúpula: dos palancas en los apoyabrazos, pedales para saltar y levitar",
		"8. Cúpula: un manubrio con el dash en el centro y la palanca de agacharse",
	]
	var builders := [_u_desk, _armrest_roof, _corner_columns, _chair_consoles, _back_wall, _dome_ring, _dome_sticks, _dome_yoke]
	for i in builders.size():
		var root := Node3D.new()
		root.position = Vector3(i * SPACING, 0, 0)
		add_child(root)
		var hide: Array = []
		if i < 5:
			hide = _cabin(root)
		else:
			hide = _dome(root)
		builders[i].call(root)
		_cutaway.append(hide)
	await get_tree().process_frame
	for i in builders.size():
		var origin := Vector3(i * SPACING, 0, 0)
		var dome := i >= 5
		var eye := origin + (Vector3(0, 1.25, 0.05) if dome else EYE)
		if i == 4:
			# La 5: la silla girada hacia la pared de atrás.
			eye = origin + Vector3(0, 1.2, 0.1)
		_eye.global_position = eye
		var looks := [Vector3(0, -0.6, -1), Vector3(0, 0.45, -1), Vector3(0, -0.25, -1), Vector3(0, -1.3, -0.7),
			Vector3(0.0, -0.15, 1.0), Vector3(0, -0.55, -1), Vector3(0, -0.85, -1), Vector3(0, -0.6, -1)]
		_eye.look_at(eye + looks[i], Vector3.UP)
		await _shot(names[i] + " · desde la silla", "%d_a" % (i + 1))
		for piece: Node3D in _cutaway[i]:
			piece.visible = false
		_eye.global_position = origin + (Vector3(1.5, 2.1, -1.5) if dome else Vector3(1.35, 1.65, -1.25))
		_eye.look_at(origin + Vector3(0, 0.95, 0.1), Vector3.UP)
		await _shot(names[i] + " · cortada", "%d_b" % (i + 1))
		for piece: Node3D in _cutaway[i]:
			piece.visible = true
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
	Clay.box(self, Vector3(400, 1, 400), Vector3(60, -6.5, 0), Color(0.44, 0.41, 0.37))
	for i in 8:
		var boss := Color(0.2, 0.19, 0.2)
		Clay.box(self, Vector3(6, 7, 4), Vector3(i * SPACING + 3, 2, -34), boss)
		Clay.box(self, Vector3(3, 0.5, 0.3), Vector3(i * SPACING + 3, 3.5, -31.9), AMBER)


# ── LA CABINA CUADRADA: piso, techo y pared de atrás macizos; vidrio adelante y a los costados ──────────────────
## Devuelve lo que se esconde para cortarla (la pared del costado derecho, el techo).
func _cabin(root: Node3D) -> Array:
	var half := CELL * 0.5
	Clay.box(root, Vector3(CELL.x + 0.2, 0.1, CELL.z + 0.2), Vector3(0, -0.05, 0), WALL)
	var roof := Clay.box(root, Vector3(CELL.x + 0.2, 0.12, CELL.z + 0.2), Vector3(0, CELL.y + 0.06, 0), WALL)
	Clay.box(root, Vector3(CELL.x + 0.2, CELL.y, 0.1), Vector3(0, half.y, half.z + 0.05), WALL)
	# El vidrio: adelante y a los costados, con su marco.
	Clay.box(root, Vector3(CELL.x, CELL.y, 0.02), Vector3(0, half.y, -half.z), GLASS)
	var right := Clay.box(root, Vector3(0.02, CELL.y, CELL.z), Vector3(half.x, half.y, 0), GLASS)
	Clay.box(root, Vector3(0.02, CELL.y, CELL.z), Vector3(-half.x, half.y, 0), GLASS)
	var hide: Array = [roof, right]
	for x: float in [-half.x, half.x]:
		var post := Clay.box(root, Vector3(0.08, CELL.y, 0.08), Vector3(x, half.y, -half.z), DARK)
		if x > 0.0:
			hide.append(post)
	for y: float in [0.04, CELL.y - 0.04]:
		Clay.box(root, Vector3(CELL.x, 0.08, 0.08), Vector3(0, y, -half.z), DARK)
	# El canto donde la cabina se mete en la caja maciza, atrás.
	Clay.box(root, Vector3(CELL.x + 0.2, 0.06, 0.06), Vector3(0, CELL.y, half.z), DARK)
	_seat(root)
	return hide


func _seat(root: Node3D, armrests := true) -> Node3D:
	var seat := Node3D.new()
	seat.position = Vector3(0, 0, 0.45)
	root.add_child(seat)
	Clay.cylinder(seat, 0.08, 0.36, Vector3(0, 0.18, 0), DARK)
	Clay.box(seat, Vector3(0.5, 0.1, 0.5), Vector3(0, 0.42, 0), STEEL)
	Clay.box(seat, Vector3(0.5, 0.75, 0.1), Vector3(0, 0.82, 0.25), STEEL)
	if armrests:
		for side: float in [-1.0, 1.0]:
			Clay.box(seat, Vector3(0.08, 0.06, 0.42), Vector3(side * 0.29, 0.66, -0.02), DARK)
	return seat


# ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────
## Un panel que mira hacia `toward`, con su color, y lo que va encima se cuelga de él (su +Z mira a quien está sentado).
func _panel(root: Node3D, at: Vector3, size: Vector2, toward: Vector3) -> Node3D:
	var spot := Node3D.new()
	root.add_child(spot)
	spot.position = at
	spot.look_at(root.to_global(toward), Vector3.UP if absf((toward - at).normalized().y) < 0.95 else Vector3.FORWARD)
	spot.rotate_object_local(Vector3.UP, PI)
	Clay.box(spot, Vector3(size.x, size.y, 0.04), Vector3(0, 0, -0.02), STEEL)
	Clay.box(spot, Vector3(size.x + 0.02, size.y + 0.02, 0.02), Vector3(0, 0, -0.035), DARK)
	return spot


func _label(parent: Node3D, text: String, at: Vector3, height := 0.018, color := INK) -> void:
	var label := StrokeLabel.make(text, height, color)
	label.position = at + Vector3(0, 0, 0.003)
	parent.add_child(label)


func _glow(color: Color) -> StandardMaterial3D:
	var made := StandardMaterial3D.new()
	made.albedo_color = color
	made.emission_enabled = true
	made.emission = color
	made.emission_energy_multiplier = 1.8
	return made


func _lamp(parent: Node3D, at: Vector3, on: bool) -> void:
	var lamp := Clay.sphere(parent, 0.013, at, AMBER if on else OFF)
	if on:
		lamp.material_override = _glow(AMBER)


## Un botón cuadrado que se traba (hundido si está puesto) o uno de apretar.
func _key(parent: Node3D, at: Vector3, text: String, on := false, lamp := true) -> void:
	Clay.box(parent, Vector3(0.075, 0.06, 0.012), at, DARK)
	Clay.box(parent, Vector3(0.062, 0.048, 0.012 if on else 0.028), at + Vector3(0, 0, 0.01 if on else 0.018), INK if on else CREAM)
	if lamp:
		_lamp(parent, at + Vector3(0, 0.05, 0.006), on)
	_label(parent, text, at + Vector3(0, -0.045, 0.004), 0.013)


## Una fila de luces: `lit` de `count` prendidas.
func _lights(parent: Node3D, at: Vector3, count: int, lit: int, color: Color, vertical := false) -> void:
	var step := 0.022
	var length := count * step + 0.012
	Clay.box(parent, Vector3(0.02 if vertical else length, length if vertical else 0.02, 0.008) + Vector3(0.012, 0.012, 0), at, INK)
	for k in count:
		var offset := -length * 0.5 + 0.006 + step * (k + 0.5)
		var place := at + (Vector3(0, offset, 0.005) if vertical else Vector3(offset, 0, 0.005))
		var cell := Clay.box(parent, Vector3(0.016, 0.016, 0.004) if true else Vector3.ONE, place, Color(color.r * 0.2, color.g * 0.2, color.b * 0.2))
		if k < lit:
			cell.material_override = _glow(color)


## Una pantalla de fósforo con la meca de frente, en formas llenas, simplificada.
func _status(parent: Node3D, at: Vector3, size: Vector2) -> void:
	Clay.box(parent, Vector3(size.x, size.y, 0.008), at, SCREEN)
	var s := size.y / 0.2
	var parts := [[Vector2(0, 0.06), Vector2(0.05, 0.05)], [Vector2(0, 0.0), Vector2(0.07, 0.06)], [Vector2(-0.055, 0.01), Vector2(0.025, 0.07)],
		[Vector2(0.055, 0.01), Vector2(0.025, 0.07)], [Vector2(-0.02, -0.065), Vector2(0.025, 0.06)], [Vector2(0.02, -0.065), Vector2(0.025, 0.06)]]
	for k in parts.size():
		var part: Array = parts[k]
		var piece := Clay.box(parent, Vector3(part[1].x * s, part[1].y * s, 0.004), at + Vector3(part[0].x * s, part[0].y * s, 0.006), GREEN)
		piece.material_override = _glow(AMBER if k == 5 else Color(0.25, 0.85, 0.4))


## La empuñadura del cañón: un mango con el botón rojo arriba.
func _grip(parent: Node3D, at: Vector3) -> void:
	Clay.cylinder(parent, 0.05, 0.03, at, DARK)
	var handle := Clay.box(parent, Vector3(0.045, 0.13, 0.055), at + Vector3(0, 0.07, 0), INK)
	handle.rotation_degrees = Vector3(-12, 0, 0)
	Clay.box(parent, Vector3(0.055, 0.03, 0.065), at + Vector3(0, 0.145, -0.015), RED)


## Los modos del cañón, en una tira: ráfaga (se traba, puesta), barrido y súper (se cargan), con su carga.
func _modes(parent: Node3D, at: Vector3, vertical := false) -> void:
	var names := ["RÁFAGA", "BARRIDO", "SÚPER"]
	for k in names.size():
		var spot := at + (Vector3(0, 0.1 - k * 0.1, 0) if vertical else Vector3(-0.09 + k * 0.09, 0, 0))
		_key(parent, spot, names[k], k == 0)
	_label(parent, "CAÑÓN", at + (Vector3(0, 0.19, 0) if vertical else Vector3(0, 0.075, 0)), 0.016)


func _eject(parent: Node3D, at: Vector3) -> void:
	for dx: float in [-0.08, 0.08]:
		Clay.box(parent, Vector3(0.008, 0.14, 0.008), at + Vector3(dx, 0.07, 0), INK)
	for k in 5:
		Clay.box(parent, Vector3(0.04, 0.035, 0.035), at + Vector3(-0.08 + k * 0.04, 0, 0), Clay.YELLOW if k % 2 else INK)


# ── 1 A 5: LA CABINA DEL CAÑÓN ───────────────────────────────────────────────────────────────────────────────────
## 1. Una consola en U, baja: a la altura de las rodillas, por adelante y a los costados; arriba, todo vidrio.
func _u_desk(root: Node3D) -> void:
	var top := 0.72
	Clay.box(root, Vector3(1.3, top, 0.3), Vector3(0, top * 0.5, -0.62), WALL)
	for side: float in [-1.0, 1.0]:
		Clay.box(root, Vector3(0.26, top, 0.7), Vector3(side * 0.56, top * 0.5, -0.2), WALL)
	var front := _panel(root, Vector3(0, top + 0.02, -0.62), Vector2(1.2, 0.26), EYE + Vector3(0, 0.3, 0))
	_grip(front, Vector3(-0.12, 0, 0.03))
	_lights(front, Vector3(0.2, 0.05, 0.02), 12, 8, GREEN)
	_label(front, "ENERGÍA", Vector3(0.2, -0.03, 0.02), 0.014)
	var left := _panel(root, Vector3(-0.56, top + 0.02, -0.2), Vector2(0.24, 0.6), EYE + Vector3(0, 0.3, 0))
	_modes(left, Vector3(0, 0.0, 0.02), true)
	var right := _panel(root, Vector3(0.56, top + 0.02, -0.2), Vector2(0.24, 0.6), EYE + Vector3(0, 0.3, 0))
	_status(right, Vector3(0, 0.05, 0.02), Vector2(0.2, 0.22))
	_eject(root, Vector3(0.4, CELL.y - 0.25, -0.3))


## 2. La empuñadura en el apoyabrazos; los modos, la energía y el estado en un panel que baja del techo, adelante.
func _armrest_roof(root: Node3D) -> void:
	_grip(root, Vector3(-0.29, 0.69, 0.32))
	var roof := _panel(root, Vector3(0, CELL.y - 0.2, -0.55), Vector2(1.2, 0.3), EYE)
	_modes(roof, Vector3(-0.38, -0.02, 0.02))
	_status(roof, Vector3(0.05, 0.0, 0.02), Vector2(0.24, 0.22))
	_lights(roof, Vector3(0.38, 0.03, 0.02), 10, 7, GREEN)
	_label(roof, "ENERGÍA", Vector3(0.38, -0.04, 0.02), 0.014)
	Clay.box(root, Vector3(1.2, 0.2, 0.06), Vector3(0, CELL.y - 0.08, -0.58), DARK)
	_eject(root, Vector3(0.0, CELL.y - 0.42, -0.1))


## 3. Dos columnas en las esquinas de adelante: la izquierda con los modos, la derecha con el estado y la energía;
## al medio, un pedestal bajo con la empuñadura.
func _corner_columns(root: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		Clay.box(root, Vector3(0.26, CELL.y, 0.26), Vector3(side * 0.56, CELL.y * 0.5, -0.66), WALL)
	var left := _panel(root, Vector3(-0.5, 1.05, -0.55), Vector2(0.22, 0.5), EYE)
	_modes(left, Vector3(0, -0.02, 0.02), true)
	var right := _panel(root, Vector3(0.5, 1.05, -0.55), Vector2(0.22, 0.5), EYE)
	_status(right, Vector3(0, 0.1, 0.02), Vector2(0.18, 0.18))
	_lights(right, Vector3(0, -0.12, 0.02), 8, 6, GREEN)
	_label(right, "ENERGÍA", Vector3(0, -0.16, 0.02), 0.013)
	Clay.box(root, Vector3(0.18, 0.66, 0.18), Vector3(0, 0.33, -0.25), WALL)
	_grip(root, Vector3(0, 0.68, -0.25))
	_eject(root, Vector3(0.3, CELL.y - 0.25, -0.2))


## 4. Todo en la silla: dos consolas sobre los apoyabrazos (los modos a la izquierda, la empuñadura y la energía a la
## derecha... la del cañón va a la izquierda) y una pantalla en un brazo que cuelga del respaldo.
func _chair_consoles(root: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		Clay.box(root, Vector3(0.18, 0.1, 0.48), Vector3(side * 0.36, 0.72, 0.3), WALL)
	_grip(root, Vector3(-0.36, 0.77, 0.18))
	var left := _panel(root, Vector3(-0.36, 0.78, 0.38), Vector2(0.16, 0.2), Vector3(-0.36, 2.0, 0.38))
	_lamp(left, Vector3(0, 0.0, 0.03), true)
	var right := _panel(root, Vector3(0.36, 0.79, 0.3), Vector2(0.16, 0.4), Vector3(0.36, 2.0, 0.32))
	_modes(right, Vector3(0, 0.0, 0.02), true)
	# El brazo con la pantalla, desde el respaldo, por encima del hombro derecho.
	Clay.box(root, Vector3(0.04, 0.5, 0.04), Vector3(0.3, 1.35, 0.68), DARK)
	Clay.box(root, Vector3(0.04, 0.04, 0.5), Vector3(0.3, 1.6, 0.45), DARK)
	var screen := _panel(root, Vector3(0.3, 1.45, 0.05), Vector2(0.26, 0.24), EYE)
	_status(screen, Vector3(0, 0.02, 0.02), Vector2(0.2, 0.17))
	_lights(screen, Vector3(0, -0.095, 0.02), 9, 6, GREEN)
	_eject(root, Vector3(0.0, CELL.y - 0.25, -0.2))


## 5. La pared de atrás llena: los modos, el estado y la energía; la silla gira para usarla. Adelante sólo la empuñadura.
func _back_wall(root: Node3D) -> void:
	var wall := _panel(root, Vector3(0, 1.1, CELL.z * 0.5 - 0.02), Vector2(1.2, 0.8), Vector3(0, 1.1, -2.0))
	_modes(wall, Vector3(-0.35, 0.0, 0.02), true)
	_status(wall, Vector3(0.1, 0.1, 0.02), Vector2(0.34, 0.32))
	_lights(wall, Vector3(0.1, -0.22, 0.02), 14, 9, GREEN)
	_label(wall, "ENERGÍA", Vector3(0.1, -0.27, 0.02), 0.016)
	_eject(wall, Vector3(0.42, 0.2, 0.06))
	Clay.box(root, Vector3(0.16, 0.7, 0.16), Vector3(0, 0.35, -0.3), WALL)
	_grip(root, Vector3(0, 0.72, -0.3))
	# La silla, girada hacia la pared (para la foto).
	for child in root.get_children():
		if child is Node3D and not (child is MeshInstance3D) and (child as Node3D).position.is_equal_approx(Vector3(0, 0, 0.45)):
			(child as Node3D).rotation_degrees.y = 180.0
	# Una tira de luces adelante, para no tener que darse vuelta a mirar la energía.
	_lights(root, Vector3(0, 0.05, -CELL.z * 0.5 + 0.03), 14, 9, GREEN)


# ── 6 A 8: LA CÚPULA DEL MOVIMIENTO ──────────────────────────────────────────────────────────────────────────────
## La cúpula: un anillo bajo de chapa y arriba media esfera de vidrio en paños. Devuelve lo que se esconde al cortarla.
func _dome(root: Node3D) -> Array:
	Clay.cylinder(root, 1.05, 0.5, Vector3(0, 0.25, 0), WALL)
	Clay.cylinder(root, 1.1, 0.06, Vector3(0, 0.5, 0), DARK)
	var glass := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = 1.05
	ball.height = 2.1
	ball.is_hemisphere = true
	glass.mesh = ball
	glass.material_override = Clay.material(GLASS)
	glass.position = Vector3(0, 0.5, 0)
	root.add_child(glass)
	var ribs: Array = [glass]
	for k in 4:
		var rib := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = 1.03
		torus.outer_radius = 1.07
		rib.mesh = torus
		rib.material_override = Clay.material(DARK)
		rib.position = Vector3(0, 0.5, 0)
		rib.rotation_degrees = Vector3(90, k * 45.0, 0)
		root.add_child(rib)
		ribs.append(rib)
	var seat := _seat(root)
	seat.position = Vector3(0, 0.5, 0.25)
	return ribs


## 6. Un aro a la altura de la cintura alrededor de la silla: el dash en ocho botones, cada uno en su dirección de
## verdad; caminar con la palanca del apoyabrazos; saltar, levitar y agacharse en el aro, a mano.
func _dome_ring(root: Node3D) -> void:
	var height := 1.05
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.62
	torus.outer_radius = 0.78
	ring.mesh = torus
	ring.material_override = Clay.material(STEEL)
	ring.position = Vector3(0, height, 0.15)
	ring.scale = Vector3(1, 0.4, 1)
	root.add_child(ring)
	for k in 8:
		var angle := TAU * k / 8.0
		var at := Vector3(sin(angle) * -0.7, height + 0.05, 0.15 - cos(angle) * 0.7)
		if k == 4:
			continue
		var key := Clay.box(root, Vector3(0.07, 0.03, 0.07), at, AMBER if k == 1 else CREAM)
		key.rotation.y = angle
	_lights(root, Vector3(0, height + 0.08, -0.5), 12, 9, GREEN)
	_grip(root, Vector3(0.29, 1.19, 0.12))
	# Saltar y levitar (se aprietan) y agacharse (se traba), en el aro a la izquierda.
	for k in 3:
		Clay.cylinder(root, 0.035, 0.03, Vector3(-0.55, height + 0.06, -0.1 + k * 0.14), INK if k < 2 else CREAM)


## 7. Dos palancas en los apoyabrazos: la izquierda camina, la derecha gira; pedales a los pies para saltar y
## levitar; el dash en una rosa de ocho sobre un pedestal adelante.
func _dome_sticks(root: Node3D) -> void:
	for side: float in [-1.0, 1.0]:
		Clay.box(root, Vector3(0.16, 0.1, 0.44), Vector3(side * 0.36, 1.22, 0.22), WALL)
		_grip(root, Vector3(side * 0.36, 1.27, 0.1))
	for side: float in [-1.0, 1.0]:
		var pedal := Clay.box(root, Vector3(0.16, 0.04, 0.26), Vector3(side * 0.16, 0.6, -0.3), INK)
		pedal.rotation_degrees = Vector3(-20, 0, 0)
	Clay.box(root, Vector3(0.2, 0.55, 0.2), Vector3(0, 0.78, -0.55), WALL)
	var rose := _panel(root, Vector3(0, 1.08, -0.52), Vector2(0.3, 0.3), Vector3(0, 1.5, 0.05))
	for k in 8:
		var angle := TAU * k / 8.0
		_key(rose, Vector3(sin(angle) * 0.1, cos(angle) * 0.1, 0.02), "", k == 1, false)
	_lights(rose, Vector3(0, -0.13, 0.02), 10, 7, GREEN)


## 8. Un manubrio de dos manos (girar y caminar), con el dash en ocho botones en el centro; a los costados, los botones
## de saltar y levitar en las empuñaduras; agacharse con una palanca al costado del asiento.
func _dome_yoke(root: Node3D) -> void:
	Clay.box(root, Vector3(0.12, 0.6, 0.12), Vector3(0, 0.8, -0.45), WALL)
	var yoke := _panel(root, Vector3(0, 1.12, -0.42), Vector2(0.22, 0.16), Vector3(0, 1.5, 0.05))
	Clay.box(yoke, Vector3(0.6, 0.05, 0.05), Vector3(0, 0.0, 0.03), STEEL)
	for side: float in [-1.0, 1.0]:
		Clay.box(yoke, Vector3(0.06, 0.18, 0.06), Vector3(side * 0.3, 0.06, 0.04), INK)
		Clay.cylinder(yoke, 0.02, 0.02, Vector3(side * 0.3, 0.16, 0.05), RED if side < 0.0 else CREAM)
	for k in 8:
		var angle := TAU * k / 8.0
		Clay.box(yoke, Vector3(0.025, 0.025, 0.012), Vector3(sin(angle) * 0.055, cos(angle) * 0.055, 0.035), AMBER if k == 1 else CREAM)
	_lights(yoke, Vector3(0, -0.06, 0.03), 9, 6, GREEN)
	Clay.box(root, Vector3(0.04, 0.3, 0.04), Vector3(0.36, 0.95, 0.3), LIGHT)
	Clay.sphere(root, 0.04, Vector3(0.36, 1.1, 0.3), INK)


func _shot(title: String, file_name: String) -> void:
	_title.text = title
	for i in 6:
		await get_tree().process_frame
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
