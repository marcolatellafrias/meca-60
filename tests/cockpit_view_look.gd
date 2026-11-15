extends Node3D

## LA VISTA SENTADO EN EL PUESTO, MAQUETA DE ARCILLA (15/11/2026, el usuario, para el camino de las cabinas: «cuando yo
## me siente en una silla tenga todos los controles alrededor de mi pantalla… acomodadas de una forma óptima para que al
## frente pueda ver libre… los hologramas los vamos a quitar… todos los indicadores de energía… pueden ser objetos…
## inevitablemente tiene perspectiva el juego… hay que probarlo… qué formas de hacer que se distorsione menos, o ver
## cómo lo solucionan otros juegos»). La vista desde los ojos de uno sentado: adelante, la arena con una meca enemiga;
## alrededor de la vista, el tablero de objetos (la energía en tubos, relojes, botones, palancas). Cinco formas:
##   1 · una sola cámara, ángulo normal (75°): lo común;
##   2 · una sola cámara, ángulo ancho (95°): se ve más mundo, la cabina se estira en los bordes;
##   3 · la cabina con su propia cámara, más cerrada (50°), sobre el mundo a 75° (el truco del arma de los juegos de
##       tiros): el mundo igual que en la 1, la cabina sin estirarse;
##   4 · como la 3, con todos los controles girados hacia el ojo y un poco más cerca;
##   5 · la otra alternativa: sin cabina de objetos, la interfaz dibujada encima del vidrio.
##   tools/godot_ventana.sh res://tests/cockpit_view_look.tscn -- --salida=C:/carpeta

const VIEW := Vector2i(1280, 720)
## La capa de la cabina (la ve sólo su cámara en la 3 y la 4).
const COCKPIT_LAYER := 1 << 1
const EYE := Vector3(0.0, 4.0, 0.0)
const NAMES := {
	1: "una cámara, 75°",
	2: "una cámara, 95°",
	3: "la cabina con su cámara a 50°, el mundo a 75°",
	4: "como la 3, los controles girados hacia el ojo",
	5: "la interfaz encima del vidrio",
}

const METAL := Color(0.5, 0.52, 0.55)
const DARK := Color(0.22, 0.23, 0.25)
const FACE := Color(0.92, 0.9, 0.84)
const RED := Color(0.8, 0.22, 0.18)
const YELLOW := Color(0.93, 0.75, 0.16)
const GREEN := Color(0.35, 0.8, 0.4)
const ORANGE := Color(1.0, 0.55, 0.15)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _cockpit: Node3D = null
var _overlay_view: SubViewport = null
var _overlay_eye: Camera3D = null
var _overlay_rect: TextureRect = null
var _ui: Control = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = VIEW
	_stage()
	_arena()
	var shots: Array = []
	for variant in [1, 2, 3, 4, 5]:
		_set_variant(variant)
		_title.text = "%d. %s" % [variant, NAMES[variant]]
		shots.append(await _grab())
	_save(shots)
	get_tree().quit()


## ── LAS VARIANTES ────────────────────────────────────────────────────────────────────────────────────────────────

func _set_variant(variant: int) -> void:
	if _cockpit != null:
		_cockpit.queue_free()
		_cockpit = null
	_ui.visible = variant == 5
	if variant != 5:
		_cockpit = _build_cockpit(variant == 4)
	var split := variant in [3, 4]
	_eye.fov = 95.0 if variant == 2 else 75.0
	_eye.cull_mask = 0xFFFFF & ~COCKPIT_LAYER if split else 0xFFFFF
	_overlay_rect.visible = split
	_overlay_eye.fov = 50.0
	if _cockpit != null:
		_on_layer(_cockpit, COCKPIT_LAYER if split else 1)
		# Con la cámara más cerrada, la cabina se achica de costado y de alto (no de fondo) en lo que se cierra el ángulo:
		# queda en el mismo lugar de la pantalla y se estira menos hacia los bordes. *Escalarla parejo no cambia nada:
		# desde el ojo, más lejos y más grande se ve igual.*
		if split:
			var squeeze := tan(deg_to_rad(50.0 * 0.5)) / tan(deg_to_rad(75.0 * 0.5))
			_cockpit.scale = Vector3(squeeze, squeeze, 1.0)


func _on_layer(node: Node, layer: int) -> void:
	if node is VisualInstance3D:
		(node as VisualInstance3D).layers = layer
	for child in node.get_children():
		_on_layer(child, layer)


## ── LA CABINA (alrededor de los ojos: x a la derecha, y arriba, −z adelante) ─────────────────────────────────────

func _build_cockpit(facing: bool) -> Node3D:
	var root := Node3D.new()
	root.position = EYE
	add_child(root)
	var near := 0.85 if facing else 1.0
	# El marco del vidrio: arriba y a los costados, finos, para que adelante quede libre.
	Clay.box(root, Vector3(2.6, 0.08, 0.08), Vector3(0, 0.62, -1.1), DARK)
	for side: float in [-1.0, 1.0]:
		var post := Clay.box(root, Vector3(0.08, 1.6, 0.08), Vector3(side * 1.2, -0.1, -1.0), DARK)
		post.rotation.z = side * 0.12
	# EL TABLERO DE ABAJO: una franja inclinada, por debajo de la línea de la vista.
	var dash := _panel(root, Vector3(0, -0.5, -0.75 * near), Vector3(1.7, 0.05, 0.42), 35.0, facing)
	# La energía: tubos con su nivel (objetos, no hologramas).
	for i in 5:
		var x := -0.7 + i * 0.09
		Clay.box(dash, Vector3(0.06, 0.02, 0.3), Vector3(x, 0.03, 0.0), DARK)
		var level: float = [0.9, 0.7, 0.5, 0.35, 0.2][i]
		Clay.box(dash, Vector3(0.045, 0.03, 0.28 * level), Vector3(x, 0.045, 0.14 - 0.14 * level), GREEN if level > 0.4
			else ORANGE)
	# Los relojes: la velocidad grande al medio, el calor y la munición chicos.
	_dial(dash, Vector3(0.0, 0.03, 0.0), 0.14, 0.4)
	_dial(dash, Vector3(0.25, 0.03, -0.05), 0.08, -0.6)
	_dial(dash, Vector3(0.43, 0.03, -0.05), 0.08, 0.9)
	# Los botones, a la derecha.
	for row in 2:
		for col in 3:
			Clay.cylinder(dash, 0.03, 0.04, Vector3(0.6 + col * 0.08, 0.04, -0.06 + row * 0.1), RED if (row + col) % 2 == 0
				else YELLOW)
	# LOS COSTADOS: palancas a la izquierda, la palanca de mando a la derecha, bajos y afuera.
	var left := _panel(root, Vector3(-0.78, -0.42, -0.45 * near), Vector3(0.38, 0.05, 0.42), 30.0, facing, 35.0)
	for i in 3:
		Clay.cylinder(left, 0.018, 0.22, Vector3(-0.1 + i * 0.1, 0.12, 0.0), DARK)
		Clay.sphere(left, 0.035, Vector3(-0.1 + i * 0.1, 0.24, 0.0), RED)
	var right := _panel(root, Vector3(0.78, -0.42, -0.45 * near), Vector3(0.38, 0.05, 0.42), 30.0, facing, -35.0)
	Clay.cylinder(right, 0.025, 0.2, Vector3(0, 0.11, 0.02), DARK)
	Clay.box(right, Vector3(0.07, 0.12, 0.07), Vector3(0, 0.25, 0.02), DARK)
	Clay.cylinder(right, 0.02, 0.02, Vector3(0, 0.32, 0.02), RED)
	# ARRIBA, una fila de luces de estado en el marco.
	for i in 6:
		Clay.sphere(root, 0.025, Vector3(-0.35 + i * 0.14, 0.56, -1.05), GREEN if i < 4 else RED)
	return root


## Una placa de `size` en `at`, inclinada `tilt` hacia arriba (hacia el ojo), girada `turn` grados hacia el medio. Con
## `facing`, la cara mira derecho al ojo.
func _panel(parent: Node3D, at: Vector3, size: Vector3, tilt: float, facing: bool, turn := 0.0) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	parent.add_child(holder)
	if facing:
		# Que la normal de la placa apunte al ojo (el origen).
		var normal := (-at).normalized()
		var side := Vector3.UP.cross(normal).normalized()
		holder.basis = Basis(side, normal, side.cross(normal))
	else:
		holder.rotation = Vector3(deg_to_rad(tilt), deg_to_rad(turn), 0.0)
	Clay.box(holder, size, Vector3.ZERO, METAL)
	return holder


func _dial(parent: Node3D, at: Vector3, radius: float, needle: float) -> void:
	Clay.cylinder(parent, radius + 0.01, 0.03, at, DARK)
	Clay.cylinder(parent, radius, 0.035, at, FACE)
	var hand := Clay.box(parent, Vector3(0.012, 0.01, radius * 0.9), at + Vector3(0, 0.025, 0), RED)
	hand.rotation.y = needle
	hand.position += Vector3(sin(needle), 0, cos(needle)) * radius * -0.4


## ── LA ARENA DE AFUERA ───────────────────────────────────────────────────────────────────────────────────────────

func _arena() -> void:
	# Una meca enemiga adelante, un poco a la derecha.
	var enemy := Node3D.new()
	enemy.position = Vector3(6.0, 0.0, -38.0)
	add_child(enemy)
	Clay.box(enemy, Vector3(7, 4, 5), Vector3(0, 9, 0), Color(0.55, 0.3, 0.28))
	for side: float in [-1.0, 1.0]:
		Clay.box(enemy, Vector3(1.6, 7, 1.6), Vector3(side * 2.4, 3.5, 0), Color(0.4, 0.25, 0.22))
		Clay.box(enemy, Vector3(1.4, 5, 1.4), Vector3(side * 4.6, 8, -0.5), Color(0.45, 0.28, 0.25))
	# Edificios bajos alrededor, para el horizonte.
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 18:
		var angle := rng.randf_range(-PI, PI)
		var reach := rng.randf_range(55.0, 120.0)
		var tall := rng.randf_range(6.0, 22.0)
		Clay.box(self, Vector3(rng.randf_range(8, 18), tall, rng.randf_range(8, 18)),
			Vector3(sin(angle) * reach, tall * 0.5, -cos(angle) * reach), Color(0.7, 0.68, 0.64))


func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(600, 1, 600), Vector3(0, -0.5, 0), Color(0.78, 0.74, 0.66))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50.0, -30.0, 0.0)
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
	_eye.near = 0.05
	_eye.position = EYE
	_eye.rotation.x = deg_to_rad(-4.0)
	add_child(_eye)
	_eye.make_current()
	# La cámara de la cabina: en su propio cuadro, encima (ve el mismo mundo, sólo la capa de la cabina).
	_overlay_view = SubViewport.new()
	_overlay_view.size = VIEW
	_overlay_view.transparent_bg = true
	_overlay_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(_overlay_view)
	_overlay_view.world_3d = get_viewport().world_3d
	_overlay_eye = Camera3D.new()
	_overlay_eye.cull_mask = COCKPIT_LAYER
	_overlay_eye.near = 0.05
	_overlay_eye.position = EYE
	_overlay_eye.rotation.x = deg_to_rad(-4.0)
	_overlay_view.add_child(_overlay_eye)
	_overlay_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_overlay_rect = TextureRect.new()
	_overlay_rect.texture = _overlay_view.get_texture()
	_overlay_rect.size = Vector2(VIEW)
	layer.add_child(_overlay_rect)
	_ui = _build_ui()
	layer.add_child(_ui)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 38)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


## LA 5: la interfaz encima del vidrio: un marco oscuro con la energía, los relojes y los botones dibujados, planos.
func _build_ui() -> Control:
	var ui := Control.new()
	ui.size = Vector2(VIEW)
	var bottom := ColorRect.new()
	bottom.color = Color(0.12, 0.13, 0.15, 0.85)
	bottom.position = Vector2(0, VIEW.y - 150)
	bottom.size = Vector2(VIEW.x, 150)
	ui.add_child(bottom)
	for i in 5:
		var level: float = [0.9, 0.7, 0.5, 0.35, 0.2][i]
		var back := ColorRect.new()
		back.color = Color(0.25, 0.25, 0.28)
		back.position = Vector2(60 + i * 34, VIEW.y - 130)
		back.size = Vector2(22, 110)
		ui.add_child(back)
		var bar := ColorRect.new()
		bar.color = GREEN if level > 0.4 else ORANGE
		bar.position = Vector2(60 + i * 34, VIEW.y - 20 - 110 * level)
		bar.size = Vector2(22, 110 * level)
		ui.add_child(bar)
	for i in 3:
		var dial := Label.new()
		dial.text = ["VEL 42", "CALOR 61%", "MUN 120"][i]
		dial.position = Vector2(420 + i * 190, VIEW.y - 100)
		dial.add_theme_font_size_override("font_size", 30)
		dial.add_theme_color_override("font_color", FACE)
		ui.add_child(dial)
	for i in 6:
		var button := ColorRect.new()
		button.color = RED if i % 2 == 0 else YELLOW
		button.position = Vector2(VIEW.x - 280 + (i % 3) * 70, VIEW.y - 130 + (i / 3) * 60)
		button.size = Vector2(50, 40)
		ui.add_child(button)
	var cross := Label.new()
	cross.text = "+"
	cross.position = Vector2(VIEW.x * 0.5 - 10, VIEW.y * 0.5 - 30)
	cross.add_theme_font_size_override("font_size", 48)
	cross.add_theme_color_override("font_color", ORANGE)
	ui.add_child(cross)
	return ui


func _save(shots: Array) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	for index in shots.size():
		var path := "%s/cabina_vista_%d.png" % [_folder, index + 1]
		(shots[index] as Image).save_png(path)
		print("CAPTURA ", path)


func _grab() -> Image:
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()
