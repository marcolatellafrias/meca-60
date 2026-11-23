class_name BaseMatchPanel
extends KnobsPanel

## EL F6 DE LA PARTIDA (22/11/2026): los ajustes de MatchSettings y el botón de reiniciar. Lo usa el capitán, en la base y
## en la arena. «Guardar» los aplica en todas las máquinas; «Reiniciar» vuelve a todos a la esclusa (BaseSync.restart).

const LABELS := {
	"controls": "cómo se maneja la meca",
	"zoom_aboard": "zoom arriba de la meca",
	"zoom_foot": "zoom a pie",
}
const TABS: Array[String] = ["Controles", "Cámara"]


func setup_panel() -> void:
	panel_width = 400.0
	var extra: Array[Button] = [new_button("Reiniciar la partida", _restart), new_button("Dañar la meca (prueba)", _hurt)]
	setup_knobs("partida", "LA PARTIDA", extra)


func _can_open() -> bool:
	return BaseState.is_captain(get_tree()) and UIState.gameplay_active()


func knobs() -> Resource:
	return MatchSettings.current


func fresh() -> Resource:
	return MatchSettings.new()


func saved_path() -> String:
	return MatchSettings.SAVED


func applied() -> void:
	if BaseSync.current != null:
		BaseSync.current.share_match()


func note() -> String:
	return "«Guardar» lo aplica para todos"


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": draft(), "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": MatchSettings.new()})
	return all


func _hurt() -> void:
	if BaseSync.current != null:
		BaseSync.current.hurt_mech()


func _restart() -> void:
	if BaseSync.current != null:
		BaseSync.current.restart()
