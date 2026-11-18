class_name HeadFormsPanel
extends TunerPanel

## ── EL EDITOR DE LAS FORMAS DE CABEZA (F3 de la fila «Cabezas», 18/11/2026) ─────────────────────────────────────────
## Lo pidió el usuario: «un sistema vivo en el que en el día de mañana puedo crear más cabezas si quiero… limpio… low
## poly» y «que se pueda cambiar el valor de aplanamiento global en un panel F». Arriba, las formas (ver HeadForms) y
## «+ nueva»; se edita la elegida, en vivo —la vitrina de la fila y los personajes que la usan se rearman—:
##   · FORMA: el alto del cilindro, el frente plano y las dos tapas (diámetro, cuánto se corre adelante y su domo).
##   · CORTES: los siete loop cuts de plantilla (ver HeadCut), cada uno prendido o no, dónde cae, su diámetro y su corrimiento.
##   · RASGOS: las alturas de los ojos y de la boca, donde se apoyan los cosméticos (ver FaceCosmetic).
##   · TODAS: el aplanamiento de la cara, uno para todas las cabezas (HeadForms.face_flat).
## Guardar escribe la elegida (y el aplanamiento) en `head_forms.tres`; Volver a lo guardado deshace lo probado; Olvidar
## devuelve una de las recetas a su receta; Borrar saca una agregada.

const TAB_FORM := "FORMA"
const TAB_CUTS := "CORTES"
const TAB_FEATURES := "RASGOS"
const TAB_ALL := "TODAS"
const LABELS := {
	"height": "alto del cilindro (m)", "flat_front": "frente plano (todo a plomo con la tapa de abajo)",
	"bottom_width": "abajo: diámetro (m)", "bottom_forward": "abajo: adelante (m)", "bottom_dome": "abajo: domo (m)",
	"top_width": "arriba: diámetro (m)", "top_forward": "arriba: adelante (m)", "top_dome": "arriba: domo (m)",
	"active": "prendido (manda en la forma)", "at": "dónde cae (0 abajo, 1 arriba)", "width": "diámetro (m)",
	"forward": "adelante (m)", "face_flat": "aplanamiento de la cara (0 redonda, 1 plana)",
	"eye_height": "altura de los ojos (0 abajo, 1 arriba)", "mouth_height": "altura de la boca (0 abajo, 1 arriba)",
}
## Lo que tarda en rearmar a los personajes después del último cambio (s): rearmar es caro y el slider manda muchos.
const SETTLE_S := 0.3

var _slot := 0
var _draft: HeadForm = null
var _flat_dirty := false
var _state: Label = null
var _settle := 0.0
var _rebuild_all := false


func setup_panel() -> void:
	setup(UIState.HEAD_FORMS, "FORMAS DE CABEZA", [
		new_button("Guardar la elegida", _save),
		new_button("Volver a lo guardado", _restore),
		new_button("Olvidar (volver a su receta)", _forget),
		new_button("Borrar la elegida (sólo las agregadas)", _remove),
	] as Array[Button])
	_state = state_label()
	_pick(0)


func header() -> Array[Control]:
	var tabs := HFlowContainer.new()
	for slot in HeadForms.count():
		var at := slot
		var button := new_button(str(slot + 1), func() -> void: _pick(at))
		button.tooltip_text = HeadForms.form_for(slot).name
		button.focus_mode = Control.FOCUS_NONE
		if slot == _slot:
			LocomotionTuner._paint_picked(button)
		tabs.add_child(button)
	var add := new_button("+ nueva", _add)
	add.focus_mode = Control.FOCUS_NONE
	tabs.add_child(add)
	return [tabs, HSeparator.new()] as Array[Control]


func sections() -> Array[Dictionary]:
	if _draft == null:
		_pick(_slot)
	var out: Array[Dictionary] = []
	out.append({"tab": TAB_FORM, "title": "%d. %s" % [_slot + 1, _draft.name], "target": _draft, "labels": LABELS,
		"only": PackedStringArray(["height", "flat_front"]), "headers": false, "on_change": _changed})
	out.append({"tab": TAB_FORM, "title": "TAPA DE ABAJO", "target": _draft, "labels": LABELS, "headers": false,
		"only": PackedStringArray(["bottom_width", "bottom_forward", "bottom_dome"]), "on_change": _changed})
	out.append({"tab": TAB_FORM, "title": "TAPA DE ARRIBA", "target": _draft, "labels": LABELS, "headers": false,
		"only": PackedStringArray(["top_width", "top_forward", "top_dome"]), "on_change": _changed})
	out.append({"tab": TAB_FEATURES, "title": "DÓNDE SE APOYAN LOS COSMÉTICOS", "target": _draft, "labels": LABELS,
		"headers": false, "only": PackedStringArray(["eye_height", "mouth_height"]), "on_change": _changed})
	for i in _draft.cuts.size():
		out.append({"tab": TAB_CUTS, "title": "CORTE %d" % (i + 1), "target": _draft.cuts[i], "labels": LABELS,
			"headers": false, "on_change": _changed})
	out.append({"tab": TAB_ALL, "title": "TODAS LAS CABEZAS", "target": HeadForms.table(), "labels": LABELS,
		"only": PackedStringArray(["face_flat"]), "headers": false, "on_change": _flat_changed})
	return out


func _pick(slot: int) -> void:
	_slot = clampi(slot, 0, HeadForms.count() - 1)
	HeadForms.editing = _slot
	_draft = HeadForms.form_for(_slot)
	_refresh_view()
	rebuild()
	_refresh_state()


func _add() -> void:
	_pick(HeadForms.add(_draft))
	_refresh_state("agregada")


## ── LO QUE CAMBIA, EN VIVO ──────────────────────────────────────────────────────────────────────────────────────
func _changed() -> void:
	HeadForms.preview[_slot] = _draft.copy()
	_refresh_view()
	_settle = SETTLE_S
	_refresh_state()


func _flat_changed() -> void:
	_flat_dirty = true
	_refresh_view()
	_settle = SETTLE_S
	_rebuild_all = true
	_refresh_state()


func _process(delta: float) -> void:
	if _settle <= 0.0:
		return
	_settle -= delta
	if _settle <= 0.0:
		_rebuild_characters()


## LA VITRINA de la fila, rearmada.
func _refresh_view() -> void:
	if is_inside_tree():
		get_tree().call_group(HeadFormsArchetype.HeadFormsView.GROUP, "refresh")


## LOS PERSONAJES QUE USAN LA ELEGIDA (o todos, si cambió el aplanamiento), rearmados.
func _rebuild_characters() -> void:
	for node in get_tree().get_nodes_in_group(CharacterRigidBody3D.CHARACTER_GROUP):
		var bi := (node as Node).get_parent() as BoneInstantiator
		if not is_instance_valid(bi) or bi.entity_instantiation == null:
			continue
		if _rebuild_all or CharacterLooks.head_form_for(int(bi.entity_instantiation.archetype_type)) == _slot:
			bi.initialize_skeleton()
	_rebuild_all = false


## ── LOS BOTONES ─────────────────────────────────────────────────────────────────────────────────────────────────
func _save() -> void:
	var ok := HeadForms.store(_slot, _draft)
	if _flat_dirty:
		ok = HeadForms.store_table() and ok
		_flat_dirty = false
	_refresh_view()
	rebuild()
	_refresh_state("guardada" if ok else "NO SE PUDO GUARDAR")


func _restore() -> void:
	HeadForms.preview.erase(_slot)
	if _flat_dirty:
		HeadForms.reload_face_flat()
		_flat_dirty = false
		_rebuild_all = true
	_draft = HeadForms.form_for(_slot)
	_refresh_view()
	_settle = SETTLE_S
	rebuild()
	_refresh_state("como lo guardado")


func _forget() -> void:
	if HeadForms.removable(_slot):
		_refresh_state("es agregada: no tiene receta (se borra con Borrar)")
		return
	HeadForms.forget(_slot)
	_draft = HeadForms.form_for(_slot)
	_refresh_view()
	_settle = SETTLE_S
	rebuild()
	_refresh_state("volvió a su receta")


func _remove() -> void:
	if not HeadForms.removable(_slot):
		_refresh_state("es de las recetas: no se borra (Olvidar la vuelve a su receta)")
		return
	HeadForms.remove(_slot)
	_pick(_slot - 1)
	_refresh_state("borrada")


func _refresh_state(note := "") -> void:
	if _state == null:
		return
	var what := "su receta"
	if HeadForms.preview.has(_slot) or _flat_dirty:
		what = "PRUEBA SIN GUARDAR"
	elif HeadForms.is_saved(_slot):
		what = "guardada"
	if not note.is_empty():
		what = "%s · %s" % [note, what]
	_state.text = "%d. %s: %s" % [_slot + 1, _draft.name if _draft != null else "", what]
