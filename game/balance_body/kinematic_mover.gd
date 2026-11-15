class_name KinematicMover
extends CharacterBody3D

## EL MOTOR DE LA MECA CINEMÁTICA (13/11/2026): la pieza que la mueve cuando es cinemática (ver BalanceBody `kinematic`).
## Es lo que se probó en el Laboratorio con el cubo, pasado a la meca de verdad (el usuario: «la meca cinemática, que
## ahora es distinta del laboratorio cinemático, probablemente habría que unificarla»).
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
## *Los golpes todavía no la mueven (ver BalanceBody.push_impulse): con movimiento discreto, falta decidir qué es un
## golpe.*

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
var _dash_velocity := Vector3.ZERO
## Cuánto lleva el dash (s), para su curva (ver KinematicSettings.dash_curve).
var _dash_clock := 0.0
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
	return body.hover * lerpf(1.0, KinematicSettings.current.crouch_share, crouched)


## El cilindro, del piso al techo de la caja.
func _fit() -> void:
	_cylinder.height = _hover_now() + body.size.y
	_holder.position.y = _cylinder.height * 0.5


## DÓNDE VA LA CAJA: sobre sus piernas, mirando como él.
func body_place() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, _yaw), global_position + Vector3.UP * (_hover_now() + body.size.y * 0.5))


## UN PASO (ver arriba): lo que se le pide, moverse con el motor, y lo que miden las piernas.
func step(delta: float) -> void:
	var k := KinematicSettings.current
	crouched = move_toward(crouched, 1.0 if body.crouch else 0.0, k.crouch_rate * delta)
	_fit()
	var grounded := is_on_floor()
	dash_fuel = minf(dash_fuel + delta / k.dash_refill, 1.0)
	if _dash_left > 0.0:
		# EN UN DASH: derecho, sin teclas ni gravedad.
		_dash_left -= delta
		velocity = _dash_velocity * _dash_rate(k, delta)
	else:
		var flat := _walk(k, delta, grounded)
		velocity = Vector3(flat.x, _rise(k, delta, grounded), flat.z)
		if body.dash and not _dash_was and body.move.length() > 0.1 and dash_fuel >= k.dash_cost:
			_dash(k, delta)
	_dash_was = body.dash
	_jump_was = body.jump
	_turn(k, delta)
	rotation.y = _yaw
	move_and_slide()
	# LO QUE MIDEN LAS PIERNAS (ver BodyLegs): el apoyo es el piso debajo, y va a la velocidad de costado.
	var real := get_real_velocity()
	body.grounded = is_on_floor()
	body.airborne = not body.grounded
	body.support = global_position
	body.support_speed = Vector3(real.x, 0.0, real.z)
	body.tilt = 0.0
	body.height = _hover_now()
	body.moves.rod_scale = (body.size.y * 0.5 + _hover_now()) / (body.size.y * 0.5 + body.hover)
	# Lo que queda debajo de la caja cuando baja, se achata (ver arriba).
	var bottom := global_position.y + _hover_now()
	if bottom < _last_bottom - 0.0001:
		_squash()
	_last_bottom = bottom


## MOVERSE: de costado, hacia la velocidad pedida, en `reach_time` (0: al instante). En el aire, nada.
func _walk(k: KinematicSettings, delta: float, grounded: bool) -> Vector3:
	if not grounded:
		return Vector3.ZERO
	var wanted := Basis(Vector3.UP, _yaw) * Vector3(body.move.x, 0.0, -body.move.y).limit_length(1.0) * k.walk_speed
	if k.reach_time <= 0.0:
		return wanted
	return Vector3(velocity.x, 0.0, velocity.z).move_toward(wanted, k.walk_speed / k.reach_time * delta)


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
		# Las toberas de abajo, prendidas (sólo se ven).
		body.nozzles.push(Vector3.UP * body.knobs.nozzle_push * body.mass, Vector3.ZERO, body.knobs)
		return k.fly_speed
	return velocity.y - gravity * delta


## EL DASH: hacia donde se pide (en el espacio de la caja), `dash_distance` en `dash_time`.
func _dash(k: KinematicSettings, delta: float) -> void:
	var stick := Vector3(body.move.x, 0.0, -body.move.y).normalized()
	var way := Basis(Vector3.UP, _yaw) * stick
	_dash_velocity = way * (k.dash_distance / k.dash_time)
	_dash_left = k.dash_time
	_dash_clock = 0.0
	velocity = _dash_velocity * _dash_rate(k, delta)
	dash_fuel -= k.dash_cost
	body.nozzles.show(way, k.dash_time)


## Por cuánto multiplicar la velocidad pareja del dash este paso, según su curva (a la mitad del paso; lineal: 1).
func _dash_rate(k: KinematicSettings, delta: float) -> float:
	var rate := MoveCurve.rate(k.dash_curve, (_dash_clock + delta * 0.5) / k.dash_time)
	_dash_clock += delta
	return rate


## EL GIRO: hacia `aim_yaw`, con tope de velocidad y de aceleración. Nada lo traba: contra el mundo es un cilindro.
func _turn(k: KinematicSettings, delta: float) -> void:
	var error := clampf(wrapf(body.aim_yaw - _yaw, -PI, PI), -BalanceBody.AIM_LEAD, BalanceBody.AIM_LEAD)
	body.aim_yaw = _yaw + error
	var top := deg_to_rad(k.turn_speed)
	_yaw_speed = move_toward(_yaw_speed, clampf(error * 6.0, -top, top), deg_to_rad(k.turn_accel) * delta)
	_yaw += _yaw_speed * delta


## LA PONE en `where` (el punto del piso debajo de su centro), quieta, sin barrer el camino (ver StompFeet.place_now).
func put(where: Transform3D) -> void:
	global_position = where.origin
	_yaw = where.basis.get_euler().y
	rotation.y = _yaw
	body.aim_yaw = _yaw
	_yaw_speed = 0.0
	velocity = Vector3.ZERO
	_dash_left = 0.0
	_last_bottom = global_position.y + _hover_now()


## Cuánto se mueve de costado (m/s), para el cartel.
func speed() -> float:
	return Vector2(velocity.x, velocity.z).length()


## LO QUE QUEDA DEBAJO de la caja cuando baja (agachándose, o cayendo): se achata.
func _squash() -> void:
	var place := body_place()
	var under := place * Transform3D(Basis(), Vector3.DOWN * (body.size.y * 0.5 + 0.2))
	for other in AreaStrike.loose_in(get_world_3d().direct_space_state, _below, under):
		if other != body and StompFeet.is_under(other, place, body.size) and StompFeet.flatten(other):
			flattened += 1
