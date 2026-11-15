class_name VortexShapePanel
extends TunerPanel

## LA FORMA DE LA MECA DEL VÓRTICE (F2 en su fila; ver VortexCabin, VortexShape): el radio, el alto de la planta baja,
## el núcleo y el vórtice, el ancho de la escalera y, en la pestaña «Brazos y piernas», LA MISMA DEL F2 DE LAS OTRAS
## (CabinShapePanel: los mismos campos y nombres), pero de esta meca sola. Como el de la redonda (RoundShapePanel): los
## números se mueven sin rearmar nada, y GUARDAR la escribe en `VortexCabin.SAVED` y rearma las mecas (las otras no
## cambian: esta tiene su forma y su cuerpo aparte).

const PANEL_WIDTH := 380.0
const LABELS := {
	"radius": "radio del disco (m)",
	"floor_height": "alto de la planta baja (m)",
	"core": "núcleo en el medio del primer piso (arriba se camina en anillo)",
	"back_raised": "atrás, el borde más alto (con un escalón)",
	"vortex_radius": "radio del vórtice, el hueco de la planta baja (m)",
	"stair_width": "ancho de la escalera caracol (m)",
}
const PARTS := ["El disco", "La escalera", "Brazos y piernas"]

var _draft := VortexCabin.current()
var _state: Label = null


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("meca del vórtice", "FORMA DE LA MECA DEL VÓRTICE", [
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
			"include": PackedStringArray([part]), "headers": false, "defaults": VortexShape.new(), "on_change": _measure})
	return all


## Lo que sale de los números, sin rearmar nada.
func _measure() -> void:
	if _state == null:
		return
	_state.text = "por fuera, %.1f m de diámetro · la escalera, %.2f m de ancho · arriba %s" % [_draft.radius * 2.0,
		_draft.stair_width, "en anillo, alrededor del núcleo" if _draft.core else "un piso entero, sin núcleo"]


func _save() -> void:
	VortexCabin.apply(_draft)
	Mech.rebuild_all(get_tree())
	_measure()
	var error := ResourceSaver.save(VortexCabin.current(), VortexCabin.SAVED)
	if error != OK:
		push_warning("VortexShapePanel: no se pudo guardar %s (%d)" % [VortexCabin.SAVED, error])
	elif _state != null:
		_state.text += " · guardada"


func _restore() -> void:
	var saved := load(VortexCabin.SAVED) as VortexShape if ResourceLoader.exists(VortexCabin.SAVED) else VortexShape.new()
	for property in _draft.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_draft.set(property["name"], saved.get(property["name"]))
	rebuild()
	VortexCabin.apply(_draft)
	Mech.rebuild_all(get_tree())
	_measure()
