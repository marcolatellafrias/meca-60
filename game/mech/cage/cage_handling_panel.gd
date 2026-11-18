class_name CageHandlingPanel
extends KnobsPanel

## CÓMO SE MANEJA LA MECA JAULA DESDE ADENTRO (F7 en su fila; ver CageHandling, CageBoards): lo de mantener apretado.
## El resorte del giro y la inclinación del torso, en el F1 (cómo se mueve).

const PANEL_WIDTH := 400.0
const LABELS := {
	"punch_charge_time": "se carga del todo en (s)",
	"punch_slowest": "cargada: velocidad de la piña (×; menos, más lenta)",
	"punch_strongest": "cargada: fuerza del golpe (×)",
}


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup_knobs("meca_jaula_manejo", "MECA JAULA: EL MANEJO")
	say("el resorte del giro y la inclinación del torso, en el F1")


func knobs() -> Resource:
	return CageHandling.current


func fresh() -> Resource:
	return CageHandling.new()


func saved_path() -> String:
	return CageHandling.SAVED


func applied() -> void:
	pass


func sections() -> Array[Dictionary]:
	return [{"title": "LA PIÑA CARGADA", "target": draft(), "labels": LABELS, "headers": false,
		"defaults": CageHandling.new()}]
