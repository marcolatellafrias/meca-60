class_name CabinShapePanel
extends TunerPanel

## LA FORMA DE LA MECA (F2 en sus filas): cuántos módulos por lado, cuántos pisos, el alto de cada piso, cuánto
## sobresale el vidrio del frente, las sillas (la altura de los ojos y su distancia al vidrio) y el cuerpo (el piso y el
## módulo de los hombros, el largo de brazos y piernas, el ancho y cuánto se estiran las piernas). Ver CabinGrid.apply. Lo pidió el usuario el 13/11/2026 («un panel F que podamos usar en
## cualquiera de las parcelas que tienen la meca… cambiar la cantidad de pisos y el tamaño de cada piso… tiene que tener
## botón de guardado, y si guardo algo… se va a actualizar en todas las mecas»).
##   · Los números se mueven sin rearmar nada: abajo dicen qué medidas salen.
##   · PROBAR rearma todas las mecas con esa forma, sin guardar (al reiniciar, vuelve la guardada).
##   · GUARDAR la escribe en `CabinGrid.SAVED` y rearma todas las mecas: es la forma de todas, también al reiniciar.
## La planta es cuadrada y el alto, libre. Las piernas y los brazos no dependen de la caja.

const PANEL_WIDTH := 380.0
const LABELS := {
	"modules": "módulos por lado (cada uno, 1,89 m)",
	"floors": "pisos",
	"floor_cells": "alto de cada piso, de losa a losa (celdas de 3,9 cm)",
	"glass_out": "el vidrio sobresale (celdas de 3,9 cm)",
	"structure": "por dónde se anda y se sube",
	"eye_height": "altura de los ojos que buscan (m)",
	"seat_gap": "distancia al vidrio (celdas)",
	"arm_floor": "piso",
	"arm_along": "módulo del costado",
	"arm_length": "largo de los brazos",
	"leg_length": "largo de las piernas",
	"thickness": "ancho (de los dos)",
	"leg_stretch": "cuánto se estiran las piernas paradas",
}

## Las partes del panel: los grupos de CabinShape, en orden.
const PARTS := ["La caja", "La estructura", "Las sillas", "Los hombros", "Brazos y piernas"]

var _draft := CabinGrid.current()
var _state: Label = null


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("cabina", "FORMA DE LA MECA", [
		new_button("Probar en todas las mecas (sin guardar)", _try),
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
	var side := _draft.modules * CabinGrid.MODULE_CELLS + CabinGrid.WALL_CELLS * 2
	var free := (_draft.floor_cells - CabinGrid.SLAB_CELLS) * CabinGrid.CELL
	_state.text = "caja de %.2f × %.2f m de planta y %.2f de alto · piso de %.2f m (%.2f libres)%s · ahora: %d × %d, %d pisos de %d" % [
		side * CabinGrid.CELL, side * CabinGrid.CELL, _draft.floors * _draft.floor_cells * CabinGrid.CELL,
		_draft.floor_cells * CabinGrid.CELL, free, " · ¡no se pasa parado!" if free < 1.9 else "",
		CabinGrid.COLUMNS, CabinGrid.COLUMNS, CabinGrid.FLOORS, CabinGrid.FLOOR_CELLS]


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
	for found in get_tree().root.find_children("*", "Mech", true, false):
		var old := found as Mech
		if old == null or old.is_queued_for_deletion():
			continue
		if old.keys != null and old.keys.driving:
			SandboxPossession.of(get_tree()).release()
		var holder := old.get_parent()
		var fresh := Mech.new()
		fresh.arms_kind = old.arms_kind
		fresh.kinematic = old.kinematic
		# Parada sobre el piso de su parcela (la altura 0 de lo que la tiene, como la arman sus arquetipos).
		fresh.transform = Transform3D(Basis(Vector3.UP, old.yaw()), Vector3(old.position.x,
			BodySettings.current.hover_height + CabinGrid.HALF_HEIGHT, old.position.z))
		old.cabin.free_dummies()
		holder.remove_child(old)
		old.queue_free()
		holder.add_child(fresh)
