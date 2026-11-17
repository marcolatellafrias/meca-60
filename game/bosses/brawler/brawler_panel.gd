class_name BrawlerPanel
extends KnobsPanel

## EL PANEL DEL LUCHADOR (F1 en su fila): sus perillas (BrawlerSettings), una pestaña por grupo del cuerpo y UNA POR
## PODER (BossPower: su tilde, a qué distancia lo usa, si es sólo con ira y sus pocas variantes; el usuario: «tildo los
## poderes… y después cada poder le puedo cambiar unas variantes»). Como todos los paneles de perillas (KnobsPanel): se
## mueve un borrador, y «Guardar» lo guarda y lo aplica (lo que pelea toma las perillas nuevas).

const PANEL_WIDTH := 400.0
const LABELS := {
	"speed": "velocidad tope (m/s)", "up_time": "llega a la tope en (s)", "up_shape": "llegando: curva",
	"coast_time": "soltando, se apaga en (s)", "coast_shape": "soltando: curva",
	"brake_time": "frenando, para en (s)", "brake_shape": "frenando: curva",
	"reverse_share": "para atrás: parte de la tope", "turn_speed": "giro de las orugas (°/s)",
	"turn_time": "el giro llega y para en (s)", "waist_speed": "giro de la cintura (°/s)",
	"door_time": "la puerta tarda (s)", "door_angle": "se abre hasta (°)",
	"rage_time": "cambia en (s)", "rage_speed": "más rápido (veces)",
	"rage_calm": "tranquilo (s; 0, sólo con la tecla)", "rage_last": "con ira (s)",
	"rage_chain": "encadena otro ataque (chance)",
	"punch_damage": "una piña en el cuerpo le saca", "furnace_damage": "una piña en el horno abierto le saca",
	"energy_damage": "tiros y taladro: vida por 100.000 kg·m/s", "energy_cap": "lo más por golpe",
	"arena_radius": "radio de la arena (m; los edificios, con R)",
}
## Lo de siempre de cada poder (ver BossPower).
const POWER_LABELS := {"on": "LO USA", "reach_from": "desde (m)", "reach_to": "hasta (m)",
	"rage_only": "sólo con ira"}
## Las pestañas del cuerpo; después, una por poder.
const TABS: Array[String] = ["Orugas", "Cintura", "Horno", "Ira", "Golpes", "Arena"]
## Las perillas de los poderes, en BrawlerSettings (en el orden de BrawlerBrain.Act).
const POWERS: Array[String] = ["charge", "slam", "throw", "spin", "hook", "flame"]


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup_knobs("luchador", "LUCHADOR DE ORUGAS")


func knobs() -> Resource:
	return BrawlerSettings.current


func fresh() -> Resource:
	return BrawlerSettings.new()


func saved_path() -> String:
	return BrawlerSettings.SAVED


## Lo que pelea toma las perillas nuevas (sus copias de cada poder).
func applied() -> void:
	for brawler in BrawlerArchetype.brawlers():
		var brain := brawler.get_node_or_null("Cabeza") as BrawlerBrain
		if brain != null:
			brain.refresh_powers()


## UNA PESTAÑA POR GRUPO DEL CUERPO, Y UNA POR PODER (su tilde, a qué distancia, si es sólo con ira y sus variantes; si
## al Luchador le falta lo que pide, lo dice).
func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": draft(), "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": BrawlerSettings.new()})
	var fresh_set := BrawlerSettings.new()
	for field in POWERS:
		var power := draft().get(field) as BossPower
		var labels := POWER_LABELS.duplicate()
		labels.merge(power.labels())
		var missing := Brawler.lacks(power.needs())
		var title := power.title().to_upper()
		if not missing.is_empty():
			title += " (le falta: %s)" % ", ".join(missing)
		all.append({"title": title, "tab": power.title().capitalize(), "target": power, "labels": labels,
			"headers": false, "defaults": fresh_set.get(field)})
	return all
