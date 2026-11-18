class_name NetFollow
extends Node

## ── SEGUIR ALGO POR LA RED: LO COMÚN (18/11/2026; módulo Jefes) ──────────────────────────────────────────────────────
## Lo que comparten la meca (BodyNet) y los jefes (BossNet): UN DUEÑO lo simula y manda su estado `RATE` veces por
## segundo (sin garantía de llegada, en orden); LOS DEMÁS no lo simulan: lo ponen `DELAY` ms atrás, entre los dos
## estados que lo rodean, o derecho un rato (`MAX_AHEAD` s) si no llega nada nuevo. Qué es el estado y cómo se pone lo
## dice cada uno (`_state_now`, `_apply`). Quien se une no pide nada: el primer estado que le llega le dice quién manda.
## *El rato derecho era de 0,15 s: con un paquete atrasado en un dash (25 m/s) se iba 4 m y volvía de golpe; ahora, a
## lo más 1,2 m.*
## Ver docs/technical/movimiento-comun.md, «Qué viaja por la red».

const RATE := 20.0
const DELAY := 100.0
const MAX_AHEAD := 0.05
const BUFFER := 20

## Quién lo simula (el id de su máquina). Por defecto, el host.
var authority := 1
## Para las pruebas: cuántos estados mandó y cuántos recibió.
var sent := 0
var received := 0

## [{t: ms locales, s: el estado}], del más viejo al más nuevo.
var _buffer: Array = []
var _clock := 0.0


## Si hay una sesión de red de verdad (con alguien conectado): sin ella, todo es local.
static func online(node: Node) -> bool:
	var peer := node.multiplayer.multiplayer_peer
	return peer != null and not peer is OfflineMultiplayerPeer \
		and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


func networked() -> bool:
	return NetFollow.online(self)


## Si en esta máquina lo sigue (otro lo simula).
func remote() -> bool:
	return networked() and authority != multiplayer.get_unique_id()


## LO TOMA esta máquina: se lo dice a todos.
func take_control() -> void:
	if not networked() or authority == multiplayer.get_unique_id():
		return
	_owner_is.rpc(multiplayer.get_unique_id())


## LO PASA a `peer` (lo pide el host: ver BodyNet.borrow).
func hand_to(peer: int) -> void:
	if networked() and authority != peer:
		_owner_is.rpc(peer)


@rpc("any_peer", "call_local", "reliable")
func _owner_is(peer: int) -> void:
	authority = peer
	_buffer.clear()
	_owner_changed()


## EL DUEÑO, después de simular su paso: manda su estado cada tanto.
func send(delta: float) -> void:
	if not networked():
		return
	_clock -= delta
	if _clock > 0.0:
		return
	_clock = 1.0 / RATE
	_state.rpc(_state_now())
	sent += 1


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _state(state: Array) -> void:
	var sender := multiplayer.get_remote_sender_id()
	if received == 0 and _buffer.is_empty():
		authority = sender
	elif sender != authority:
		return
	received += 1
	_buffer.append({"t": Time.get_ticks_msec(), "s": state})
	if _buffer.size() > BUFFER:
		_buffer.pop_front()


## LOS DEMÁS: lo pone `DELAY` ms atrás. Devuelve si tenía algo para poner.
func follow(delta: float) -> bool:
	if _buffer.is_empty():
		return false
	var now := float(Time.get_ticks_msec()) - DELAY
	var older: Dictionary = _buffer[0]
	# Sin uno más nuevo que `now` (no llegó a tiempo), sigue derecho desde el último. *Arrancaba en el primero del
	# buffer, el más viejo: sin paquete nuevo a tiempo, la mezcla iba del último a ése, y saltaba 1 s para atrás.*
	var newer := {}
	for entry: Dictionary in _buffer:
		if float(entry["t"]) <= now:
			older = entry
		else:
			newer = entry
			break
	if newer.is_empty() or newer == older:
		_apply(older["s"], older["s"], 0.0, clampf((now - float(older["t"])) / 1000.0, 0.0, MAX_AHEAD), delta)
		return true
	var span := maxf(float(newer["t"]) - float(older["t"]), 1.0)
	_apply(older["s"], newer["s"], clampf((now - float(older["t"])) / span, 0.0, 1.0), 0.0, delta)
	return true


## ── LO DE CADA UNO ───────────────────────────────────────────────────────────────────────────────────────────────

## El estado que manda el dueño.
func _state_now() -> Array:
	return []


## Lo pone entre `from` y `to` (`share`), o `ahead` s después del último.
func _apply(_from: Array, _to: Array, _share: float, _ahead: float, _delta: float) -> void:
	pass


## Cambió el dueño (por si el que lo seguía tiene que volver a simularlo).
func _owner_changed() -> void:
	pass
