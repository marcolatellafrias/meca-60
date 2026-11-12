class_name PendulumMechPanel
extends TunerPanel

## EL PANEL DE LA MECA PÉNDULO (F1 en la fila Meca péndulo): las perillas del cubo péndulo en su propia copia, y las de
## correr, agacharse, saltar y el propulsor (PendulumMechSettings).

const LABELS := {
	"sprint_multiplier": "correr: hasta cuántas veces la caminata", "sprint_accel": "correr: aceleración en la banda (parte)",
	"crouch_rod": "agachada: largo del palo (parte)", "crouch_speed": "agachada: velocidad (parte)",
	"rod_rate": "cuán rápido sube y baja (por s)",
	"jump_height": "salto entero (m)", "jump_charge_time": "el salto se carga en (s)",
	"jump_squat": "cargando baja hasta (parte del palo)", "jump_least": "un toque sin cargar salta (parte)",
	"air_accel": "en el aire, cambia de costado (m/s²)",
	"thrust": "propulsor: empuje (m/s²)", "thrust_time": "propulsor: dura (s)", "thrust_refill": "propulsor: se recarga en (s)",
}


func setup_panel() -> void:
	panel_width = HoverPanel.PANEL_WIDTH
	setup("meca péndulo", "MECA PÉNDULO")


func sections() -> Array[Dictionary]:
	var labels := HoverPanel.LABELS.duplicate()
	labels.merge(PendulumCubePanel.LABELS, true)
	labels.merge(LABELS, true)
	return [{"title": "PendulumMechSettings (game/pendulum_mech/pendulum_mech_settings.gd)",
		"target": PendulumMechSettings.tuned, "labels": labels, "skip": PackedStringArray(PendulumCubePanel.UNUSED),
		"defaults": PendulumMechSettings.new()}]
