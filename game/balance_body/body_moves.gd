class_name BodyMoves
extends RefCounted

## LO QUE HACE UN CUERPO CON EQUILIBRIO CON LO QUE SE LE PIDE (ver BalanceBody, LO QUE SE LE PIDE): caminar, correr, agacharse, saltar y el
## propulsor. Todo son FUERZAS sobre la caja, o el largo del palo del péndulo: nunca la mueve por código. (Acá van a
## ir los propulsores de costado y los dashes.)
##   · CAMINAR (`move`): empuja al torso, en su centro, hacia la velocidad pedida —adelante hacia donde mira, y de
##     costado—, con tope para arrancar y para frenar: su inercia.
##   · CORRER (`sprint`, yendo hacia adelante): hasta `sprint_multiplier` por la velocidad de caminar. Lo de arriba de
##     la caminata es una banda que se gana y se pierde a `sprint_accel` de la aceleración: tarda en llegar y en irse.
##   · AGACHARSE (`crouch`): el palo se acorta (`crouch_rod`), el cuerpo baja y las piernas se doblan solas; camina más
##     lento.
##   · SALTAR (`jump`): mantenerlo CARGA —el cuerpo baja, `jump_squat`— y soltarlo SALTA, de `jump_least` a todo su
##     `jump_height` según lo cargado (se carga altura, no fuerza: la barra es lineal con lo que salta).
##   · EL PROPULSOR (`jump` en el aire): las toberas de abajo la empujan para arriba mientras le quede (`thrust_time`);
##     se recarga en el piso.
##   · EN EL AIRE PESA MÁS (`air_gravity`, y bajando `fall_extra`): el salto sube y baja rápido, sin flotar. Con el
##     propulsor prendido, lo de siempre.
##   · EL DASH (`dash` en el aire, apretado de nuevo): un impulso de costado hacia donde se pide, de las toberas del otro
##     lado; gasta propulsor y hay `dash_count` por salto. SÓLO EN EL AIRE (el usuario: «los dashes van a estar
##     disponibles solamente mientras estás haciendo un salto… si no, un dash con el sistema de piernas actual se vería
##     raro»): al aterrizar, el apoyo arranca con la velocidad que trae y los pies frenan.

## Cuánto se ven prendidas las toberas de un dash (s).
const DASH_SHOW := 0.3

## Lo cargado del salto y lo que le queda al propulsor (0 a 1), para mirar.
var jump_charge := 0.0
var fuel := 1.0
## El largo del palo de ahora, en partes del entero (agachada, cargando).
var rod_scale := 1.0

## Los dashes que le quedan en este salto.
var dashes_left := 0

var _body: BalanceBody = null
var _jump_was := false
var _dash_was := true
var _thrusting := false
## En el aire, el salto empuja recién cuando se lo vuelve a pedir (el que soltó para saltar no cuenta).
var _thrust_armed := false


func _init(body: BalanceBody) -> void:
	_body = body


## Agacharse, cargar y soltar el salto, y el propulsor: lo que se pide en este paso.
func step(k: BodySettings, delta: float) -> void:
	var crouching := _body.crouch
	_thrusting = false
	if _body.airborne:
		jump_charge = 0.0
		if not _body.jump:
			_thrust_armed = true
		if _body.jump and _thrust_armed and fuel > 0.0:
			_thrusting = true
			fuel = maxf(fuel - delta / k.thrust_time, 0.0)
			_body.nozzles.push(Vector3.UP * k.thrust * _body.mass, Vector3.ZERO, k)
		if _body.dash and not _dash_was and dashes_left > 0 and fuel >= k.dash_cost:
			_dash(k)
	else:
		dashes_left = k.dash_count
		_thrust_armed = false
		fuel = minf(fuel + delta / k.thrust_refill, 1.0)
		if _body.jump and not crouching and _body.grounded:
			jump_charge = minf(jump_charge + delta / k.jump_charge_time, 1.0)
		elif _jump_was and jump_charge > 0.0 and _body.grounded:
			_jump(k)
		else:
			jump_charge = 0.0
	_jump_was = _body.jump
	_dash_was = _body.dash
	var low := k.crouch_rod if crouching and not _body.airborne else 1.0
	rod_scale = move_toward(rod_scale, minf(low, lerpf(1.0, k.jump_squat, jump_charge)), k.rod_rate * delta)


## SALTA: la altura sale de lo cargado, y de ahí la velocidad (v = √(2·g·h), con la gravedad del aire). Es un cambio de velocidad propio y hacia
## arriba: el péndulo no lo lee como un golpe.
func _jump(k: BodySettings) -> void:
	var rise := lerpf(k.jump_least, 1.0, jump_charge) * k.jump_height
	var now := _body.velocity()
	_body.set_velocity(Vector3(now.x, sqrt(2.0 * BalanceBody.gravity() * k.air_gravity * rise), now.z))
	jump_charge = 0.0
	_body.take_off()


## EL DASH: un impulso (ver arriba). Lo que se pide de costado, en el espacio del torso; sin pedir nada, adelante.
func _dash(k: BodySettings) -> void:
	var stick := Vector3(_body.move.x, 0.0, -_body.move.y)
	if stick.length_squared() < 0.01:
		stick = Vector3.FORWARD
	var way := (Basis(Vector3.UP, _body.yaw()) * stick).normalized()
	var now := _body.velocity()
	var flat := Vector3(now.x, 0.0, now.z)
	var change := way * maxf(flat.dot(way), 0.0) + way * k.dash_speed - flat
	change.y = maxf(k.dash_lift - now.y, 0.0)
	_body.push_impulse(change * _body.mass)
	_body.nozzles.show(way, DASH_SHOW)
	fuel = maxf(fuel - k.dash_cost, 0.0)
	dashes_left -= 1


## CUÁNTO PESA AHORA (la escala de la gravedad): en el aire, más (ver arriba); con el propulsor o apoyada, lo de siempre.
func gravity_share(k: BodySettings) -> float:
	if not _body.airborne or _thrusting:
		return 1.0
	return k.air_gravity * (k.fall_extra if _body.velocity().y < 0.0 else 1.0)


## CAMINAR, CORRER Y AGACHADA. En el aire casi no cambia su velocidad de costado.
func drive(k: BodySettings, delta: float) -> void:
	var crouching := _body.crouch and not _body.airborne
	var walk := k.walk_speed * (k.crouch_speed if crouching else 1.0)
	var stick := Vector3(_body.move.x, 0.0, -_body.move.y)
	var sprinting := _body.sprint and stick.z < 0.0 and not crouching
	var wanted := Basis(Vector3.UP, _body.yaw()) * stick.limit_length(1.0) * walk * (k.sprint_multiplier if sprinting else 1.0)
	var now := _body.velocity()
	var flat := Vector3(now.x, 0.0, now.z)
	var most := k.walk_accel if wanted.length_squared() > 0.0001 else k.walk_brake
	# LA BANDA DEL SPRINT: por encima de la caminata, la velocidad se gana y se pierde más despacio.
	if flat.length() > walk:
		most *= k.sprint_accel
	if _body.airborne:
		most = k.air_accel
	_body.push_force(((wanted - flat) / maxf(delta, 0.0001)).limit_length(most) * _body.mass)


## El salto cargándose y el propulsor, para el cartel de poseer.
func status() -> String:
	var parts := PackedStringArray()
	if jump_charge > 0.0:
		parts.append("salto %s %d %%" % [BodyMoves._bar(jump_charge), roundi(jump_charge * 100.0)])
	parts.append("propulsor %s %d %%" % [BodyMoves._bar(fuel), roundi(fuel * 100.0)])
	if _body.airborne:
		parts.append("dash %d" % dashes_left)
	return "   ".join(parts)


static func _bar(share: float) -> String:
	var full := roundi(clampf(share, 0.0, 1.0) * 10.0)
	return "█".repeat(full) + "░".repeat(10 - full)
