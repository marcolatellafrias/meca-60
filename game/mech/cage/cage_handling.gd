class_name CageHandling
extends Resource

## CÓMO SE MANEJA LA MECA JAULA DESDE ADENTRO: las perillas de los controles (17/11/2026, el usuario: «un panel F… con
## una cierta cantidad de opciones»; ver CageBoards). El giro y la inclinación del torso son de cómo se mueve (el F1,
## KinematicSettings: el resorte). Acá, lo de mantener apretado:
##   · LA PIÑA CARGADA (el mando del puño, clic izquierdo mantenido; MechArm.charged_strike): en cuánto se carga del todo,
##     y cargada del todo, lo fuerte (× el golpe) que sale. Sale siempre a la misma velocidad.
## Se guarda en `SAVED` (del usuario: no se sube); el F7 de su fila (CageHandlingPanel).

const SAVED := "res://game/mech/cage/cage_handling.tres"
static var current := CageHandling.saved()

@export_group("La piña cargada")
@export_range(0.1, 3.0, 0.05) var punch_charge_time := 1.0
@export_range(1.0, 4.0, 0.05) var punch_strongest := 2.5


static func saved() -> CageHandling:
	if ResourceLoader.exists(SAVED):
		return KnobsFile.load_into(CageHandling.new(), SAVED) as CageHandling
	return CageHandling.new()
