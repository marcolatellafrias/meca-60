class_name KnobsPanel
extends TunerPanel

## UN PANEL F DE PERILLAS QUE SE GUARDAN, TODOS IGUALES (13/11/2026; el usuario: «borraría lo de probar y dejaría
## solamente guardar. Y que cuando guarde se regeneren las mecas, o sea, que sea un solo sistema robusto»):
##   · SE MUEVE UN BORRADOR: nada cambia en vivo, con las cosas en movimiento. *El F1 de la meca cambiaba las perillas en
##     vivo y la meca quedaba a mitad de camino («hace que cambien a la mitad y hace que se bugeen»).*
##   · «GUARDAR»: el borrador pasa a las perillas de verdad, se escribe al archivo y se APLICA (`applied`: la meca, por
##     ejemplo, rearma todas las mecas). Un solo camino.
##   · «VOLVER A LO GUARDADO»: el borrador vuelve a lo del archivo, y se aplica igual.
## Cada panel dice qué perillas son (`knobs`, `fresh`, `saved_path`) y qué hacer al aplicarlas (`applied`). Los
## archivos son del usuario: no se suben al repositorio (ver KnobsFile).

var _draft: Resource = null
var _state: Label = null


## ── LO QUE CADA PANEL DICE ───────────────────────────────────────────────────────────────────────────────────────

## Las perillas de verdad (el `current` del recurso).
func knobs() -> Resource:
	return null


## Uno nuevo, con los valores del código.
func fresh() -> Resource:
	return null


## Dónde se guardan.
func saved_path() -> String:
	return ""


## AL APLICAR (guardar o volver a lo guardado): lo que hay que rearmar para que se vea bien.
func applied() -> void:
	pass


## Una línea de arriba del panel (opcional): qué es lo de este panel.
func note() -> String:
	return ""


## ── EL PANEL ─────────────────────────────────────────────────────────────────────────────────────────────────────

## Arma el panel (se llama desde `setup_panel`): `extra`, botones propios antes de los dos de siempre.
func setup_knobs(ui_key: String, title_text: String, extra: Array[Button] = []) -> void:
	_draft = fresh()
	KnobsFile.copy(_draft, knobs())
	var buttons: Array[Button] = []
	buttons.append_array(extra)
	buttons.append(new_button("Guardar", _save))
	buttons.append(new_button("Volver a lo guardado", _restore))
	setup(ui_key, title_text, buttons)
	_state = state_label()
	say(note())


## El borrador (lo que muestran las secciones del panel).
func draft() -> Resource:
	return _draft


## LAS PERILLAS DE VERDAD CAMBIARON POR OTRO LADO (un experimento, Experiments): el borrador las toma y el panel se
## rearma, con su línea de arriba.
func reload_draft() -> void:
	if _draft == null:
		return
	KnobsFile.copy(_draft, knobs())
	rebuild()
	say(note())


func say(text: String) -> void:
	if _state != null:
		_state.text = text


func _save() -> void:
	KnobsFile.copy(knobs(), _draft)
	var error := ResourceSaver.save(_draft.duplicate(), saved_path())
	applied()
	say("guardado y aplicado" if error == OK else "no se pudo guardar (%d)" % error)


func _restore() -> void:
	KnobsFile.copy(_draft, KnobsFile.load_into(fresh(), saved_path()))
	KnobsFile.copy(knobs(), _draft)
	rebuild()
	applied()
	say("volvió a lo guardado")
