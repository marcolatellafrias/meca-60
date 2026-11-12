class_name HoverPanel
extends TunerPanel

## EL PANEL DEL CUBO FLOTANTE (F1 en la fila Cubo flotante), como los paneles de fila del sandbox de
## character-parametric (TunerPanel): a la izquierda, abre parado en la fila y cierra con la misma tecla. Sus perillas
## salen de HoverCubeSettings —lo que el recurso exporta es lo que se ve— y vuelven a lo del código con el botón de cada
## fila.

const PANEL_WIDTH := 420.0
const LABELS := {
	"hover_height": "altura de flotar (m)", "height_kp": "resorte de altura", "height_kd": "freno de altura",
	"max_height_error": "error de altura con tope (m)", "max_up": "empuje para arriba con tope (m/s²)",
	"slide_brake": "freno de costado (m/s²)",
	"upright_kp": "torque que endereza", "upright_kd": "freno del giro",
	"max_tilt": "se deja caer inclinado más de (°)", "max_fall_speed": "o cayendo a más de (m/s)",
	"max_side_speed": "o de costado a más de (m/s)", "limp_time": "tirado, quieto, antes de recuperarse (s)",
	"nozzle_push": "empuje de cada tobera (m/s²)", "lift_share": "sube hasta esta parte de la altura",
	"lift_kp": "resorte de subir", "lift_kd": "freno de subir", "right_kp": "resorte de enderezarse",
	"right_kd": "freno de enderezarse", "upright_done": "derecho con menos de (°)",
}


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("cubo flotante", "CUBO FLOTANTE")


func sections() -> Array[Dictionary]:
	return [{"title": "HoverCubeSettings (game/hover/hover_cube_settings.gd)", "target": HoverCubeSettings.current,
		"labels": LABELS, "defaults": HoverCubeSettings.new()}]
