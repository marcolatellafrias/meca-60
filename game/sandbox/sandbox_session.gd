class_name SandboxSession
extends Node

## LA SESIÓN DE RED EN EL SANDBOX (ver MultiplayerArchetype, la fila Multijugador). Sin sesión no hace nada: el sandbox
## es de uno, con su ente. Cuando la sesión arranca —se abra acá o se una uno—, el ente se va y los personajes los pone el
## CharacterSpawner del juego (el local y los de los demás, con su CharacterNetSync), colgados de `chars`: el mismo path
## en todas las máquinas, así los pedidos de red llegan. El anfitrión crea lo de la parcela con NetSpawner (quien se une
## lo recibe en la foto del mundo). Al salir se borra todo eso y vuelve el ente.
##
## TRAÍDO DE CHARACTER-PARAMETRIC el 11/11/2026, sin la nave compartida de allá (ShipBuilder.for_crew). Las mecas
## todavía no van por red: cada uno ve las suyas.

const GROUP := "net_world"
const CHARS := "chars"

var sandbox: Node3D = null
var _spawner: CharacterSpawner = null
var _chars: Node3D = null


static func find(tree: SceneTree) -> SandboxSession:
	return tree.get_first_node_in_group(GROUP) as SandboxSession


## Una línea para el panel de la parcela: en qué está la sesión.
static func status_line() -> String:
	if not SessionManager.session_started:
		return "sin sesión"
	var role := "anfitrión" if SessionManager.is_host else "unido"
	var transport := "esta compu" if SessionManager.is_local_transport else "Steam"
	return "sesión: %s por %s · %d jugador(es)" % [role, transport, SessionManager.players.size()]


func _ready() -> void:
	add_to_group(GROUP)
	SessionManager.session_ready.connect(_on_session_ready)
	if SessionManager.session_started:
		_on_session_ready.call_deferred(SessionManager.local_peer_id)
	# Quien se une por la línea de comandos (--join-local) espera el mundo antes de conectarse: es este.
	SessionManager.world_ready.call_deferred()


## DÓNDE APARECE UN PERSONAJE (ver CharacterSpawner.spawn_point): en la parcela Multijugador.
func start_point() -> Vector3:
	var parcel := _parcel()
	return parcel.global_transform * MultiplayerArchetype.START if parcel != null else Vector3.ZERO


func active() -> bool:
	return is_instance_valid(_spawner)


func _process(_delta: float) -> void:
	# El local lo pone el spawner, y lo rearma si cambia su id: el sandbox sigue siempre al de ahora.
	if active() and is_instance_valid(_spawner.local_player) and sandbox.local_player != _spawner.local_player:
		sandbox.call("net_adopt", _spawner.local_player)


func _on_session_ready(_peer_id: int) -> void:
	if active():
		return
	sandbox.call("net_release")
	_chars = Node3D.new()
	_chars.name = CHARS
	sandbox.add_child(_chars)
	_spawner = CharacterSpawner.new()
	_spawner.name = "CharacterSpawner"
	_spawner.characters_root = _chars
	_spawner.debug_local = false
	sandbox.add_child(_spawner)
	if SessionManager.is_host:
		_spawn_objects()


func _spawn_objects() -> void:
	var parcel := _parcel()
	if parcel == null:
		return
	for entry: Array in MultiplayerArchetype.OBJECTS:
		NetSpawner.host_spawn(entry[0], parcel.global_transform * Transform3D(Basis(), entry[1]))


## SALIR (la L): se deja la sesión, se borra lo compartido y vuelve el ente.
func leave() -> void:
	if not SessionManager.session_started and not active():
		return
	SessionManager.leave_session()
	NetSpawner.request_clear_all()
	for node in [_spawner, _chars]:
		if is_instance_valid(node):
			node.get_parent().remove_child(node)
			node.queue_free()
	_spawner = null
	_chars = null
	sandbox.call("net_release")
	sandbox.call("respawn_ente")


func _parcel() -> SandboxParcel:
	for node in sandbox.find_children("*", "SandboxParcel", true, false):
		var parcel := node as SandboxParcel
		if parcel.archetype is MultiplayerArchetype:
			return parcel
	return null
