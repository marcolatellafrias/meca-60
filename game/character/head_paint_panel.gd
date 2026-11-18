class_name HeadPaintPanel
extends TunerPanel

## ── LAS PINTURAS DE LAS CABEZAS (F2 de la fila «Cabezas», 18/11/2026) ───────────────────────────────────────────────
## Lo que guarda va en un panel F, no en el panel chico (el usuario: «usar un control para algo que se guarda
## permanentemente en un panel chico… es muy mala práctica»). Arriba, las formas de cabeza y las pinturas de la elegida;
## abajo, cómo nace la próxima (densidad y giro) y los botones: crear, duplicar y borrar. Lo que se pinta se pinta con el
## F1 (PixelPaintPanel), mirando la cabeza de la parcela «Pintar caras» (ver HeadPaintArchetype).

var _settings := HeadPaintSettings.new()
var _state: Label = null


func setup_panel() -> void:
	setup("head_paint", "PINTURAS DE CABEZA", [
		new_button("Crear una pintura nueva (con lo de abajo)", func() -> void: _act("_create", "creada")),
		new_button("Duplicar la elegida", func() -> void: _act("_duplicate", "duplicada")),
		new_button("Borrar la elegida", func() -> void: _act("_delete", "borrada")),
	] as Array[Button])
	_state = state_label()
	_refresh_state()


## La fila de la parcela «Pintar caras» y su parcela, si uno está en ella (ver `sandbox`), o null.
func _parcel() -> SandboxParcel:
	if not is_instance_valid(sandbox):
		return null
	var parcel := sandbox.call("current_parcel") as SandboxParcel
	return parcel if parcel != null and parcel.archetype is HeadPaintArchetype else null


func _row() -> HeadPaintArchetype:
	var parcel := _parcel()
	return parcel.archetype as HeadPaintArchetype if parcel != null else null


func header() -> Array[Control]:
	var row := _row()
	if row == null:
		var note := Label.new()
		note.text = "Parate en la parcela «Pintar caras» de esta fila."
		return [note] as Array[Control]
	var forms := HFlowContainer.new()
	var forms_title := Label.new()
	forms_title.text = "forma:"
	forms.add_child(forms_title)
	for slot in HeadForms.count():
		var at := slot
		var button := new_button(str(slot + 1), func() -> void:
			row.head_slot = at
			row.painting = 0
			_regenerate())
		button.focus_mode = Control.FOCUS_NONE
		if slot == row.head_slot:
			LocomotionTuner._paint_picked(button)
		forms.add_child(button)
	var paints := HFlowContainer.new()
	var paints_title := Label.new()
	paints_title.text = "pintura:"
	paints.add_child(paints_title)
	var names := row.paintings()
	for i in names.size():
		var at := i
		var button := new_button(names[i].trim_prefix(row._prefix()), func() -> void:
			row.painting = at
			_regenerate())
		button.focus_mode = Control.FOCUS_NONE
		if i == row.painting:
			LocomotionTuner._paint_picked(button)
		paints.add_child(button)
	return [forms, paints, HSeparator.new()] as Array[Control]


func sections() -> Array[Dictionary]:
	return [{"title": "LA PRÓXIMA PINTURA NUEVA", "target": _settings, "headers": false, "on_change": _settings_changed,
		"labels": {"density": "densidad (píxeles por metro)", "front_face": "con un lado plano adelante (si no, una esquina)"}}] \
		as Array[Dictionary]


func _settings_changed() -> void:
	var row := _row()
	if row != null:
		row.new_density = _settings.density
		row.new_front_face = _settings.front_face


func _opened() -> void:
	var row := _row()
	if row != null:
		_settings.density = row.new_density
		_settings.front_face = row.new_front_face
	rebuild()
	_refresh_state()


## Lo que hace un botón: una función de la fila con la parcela, y la parcela rearmada.
func _act(method: String, note: String) -> void:
	var parcel := _parcel()
	if parcel == null:
		_refresh_state("parate en «Pintar caras»")
		return
	_settings_changed()
	(parcel.archetype as HeadPaintArchetype).call(method, parcel)
	_refresh_sandbox()
	rebuild()
	_refresh_state(note)


func _regenerate() -> void:
	var parcel := _parcel()
	if parcel != null:
		parcel.regenerate(parcel.seed_value)
	_refresh_sandbox()
	rebuild()
	_refresh_state()


## EL PANEL CHICO, al día con la pintura elegida (su texto dice cuál es).
func _refresh_sandbox() -> void:
	if is_instance_valid(sandbox) and sandbox.has_method("_refresh"):
		sandbox.call("_refresh")


func _refresh_state(note := "") -> void:
	if _state == null:
		return
	var row := _row()
	var text := "—" if row == null else " · ".join(row.describe(0).slice(0, 2))
	_state.text = text if note.is_empty() else "%s · %s" % [note, text]


## CÓMO NACE LA PRÓXIMA (lo que muestran los controles del panel).
class HeadPaintSettings:
	extends Resource
	@export_enum("64 px/m", "100 px/m", "150 px/m", "200 px/m") var density := 1
	@export var front_face := true
