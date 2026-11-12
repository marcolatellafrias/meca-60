class_name PhysicalCubePanel
extends TunerPanel

## EL PANEL DEL CUBO FÍSICO (F1 en la fila Cubo físico): sus perillas (PhysicalCubeSettings), sin las de la línea de
## equilibrio, que no usa.

const LABELS := {
	"grip_rate": "pies: cuánto agarran (1/s)", "grip_max": "pies: lo más que empujan (m/s²)",
	"grip_depth": "pies: dónde agarran (0 el cubo, 1 el piso)",
	"corner_spread": "resortes de las esquinas: qué tan afuera", "upright_kp": "torque que lo endereza",
	"upright_kd": "freno del giro", "fall_tilt": "se cae inclinado más de (°)",
	"knock_soft": "F2 suave (m/s arriba)", "knock_strong": "F2 fuerte (m/s arriba)",
}
const UNUSED := ["lean_per_ms", "push_rate", "stiffness", "damping", "fall_at", "lean_angle", "base_grip", "tip_carry",
	"knock_gain", "knock_brake", "fixed_lean", "height_weight", "slide_brake"]


func setup_panel() -> void:
	panel_width = HoverPanel.PANEL_WIDTH
	setup("cubo físico", "CUBO FÍSICO")


func sections() -> Array[Dictionary]:
	var labels := HoverPanel.LABELS.duplicate()
	labels.merge(LABELS)
	return [{"title": "PhysicalCubeSettings (game/physical_cube/physical_cube_settings.gd)",
		"target": PhysicalCubeSettings.shared, "labels": labels, "skip": PackedStringArray(UNUSED),
		"defaults": PhysicalCubeSettings.new()}]
