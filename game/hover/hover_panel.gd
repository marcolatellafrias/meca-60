class_name HoverPanel
extends TunerPanel

## EL PANEL DEL CUBO (F1 en la fila Cubo), como los paneles de fila del sandbox de character-parametric (TunerPanel): a
## la izquierda, abre parado en la fila y cierra con la misma tecla. Sus perillas salen de HoverCubeSettings —lo que el
## recurso exporta es lo que se ve— y vuelven a lo del código con el botón de cada fila.

const PANEL_WIDTH := 420.0
const LABELS := {
	"hover_height": "altura de flotar (m)", "height_kp": "resorte de altura", "height_kd": "freno de altura",
	"max_height_error": "error de altura con tope (m)", "max_up": "empuje para arriba con tope (m/s²)",
	"walk_speed": "velocidad propia (m/s)", "walk_accel": "cuánto tarda en arrancar (m/s²)",
	"walk_brake": "freno al soltar (m/s²)", "turn_speed": "giro con A/D (°/s)",
	"knock_brake": "freno del retroceso: cuánto lo corre un golpe (m/s²)",
	"lean_per_ms": "inclinación por m/s de golpe", "push_rate": "cuánto empuja la inclinación",
	"stiffness": "resorte que lo endereza", "damping": "freno de la inclinación", "fall_at": "se cae en",
	"lean_angle": "inclinación del dibujo en 1 (°)", "base_grip": "cuánto se le traba la base al caer",
	"tip_carry": "cuánto de la inclinación sigue al caer",
	"fall_gravity": "gravedad caído (veces)", "ground_spin_damp": "freno del giro caído (1/s)",
	"limp_time": "tirado, antes de recuperarse (s)",
	"settle_speed": "se recupera más lento que (m/s)", "settle_spin": "y girando menos que (rad/s)",
	"nozzle_push": "empuje de cada tobera (m/s²)", "lift_share": "sube hasta esta parte de la altura",
	"lift_kp": "resorte de subir", "lift_kd": "freno de subir", "right_kp": "resorte de enderezarse",
	"right_kd": "freno de enderezarse", "upright_done": "derecho con menos de (°)",
}


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("cubo", "CUBO")


func sections() -> Array[Dictionary]:
	return [{"title": "HoverCubeSettings (game/hover/hover_cube_settings.gd)", "target": HoverCubeSettings.current,
		"labels": LABELS, "defaults": HoverCubeSettings.new()}]
