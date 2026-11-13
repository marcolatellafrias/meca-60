class_name PillarPanel
extends TunerPanel

## EL PANEL DEL CUBO CINEMÁTICO (F1 en el Laboratorio cinemático): sus perillas (PillarSettings).

const PANEL_WIDTH := 400.0
const LABELS := {
	"walk_speed": "caminar: velocidad (m/s)", "walk_accel": "arrancar (m/s²)", "walk_brake": "frenar (m/s²)",
	"sprint_multiplier": "correr: veces la caminata",
	"turn_speed": "giro: velocidad tope (°/s)", "turn_accel": "giro: aceleración tope (°/s²)",
	"jump_height": "salto (m)", "air_gravity": "en el aire pesa (veces)",
	"crouch_share": "agachado: alto que queda (parte)", "crouch_rate": "agacharse: ritmo (partes por s)",
	"cap_extra": "topadora: sale como mucho tanto más rápido (m/s)",
	"ghost_extra": "atraviesa: empuja tanto más rápido (m/s)",
}


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("cubo_cinematico", "CUBO CINEMÁTICO")


func sections() -> Array[Dictionary]:
	return [{"title": "PillarSettings (game/kinematic_lab/pillar_settings.gd)", "target": PillarSettings.current,
		"labels": LABELS, "defaults": PillarSettings.new()}]
