class_name Experiments
extends RefCounted

## LOS EXPERIMENTOS (22/11/2026; el usuario: «cuando selecciones un contrato sea un experimento y cuando selecciones otro
## sea otro… cuando selecciones el contrato puedas cambiar los valores de los paneles. O sea, no hacer un sistema nuevo
## encima»). Un contrato de prueba (ContractsCatalog, `experiment`) es un juego de perillas para los paneles de siempre:
##   · AL FIRMARLO, cada recurso de perillas (`current` de DashSettings, BossSettings y BrawlerSettings) toma las del
##     experimento: SU ARCHIVO si ya se guardó alguna vez (`<archivo>_exp_<id>.tres`, `path_for`), y si no, LO GUARDADO
##     DE SIEMPRE CON LOS CAMBIOS DE `CHANGES`. Firmar un contrato sin experimento vuelve a lo guardado de siempre.
##   · LOS PANELES SIGUEN ANDANDO ENCIMA (F3 el dash, F5 el jefe): con un experimento firmado, «Guardar» guarda en el
##     archivo de ese experimento y no toca el de siempre (`path_for`, que usan sus `saved_path`).
## Lo aplica cada máquina al cambiar el contrato (BaseSync); el dash, además, lo reparte el host. Los archivos son del
## usuario, como todos los de perillas (KnobsFile).
##
## LOS CUATRO DE HOY (ver docs/technical/experimentos.md):
##   · «bolitas», MUCHAS COSAS PARA ESQUIVAR (22/11/2026): sólo las bolitas de distintos tipos (OrbsPower), y la meca con el dash
##     intocable y el sobrevuelo.
##   · «mixto», LAS DOS MANERAS JUNTAS (el usuario, 22/11/2026): todos los poderes de las otras dos, cada uno con su aviso
##     (zonas marcadas; la embestida y el trompo, por la pose), y la meca con la ráfaga intocable Y el sobrevuelo.
##   · «posicion», ESQUIVAR POR POSICIÓN: los poderes de zonas y de cosas lanzadas (la onda, la piedra, el agarre, el
##     lanzallamas), las marcas en el piso, y el dash sin intocable.
##   · «timing», ESQUIVAR POR TIEMPO: los poderes que pegan con el cuerpo (la embestida, el trompo), sin marcas en el
##     piso (se leen por la pose, como en Souls), y la ráfaga más corta pero intocable un rato.

const CHANGES := {
	"posicion": {
		"dash": {"style": DashSettings.Style.BURST, "burst_untouchable": 0.0},
		"boss": {"floor_marks": true},
		"powers": {"charge": false, "slam": true, "throw": true, "spin": false, "hook": true, "flame": true,
			"bomb": false},
	},
	"timing": {
		"dash": {"style": DashSettings.Style.BURST, "burst_distance": 5.0, "burst_untouchable": 0.3},
		"boss": {"floor_marks": false},
		"powers": {"charge": true, "slam": false, "throw": false, "spin": true, "hook": false, "flame": false,
			"bomb": false},
	},
	"bolitas": {
		"dash": {"style": DashSettings.Style.BOTH, "burst_untouchable": 0.2},
		"boss": {"floor_marks": true},
		"powers": {"charge": false, "slam": false, "throw": false, "spin": false, "hook": false, "flame": false,
			"bomb": false, "orbs": true},
	},
	"mixto": {
		"dash": {"style": DashSettings.Style.BOTH, "burst_untouchable": 0.3},
		"boss": {"floor_marks": true},
		"powers": {"charge": true, "slam": true, "throw": true, "spin": true, "hook": true, "flame": true,
			"bomb": false},
	},
}

## El experimento firmado ("" ninguno: lo guardado de siempre).
static var active := ""


## DÓNDE SE GUARDA un recurso de perillas cuyo archivo de siempre es `saved`: con un experimento firmado, el suyo.
static func path_for(saved: String) -> String:
	if active.is_empty():
		return saved
	return "%s_exp_%s.tres" % [saved.get_basename(), active]


## EL CONTRATO CAMBIÓ (BaseSync, en cada máquina): si cambia el experimento, las perillas pasan a las suyas.
static func follow(contract: int, tree: SceneTree) -> void:
	var id := ContractsCatalog.experiment_of(contract)
	if id == active:
		return
	active = id
	for knobs in _sets():
		var into: Resource = knobs.fresh
		var path := path_for(knobs.saved)
		if ResourceLoader.exists(path):
			KnobsFile.load_into(into, path)
		else:
			KnobsFile.load_into(into, knobs.saved)
			_change(into, knobs.key)
		KnobsFile.copy(knobs.current, into)
	_applied(tree)


## Los recursos de perillas que cambia un experimento.
static func _sets() -> Array[Dictionary]:
	return [
		{"key": "dash", "current": DashSettings.current, "fresh": DashSettings.new(), "saved": DashSettings.SAVED},
		{"key": "boss", "current": BossSettings.current, "fresh": BossSettings.new(), "saved": BossSettings.SAVED},
		{"key": "brawler", "current": BrawlerSettings.current, "fresh": BrawlerSettings.new(),
			"saved": BrawlerSettings.SAVED},
	]


## LOS CAMBIOS DEL EXPERIMENTO sobre lo guardado de siempre. Los poderes: prendido, lo usa tranquilo y con ira; apagado,
## nunca (ninguno vuela: el vuelo está apagado de entrada).
static func _change(into: Resource, key: String) -> void:
	var changes: Dictionary = CHANGES.get(active, {})
	if key == "brawler":
		var powers: Dictionary = changes.get("powers", {})
		for field: String in powers:
			var power := into.get(field) as BossPower
			var on: bool = powers[field]
			power.in_calm = on
			power.in_mode_1 = on
			power.in_mode_2 = false
		return
	var values: Dictionary = changes.get(key, {})
	for knob: String in values:
		into.set(knob, values[knob])


## Lo que hay que avisar: el dash a las otras máquinas, los poderes al jefe que pelea y los paneles abiertos.
static func _applied(tree: SceneTree) -> void:
	if BaseSync.current != null:
		BaseSync.current.share_dash()
	for brawler in BrawlerArchetype.brawlers():
		var brain := brawler.get_node_or_null("Cabeza") as BrawlerBrain
		if brain != null:
			brain.refresh_powers()
	for node in tree.root.find_children("*", "", true, false):
		if node is KnobsPanel:
			(node as KnobsPanel).reload_draft()
