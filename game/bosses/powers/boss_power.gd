class_name BossPower
extends Resource

## UN PODER DE UN JEFE (17/11/2026): un ataque que se tilda o no, con sus pocas variantes como perillas. El usuario:
## «un sistema robusto… más modularizados distintos tipos de ataque… que yo después pueda hacer variaciones… tildo
## los poderes… y después cada poder le puedo cambiar unas variantes… libertad sin tantos sliders».
##   · LO QUE ES: sus perillas (`@export`, en el panel del jefe una pestaña por poder: EN QUÉ MODOS LO USA —tranquilo,
##     y cada modo del jefe (BossMode: la ira, el vuelo…)—, a qué distancia `reach_from`/`reach_to`, y sus variantes;
##     las «fuertes» valen en los modos que lo dicen). Cada jefe usa una COPIA (`duplicate`): lo que guarda mientras
##     pelea (lo que lanzó, por dónde va) es de esa copia.
##   · DE DÓNDE SALE Y CON QUÉ PEGA, LIBRE (el usuario: «yo decido desde qué punto sale algo y no tanto algo tan
##     figurativo»): el poder no sabe qué hay en el cuerpo. Sus perillas que terminan en `_point` (de qué punto sale),
##     `_zone` (qué zona de golpe prende) y `_pose` (qué pose pone) se eligen, en el panel, entre los nombres que ofrece
##     el cuerpo (`choices`); y `exposes`, si deja a la vista el punto débil mientras dura.
##   · LO QUE PIDE (`needs`): sólo lo físico («suelo»): si el jefe no lo tiene ahora (vuela), no lo usa.
##   · CÓMO PELEA: `start` al elegirlo; `act` en cada paso mientras es el ataque de ahora, por tiempos (`b.step`,
##     `b.clock`, `b.next(n)`), y `b.finish()` al terminar; `tick` en cada paso aunque no sea el de ahora (lo que lanzó
##     sigue en el mundo: las ondas, las piedras); `drop` si lo cortan (lo que quedó a medio armar se va).
## Lo común (el blanco, los golpes, manejar, la ira) lo da la cabeza (BrawlerBrain, `b`).

## En qué modos lo usa: tranquilo (sin modo), y en el primero y el segundo de los modos del jefe.
@export var in_calm := true
@export var in_mode_1 := true
@export var in_mode_2 := false
## Desde y hasta qué distancia lo usa (m, de su medio al blanco).
@export_range(0.0, 60.0, 0.5) var reach_from := 5.0
@export_range(0.0, 60.0, 0.5) var reach_to := 13.0

## LO QUE OFRECE EL CUERPO, para elegir en el panel: los nombres de sus puntos, sus zonas de golpe, sus poses y sus
## aspectos. Hoy, los del Luchador (el único cuerpo); con otro cuerpo, su panel pone los suyos antes de armarse.
static var choices := {"point": Brawler.POINTS, "zone": Brawler.ZONES, "pose": Brawler.POSE_NAMES,
	"look": Brawler.LOOKS}
## Los nombres de las perillas de siempre.
const BODY_LABELS := {"from_point": "sale de", "hit_zone": "pega con", "ready_pose": "pose del aviso",
	"strike_pose": "pose del golpe", "exposes": "deja a la vista el punto débil"}

## Cuántas veces lo usó y cuántas pegó (para mirar).
var uses := 0
var hits := 0


## LAS PERILLAS DE `target` QUE SON UNA LISTA DE NOMBRES DEL CUERPO (las que se llaman, o terminan en, `_point`,
## `_zone`, `_pose` o `look`): {propiedad: [nombres]}, para el panel (`choices` de sus secciones; también los modos).
static func choice_spec(target: Object) -> Dictionary:
	var out := {}
	for property in target.get_property_list():
		var name := str(property["name"])
		for kind: String in choices:
			if name == kind or name.ends_with("_" + kind):
				out[name] = choices[kind]
	return out


## Su nombre (para el panel, el letrero y la L de la parcela).
func title() -> String:
	return "poder"


## Lo que pide (sólo lo físico: "suelo"). Vacío: nada.
func needs() -> PackedStringArray:
	return PackedStringArray()


## Los nombres de sus perillas en el panel (propiedad → texto). Los tres de siempre los pone el panel.
func labels() -> Dictionary:
	return {}


## Si lo usa en el modo de índice `mode` (-1, tranquilo).
func used_in(mode: int) -> bool:
	return in_calm if mode < 0 else (in_mode_1 if mode == 0 else in_mode_2)


## Si lo usa en algún modo.
func used() -> bool:
	return in_calm or in_mode_1 or in_mode_2


## Si lo puede usar ahora, a `gap` metros (además de sus modos).
func ready_at(gap: float) -> bool:
	return gap > reach_from and gap < reach_to


func start(_b: BrawlerBrain) -> void:
	pass


func act(_b: BrawlerBrain, _delta: float) -> void:
	pass


func tick(_b: BrawlerBrain, _delta: float) -> void:
	pass


func drop(_b: BrawlerBrain) -> void:
	pass


## LAS PERILLAS EN METROS Y M/S, las que estira el alcance de los ataques (BossSettings.attack_range).
func reach_knobs() -> PackedStringArray:
	return PackedStringArray()


## ESTA COPIA, ESTIRADA `share` veces: distancias y velocidades juntas, así los tiempos de aviso no cambian. Se llama sobre
## una copia recién tomada de las perillas (ver BrawlerBrain.refresh_powers).
func fit_reach(share: float) -> void:
	for knob: String in ["reach_from", "reach_to"] + Array(reach_knobs()):
		set(knob, float(get(knob)) * share)


## Las perillas de `from` pasan a esta copia (el panel guardó): lo que guarda mientras pelea, no.
func copy_knobs(from: BossPower) -> void:
	for property in from.get_property_list():
		if property["usage"] & PROPERTY_USAGE_STORAGE and property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			set(property["name"], from.get(property["name"]))
