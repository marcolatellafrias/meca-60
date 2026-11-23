class_name MechEnergy
extends Node

## LA ENERGÍA DE LA MECA, UNA SOLA PARA TODOS (ver docs/conceptual/armamento.md: «la energía es la estamina de la meca…
## coordinarse en cómo se usa es la idea básica del juego»). La gastan el movimiento (el dash, levitar), el taladro y
## el cañón. Se recarga sola un rato después del último gasto.
## UNA SOLA REGLA (22/11/2026; el usuario: «el stun no debería ser cuando llega a cero, sino cuando llega a negativo»):
##   · EN CERO, sólo no hay energía: lo que la gasta (el dash, lo que gira) no anda.
##   · EN NEGATIVO, STUN: sólo se llega cargando el cañón de más, y el stun viene al disparar (ver `settle`).
## *Por ahora, sólo en la meca con herramientas (ToolMech, la base de la jaula; nació en la Meca de tres). El máximo que
## baja con el uso y cambiar la batería, después.*

## LA CAPACIDAD Y LA RECARGA SON PERILLAS (F3, DashSettings; 22/11/2026; el usuario: «que tenga más energía la nave, pero que
## se regenere un poco más lento… parecido al de la maná»). LOS COSTOS SON ABSOLUTOS: un súper cuesta lo mismo en cualquier
## batería, así que una más grande rinde más. En el código, 1,0 de `level` son `UNIT` de energía de las perillas.
const UNIT := 100.0
## Cuánto espera después de un gasto para empezar a recargar (s).
const REFILL_DELAY := 0.8

## Cuánta queda (hasta `capacity`). Puede quedar EN NEGATIVO si el cañón se carga de más (ver `overdraw`).
var level := 1.0
## Cuánto le queda al aturdimiento (s; 0, no está aturdida).
var stunned := 0.0

var _since_spent := 99.0
var _capacity_was := 1.0


func _ready() -> void:
	_capacity_was = capacity()
	level = _capacity_was


## Lo que entra en la batería (en las unidades de `level`).
static func capacity() -> float:
	return DashSettings.current.energy_capacity / UNIT


## Cuánto de la barra está lleno (0 a 1), para dibujarla.
func share() -> float:
	return clampf(level / capacity(), 0.0, 1.0)


## Lo que se debe, como parte de la barra (0 a 1; 0, nada), para dibujarlo en rojo.
func debt_share() -> float:
	return clampf(-level / capacity(), 0.0, 1.0)


func _physics_process(delta: float) -> void:
	# SI CAMBIÓ LA CAPACIDAD en el F3, la barra sigue igual de llena.
	var room := capacity()
	if not is_equal_approx(room, _capacity_was):
		if level > 0.0:
			level *= room / _capacity_was
		_capacity_was = room
	stunned = maxf(stunned - delta, 0.0)
	_since_spent += delta
	if _since_spent >= REFILL_DELAY:
		level = minf(level + DashSettings.current.energy_refill / UNIT * delta, room)


## Si puede hacer algo: no está aturdida.
func able() -> bool:
	return stunned <= 0.0


## GASTA `amount` DE UNA VEZ, si alcanza y no está aturdida. Devuelve si lo gastó.
func spend(amount: float) -> bool:
	if not able() or level < amount:
		return false
	_take(amount)
	return true


## GASTA DE A POCO (`rate` por segundo, este paso). Devuelve si todavía queda.
func drain(rate: float, delta: float) -> bool:
	if not able() or level <= 0.0:
		return false
	_take(rate * delta)
	return level > 0.0


## Lo normal nunca baja de cero.
func _take(amount: float) -> void:
	level = maxf(level - amount, 0.0)
	_since_spent = 0.0


## GASTA AUNQUE NO ALCANCE (la carga del cañón): puede bajar de cero, y el stun llega recién con `settle`.
func overdraw(amount: float) -> void:
	level -= amount
	_since_spent = 0.0


## Mientras se sostiene una carga no se recarga: si no, mantenerla a tope llenaría la batería.
func pause_refill() -> void:
	_since_spent = 0.0


## SE DISPARÓ LO CARGADO: si quedó en negativo, el mini stun (si está prendido en el F3 de la partida).
func settle() -> void:
	_since_spent = 0.0
	if level < 0.0 and DashSettings.current.stun_on:
		stun(DashSettings.current.stun_time)


## LA ATURDE `seconds` (se queda con lo más largo). Lo que se ve, en MechStun; desde afuera se pide por `MechStun.hit`.
func stun(seconds: float) -> void:
	stunned = maxf(stunned, seconds)


## La barra para el cartel de poseerla.
func bar() -> String:
	return "aturdida %.1f s" % stunned if not able() else Mech.bar(share())
