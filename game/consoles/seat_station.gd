class_name SeatStation
extends Node3D

## EL PUESTO DE UNA SILLA DE ADELANTE (15/11/2026, ver docs/conceptual/armamento.md, «El puesto: holograma, botones y
## estado», y docs/technical/paneles.md). Reemplaza al panel que se traía (SeatPanels). Va en el hueco del tablero de
## cada puesto abierto, mirando a su silla:
##   · AL MEDIO, EL HOLOGRAMA: sube de una ranura del tablero. Es la mira, con LA ENERGÍA SIEMPRE a la izquierda (se
##     calcula antes de cada acción) y lo del sistema elegido.
##   · A LOS COSTADOS, MÓDULOS PAREJOS: un cubo (`CUBE`) y rectángulos de su mismo ancho y fondo y la mitad de alto
##     (`SLAB`). A la izquierda, eyectar (un rectángulo) con el cubo de estado encima; a la derecha, los botones. Todo lo
##     que se usa va en la cara que mira a la silla; las otras caras, vacías.
##   · DE TALLER, NO FUTURISTA: chapa pintada, baquelita, lamparitas. El holograma sigue siendo holograma, en naranja.
## TODAVÍA DE ARCILLA: nada funciona. El holograma muestra la mira fija y los botones no se aprietan. Las pantallas se
## dibujan una sola vez (no cambian), así seis pantallas no cuestan cada cuadro.

## El cubo de los módulos; los rectángulos, del mismo ancho y fondo y la mitad de alto.
const CUBE := 0.28
const SLAB := CUBE * 0.5
const HOLO_SIZE := Vector2(0.66, 0.4)
const HOLO_PIXELS := Vector2i(660, 400)
const HOLO := Color(1.0, 0.62, 0.25)
const PAINT := Color(0.42, 0.45, 0.43)
const PLINTH := Color(0.22, 0.23, 0.23)
const CAP_LIGHT := Color(0.86, 0.83, 0.74)
const CAP_DARK := Color(0.12, 0.12, 0.12)
const RING := Color(0.6, 0.62, 0.64)
const LAMP_ON := Color(1.0, 0.68, 0.25)
const LAMP_OFF := Color(0.35, 0.28, 0.2)
const INK := Color(0.08, 0.08, 0.08)
const PHOSPHOR := Color(0.45, 1.0, 0.55)
const EJECT_GLASS := Color(0.75, 0.85, 0.9, 0.22)

## Lo que maneja cada puesto de adelante, en el orden de MechCabin.POSTS: el nombre en el holograma, los botones (el
## primero, elegido) y la parte de la meca que es suya en la pantalla de estado.
const SYSTEMS := [
	{"name": "BRAZO IZQUIERDO", "buttons": ["PIÑA", "AGARRE", "SIERRA"], "part": "brazo izquierdo"},
	{"name": "ESPALDA", "buttons": ["AMETRALLADORA", "MISILES"], "part": "espalda"},
	{"name": "BRAZO DERECHO", "buttons": ["PIÑA", "AGARRE", "CAÑÓN"], "part": "brazo derecho"},
]

var system: Dictionary = {}


## Pone un puesto en cada silla de adelante cuyo puesto esté abierto (CabinGrid.OPEN_POSTS).
static func attach(cabin: MechCabin) -> void:
	for post in mini(3, cabin.chairs.size()):
		if not CabinGrid.OPEN_POSTS[post]:
			continue
		var chair := cabin.chairs[post]
		var station := SeatStation.new()
		station.name = "Puesto %s" % MechCabin.POSTS[post]
		station.system = SYSTEMS[post]
		station.transform = Transform3D(chair.transform.basis.orthonormalized(), chair.position)
		cabin.add_child(station)


## Todo en el espacio de la silla (mira a −Z, el piso en y = 0): el tablero tiene su cara de atrás en z = −0,75 trama y
## su tapa en y = DESK_HEIGHT; los módulos, contra los costados del hueco (CabinGrid.hole_cells).
func _ready() -> void:
	var top := CabinGrid.DESK_HEIGHT
	var back := -0.75 * CabinGrid.TRAMA
	_hologram(Vector3(0, top, back - 0.14))
	var side := CabinGrid.hole_cells() * CabinGrid.TRAMA * 0.5 - CUBE * 0.5 - 0.03
	var left := _module(Vector3(-side, top, back - 0.2), 1.0)
	_eject(left)
	_status(left, Vector3(0, SLAB, 0))
	var right := _module(Vector3(side, top, back - 0.2), -1.0)
	_buttons(right, system.buttons, 0)


## Un lugar para módulos sobre el tablero, girado hacia la silla (`turn` +1 si está a la izquierda, −1 a la derecha).
func _module(at: Vector3, turn: float) -> Node3D:
	var spot := Node3D.new()
	add_child(spot)
	spot.position = at
	spot.rotation_degrees = Vector3(0, turn * 22.0, 0)
	return spot


## Una caja de módulo de `tall` de alto, con su zócalo más oscuro, apoyada en `at` (su base).
func _box(parent: Node3D, at: Vector3, tall: float) -> void:
	Clay.box(parent, Vector3(CUBE, tall - 0.012, CUBE), at + Vector3(0, 0.012 + (tall - 0.012) * 0.5, 0), PAINT)
	Clay.box(parent, Vector3(CUBE - 0.012, 0.012, CUBE - 0.012), at + Vector3(0, 0.006, 0), PLINTH)


## LOS BOTONES: un rectángulo con un botón de baquelita por opción y una lamparita sobre el que está elegido, todo en
## la cara que mira a la silla.
func _buttons(spot: Node3D, names: Array, chosen: int) -> void:
	_box(spot, Vector3.ZERO, SLAB)
	for index in names.size():
		var x := (index + 0.5) / names.size() * CUBE - CUBE * 0.5
		var on := index == chosen
		# La lamparita arriba, el botón al medio, el nombre abajo.
		var face := Vector3(x, SLAB * 0.55, CUBE * 0.5)
		Clay.cylinder(spot, 0.031, 0.008, face + Vector3(0, 0, 0.004), RING, Vector3(90, 0, 0))
		Clay.cylinder(spot, 0.024, 0.006 if on else 0.018, face + Vector3(0, 0, 0.011 if on else 0.012),
			CAP_DARK if on else CAP_LIGHT, Vector3(90, 0, 0))
		Clay.sphere(spot, 0.007, Vector3(x, SLAB - 0.016, CUBE * 0.5), LAMP_ON if on else LAMP_OFF)
		var label := StrokeLabel.make(names[index], 0.013, INK)
		label.max_width = CUBE / names.size() - 0.02
		label.position = Vector3(x, 0.022, CUBE * 0.5 + 0.001)
		spot.add_child(label)


## EYECTAR: un rectángulo con un hongo rojo al frente, bajo una tapa de vidrio (trabada hasta que la meca está por
## explotar). Arriba va el cubo de estado.
func _eject(spot: Node3D) -> void:
	_box(spot, Vector3.ZERO, SLAB)
	var face := Vector3(0, SLAB * 0.5 + 0.02, CUBE * 0.5)
	Clay.cylinder(spot, 0.04, 0.01, face + Vector3(0, 0, 0.005), RING, Vector3(90, 0, 0))
	Clay.cylinder(spot, 0.032, 0.03, face + Vector3(0, 0, 0.018), Clay.RED, Vector3(90, 0, 0))
	Clay.box(spot, Vector3(0.09, 0.085, 0.045), face + Vector3(0, 0, 0.024), EJECT_GLASS)
	var label := StrokeLabel.make("EYECTAR", 0.016, INK)
	label.position = Vector3(0, 0.022, CUBE * 0.5 + 0.001)
	spot.add_child(label)


## EL ESTADO: un cubo con una pantalla de fósforo hacia la silla: la meca de frente, cada parte que se rompe; la rota,
## punteada (en la arcilla, el brazo derecho).
func _status(spot: Node3D, base: Vector3) -> void:
	_box(spot, base, CUBE)
	var drawing := _StatusDrawing.new()
	drawing.part = system.part
	var screen := _screen(spot, drawing, Vector2i(240, 240), Vector2.ONE * CUBE * 0.72, false)
	screen.position = base + Vector3(0, CUBE * 0.5, CUBE * 0.5 + 0.003)
	var rim := CUBE * 0.72 + 0.03
	for edge: float in [-1.0, 1.0]:
		Clay.box(spot, Vector3(rim, 0.015, 0.012), base + Vector3(0, CUBE * 0.5 + edge * (rim - 0.015) * 0.5, CUBE * 0.5 + 0.006),
			PLINTH)
		Clay.box(spot, Vector3(0.015, rim, 0.012), base + Vector3(edge * (rim - 0.015) * 0.5, CUBE * 0.5, CUBE * 0.5 + 0.006),
			PLINTH)


## EL HOLOGRAMA: un vidrio de luz que sube de una ranura del tablero.
func _hologram(base: Vector3) -> void:
	var drawing := _HoloDrawing.new()
	drawing.title = system.name
	var sheet := _screen(self, drawing, HOLO_PIXELS, HOLO_SIZE, true)
	sheet.position = base + Vector3(0, 0.06 + HOLO_SIZE.y * 0.5, 0)
	Clay.box(self, Vector3(HOLO_SIZE.x + 0.06, 0.03, 0.07), base + Vector3(0, 0.015, 0), PLINTH)
	Clay.box(self, Vector3(HOLO_SIZE.x, 0.004, 0.012), base + Vector3(0, 0.031, 0), HOLO)


## Una pantalla: `drawing` dibujado una vez en una textura de `pixels`, sobre un cuadro de `size` metros. `glass`: se
## ve de los dos lados y deja ver a través (el holograma).
func _screen(parent: Node3D, drawing: Control, pixels: Vector2i, size: Vector2, glass: bool) -> MeshInstance3D:
	var view := SubViewport.new()
	view.size = pixels
	view.transparent_bg = glass
	view.render_target_update_mode = SubViewport.UPDATE_ONCE
	parent.add_child(view)
	drawing.size = Vector2(pixels)
	view.add_child(drawing)
	var sheet := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	sheet.mesh = quad
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_texture = view.get_texture()
	if glass:
		look.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		look.cull_mode = BaseMaterial3D.CULL_DISABLED
	sheet.material_override = look
	parent.add_child(sheet)
	return sheet


## Un dibujo 2D que escribe con la letra del juego (StrokeFont).
class _Screen extends Control:
	## Escribe `text`: `at` es la esquina de abajo a la izquierda.
	func write(text: String, at: Vector2, height: float, color: Color, width := 2.0) -> void:
		var lines := StrokeFont.segments(text, height, StrokeFont.Align.LEFT)
		for k in range(0, lines.size(), 2):
			draw_line(at + Vector2(lines[k].x, -lines[k].y - height * 0.5),
				at + Vector2(lines[k + 1].x, -lines[k + 1].y - height * 0.5), color, width)


## Lo que dibuja el holograma: la mira al medio, LA ENERGÍA SIEMPRE a la izquierda (el máximo que le queda, la raya
## roja) y el nombre del sistema.
class _HoloDrawing extends _Screen:
	var title := ""

	func _draw() -> void:
		var middle := size * 0.5 + Vector2(20, 0)
		var faint := Color(HOLO, 0.7)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.05, 0.02, 0.35))
		draw_rect(Rect2(Vector2(2, 2), size - Vector2(4, 4)), faint, false, 2.0)
		draw_arc(middle, 18, 0, TAU, 32, HOLO, 3.0)
		for way: Vector2 in [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]:
			draw_line(middle + way * 24, middle + way * 42, HOLO, 3.0)
		write(title, Vector2(110, 44), 22, HOLO, 3.0)
		var bar := Rect2(Vector2(30, 40), Vector2(34, 300))
		draw_rect(bar, HOLO, false, 2.0)
		draw_rect(Rect2(bar.position + Vector2(0, bar.size.y * 0.45), Vector2(bar.size.x, bar.size.y * 0.55)), Color(HOLO, 0.6))
		draw_line(bar.position + Vector2(-6, bar.size.y * 0.15), bar.position + Vector2(bar.size.x + 6, bar.size.y * 0.15),
			Color(1.0, 0.35, 0.25), 3.0)
		write("ENERGÍA", Vector2(12, 374), 14, HOLO, 2.0)


## La pantalla de estado: la meca de frente con cada parte que se rompe; la rota, punteada.
class _StatusDrawing extends _Screen:
	var part := ""

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.07, 0.04))
		var center := Vector2(120, 104)
		_outline(Rect2(center + Vector2(-38, -62), Vector2(76, 76)), false)
		_outline(Rect2(center + Vector2(-70, -52), Vector2(22, 70)), false)
		_outline(Rect2(center + Vector2(48, -52), Vector2(22, 70)), true)
		for edge: float in [-1.0, 1.0]:
			draw_line(center + Vector2(edge * 20, 14), center + Vector2(edge * 26, 88), PHOSPHOR, 3.0)
		write(part.to_upper(), Vector2(14, 222), 13, PHOSPHOR, 2.0)

	func _outline(box: Rect2, broken: bool) -> void:
		if not broken:
			draw_rect(box, PHOSPHOR, false, 3.0)
			return
		var corners: Array[Vector2] = [box.position, box.position + Vector2(box.size.x, 0), box.end,
			box.position + Vector2(0, box.size.y)]
		for k in 4:
			draw_dashed_line(corners[k], corners[(k + 1) % 4], PHOSPHOR, 3.0, 8.0)
