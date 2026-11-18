class_name Gait
extends RefCounted

## ── LA MARCHA DE CUALQUIER CUERPO CON PATAS: 2, 4 O 6 (18/11/2026; módulo Jefes, el sistema común de movimiento) ────
## El usuario: «unificar las piernas IK… para 2, 4 o 6 patas». Sin BalanceBody: sólo cuenta dónde va cada pie. No
## dibuja ni mueve el cuerpo (no se sincroniza: sale de dónde está el cuerpo, a qué velocidad va y cuánto gira).
## UN CICLO CONTINUO, COMO SE HACE EN TODOS LADOS (fase y desfase por grupo; el pie pisa adelantado por la velocidad):
##   · LOS PIES SE AGRUPAN (`groups`) y cada grupo tiene su DESFASE en el ciclo: dos patas, de a una; cuatro, las
##     diagonales; seis, el trípode (`pattern`). Los grupos se reparten el ciclo: apenas uno pisa, sale el otro
##     (`swing_part`: la parte del ciclo en el aire; un poco menos que la que le toca, para un instante con todos
##     apoyados). *Hasta el 18/11/2026 un pie salía al quedar un tercio de paso atrás: entre un paso y el otro, un tercio
##     del ciclo nadie estaba en el aire, y el usuario lo vio: «hacen paso, paso, pausa».*
##   · EL CICLO AVANZA CON LO QUE ANDA: uno por `stride` m recorridos (o lo que recorre la pata de más afuera girando),
##     con topes (`fastest`, `slowest`; corriendo, el paso se alarga). Siempre al mismo ritmo, sin pausas.
##   · CADA PIE PISA donde va a estar SU LUGAR (`rests`, debajo de su cadera, en el piso de verdad: `ground`) a mitad
##     de su apoyo: el lugar al pisar, más lo que avanza el cuerpo en medio apoyo (el lugar también gira, si gira). Así
##     el apoyo queda centrado: el pie va de medio paso adelante a medio paso atrás, y no se corre.
##   · QUIETO, TERMINA EL PASO Y SE ACOMODA: cada grupo da un paso hasta su lugar y el ciclo se para. Un pie que quedó
##     poco corrido (menos de `settle_gap` del paso) no da pasitos.
##   · EL PIE EN EL AIRE va en arco (`lift`, más bajo en un paso corto), de donde salió hacia donde va a pisar, que se
##     mueve con el cuerpo. CON PISOTÓN (`stomp`, 0 a 1: el usuario, «que se sienta más de una meca»): llega adelante y
##     arriba antes y baja casi derecho y de golpe al final; en 0, un arco parejo.
## Lo que da: `feet` (el mundo), `swing_share` (0 a 1 por pata: cuánto lleva de su paso; −1 apoyada), `phase` y
## `steps_taken`. Uso: `setup(rests, groups)`, `place(root)` al ponerlo, y `update(delta, root, velocity)` en cada paso;
## `root`, el cuerpo en el piso (su giro y el punto debajo de su centro). El IK de cada pata, el común (IkUtil.bend_point).

## Más lento que esto (m/s) está quieto.
const STILL := 0.2

## Lo que avanza el cuerpo en un ciclo (m), lo que levanta el pie (m), los topes de un ciclo (s), la parte del ciclo de
## cada grupo que va en el aire (0 a 1) y lo poco corrido que no merece un paso (parte del paso).
var stride := 4.0
var lift := 1.2
var fastest := 0.35
var slowest := 1.1
var swing_part := 0.9
var settle_gap := 0.12
## El pisotón (0, arco parejo; 1, llega alto y adelante y baja de golpe).
var stomp := 0.0
## EL PISO DE VERDAD debajo de un punto (Callable(Vector3) -> Vector3). Sin él, el piso de `root`.
var ground := Callable()

var rests: Array[Vector3] = []
var groups: Array[int] = []
var feet: Array[Vector3] = []
var swing_share: Array[float] = []
var phase := 0.0
var steps_taken := 0

var _group_count := 1
## Si cada grupo está en el aire, y de dónde salió cada pie.
var _flying: Array[bool] = []
var _from: Array[Vector3] = []
## Quieto y acomodado: el ciclo parado.
var _resting := true
var _root := Transform3D()
var _velocity := Vector3.ZERO
## Cuánto gira (rad/s), suavizado; y lo más lejos que llega un pie del medio (m).
var _spin := 0.0
var _yaw_was := 0.0
var _reach := 1.0
var _period := 1.0


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
	_reach = 0.5
	for rest in rests:
		_reach = maxf(_reach, Vector2(rest.x, rest.z).length())
	feet.resize(rests.size())
	_from.resize(rests.size())
	swing_share.resize(rests.size())
	swing_share.fill(-1.0)
	_flying.resize(_group_count)
	_flying.fill(false)


## LO PONE en `root`: cada pie en su lugar, quieto.
func place(root: Transform3D) -> void:
	_root = root
	_velocity = Vector3.ZERO
	_spin = 0.0
	_yaw_was = root.basis.get_euler().y
	for leg in rests.size():
		feet[leg] = _floor(root * rests[leg])
	_flying.fill(false)
	swing_share.fill(-1.0)
	_resting = true


func update(delta: float, root: Transform3D, velocity: Vector3) -> void:
	_root = root
	_velocity = Vector3(velocity.x, 0.0, velocity.z)
	var yaw := root.basis.get_euler().y
	_spin = lerpf(_spin, angle_difference(_yaw_was, yaw) / maxf(delta, 0.0001), 1.0 - exp(-12.0 * delta))
	_yaw_was = yaw
	# Lo que anda: lo que avanza el medio o lo que recorre la pata de más afuera girando.
	var travel := maxf(_velocity.length(), absf(_spin) * _reach)
	var moving := travel > STILL
	if moving:
		_resting = false
	elif not _resting and _settled():
		# Quieto y acomodado: se para el ciclo con todos los pies en su lugar.
		_resting = true
		for group in _group_count:
			if _flying[group]:
				_land(group)
	if _resting:
		return
	_period = clampf(stride / travel, fastest, slowest) if moving else slowest
	phase = fposmod(phase + delta / _period, 1.0)
	var air := clampf(swing_part / _group_count, 0.05, 1.0)
	for group in _group_count:
		var local := fposmod(phase - float(group) / _group_count, 1.0)
		var wants := local < air
		if wants and not _flying[group]:
			_flying[group] = true
			steps_taken += 1
			for leg in rests.size():
				if groups[leg] == group:
					_from[leg] = feet[leg]
		elif not wants and _flying[group]:
			_land(group)
		if _flying[group]:
			var share := local / air
			var left := (air - local) * _period
			for leg in rests.size():
				if groups[leg] == group:
					swing_share[leg] = share
					feet[leg] = _in_air(leg, share, left)


## Quieto: si todos los pies están en su lugar (o casi), y los que van en el aire, también hacia él.
func _settled() -> bool:
	for leg in rests.size():
		var off := feet[leg] - _floor(_root * rests[leg])
		off.y = 0.0
		if off.length() > stride * settle_gap:
			return false
		if _flying[groups[leg]]:
			var lap := _from[leg] - feet[leg]
			lap.y = 0.0
			if lap.length() > stride * settle_gap:
				return false
	return true


func _land(group: int) -> void:
	_flying[group] = false
	for leg in rests.size():
		if groups[leg] == group:
			feet[leg] = _landing(leg, 0.0)
			swing_share[leg] = -1.0


## DÓNDE PISA el pie `leg` si le quedan `left` segundos en el aire: su lugar entonces (el cuerpo corrido y girado lo que
## falta), más lo que avanza el cuerpo en medio apoyo, para que el apoyo quede centrado.
func _landing(leg: int, left: float) -> Vector3:
	var stance := _period * (1.0 - clampf(swing_part / _group_count, 0.05, 1.0))
	var ahead := left + stance * 0.5
	var turn := Basis(Vector3.UP, _spin * ahead)
	var later := Transform3D(turn * _root.basis, _root.origin + _velocity * ahead)
	if _resting or (_velocity.length() <= STILL and absf(_spin) * _reach <= STILL):
		later = _root
	return _floor(later * rests[leg])


## EL PIE EN EL AIRE: de donde salió hacia donde va a pisar, en arco.
func _in_air(leg: int, share: float, left: float) -> Vector3:
	var to := _landing(leg, left)
	# Con pisotón, lo de costado termina antes (después baja casi derecho) y lo más alto queda más tarde.
	var eased := smoothstep(0.0, 1.0 - 0.25 * stomp, share)
	var arc := sin(PI * pow(share, 1.0 + stomp))
	var high := clampf(Vector2(to.x - _from[leg].x, to.z - _from[leg].z).length() / stride, 0.2, 1.0)
	return _from[leg].lerp(to, eased) + Vector3.UP * arc * lift * high


func _floor(at: Vector3) -> Vector3:
	if ground.is_valid():
		return ground.call(at)
	return Vector3(at.x, _root.origin.y, at.z)
