extends Node3D

## LOS TRES TABLEROS EN ARCILLA, DE FRENTE Y SIN PERSPECTIVA (15/11/2026, sesión Tableros): el movimiento, el cañón y la
## espada, repensados desde cero con la regla del mouse (ver docs/conceptual/armamento.md, «El mouse, sentado»): una
## palanca se agarra manteniendo el clic izquierdo y el derecho es el gatillo rojo de su bocha. Una cámara ortogonal,
## apenas desde arriba para que se lean las tapas. Sólo para mirar: nada funciona.
##   tools/godot_ventana.sh res://tests/cockpit_clay_look.tscn -- --salida=C:/carpeta

const FRAME := Color(0.30, 0.31, 0.33)
const METAL := Color(0.50, 0.52, 0.54)
const LIGHT := Color(0.66, 0.68, 0.70)
const BLACK := Color(0.10, 0.10, 0.11)
const CREAM := Color(0.86, 0.83, 0.74)
const INK := Color(0.08, 0.08, 0.08)
const GREEN := Color(0.35, 1.0, 0.45)
const AMBER := Color(1.0, 0.62, 0.2)
const OFF := Color(0.32, 0.24, 0.16)
const TRIGGER := Color(0.85, 0.15, 0.12)
const GLASS := Color(0.75, 0.85, 0.88, 0.25)
const SPACING := 12.0

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48.0, -28.0, 0.0)
	sun.shadow_enabled = true
	sun.light_energy = 1.1
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.68, 0.66, 0.62)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.75, 0.75, 0.78)
	world.environment.ambient_light_energy = 0.7
	add_child(world)
	_eye = Camera3D.new()
	_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
	_eye.size = 2.8
	_eye.rotation_degrees = Vector3(-6.0, 0.0, 0.0)
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
	var cockpits: Array[Node3D] = [_movement(), _cannon(), _sword()]
	var names := ["1. Movimiento", "2. Cañón (brazo izquierdo)", "3. Espada (brazo derecho)"]
	for i in cockpits.size():
		cockpits[i].position.x = i * SPACING
	for i in cockpits.size():
		_eye.position = Vector3(i * SPACING, 0.2, 2.6)
		await _shot(names[i], str(i + 1))
	get_tree().quit()


# ── LO COMÚN: el mundo, el marco, la pared de instrumentos y la energía ─────────────────────────────────────────
## La pared de instrumentos: una cara vertical que mira al jugador, donde va todo lo que se toca y se lee.
const WALL_FRONT := 0.38
const WALL_TOP := -0.1
const WALL_BOTTOM := -0.95


func _cockpit(title: String, boss_x: float) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	Clay.box(root, Vector3(9, 0.1, 5), Vector3(0, -0.45, -4.5), Color(0.46, 0.43, 0.39))
	var heights := [0.9, 1.4, 0.7, 1.8, 1.1, 0.8, 1.6, 1.0, 1.3, 0.75]
	for k in heights.size():
		Clay.box(root, Vector3(0.62, heights[k], 0.5), Vector3(-3.0 + k * 0.66, -0.4 + heights[k] * 0.5, -7.0),
			Color(0.42, 0.42, 0.44))
	var boss := Node3D.new()
	root.add_child(boss)
	boss.position = Vector3(boss_x, -0.4, -5.0)
	boss.scale = Vector3.ONE * 0.6
	Clay.box(boss, Vector3(0.7, 0.8, 0.5), Vector3(0, 0.75, 0), Color(0.2, 0.19, 0.2))
	Clay.box(boss, Vector3(0.36, 0.06, 0.05), Vector3(0, 0.95, 0.26), AMBER)
	for side: float in [-1.0, 1.0]:
		Clay.box(boss, Vector3(0.14, 0.5, 0.3), Vector3(side * 0.44, 0.7, 0), Color(0.2, 0.19, 0.2))
		Clay.box(boss, Vector3(0.18, 0.36, 0.3), Vector3(side * 0.18, 0.18, 0), Color(0.2, 0.19, 0.2))
	for side: float in [-1.0, 1.0]:
		Clay.box(root, Vector3(0.3, 3.2, 0.34), Vector3(side * 1.9, 0.2, 0.2), FRAME)
		# El parante: un canto más claro hacia el vidrio y dos caños de cables que bajan, con sus abrazaderas.
		Clay.box(root, Vector3(0.03, 3.2, 0.35), Vector3(side * 1.76, 0.2, 0.2), METAL)
		for dx: float in [0.1, 0.14]:
			Clay.cylinder(root, 0.014, 3.0, Vector3(side * (1.9 + dx), 0.2, 0.38), BLACK)
		for y in [-0.55, 0.75, 1.0]:
			Clay.box(root, Vector3(0.1, 0.03, 0.06), Vector3(side * 2.02, y, 0.39), METAL)
		for y in [0.62, 0.98]:
			_rivet(root, Vector3(side * 1.84, y, 0.38))
			_rivet(root, Vector3(side * 1.96, y, 0.38))
	# La visera: oscura, con su canto, una fila de remaches y dos plafones a los lados del nombre.
	Clay.box(root, Vector3(4.4, 0.42, 0.6), Vector3(0, 1.3, 0.3), FRAME)
	Clay.box(root, Vector3(4.0, 0.05, 0.64), Vector3(0, 1.08, 0.32), METAL)
	for k in 15:
		_rivet(root, Vector3(-1.68 + k * 0.24, 1.14, 0.6))
	for x: float in [-0.62, 0.62]:
		Clay.cylinder(root, 0.07, 0.03, Vector3(x, 1.27, 0.6), METAL, Vector3(90, 0, 0))
		var dome := Clay.sphere(root, 0.055, Vector3(x, 1.27, 0.61), CREAM)
		dome.scale = Vector3(1, 1, 0.45)
		for g in 3:
			Clay.box(root, Vector3(0.12, 0.008, 0.01), Vector3(x, 1.245 + g * 0.025, 0.64), FRAME)
	_plaque(root, title, Vector3(0, 1.26, 0.61), 0.075)
	# La pared de instrumentos y, abajo, la consola donde van los pies.
	var tall := WALL_TOP - WALL_BOTTOM
	Clay.box(root, Vector3(4.4, tall, 0.3), Vector3(0, WALL_BOTTOM + tall * 0.5, WALL_FRONT - 0.15), METAL)
	Clay.box(root, Vector3(4.4, 0.04, 0.34), Vector3(0, WALL_TOP, WALL_FRONT - 0.15), LIGHT)
	Clay.box(root, Vector3(4.4, 0.6, 1.0), Vector3(0, WALL_BOTTOM - 0.3, 0.5), FRAME)
	# Las costuras de la chapa, la franja de peligro abajo, las rejillas y la placa del taller.
	for x: float in [-1.66, 1.66]:
		Clay.box(root, Vector3(0.012, WALL_TOP - WALL_BOTTOM, 0.01), Vector3(x, (WALL_TOP + WALL_BOTTOM) * 0.5, WALL_FRONT + 0.001), FRAME)
	for k in 44:
		var stripe := Clay.box(root, Vector3(0.05, 0.12, 0.01), Vector3(-2.15 + k * 0.1, WALL_BOTTOM - 0.06, 1.002),
			Clay.YELLOW if k % 2 else BLACK)
		stripe.rotation_degrees = Vector3(0, 0, 40)
	Clay.box(root, Vector3(4.4, 0.02, 0.02), Vector3(0, WALL_BOTTOM - 0.005, 1.0), FRAME)
	Clay.box(root, Vector3(4.4, 0.02, 0.02), Vector3(0, WALL_BOTTOM - 0.115, 1.0), FRAME)
	for side: float in [-1.0, 1.0]:
		for k in 6:
			Clay.box(root, Vector3(0.36, 0.014, 0.01), Vector3(side * 1.25, WALL_BOTTOM - 0.18 - k * 0.03, 1.002), BLACK)
	var maker := StrokeLabel.make("TALLERES NUEVOS AIRES", 0.022, INK)
	maker.position = Vector3(0, WALL_BOTTOM - 0.25, 1.014)
	root.add_child(maker)
	Clay.box(root, Vector3(0.42, 0.05, 0.01), Vector3(0, WALL_BOTTOM - 0.25, 1.006), CREAM)
	# La energía, común a todos: una barra de luces al medio de la pared.
	_zone(root, Vector2(0, -0.8), Vector2(1.0, 0.24), "")
	_lights(root, Vector3(0, -0.78, FACE), 20, 12, GREEN, "ENERGÍA", false)
	return root


## Una placa negra con el nombre en crema.
func _plaque(parent: Node3D, text: String, at: Vector3, height: float) -> void:
	var label := StrokeLabel.make(text, height, CREAM)
	label.position = at + Vector3(0, 0, 0.012)
	parent.add_child(label)
	var width := text.length() * height * 0.75 + height
	Clay.box(parent, Vector3(width, height * 1.8, 0.02), at, BLACK)


## UNA ZONA: una placa más oscura, apenas saliente, con su marco y su título arriba; lo que va junto, adentro.
const ZONE := Color(0.40, 0.42, 0.44)
const FACE := WALL_FRONT + 0.025


func _rivet(parent: Node3D, at: Vector3) -> void:
	Clay.cylinder(parent, 0.011, 0.012, at, LIGHT, Vector3(90, 0, 0))


func _zone(parent: Node3D, center: Vector2, size: Vector2, title: String, z := WALL_FRONT) -> void:
	Clay.box(parent, Vector3(size.x + 0.05, size.y + 0.05, 0.02), Vector3(center.x, center.y, z + 0.005), FRAME)
	Clay.box(parent, Vector3(size.x, size.y, 0.02), Vector3(center.x, center.y, z + 0.012), ZONE)
	Clay.box(parent, Vector3(size.x, 0.008, 0.022), Vector3(center.x, center.y - size.y * 0.5 + 0.004, z + 0.013), BLACK)
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			_rivet(parent, Vector3(center.x + sx * (size.x * 0.5 - 0.025), center.y + sy * (size.y * 0.5 - 0.025), z + 0.024))
	if title.is_empty():
		return
	Clay.box(parent, Vector3(size.x, 0.07, 0.01), Vector3(center.x, center.y + size.y * 0.5 - 0.035, z + 0.024), BLACK)
	var label := StrokeLabel.make(title, 0.034, CREAM)
	label.position = Vector3(center.x, center.y + size.y * 0.5 - 0.035, z + 0.03)
	parent.add_child(label)


func _glow(color: Color) -> StandardMaterial3D:
	var made := StandardMaterial3D.new()
	made.albedo_color = color
	made.emission_enabled = true
	made.emission = color
	made.emission_energy_multiplier = 1.6
	return made


func _lamp(parent: Node3D, at: Vector3, on: bool) -> void:
	Clay.cylinder(parent, 0.04, 0.02, at, FRAME, Vector3(90, 0, 0))
	var lamp := Clay.sphere(parent, 0.028, at + Vector3(0, 0, 0.015), AMBER if on else OFF)
	if on:
		lamp.material_override = _glow(AMBER)


## UNA BARRA DE LUCES en un marco: `count` celdas, `lit` prendidas; acostada o parada.
func _pillar_lights(parent: Node3D, x: float, lit: int, color: Color, title: String) -> void:
	_zone(parent, Vector2(x, 0.2), Vector2(0.24, 0.72), "", 0.37)
	_lights(parent, Vector3(x, 0.26, 0.4), 10, lit, color, title, true)


func _lights(parent: Node3D, at: Vector3, count: int, lit: int, color: Color, title: String, upright: bool) -> void:
	var cell := Vector2(0.05, 0.035) if upright else Vector2(0.035, 0.07)
	var step := (cell.y if upright else cell.x) + 0.012
	var length := count * step + 0.03
	var frame_size := Vector3(cell.x + 0.04, length, 0.03) if upright else Vector3(length, cell.y + 0.04, 0.03)
	Clay.box(parent, frame_size, at, BLACK)
	var dim := Color(color.r * 0.22, color.g * 0.22, color.b * 0.22)
	for k in count:
		var offset := -length * 0.5 + 0.015 + step * (k + 0.5)
		var place := at + (Vector3(0, offset, 0.018) if upright else Vector3(offset, 0, 0.018))
		var piece := Clay.box(parent, Vector3(cell.x, cell.y, 0.01), place, dim)
		if k < lit:
			piece.material_override = _glow(color)
	var below := (length if upright else cell.y + 0.04) * 0.5 + 0.05
	_plaque(parent, title, at + Vector3(0, -below, 0.01), 0.032)


## UN BOTÓN QUE SE TRABA: cuadrado, con su lamparita arriba; hundido y con la luz prendida si está puesto.
func _latch(parent: Node3D, at: Vector3, on: bool, title: String, size := Vector2(0.16, 0.11)) -> void:
	Clay.box(parent, Vector3(size.x + 0.04, size.y + 0.04, 0.02), at, FRAME)
	Clay.box(parent, Vector3(size.x, size.y, 0.03 if on else 0.06), at + Vector3(0, 0, 0.02 if on else 0.035), BLACK if on else CREAM)
	_lamp(parent, at + Vector3(0, size.y * 0.5 + 0.06, 0), on)
	var tag := StrokeLabel.make(title, 0.03, INK)
	tag.position = at + Vector3(0, -size.y * 0.5 - 0.05, 0.012)
	parent.add_child(tag)


## UN BOTÓN DE APRETAR (no se traba): redondo, con su aro.
func _push(parent: Node3D, at: Vector3, radius: float, cap: Color, title: String) -> void:
	Clay.cylinder(parent, radius + 0.02, 0.02, at, FRAME, Vector3(90, 0, 0))
	Clay.cylinder(parent, radius, 0.05, at + Vector3(0, 0, 0.03), cap, Vector3(90, 0, 0))
	if not title.is_empty():
		var tag := StrokeLabel.make(title, 0.03, INK)
		tag.position = at + Vector3(0, -radius - 0.05, 0.012)
		parent.add_child(tag)


## LA PALANCA DE DOS EJES, EN LA PARED: sale hacia el jugador, de una placa con su ranura en cruz; la bocha se corre
## hacia donde quedó (`lean`, de −1 a 1) y lleva el gatillo rojo arriba.
func _stick(parent: Node3D, at: Vector3, lean: Vector2, title: String, trigger: String) -> void:
	# El nombre lo pone la zona; acá, lo que hace el gatillo.
	Clay.box(parent, Vector3(0.36, 0.36, 0.03), at, FRAME)
	Clay.box(parent, Vector3(0.3, 0.3, 0.02), at + Vector3(0, 0, 0.02), BLACK)
	Clay.box(parent, Vector3(0.26, 0.02, 0.01), at + Vector3(0, 0, 0.032), METAL)
	Clay.box(parent, Vector3(0.02, 0.26, 0.01), at + Vector3(0, 0, 0.032), METAL)
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			_rivet(parent, at + Vector3(sx * 0.15, sy * 0.15, 0.03))
	# El fuelle de goma, en anillos.
	for k in 3:
		Clay.cylinder(parent, 0.085 - k * 0.015, 0.025, at + Vector3(0, 0, 0.045 + k * 0.025), Color(0.16, 0.16, 0.17), Vector3(90, 0, 0))
	var tip := at + Vector3(lean.x * 0.1, lean.y * 0.1, 0.28)
	var shaft := MeshInstance3D.new()
	shaft.mesh = BoxMesh.new()
	shaft.material_override = Clay.material(LIGHT)
	parent.add_child(shaft)
	Clay.segment(shaft, at + Vector3(0, 0, 0.05), tip, 0.04)
	Clay.sphere(parent, 0.075, tip, BLACK)
	Clay.box(parent, Vector3(0.04, 0.04, 0.04), tip + Vector3(0, 0.07, 0.0), TRIGGER)
	var tag := StrokeLabel.make("GATILLO", 0.026, INK)
	tag.position = at + Vector3(0.0, -0.33, 0.012)
	parent.add_child(tag)
	tag = StrokeLabel.make(trigger, 0.03, TRIGGER.darkened(0.3))
	tag.position = at + Vector3(0.0, -0.38, 0.012)
	parent.add_child(tag)


## UNA FLECHA en relieve, apuntando a `angle` (grados, 0 a la derecha).
func _arrow(parent: Node3D, at: Vector3, angle: float, color: Color) -> void:
	var holder := Node3D.new()
	parent.add_child(holder)
	holder.position = at
	holder.rotation_degrees = Vector3(0, 0, angle)
	Clay.box(holder, Vector3(0.04, 0.011, 0.008), Vector3(-0.004, 0, 0), color)
	for side: float in [-1.0, 1.0]:
		var head := Clay.box(holder, Vector3(0.026, 0.011, 0.008), Vector3(0.01, side * 0.008, 0), color)
		head.rotation_degrees = Vector3(0, 0, -side * 45.0)


## EL DASH: ocho botones cuadrados con su flecha, en tres por tres; al medio, la lamparita de listo.
func _dash_pad(parent: Node3D, at: Vector3, pressed: int) -> void:
	var k := 0
	for row in 3:
		for col in 3:
			var spot := at + Vector3((col - 1) * 0.115, (1 - row) * 0.115, 0)
			if row == 1 and col == 1:
				_lamp(parent, spot, true)
				continue
			var angle := rad_to_deg(atan2(1 - row, col - 1))
			var down := k == pressed
			Clay.box(parent, Vector3(0.1, 0.1, 0.02), spot, FRAME)
			Clay.box(parent, Vector3(0.085, 0.085, 0.02 if down else 0.04), spot + Vector3(0, 0, 0.015 if down else 0.025),
				AMBER if down else CREAM)
			_arrow(parent, spot + Vector3(0, 0, 0.05 if not down else 0.03), angle, INK)
			k += 1


## UNA MANIJA QUE CUELGA DE LA VISERA: dos cordones y una T rayada (eyectar: se tira una vez y no hay vuelta).
func _pull(parent: Node3D, x: float, title: String) -> void:
	for dx: float in [-0.12, 0.12]:
		Clay.box(parent, Vector3(0.015, 0.22, 0.015), Vector3(x + dx, 0.97, 0.45), BLACK)
	for k in 8:
		Clay.box(parent, Vector3(0.05, 0.07, 0.07), Vector3(x - 0.175 + k * 0.05, 0.84, 0.45), Clay.YELLOW if k % 2 else BLACK)
	# La guarda: un estribo de chapa alrededor de la manija, para no tirarla sin querer.
	Clay.box(parent, Vector3(0.52, 0.025, 0.04), Vector3(x, 0.79, 0.5), METAL)
	for dx: float in [-0.26, 0.26]:
		Clay.box(parent, Vector3(0.025, 0.28, 0.04), Vector3(x + dx, 0.92, 0.5), METAL)
	_plaque(parent, title, Vector3(x, 0.74, 0.47), 0.035)


# ── 1. EL MOVIMIENTO ─────────────────────────────────────────────────────────────────────────────────────────────
func _movement() -> Node3D:
	var root := _cockpit("MOVIMIENTO", 0.0)
	_zone(root, Vector2(-1.33, -0.52), Vector2(0.72, 0.74), "CAMINAR")
	_stick(root, Vector3(-1.33, -0.46, FACE), Vector2(-0.3, 0.8), "CAMINAR", "SALTAR")
	# El dash, aparte de caminar: ocho botones con flecha, cada uno hacia donde sale.
	_zone(root, Vector2(-0.6, -0.39), Vector2(0.56, 0.48), "DASH")
	_dash_pad(root, Vector3(-0.6, -0.42, FACE), 2)
	# El cuerpo: agacharse se traba; el giro, mientras se lo aprieta.
	_zone(root, Vector2(0.95, -0.36), Vector2(1.3, 0.44), "CUERPO")
	_latch(root, Vector3(0.45, -0.38, FACE), false, "AGACHAR")
	_push(root, Vector3(0.9, -0.38, FACE), 0.06, CREAM, "GIRO IZQUIERDA")
	_push(root, Vector3(1.38, -0.38, FACE), 0.06, CREAM, "GIRO DERECHA")
	# El ascensor, en la visera.
	_zone(root, Vector2(-0.98, 0.95), Vector2(0.5, 0.28), "", 0.6)
	_push(root, Vector3(-1.1, 1.0, 0.63), 0.045, CREAM, "SUBIR")
	_push(root, Vector3(-0.86, 1.0, 0.63), 0.045, CREAM, "BAJAR")
	_pull(root, 1.0, "EYECTAR")
	# Los parantes: la carga del salto y el propulsor, en luces.
	_pillar_lights(root, -1.9, 5, GREEN, "SALTO")
	_pillar_lights(root, 1.9, 8, AMBER, "PROPULSOR")
	_lamp(root, Vector3(1.9, 0.62, 0.4), false)
	return root


# ── 2. EL CAÑÓN ──────────────────────────────────────────────────────────────────────────────────────────────────
func _cannon() -> Node3D:
	var root := _cockpit("BRAZO IZQUIERDO", 0.45)
	var barrel := Clay.cylinder(root, 0.16, 2.4, Vector3(-1.1, -0.2, -1.2), Color(0.28, 0.29, 0.3), Vector3(70, 0, 28))
	barrel.name = "Caño"
	for k in 16:
		var angle := TAU * k / 16.0
		Clay.box(root, Vector3(0.025, 0.025, 0.01), Vector3(0.5 + cos(angle) * 0.13, 0.42 + sin(angle) * 0.13, 0.0), AMBER)
	for way: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		Clay.box(root, Vector3(0.025 + absf(way.x) * 0.06, 0.025 + absf(way.y) * 0.06, 0.01),
			Vector3(0.5 + way.x * 0.2, 0.42 + way.y * 0.2, 0.0), AMBER)
	_zone(root, Vector2(-1.15, -0.52), Vector2(1.1, 0.74), "APUNTAR")
	_stick(root, Vector3(-1.15, -0.46, FACE), Vector2(0.6, 0.3), "APUNTAR", "DISPARAR")
	# Los modos: cuatro botones que se traban, uno solo puesto a la vez.
	_zone(root, Vector2(0.95, -0.36), Vector2(1.3, 0.44), "MODO")
	var names := ["SIMPLE", "RÁFAGA", "BARRIDO", "SÚPER"]
	for i in names.size():
		_latch(root, Vector3(0.53 + i * 0.28, -0.38, FACE), i == 0, names[i])
	_pull(root, 1.0, "EYECTAR")
	_pillar_lights(root, 1.9, 3, AMBER, "SÚPER")
	return root


# ── 3. LA ESPADA ─────────────────────────────────────────────────────────────────────────────────────────────────
func _sword() -> Node3D:
	var root := _cockpit("BRAZO DERECHO", -0.4)
	var fist := Vector3(0.6, 0.05, -0.6)
	Clay.box(root, Vector3(0.36, 0.3, 0.3), fist, Color(0.28, 0.29, 0.3))
	for k in 4:
		Clay.box(root, Vector3(0.37, 0.02, 0.31), fist + Vector3(0, -0.11 + k * 0.07, 0), FRAME)
	var blade := Clay.box(root, Vector3(0.1, 1.7, 0.03), fist + Vector3(-0.38, 0.95, 0), Color(0.82, 0.84, 0.86))
	blade.rotation_degrees = Vector3(0, 0, 24)
	var guard := Clay.box(root, Vector3(0.5, 0.06, 0.1), fist + Vector3(-0.03, 0.2, 0), FRAME)
	guard.rotation_degrees = Vector3(0, 0, 24)
	_zone(root, Vector2(1.15, -0.52), Vector2(1.1, 0.74), "HOJA")
	_stick(root, Vector3(1.15, -0.46, FACE), Vector2(-0.7, 0.5), "HOJA", "ESTOCADA")
	# Atacar o cubrirse: dos botones que se traban, uno u otro. La mano: agarrar se traba.
	_zone(root, Vector2(-1.2, -0.36), Vector2(0.95, 0.44), "POSTURA")
	_latch(root, Vector3(-1.42, -0.38, FACE), true, "ATAQUE")
	_latch(root, Vector3(-0.98, -0.38, FACE), false, "GUARDIA")
	_zone(root, Vector2(-0.25, -0.36), Vector2(0.55, 0.44), "MANO")
	_latch(root, Vector3(-0.25, -0.38, FACE), true, "AGARRAR")
	_pull(root, -1.0, "EYECTAR")
	_pillar_lights(root, 1.9, 4, AMBER, "ESTOCADA")
	return root


func _shot(title: String, file_name: String) -> void:
	_title.text = title
	for i in 8:
		await get_tree().process_frame
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)
