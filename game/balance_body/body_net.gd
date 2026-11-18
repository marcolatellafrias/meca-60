class_name BodyNet
extends Node

## ── UN CUERPO CON EQUILIBRIO POR LA RED (18/11/2026; módulo Jefes, el sistema común de movimiento) ──────────────────
## La regla acordada con el usuario (docs/technical/movimiento-comun.md, «Qué viaja por la red»): VIAJA LO QUE LA OTRA
## MÁQUINA NO PUEDE DEDUCIR. Lo físico viaja (el motor: dónde está, el rumbo, la velocidad, lo agachada, el estado y la
## caída, si levita o recoge las piernas, y las dos salidas del resorte); el esqueleto, las piernas, los pies, el
## caminar y el polvo se calculan en cada máquina con eso, igual que en la del dueño.
##   · UN DUEÑO (`authority`): el único que la simula. Por defecto el host; quien la posee con la O desde su máquina la
##     toma (`take_control`, ver MechKeys.begin). Manejada desde adentro, los controles ya viajan (los tableros:
##     ControllableInteractable) y le llegan al dueño.
##   · EL DUEÑO MANDA SU ESTADO `RATE` veces por segundo (sin garantía de llegada, en orden: uno perdido no importa).
##   · LOS DEMÁS NO SIMULAN EL MOTOR: lo ponen donde dice el dueño, `DELAY` ms atrás, entre los dos estados que lo rodean
##     (KinematicMover.follow); sin estado nuevo, siguen derecho con la última velocidad a lo más `MAX_AHEAD` s.
##   · QUIEN SE UNE no pide nada: el primer estado que le llega le dice quién es el dueño.
## *Falta: las piñas, el cañón y el escudo poseyéndola con el teclado (desde adentro ya viajan, por los controles), la
## energía, los golpes de los jefes y la muerte.*

const RATE := 20.0
const DELAY := 100.0
const MAX_AHEAD := 0.15
const BUFFER := 20

var body: BalanceBody = null
## Quién la simula (el id de su máquina).
var authority := 1
## Los estados recibidos: [{t: ms locales, s: el estado}], del más viejo al más nuevo.
var _buffer: Array = []
var _clock := 0.0
## Para las pruebas: cuántos estados mandó y cuántos recibió.
var sent := 0
var received := 0


## Si hay una sesión de red de verdad (con alguien conectado): sin ella, todo es local.
func networked() -> bool:
	var peer := multiplayer.multiplayer_peer
	return peer != null and not peer is OfflineMultiplayerPeer \
		and peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED


## Si en esta máquina la siguen (otro la simula).
func remote() -> bool:
	return networked() and authority != multiplayer.get_unique_id()


## LA TOMA esta máquina (la posee su jugador): se lo dice a todos.
func take_control() -> void:
	if not networked() or authority == multiplayer.get_unique_id():
		return
	_owner_is.rpc(multiplayer.get_unique_id())


@rpc("any_peer", "call_local", "reliable")
func _owner_is(peer: int) -> void:
	authority = peer
	_buffer.clear()


## EL DUEÑO, después de mover el motor: manda su estado cada tanto.
func send(delta: float) -> void:
	if not networked():
		return
	_clock -= delta
	if _clock > 0.0:
		return
	_clock = 1.0 / RATE
	_state.rpc(body.mover.net_state())
	sent += 1


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _state(state: Array) -> void:
	var sender := multiplayer.get_remote_sender_id()
	# Quien se une todavía no sabe quién es el dueño: se lo dice el primero que manda. Si no, sólo el dueño.
	if _buffer.is_empty() and received == 0:
		authority = sender
	elif sender != authority:
		return
	received += 1
	_buffer.append({"t": Time.get_ticks_msec(), "s": state})
	if _buffer.size() > BUFFER:
		_buffer.pop_front()


## LOS DEMÁS: el motor donde dice el dueño, `DELAY` ms atrás.
func follow(delta: float) -> void:
	if _buffer.is_empty():
		return
	var now := float(Time.get_ticks_msec()) - DELAY
	var older: Dictionary = _buffer[0]
	var newer: Dictionary = _buffer[0]
	for entry: Dictionary in _buffer:
		if float(entry["t"]) <= now:
			older = entry
		else:
			newer = entry
			break
	if newer == older:
		# Sin uno más nuevo: sigue derecho con la última velocidad, un rato.
		var ahead := clampf((now - float(older["t"])) / 1000.0, 0.0, MAX_AHEAD)
		body.mover.follow(older["s"], older["s"], 0.0, ahead, delta)
		return
	var span := maxf(float(newer["t"]) - float(older["t"]), 1.0)
	body.mover.follow(older["s"], newer["s"], clampf((now - float(older["t"])) / span, 0.0, 1.0), 0.0, delta)
