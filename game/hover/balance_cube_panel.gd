class_name BalanceCubePanel
extends TunerPanel

## EL PANEL DEL CUBO CON EQUILIBRIO (F1 en la fila Cubo con equilibrio), como los paneles de fila del sandbox de
## character-parametric (TunerPanel): la línea de equilibrio y el tropezar (BalanceCubeSettings), y lo de flotar, caído y
## recuperarse del cubo flotante en su propia copia (BalanceCube.hover_knobs). El torque que endereza y los umbrales de
## dejarse caer del cubo flotante no se usan acá (los reemplaza la línea): no están.

const PANEL_WIDTH := 420.0
const LABELS := {
	"lean_per_ms": "inclinación por m/s de golpe", "push_rate": "cuánto empuja la inclinación",
	"stiffness": "resorte que lo endereza", "damping": "freno de la inclinación", "fall_at": "se cae en",
	"lean_angle": "inclinación del dibujo en 1 (°)", "base_grip": "cuánto se le traba la base al caer",
	"tip_carry": "cuánto de la inclinación sigue al caer",
}
const UNUSED := ["upright_kp", "upright_kd", "max_tilt", "max_fall_speed", "max_side_speed"]


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("cubo con equilibrio", "CUBO CON EQUILIBRIO")


func sections() -> Array[Dictionary]:
	var hover_labels := HoverPanel.LABELS.duplicate()
	return [
		{"title": "BalanceCubeSettings (game/hover/balance_cube_settings.gd)", "target": BalanceCubeSettings.current,
			"labels": LABELS, "defaults": BalanceCubeSettings.new()},
		{"title": "Flotar, caído y recuperarse (BalanceCube.hover_knobs)", "target": BalanceCube.hover_knobs,
			"labels": hover_labels, "skip": PackedStringArray(UNUSED), "defaults": BalanceCube._own_knobs()},
	]
