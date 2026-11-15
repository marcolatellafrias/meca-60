extends Node3D

## MAQUETAS DEL PUESTO (15/11/2026, ver docs/conceptual/armamento.md, «El puesto: holograma, botones y estado»): en la
## silla del brazo derecho de una meca parada, el holograma adelante (que es la mira), los botones a los costados en
## paneles inclinados, la pantalla de estado y eyectar bajo un vidrio. Arcilla: nada funciona, sólo se mira.
## Cuatro disposiciones, tres formas del holograma, cinco casos y una vista desde atrás.
##   tools/godot_ventana.sh res://tests/seat_station_ideas_look.tscn -- --salida=C:/carpeta

const HOLO_SIZE := Vector2(0.66, 0.4)
const HOLO_PIXELS := Vector2i(660, 400)
const STATUS_SIZE := 0.22
const PANEL_SIZE := Vector2(0.34, 0.22)
const ARM_LIGHT := Color(0.35, 0.95, 1.0)
const LEFT_LIGHT := Color(0.45, 1.0, 0.55)
const BACK_LIGHT := Color(1.0, 0.7, 0.25)
const SCREEN_BACK := Color(0.06, 0.08, 0.1)
const BUTTON := Color(0.32, 0.33, 0.35)
const PANEL := Color(0.25, 0.26, 0.28)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _mech: Mech = null
var _built: Array[Node3D] = []


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	# Afuera: un bloque para pegarle y unas cosas agarrables (un poste y un auto), para el caso del agarre.
	var target := StaticBody3D.new()
	Clay.solid(target, Vector3(4, 8, 4), Vector3(3, 4, -16), Clay.RED)
	Clay.solid(target, Vector3(0.5, 6, 0.5), Vector3(-2.5, 3, -9), Clay.METAL)
	Clay.solid(target, Vector3(2, 1.4, 4), Vector3(5.5, 0.7, -8), Clay.YELLOW.darkened(0.3))
	add_child(target)
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
	add_child(world)
	_eye = Camera3D.new()
	_eye.fov = 75.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(20, 10)
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_outline_color", Color.BLACK)
	_title.add_theme_constant_override("outline_size", 8)
	layer.add_child(_title)
	_mech = Mech.new()
	_mech.arms_kind = Mech.Arms.POSE
	_mech.position = Vector3(0.0, Mech.standing_height(), 0.0)
	add_child(_mech)
	await get_tree().create_timer(3.0).timeout
	_mech.freeze = true
	if _mech.label != null:
		_mech.label.visible = false
	# El panel que se traía (lo reemplaza esto): afuera, para que no se mezcle.
	for old in _mech.cabin.find_children("*", "SeatPanels", false, false):
		old.queue_free()
	var right := _mech.cabin.chairs[2]
	# Un poco detrás y arriba de los ojos, mirando el tablero: así entra el puesto entero (a los ojos, los costados
	# quedan fuera del cuadro y se ven girando).
	var eye := _frame(right) * Vector3(0, right.eye_height + 0.06, 0.18)
	var ahead := _frame(right) * Vector3(0, 1.0, -0.6)
	var fist := {"system": "puño", "buttons": ["PIÑA", "AGARRE", "SIERRA"], "lit": 0}

	# Las disposiciones: dónde va cada módulo.
	var layouts := [
		["1. Holograma al medio, botones a la derecha, estado y eyectar a la izquierda", "uno"],
		["2. Botones y estado juntos a la derecha; eyectar solo a la izquierda", "juntos"],
		["3. Botones en un atril bajo, adelante de las rodillas; estado a la derecha", "atril"],
		["4. Botones en dos pies a los lados de la silla; estado en el tablero", "pies"],
	]
	for index in layouts.size():
		_rebuild([right], [fist], layouts[index][1], "ranura")
		_look(eye, ahead)
		await _shot(layouts[index][0], str(index + 1))
	var styles := [
		["5. El holograma sale de una ranura del tablero", "ranura"],
		["6. El holograma sale de un proyector redondo, con el haz a la vista", "proyector"],
		["7. El holograma, tendido entre dos varillas", "varillas"],
	]
	for index in styles.size():
		_rebuild([right], [fist], "uno", styles[index][1])
		_look(eye, ahead)
		await _shot(styles[index][0], str(index + 5))
	var cases := [
		["8. Puño: el alcance, lo que está a tiro y la carga", fist],
		["9. Agarre: lo agarrable en otro color, lo que está a tiro resaltado",
			{"system": "agarre", "buttons": ["PIÑA", "AGARRE", "SIERRA"], "lit": 1}],
		["10. Cañón de energía: la mano, y sus tres modos en botones",
			{"system": "cañón", "buttons": ["PIÑA", "AGARRE", "TIROS CORTOS", "RAYO", "SÚPER TIRO"], "lit": 4}],
		["11. Espalda: las dos armas en botones; la munición, en el holograma",
			{"system": "espalda", "buttons": ["AMETRALLADORA", "MISIL GUIADO"], "lit": 0}],
		["12. Con dos jugadores: tres selectores eligen qué maneja el holograma",
			{"system": "dos", "buttons": ["PIÑA", "AGARRE", "SIERRA"], "lit": 0}],
	]
	for index in cases.size():
		_rebuild([right], [cases[index][1]], "uno", "ranura")
		_look(eye, ahead)
		await _shot(cases[index][0], str(index + 8))
	# 13. Desde atrás: los tres puestos de adelante, cada uno con lo suyo.
	_rebuild(_mech.cabin.chairs.slice(0, 3), [
			{"system": "cañón", "buttons": ["PIÑA", "AGARRE", "TIROS CORTOS", "RAYO", "SÚPER TIRO"], "lit": 2, "light": LEFT_LIGHT,
				"name": "brazo izquierdo"},
			{"system": "espalda", "buttons": ["AMETRALLADORA", "MISIL GUIADO"], "lit": 1},
			fist], "uno", "ranura")
	var middle := _mech.cabin.chairs[1]
	_look(_frame(middle) * Vector3(0, 2.3, 1.6), _frame(middle) * Vector3(0, 0.9, -0.6))
	await _shot("13. Desde atrás: brazo izquierdo, espalda y brazo derecho", "13")
	get_tree().quit()


## Dónde está la silla y hacia dónde mira, sin su escala (la silla se escala a la medida de quien la usa).
func _frame(chair: SeatInteractable) -> Transform3D:
	return Transform3D(chair.global_basis.orthonormalized(), chair.global_position)


func _look(from: Vector3, to: Vector3) -> void:
	_eye.global_position = from
	_eye.look_at(to)


## Saca lo armado y arma en cada silla de `chairs` el puesto de `systems`, con la disposición y el holograma pedidos.
func _rebuild(chairs: Array, systems: Array, layout: String, style: String) -> void:
	for old in _built:
		old.queue_free()
	_built.clear()
	for index in chairs.size():
		var chair := chairs[index] as SeatInteractable
		var station := Node3D.new()
		_mech.cabin.add_child(station)
		station.transform = Transform3D(chair.transform.basis.orthonormalized(), chair.position)
		_built.append(station)
		_station(station, systems[index], layout, style)


## UN PUESTO, en el espacio de la silla (mira a −Z, el piso en y = 0): el tablero tiene su cara de atrás en
## z = −0,75 trama y su tapa en y = DESK_HEIGHT.
func _station(station: Node3D, system: Dictionary, layout: String, style: String) -> void:
	var top := CabinGrid.DESK_HEIGHT
	var back := -0.75 * CabinGrid.TRAMA
	var light: Color = system.get("light", BACK_LIGHT if system.system == "espalda" else ARM_LIGHT)
	if system.system == "dos":
		light = LEFT_LIGHT
	_hologram(station, Vector3(0, top, back - 0.14), style, system, light)
	var buttons: Array = system.buttons
	var status_at := Vector3(-0.52, top, back - 0.18)
	var eject_at := Vector3(-0.5, top, back - 0.02)
	match layout:
		"uno":
			_panel(station, Vector3(0.56, top, back - 0.16), buttons, system.lit, light, -1.0,
				Vector2(0.42, 0.24) if buttons.size() > 3 else PANEL_SIZE)
			eject_at = Vector3(-0.36, top, back - 0.06)
			# Con dos jugadores, otro panel a la izquierda: los tres selectores de qué maneja el holograma.
			if system.system == "dos":
				_panel(station, Vector3(-0.56, top, back - 0.16), ["BRAZO IZQUIERDO", "ESPALDA", "BRAZO DERECHO"], 0,
					LEFT_LIGHT, 1.0, Vector2(0.42, 0.2))
				status_at = Vector3(-0.9, top, back - 0.3)
				eject_at = Vector3(0.3, top, back - 0.04)
		"juntos":
			_panel(station, Vector3(0.46, top, back - 0.08), buttons, system.lit, light, -1.0)
			status_at = Vector3(0.62, top, back - 0.34)
			eject_at = Vector3(-0.45, top, back - 0.08)
		"atril":
			var desk := Node3D.new()
			station.add_child(desk)
			desk.position = Vector3(0, 0.66, -0.2)
			Clay.box(desk, Vector3(0.04, 0.66, 0.04), Vector3(0, -0.33, 0), Clay.METAL)
			_panel(desk, Vector3.ZERO, buttons, system.lit, light, 0.0, Vector2(0.5, 0.14))
			status_at = Vector3(0.52, top, back - 0.18)
			eject_at = Vector3(-0.5, top, back - 0.08)
		"pies":
			var stand := Node3D.new()
			station.add_child(stand)
			stand.position = Vector3(0.42, 0.78, -0.05)
			Clay.box(stand, Vector3(0.05, 0.78, 0.05), Vector3(0, -0.39, 0), Clay.METAL)
			_panel(stand, Vector3.ZERO, buttons, system.lit, light, -1.0, Vector2(0.22, 0.3))
			var other := Node3D.new()
			station.add_child(other)
			other.position = Vector3(-0.42, 0.78, -0.05)
			Clay.box(other, Vector3(0.05, 0.78, 0.05), Vector3(0, -0.39, 0), Clay.METAL)
			_eject(other, Vector3(0, 0.03, 0))
			eject_at = Vector3.INF
	_status(station, status_at, system)
	if eject_at != Vector3.INF:
		_eject(station, eject_at)


## EL HOLOGRAMA: un vidrio de luz que sube del tablero, con la mira y lo del sistema dibujados. `base` es donde toca
## el tablero.
func _hologram(station: Node3D, base: Vector3, style: String, system: Dictionary, light: Color) -> void:
	var view := SubViewport.new()
	view.size = HOLO_PIXELS
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	station.add_child(view)
	var drawing := _HoloDrawing.new()
	drawing.system = system
	drawing.light = light
	drawing.size = Vector2(HOLO_PIXELS)
	view.add_child(drawing)
	var sheet := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = HOLO_SIZE
	sheet.mesh = quad
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	look.cull_mode = BaseMaterial3D.CULL_DISABLED
	look.albedo_texture = view.get_texture()
	sheet.material_override = look
	var lift := 0.06
	sheet.position = base + Vector3(0, lift + HOLO_SIZE.y * 0.5, 0)
	station.add_child(sheet)
	var glow := Color(light, 0.9)
	match style:
		"ranura":
			Clay.box(station, Vector3(HOLO_SIZE.x + 0.06, 0.03, 0.06), base + Vector3(0, 0.015, 0), Clay.DARK)
			Clay.box(station, Vector3(HOLO_SIZE.x, 0.005, 0.012), base + Vector3(0, 0.032, 0), glow)
		"proyector":
			Clay.cylinder(station, 0.06, 0.05, base + Vector3(0, 0.025, 0.04), Clay.DARK)
			Clay.cylinder(station, 0.035, 0.005, base + Vector3(0, 0.052, 0.04), glow)
			var beam := Color(light, 0.3)
			for side: float in [-1.0, 1.0]:
				Clay.segment(_paint(station, beam), base + Vector3(0, 0.055, 0.04),
					base + Vector3(side * HOLO_SIZE.x * 0.5, lift, 0), 0.008)
		"varillas":
			for side: float in [-1.0, 1.0]:
				var x := side * (HOLO_SIZE.x * 0.5 + 0.02)
				Clay.box(station, Vector3(0.018, HOLO_SIZE.y + lift + 0.02, 0.018),
					base + Vector3(x, (HOLO_SIZE.y + lift + 0.02) * 0.5, 0), Clay.METAL)
				Clay.box(station, Vector3(0.006, HOLO_SIZE.y, 0.006),
					base + Vector3(x - side * 0.012, lift + HOLO_SIZE.y * 0.5, 0), glow)


## Una caja de lado 1 pintada de `color`, para que `Clay.segment` la ponga entre dos puntos.
func _paint(parent: Node3D, color: Color) -> Node3D:
	return Clay.box(parent, Vector3.ONE, Vector3.ZERO, color)


## UN PANEL DE BOTONES, inclinado hacia el que está sentado. `turn` lo gira hacia la silla (−1 si está a la derecha,
## +1 a la izquierda, 0 de frente). El botón `lit` está prendido.
func _panel(parent: Node3D, at: Vector3, buttons: Array, lit: int, light: Color, turn: float,
		size := PANEL_SIZE) -> void:
	var plate := Node3D.new()
	parent.add_child(plate)
	plate.position = at + Vector3(0, 0.03 + size.y * 0.25, 0)
	plate.rotation_degrees = Vector3(40.0, turn * 28.0, 0.0)
	Clay.box(plate, Vector3(size.x, 0.03, size.y), Vector3.ZERO, PANEL)
	var columns := 3 if buttons.size() > 3 else buttons.size()
	if size.x < size.y:
		columns = 1
	var rows := ceili(buttons.size() / float(columns))
	for index in buttons.size():
		var column := index % columns
		var row := floori(index / float(columns))
		var spot := Vector3((column + 0.5) / columns * size.x - size.x * 0.5, 0.02,
			(row + 0.5) / rows * size.y - size.y * 0.5 - 0.012)
		var color := light if index == lit else BUTTON
		Clay.cylinder(plate, 0.028, 0.02, spot, color)
		var name := Label3D.new()
		name.text = buttons[index]
		name.font_size = 22
		name.pixel_size = 0.00085
		name.outline_size = 0
		name.modulate = Color(0.92, 0.92, 0.9) if index != lit else light
		name.position = spot + Vector3(0, 0.002, 0.038)
		name.rotation_degrees = Vector3(-90, 0, 0)
		plate.add_child(name)


## LA PANTALLA DE ESTADO: un cubo con la cara de pantalla hacia el sentado.
func _status(station: Node3D, at: Vector3, system: Dictionary) -> void:
	var cube := Node3D.new()
	station.add_child(cube)
	cube.position = at + Vector3(0, STATUS_SIZE * 0.5, 0)
	cube.rotation_degrees = Vector3(0, -signf(at.x) * 22.0, 0)
	Clay.box(cube, Vector3.ONE * STATUS_SIZE, Vector3.ZERO, Clay.DARK)
	var view := SubViewport.new()
	view.size = Vector2i(240, 240)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	cube.add_child(view)
	var drawing := _StatusDrawing.new()
	drawing.system = system
	drawing.size = Vector2(240, 240)
	view.add_child(drawing)
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * STATUS_SIZE * 0.86
	screen.mesh = quad
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_texture = view.get_texture()
	screen.material_override = look
	screen.position = Vector3(0, 0, STATUS_SIZE * 0.5 + 0.002)
	cube.add_child(screen)


## EYECTAR: un botón rojo bajo un vidrio (trabado hasta que la meca está por explotar).
func _eject(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.12, 0.03, 0.12), at + Vector3(0, 0.015, 0), Clay.DARK)
	Clay.cylinder(parent, 0.035, 0.025, at + Vector3(0, 0.04, 0), Clay.RED)
	Clay.box(parent, Vector3(0.1, 0.06, 0.1), at + Vector3(0, 0.06, 0), Color(0.7, 0.85, 0.95, 0.25))
	var name := Label3D.new()
	name.text = "EYECTAR"
	name.font_size = 22
	name.pixel_size = 0.00085
	name.modulate = Color(1.0, 0.5, 0.45)
	name.position = at + Vector3(0, 0.032, 0.075)
	name.rotation_degrees = Vector3(-60, 0, 0)
	parent.add_child(name)


func _shot(title: String, file_name: String) -> void:
	_title.text = title
	for i in 6:
		await get_tree().process_frame
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)


## Lo que dibuja el holograma: la mira siempre al medio, y alrededor lo del sistema.
class _HoloDrawing extends Control:
	var system := {}
	var light := Color.WHITE

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var middle := size * 0.5
		var faint := Color(light, 0.7)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.06, 0.08, 0.35))
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), faint, false, 2.0)
		# La mira.
		draw_arc(middle, 18, 0, TAU, 32, light, 3.0)
		for way: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			draw_line(middle + way * 24, middle + way * 42, light, 3.0)
		var kind: String = system.system
		var header: String = {"puño": "PUÑO", "agarre": "AGARRE", "cañón": "CAÑÓN · SÚPER TIRO", "espalda": "AMETRALLADORA",
			"dos": "BRAZO IZQUIERDO"}[kind]
		draw_string(font, Vector2(16, 34), header, HORIZONTAL_ALIGNMENT_LEFT, -1, 30, light)
		match kind:
			"puño":
				draw_arc(middle + Vector2(0, 120), 210, PI * 1.18, PI * 1.82, 48, faint, 2.0)
				draw_string(font, Vector2(size.x - 170, 76), "alcance 8 m", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, faint)
				_bar("carga", 0.55)
			"agarre":
				var green := Color(0.5, 1.0, 0.5)
				_brackets(middle + Vector2(-120, 10), Vector2(30, 90), Color(green, 0.5))
				_brackets(middle + Vector2(110, 60), Vector2(70, 40), green)
				draw_string(font, Vector2(16, size.y - 20), "a tiro: un auto", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, green)
			"cañón":
				_bar("carga", 0.8)
				draw_string(font, Vector2(size.x - 260, 76), "gasta 40 de energía", HORIZONTAL_ALIGNMENT_LEFT, -1, 24,
					faint)
			"espalda":
				draw_string(font, Vector2(size.x - 190, 36), "balas  240", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, light)
				draw_string(font, Vector2(size.x - 190, 66), "misiles  6", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, faint)
			"dos":
				for index in 3:
					var names: Array[String] = ["BRAZO IZQUIERDO", "ESPALDA", "BRAZO DERECHO"]
					var colors: Array[Color] = [Color(0.45, 1.0, 0.55), Color(1.0, 0.7, 0.25), Color(0.35, 0.95, 1.0)]
					var spot := Vector2(16 + index * 220, size.y - 22)
					draw_string(font, spot, names[index], HORIZONTAL_ALIGNMENT_LEFT, -1, 22,
						colors[index] if index == 0 else Color(colors[index], 0.35))

	func _bar(label: String, share: float) -> void:
		var font := ThemeDB.fallback_font
		var where := Rect2(Vector2(size.x * 0.25, size.y - 34), Vector2(size.x * 0.5, 14))
		draw_rect(where, Color(light, 0.35), false, 2.0)
		draw_rect(Rect2(where.position, Vector2(where.size.x * share, where.size.y)), Color(light, 0.7))
		draw_string(font, where.position + Vector2(-80, 15), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, light)

	func _brackets(center: Vector2, half: Vector2, color: Color) -> void:
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			var point := center + half * corner
			draw_line(point, point - Vector2(corner.x * 14, 0), color, 3.0)
			draw_line(point, point - Vector2(0, corner.y * 14), color, 3.0)


## Lo que dibuja la pantalla de estado: la meca de frente con cada parte que se rompe (sana, verde; rota, roja), la
## energía y su máximo. Con dos sistemas o más, todos los de la silla.
class _StatusDrawing extends Control:
	var system := {}

	func _draw() -> void:
		var font := ThemeDB.fallback_font
		var line := Color(0.35, 0.95, 1.0)
		var good := Color(0.45, 0.95, 0.5)
		var bad := Color(1.0, 0.35, 0.3)
		draw_rect(Rect2(Vector2.ZERO, size), SCREEN_BACK)
		# La energía, a la izquierda: el máximo que le queda (la raya) y lo que hay.
		draw_rect(Rect2(Vector2(16, 30), Vector2(26, 170)), line, false, 2.0)
		draw_rect(Rect2(Vector2(16, 30 + 170 * 0.4), Vector2(26, 170 * 0.6)), Color(line, 0.6))
		draw_line(Vector2(10, 30 + 170 * 0.15), Vector2(48, 30 + 170 * 0.15), bad, 2.0)
		draw_string(font, Vector2(8, 224), "energía", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, line)
		# La meca: el casco, los dos brazos y las piernas (el movimiento). El brazo derecho, roto.
		var center := Vector2(150, 110)
		draw_rect(Rect2(center + Vector2(-34, -60), Vector2(68, 70)), good, false, 3.0)
		draw_rect(Rect2(center + Vector2(-62, -50), Vector2(20, 64)), good, false, 3.0)
		draw_rect(Rect2(center + Vector2(42, -50), Vector2(20, 64)), bad, false, 3.0)
		for side: float in [-1.0, 1.0]:
			draw_line(center + Vector2(side * 18, 12), center + Vector2(side * 24, 80), good, 3.0)
		var names := {"puño": "brazo derecho", "agarre": "brazo derecho", "cañón": "brazo derecho",
			"espalda": "espalda", "dos": "brazos y espalda"}
		draw_string(font, Vector2(84, 224), system.get("name", names.get(system.get("system", ""), "")), HORIZONTAL_ALIGNMENT_LEFT, -1, 16,
			line)
