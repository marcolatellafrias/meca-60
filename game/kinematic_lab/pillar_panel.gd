class_name PillarPanel
extends TunerPanel

## EL PANEL DEL CUBO CINEMÁTICO (F1 en el Laboratorio cinemático): sus perillas (PillarSettings), una pestaña por
## grupo (el usuario: «organices mejor el panel F con tabs»).

const PANEL_WIDTH := 400.0
const LABELS := {
	"walk_speed": "velocidad (m/s)", "reach_time": "tiempo para llegar a ella y para frenar (s; 0: al instante)",
	"air_control": "en el aire, cuánto se controla (parte)", "loose_mode": "cómo trata lo suelto",
	"turn_speed": "velocidad tope (°/s)", "turn_accel": "aceleración tope (°/s²)",
	"jump_height": "salto (m)", "air_gravity": "en el aire pesa (veces)",
	"thrust": "vuelo: empuje (m/s²)", "thrust_time": "vuelo: la barra dura (s)",
	"thrust_refill": "vuelo: se llena apoyado en (s)",
	"dash_speed": "suma (m/s)", "dash_lift": "en el aire, sube a (m/s)", "dash_hold": "un rato sin frenar (s)",
	"dash_cost": "gasta de la barra (parte)", "dash_refill": "la barra se llena en (s)",
	"crouch_share": "agachado: alto que queda (parte)", "crouch_rate": "ritmo (partes por s)",
	"cap_extra": "topadora: sale como mucho tanto más rápido (m/s)",
	"ghost_extra": "atraviesa: empuja tanto más rápido (m/s)",
}
## Una pestaña por grupo de PillarSettings.
const TABS: Array[String] = ["Moverse", "Girar", "Saltar y volar", "Dash", "Agacharse", "Con lo suelto"]


## LAS CONFIGURACIONES DE UN TOQUE (el usuario: «quiero probar varias combinaciones… pero no un millón de opciones…
## pensá configuraciones posibles»): cada botón ESCRIBE las tres perillas de moverse; lo que manda son las perillas
## (después se ajustan a mano).
const PRESETS := [
	{"name": "Instantánea", "walk_speed": 8.0, "reach_time": 0.0, "air_control": 1.0},
	{"name": "Casi instantánea", "walk_speed": 8.0, "reach_time": 0.15, "air_control": 1.0},
	{"name": "Pesada", "walk_speed": 6.0, "reach_time": 0.6, "air_control": 0.5},
	{"name": "Sin control en el aire", "walk_speed": 8.0, "reach_time": 0.0, "air_control": 0.0},
]


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	var buttons: Array[Button] = []
	for preset: Dictionary in PRESETS:
		buttons.append(new_button("Moverse: %s" % preset["name"], _apply.bind(preset)))
	setup("cubo_cinematico", "CUBO CINEMÁTICO", buttons)


func _apply(preset: Dictionary) -> void:
	for name: String in ["walk_speed", "reach_time", "air_control"]:
		PillarSettings.current.set(name, preset[name])
	rebuild()


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": PillarSettings.current, "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": PillarSettings.new()})
	return all
