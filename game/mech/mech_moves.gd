class_name MechMoves
extends RefCounted

## LO QUE HACE LA MECA CON LO QUE SE LE PIDE (ver Mech, LO QUE SE LE PIDE): caminar, correr, agacharse, saltar y el
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

## Lo cargado del salto y lo que le queda al propulsor (0 a 1), para mirar.
var jump_charge := 0.0
var fuel := 1.0
## El largo del palo de ahora, en partes del entero (agachada, cargando).
var rod_scale := 1.0

var _mech: Mech = null
var _jump_was := false
## En el aire, el salto empuja recién cuando se lo vuelve a pedir (el que soltó para saltar no cuenta).
var _thrust_armed := false


func _init(mech: Mech) -> void:
	_mech = mech


## Agacharse, cargar y soltar el salto, y el propulsor: lo que se pide en este paso.
func step(k: MechSettings, delta: float) -> void:
	var crouching := _mech.crouch
	if _mech.airborne:
		jump_charge = 0.0
		if not _mech.jump:
			_thrust_armed = true
		if _mech.jump and _thrust_armed and fuel > 0.0:
			fuel = maxf(fuel - delta / k.thrust_time, 0.0)
			_mech.nozzles.push(Vector3.UP * k.thrust * Mech.MASS, Vector3.ZERO, k)
	else:
		_thrust_armed = false
		fuel = minf(fuel + delta / k.thrust_refill, 1.0)
		if _mech.jump and not crouching and _mech.grounded:
			jump_charge = minf(jump_charge + delta / k.jump_charge_time, 1.0)
		elif _jump_was and jump_charge > 0.0 and _mech.grounded:
			_jump(k)
		else:
			jump_charge = 0.0
	_jump_was = _mech.jump
	var low := k.crouch_rod if crouching and not _mech.airborne else 1.0
	rod_scale = move_toward(rod_scale, minf(low, lerpf(1.0, k.jump_squat, jump_charge)), k.rod_rate * delta)


## SALTA: la altura sale de lo cargado, y de ahí la velocidad (v = √(2·g·h)). Es un cambio de velocidad propio y hacia
## arriba: el péndulo no lo lee como un golpe.
func _jump(k: MechSettings) -> void:
	var rise := lerpf(k.jump_least, 1.0, jump_charge) * k.jump_height
	_mech.linear_velocity.y = sqrt(2.0 * Mech.gravity() * rise)
	jump_charge = 0.0
	_mech.take_off()


## CAMINAR, CORRER Y AGACHADA. En el aire casi no cambia su velocidad de costado.
func drive(k: MechSettings, delta: float) -> void:
	var crouching := _mech.crouch and not _mech.airborne
	var walk := k.walk_speed * (k.crouch_speed if crouching else 1.0)
	var stick := Vector3(_mech.move.x, 0.0, -_mech.move.y)
	var sprinting := _mech.sprint and stick.z < 0.0 and not crouching
	var wanted := Basis(Vector3.UP, _mech.yaw()) * stick.limit_length(1.0) * walk * (k.sprint_multiplier if sprinting else 1.0)
	var flat := Vector3(_mech.linear_velocity.x, 0.0, _mech.linear_velocity.z)
	var most := k.walk_accel if wanted.length_squared() > 0.0001 else k.walk_brake
	# LA BANDA DEL SPRINT: por encima de la caminata, la velocidad se gana y se pierde más despacio.
	if flat.length() > walk:
		most *= k.sprint_accel
	if _mech.airborne:
		most = k.air_accel
	_mech.apply_central_force(((wanted - flat) / maxf(delta, 0.0001)).limit_length(most) * Mech.MASS)


## El salto cargándose y el propulsor, para el cartel de poseer.
func status() -> String:
	var parts := PackedStringArray()
	if jump_charge > 0.0:
		parts.append("salto %s %d %%" % [MechMoves._bar(jump_charge), roundi(jump_charge * 100.0)])
	parts.append("propulsor %s %d %%" % [MechMoves._bar(fuel), roundi(fuel * 100.0)])
	return "   ".join(parts)


static func _bar(share: float) -> String:
	var full := roundi(clampf(share, 0.0, 1.0) * 10.0)
	return "█".repeat(full) + "░".repeat(10 - full)
