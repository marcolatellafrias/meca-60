class_name BaseDashPanel
extends KnobsPanel

## EL F3 DE LA PARTIDA: CÓMO ES EL DASH Y EL STUN DE LA BATERÍA NEGATIVA (DashSettings). Como todo panel de perillas, se mueve un borrador y «Guardar» lo
## aplica, en todas las máquinas (BaseSync.share_dash). Lo usa el capitán, también en la arena.

const LABELS := {
	"style": "estilo", "inertia": "con inercia al terminar", "inertia_time": "la inercia frena en (s)",
	"burst_distance": "recorre (m)", "burst_time": "en (s)", "burst_cost": "gasta (energía)",
	"burst_cooldown": "espera entre dashes (s)", "burst_untouchable": "intocable desde que arranca (s; 0, nunca)",
	"thrust_speed": "sobrevuelo: velocidad (m/s)", "thrust_drain": "gasta por segundo (energía)",
	"thrust_start": "gasta al arrancar (energía)",
	"shield_cast": "gasta al activarlo (energía)", "shield_hold": "gasta por segundo al mantenerlo (energía)",
	"shield_parry": "activarlo justo a tiempo devuelve el costo",
	"fist_light_share": "puño: parte de la carga para el liviano", "fist_cost": "puño: gasta al apretar (energía)",
	"fist_heavy_cost": "puño: gasta al llegar a pesado (energía)", "cannon_segment_time": "cañón: cada segmento carga en (s)",
	"cannon_segment_cost": "cañón: gasta cada segmento (energía)",
	"energy_capacity": "capacidad de la batería", "energy_refill": "recarga por segundo",
	"stun_on": "mini stun con batería negativa", "stun_time": "el stun dura (s)",
	"stun_blocks_guns": "el stun frena ametralladora y misiles",
	"recoil_on": "retroceso al disparar", "cannon_recoil": "cañón, tercer segmento: empuja (m)",
	"tap_recoil": "cañón, primer segmento: empuja (m)", "recoil_time": "se frena en (s)",
	"minigun_slow": "ametralladora: cuánto menos avanza (parte)",
}
const TABS: Array[String] = ["Estilo", "Ráfaga", "Propulsor", "Escudo", "Golpes", "Energía", "Retroceso"]


func setup_panel() -> void:
	panel_width = 400.0
	setup_knobs("dash_partida", "EL DASH Y LA ENERGÍA")


func _can_open() -> bool:
	return BaseState.is_captain(get_tree()) and UIState.gameplay_active()


func knobs() -> Resource:
	return DashSettings.current


func fresh() -> Resource:
	return DashSettings.new()


## Con un experimento firmado, el suyo (Experiments).
func saved_path() -> String:
	return Experiments.path_for(DashSettings.SAVED)


func applied() -> void:
	if BaseSync.current != null:
		BaseSync.current.share_dash()


func note() -> String:
	if not Experiments.active.is_empty():
		return "«Guardar» lo aplica y lo guarda en el experimento «%s»" % Experiments.active
	return "«Guardar» lo aplica al instante"


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": draft(), "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": DashSettings.new()})
	return all
