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
	"charge_windup": "aviso: abre el horno (s)", "charge_speed": "velocidad (m/s)",
	"charge_up_time": "llega a ella en (s)", "charge_time": "dura como mucho (s)",
	"charge_homing": "corrige hacia vos (°/s)", "stun_time": "estrellado, aturdido (s)",
	"charge_damage": "te saca (vida)", "charge_push": "te empuja (m/s)",
	"punch_damage": "una piña en el cuerpo le saca", "furnace_damage": "una piña en el horno abierto le saca",
	"arena_radius": "radio de la arena (m; los edificios, con R)",
	"slam_windup": "aviso: los brazos arriba (s)", "slam_recover": "se queda después (s)",
	"wave_speed": "la onda corre a (m/s)", "wave_reach": "llega hasta (m)", "wave_width": "ancho (m)",
	"wave_damage": "te saca (vida)", "wave_push": "te levanta (m/s)",
	"rip_time": "mete las manos y lo arranca en (s)", "lift_time": "aviso: la tiene arriba (s)",
	"rock_flight": "vuela (s)", "rock_arc": "el arco sube (m)", "rock_radius": "radio del golpe (m)",
	"rock_stay": "queda en el piso (s)", "throw_recover": "se queda después (s)",
	"rock_damage": "te saca (vida)", "rock_push": "te empuja (m/s)",
	"spin_windup": "aviso: abre los brazos (s)", "spin_time": "gira (s)", "spin_speed": "a (°/s)",
	"spin_move": "las orugas, a (m/s)", "spin_dizzy": "mareado, horno abierto (s)",
	"spin_reach": "los brazos llegan a (m)", "spin_damage": "te saca (vida)", "spin_push": "te empuja (m/s)",
	"hook_windup": "aviso: la franja (s)", "hook_lock": "ya apuntó, quieta (s)", "hook_speed": "la mano sale a (m/s)",
	"hook_reach": "llega hasta (m)", "hook_width": "ancho (m)", "swing_time": "te revolea (s)",
	"swing_speed": "a (°/s)", "fling_distance": "te tira a (m)", "fling_arc": "el arco sube (m)",
	"fling_time": "vuelo (s)", "fling_damage": "al caer te saca (vida)", "hook_recover": "se queda después (s)",
}
const TABS: Array[String] = ["Orugas", "Cintura", "Horno", "Ira", "Embestida", "Golpe al piso", "Arrancar el piso",
	"Trompo", "Agarre", "Golpes", "Arena"]


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
