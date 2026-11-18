class_name BaseSync
extends Node

## LA SUCURSAL EN RED (ver docs/technical/flujo-de-partida.md): cuelga de la base del juego (BaseWorld) con el mismo
## nombre en todas las máquinas, así sus RPC llegan.
##   · EL ESTADO (BaseState): manda el del host. Cada vez que cambia, el host le manda a todos la foto entera; al que
##     llega, se la manda apenas se conoce. Los demás no lo tocan: sólo el capitán (el host) compra, pone y firma.
##   · EL ASCENSOR A LA ARENA (`launch`): lo arranca el capitán desde el botón de la plataforma, en todos.

const NAME := "Sucursal"

static var current: BaseSync


func _ready() -> void:
	name = NAME
	current = self
	BaseState.current.changed.connect(_on_changed)
	SessionManager.remote_player_joined.connect(_on_player_joined)


func _exit_tree() -> void:
	if current == self:
		current = null
	if BaseState.current.changed.is_connected(_on_changed):
		BaseState.current.changed.disconnect(_on_changed)


func _on_changed() -> void:
	if multiplayer.is_server() and multiplayer.get_peers().size() > 0:
		_receive.rpc(BaseState.current.snapshot())


func _on_player_joined(peer_id: int) -> void:
	if multiplayer.is_server():
		_receive.rpc_id(peer_id, BaseState.current.snapshot())


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


func _elevator() -> BaseElevator:
	var holder := get_tree().get_first_node_in_group(BaseLayout.GROUP)
	return holder.get_node_or_null("Ascensor") as BaseElevator if holder != null else null
