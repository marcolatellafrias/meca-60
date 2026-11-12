class_name MuscleArmPanel
extends TunerPanel

## EL PANEL DEL BRAZO CON MÚSCULOS (F1 en la fila Brazo): sus perillas (MuscleArmSettings).

const LABELS := {
	"muscle_kp": "músculo: resorte (cuánto tira)", "muscle_kd": "músculo: freno",
	"muscle_max": "músculo: fuerza tope (rad/s²)",
	"punch_speed": "piñas: cuánto más rápidas (×)",
	"mouse_reach": "a mano: m por cada 100 px del mouse", "depth_speed": "a mano: W/S adelante y atrás (m/s)",
}


func setup_panel() -> void:
	panel_width = HoverPanel.PANEL_WIDTH
	setup("brazo con músculos", "BRAZO CON MÚSCULOS")


func sections() -> Array[Dictionary]:
	return [{"title": "MuscleArmSettings (game/muscle_arm/muscle_arm_settings.gd)", "target": MuscleArmSettings.current,
		"labels": LABELS, "defaults": MuscleArmSettings.new()}]
