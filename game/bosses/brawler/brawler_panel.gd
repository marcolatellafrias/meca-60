class_name BrawlerPanel
extends KnobsPanel

## EL PANEL DEL LUCHADOR (F1 en su fila): sus perillas (BrawlerSettings), una pestaña por grupo. Como todos los paneles
## de perillas (KnobsPanel): se mueve un borrador, y «Guardar» lo guarda y lo aplica. Lo lee en cada paso: nada que
## rearmar.

const PANEL_WIDTH := 400.0
const LABELS := {
	"speed": "velocidad tope (m/s)", "up_time": "llega a la tope en (s)", "up_shape": "llegando: curva",
	"coast_time": "soltando, se apaga en (s)", "coast_shape": "soltando: curva",
	"brake_time": "frenando, para en (s)", "brake_shape": "frenando: curva",
	"reverse_share": "para atrás: parte de la tope", "turn_speed": "giro de las orugas (°/s)",
	"turn_time": "el giro llega y para en (s)", "waist_speed": "giro de la cintura (°/s)",
	"door_time": "la puerta tarda (s)", "door_angle": "se abre hasta (°)",
	"rage_time": "cambia en (s)", "rage_speed": "más rápido (veces)",
	"arena_radius": "radio de la arena (m; los edificios, con R)",
}
const TABS: Array[String] = ["Orugas", "Cintura", "Horno", "Ira", "Arena"]


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup_knobs("luchador", "LUCHADOR DE ORUGAS")


func knobs() -> Resource:
	return BrawlerSettings.current


func fresh() -> Resource:
	return BrawlerSettings.new()


func saved_path() -> String:
	return BrawlerSettings.SAVED


func applied() -> void:
	pass


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": draft(), "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": BrawlerSettings.new()})
	return all
