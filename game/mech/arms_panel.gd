class_name ArmsPanel
extends TunerPanel

## LOS BRAZOS (F3 de las filas de la meca): UN SOLO PANEL PARA TODAS, CON UNA PESTAÑA POR CLASE DE BRAZO, y cada fila
## muestra sólo las de los brazos que tiene su meca (16/11/2026, el usuario: «los paneles deberían ser los mismos que la
## meca común, solamente que cada meca elige qué cosas usar y qué cosas no»; «unificalos… para que quede en todas las
## mecas a la vez»). Las perillas son las de siempre, una copia para todas las mecas: los brazos discretos
## (PoseArmSettings) y los con músculos (MuscleArmSettings). Como los de perillas (KnobsPanel): se mueve un borrador,
## y «Guardar» o «Volver a lo guardado» los escriben y rearman las mecas.
## *Hasta ese día eran dos paneles, PoseArmPanel y MuscleArmPanel, y la meca jaula, que tiene uno de cada, no tenía
## ninguno.*

enum Kind { POSE, MUSCLE }

## *El ancho era el del panel del cubo (HoverPanel), borrado con él el 17/11/2026.*
const PANEL_WIDTH := 420.0
const TITLES := {Kind.POSE: "Discretos", Kind.MUSCLE: "Con músculos"}
const POSE_LABELS := {
	"punch_speed": "piñas: cuánto más rápidas (×)",
	"hit_mass": "al conectar: lo que pesa el puño (kg)", "fist_radius": "al conectar: radio del puño (m)",
	"stops_on_hit": "al conectar: se frena donde pega",
}
const MUSCLE_LABELS := {
	"muscle_kp": "músculo: resorte (cuánto tira)", "muscle_kd": "músculo: freno",
	"muscle_max": "músculo: fuerza tope (rad/s²)",
	"follow": "músculo: sigue la velocidad pedida (0 no, 1 entera)",
	"pass_through": "atraviesa y pega con la punta (al armar)",
	"punch_speed": "piñas: cuánto más rápidas (×)",
	"mouse_reach": "a mano: m por cada 100 px del mouse", "depth_speed": "a mano: W/S adelante y atrás (m/s)",
}

## Las clases de brazo de la meca de la fila, en orden.
var kinds: Array[Kind] = []
var _drafts := {}
var _state: Label = null


func _init(with: Array[Kind] = [Kind.POSE]) -> void:
	kinds = with


func setup_panel() -> void:
	panel_width = PANEL_WIDTH
	for kind in kinds:
		var draft := ArmsPanel._fresh(kind)
		KnobsFile.copy(draft, ArmsPanel._knobs(kind))
		_drafts[kind] = draft
	setup("brazos", "BRAZOS", [new_button("Guardar", _save), new_button("Volver a lo guardado", _restore)])
	_state = state_label()


func sections() -> Array[Dictionary]:
	var all: Array[Dictionary] = []
	for kind in kinds:
		all.append({"title": String(TITLES[kind]).to_upper(), "tab": TITLES[kind], "target": _drafts[kind],
			"labels": POSE_LABELS if kind == Kind.POSE else MUSCLE_LABELS, "defaults": ArmsPanel._fresh(kind)})
	return all


## ── LO DE CADA CLASE ─────────────────────────────────────────────────────────────────────────────────────────────

static func _knobs(kind: Kind) -> Resource:
	return PoseArmSettings.current if kind == Kind.POSE else MuscleArmSettings.current


static func _fresh(kind: Kind) -> Resource:
	return PoseArmSettings.new() if kind == Kind.POSE else MuscleArmSettings.new()


static func _path(kind: Kind) -> String:
	return PoseArmSettings.SAVED if kind == Kind.POSE else MuscleArmSettings.SAVED


## ── GUARDAR Y VOLVER ─────────────────────────────────────────────────────────────────────────────────────────────

func _save() -> void:
	var failed := false
	for kind in kinds:
		KnobsFile.copy(ArmsPanel._knobs(kind), _drafts[kind])
		failed = failed or ResourceSaver.save((_drafts[kind] as Resource).duplicate(), ArmsPanel._path(kind)) != OK
	Mech.rebuild_all(get_tree())
	_say("no se pudo guardar" if failed else "guardado y aplicado")


func _restore() -> void:
	for kind in kinds:
		KnobsFile.copy(_drafts[kind], KnobsFile.load_into(ArmsPanel._fresh(kind), ArmsPanel._path(kind)))
		KnobsFile.copy(ArmsPanel._knobs(kind), _drafts[kind])
	rebuild()
	Mech.rebuild_all(get_tree())


func _say(text: String) -> void:
	if _state != null:
		_state.text = text
