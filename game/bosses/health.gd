class_name Health
extends Node

## LA VIDA (13/11/2026): cuánta tiene algo y cuánta le queda. Se cuelga como hijo («Vida») del jefe o de la meca. TODO
## POR CÓDIGO: no la bajan los choques ni la física, sino quien decide que algo pegó (la cabeza de cada jefe). El usuario: «un
## sistema de vida que por ahora sea todo vía código… si toca un área de un misil, o si toca la bola cuando está yendo…
## le hace daño; bien simple por ahora». *Cambia lo que decía el diseño («no hay vida»): ahora hay vida.*

signal changed
signal died

const NODE_NAME := "Vida"

## AL MORIR, SU DUEÑO SE DESARMA (PartsRagdoll.fall_apart; 18/11/2026, el usuario: «todos… se caen con ragdoll al
## morir»). Apagado, sólo avisa (`died`).
var falls_apart := true
## Lo que tiene entera, lo que le queda y con qué le pegaron la última vez.
@export var full := 100.0
var left := 100.0
var last := ""
## CÓMO LO EMPUJÓ EL ÚLTIMO GOLPE (m/s, en el mundo): lo dice quien pega. El que mata decide hacia dónde y con cuánta
## fuerza sale el ragdoll (el usuario: «generalmente cuando revolee… va a ser porque el boss le hizo alguna habilidad que
## lo hizo revolear en una cierta dirección con un cierto impulso… se controla en base al hit»).
var push := Vector3.ZERO


## La vida de `node`, si tiene.
static func of(node: Node) -> Health:
	return node.get_node_or_null(NODE_NAME) as Health if node != null else null


## Le cuelga a `node` una vida de `amount`.
static func attach(node: Node, amount: float) -> Health:
	var made := Health.new()
	made.name = NODE_NAME
	made.full = amount
	made.left = amount
	node.add_child(made)
	return made


## LE SACA `amount` por `what`, empujándolo `with_push` (m/s; ver `push`). Ya sin vida, nada.
## POR LA RED (18/11/2026): LA VIDA LA DECIDE EL HOST. Un golpe que pasa en otra máquina (la piña de alguien que maneja
## la meca desde la suya) se le pide al host (`_ask_hurt`); el host la baja y le dice a todos cuánta queda, con qué le
## pegaron y el empujón (`_set_left`), y en todas se muere igual (con el mismo empujón para el ragdoll).
func hurt(amount: float, what: String, with_push := Vector3.ZERO) -> void:
	if dead():
		return
	if NetFollow.online(self) and not multiplayer.is_server():
		_ask_hurt.rpc_id(1, amount, what, with_push)
		return
	_change(maxf(left - amount, 0.0), what, with_push)
	if NetFollow.online(self):
		_set_left.rpc(left, what, with_push)


@rpc("any_peer", "call_remote", "reliable")
func _ask_hurt(amount: float, what: String, with_push: Vector3) -> void:
	if multiplayer.is_server():
		hurt(amount, what, with_push)


@rpc("authority", "call_remote", "reliable")
func _set_left(now: float, what: String, with_push: Vector3) -> void:
	if not dead():
		_change(now, what, with_push)


func _change(now: float, what: String, with_push: Vector3) -> void:
	left = now
	last = what
	push = with_push
	changed.emit()
	if dead():
		died.emit()
		if falls_apart and get_parent() is Node3D:
			PartsRagdoll.fall_apart.call_deferred(get_parent())


## LE DEVUELVE `amount` (un kit de reparación). Lo decide el host. Muerta, nada.
func heal(amount: float) -> void:
	if dead() or (NetFollow.online(self) and not multiplayer.is_server()):
		return
	_change(minf(left + amount, full), "reparada", Vector3.ZERO)
	if NetFollow.online(self):
		_set_left.rpc(left, last, Vector3.ZERO)


func dead() -> bool:
	return left <= 0.0


func share() -> float:
	return left / maxf(full, 0.001)
