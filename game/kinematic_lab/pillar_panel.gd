class_name PillarPanel
extends TunerPanel

## EL PANEL DEL CUBO CINEMÁTICO (F1 en el Laboratorio cinemático): sus perillas (PillarSettings), una pestaña por
## grupo (el usuario: «organices mejor el panel F con tabs»).

const PANEL_WIDTH := 400.0
const LABELS := {
	"walk_speed": "caminar: velocidad (m/s)", "walk_accel": "arrancar (m/s²)", "walk_brake": "frenar: el roce (m/s²)",
	"sprint_multiplier": "correr: veces la caminata", "air_control": "en el aire, arrancar y frenar (parte)",
	"turn_speed": "velocidad tope (°/s)", "turn_accel": "aceleración tope (°/s²)",
	"jump_height": "salto (m)", "air_gravity": "en el aire pesa (veces)",
	"thrust": "vuelo: empuje (m/s²)", "thrust_time": "vuelo: la barra dura (s)",
	"thrust_refill": "vuelo: se llena apoyado en (s)",
	"dash_speed": "suma (m/s)", "dash_lift": "en el aire, sube a (m/s)", "dash_hold": "un rato sin frenar (s)",
	"dash_cost": "gasta de la barra (parte)", "dash_refill": "la barra se llena en (s)",
	"crouch_share": "agachado: alto que queda (parte)", "crouch_rate": "ritmo (partes por s)",
	"cap_extra": "topadora: sale como mucho tanto más rápido (m/s)",
	"ghost_extra": "atraviesa: empuja tanto más rápido (m/s)",
}
## Una pestaña por grupo de PillarSettings.
const TABS: Array[String] = ["Moverse", "Girar", "Saltar y volar", "Dash", "Agacharse", "Con lo suelto"]


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("cubo_cinematico", "CUBO CINEMÁTICO")


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": PillarSettings.current, "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": PillarSettings.new()})
	return all
