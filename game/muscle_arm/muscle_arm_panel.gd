class_name MuscleArmPanel
extends KnobsPanel

## EL PANEL DEL BRAZO CON MÚSCULOS (F1 en la fila Brazo): sus perillas (MuscleArmSettings).

const LABELS := {
	"muscle_kp": "músculo: resorte (cuánto tira)", "muscle_kd": "músculo: freno",
	"muscle_max": "músculo: fuerza tope (rad/s²)",
	"follow": "músculo: sigue la velocidad pedida (0 no, 1 entera)",
	"punch_speed": "piñas: cuánto más rápidas (×)",
	"mouse_reach": "a mano: m por cada 100 px del mouse", "depth_speed": "a mano: W/S adelante y atrás (m/s)",
}


func setup_panel() -> void:
	panel_width = HoverPanel.PANEL_WIDTH
	setup_knobs("brazo con músculos", "BRAZO CON MÚSCULOS")


func knobs() -> Resource:
	return MuscleArmSettings.current


func fresh() -> Resource:
	return MuscleArmSettings.new()


func saved_path() -> String:
	return MuscleArmSettings.SAVED


## Los brazos con músculos de las mecas se arman con sus perillas: se rearman.
func applied() -> void:
	Mech.rebuild_all(get_tree())


func sections() -> Array[Dictionary]:
	return [{"title": "MuscleArmSettings (game/muscle_arm/muscle_arm_settings.gd)", "target": draft(),
		"labels": LABELS, "defaults": MuscleArmSettings.new()}]
