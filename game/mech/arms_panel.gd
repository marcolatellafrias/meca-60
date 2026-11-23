class_name ArmsPanel
extends TunerPanel

## LOS BRAZOS (F3 de las filas de la meca): lo rápido de las piñas, una copia para todas las mecas (PoseArmSettings). Como los
## de perillas (KnobsPanel): se mueve un borrador, y «Guardar» o «Volver a lo guardado» lo escriben y rearman las mecas.
## *Hasta el 22/11/2026 tenía también las pestañas de los brazos con músculos y de los golpes físicos.*

const PANEL_WIDTH := 420.0
const LABELS := {"punch_speed": "piñas: cuánto más rápidas (×)"}

var _draft := PoseArmSettings.new()
var _state: Label = null


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	KnobsFile.copy(_draft, PoseArmSettings.current)
	setup("brazos", "BRAZOS", [new_button("Guardar", _save), new_button("Volver a lo guardado", _restore)])
	_state = state_label()


func sections() -> Array[Dictionary]:
	return [{"title": "DISCRETOS", "tab": "Discretos", "target": _draft, "labels": LABELS, "defaults": PoseArmSettings.new()}]


func _save() -> void:
	KnobsFile.copy(PoseArmSettings.current, _draft)
	var failed := ResourceSaver.save(_draft.duplicate(), PoseArmSettings.SAVED) != OK
	Mech.rebuild_all(get_tree())
	if _state != null:
		_state.text = "no se pudo guardar" if failed else "guardado y aplicado"


func _restore() -> void:
	KnobsFile.copy(_draft, KnobsFile.load_into(PoseArmSettings.new(), PoseArmSettings.SAVED))
	KnobsFile.copy(PoseArmSettings.current, _draft)
	rebuild()
	Mech.rebuild_all(get_tree())
