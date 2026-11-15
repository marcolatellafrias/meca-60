class_name SeatStrip
extends Node3D

## LA TIRA QUE TIENEN TODOS LOS PUESTOS (14/11/2026, ver SeatPanels y docs/conceptual/armamento.md, «El tablero mínimo»):
## una pantalla chica, fija adelante y abajo, inclinada hacia el que va sentado. A la izquierda, LA ENERGÍA (todavía no
## existe: la barra queda vacía); a la derecha, LA MECA DIBUJADA EN CONTORNO, de frente y de costado, inclinada como está
## (adentro no se siente cómo está parada: el usuario quería «spatial awareness»).

const SIZE := Vector2(0.4, 0.18)
const PIXELS := Vector2i(400, 180)
const LINE := Color(0.35, 0.95, 1.0)
const BACK := Color(0.06, 0.08, 0.1)

var mech: Mech = null
var _drawing: _Drawing = null


func _ready() -> void:
	var view := SubViewport.new()
	view.size = PIXELS
	view.transparent_bg = false
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(view)
	_drawing = _Drawing.new()
	_drawing.mech = mech
	_drawing.size = Vector2(PIXELS)
	view.add_child(_drawing)
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = SIZE
	screen.mesh = quad
	var look := StandardMaterial3D.new()
	look.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	look.albedo_texture = view.get_texture()
	screen.material_override = look
	screen.position = Vector3(0, 0, 0.012)
	add_child(screen)
	Clay.box(self, Vector3(SIZE.x + 0.04, SIZE.y + 0.04, 0.02), Vector3.ZERO, SeatPanels.FRAME)


func place(where: Transform3D) -> void:
	transform = where


## Lo que se dibuja en la pantalla, cada cuadro.
class _Drawing extends Control:
	var mech: Mech = null

	func _process(_delta: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), BACK)
		# La energía: el marco y lo que hay (nada, por ahora).
		draw_rect(Rect2(Vector2(20, 24), Vector2(34, 132)), LINE, false, 2.0)
		draw_string(ThemeDB.fallback_font, Vector2(14, 172), "energía", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, LINE)
		if not is_instance_valid(mech):
			return
		# Cuánto se inclina de costado (rolido) y hacia adelante (cabeceo), visto desde la meca.
		var up := mech.global_basis.inverse() * Vector3.UP
		var roll := atan2(-up.x, up.y)
		var pitch := atan2(up.z, up.y)
		_mech(Vector2(160, 92), roll, "de frente")
		_mech(Vector2(300, 92), -pitch, "de costado")

	## La meca de frente o de costado, en contorno: la caja, las dos piernas y los brazos, girada `tilt`.
	func _mech(center: Vector2, tilt: float, label: String) -> void:
		var turn := Transform2D(tilt, center)
		var box := PackedVector2Array([Vector2(-26, -50), Vector2(26, -50), Vector2(26, 2), Vector2(-26, 2), Vector2(-26, -50)])
		draw_polyline(turn * box, LINE, 2.0)
		for side: float in [-1.0, 1.0]:
			draw_line(turn * Vector2(side * 14, 2), turn * Vector2(side * 18, 26), LINE, 2.0)
			draw_line(turn * Vector2(side * 18, 26), turn * Vector2(side * 14, 50), LINE, 2.0)
			draw_line(turn * Vector2(side * 30, -36), turn * Vector2(side * 34, -6), LINE, 2.0)
		draw_line(center + Vector2(-50, 52), center + Vector2(50, 52), Color(LINE, 0.35), 1.0)
		draw_string(ThemeDB.fallback_font, center + Vector2(-30, 74), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, LINE)
