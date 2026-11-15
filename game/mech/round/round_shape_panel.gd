class_name RoundShapePanel
extends TunerPanel

## LA FORMA DE LA MECA REDONDA (F2 en la fila «Meca redonda»; ver RoundGrid, RoundShape): el radio y los lados, el alto
## de la cabina, el disco de abajo, la tarima, el ascensor y el vidrio. Como el de la cuadrada (CabinShapePanel): los
## números se mueven sin rearmar nada, y GUARDAR la escribe en `RoundGrid.SAVED` y rearma las mecas (la cuadrada no
## cambia: tiene su forma aparte).

const PANEL_WIDTH := 380.0
const LABELS := {
	"sides": "lados de adentro",
	"radius": "radio de adentro, a un vértice (m)",
	"clear_height": "alto libre de la cabina (m)",
	"disc_height": "alto del disco de abajo (m)",
	"platform_radius": "radio de la tarima (m)",
	"platform_height": "alto de la tarima (m)",
	"lift_radius": "radio del ascensor (m)",
	"lift_back": "ascensor corrido atrás (m)",
	"glass_sides": "lados de vidrio, al frente",
	"glass_color": "color del vidrio",
	"glass_opacity": "cuánto se ve el vidrio (0 nada, 1 opaco)",
}
const PARTS := ["La caja", "La tarima y el ascensor", "El vidrio"]

var _draft := RoundGrid.current()
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
	return all


## Lo que sale de los números, sin rearmar nada.
func _measure() -> void:
	if _state == null:
		return
	var apothem := _draft.radius * cos(PI / maxi(_draft.sides, 6))
	_state.text = "por fuera, %.2f m de diámetro y %.2f m de alto (la cabina %.2f m libres, el disco %.2f m)" % [
		(apothem + RoundGrid.WALL) * 2.0, _draft.disc_height + _draft.clear_height + RoundGrid.SLAB * 2.0,
		_draft.clear_height, _draft.disc_height]


func _save() -> void:
	RoundGrid.apply(_draft)
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
	rebuild()
	RoundGrid.apply(_draft)
	Mech.rebuild_all(get_tree())
	_measure()
