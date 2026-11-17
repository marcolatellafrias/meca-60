class_name CageMovesPanel
extends KnobsPanel

## EL F1 DE LA MECA JAULA: las perillas de moverse de la cinemática (KinematicSettings), una pestaña por grupo, pero LAS
## SUYAS (CageMech.MOVES, guardadas aparte; el usuario: «si un panel lo quiero modificar para este mecha, me gustaría
## que sea solamente para esta»). Como todos los paneles de perillas (KnobsPanel): se mueve un borrador, y «Guardar» o
## «Volver a lo guardado» rearman las mecas con eso.
## *Hasta el 17/11/2026 heredaba del panel de la Meca cinemática (KinematicPanel), borrado con la meca grande: sus
## nombres y sus pestañas pasaron acá. Sus configuraciones de un toque eran para las grandes y la jaula nunca las tuvo.*

const PANEL_WIDTH := 400.0
const LABELS := {
	"walk_speed": "velocidad (m/s)", "start_time": "tarda en arrancar (s; 0: al instante)",
	"stop_time": "tarda en frenar o cambiar de dirección (s)",
	"turn_speed": "velocidad tope (°/s)", "turn_accel": "aceleración tope (°/s²)",
	"jump_height": "salto: sube (m)", "jump_time": "salto: tarda en subir (s)",
	"fly_speed": "vuelo: sube a (m/s)", "fly_time": "vuelo: la barra dura (s)",
	"fly_refill": "vuelo: se llena apoyada en (s)",
	"dash_distance": "recorre (m)", "dash_time": "en (s)",
	"dash_cost": "gasta de la barra (parte)", "dash_refill": "la barra se llena en (s)",
	"dash_cooldown": "espera entre dashes (s)",
	"dash_steer": "se tuerce a lo más (°/s)",
	"fall_time": "cae en (s)", "fall_lie": "queda inclinada (°)", "down_time": "tirada (s)",
	"rise_time": "se levanta en (s)",
	"crouch_share": "agachada: la altura que le queda (parte)", "crouch_rate": "ritmo (partes por s)",
}
## Una pestaña por grupo de KinematicSettings.
const TABS: Array[String] = ["Moverse", "Girar", "Saltar y volar", "Dash", "Caerse", "Agacharse"]


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup_knobs("meca_jaula_moverse", "MECA JAULA: MOVERSE (sólo ella)")


func knobs() -> Resource:
	return CageMech.MOVES


func fresh() -> Resource:
	return KinematicSettings.new()


func saved_path() -> String:
	return CageMech.SAVED_MOVES


func applied() -> void:
	Mech.rebuild_all(get_tree())


func note() -> String:
	return "sólo la meca jaula · los pasos son los de las piernas, achicados con ella"


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": draft(), "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": KinematicSettings.new()})
	return all
