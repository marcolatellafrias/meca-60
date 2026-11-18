class_name BaseSync
extends Node

## LA SUCURSAL EN RED (ver docs/technical/flujo-de-partida.md): cuelga de la base del juego (BaseWorld) con el mismo
## nombre en todas las máquinas, así sus RPC llegan.
##   · EL ESTADO (BaseState): manda el del host. Cada vez que cambia, el host le manda a todos la foto entera; al que
##     llega, se la manda apenas se conoce. Los demás no lo tocan: sólo el capitán (el host) compra, pone y firma.
##   · LA COMPUERTA DEL TECHO: la abre el capitán («salir a la arena»), en todos.

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


## «SALIR A LA ARENA»: el capitán abre la compuerta del techo en todos.
func open_hatch() -> void:
	if multiplayer.is_server():
		_open_hatch.rpc()


@rpc("authority", "call_local", "reliable")
func _open_hatch() -> void:
	var hatch := get_tree().get_first_node_in_group(BaseLayout.GROUP)
	if hatch != null:
		var door := hatch.get_node_or_null("Compuerta") as BaseHatch
		if door != null:
			door.set_open(true)
