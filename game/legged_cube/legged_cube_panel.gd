class_name LeggedCubePanel
extends TunerPanel

## EL PANEL DEL CUBO CON PIERNAS (F1 en la fila Cubo con piernas): las perillas del cubo, en su propia copia, y las de
## las piernas (LeggedCubeSettings).

const LABELS := {
	"step_radius": "da un paso al alejarse más de (m)", "step_lead": "cuánto se adelanta el pie (s de marcha)",
	"step_time": "cuánto dura un paso (s)", "step_height": "cuánto sube el pie (m)",
	"fold_time": "se recogen al caer en (s)", "unfold_time": "se estiran al enderezarse en (s)",
}


func setup_panel() -> void:
	panel_width = HoverPanel.PANEL_WIDTH
	setup("cubo con piernas", "CUBO CON PIERNAS")


func sections() -> Array[Dictionary]:
	var labels := HoverPanel.LABELS.duplicate()
	labels.merge(LABELS)
	return [{"title": "LeggedCubeSettings (game/legged_cube/legged_cube_settings.gd)", "target": LeggedCubeSettings.shared,
		"labels": labels, "defaults": LeggedCubeSettings.new()}]
