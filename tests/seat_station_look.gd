extends Node3D

## EL PUESTO, UNA MAQUETA QUE SE VA MEJORANDO (15/11/2026, ver docs/conceptual/armamento.md, «El puesto: holograma,
## botones y estado»). En la silla del brazo derecho de una meca parada: el holograma al medio (la mira, con la energía
## siempre), y a los costados MÓDULOS PAREJOS: un cubo y rectángulos del mismo ancho y fondo que el cubo y la mitad de
## alto. A la izquierda, eyectar (un rectángulo) con el cubo de estado encima; a la derecha, los botones. Las letras,
## con la letra del juego (StrokeFont). Arcilla: nada funciona, sólo se mira. El usuario: iterar sobre esta sola, no
## hacer tandas de ideas.
##   tools/godot_ventana.sh res://tests/seat_station_look.tscn -- --salida=C:/carpeta

## El cubo de los módulos; los rectángulos, del mismo ancho y fondo y la mitad de alto.
const CUBE := 0.28
const SLAB := CUBE * 0.5
const HOLO_SIZE := Vector2(0.66, 0.4)
const HOLO_PIXELS := Vector2i(660, 400)
## El holograma sigue siendo un holograma; lo demás, de taller: chapa pintada, baquelita, lamparitas.
const HOLO := Color(0.35, 0.95, 1.0)
const PAINT := Color(0.42, 0.45, 0.43)
const PLINTH := Color(0.22, 0.23, 0.23)
const CAP_LIGHT := Color(0.86, 0.83, 0.74)
const CAP_DARK := Color(0.12, 0.12, 0.12)
const RING := Color(0.6, 0.62, 0.64)
const LAMP_ON := Color(1.0, 0.68, 0.25)
const LAMP_OFF := Color(0.35, 0.28, 0.2)
const INK := Color(0.08, 0.08, 0.08)
const PHOSPHOR := Color(0.45, 1.0, 0.55)

var _folder := ""
var _eye: Camera3D = null
var _title: Label = null
var _mech: Mech = null


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
	get_window().size = Vector2i(1280, 720)
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(900, 1, 900), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var target := StaticBody3D.new()
	Clay.solid(target, Vector3(4, 8, 4), Vector3(3, 4, -16), Clay.RED)
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
	# El panel que se traía (lo reemplaza esto): afuera.
	for old in _mech.cabin.find_children("*", "SeatPanels", false, false):
		old.queue_free()
	var right := _mech.cabin.chairs[2]
	var station := Node3D.new()
	_mech.cabin.add_child(station)
	station.transform = Transform3D(right.transform.basis.orthonormalized(), right.position)
	_station(station)
	var seat := _frame(right)
	# 1. Sentado (un poco detrás y arriba de los ojos, para que entre el puesto entero).
	_look(seat * Vector3(0, right.eye_height + 0.06, 0.18), seat * Vector3(0, 1.0, -0.6))
	await _shot("1. Sentado: el holograma con la energía; a la izquierda eyectar y el estado, a la derecha los botones", "1")
	# Un maniquí en la silla, para ver la silla con el puesto.
	_mech.cabin.dummies[0].intent.seat = right
	await get_tree().create_timer(1.5).timeout
	# 2. Por encima del hombro derecho.
	_look(seat * Vector3(0.6, 1.5, 0.95), seat * Vector3(-0.05, 0.9, -0.45))
	await _shot("2. Por encima del hombro: la silla y los módulos, a la altura de la mano", "2")
	# 3. Desde atrás y arriba.
	_look(seat * Vector3(-0.5, 2.2, 1.5), seat * Vector3(0, 0.9, -0.5))
	await _shot("3. Desde atrás: el que maneja el brazo derecho, sentado", "3")
	get_tree().quit()


## Dónde está la silla y hacia dónde mira, sin escala.
func _frame(chair: SeatInteractable) -> Transform3D:
	return Transform3D(chair.global_basis.orthonormalized(), chair.global_position)


func _look(from: Vector3, to: Vector3) -> void:
	_eye.global_position = from
	_eye.look_at(to)


## EL PUESTO, en el espacio de la silla (mira a −Z, el piso en y = 0): el tablero tiene su cara de atrás en
## z = −0,75 trama y su tapa en y = DESK_HEIGHT.
func _station(station: Node3D) -> void:
	var top := CabinGrid.DESK_HEIGHT
	var back := -0.75 * CabinGrid.TRAMA
	_hologram(station, Vector3(0, top, back - 0.14))
	# A la izquierda: eyectar, y el cubo de estado encima.
	var left := _module(station, Vector3(-0.56, top, back - 0.2), 1.0)
	_eject(left)
	_status(left, Vector3(0, SLAB, 0))
	# A la derecha: los botones del brazo.
	var right := _module(station, Vector3(0.56, top, back - 0.2), -1.0)
	_buttons(right, ["PIÑA", "AGARRE", "SIERRA"], 0)


## Un lugar para módulos sobre el tablero, girado hacia la silla (`turn` +1 si está a la izquierda, −1 a la derecha).
func _module(station: Node3D, at: Vector3, turn: float) -> Node3D:
	var spot := Node3D.new()
	station.add_child(spot)
	spot.position = at
	spot.rotation_degrees = Vector3(0, -turn * 22.0, 0)
	return spot


## Una caja de módulo de `tall` de alto, con su zócalo más oscuro, apoyada en `at` (su base).
func _box(parent: Node3D, at: Vector3, tall: float) -> void:
	Clay.box(parent, Vector3(CUBE, tall - 0.012, CUBE), at + Vector3(0, 0.012 + (tall - 0.012) * 0.5, 0), PAINT)
	Clay.box(parent, Vector3(CUBE - 0.012, 0.012, CUBE - 0.012), at + Vector3(0, 0.006, 0), PLINTH)


## Un rótulo grabado (la letra del juego) en la cara de arriba de un módulo, leyéndose desde la silla.
func _engrave(parent: Node3D, text: String, at: Vector3, height: float) -> void:
	var label := StrokeLabel.make(text, height, INK)
	label.position = at
	label.rotation_degrees = Vector3(-90, 0, 0)
	parent.add_child(label)


## LOS BOTONES: un rectángulo con un botón de baquelita por opción y una lamparita al lado del que está elegido.
func _buttons(spot: Node3D, names: Array, chosen: int) -> void:
	_box(spot, Vector3.ZERO, SLAB)
	for index in names.size():
		var x := (index + 0.5) / names.size() * CUBE - CUBE * 0.5
		var on := index == chosen
		var face := Vector3(x, SLAB, -0.03)
		Clay.cylinder(spot, 0.034, 0.008, face + Vector3(0, 0.004, 0), RING)
		Clay.cylinder(spot, 0.027, 0.012 if on else 0.022, face + Vector3(0, 0.006 if on else 0.011, 0),
			CAP_DARK if on else CAP_LIGHT)
		Clay.sphere(spot, 0.008, face + Vector3(0, 0.004, -0.05), LAMP_ON if on else LAMP_OFF)
		var label := StrokeLabel.make(names[index], 0.016, INK)
		label.max_width = CUBE / names.size() - 0.03
		label.position = Vector3(x, SLAB * 0.5, CUBE * 0.5 + 0.001)
		spot.add_child(label)


## EYECTAR: un rectángulo con un hongo rojo en la cara que mira a la silla, bajo una tapa de vidrio (trabada hasta
## que la meca está por explotar). Arriba va el cubo de estado, así que el botón va al frente.
func _eject(spot: Node3D) -> void:
	_box(spot, Vector3.ZERO, SLAB)
	var face := Vector3(0, SLAB * 0.5 + 0.02, CUBE * 0.5)
	Clay.cylinder(spot, 0.04, 0.01, face + Vector3(0, 0, 0.005), RING, Vector3(90, 0, 0))
	Clay.cylinder(spot, 0.032, 0.03, face + Vector3(0, 0, 0.018), Clay.RED, Vector3(90, 0, 0))
	Clay.box(spot, Vector3(0.1, 0.1, 0.045), face + Vector3(0, 0, 0.024), Color(0.75, 0.85, 0.9, 0.22))
	var label := StrokeLabel.make("EYECTAR", 0.016, INK)
	label.position = Vector3(0, 0.022, CUBE * 0.5 + 0.001)
	spot.add_child(label)


## EL ESTADO: un cubo con una pantalla de fósforo hacia la silla: la meca de frente, cada parte que se rompe; la rota,
## punteada.
func _status(spot: Node3D, base: Vector3) -> void:
	_box(spot, base, CUBE)
	var view := SubViewport.new()
	view.size = Vector2i(240, 240)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	spot.add_child(view)
	view.add_child(_StatusDrawing.new())
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * CUBE * 0.72
	screen.mesh = quad
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_texture = view.get_texture()
	screen.material_override = look
	screen.position = base + Vector3(0, CUBE * 0.5, CUBE * 0.5 + 0.003)
	spot.add_child(screen)
	# El marco de la pantalla, un poco salido.
	var rim := CUBE * 0.72 + 0.03
	for side: float in [-1.0, 1.0]:
		Clay.box(spot, Vector3(rim, 0.015, 0.012), base + Vector3(0, CUBE * 0.5 + side * (rim - 0.015) * 0.5, CUBE * 0.5 + 0.006),
			PLINTH)
		Clay.box(spot, Vector3(0.015, rim, 0.012), base + Vector3(side * (rim - 0.015) * 0.5, CUBE * 0.5, CUBE * 0.5 + 0.006),
			PLINTH)


## EL HOLOGRAMA: un vidrio de luz que sube de una ranura del tablero, con la mira, la energía siempre y lo del sistema.
func _hologram(station: Node3D, base: Vector3) -> void:
	var view := SubViewport.new()
	view.size = HOLO_PIXELS
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	station.add_child(view)
	var drawing := _HoloDrawing.new()
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
	sheet.position = base + Vector3(0, 0.06 + HOLO_SIZE.y * 0.5, 0)
	station.add_child(sheet)
	# La ranura: una tapa de chapa con la rendija.
	Clay.box(station, Vector3(HOLO_SIZE.x + 0.06, 0.03, 0.07), base + Vector3(0, 0.015, 0), PLINTH)
	Clay.box(station, Vector3(HOLO_SIZE.x, 0.004, 0.012), base + Vector3(0, 0.031, 0), HOLO)


func _shot(title: String, file_name: String) -> void:
	_title.text = title
	for i in 6:
		await get_tree().process_frame
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var path := "%s/%s.png" % [_folder, file_name]
	get_viewport().get_texture().get_image().save_png(path)
	print("CAPTURA ", path)


## Un dibujo 2D que escribe con la letra del juego.
class _Screen extends Control:
	## Escribe `text`: `at` es la esquina de abajo a la izquierda.
	func write(text: String, at: Vector2, height: float, color: Color, width := 2.0) -> void:
		var lines := StrokeFont.segments(text, height, StrokeFont.Align.LEFT)
		for k in range(0, lines.size(), 2):
			draw_line(at + Vector2(lines[k].x, -lines[k].y - height * 0.5),
				at + Vector2(lines[k + 1].x, -lines[k + 1].y - height * 0.5), color, width)


## Lo que dibuja el holograma: la mira al medio, LA ENERGÍA SIEMPRE a la izquierda (el máximo que le queda, la raya), y
## lo del sistema: el alcance y la carga del puño.
class _HoloDrawing extends _Screen:
	func _draw() -> void:
		var middle := size * 0.5 + Vector2(20, 0)
		var faint := Color(HOLO, 0.7)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.06, 0.08, 0.35))
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), faint, false, 2.0)
		draw_arc(middle, 18, 0, TAU, 32, HOLO, 3.0)
		for way: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			draw_line(middle + way * 24, middle + way * 42, HOLO, 3.0)
		write("PUÑO", Vector2(110, 44), 22, HOLO, 3.0)
		# La energía.
		var bar := Rect2(Vector2(30, 40), Vector2(34, 300))
		draw_rect(bar, HOLO, false, 2.0)
		draw_rect(Rect2(bar.position + Vector2(0, bar.size.y * 0.45), Vector2(bar.size.x, bar.size.y * 0.55)), Color(HOLO, 0.6))
		draw_line(bar.position + Vector2(-6, bar.size.y * 0.15), bar.position + Vector2(bar.size.x + 6, bar.size.y * 0.15),
			Color(1.0, 0.45, 0.35), 3.0)
		write("ENERGÍA", Vector2(12, 374), 14, HOLO, 2.0)
		# El alcance y la carga.
		draw_arc(middle + Vector2(0, 120), 210, PI * 1.18, PI * 1.82, 48, faint, 2.0)
		write("ALCANCE 8 M", Vector2(size.x - 190, 76), 16, faint, 2.0)
		var charge := Rect2(Vector2(size.x * 0.32, size.y - 40), Vector2(size.x * 0.5, 16))
		draw_rect(charge, faint, false, 2.0)
		draw_rect(Rect2(charge.position, Vector2(charge.size.x * 0.55, charge.size.y)), Color(HOLO, 0.7))
		write("CARGA", charge.position + Vector2(-84, 16), 16, HOLO, 2.0)


## La pantalla de estado: la meca de frente con cada parte que se rompe; la rota, punteada.
class _StatusDrawing extends _Screen:
	func _ready() -> void:
		size = Vector2(240, 240)

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.07, 0.04))
		var center := Vector2(120, 104)
		_outline(Rect2(center + Vector2(-38, -62), Vector2(76, 76)), false)
		_outline(Rect2(center + Vector2(-70, -52), Vector2(22, 70)), false)
		_outline(Rect2(center + Vector2(48, -52), Vector2(22, 70)), true)
		for side: float in [-1.0, 1.0]:
			draw_line(center + Vector2(side * 20, 14), center + Vector2(side * 26, 88), PHOSPHOR, 3.0)
		write("BRAZO DERECHO ROTO", Vector2(14, 222), 13, PHOSPHOR, 2.0)

	func _outline(box: Rect2, broken: bool) -> void:
		if not broken:
			draw_rect(box, PHOSPHOR, false, 3.0)
			return
		var corners: Array[Vector2] = [box.position, box.position + Vector2(box.size.x, 0), box.end, box.position + Vector2(0, box.size.y)]
		for k in 4:
			draw_dashed_line(corners[k], corners[(k + 1) % 4], PHOSPHOR, 3.0, 8.0)
