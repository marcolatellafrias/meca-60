class_name Health
extends Node

## LA VIDA (13/11/2026): cuánta tiene algo y cuánta le queda. Se cuelga como hijo («Vida») del jefe o de la meca. TODO
## POR CÓDIGO: no la bajan los choques ni la física, sino quien decide que algo pegó (la cabeza de cada jefe). El usuario: «un
## sistema de vida que por ahora sea todo vía código… si toca un área de un misil, o si toca la bola cuando está yendo…
## le hace daño; bien simple por ahora». *Cambia lo que decía el diseño («no hay vida»): ahora hay vida.*

signal changed
signal died

const NODE_NAME := "Vida"

## Lo que tiene entera, lo que le queda y con qué le pegaron la última vez.
@export var full := 100.0
var left := 100.0
var last := ""


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


## LE SACA `amount` por `what`. Ya sin vida, nada.
func hurt(amount: float, what: String) -> void:
	if dead():
		return
	left = maxf(left - amount, 0.0)
	last = what
	changed.emit()
	if dead():
		died.emit()


func dead() -> bool:
	return left <= 0.0


func share() -> float:
	return left / maxf(full, 0.001)
