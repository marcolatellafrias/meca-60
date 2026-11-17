class_name ArmPosesPanel
extends TunerPanel

## LAS POSES DE LOS BRAZOS, PARA PROBARLAS JUGANDO (F6 de la meca jaula; TEMPORAL; 16/11/2026, el usuario: «¿podrías
## poner todas las poses para probar, en un panel F temporal, así veo?»): dónde descansa el brazo de piñas, dónde
## descansa el cañón (estirado o en L) y el golpe del clic izquierdo, con los números de las hojas (ver ArmPoseIdeas).
## Cambia en vivo, en todas las mecas con brazos de herramientas; no se guarda. El cañón sale de ese reposo y la palanca
## (las flechas) lo mueve desde ahí.

const PANEL_WIDTH := 400.0
const LABELS := {
	"fist_rest": "el palo (o el puño): dónde descansa",
	"cannon_rest": "el cañón: dónde descansa",
	"strike": "el golpe del clic izquierdo",
}


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup("poses_de_brazos", "POSES DE LOS BRAZOS (PARA PROBAR)")
	state_label().text = "temporal: cambia en vivo y no se guarda · los números son los de las hojas"


func sections() -> Array[Dictionary]:
	return [{"title": "LO ELEGIDO", "target": ArmPoseTrial.current, "labels": LABELS, "headers": false,
		"defaults": ArmPoseTrial.new(), "on_change": func() -> void: ArmPoseIdeas.apply_all(get_tree())}]
