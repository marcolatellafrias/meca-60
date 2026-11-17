class_name MechEnergy
extends Node

## LA ENERGÍA DE LA MECA, UNA SOLA PARA TODOS (ver docs/conceptual/armamento.md: «la energía es la estamina de la meca…
## coordinarse en cómo se usa es la idea básica del juego»). La gastan el movimiento (el dash, levitar), el taladro y
## el cañón. Se recarga sola un rato después del último gasto; si se vacía, LA MECA QUEDA ATURDIDA un rato: no hace
## nada hasta que se le pasa.
## *Por ahora, sólo en la meca con herramientas (ToolMech, la base de la jaula; nació en la Meca de tres). El máximo que
## baja con el uso y cambiar la batería, después.*

## Cuánto se recarga por segundo (partes del total), y cuánto espera después de un gasto para empezar (s).
const REFILL := 0.14
const REFILL_DELAY := 0.8
## Cuánto dura el aturdimiento al vaciarse (s).
const STUN := 2.5

## Cuánta queda (0 a 1).
var level := 1.0
## Cuánto le queda al aturdimiento (s; 0, no está aturdida).
var stunned := 0.0

var _since_spent := 99.0


func _physics_process(delta: float) -> void:
	stunned = maxf(stunned - delta, 0.0)
	_since_spent += delta
	if _since_spent >= REFILL_DELAY:
		level = minf(level + REFILL * delta, 1.0)


## Si puede hacer algo: no está aturdida.
func able() -> bool:
	return stunned <= 0.0


## GASTA `amount` DE UNA VEZ, si alcanza y no está aturdida. Devuelve si lo gastó.
func spend(amount: float) -> bool:
	if not able() or level < amount:
		return false
	_take(amount)
	return true


## GASTA DE A POCO (`rate` por segundo, este paso). Devuelve si todavía queda; si se vacía, se aturde.
func drain(rate: float, delta: float) -> bool:
	if not able():
		return false
	_take(rate * delta)
	return stunned <= 0.0


func _take(amount: float) -> void:
	level -= amount
	_since_spent = 0.0
	if level <= 0.001:
		level = 0.0
		stunned = STUN


## La barra para el cartel de poseerla.
func bar() -> String:
	return "aturdida %.1f s" % stunned if not able() else BodyMoves._bar(level)
