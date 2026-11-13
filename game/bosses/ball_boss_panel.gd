class_name BallBossPanel
extends TunerPanel

## EL PANEL DEL JEFE BOLA (F1 en su fila): sus perillas (BallBossSettings), una pestaña por grupo.

const PANEL_WIDTH := 400.0
const LABELS := {
	"walk_speed": "velocidad (m/s)", "reach_time": "tiempo para llegar a ella y para frenar (s; 0: al instante)",
	"turn_speed": "velocidad tope (°/s)", "turn_accel": "aceleración tope (°/s²)",
	"jump_height": "sube (m)", "jump_time": "tarda en subir (s)",
	"stand_height": "centro de la bola, parada (m)", "crouch_height": "centro de la bola, agachada (m)",
	"crouch_rate": "ritmo (partes por s)", "pitch_speed": "corre por la rendija a (°/s)",
	"tentacle_length": "largo de cada tentáculo (m)", "spread": "el pie, a cuánto del centro (m)",
	"step_radius": "un pie sale a más de (m)", "step_time": "el paso tarda (s)", "step_lift": "el pie sube (m)",
}
const TABS: Array[String] = ["Moverse", "Girar", "Saltar", "Agacharse", "Cañón", "Tentáculos"]


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("jefe_bola", "JEFE BOLA")


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": BallBossSettings.current, "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": BallBossSettings.new()})
	return all
