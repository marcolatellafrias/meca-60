class_name BaseSupplies
extends Node

## LOS PAQUETES DE LA PARTIDA (22/11/2026; ver docs/conceptual/recursos.md y docs/technical/sucursal.md). Cuelga de BaseWorld
## con el mismo nombre en todas las máquinas. MANDA EL HOST: qué paquetes hay, quién lleva cada uno y adónde fueron.
##   · LOS TUBOS (BaseSupplyTube): cuando su lugar queda vacío, cae otro al rato.
##   · AGARRAR, con la E o el clic. Con uno en las manos, la E o el clic CERCA DE LA MECA se lo pone, antes de subirse; LEJOS
##     lo deja en el piso.
##   · PONERLO: la munición reemplaza la carga de su arma; el kit devuelve vida, y con la vida llena no se gasta.

const NAME := "Suministros"
const RESPAWN := 1.1
const FIRST_DROP := 0.8
## Hasta cuántos paquetes sueltos de cada tubo puede haber: los que queden tirados no llenan la base.
const MAX_LOOSE := 4
## A cuánto del borde de la meca se le puede poner (m).
const MECH_REACH := 1.9
const DROP_AHEAD := 0.8
const NOTICE_TIME := 1.5
const NOTICE_RISE := 1.6
const HEAL_COLOR := Color(0.35, 0.95, 0.45)

static var current: BaseSupplies = null

var _crates := {}
var _tubes := {}
var _wait := {}
var _next_id := 1


func _ready() -> void:
	name = NAME
	current = self
	for node in get_tree().get_nodes_in_group(BaseSupplyTube.GROUP):
		var tube := node as BaseSupplyTube
		_tubes[tube.slot] = tube
		_wait[tube.slot] = FIRST_DROP
	multiplayer.peer_disconnected.connect(_forget)
	SessionManager.remote_player_joined.connect(_on_joined)
	multiplayer.connected_to_server.connect(_on_connected)
	if not multiplayer.is_server():
		_ask_state.call_deferred()


func _exit_tree() -> void:
	if current == self:
		current = null


func _ask_state() -> void:
	if multiplayer.multiplayer_peer != null and multiplayer.multiplayer_peer.get_connection_status() \
			== MultiplayerPeer.CONNECTION_CONNECTED:
		_want_state.rpc_id(1)


## RECIÉN CONECTADO: lo que armó solo mientras cargaba no vale; manda lo del host.
func _on_connected() -> void:
	for id: int in _crates.keys():
		_remove(id)
	_ask_state()


## ── LO QUE PIDE ESTA MÁQUINA ─────────────────────────────────────────────────────────────────────────────────────

func ask_take(id: int) -> void:
	if multiplayer.is_server():
		_do_take(multiplayer.get_unique_id(), id)
	else:
		_req_take.rpc_id(1, id)


func ask_next(slot: int) -> void:
	if multiplayer.is_server():
		_do_next(slot)
	else:
		_req_next.rpc_id(1, slot)


## LA E O EL CLIC CON UN PAQUETE EN LAS MANOS: cerca de la meca se lo pone; si no, lo deja adelante suyo.
func use_carried(bi: BoneInstantiator) -> void:
	var crate := bi.carried
	if not is_instance_valid(crate):
		return
	if _near_mech(bi):
		if multiplayer.is_server():
			_do_deliver(multiplayer.get_unique_id(), crate.id)
		else:
			_req_deliver.rpc_id(1, crate.id)
		return
	var ahead := Basis(Vector3.UP, bi.char_rigidbody.global_rotation.y) * Vector3.FORWARD
	var spot := _floor_under(bi.char_rigidbody.global_position + ahead * DROP_AHEAD, bi)
	if multiplayer.is_server():
		_do_drop(multiplayer.get_unique_id(), crate.id, spot)
	else:
		_req_drop.rpc_id(1, crate.id, spot)


func _near_mech(bi: BoneInstantiator) -> bool:
	var mech := _mech()
	if mech == null:
		return false
	var to := mech.global_position - bi.char_rigidbody.global_position
	to.y = 0.0
	return to.length() <= maxf(mech.size.x, mech.size.z) * 0.5 + MECH_REACH


## El piso debajo de `at`.
func _floor_under(at: Vector3, bi: BoneInstantiator) -> Vector3:
	var from := at + Vector3.UP * 1.0
	var query := PhysicsRayQueryParameters3D.create(from, at + Vector3.DOWN * 4.0, PhysicsLayers.FIXED)
	var hit := bi.char_rigidbody.get_world_3d().direct_space_state.intersect_ray(query)
	return hit["position"] if not hit.is_empty() else at


func _mech() -> CageMech:
	var world := get_parent()
	return world.get_node_or_null("Base/Meca jaula") as CageMech


func _character(peer: int) -> BoneInstantiator:
	var spawner := get_tree().get_first_node_in_group("character_spawner") as CharacterSpawner
	if spawner == null:
		return null
	if peer == multiplayer.get_unique_id():
		return spawner.local_player
	return spawner.remote_players.get(peer) as BoneInstantiator


## ── EN EL HOST ───────────────────────────────────────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	# TIRADO, se le cae lo que llevaba.
	var player := DesignSandbox.player_of(get_tree())
	if is_instance_valid(player) and is_instance_valid(player.carried) and player._is_ragdolling():
		var spot := _floor_under(player.char_rigidbody.global_position, player)
		if multiplayer.is_server():
			_do_drop(multiplayer.get_unique_id(), player.carried.id, spot)
		else:
			_req_drop.rpc_id(1, player.carried.id, spot)
	if not multiplayer.is_server():
		return
	for slot: int in _tubes:
		if _on_pad(slot) != null:
			continue
		_wait[slot] = float(_wait[slot]) - delta
		if float(_wait[slot]) <= 0.0 and _loose(slot) < MAX_LOOSE:
			_wait[slot] = RESPAWN
			var id := _next_id
			_next_id += 1
			_spawn.rpc(id, (_tubes[slot] as BaseSupplyTube).kind(), slot)


func _on_pad(slot: int) -> SupplyCrate:
	for crate: SupplyCrate in _crates.values():
		if crate.tube == slot and crate.on_pad:
			return crate
	return null


func _loose(slot: int) -> int:
	var count := 0
	for crate: SupplyCrate in _crates.values():
		count += 1 if crate.tube == slot else 0
	return count


func _do_take(peer: int, id: int) -> void:
	var crate := _crates.get(id) as SupplyCrate
	var who := _character(peer)
	if crate == null or crate.carrier != null or who == null or is_instance_valid(who.carried) or who.is_seated:
		return
	_wait[crate.tube] = RESPAWN
	_taken.rpc(id, peer)


func _do_next(slot: int) -> void:
	var tube := _tubes.get(slot) as BaseSupplyTube
	if tube == null or tube.kinds.size() < 2:
		return
	var fresh := (tube.index + 1) % tube.kinds.size()
	var old := _on_pad(slot)
	_wait[slot] = 0.25
	_chosen.rpc(slot, fresh, old.id if old != null else 0)


func _do_drop(peer: int, id: int, spot: Vector3) -> void:
	var crate := _crates.get(id) as SupplyCrate
	if crate != null and crate.carrier == _character(peer) and crate.carrier != null:
		_dropped.rpc(id, spot)


func _do_deliver(peer: int, id: int) -> void:
	var crate := _crates.get(id) as SupplyCrate
	var mech := _mech()
	if crate == null or mech == null or crate.carrier == null or crate.carrier != _character(peer):
		return
	if crate.kind == SupplyKinds.Kind.REPAIR:
		var life := Health.of(mech)
		if life == null or life.dead() or life.left >= life.full:
			_say.rpc_id(peer, "LA SALUD ESTÁ LLENA", mech.global_position)
			return
		life.heal(SupplyKinds.REPAIR_AMOUNT)
	_delivered.rpc(id)


func _forget(peer: int) -> void:
	if not multiplayer.is_server():
		return
	for crate: SupplyCrate in _crates.values():
		if crate.carrier != null and crate.carrier == _character(peer):
			_dropped.rpc(crate.id, crate.global_position + Vector3.DOWN * SupplyCrate.HALF)


func _on_joined(peer: int) -> void:
	if multiplayer.is_server():
		_send_state(peer)


func _send_state(peer: int) -> void:
	var list: Array = []
	for crate: SupplyCrate in _crates.values():
		list.append([crate.id, int(crate.kind), crate.tube, crate.global_position, crate.on_pad, _peer_of(crate)])
	var picks := {}
	for slot: int in _tubes:
		picks[slot] = (_tubes[slot] as BaseSupplyTube).index
	_state.rpc_id(peer, list, picks)


func _peer_of(crate: SupplyCrate) -> int:
	if crate.carrier == null:
		return 0
	var spawner := get_tree().get_first_node_in_group("character_spawner") as CharacterSpawner
	if crate.carrier == spawner.local_player:
		return multiplayer.get_unique_id()
	for peer: int in spawner.remote_players:
		if spawner.remote_players[peer] == crate.carrier:
			return peer
	return 0


@rpc("any_peer", "call_remote", "reliable")
func _want_state() -> void:
	if multiplayer.is_server():
		_send_state(multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func _req_take(id: int) -> void:
	if multiplayer.is_server():
		_do_take(multiplayer.get_remote_sender_id(), id)


@rpc("any_peer", "call_remote", "reliable")
func _req_next(slot: int) -> void:
	if multiplayer.is_server():
		_do_next(slot)


@rpc("any_peer", "call_remote", "reliable")
func _req_drop(id: int, spot: Vector3) -> void:
	if multiplayer.is_server():
		_do_drop(multiplayer.get_remote_sender_id(), id, spot)


@rpc("any_peer", "call_remote", "reliable")
func _req_deliver(id: int) -> void:
	if multiplayer.is_server():
		_do_deliver(multiplayer.get_remote_sender_id(), id)


## ── EN TODAS LAS MÁQUINAS ────────────────────────────────────────────────────────────────────────────────────────

@rpc("authority", "call_local", "reliable")
func _spawn(id: int, kind: int, slot: int) -> void:
	var tube := _tubes.get(slot) as BaseSupplyTube
	if tube == null or _crates.has(id):
		return
	_next_id = maxi(_next_id, id + 1)
	var crate := _make(id, kind, slot, tube.mouth(), tube.pad())
	crate.on_pad = true


func _make(id: int, kind: int, slot: int, at: Vector3, to: Vector3) -> SupplyCrate:
	var crate := SupplyCrate.new()
	add_child(crate)
	crate.tube = slot
	crate.setup(id, kind, at, to)
	_crates[id] = crate
	return crate


@rpc("authority", "call_remote", "reliable")
func _state(list: Array, picks: Dictionary) -> void:
	for slot: int in picks:
		var tube := _tubes.get(slot) as BaseSupplyTube
		if tube != null:
			tube.index = int(picks[slot])
			tube.show_kind()
	for entry: Array in list:
		if _crates.has(int(entry[0])):
			continue
		var at: Vector3 = entry[3]
		var floor_at := at + Vector3.DOWN * SupplyCrate.HALF
		var crate := _make(int(entry[0]), int(entry[1]), int(entry[2]), floor_at + Vector3.UP * SupplyCrate.HALF, floor_at)
		crate.on_pad = bool(entry[4])
		if int(entry[5]) != 0:
			var who := _character(int(entry[5]))
			if who != null:
				crate.held_by(who)


@rpc("authority", "call_local", "reliable")
func _taken(id: int, peer: int) -> void:
	var crate := _crates.get(id) as SupplyCrate
	var who := _character(peer)
	if crate != null and who != null:
		crate.held_by(who)


@rpc("authority", "call_local", "reliable")
func _chosen(slot: int, index: int, old: int) -> void:
	var tube := _tubes.get(slot) as BaseSupplyTube
	if tube != null:
		tube.index = index
		tube.show_kind()
	if old != 0:
		_remove(old)


@rpc("authority", "call_local", "reliable")
func _dropped(id: int, spot: Vector3) -> void:
	var crate := _crates.get(id) as SupplyCrate
	if crate == null:
		return
	_let_go(crate)
	crate.land_at(spot, false)


@rpc("authority", "call_local", "reliable")
func _delivered(id: int) -> void:
	var crate := _crates.get(id) as SupplyCrate
	var mech := _mech()
	if crate == null:
		return
	var kind := int(crate.kind)
	_remove(id)
	if mech == null:
		return
	if SupplyKinds.is_bullets(kind) or SupplyKinds.is_missiles(kind):
		mech.guns.weapons.load_supply(kind)
	EnergyBolt.flash(mech.get_parent(), mech.global_position, 2.2,
		HEAL_COLOR if kind == SupplyKinds.Kind.REPAIR else SupplyKinds.tag_color(kind))
	_notice(("+%d DE SALUD" % roundi(SupplyKinds.REPAIR_AMOUNT)) if kind == SupplyKinds.Kind.REPAIR else SupplyKinds.title(kind),
		mech.global_position, HEAL_COLOR if kind == SupplyKinds.Kind.REPAIR else SupplyKinds.tag_color(kind).lightened(0.3))


@rpc("authority", "call_local", "reliable")
func _say(text: String, at: Vector3) -> void:
	_notice(text, at, Color(1.0, 0.85, 0.5))


func _remove(id: int) -> void:
	var crate := _crates.get(id) as SupplyCrate
	if crate == null:
		return
	_let_go(crate)
	_crates.erase(id)
	crate.queue_free()


func _let_go(crate: SupplyCrate) -> void:
	if crate.carrier != null and is_instance_valid(crate.carrier):
		crate.carrier.carried = null
	crate.carrier = null


## UN CARTELITO que sube y se apaga.
func _notice(text: String, at: Vector3, tint: Color) -> void:
	var label := Label3D.new()
	label.text = text
	label.font_size = 52
	label.pixel_size = 0.008
	label.modulate = tint
	label.outline_size = 12
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.top_level = true
	add_child(label)
	label.global_position = at + Vector3.UP * 3.2
	var move := label.create_tween()
	move.set_parallel(true)
	move.tween_property(label, "global_position:y", label.global_position.y + NOTICE_RISE, NOTICE_TIME)
	move.tween_property(label, "modulate:a", 0.0, NOTICE_TIME).set_delay(NOTICE_TIME * 0.4)
	move.chain().tween_callback(label.queue_free)
