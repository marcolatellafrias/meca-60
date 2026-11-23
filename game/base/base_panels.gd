class_name BasePanels
extends Node

## LAS TECLAS F DE LA PARTIDA (22/11/2026; el usuario: «tener teclas F en las que puedo cambiar el armamento de la meca,
## otra… en la que puedo firmar el contrato»; «que abras la UI que ya tenemos… así no duplicamos código»). No hay pantallas
## nuevas: abren las de siempre, y sólo hasta que arranca el ascensor.
##   · F1, EL EQUIPO DE LA MECA: el panel del sandbox (BaseEquipmentPanel). Lo usa el capitán.
##   · F2, LOS CONTRATOS: la pantalla de la consola. Salir a la arena sigue siendo el botón del ascensor.
##   · F3, EL DASH (BaseDashPanel): su estilo y sus números. Éste sigue andando en la arena.
##   · F4, LOS GOLPES (BaseHitPanel): el daño, el quiebre y el empuje de cada arma, y el aguante de la bolsa.
##   · F5, EL JEFE (BrawlerPanel, el F1 de su fila; 22/11/2026): sus poderes y sus perillas, para ajustar los
##     experimentos (Experiments). También en la arena.
##   · F6, LA PARTIDA (BaseMatchPanel): los controles, el zoom y reiniciar. También en la arena.

const EQUIPMENT_KEY := KEY_F1
const CONTRACTS_KEY := KEY_F2
const DASH_KEY := KEY_F3
const HITS_KEY := KEY_F4
const BOSS_KEY := KEY_F5
const MATCH_KEY := KEY_F6

var equipment: BaseEquipmentPanel = null
var dash: BaseDashPanel = null
var hits: BaseHitPanel = null
var boss: BrawlerPanel = null
var game: BaseMatchPanel = null


func _ready() -> void:
	name = "PanelesF"
	equipment = BaseEquipmentPanel.new()
	equipment.menu_key = EQUIPMENT_KEY
	add_child(equipment)
	equipment.side = TunerPanel.SIDE_LEFT
	equipment.setup_panel()
	dash = BaseDashPanel.new()
	dash.menu_key = DASH_KEY
	add_child(dash)
	dash.side = TunerPanel.SIDE_LEFT
	dash.setup_panel()
	hits = BaseHitPanel.new()
	hits.menu_key = HITS_KEY
	add_child(hits)
	hits.side = TunerPanel.SIDE_LEFT
	hits.setup_panel()
	boss = BrawlerPanel.new()
	boss.menu_key = BOSS_KEY
	add_child(boss)
	boss.side = TunerPanel.SIDE_LEFT
	boss.setup_panel()
	game = BaseMatchPanel.new()
	game.menu_key = MATCH_KEY
	add_child(game)
	game.side = TunerPanel.SIDE_LEFT
	game.setup_panel()


func _exit_tree() -> void:
	if is_instance_valid(equipment):
		UIState.close(equipment._ui_key)
	if is_instance_valid(dash):
		UIState.close(dash._ui_key)
	if is_instance_valid(hits):
		UIState.close(hits._ui_key)
	if is_instance_valid(boss):
		UIState.close(boss._ui_key)
	if is_instance_valid(game):
		UIState.close(game._ui_key)


func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo or key.keycode != CONTRACTS_KEY:
		return
	if TerminalScreen.opened is ContractsScreen:
		TerminalScreen.opened.close()
	elif BasePanels.before_launch() and UIState.gameplay_active():
		TerminalScreen.open_screen(ContractsScreen.new(), get_tree())
	else:
		return
	get_viewport().set_input_as_handled()


## Si el ascensor todavía no arrancó: después, el equipo y el contrato ya no se cambian.
static func before_launch() -> bool:
	return BaseSync.current != null and not BaseSync.current.launched()
