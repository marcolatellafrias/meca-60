class_name MechHud
extends CanvasLayer

## LO QUE SE VE EN PANTALLA SENTADO EN LA MECA, mientras se prueba: la mira en el medio y, abajo a la izquierda, el
## puesto, sus teclas y el estado (equilibrio, si está afirmada o caída, si los brazos están listos). No es la
## interfaz del juego: es para probar el boceto. Parado no se ve.

var _dot: ColorRect = null
var _text: Label = null


func _ready() -> void:
	layer = 20
	_dot = ColorRect.new()
	_dot.color = Color(1, 1, 1, 0.9)
	_dot.size = Vector2(6, 6)
	_dot.set_anchors_preset(Control.PRESET_CENTER)
	_dot.position -= _dot.size * 0.5
	# La mira está justo donde queda el mouse capturado: si lo atajara, la meca no recibiría ni el movimiento ni los
	# clics (así pasaba el 11/11/2026: el mouse sentado no movía nada).
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dot)
	_text = Label.new()
	_text.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_text.position = Vector2(20, -210)
	_text.add_theme_font_size_override("font_size", 18)
	_text.add_theme_color_override("font_color", Color(1, 1, 1))
	_text.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_text.add_theme_constant_override("outline_size", 6)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	visible = false


func show_state(mech: Mech, seat: MechSeat) -> void:
	visible = seat != null
	if seat == null:
		return
	var lines := PackedStringArray()
	lines.append("PUESTO: %s   (E se levanta)" % str(MechSeat.NAMES[seat.station]).to_upper())
	match seat.station:
		MechSeat.Station.LEGS:
			lines.append("W/S camina · A/D gira · Shift se afirma")
		MechSeat.Station.ARMS:
			lines.append("mouse apunta · clic izq. puño · clic der. cañón")
		MechSeat.Station.LOOKOUT:
			lines.append("mouse gira la cámara de afuera")
	lines.append("desde cualquier puesto: flechas caminan · B se afirma · F puño · G cañón")
	var states := ["parada", "CAYÉNDOSE", "EN EL SUELO", "levantándose"]
	lines.append("equilibrio %d %%  ·  %s" % [roundi(mech.stability.length() * 100.0), states[mech.state]])
	lines.append("puño %s  ·  cañón %s" % ["listo" if mech.fist.ready_to_use() else "…",
		"listo" if mech.cannon.ready_to_use() else "recargando"])
	_text.text = "\n".join(lines)
