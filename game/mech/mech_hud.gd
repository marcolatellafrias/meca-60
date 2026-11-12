class_name MechHud
extends CanvasLayer

## LO QUE SE VE EN PANTALLA SENTADO EN LA MECA, mientras se prueba: la mira en el medio y, abajo a la izquierda, el
## puesto, sus teclas y el estado (equilibrio, si está afirmada o caída, los brazos y el rival). No es la
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
	_text.add_theme_font_size_override("font_size", 18)
	_text.add_theme_color_override("font_color", Color(1, 1, 1))
	_text.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	_text.add_theme_constant_override("outline_size", 6)
	_text.add_theme_constant_override("line_spacing", 2)
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text)
	visible = false


func show_state(mech: Mech, seat: MechSeat) -> void:
	var outside := mech.driven_from_outside()
	visible = seat != null or outside
	if not visible:
		return
	var lines := PackedStringArray()
	if outside:
		lines.append("DESDE AFUERA   (O o E vuelve · T primera / tercera persona)")
		lines.append("WASD piernas · mouse gira el torso · Shift se afirma")
		lines.append("clic izq. / der.: mantener carga, soltar pega · el mouse dobla la piña que sale · G cañón")
	else:
		lines.append("PUESTO: %s   (E se levanta)" % str(MechSeat.NAMES[seat.station]).to_upper())
		match seat.station:
			MechSeat.Station.LEGS:
				lines.append("W/S camina · A/D gira las piernas · Shift se afirma")
			MechSeat.Station.ARMS:
				lines.append("se apunta mirando · Z/X gira el torso · G cañón")
				lines.append("clics: mantener carga, soltar pega · el mouse dobla la piña")
			MechSeat.Station.LOOKOUT:
				lines.append("mouse gira la cámara de afuera")
		lines.append("desde cualquier puesto: flechas caminan · B se afirma · Z/X torso · F/H brazos · G cañón")
	var states := ["parada", "CAYÉNDOSE", "EN EL SUELO", "levantándose"]
	lines.append("equilibrio %d %%  ·  %s  ·  golpes recibidos %d" % [roundi(mech.stability.length() * 100.0),
		states[mech.state], mech.hits_taken])
	lines.append("brazo izq. %s  ·  brazo der. %s  ·  cañón %s" % [_arm_text(mech.left_arm), _arm_text(mech.right_arm),
		"listo" if mech.right_arm.cannon_ready() else "recargando"])
	if mech.opponent != null:
		var rival := mech.opponent
		var mode := str(MechBrain.NAMES[rival.brain.mode]) if rival.brain != null else "—"
		lines.append("RIVAL (%s): equilibrio %d %%  ·  %s  ·  último golpe ×%.1f" % [mode,
			roundi(rival.stability.length() * 100.0), states[rival.state], rival.last_weakness])
	_text.text = "\n".join(lines)
	# Pegado abajo a la izquierda, del alto justo del texto.
	_text.size = Vector2.ZERO
	_text.position = Vector2(20.0, _text.get_viewport_rect().size.y - _text.get_combined_minimum_size().y - 20.0)


func _arm_text(arm: MechArm) -> String:
	var text := str(MechArm.NAMES[arm.phase])
	if arm.phase == MechArm.Phase.CHARGE:
		text += " %d %%" % roundi(arm.charge * 100.0)
	elif arm.last_hit_speed > 0.0:
		text += " (pegó a %d m/s)" % roundi(arm.last_hit_speed)
	elif arm.jammed:
		text += " (trabado)"
	return text
