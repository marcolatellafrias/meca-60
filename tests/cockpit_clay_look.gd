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


# ── LO COMÚN: el mundo, el marco y la energía ────────────────────────────────────────────────────────────────────
func _cockpit(title: String, boss_x: float) -> Node3D:
	var root := Node3D.new()
	add_child(root)
	# El mundo: el piso, unos edificios y la meca enemiga.
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
	# Los parantes, con sus bandas.
	for side: float in [-1.0, 1.0]:
		Clay.box(root, Vector3(0.3, 3.2, 0.34), Vector3(side * 1.9, 0.2, 0.2), FRAME)
		for y in [-0.3, 0.3, 0.9]:
			Clay.box(root, Vector3(0.34, 0.04, 0.38), Vector3(side * 1.9, y, 0.2), METAL)
	# Arriba, la visera: oscura, con su canto.
	Clay.box(root, Vector3(4.4, 0.42, 0.6), Vector3(0, 1.3, 0.3), FRAME)
	Clay.box(root, Vector3(4.0, 0.05, 0.64), Vector3(0, 1.08, 0.32), METAL)
	_plaque(root, title, Vector3(0, 1.26, 0.61), 0.075)
	# Abajo, la consola: una sola pieza ancha, con su baranda adelante.
	Clay.box(root, Vector3(4.4, 0.6, 1.0), Vector3(0, -1.0, 0.5), METAL)
	Clay.box(root, Vector3(4.4, 0.05, 1.02), Vector3(0, -0.72, 0.5), LIGHT)
	Clay.box(root, Vector3(3.6, 0.07, 0.07), Vector3(0, -0.76, 1.03), FRAME)
	# La energía, común a todos: un tubo de vidrio acostado en el frente de la consola.
	Clay.box(root, Vector3(1.5, 0.16, 0.06), Vector3(0, -1.0, 1.02), FRAME)
	Clay.cylinder(root, 0.05, 1.3, Vector3(0, -1.0, 1.1), GLASS, Vector3(0, 0, 90))
	Clay.cylinder(root, 0.042, 1.3 * 0.62, Vector3(-0.65 + 0.65 * 0.62, -1.0, 1.1), GREEN, Vector3(0, 0, 90))
	for x: float in [-0.68, 0.68]:
		Clay.cylinder(root, 0.065, 0.05, Vector3(x, -1.0, 1.1), FRAME, Vector3(0, 0, 90))
	_plaque(root, "ENERGÍA", Vector3(0, -1.13, 1.06), 0.04)
	return root


## Una placa negra con el nombre en crema.
func _plaque(parent: Node3D, text: String, at: Vector3, height: float) -> void:
	var label := StrokeLabel.make(text, height, CREAM)
	label.position = at + Vector3(0, 0, 0.012)
	parent.add_child(label)
	var width := text.length() * height * 0.75 + height
	Clay.box(parent, Vector3(width, height * 1.8, 0.02), at, BLACK)


func _lamp(parent: Node3D, at: Vector3, on: bool) -> void:
	var lamp := Clay.sphere(parent, 0.03, at, AMBER if on else OFF)
	if on:
		var glow := StandardMaterial3D.new()
		glow.albedo_color = AMBER
		glow.emission_enabled = true
		glow.emission = AMBER
		glow.emission_energy_multiplier = 1.5
		lamp.material_override = glow
	Clay.cylinder(parent, 0.04, 0.02, at - Vector3(0, 0, 0.02), FRAME, Vector3(90, 0, 0))


## LA PALANCA: una base redonda sobre la consola, el palo inclinado y la bocha con el gatillo rojo adelante.
func _stick(parent: Node3D, at: Vector3, lean: Vector2, title: String, trigger: String) -> void:
	Clay.cylinder(parent, 0.24, 0.06, at + Vector3(0, 0.03, 0), FRAME)
	Clay.sphere(parent, 0.13, at + Vector3(0, 0.04, 0), BLACK)
	var top := at + Vector3(lean.x * 0.14, 0.46, lean.y * 0.14)
	var shaft := MeshInstance3D.new()
	shaft.mesh = BoxMesh.new()
	shaft.material_override = Clay.material(LIGHT)
	parent.add_child(shaft)
	Clay.segment(shaft, at + Vector3(0, 0.08, 0), top, 0.05)
	Clay.sphere(parent, 0.085, top + Vector3(0, 0.05, 0), BLACK)
	Clay.box(parent, Vector3(0.05, 0.05, 0.05), top + Vector3(0, 0.04, 0.08), TRIGGER)
	_plaque(parent, title, at + Vector3(0, -0.12, 0.48), 0.045)
	var tag := StrokeLabel.make("GATILLO: " + trigger, 0.03, INK)
	tag.position = at + Vector3(0, -0.2, 0.49)
	parent.add_child(tag)


## UN TUBO EN EL PARANTE: el vidrio, lo que tiene adentro y las abrazaderas.
func _pod(parent: Node3D, x: float, y: float, frac: float, color: Color, title: String) -> void:
	var at := Vector3(x, y, 0.5)
	for dy: float in [-0.24, 0.24]:
		Clay.cylinder(parent, 0.1, 0.05, at + Vector3(0, dy, 0), FRAME)
		Clay.box(parent, Vector3(0.06, 0.04, 0.3), at + Vector3(signf(-x) * -0.0, dy, -0.16), METAL)
	Clay.cylinder(parent, 0.08, 0.44, at, GLASS)
	Clay.cylinder(parent, 0.07, 0.44 * frac, at + Vector3(0, -0.22 + 0.22 * frac, 0), color)
	_plaque(parent, title, at + Vector3(0, -0.34, 0.06), 0.035)


## UNA MANIJA QUE CUELGA DE LA VISERA: dos cordones y una T; rayada si es peligrosa.
func _pull(parent: Node3D, x: float, title: String, striped: bool) -> void:
	for dx: float in [-0.12, 0.12]:
		Clay.box(parent, Vector3(0.015, 0.22, 0.015), Vector3(x + dx, 0.97, 0.45), BLACK)
	if striped:
		for k in 8:
			Clay.box(parent, Vector3(0.05, 0.07, 0.07), Vector3(x - 0.175 + k * 0.05, 0.84, 0.45), Clay.YELLOW if k % 2 else BLACK)
	else:
		Clay.box(parent, Vector3(0.4, 0.07, 0.07), Vector3(x, 0.84, 0.45), LIGHT)
	_plaque(parent, title, Vector3(x, 0.74, 0.47), 0.035)


# ── 1. EL MOVIMIENTO ─────────────────────────────────────────────────────────────────────────────────────────────
func _movement() -> Node3D:
	var root := _cockpit("MOVIMIENTO", 0.0)
	var base := Vector3(-0.75, -0.7, 0.55)
	_stick(root, base, Vector2(-0.4, -0.8), "CAMINAR", "SALTAR")
	# El dash: ocho teclas en aro alrededor de la base de la palanca, cada una en su dirección.
	for i in 8:
		var angle := TAU * i / 8.0
		var key := Clay.box(root, Vector3(0.14, 0.07 if i != 1 else 0.035, 0.1), base + Vector3(cos(angle) * 0.4, 0.03, -sin(angle) * 0.28),
			AMBER if i == 1 else CREAM)
		key.rotation.y = angle
	_plaque(root, "DASH", base + Vector3(0.62, 0.02, 0.2), 0.035)
	# Agacharse: una palanca grande a la derecha, que se tira para abajo.
	var crouch := Vector3(0.95, -0.7, 0.6)
	Clay.box(root, Vector3(0.12, 0.04, 0.36), crouch + Vector3(0, 0.02, 0), BLACK)
	var arm := MeshInstance3D.new()
	arm.mesh = BoxMesh.new()
	arm.material_override = Clay.material(LIGHT)
	root.add_child(arm)
	Clay.segment(arm, crouch + Vector3(0, 0.04, 0.1), crouch + Vector3(0, 0.36, 0.22), 0.045)
	Clay.sphere(root, 0.06, crouch + Vector3(0, 0.38, 0.23), BLACK)
	_plaque(root, "AGACHAR", crouch + Vector3(0, -0.12, 0.43), 0.04)
	# El giro: dos pedales abajo, a los pies.
	for side: float in [-1.0, 1.0]:
		var pedal := Vector3(side * 0.32 + 0.0, -1.22, 1.2)
		Clay.box(root, Vector3(0.26, 0.12, 0.06), pedal, BLACK)
		for k in 3:
			Clay.box(root, Vector3(0.22, 0.012, 0.02), pedal + Vector3(0, -0.04 + k * 0.04, 0.035), FRAME)
	_plaque(root, "GIRO", Vector3(0, -1.22, 1.22), 0.035)
	# Arriba: el ascensor y eyectar, manijas que cuelgan.
	_pull(root, -1.0, "ASCENSOR", false)
	_pull(root, 1.0, "EYECTAR", true)
	# Los parantes: la carga del salto y el propulsor.
	_pod(root, -1.9, 0.2, 0.55, GREEN, "SALTO")
	_pod(root, 1.9, 0.2, 0.8, AMBER, "PROPULSOR")
	_lamp(root, Vector3(1.9, 0.58, 0.52), false)
	return root


# ── 2. EL CAÑÓN ──────────────────────────────────────────────────────────────────────────────────────────────────
func _cannon() -> Node3D:
	var root := _cockpit("BRAZO IZQUIERDO", 0.45)
	# El caño entra desde abajo a la izquierda.
	var barrel := Clay.cylinder(root, 0.16, 2.4, Vector3(-1.1, -0.35, -1.2), Color(0.28, 0.29, 0.3), Vector3(70, 0, 28))
	barrel.name = "Caño"
	# La mira pintada en el vidrio, donde apunta el brazo (atrasada de la palanca).
	for k in 16:
		var angle := TAU * k / 16.0
		Clay.box(root, Vector3(0.025, 0.025, 0.01), Vector3(0.5 + cos(angle) * 0.13, 0.42 + sin(angle) * 0.13, 0.0), AMBER)
	for way: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
		Clay.box(root, Vector3(0.025 + absf(way.x) * 0.06, 0.025 + absf(way.y) * 0.06, 0.01),
			Vector3(0.5 + way.x * 0.2, 0.42 + way.y * 0.2, 0.0), AMBER)
	_stick(root, Vector3(-0.8, -0.7, 0.55), Vector2(0.5, -0.3), "APUNTAR", "DISPARAR")
	# Los modos: cuatro teclas de piano; la elegida queda abajo, con su lamparita.
	var names := ["SIMPLE", "RÁFAGA", "BARRIDO", "SÚPER"]
	for i in names.size():
		var x := 0.35 + i * 0.27
		var down := i == 0
		Clay.box(root, Vector3(0.22, 0.08 if not down else 0.04, 0.42), Vector3(x, -0.66 if not down else -0.68, 0.62), BLACK if down else CREAM)
		_lamp(root, Vector3(x, -0.6, 0.38), down)
		var tag := StrokeLabel.make(names[i], 0.03, INK)
		tag.position = Vector3(x, -0.86, 1.01)
		root.add_child(tag)
	_plaque(root, "MODO", Vector3(0.75, -0.92, 1.01), 0.035)
	_pull(root, 1.0, "EYECTAR", true)
	_pod(root, 1.9, 0.2, 0.3, AMBER, "SÚPER")
	return root


# ── 3. LA ESPADA ─────────────────────────────────────────────────────────────────────────────────────────────────
func _sword() -> Node3D:
	var root := _cockpit("BRAZO DERECHO", -0.4)
	# El puño de la meca abajo a la derecha, con la espada hacia arriba a la izquierda.
	var fist := Vector3(0.75, -0.42, -0.6)
	Clay.box(root, Vector3(0.36, 0.3, 0.3), fist, Color(0.28, 0.29, 0.3))
	for k in 4:
		Clay.box(root, Vector3(0.37, 0.02, 0.31), fist + Vector3(0, -0.11 + k * 0.07, 0), FRAME)
	var blade := Clay.box(root, Vector3(0.1, 1.7, 0.03), fist + Vector3(-0.38, 0.95, 0), Color(0.82, 0.84, 0.86))
	blade.rotation_degrees = Vector3(0, 0, 24)
	var guard := Clay.box(root, Vector3(0.5, 0.06, 0.1), fist + Vector3(-0.03, 0.2, 0), FRAME)
	guard.rotation_degrees = Vector3(0, 0, 24)
	_stick(root, Vector3(0.85, -0.7, 0.55), Vector2(-0.6, -0.5), "HOJA", "ESTOCADA")
	# Atacar o cubrirse: una palanca de cuchilla con dos posiciones.
	var knife := Vector3(-0.85, -0.7, 0.6)
	Clay.box(root, Vector3(0.36, 0.04, 0.3), knife + Vector3(0, 0.02, 0), FRAME)
	for side: float in [-1.0, 1.0]:
		Clay.box(root, Vector3(0.03, 0.12, 0.08), knife + Vector3(side * 0.08, 0.08, -0.08), METAL)
	var arm := MeshInstance3D.new()
	arm.mesh = BoxMesh.new()
	arm.material_override = Clay.material(LIGHT)
	root.add_child(arm)
	Clay.segment(arm, knife + Vector3(0, 0.1, -0.08), knife + Vector3(0, 0.34, 0.12), 0.04)
	Clay.box(root, Vector3(0.2, 0.05, 0.05), knife + Vector3(0, 0.36, 0.13), BLACK)
	var up := StrokeLabel.make("ATAQUE", 0.03, INK)
	up.position = knife + Vector3(0.26, 0.36, 0.13)
	root.add_child(up)
	var down := StrokeLabel.make("GUARDIA", 0.03, INK)
	down.position = knife + Vector3(0.26, 0.06, 0.2)
	root.add_child(down)
	_lamp(root, knife + Vector3(-0.22, 0.04, 0.3), true)
	# La mano: un gatillo grande de agarrar en el parante izquierdo, con su lamparita de empuñada.
	var grip := Vector3(-1.9, 0.25, 0.5)
	Clay.box(root, Vector3(0.18, 0.4, 0.14), grip, BLACK)
	for k in 4:
		Clay.box(root, Vector3(0.19, 0.03, 0.15), grip + Vector3(0, -0.15 + k * 0.1, 0), FRAME)
	Clay.box(root, Vector3(0.08, 0.2, 0.1), grip + Vector3(0.1, -0.02, 0.1), TRIGGER)
	_lamp(root, grip + Vector3(0, 0.3, 0.06), true)
	_plaque(root, "AGARRAR", grip + Vector3(0, -0.32, 0.08), 0.035)
	_pull(root, 1.0, "EYECTAR", true)
	_pod(root, 1.9, 0.2, 0.4, AMBER, "ESTOCADA")
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
