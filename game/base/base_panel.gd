class_name BasePanel
extends KnobsPanel

## EL PANEL DE LA BASE (F1 en su fila): sus medidas (BaseSettings). Como todos los paneles de perillas (KnobsPanel): se
## mueve un borrador, y «Guardar» lo guarda y vuelve a armar la base.

const PANEL_WIDTH := 380.0
const LABELS := {
	"nave_height": "nave (elevador y gimnasio): alto (m)",
	"strip_depth": "franja de las consolas: fondo (m)",
	"strip_height": "franja de las consolas (y esclusa): alto (m)",
}


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup_knobs("base", "BASE")


func knobs() -> Resource:
	return BaseSettings.current


func fresh() -> Resource:
	return BaseSettings.new()


func saved_path() -> String:
	return BaseSettings.SAVED


## Cada base armada se vuelve a armar con las medidas nuevas (BaseLayout.rebuild).
func applied() -> void:
	for node in get_tree().get_nodes_in_group(BaseLayout.GROUP):
		BaseLayout.rebuild(node as Node3D)


func sections() -> Array[Dictionary]:
	return [{"title": "MEDIDAS", "tab": "Medidas", "target": draft(), "labels": LABELS,
		"include": PackedStringArray(["Medidas"]), "headers": false, "defaults": BaseSettings.new()}]
