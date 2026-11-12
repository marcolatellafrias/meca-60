class_name BalancePanel
extends TunerPanel

## EL PANEL DE LA MECA DE EQUILIBRIO (F1 en la fila Meca), como los paneles de fila del sandbox de character-parametric
## (TunerPanel): a la izquierda, abre parado en la fila y cierra con la misma tecla. Sus perillas salen de
## MechBalanceSettings —lo que el recurso exporta es lo que se ve—, valen para todas las mecas de equilibrio y vuelven a
## lo del código con el botón de cada fila. «Copiar todo» deja los valores para pegarlos en el código.

const PANEL_WIDTH := 420.0
const LABELS := {
	"hit_pushes": "el golpe empuja", "push_rate": "cuánto empuja",
	"steps": "pasos para recuperarse", "step_at": "da un paso pasada", "step_length": "largo del paso (m)",
	"step_time": "lo que dura el paso (s)", "step_catch": "inclinación que saca un paso",
	"stiffness": "rigidez", "damping": "amortiguación", "spring_scale": "escala de la rigidez (meca)",
	"damp_scale": "escala de la amortiguación (meca)", "lean_per_ms": "inclinación por m/s de golpe",
	"fall_at": "se cae en", "fall_warning": "aviso antes de caer (s)",
	"stability_forward": "golpe de atrás (empuja adelante)", "stability_backward": "golpe de frente (empuja atrás)",
	"stability_sideways": "golpe de costado",
	"lean_angle": "inclinación del torso en 1 (°)", "brake": "freno de los pies (m/s²)", "topple": "vuelco al caer",
	"down_time": "en el suelo (s)", "rise_time": "levantarse (s)",
}


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("equilibrio", "MECA DE EQUILIBRIO")


func sections() -> Array[Dictionary]:
	return [{"title": "MechBalanceSettings (game/mech/mech_balance_settings.gd)", "target": MechBalanceSettings.current,
		"labels": LABELS, "defaults": MechBalanceSettings.new()}]
