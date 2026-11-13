class_name MuscleArmPanel
extends TunerPanel

## EL PANEL DEL BRAZO CON MÚSCULOS (F1 en la fila Brazo): sus perillas (MuscleArmSettings).

const LABELS := {
	"muscle_kp": "músculo: resorte (cuánto tira)", "muscle_kd": "músculo: freno",
	"muscle_max": "músculo: fuerza tope (rad/s²)",
	"punch_speed": "piñas: cuánto más rápidas (×)",
	"mouse_reach": "a mano: m por cada 100 px del mouse", "depth_speed": "a mano: W/S adelante y atrás (m/s)",
}


var _state: Label = null


func setup_panel() -> void:
	panel_width = HoverPanel.PANEL_WIDTH
	setup("brazo con músculos", "BRAZO CON MÚSCULOS", KnobsFile.buttons(MuscleArmSettings.current,
		func() -> MuscleArmSettings: return MuscleArmSettings.new(), MuscleArmSettings.SAVED, rebuild, _say))
	_state = state_label()


func _say(text: String) -> void:
	if _state != null:
		_state.text = text


func sections() -> Array[Dictionary]:
	return [{"title": "MuscleArmSettings (game/muscle_arm/muscle_arm_settings.gd)", "target": MuscleArmSettings.current,
		"labels": LABELS, "defaults": MuscleArmSettings.new()}]
