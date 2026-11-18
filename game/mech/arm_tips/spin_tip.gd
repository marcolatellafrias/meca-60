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
## Hasta dónde llega lo que gira, en el antebrazo (ver `_far`; 0, sin medir).
var _reach_z := 0.0


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
	MechSounds.hit(arm, MechSounds.SPIN_STRIKE, forearm, 0.8 + 0.4 * spin)
	spin *= 0.3
	return true


func hit(body: RigidBody3D, at: Vector3, velocity: Vector3) -> bool:
	var push := lerpf(PUSH_STILL, PUSH_FULL, _strike_spin)
	EnergyBolt.lands(body, velocity * StrikeSettings.current.hit_mass * push, at, _hit_name())
	return true


## LO QUE GOLPEA: además del puño, lo que gira, a lo largo del antebrazo hasta su punta más lejana (la del cono del
## taladro, el borde del disco de la sierra). *Hasta el 18/11/2026 golpeaba sólo el puño, que en éstas va adentro de la
## boca: la mecha y el disco atravesaban lo que tocaban sin pegarle.*
func strike_points() -> PackedVector3Array:
	var points := super()
	var start := -arm.forearm_length() * 0.5
	var far := _far()
	var count := maxi(int(ceil((start - far) / maxf(arm.strike_radius(), 0.05))), 1)
	for i in count + 1:
		points.append(forearm.global_transform * Vector3(0.0, 0.0, lerpf(start, far, float(i) / count)))
	return points


## HASTA DÓNDE LLEGA LO QUE GIRA, en el antebrazo (su −z): lo más adelante de sus mallas, medido una vez armado.
func _far() -> float:
	if _reach_z < 0.0:
		return _reach_z
	var start := -arm.forearm_length() * 0.5
	if _spinner == null or not _spinner.is_inside_tree():
		return start
	var into := forearm.global_transform.affine_inverse()
	var far := start
	for found in _spinner.find_children("*", "MeshInstance3D", true, false) + [_spinner]:
		var mesh := found as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		var box := mesh.get_aabb()
		for corner in 8:
			far = minf(far, (into * mesh.global_transform * box.get_endpoint(corner)).z)
	_reach_z = far
	return far


## El nombre del golpe (ver EnergyBolt.lands).
func _hit_name() -> String:
	return "taladro"


func status() -> String:
	return "%s %s" % [_hit_name(), Mech.bar(spin)]
