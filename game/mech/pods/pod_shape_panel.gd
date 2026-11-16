class_name PodShapePanel
extends TunerPanel

## LA FORMA DE LA MECA DE CÁPSULAS (F2 en su fila; ver PodCabin, PodShape): el torso (radio, pared, domo, borde), el
## radial de las cápsulas y el de los hombros, aparte, y en la pestaña «Brazos y piernas», LA MISMA DEL F2 DE LAS OTRAS
## (CabinShapePanel: los mismos campos y nombres), pero de esta meca sola. Como el de la del vórtice (VortexShapePanel):
## los números se mueven sin rearmar nada, y GUARDAR la escribe en `PodCabin.SAVED` y rearma las mecas.

const PANEL_WIDTH := 380.0
const LABELS := {
	"radius": "radio del torso (m)",
	"wall": "alto de la parte cilíndrica (m)",
	"dome": "alto del domo de arriba (m)",
	"edge": "borde de abajo, redondeado (m)",
	"pod_step": "las cápsulas de los costados, a (° del frente)",
	"pod_out": "cuánto asoman las cápsulas (partes del diámetro)",
	"window": "la ventana de cada cápsula (° desde su centro)",
	"shoulder_step": "los hombros, a (° del frente)",
}
const PARTS := ["El cuerpo", "Las cápsulas", "Los hombros", "Brazos y piernas"]

var _draft := PodCabin.current()
var _state: Label = null


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("meca de cápsulas", "FORMA DE LA MECA DE CÁPSULAS", [
		new_button("Guardar (rearma la meca)", _save),
		new_button("Volver a lo guardado", _restore),
	])
	_state = state_label()
	_measure()


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for part: String in PARTS:
		all.append({"title": part.to_upper(), "tab": part, "target": _draft,
			"labels": CabinShapePanel.LABELS if part == "Brazos y piernas" else LABELS,
			"include": PackedStringArray([part]), "headers": false, "defaults": PodShape.new(), "on_change": _measure})
	return all


## Lo que sale de los números, sin rearmar nada.
func _measure() -> void:
	if _state == null:
		return
	_state.text = "%.1f m de diámetro y %.1f de alto · cápsulas a ±%d°, hombros a ±%d°" % [_draft.radius * 2.0,
		_draft.edge + _draft.wall + _draft.dome, int(_draft.pod_step), int(_draft.shoulder_step)]


func _save() -> void:
	PodCabin.apply(_draft)
	Mech.rebuild_all(get_tree())
	_measure()
	var error := ResourceSaver.save(PodCabin.current(), PodCabin.SAVED)
	if error != OK:
		push_warning("PodShapePanel: no se pudo guardar %s (%d)" % [PodCabin.SAVED, error])
	elif _state != null:
		_state.text += " · guardada"


func _restore() -> void:
	var saved := load(PodCabin.SAVED) as PodShape if ResourceLoader.exists(PodCabin.SAVED) else PodShape.new()
	for property in _draft.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_draft.set(property["name"], saved.get(property["name"]))
	rebuild()
	PodCabin.apply(_draft)
	Mech.rebuild_all(get_tree())
	_measure()
