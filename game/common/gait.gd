class_name Gait
extends RefCounted

## ── LA MARCHA DE CUALQUIER CUERPO CON PATAS: 2, 4 O 6 (18/11/2026; módulo Jefes, el sistema común de movimiento) ────
## El usuario: «unificar las piernas IK… para 2, 4 o 6 patas». Es la regla de las piernas de la jaula (BodyLegs, «los
## pasos nuevos»: cada pie tiene su lugar) llevada a N patas y a GRUPOS que pisan juntos, sin BalanceBody: sólo cuenta
## dónde va cada pie. No dibuja ni mueve el cuerpo (no se sincroniza: sale de dónde está el cuerpo y a qué velocidad va).
##   · CADA PIE TIENE SU LUGAR (`rests`: debajo de su cadera, en los ejes del cuerpo), en el piso de verdad (`ground`).
##   · LOS PIES SE AGRUPAN (`groups`: el grupo de cada pata) y UN GRUPO SALE ENTERO: dos patas, de a una (alternada);
##     cuatro, las diagonales; seis, el trípode (adelante y atrás de un lado con la del medio del otro). Otro reparto
##     sale de `groups` (`pattern`).
##   · UN GRUPO SALE cuando alguno de sus pies quedó UN TERCIO DE PASO atrás de su lugar (o corrido, girando: el lugar
##     gira con el cuerpo) Y NO HAY OTRO GRUPO EN EL AIRE (se turnan). Cada pie pisa un tercio adelante de donde va a
##     estar su lugar al pisar; el paso dura lo que el cuerpo tarda en recorrer el otro tercio, con topes: siempre el
##     mismo largo (`stride`), más rápido, más seguido.
##   · QUIETO, SE ACOMODA: después de `settle_wait`, el grupo que quedó corrido trae sus pies.
##   · EL PIE EN EL AIRE va en arco (`lift`, más bajo en un paso corto) hacia donde va a pisar, que se mueve con el
##     cuerpo.
## Lo que da: `feet` (el mundo), `swing_share` (0 a 1 por pata: cuánto lleva de su paso; −1 apoyada) y `steps_taken`.
## Uso: `setup(rests, groups)`, `place(root)` al ponerlo, y `update(delta, root, velocity)` en cada paso; `root`, el
## cuerpo en el piso (su giro y el punto debajo de su centro). El IK de cada pata, `knee`.

## Más lento que esto (m/s) está quieto: los pies sólo se acomodan.
const STILL := 0.25

## El largo de un paso (m), lo que levanta el pie (m), los topes de un paso (s) y cuánto espera quieto para acomodarse.
var stride := 4.0
var lift := 1.2
var fastest := 0.15
var slowest := 0.6
var settle_wait := 0.25
## EL PISO DE VERDAD debajo de un punto (Callable(Vector3) -> Vector3). Sin él, el piso de `root`.
var ground := Callable()

var rests: Array[Vector3] = []
var groups: Array[int] = []
var feet: Array[Vector3] = []
var swing_share: Array[float] = []
var steps_taken := 0

var _group_count := 1
## El grupo en el aire (−1, ninguno), cuánto lleva y cuánto dura, y de dónde salió cada pie.
var _swing := -1
var _swing_clock := 0.0
var _swing_time := 1.0
var _from: Array[Vector3] = []
var _still_clock := 0.0
var _root := Transform3D()
var _velocity := Vector3.ZERO


## LOS REPARTOS DE SIEMPRE, por cuántas patas. Las patas van de adelante para atrás, de a pares (izquierda, derecha):
## 0 y 1 las de adelante, 2 y 3 las siguientes…
static func pattern(count: int) -> Array[int]:
	var out: Array[int] = []
	for leg in count:
		var row := leg / 2
		var side := leg % 2
		match count:
			2:
				out.append(side)
			_:
				# Las diagonales (4) y el trípode (6): se alternan de fila en fila.
				out.append((row + side) % 2)
	return out


func setup(leg_rests: Array[Vector3], leg_groups: Array[int] = []) -> void:
	rests = leg_rests.duplicate()
	groups = leg_groups.duplicate() if leg_groups.size() == rests.size() else pattern(rests.size())
	_group_count = 0
	for group in groups:
		_group_count = maxi(_group_count, group + 1)
	feet.resize(rests.size())
	_from.resize(rests.size())
	swing_share.resize(rests.size())
	swing_share.fill(-1.0)


## LO PONE en `root`: cada pie en su lugar, quieto.
func place(root: Transform3D) -> void:
	_root = root
	_velocity = Vector3.ZERO
	for leg in rests.size():
		feet[leg] = _home(leg, 0.0)
	_swing = -1
	swing_share.fill(-1.0)


func update(delta: float, root: Transform3D, velocity: Vector3) -> void:
	_root = root
	_velocity = Vector3(velocity.x, 0.0, velocity.z)
	if _swing >= 0:
		_swing_clock += delta
		var share := clampf(_swing_clock / _swing_time, 0.0, 1.0)
		for leg in rests.size():
			if groups[leg] == _swing:
				swing_share[leg] = share
				feet[leg] = _in_air(leg, share)
		if _swing_clock < _swing_time:
			return
		for leg in rests.size():
			if groups[leg] == _swing:
				feet[leg] = _landing(leg, 0.0)
				swing_share[leg] = -1.0
		_swing = -1
	var speed := _velocity.length()
	var moving := speed > STILL
	_still_clock = 0.0 if moving else _still_clock + delta
	var worst := -1
	var farthest := 0.0
	for group in _group_count:
		var gap := 0.0
		var due := false
		for leg in rests.size():
			if groups[leg] != group:
				continue
			var off := feet[leg] - _home(leg, 0.0)
			off.y = 0.0
			gap = maxf(gap, off.length())
			# ATRÁS (o de costado) a un tercio de paso: sale. Adelante no: recién pisó.
			if off.length() >= stride / 3.0 and (not moving or off.dot(_velocity) <= 0.0):
				due = true
		if not moving and _still_clock >= settle_wait and gap > stride * 0.05:
			due = true
		if due and gap > farthest:
			worst = group
			farthest = gap
	if worst < 0:
		return
	_swing = worst
	_swing_clock = 0.0
	_swing_time = clampf(stride / 3.0 / speed, fastest, slowest) if moving else slowest
	for leg in rests.size():
		if groups[leg] == worst:
			_from[leg] = feet[leg]
			swing_share[leg] = 0.0
	steps_taken += 1


## EL LUGAR DEL PIE `leg` dentro de `ahead` segundos: debajo de su cadera, en el piso.
func _home(leg: int, ahead: float) -> Vector3:
	var at := _root * rests[leg] + _velocity * ahead
	return _floor(at)


## DÓNDE PISA el pie `leg` si le quedan `left` segundos de paso: un tercio de paso adelante de su lugar, hacia donde va.
func _landing(leg: int, left: float) -> Vector3:
	var at := _home(leg, left)
	if _velocity.length() > STILL:
		at = _floor(at + _velocity.normalized() * stride / 3.0)
	return at


## EL PIE EN EL AIRE: de donde salió hacia donde va a pisar, en arco.
func _in_air(leg: int, share: float) -> Vector3:
	var to := _landing(leg, maxf(_swing_time - _swing_clock, 0.0))
	var eased := smoothstep(0.0, 1.0, share)
	var high := clampf(Vector2(to.x - _from[leg].x, to.z - _from[leg].z).length() / stride, 0.35, 1.0)
	return _from[leg].lerp(to, eased) + Vector3.UP * sin(share * PI) * lift * high


func _floor(at: Vector3) -> Vector3:
	if ground.is_valid():
		return ground.call(at)
	return Vector3(at.x, _root.origin.y, at.z)


## EL IK DE DOS HUESOS: dónde va la rodilla de una pata que va de `hip` a `foot` con muslo `upper` y canilla `lower`,
## doblando hacia `bend` (el mundo). Si el pie queda lejos, la pata se estira derecha hacia él.
static func knee(hip: Vector3, foot: Vector3, upper: float, lower: float, bend: Vector3) -> Vector3:
	var along := foot - hip
	var reach := clampf(along.length(), absf(upper - lower) + 0.001, upper + lower - 0.001)
	var way := along.normalized() if along.length() > 0.0001 else Vector3.DOWN
	# Lo que avanza la rodilla por la línea y lo que se aparta (ley de los cosenos).
	var forward := (upper * upper - lower * lower + reach * reach) / (2.0 * reach)
	var out := sqrt(maxf(upper * upper - forward * forward, 0.0))
	var side := (bend - way * bend.dot(way))
	side = side.normalized() if side.length() > 0.0001 else way.cross(Vector3.RIGHT).normalized()
	return hip + way * forward + side * out
