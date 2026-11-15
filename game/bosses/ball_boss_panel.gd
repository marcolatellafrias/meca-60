class_name BallBossPanel
extends KnobsPanel

## EL PANEL DEL JEFE BOLA (F1 en su fila): sus perillas (BallBossSettings), una pestaña por grupo. Como todos los
## paneles de perillas (KnobsPanel): se mueve un borrador, y «Guardar» lo guarda y lo aplica.

const PANEL_WIDTH := 400.0
const LABELS := {
	"walk_speed": "velocidad (m/s)", "reach_time": "tiempo para llegar a ella y para frenar (s; 0: al instante)",
	"turn_speed": "velocidad tope (°/s)", "turn_accel": "aceleración tope (°/s²)",
	"jump_height": "sube (m)", "jump_time": "tarda en subir (s)",
	"stand_height": "centro de la bola, parada (m)", "crouch_height": "centro de la bola, agachada (m)",
	"crouch_rate": "ritmo (partes por s)", "pitch_speed": "corre por la rendija a (°/s)",
	"shell_speed": "el simple: velocidad (m/s)", "shot_cooldown": "entre tiro y tiro (s)",
	"barrage_count": "del cielo: cuántos", "barrage_gap": "del cielo: sale uno cada (s)",
	"barrage_flight": "del cielo: tarda en caer (s)", "barrage_distance": "del cielo: el primero cae a (m)",
	"barrage_spacing": "del cielo: cada uno más lejos (m)",
	"fold_time": "se pliega o se abre en (s)", "roll_speed": "rodando: velocidad tope (m/s)",
	"roll_up_time": "llega a la tope en (s)", "roll_up_shape": "llegando: curva",
	"roll_coast_time": "soltando, se apaga en (s)", "roll_coast_shape": "soltando: curva",
	"roll_brake_time": "con S, frena en (s)", "roll_brake_shape": "frenando: curva",
	"roll_turn": "giro casi quieta (°/s)", "roll_turn_fast": "giro a la tope (°/s)",
	"hit_min_speed": "pega desde (m/s)", "hit_push": "pega: le cambia la velocidad (m/s)",
	"sweep_time": "dura (s)", "sweep_turns": "vueltas (negativo: al revés)", "sweep_reach": "pasa a (m del centro)",
	"sweep_height": "pasa a (m del piso)", "sweep_push": "le cambia la velocidad (m/s)",
	"tentacle_length": "largo de cada tentáculo (m)", "spread": "el pie, a cuánto del centro (m)",
	"step_radius": "un pie sale a más de (m)", "step_time": "el paso tarda (s)", "step_lift": "el pie sube (m)",
}
const TABS: Array[String] = ["Moverse", "Girar", "Saltar", "Agacharse", "Cañón", "Disparos", "Bola", "Barrido", "Tentáculos"]


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	setup_knobs("jefe_bola", "JEFE BOLA")


func knobs() -> Resource:
	return BallBossSettings.current


func fresh() -> Resource:
	return BallBossSettings.new()


func saved_path() -> String:
	return BallBossSettings.SAVED


## Nada que rearmar: el jefe lee sus perillas en cada paso (lo que cambia de forma, como la altura o los tentáculos, va
## de a poco hacia lo nuevo).
func applied() -> void:
	pass


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": draft(), "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": BallBossSettings.new()})
	return all
