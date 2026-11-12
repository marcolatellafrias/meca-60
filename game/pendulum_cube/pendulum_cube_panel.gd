class_name PendulumCubePanel
extends TunerPanel

## EL PANEL DEL CUBO PÉNDULO (F1 en la fila Cubo péndulo): sus perillas (PendulumCubeSettings), sin las de la línea de
## equilibrio ni las de flotar con resorte, que no usa.

const LABELS := {
	"pivot_kp": "agarre al apoyo: resorte", "pivot_kd": "agarre al apoyo: freno",
	"upright_kp": "músculo que lo quiere derecho", "upright_kd": "freno del músculo",
	"fall_tilt": "se cae inclinado más de (°)",
	"feet_accel": "pies: cuánto aceleran para alcanzarlo (m/s²)", "feet_speed": "pies: velocidad tope (m/s)",
	"feet_react": "pies: qué tan rápido reaccionan (1/s)",
	"feet_catch": "pies: cuánto buscan ponerse debajo (1/s)",
	"yaw_force": "giro: fuerza del motor (rad/s²)", "yaw_grip": "giro: qué tan firme sigue al mouse",
	"turn_speed": "giro: velocidad tope (°/s)",
	"step_radius": "da un paso al alejarse más de (m)", "step_lead": "cuánto se adelanta el pie (s de marcha)",
	"step_time": "cuánto dura un paso (s)", "step_height": "cuánto sube el pie (m)",
	"fold_time": "se recogen al caer en (s)", "unfold_time": "se estiran al enderezarse en (s)",
	"knock_soft": "F2 suave (m/s arriba)", "knock_strong": "F2 fuerte (m/s arriba)",
	"hover_height": "altura del cubo sobre el piso (m)",
}
const UNUSED := ["lean_per_ms", "push_rate", "stiffness", "damping", "fall_at", "lean_angle", "base_grip", "tip_carry",
	"knock_gain", "knock_brake", "fixed_lean", "height_weight", "height_kp", "height_kd", "max_height_error", "max_up"]


func setup_panel() -> void:
	panel_width = HoverPanel.PANEL_WIDTH
	setup("cubo péndulo", "CUBO PÉNDULO")


func sections() -> Array[Dictionary]:
	var labels := HoverPanel.LABELS.duplicate()
	labels.merge(LABELS, true)
	return [{"title": "PendulumCubeSettings (game/pendulum_cube/pendulum_cube_settings.gd)",
		"target": PendulumCubeSettings.shared, "labels": labels, "skip": PackedStringArray(UNUSED),
		"defaults": PendulumCubeSettings.new()}]
