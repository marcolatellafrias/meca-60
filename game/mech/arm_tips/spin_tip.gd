class_name SpinTip
extends ArmTip

## LO QUE GIRA EN LA PUNTA (el taladro, DrillTip; la sierra, SawTip), en vez de la mano (el usuario, 15/11/2026, del
## taladro: «con el clic derecho… lo cargas y con el otro clic… lo usas, porque no lo puedes usar de una porque tarda en
## agarrar velocidad… su propia barra, y mientras más tiempo lo cargas… más energía gasta»; y el 16/11/2026, la sierra
## también):
##   · CARGAR (`charging`, mantenido): toma velocidad (`spin`, de 0 a 1, en SPIN_UP) y gasta energía de a poco, más
##     cuanto más rápido gira. Suelto, se va frenando solo.
##   · DESCARGAR (`strike`): un directo al frente, sin apuntar. En un brazo discreto, lo que toca recibe el impulso de la
##     piña por lo que giraba al tirarlo (`hit`); en uno con músculos, pega como pega el brazo. Después de pegar, gira
##     mucho menos.
## *Era DrillArm, un brazo discreto con la mecha en vez de mano, hasta el 16/11/2026.*

## En cuánto llega a girar a fondo cargando, y en cuánto se frena solo (s).
const SPIN_UP := 1.4
const SPIN_DOWN := 3.0
## Lo que gasta cargando (por segundo): lo de base, más lo que crece con lo que gira. Y lo que gasta el golpe.
const CHARGE_COST := 0.06
const SPIN_COST := 0.3
const STRIKE_COST := 0.04
## Lo mínimo que tiene que girar para pegar, y por cuánto multiplica el empujón del directo, de quieto a fondo.
const MIN_SPIN := 0.15
const PUSH_STILL := 0.4
const PUSH_FULL := 2.6
## Cuántas vueltas por segundo da a fondo (sólo se ve).
const TURNS := 9.0

## Lo pide quien la maneja: cargando o no.
var charging := false
## Cuánto gira (0 a 1).
var spin := 0.0

## Lo que gira (lo arma cada una) y sobre qué eje suyo.
var _spinner: Node3D = null
var _axis := Vector3.UP
## Lo que giraba al tirar el golpe de ahora.
var _strike_spin := 0.0


func step(delta: float) -> void:
	if charging and energy != null and energy.drain(CHARGE_COST + SPIN_COST * spin, delta):
		spin = minf(spin + delta / SPIN_UP, 1.0)
	else:
		charging = false
		spin = maxf(spin - delta / SPIN_DOWN, 0.0)
	if _spinner != null:
		_spinner.rotate_object_local(_axis, spin * TURNS * TAU * delta)


## DESCARGA: el directo, si gira lo suficiente y alcanza la energía. Devuelve si lo tiró.
func strike() -> bool:
	if arm.punching != MechArm.Punch.NONE or spin < MIN_SPIN or energy == null or not energy.spend(STRIKE_COST):
		return false
	_strike_spin = spin
	if not arm.punch(MechArm.Punch.STRAIGHT):
		return false
	spin *= 0.3
	return true


func hit(body: RigidBody3D, at: Vector3, velocity: Vector3) -> bool:
	var push := lerpf(PUSH_STILL, PUSH_FULL, _strike_spin)
	EnergyBolt.lands(body, velocity * StrikeSettings.current.hit_mass * push, at, _hit_name())
	return true


## El nombre del golpe (ver EnergyBolt.lands).
func _hit_name() -> String:
	return "taladro"


func status() -> String:
	return "%s %s" % [_hit_name(), BodyMoves._bar(spin)]
