class_name KinematicPanel
extends KnobsPanel

## EL PANEL DE MOVERSE DE LA MECA CINEMÁTICA (F1 en la Meca cinemática y en el Laboratorio cinemático, donde está la
## simplificada): sus perillas (KinematicSettings), una pestaña por grupo. Como todos los paneles de perillas
## (KnobsPanel): se mueve un borrador, y «Guardar» o «Volver a lo guardado» rearman las mecas con eso.
## *Era el del cubo del Laboratorio (PillarPanel) hasta el 13/11/2026.*

const PANEL_WIDTH := 400.0
const LABELS := {
	"walk_speed": "velocidad (m/s)", "reach_time": "tiempo para llegar a ella y para frenar (s; 0: al instante)",
	"turn_speed": "velocidad tope (°/s)", "turn_accel": "aceleración tope (°/s²)",
	"jump_height": "salto: sube (m)", "jump_time": "salto: tarda en subir (s)",
	"fly_speed": "vuelo: sube a (m/s)", "fly_time": "vuelo: la barra dura (s)",
	"fly_refill": "vuelo: se llena apoyada en (s)",
	"dash_distance": "recorre (m)", "dash_time": "en (s)",
	"dash_cost": "gasta de la barra (parte)", "dash_refill": "la barra se llena en (s)",
	"dash_curve": "la curva (lineal: parejo)",
	"dash_untouchable": "intocable desde que arranca (s)",
	"fall_time": "cae en (s)", "fall_lie": "queda inclinada (°)", "down_time": "tirada (s)",
	"rise_time": "se levanta en (s)",
	"crouch_share": "agachada: la altura que le queda (parte)", "crouch_rate": "ritmo (partes por s)",
}
## Una pestaña por grupo de KinematicSettings.
const TABS: Array[String] = ["Moverse", "Girar", "Saltar y volar", "Dash", "Caerse", "Agacharse"]
## LAS CONFIGURACIONES DE UN TOQUE (el usuario: «quiero probar varias combinaciones… pero no un millón de opciones…
## pensá configuraciones posibles»): cada botón ESCRIBE las dos perillas de moverse en el borrador; se aplica al
## guardar.
const PRESETS := [
	{"name": "Instantánea", "walk_speed": 8.0, "reach_time": 0.0},
	{"name": "Casi instantánea", "walk_speed": 8.0, "reach_time": 0.15},
	{"name": "Pesada", "walk_speed": 6.0, "reach_time": 0.6},
]


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	var buttons: Array[Button] = []
	for preset: Dictionary in PRESETS:
		buttons.append(new_button("Moverse: %s" % preset["name"], _apply.bind(preset)))
	setup_knobs("meca_cinematica", "MECA CINEMÁTICA: MOVERSE", buttons)


func knobs() -> Resource:
	return KinematicSettings.current


func fresh() -> Resource:
	return KinematicSettings.new()


func saved_path() -> String:
	return KinematicSettings.SAVED


func applied() -> void:
	Mech.rebuild_all(get_tree())


func note() -> String:
	return "los botones de moverse escriben el borrador: se aplica al guardar · los pasos son los de las piernas (F2)"


## Una configuración de un toque: escribe el borrador (se aplica al guardar).
func _apply(preset: Dictionary) -> void:
	for name: String in ["walk_speed", "reach_time"]:
		draft().set(name, preset[name])
	rebuild()


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for tab in TABS:
		all.append({"title": tab.to_upper(), "tab": tab, "target": draft(), "labels": LABELS,
			"include": PackedStringArray([tab]), "headers": false, "defaults": KinematicSettings.new()})
	return all
