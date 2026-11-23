class_name BaseHitPanel
extends KnobsPanel

## EL F4 DE LA PARTIDA: LAS FICHAS DE LOS GOLPES Y EL AGUANTE DE LA BOLSA (HitSettings). Como todo panel de perillas, se
## mueve un borrador y «Guardar» lo aplica. Los golpes los decide el host: lo usa el capitán.

const LABELS := {
	"skill_range": "ALCANCE DE TODAS (m)", "fist_half": "puño: abertura a cada lado (°)", "fist_reach": "puño: largo (parte)",
	"pole_width": "palo: ancho (parte)", "pole_reach": "palo: largo (parte)", "spin_half": "taladro y sierra: abertura (°)",
	"spin_reach": "taladro y sierra: largo (parte)", "cannon_width": "cañón: ancho (parte)",
	"cannon_short": "cañón de un toque: largo (parte)", "cannon_long": "cañón a fondo: largo (parte)",
	"minigun_width": "ametralladora: ancho (parte)", "minigun_reach": "ametralladora: largo (parte)",
	"missile_reach": "misil: hasta dónde vuela (parte)", "missile_radius": "misil: radio de la explosión (parte)",
	"missile_guide": "misil: se guía durante (s)", "shield_half": "escudo: frena a cada lado (°)",
	"shield_reach": "escudo: largo que se dibuja (parte)",
	"fist_damage": "daño", "fist_stagger": "quiebre", "fist_push": "empuje (m)",
	"cannon_damage": "daño a fondo", "cannon_stagger": "quiebre a fondo", "cannon_push": "empuje a fondo (m)",
	"minigun_damage": "daño por pulso (10 por segundo)", "minigun_stagger": "quiebre por pulso",
	"minigun_push": "empuje por pulso (m)",
	"missile_damage": "daño en el centro", "missile_stagger": "quiebre en el centro", "missile_push": "empuje en el centro (m)",
	"spin_damage": "daño", "spin_stagger": "quiebre", "spin_push": "empuje (m)",
	"aim_sensitivity": "sensibilidad de la mira", "gun_turn": "giro de las armas de arriba (°/s)",
	"missile_speed": "velocidad del misil (m/s)",
	"missile_turn": "lo que dobla el misil (°/s)",
	"bag_poise": "aguante", "poise_wait": "espera para recuperarlo (s)", "poise_refill": "lo recupera por segundo",
	"bag_weight": "peso (más, menos empuje)",
}
const TABS: Array[String] = ["Zonas", "Puño", "Cañón", "Ametralladora", "Misil", "Taladro y sierra", "Puntería", "La bolsa"]


func setup_panel() -> void:
	panel_width = 460.0
	setup_knobs("golpes_partida", "LOS GOLPES")


func _can_open() -> bool:
	return BaseState.is_captain(get_tree()) and UIState.gameplay_active()


func knobs() -> Resource:
	return HitSettings.current


func fresh() -> Resource:
	return HitSettings.new()


func saved_path() -> String:
	return HitSettings.SAVED


func note() -> String:
	return "con esta cámara se ven %.1f m hacia abajo; el empuje sólo ocurre si rompe el aguante" % MechSkills.visible_reach()


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": draft(), "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": HitSettings.new()})
	return all
