class_name MatchSettings
extends Resource

## LOS AJUSTES DE LA PARTIDA (22/11/2026; el usuario: «un menú F de yo como host para cambiar los settings de la partida o
## reiniciarla cuando yo quiera»). Los cambia el capitán con el F6 (BaseMatchPanel) y valen para todas las máquinas.
##   · LOS CONTROLES: con teclas, o con clic en los cuadrados (MechCrew): la palanca que se queda donde la dejás, el giro
##     que sigue solo, y las armas que se toman y se apuntan con la mira.
##   · EL ZOOM: arriba de la meca se ve más que a pie (IsoView).

const SAVED := "res://game/base/match_settings.tres"

enum Controls { KEYS, CLICK }

static var current := KnobsFile.load_into(MatchSettings.new(), SAVED) as MatchSettings

@export_group("Controles")
@export_enum("teclas", "clic en los cuadrados") var controls := 0

@export_group("Cámara")
## Desde 16: más cerca, la cámara ya está en su distancia mínima (IsoView.MIN_AWAY) y no cambia.
@export_range(16.0, 60.0, 0.5) var zoom_aboard := 29.0
@export_range(16.0, 60.0, 0.5) var zoom_foot := 22.0


func clicking() -> bool:
	return controls == Controls.CLICK


## Las perillas, para mandarlas por la red.
func values() -> Dictionary:
	return {"controls": controls, "zoom_aboard": zoom_aboard, "zoom_foot": zoom_foot}


func load_values(from: Dictionary) -> void:
	for knob: String in from:
		set(knob, from[knob])
