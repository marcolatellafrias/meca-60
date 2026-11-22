class_name MechCrew
extends Node

## LAS TECLAS COMPARTIDAS DE LA MECA (22/11/2026; el usuario: «si varios jugadores quieren tocar la misma tecla, como que
## se bloquea. Entonces eso promueve la comunicación y la sincronización»). Todos los que van arriba pueden tocar todas:
##   · WASD la mueve según la pantalla, y las piernas siguen apuntando al frente de la meca.
##   · LAS FLECHAS giran ese frente, así el que apunta no depende del que camina.
##   · UNA TECLA APRETADA POR DOS O MÁS NO ANDA PARA NADIE, hasta que quede uno solo.
## La cuenta la lleva el host y se la dice a todos. Lo que resulta se escribe en MechCockpit, como los tableros.

const SLOTS: Array[Dictionary] = [
	{"key": KEY_W, "text": "W", "cell": Vector2i(1, 0), "tip": "mover hacia arriba de la pantalla"},
	{"key": KEY_A, "text": "A", "cell": Vector2i(0, 1), "tip": "mover hacia la izquierda de la pantalla"},
	{"key": KEY_S, "text": "S", "cell": Vector2i(1, 1), "tip": "mover hacia abajo de la pantalla"},
	{"key": KEY_D, "text": "D", "cell": Vector2i(2, 1), "tip": "mover hacia la derecha de la pantalla"},
	{"key": KEY_LEFT, "text": "←", "cell": Vector2i(4, 1), "tip": "girar el frente de la meca a la izquierda"},
	{"key": KEY_RIGHT, "text": "→", "cell": Vector2i(5, 1), "tip": "girar el frente de la meca a la derecha"},
]
const W := 0
const A := 1
const S := 2
const D := 3
const LEFT := 4
const RIGHT := 5

var mech: CageMech = null
## Cuántos aprietan cada tecla (en el orden de SLOTS).
var counts := PackedByteArray([0, 0, 0, 0, 0, 0])

## Lo que aprieta esta máquina (un bit por tecla).
var _mine := 0
## En el host: lo que aprieta cada máquina.
var _held := {}
var _in_use := false
var _turning := false


func _ready() -> void:
	name = "Tripulacion"
	multiplayer.peer_disconnected.connect(_forget)
	var hud := MechCrewHud.new()
	hud.crew = self
	add_child(hud)


## Si la tecla `slot` anda: la aprieta exactamente uno.
func works(slot: int) -> bool:
	return counts[slot] == 1


## SI EL JUGADOR DE ESTA MÁQUINA VA ARRIBA, con la cámara isométrica.
func local_aboard() -> bool:
	var player := DesignSandbox.player_of(get_tree())
	if not is_instance_valid(player) or not player.is_seated or not is_instance_valid(player.player_controller):
		return false
	if not is_instance_valid(player.player_controller.iso_view) or mech.cabin == null:
		return false
	return mech.cabin.chairs.has(player.current_seat)


## CADA PASO, ANTES DE QUE LA MECA LEA LO QUE SE LE PIDE (ver CageMechKeys.read).
func apply() -> void:
	_read_mine()
	var used := false
	for count in counts:
		used = used or count > 0
	# Soltaron todo: un paso más, para dejar la meca sin pedidos. Después los tableros quedan libres.
	if used or _in_use:
		_write()
	_in_use = used


func _read_mine() -> void:
	var bits := 0
	if local_aboard() and UIState.gameplay_active():
		for slot in SLOTS.size():
			if Input.is_physical_key_pressed(SLOTS[slot]["key"]):
				bits |= 1 << slot
	if bits == _mine:
		return
	_mine = bits
	if multiplayer.is_server():
		_store(multiplayer.get_unique_id(), bits)
	else:
		_report.rpc_id(1, bits)


func _write() -> void:
	if mech.legs != null:
		mech.legs.pivot_feet = true
	var cockpit := (mech.keys as ToolMechKeys).cockpit
	var screen := Vector2(_on(D) - _on(A), _on(W) - _on(S))
	# La pantalla, en los ejes del torso, que es como la meca entiende `move`.
	var local := Basis(Vector3.UP, -mech.yaw()) * IsoSettings.current.screen_to_world(screen)
	cockpit.move = Vector2(local.x, -local.z).limit_length(1.0)
	var turn := _on(LEFT) - _on(RIGHT)
	if turn != 0.0:
		mech.aim_yaw = mech.yaw() + turn * BalanceBody.AIM_LEAD
	elif _turning:
		mech.aim_yaw = mech.yaw()
	_turning = turn != 0.0


func _on(slot: int) -> float:
	return 1.0 if works(slot) else 0.0


@rpc("any_peer", "call_remote", "reliable")
func _report(bits: int) -> void:
	if multiplayer.is_server():
		_store(multiplayer.get_remote_sender_id(), bits)


func _forget(peer: int) -> void:
	if multiplayer.is_server() and _held.has(peer):
		_store(peer, 0)


## EN EL HOST: lo que aprieta `peer`, y la cuenta nueva para todos.
func _store(peer: int, bits: int) -> void:
	_held[peer] = bits
	var fresh := PackedByteArray([0, 0, 0, 0, 0, 0])
	for held: int in _held.values():
		for slot in SLOTS.size():
			if held & (1 << slot):
				fresh[slot] += 1
	if fresh == counts:
		return
	if NetFollow.online(self):
		_show.rpc(fresh)
	else:
		counts = fresh


@rpc("authority", "call_local", "reliable")
func _show(fresh: PackedByteArray) -> void:
	counts = fresh
