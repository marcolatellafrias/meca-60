class_name RoundShapePanel
extends TunerPanel

## LA FORMA DE LA MECA REDONDA (F2 en la fila «Meca redonda»; ver RoundGrid, RoundShape): el radio y los lados, el alto
## de la cabina, el disco de abajo, la tarima, el ascensor y el vidrio. Como el de la cuadrada (CabinShapePanel): los
## números se mueven sin rearmar nada, y GUARDAR la escribe en `RoundGrid.SAVED` y rearma las mecas (la cuadrada no
## cambia: tiene su forma aparte).
##   · BRAZOS Y PIERNAS (el usuario, 15/11/2026: «hay cosas que no están en los paneles del cilíndrico, como los
##     distintos tamaños y grosores de piernas y brazos»): la misma pestaña que el F2 de la cuadrada. EL CUERPO ES UNO
##     SOLO PARA TODAS LAS MECAS (MechBody.dress): se guarda donde lo guarda la cuadrada (CabinGrid.SAVED), y cambiarlo
##     acá lo cambia también allá.

const PANEL_WIDTH := 380.0
const LABELS := {
	"sides": "lados de adentro",
	"radius": "radio de adentro, a un vértice (m)",
	"clear_height": "alto libre de la cabina (m)",
	"disc_height": "alto del disco de abajo (m)",
	"dome": "domo arriba (abierto por dentro)",
	"dome_rise": "cuánto sube el domo (1 media esfera, menos más chato)",
	"platform_radius": "radio de la tarima (m)",
	"platform_height": "alto de la tarima (m)",
	"lift_radius": "radio del ascensor (m)",
	"lift_back": "ascensor corrido atrás (m)",
	"glass_sides": "lados de vidrio, al frente",
	"visor_height": "alto del visor, desde el piso (m)",
	"glass_color": "color del vidrio",
	"glass_opacity": "cuánto se ve el vidrio (0 nada, 1 opaco)",
}
const PARTS := ["La caja", "La tarima y el ascensor", "El vidrio"]
## La pestaña del cuerpo, con sus nombres (los del F2 de la cuadrada).
const BODY_PART := "Brazos y piernas"

var _draft := RoundGrid.current()
## El cuerpo: la forma de la cuadrada entera (ahí se guarda), de la que acá sólo se toca la pestaña del cuerpo.
var _body := CabinGrid.current()
var _state: Label = null


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("cabina redonda", "FORMA DE LA MECA REDONDA", [
		new_button("Guardar (la forma de las mecas redondas)", _save),
		new_button("Volver a lo guardado", _restore),
	])
	_state = state_label()
	_measure()


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for part: String in PARTS:
		all.append({"title": part.to_upper(), "tab": part, "target": _draft, "labels": LABELS,
			"include": PackedStringArray([part]), "headers": false, "defaults": RoundShape.new(), "on_change": _measure})
	all.append({"title": BODY_PART.to_upper(), "tab": BODY_PART, "target": _body, "labels": CabinShapePanel.LABELS,
		"include": PackedStringArray([BODY_PART]), "headers": false, "defaults": CabinShape.new(), "on_change": _measure})
	return all


## Lo que sale de los números, sin rearmar nada.
func _measure() -> void:
	if _state == null:
		return
	var apothem := _draft.radius * cos(PI / maxi(_draft.sides, 6))
	var top := (apothem + RoundGrid.WALL) * _draft.dome_rise if _draft.dome else RoundGrid.SLAB
	_state.text = "por fuera, %.2f m de diámetro y %.2f m de alto (la cabina %.2f m libres, el disco %.2f m) · la caja va a %.2f m del piso (sale de las piernas)" % [
		(apothem + RoundGrid.WALL) * 2.0, _draft.disc_height + _draft.clear_height + RoundGrid.SLAB + top,
		_draft.clear_height, _draft.disc_height, MechBody.waist_for(_body.thickness, _body.leg_length, _body.leg_stretch)]


func _save() -> void:
	RoundGrid.apply(_draft)
	# El cuerpo, para todas las mecas: se guarda con la forma de la cuadrada, la de AHORA (si se la cambió en su F2
	# después de abrir este, no se la pisa): de acá, sólo los campos del cuerpo.
	var square := CabinGrid.current()
	for field: String in ["arm_length", "leg_length", "thickness", "leg_stretch"]:
		square.set(field, _body.get(field))
	CabinGrid.apply(square)
	var body_error := ResourceSaver.save(CabinGrid.current(), CabinGrid.SAVED)
	if body_error != OK:
		push_warning("RoundShapePanel: no se pudo guardar el cuerpo en %s (%d)" % [CabinGrid.SAVED, body_error])
	Mech.rebuild_all(get_tree())
	_measure()
	var error := ResourceSaver.save(RoundGrid.current(), RoundGrid.SAVED)
	if error != OK:
		push_warning("RoundShapePanel: no se pudo guardar %s (%d)" % [RoundGrid.SAVED, error])
	elif _state != null:
		_state.text += " · guardada"


func _restore() -> void:
	var saved := load(RoundGrid.SAVED) as RoundShape if ResourceLoader.exists(RoundGrid.SAVED) else RoundShape.new()
	for property in _draft.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_draft.set(property["name"], saved.get(property["name"]))
	var body := load(CabinGrid.SAVED) as CabinShape if ResourceLoader.exists(CabinGrid.SAVED) else CabinShape.new()
	for property in _body.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_body.set(property["name"], body.get(property["name"]))
	rebuild()
	RoundGrid.apply(_draft)
	CabinGrid.apply(_body)
	Mech.rebuild_all(get_tree())
	_measure()
