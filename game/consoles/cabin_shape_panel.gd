class_name CabinShapePanel
extends TunerPanel

## LA FORMA DE LA MECA (F2 en sus filas): la trama de la cabina (la celda, cuántas por lado), el alto, el corte del
## vidrio, el ascensor, las sillas y el cuerpo (el largo de brazos y piernas, el ancho y cuánto se estiran las piernas).
## Ver CabinGrid.apply. Lo pidió el usuario el 13/11/2026 («un panel F que podamos usar en cualquiera de las parcelas
## que tienen la meca… tiene que tener botón de guardado, y si guardo algo… se va a actualizar en todas las mecas»).
##   · Los números se mueven sin rearmar nada: abajo dicen qué medidas salen, también LA ALTURA DE LA CAJA SOBRE EL PISO,
##     que no es una perilla: sale del largo y lo estirado de las piernas.
##   · GUARDAR (el único: «Probar» se sacó el 13/11/2026) la escribe en `CabinGrid.SAVED` y rearma todas las mecas: es
##     la forma de todas, también al reiniciar.

const PANEL_WIDTH := 380.0
const LABELS := {
	"cell": "celda de la trama (celdas de 3,9 cm)",
	"across": "celdas por lado",
	"height_cells": "alto libre (celdas de 3,9 cm)",
	"chamfer": "corte del vidrio de arriba (celdas de la trama)",
	"side_glass": "vidrio de los costados, hasta (celdas de la trama)",
	"roof_glass": "vidrio del techo, hasta (celdas de la trama)",
	"lift_radius": "radio del ascensor (celdas de 3,9 cm)",
	"lift_square": "ascensor cuadrado",
	"glass_color": "color del vidrio",
	"glass_opacity": "cuánto se ve el vidrio (0 nada, 1 opaco)",
	"frame_kind": "marco del vidrio",
	"edge_thickness": "grosor de las aristas (m)",
	"post_thickness": "grosor de los parantes (m)",
	"platform_height": "alto de la tarima de atrás (m)",
	"eye_height": "altura de los ojos que buscan (m)",
	"arm_length": "largo de los brazos",
	"leg_length": "largo de las piernas",
	"thickness": "ancho (de los dos)",
	"leg_stretch": "cuánto se estiran las piernas paradas",
	"shoulder_out": "cuánto salen los hombros del costado (m)",
}

## Las partes del panel: los grupos de CabinShape, en orden.
const PARTS := ["La caja", "El vidrio", "Las sillas", "Brazos y piernas"]

var _draft := CabinGrid.current()
var _state: Label = null


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	# Un solo «Guardar», que aplica y rearma (el usuario, 13/11/2026: «borraría lo de probar y dejaría solamente
	# guardar»; ver KnobsPanel, que hace lo mismo para las perillas).
	setup("cabina", "FORMA DE LA MECA", [
		new_button("Guardar (la forma de todas las mecas)", _save),
		new_button("Volver a lo guardado", _restore),
	])
	_state = state_label()
	_measure()


func sections() -> Array[Dictionary]:
	# UNA PESTAÑA POR PARTE (el usuario, 13/11/2026: «separada por partes con labels… como tabs arriba»): los grupos
	# de CabinShape.
	var all: Array[Dictionary] = []
	for part: String in PARTS:
		all.append({"title": part.to_upper(), "tab": part, "target": _draft, "labels": LABELS,
			"include": PackedStringArray([part]), "headers": false, "defaults": CabinShape.new(), "on_change": _measure})
	return all


## Lo que sale de los números, sin rearmar nada.
func _measure() -> void:
	if _state == null:
		return
	var trama := _draft.cell * CabinGrid.CELL
	var inner := _draft.across * trama
	var clear := _draft.height_cells * CabinGrid.CELL
	_state.text = "por dentro, %.2f × %.2f m y %.2f m libres de alto · celda de %d cm · la caja va a %.2f m del piso (sale de las piernas)" % [
		inner, inner, clear, roundi(trama * 100.0), MechBody.waist_for(_draft.thickness, _draft.leg_length, _draft.leg_stretch)]


func _try() -> void:
	CabinGrid.apply(_draft)
	_rebuild_mechs()
	_measure()


func _save() -> void:
	_try()
	var error := ResourceSaver.save(CabinGrid.current(), CabinGrid.SAVED)
	if error != OK:
		push_warning("CabinShapePanel: no se pudo guardar %s (%d)" % [CabinGrid.SAVED, error])
	elif _state != null:
		_state.text += " · guardada"


func _restore() -> void:
	var saved := load(CabinGrid.SAVED) as CabinShape if ResourceLoader.exists(CabinGrid.SAVED) else CabinShape.new()
	for property in _draft.get_property_list():
		if int(property["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
			_draft.set(property["name"], saved.get(property["name"]))
	rebuild()
	_try()


## REARMA LAS MECAS, Y NADA MÁS: cada una se cambia por una nueva igual —sus brazos, su lugar en el piso, hacia dónde
## mira, parada sobre el piso de su parcela— con la forma de ahora. *Al principio se rearmaba la parcela entera, como
## la R, y lo demás volvía a como nace: en la arena de esquivar, la torre volvía a tirar aunque el panel chico dijera
## que no (lo vio el usuario).* Si se la estaba poseyendo, se la suelta antes; el que iba adentro queda donde estaba.
func _rebuild_mechs() -> void:
	Mech.rebuild_all(get_tree())
