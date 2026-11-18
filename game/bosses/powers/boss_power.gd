class_name BossPower
extends Resource

## UN PODER DE UN JEFE (17/11/2026): un ataque que se tilda o no, con sus pocas variantes como perillas. El usuario:
## «un sistema robusto… más modularizados distintos tipos de ataque… que yo después pueda hacer variaciones… tildo
## los poderes… y después cada poder le puedo cambiar unas variantes… libertad sin tantos sliders».
##   · LO QUE ES: sus perillas (`@export`, en el panel del jefe una pestaña por poder: EN QUÉ MODOS LO USA —tranquilo,
##     y cada modo del jefe (BossMode: la ira, el vuelo…)—, a qué distancia `reach_from`/`reach_to`, y sus variantes;
##     las «fuertes» valen en los modos que lo dicen). Cada jefe usa una COPIA (`duplicate`): lo que guarda mientras
##     pelea (lo que lanzó, por dónde va) es de esa copia.
##   · LO QUE NECESITA (`needs`): las piezas del cuerpo que lo hacen posible (un horno, dos brazos): si el jefe no las
##     tiene, no lo puede usar (el panel lo dice).
##   · CÓMO PELEA: `start` al elegirlo; `act` en cada paso mientras es el ataque de ahora, por tiempos (`b.step`,
##     `b.clock`, `b.next(n)`), y `b.finish()` al terminar; `tick` en cada paso aunque no sea el de ahora (lo que lanzó
##     sigue en el mundo: las ondas, las piedras); `drop` si lo cortan (lo que quedó a medio armar se va).
## Lo común (el blanco, los golpes, manejar, la ira) lo da la cabeza (BrawlerBrain, `b`).

## En qué modos lo usa: tranquilo (sin modo), y en el primero y el segundo de los modos del jefe.
@export var in_calm := true
@export var in_mode_1 := true
@export var in_mode_2 := false
## Desde y hasta qué distancia lo usa (m, de su medio al blanco).
@export_range(0.0, 300.0, 1.0) var reach_from := 30.0
@export_range(0.0, 300.0, 1.0) var reach_to := 120.0

## Cuántas veces lo usó y cuántas pegó (para mirar).
var uses := 0
var hits := 0


## Su nombre (para el panel, el letrero y la L de la parcela).
func title() -> String:
	return "poder"


## Lo que pide del cuerpo (las piezas: "horno", "dos brazos"…). Vacío: nada.
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


## Las perillas de `from` pasan a esta copia (el panel guardó): lo que guarda mientras pelea, no.
func copy_knobs(from: BossPower) -> void:
	for property in from.get_property_list():
		if property["usage"] & PROPERTY_USAGE_STORAGE and property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			set(property["name"], from.get(property["name"]))
