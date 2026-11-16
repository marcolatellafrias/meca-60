class_name CageMovesPanel
extends KinematicPanel

## EL F1 DE LA MECA JAULA: las perillas de moverse de la cinemática (las de KinematicPanel), pero LAS SUYAS (CageMech.MOVES,
## guardadas aparte; el usuario: «si un panel lo quiero modificar para este mecha, me gustaría que sea solamente para
## esta»). Sin las configuraciones de un toque: son para las grandes.


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup_knobs("meca_jaula_moverse", "MECA JAULA: MOVERSE (sólo ella)")


func knobs() -> Resource:
	return CageMech.MOVES


func saved_path() -> String:
	return CageMech.SAVED_MOVES


func note() -> String:
	return "sólo la meca jaula · los pasos son los de las piernas, achicados con ella"
