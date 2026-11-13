class_name PoseArmPanel
extends KnobsPanel

## EL PANEL DEL BRAZO DISCRETO (F3 en las filas de la meca discreta): sus perillas (PoseArmSettings). Como todos los
## paneles de perillas (KnobsPanel): se mueve un borrador, y «Guardar» o «Volver a lo guardado» rearman las mecas.

const LABELS := {
	"punch_speed": "piñas: cuánto más rápidas (×)",
	"hit_mass": "al conectar: lo que pesa el puño (kg)", "fist_radius": "al conectar: radio del puño (m)",
}


func setup_panel() -> void:
	panel_width = HoverPanel.PANEL_WIDTH
	setup_knobs("brazo discreto", "BRAZOS DISCRETOS")


func knobs() -> Resource:
	return PoseArmSettings.current


func fresh() -> Resource:
	return PoseArmSettings.new()


func saved_path() -> String:
	return PoseArmSettings.SAVED


func applied() -> void:
	Mech.rebuild_all(get_tree())


func sections() -> Array[Dictionary]:
	return [{"title": "PoseArmSettings (game/pose_arm/pose_arm_settings.gd)", "target": draft(), "labels": LABELS,
		"defaults": PoseArmSettings.new()}]
