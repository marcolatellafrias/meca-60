class_name BaseSync
extends Node

## LA SUCURSAL EN RED (ver docs/technical/flujo-de-partida.md): cuelga de la base del juego (BaseWorld) con el mismo
## nombre en todas las máquinas, así sus RPC llegan.
##   · EL ESTADO (BaseState): manda el del host. Cada vez que cambia, el host le manda a todos la foto entera; al que
##     llega, se la manda apenas se conoce. Los demás no lo tocan: sólo el capitán (el host) compra, pone y firma.
##   · EL ASCENSOR A LA ARENA (`launch`): lo arranca el capitán desde el botón de la plataforma, en todos.
##   · EL EXPERIMENTO DEL CONTRATO (Experiments): cada máquina lo aplica al cambiar el contrato, después de mandar la foto
##     (así, en las otras, el dash que reparte el host llega después y manda).

const NAME := "Sucursal"
const TEST_DAMAGE := 30.0

static var current: BaseSync

var _restarting := false


func _ready() -> void:
	name = NAME
	current = self
	BaseState.current.changed.connect(_on_changed)
	BaseState.current.changed.connect(_on_contract)
	SessionManager.remote_player_joined.connect(_on_player_joined)
	_on_contract.call_deferred()


func _exit_tree() -> void:
	if current == self:
		current = null
	if BaseState.current.changed.is_connected(_on_changed):
		BaseState.current.changed.disconnect(_on_changed)
	if BaseState.current.changed.is_connected(_on_contract):
		BaseState.current.changed.disconnect(_on_contract)


func _on_changed() -> void:
	if multiplayer.is_server() and multiplayer.get_peers().size() > 0:
		_receive.rpc(BaseState.current.snapshot())


func _on_contract() -> void:
	Experiments.follow(BaseState.current.contract, get_tree())


func _on_player_joined(peer_id: int) -> void:
	if multiplayer.is_server():
		_receive.rpc_id(peer_id, BaseState.current.snapshot())
		_equip.rpc_id(peer_id, _equipment())
		_dash.rpc_id(peer_id, DashSettings.current.values())
		_match.rpc_id(peer_id, MatchSettings.current.values())


@rpc("authority", "reliable")
func _receive(data: Dictionary) -> void:
	# la foto del host: se carga sin volver a mandarla (el que no es host no manda)
	BaseState.current.load_snapshot(data)




## EL ASCENSOR A LA ARENA (BaseElevator, el paso 7): el capitán aprieta el botón de la plataforma; el host mira que se
## pueda (contrato firmado y todos arriba) y lo arranca en todos. El pedido de otro no hace nada (como la esclusa).
func launch() -> void:
	if multiplayer.is_server():
		var elevator := _elevator()
		if elevator != null and elevator.can_launch():
			_launch.rpc()
	else:
		_request_launch.rpc_id(1)


@rpc("any_peer", "reliable")
func _request_launch() -> void:
	# sólo el capitán, que es el host: el pedido de otro se ignora
	pass


@rpc("authority", "call_local", "reliable")
func _launch() -> void:
	var elevator := _elevator()
	if elevator != null:
		elevator.launch()


## Si el ascensor ya arrancó.
func launched() -> bool:
	var elevator := _elevator()
	return elevator != null and elevator.launched


## EL EQUIPO DE LA MECA (BaseEquipmentPanel): lo cambia el capitán, y la meca se rearma con él en todas las máquinas.
func equip() -> void:
	if multiplayer.is_server():
		_equip.rpc(_equipment())


func _equipment() -> Array:
	var now := MechLoadout.current(CageMechArchetype.ROW, CageMech.default_arms())
	return [now.left_tip, now.left_plate, now.right_tip, now.right_plate]


@rpc("authority", "call_local", "reliable")
func _equip(values: Array) -> void:
	var now := MechLoadout.current(CageMechArchetype.ROW, CageMech.default_arms())
	now.left_tip = int(values[0])
	now.left_plate = bool(values[1])
	now.right_tip = int(values[2])
	now.right_plate = bool(values[3])
	Mech.rebuild_all(get_tree())


## CÓMO ES EL DASH (BaseDashPanel): lo cambia el capitán, para todas las máquinas.
func share_dash() -> void:
	if multiplayer.is_server() and multiplayer.get_peers().size() > 0:
		_dash.rpc(DashSettings.current.values())


@rpc("authority", "reliable")
func _dash(values: Dictionary) -> void:
	DashSettings.current.load_values(values)


## LOS AJUSTES DE LA PARTIDA (BaseMatchPanel): los cambia el capitán, para todas las máquinas.
func share_match() -> void:
	if multiplayer.is_server() and multiplayer.get_peers().size() > 0:
		_match.rpc(MatchSettings.current.values())


@rpc("authority", "reliable")
func _match(values: Dictionary) -> void:
	MatchSettings.current.load_values(values)


## DAÑAR LA MECA (el botón del F6, para probar el kit de reparación en la base): nunca la mata.
func hurt_mech() -> void:
	if multiplayer.is_server():
		_hurt_mech.rpc()


@rpc("authority", "call_local", "reliable")
func _hurt_mech() -> void:
	var holder := get_tree().get_first_node_in_group(BaseWorld.GROUP)
	var mech := holder.get_node_or_null("Base/Meca jaula") as Mech if holder != null else null
	if mech == null:
		return
	var life := Health.of(mech)
	if life == null:
		life = Health.attach(mech, BaseWorld.MECH_HEALTH)
	if multiplayer.is_server():
		life.hurt(minf(TEST_DAMAGE, life.left - 1.0), "prueba")


## REINICIAR (el F6 del capitán): todas las máquinas vuelven a armar la base, con la misma sesión, el mismo contrato y el
## mismo equipo. Vuelve a la esclusa, así que hasta abrirla se puede unir alguien.
func restart() -> void:
	if multiplayer.is_server() and not _restarting:
		_restart.rpc()


@rpc("authority", "call_local", "reliable")
func _restart() -> void:
	if _restarting:
		return
	_restarting = true
	SessionManager.reopen_to_new_players()
	CageShape.crew = 2
	get_tree().reload_current_scene.call_deferred()


func _elevator() -> BaseElevator:
	var holder := get_tree().get_first_node_in_group(BaseLayout.GROUP)
	return holder.get_node_or_null("Ascensor") as BaseElevator if holder != null else null
