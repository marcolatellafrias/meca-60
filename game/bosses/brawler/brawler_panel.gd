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
	"rage_time": "la ira: cambia de color en (s)",
	"punch_damage": "una piña en el cuerpo le saca", "furnace_damage": "una piña en el horno abierto le saca",
	"punch_reference": "a esta fuerza (kg·m/s); más fuerte, más",
	"energy_damage": "tiros y taladro: vida por 100.000 kg·m/s",
	"hit_sway": "se inclina con un golpe (por 100.000 kg·m/s)", "energy_cap": "lo más por golpe",
	"arena_radius": "radio de la arena (m; los edificios, con R)",
}
## Lo de siempre de cada poder (ver BossPower); los nombres de los modos los pone `sections`.
const POWER_LABELS := {"in_calm": "LO USA: tranquilo", "reach_from": "desde (m)", "reach_to": "hasta (m)"}
## Las pestañas del cuerpo; después, una por modo y una por poder.
const TABS: Array[String] = ["Orugas", "Cintura", "Horno", "Modos", "Golpes", "Arena"]
## Lo de todo poder: en qué modos lo usa y a qué distancia (va arriba en su pestaña).
const WHEN: Array[String] = ["in_calm", "in_mode_1", "in_mode_2", "reach_from", "reach_to"]
## Las perillas de los modos, en BrawlerSettings (en el orden de los tildes de los poderes).
const MODES: Array[String] = ["rage", "flight"]
## Las perillas de los poderes, en BrawlerSettings (en el orden de BrawlerBrain.Act).
const POWERS: Array[String] = ["charge", "slam", "throw", "spin", "hook", "flame", "bomb"]


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


## UNA PESTAÑA POR GRUPO DEL CUERPO, UNA POR MODO (cuándo entra, cuánto dura, qué cambia) Y UNA POR PODER (en qué
## modos lo usa, a qué distancia y sus variantes; si al Luchador le falta lo que pide, lo dice).
func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": draft(), "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": BrawlerSettings.new()})
	var fresh_set := BrawlerSettings.new()
	var mode_names := PackedStringArray()
	for mode in (draft() as BrawlerSettings).modes():
		mode_names.append(mode.title)
	for index in MODES.size():
		all.append({"title": "MODO: %s" % mode_names[index].to_upper(), "tab": "Modo %s" % mode_names[index],
			"target": draft().get(MODES[index]), "labels": BossMode.LABELS, "headers": false,
			"choices": BossPower.choice_spec(draft().get(MODES[index])),
			"defaults": fresh_set.get(MODES[index])})
	for field in POWERS:
		var power := draft().get(field) as BossPower
		var labels := POWER_LABELS.duplicate()
		labels["in_mode_1"] = "LO USA: en %s" % mode_names[0]
		labels["in_mode_2"] = "LO USA: en %s" % mode_names[1]
		labels.merge(power.labels())
		var missing := Brawler.lacks(power.needs())
		var title := power.title().to_upper()
		if not missing.is_empty():
			title += " (le falta: %s)" % ", ".join(missing)
		# Arriba, cuándo lo usa (lo de todo poder); abajo, lo suyo.
		var tab := power.title().capitalize()
		all.append({"title": title, "tab": tab, "target": power, "labels": labels, "headers": false,
			"only": PackedStringArray(WHEN), "defaults": fresh_set.get(field)})
		all.append({"title": "SUS VARIANTES", "tab": tab, "target": power, "labels": labels, "headers": false,
			"skip": PackedStringArray(WHEN), "choices": BossPower.choice_spec(power), "defaults": fresh_set.get(field)})
	return all
