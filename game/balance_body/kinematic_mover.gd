class_name KinematicMover
extends CharacterBody3D

## EL MOTOR DE LA MECA CINEMÁTICA (13/11/2026): la pieza que la mueve cuando es cinemática (ver BalanceBody `kinematic`).
## Es lo que se probó en el Laboratorio cinemático con el cubo, pasado a la meca de verdad (el usuario: «la meca
## cinemática, que ahora es distinta del laboratorio cinemático, probablemente habría que unificarla»); hoy mueve a la
## meca jaula. *El laboratorio y la meca cinemática de la meca grande se borraron el 17/11/2026 (commit 0bcaeaf).*
##
## LO MUEVE EL CONTROLADOR DE PERSONAJE DEL MOTOR (CharacterBody3D, `move_and_slide`): se le da una velocidad y él frena
## y se desliza contra paredes y esquinas, sabe si está en el piso y se sale solo si queda metido en algo. *Antes la
## meca cinemática se movía con un «pruebo y deslizo» escrito a mano (BodyKinematic): en una esquina quedaba un
## centímetro adentro y de ahí atravesaba el edificio.*
##   · CONTRA LO FIJO DEL MUNDO, UN CILINDRO que envuelve la caja (y el vidrio de adelante: `BalanceBody.outline_extra`),
##     del piso al techo. Es la forma de este cuerpo, y mira SÓLO LA CAPA DE LO FIJO (PhysicsLayers.FIXED): a él no lo
##     ve nadie. Girar nunca lo traba.
##   · CONTRA LO SUELTO, LO QUE SE VE: la caja de la meca (congelada, cinemática, que lo sigue) y sus pies con choque
##     (StompFeet). LO QUE QUEDA DEBAJO DE LA CAJA CUANDO BAJA (al agacharse, al caer) SE ACHATA (StompFeet.flatten).
##   · MOVERSE ES DISCRETO, EN METROS Y SEGUNDOS (KinematicSettings): una velocidad y el tiempo para llegar; el salto,
##     sólo vertical; el vuelo, a velocidad fija; el dash (Shift, con una dirección), tantos metros en tanto tiempo, en
##     el piso y en el aire. Agacharse baja la caja de a poco.
## Lee lo que se le pide del cuerpo (`move`, `jump`, `dash`, `crouch`, `aim_yaw`) y le escribe lo que miden las piernas
## (el apoyo y su velocidad, si está apoyado) y dónde va la caja (`body_place`).
## LOS GOLPES la mueven por dos puertas (las llama quien pega: los jefes, HitReaction), y mientras duran no se maneja:
##   · EL EMPUJÓN (`shove`): se corre tantos metros de costado en tanto tiempo, con un saltito o un arco (el revoleo),
##     por este mismo motor (no atraviesa lo fijo), y termina en el piso.
##   · LA CAÍDA (`knock_down`): cae de espaldas, queda tirada y se levanta (BalanceBody.State, como la física), animado.
##     La inclinación es de la caja misma (`body_place`), así los brazos (que se arman desde ella) y las piernas (que se
##     recogen, como en la física) la siguen solos.
## *Hasta el 15/11/2026 lo hacía desde afuera el módulo Jefes, después de cada paso, girando encima las piezas ya
## armadas derechas: los brazos se veían rotos.*

var body: BalanceBody = null
## Las barras (0 a 1): la del dash y la del vuelo. Y cuánto está agachada (0 a 1).
var dash_fuel := 1.0
var fly_fuel := 1.0
var crouched := 0.0
## Cuántas cosas acható con la caja (las de los pies, en StompFeet).
var flattened := 0

var _yaw := 0.0
var _yaw_speed := 0.0
var _jump_was := false
var _dash_was := false
var _fly_armed := false
## El dash de ahora: cuánto le queda (s) y a qué velocidad va.
var _dash_left := 0.0
var _dash_way := Vector3.FORWARD
## Cuánto lleva el dash (s; ver `_dashing`).
var _dash_clock := 0.0
## Cuánto falta para que pueda salir otro dash (s; el que dura más la espera: ver KinematicSettings.dash_cooldown).
var _dash_wait := 0.0
## El empujón de ahora (ver `shove`): cuánto le queda y cuánto dura (s), a qué velocidad de costado va y el saltito (m).
var _shove_left := 0.0
var _shove_time := 0.0
var _shove_flat := Vector3.ZERO
var _shove_hop := 0.0
## LA CAÍDA (ver `knock_down`): cuánto está inclinada para atrás (°) y su reloj (s).
var lean := 0.0
var _fall_clock := 0.0
var _cylinder := CylinderShape3D.new()
var _holder := CollisionShape3D.new()
var _below := BoxShape3D.new()
var _last_bottom := 0.0


func _init() -> void:
	top_level = true
	# A él no lo ve nadie, y él ve sólo lo fijo del mundo.
	collision_layer = 0
	collision_mask = PhysicsLayers.FIXED
	floor_snap_length = 0.2


func _ready() -> void:
	var half := Vector2(body.size.x * 0.5, body.size.z * 0.5 + body.outline_extra)
	_cylinder.radius = half.length() + 0.1
	_holder.shape = _cylinder
	add_child(_holder)
	_below.size = Vector3(body.size.x, 0.6, body.size.z)
	_yaw = body.global_rotation.y
	body.aim_yaw = _yaw
	global_position = body.global_position - Vector3.UP * (body.size.y * 0.5 + body.hover)
	_fit()
	_last_bottom = global_position.y + _hover_now()


## A QUÉ ALTURA VA LA CARA DE ABAJO DE LA CAJA, ahora (agachada, más bajo).
func _hover_now() -> float:
	return body.hover * lerpf(1.0, body.kinematic_settings().crouch_share, crouched)


## El cilindro, del piso al techo de la caja.
func _fit() -> void:
	_cylinder.height = _hover_now() + body.size.y
	_holder.position.y = _cylinder.height * 0.5


## DÓNDE VA LA CAJA: sobre sus piernas, mirando como él. CAYÉNDOSE, LA POSE DE REPOSO DE UNA PIEZA (la caja, las
## piernas y los brazos como parada) se vuelca `lean` grados PARA ATRÁS, siempre de espaldas, sobre el canto del piso
## debajo de su espalda: con 90°, la espalda en el piso (el usuario, 15/11/2026: «la animación debería ser mucho más
## simple, agarrar la pose de reposo, y hacer que siempre se caiga hacia arriba (espalda al suelo)»).
func body_place() -> Transform3D:
	var upright := standing_place()
	if lean <= 0.0:
		return upright
	var back := upright.basis.z * body.size.z * 0.5
	var turn := Basis(upright.basis.x, deg_to_rad(lean))
	var pivot := global_position + back
	return Transform3D(turn * upright.basis, pivot + turn * (upright.origin - pivot))


## DÓNDE IRÍA LA CAJA PARADA, aunque esté caída (la pose de reposo se arma ahí y se vuelca: ver BodyLegs.place).
func standing_place() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, _yaw), global_position + Vector3.UP * (_hover_now() + body.size.y * 0.5))


## UN PASO (ver arriba): lo que se le pide, moverse con el motor, y lo que miden las piernas.
func step(delta: float) -> void:
	var k := body.kinematic_settings()
	crouched = move_toward(crouched, 1.0 if body.crouch else 0.0, k.crouch_rate * delta)
	_fit()
	var grounded := is_on_floor()
	dash_fuel = minf(dash_fuel + delta / k.dash_refill, 1.0)
	_dash_wait = maxf(_dash_wait - delta, 0.0)
	_fall(k, delta)
	if _shove_left > 0.0 or body.state != BalanceBody.State.STANDING:
		# EMPUJADA O EN EL PISO: no se maneja (ver `shove`, `knock_down`).
		velocity = _pushed(k, delta, grounded)
	elif _dash_left > 0.0:
		# EN UN DASH: frenándose sola, torciéndose hacia donde se pide, sin gravedad.
		velocity = _dashing(k, delta)
	else:
		var flat := _walk(k, delta, grounded)
		velocity = Vector3(flat.x, _rise(k, delta, grounded), flat.z)
		# Una sola regla de cuándo sale (la lee también la meca con herramientas: ToolMechKeys).
		if body.dash and not _dash_was and dash_ready():
			_dash(k, delta)
	_dash_was = body.dash
	_jump_was = body.jump
	if body.state == BalanceBody.State.STANDING and _shove_left <= 0.0:
		_turn(k, delta)
	else:
		body.aim_yaw = _yaw
		_yaw_speed = 0.0
	rotation.y = _yaw
	move_and_slide()
	# LO QUE MIDEN LAS PIERNAS (ver BodyLegs): el apoyo es el piso debajo, y va a la velocidad de costado.
	var real := get_real_velocity()
	body.grounded = is_on_floor()
	body.airborne = not body.grounded
	body.support = global_position
	body.support_speed = Vector3(real.x, 0.0, real.z)
	body.tilt = lean
	body.height = _hover_now()
	body.moves.rod_scale = (body.size.y * 0.5 + _hover_now()) / (body.size.y * 0.5 + body.hover)
	# Lo que queda debajo de la caja cuando baja, se achata (ver arriba).
	var bottom := global_position.y + _hover_now()
	if bottom < _last_bottom - 0.0001:
		_squash()
	_last_bottom = bottom


## MOVERSE: de costado, hacia la velocidad pedida, CON PESO: acelerando, en `start_time`; frenando o cambiando de
## dirección, en `stop_time` (0: al instante). EN EL AIRE NO SE MANEJA, PERO SIGUE CON SU IMPULSO: lo que traía de
## costado (de caminar o de un dash) no cambia hasta tocar el piso.
func _walk(k: KinematicSettings, delta: float, grounded: bool) -> Vector3:
	if not grounded:
		return Vector3(velocity.x, 0.0, velocity.z)
	var wanted := _wanted() * k.walk_speed
	var now := Vector3(velocity.x, 0.0, velocity.z)
	var speeding := wanted.length() > now.length() + 0.01 and wanted.dot(now) >= 0.0
	var time := k.start_time if speeding else k.stop_time
	if time <= 0.0:
		return wanted
	return now.move_toward(wanted, k.walk_speed / time * delta)


## Hacia dónde y cuánto se pide moverse (de costado, en el mundo; largo 0 a 1).
func _wanted() -> Vector3:
	return Basis(Vector3.UP, _yaw) * Vector3(body.move.x, 0.0, -body.move.y).limit_length(1.0)


## SUBIR Y BAJAR: el salto (al apretar, apoyada), el vuelo (apretando otra vez en el aire) y la caída. Devuelve la
## velocidad para arriba.
func _rise(k: KinematicSettings, delta: float, grounded: bool) -> float:
	# De subir `jump_height` en `jump_time`: g = 2·h / t², y sale a v = 2·h / t.
	var gravity := 2.0 * k.jump_height / (k.jump_time * k.jump_time)
	if grounded:
		fly_fuel = minf(fly_fuel + delta / k.fly_refill, 1.0)
		if body.jump and not _jump_was:
			_fly_armed = false
			return 2.0 * k.jump_height / k.jump_time
		return 0.0
	if not body.jump:
		_fly_armed = true
	if body.jump and _fly_armed and fly_fuel > 0.0:
		fly_fuel = maxf(fly_fuel - delta / k.fly_time, 0.0)
		return k.fly_speed
	return velocity.y - gravity * delta


## EL DASH: hacia donde se pide (ver KinematicSettings, «Dash»).
func _dash(k: KinematicSettings, delta: float) -> void:
	_dash_way = _wanted().normalized()
	_dash_left = k.dash_time
	_dash_clock = 0.0
	_dash_wait = k.dash_time + k.dash_cooldown
	velocity = _dashing(k, delta)
	dash_fuel -= k.dash_cost


## UN PASO DEL DASH: la velocidad baja pareja de la de salida a la de caminar (`walk_speed`) en `dash_time`, así recorre
## `dash_distance` (la de salida sale de eso: d = t · (salida + caminar) / 2); la dirección se tuerce hacia donde se
## pide, a lo más `dash_steer` grados por segundo.
func _dashing(k: KinematicSettings, delta: float) -> Vector3:
	var wanted := _wanted()
	if wanted.length() > 0.1:
		var angle := _dash_way.signed_angle_to(wanted, Vector3.UP)
		var most := deg_to_rad(k.dash_steer) * delta
		_dash_way = _dash_way.rotated(Vector3.UP, clampf(angle, -most, most)).normalized()
	var share := clampf((_dash_clock + delta * 0.5) / k.dash_time, 0.0, 1.0)
	var start := maxf(2.0 * k.dash_distance / k.dash_time - k.walk_speed, k.walk_speed)
	_dash_clock += delta
	_dash_left -= delta
	return _dash_way * lerpf(start, k.walk_speed, share)


## UN EMPUJÓN: se corre `offset` (m, de costado) en `time` (s), con un saltito de `hop` m (un arco: sube y baja en
## ese tiempo), por este motor (no atraviesa lo fijo). Mientras, no se maneja (ni el dash); después cae al piso. Sirve
## para empujarla (10–22 m en medio segundo) y para revolearla (70 m en 1,3 s, con 25 m de arco).
func shove(offset: Vector3, time: float, hop := 0.0) -> void:
	_shove_time = maxf(time, 0.01)
	_shove_left = _shove_time
	_shove_flat = Vector3(offset.x, 0.0, offset.z) / _shove_time
	_shove_hop = hop
	_dash_left = 0.0


## DERRIBADA: cae de espaldas (ver `body_place`), queda tirada y se levanta (BalanceBody.State: DOWN, LIFT, RIGHT y
## otra vez STANDING), en los tiempos de KinematicSettings («Caerse»). Si ya está en el piso, nada.
func knock_down() -> void:
	if body.state != BalanceBody.State.STANDING:
		return
	_fall_clock = 0.0
	_dash_left = 0.0
	body.state = BalanceBody.State.DOWN
	body.falls += 1


## EMPUJADA O EN EL PISO: la velocidad del empujón (de costado, y el arco del saltito: y = 4·h·s·(1 − s)), o quieta
## de costado y cayendo al piso.
func _pushed(k: KinematicSettings, delta: float, grounded: bool) -> Vector3:
	if _shove_left > 0.0:
		var share := 1.0 - (_shove_left - delta * 0.5) / _shove_time
		_shove_left -= delta
		return _shove_flat + Vector3.UP * (4.0 * _shove_hop * (1.0 - 2.0 * share) / _shove_time)
	var gravity := 2.0 * k.jump_height / (k.jump_time * k.jump_time)
	return Vector3(0.0, 0.0 if grounded else velocity.y - gravity * delta, 0.0)


## LA CAÍDA, paso a paso: cae (acelerando) hasta `fall_lie`, queda tirada, y se levanta; a la mitad de levantarse (ver
## BalanceBody.LAST_STRETCH) estira las piernas, como la física.
func _fall(k: KinematicSettings, delta: float) -> void:
	if body.state == BalanceBody.State.STANDING:
		lean = 0.0
		return
	_fall_clock += delta
	if body.state == BalanceBody.State.DOWN:
		var share := clampf(_fall_clock / k.fall_time, 0.0, 1.0)
		lean = k.fall_lie * share * share
		if _fall_clock >= k.fall_time + k.down_time:
			body.state = BalanceBody.State.LIFT
			_fall_clock = 0.0
		return
	lean = k.fall_lie * (1.0 - smoothstep(0.0, 1.0, _fall_clock / k.rise_time))
	if body.state == BalanceBody.State.LIFT and lean <= BalanceBody.LAST_STRETCH:
		body.state = BalanceBody.State.RIGHT
	if _fall_clock >= k.rise_time:
		lean = 0.0
		body.state = BalanceBody.State.STANDING
		body.legs.replant()


## EL GIRO: hacia `aim_yaw`, con tope de velocidad y de aceleración. Nada lo traba: contra el mundo es un cilindro.
func _turn(k: KinematicSettings, delta: float) -> void:
	var error := clampf(wrapf(body.aim_yaw - _yaw, -PI, PI), -BalanceBody.AIM_LEAD, BalanceBody.AIM_LEAD)
	body.aim_yaw = _yaw + error
	var top := deg_to_rad(k.turn_speed)
	if k.turn_spring > 0.0:
		# EL RESORTE (ver KinematicSettings.turn_spring): tira hacia lo pedido, frena con la velocidad; con los topes.
		var push := KinematicMover.spring(error, _yaw_speed, k.turn_spring, k.turn_bounce)
		var most := deg_to_rad(k.turn_accel)
		_yaw_speed = clampf(_yaw_speed + clampf(push, -most, most) * delta, -top, top)
	else:
		_yaw_speed = move_toward(_yaw_speed, clampf(error * 6.0, -top, top), deg_to_rad(k.turn_accel) * delta)
	_yaw += _yaw_speed * delta


## LA ACELERACIÓN DE UN RESORTE CON FRENO hacia `error` (lo que falta), yendo a `speed`: de `frequency` (Hz) y
## amortiguado `bounce` (1, justo sin pasarse; menos, se pasa y vuelve).
static func spring(error: float, speed: float, frequency: float, bounce: float) -> float:
	var omega := TAU * frequency
	return omega * omega * error - 2.0 * bounce * omega * speed


## LA PONE en `where` (el punto del piso debajo de su centro), quieta, sin barrer el camino (ver StompFeet.place_now).
func put(where: Transform3D) -> void:
	global_position = where.origin
	_yaw = where.basis.get_euler().y
	rotation.y = _yaw
	body.aim_yaw = _yaw
	_yaw_speed = 0.0
	velocity = Vector3.ZERO
	_dash_left = 0.0
	_shove_left = 0.0
	_last_bottom = global_position.y + _hover_now()


## Cuánto se mueve de costado (m/s), para el cartel.
func speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## SI UN DASH SALDRÍA AHORA, si se apretara: lo mismo que pide step() (parada, sin empujón ni otro dash en curso, con una
## dirección, con barra y pasada la espera entre dashes). Para quien cobra el dash aparte, como la meca con herramientas
## (ToolMech) con su energía: así no cobra uno que no sale.
func dash_ready() -> bool:
	return body.state == BalanceBody.State.STANDING and _shove_left <= 0.0 and _dash_left <= 0.0 \
			and body.move.length() > 0.1 and dash_fuel >= body.kinematic_settings().dash_cost and _dash_wait <= 0.0


## LO QUE QUEDA DEBAJO de la caja cuando baja (agachándose, o cayendo): se achata.
func _squash() -> void:
	var place := body_place()
	var under := place * Transform3D(Basis(), Vector3.DOWN * (body.size.y * 0.5 + 0.2))
	for other in AreaStrike.loose_in(get_world_3d().direct_space_state, _below, under):
		if other != body and StompFeet.is_under(other, place, body.size) and StompFeet.flatten(other, body):
			flattened += 1
