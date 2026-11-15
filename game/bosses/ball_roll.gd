class_name BallRoll
extends RefCounted

## HECHA BOLA (13/11/2026), PASO 4: el jefe bola mete las patas adentro, baja hasta el piso y rueda. Lo pensó el usuario:
## «podemos hacer que se haga una bola y gire más rápido… que retraiga los brazos»; las patas «se meten adentro», «puede
## doblar», «Shift» lo cambia, y «que haga daño al tocar».
##   · PLEGARSE (`fold`, de 0 a 1, en `fold_time`): las patas se acortan hacia adentro de la bola y la bola baja hasta
##     apoyarse. Al abrirse, al revés: las patas salen hacia su lugar en el piso.
##   · RODAR: sólo hecha bola del todo. CON RAMPAS (MoveRamp, las curvas de la base común; 14/11/2026, el usuario: «se
##     siente muy soso… siempre anda igual a la misma velocidad»): W la lleva a `roll_speed` en `roll_up_time`, con su
##     curva (arranca pesada); SOLTANDO SIGUE RODANDO y se apaga en `roll_coast_time` (la inercia); S frena en
##     `roll_brake_time` (y va un poco para atrás). A/D y el mouse doblan, y CUANTO MÁS RÁPIDO, MENOS DOBLA. Contra una
##     pared pierde lo que no pudo avanzar. La bola se ve girar según lo que avanza (ángulo = camino / radio).
##   · PEGA AL TOCAR (sin vida: todo es equilibrio): lo suelto que toca la bola rodando a más de `hit_min_speed` sale
##     despedido, con un cambio de velocidad de hasta `hit_push` según lo rápido que iba (ver BalanceBody.hit: a una
##     meca, su péndulo decide si cae). A cada cosa, una vez por toque (`REHIT` s).

## Cuánto tiene que pasar para volver a pegarle a lo mismo (s).
const REHIT := 0.6
## Cuánto más allá de la bola busca qué toca (m).
const TOUCH := 1.0

## Cuán plegada está (0: parada en sus patas; 1: hecha bola).
var fold := 0.0
## A cuánto rueda hacia adelante (m/s; para atrás, negativo).
var speed := 0.0
## Cuánto giró rodando (en el mundo): se le suma al giro de la bola.
var spin := Quaternion.IDENTITY
## Cuántas veces pegó (para mirar).
var hits := 0

var _clock := 0.0
var _last_hit := {}
var _ramp := MoveRamp.new()


## Si está hecha bola del todo (rueda).
func rolling() -> bool:
	return fold >= 1.0


## UN PASO: se pliega o se abre hacia `curl`, y devuelve la velocidad de costado (mundo) con que rueda hacia `heading`.
func step(k: BallBossSettings, delta: float, curl: bool, push: float, heading: Vector3) -> Vector3:
	_clock += delta
	fold = move_toward(fold, 1.0 if curl else 0.0, delta / maxf(k.fold_time, 0.05))
	var wanted := clampf(push, -0.4, 1.0) if rolling() else 0.0
	# Frenar es pedir lo contrario de para donde va (o abrirse: ahí también frena); soltar es dejarla rodar.
	var braking := (not rolling()) or (wanted * _ramp.level < 0.0)
	var down_time := k.roll_brake_time if braking else k.roll_coast_time
	var down_shape := k.roll_brake_shape if braking else k.roll_coast_shape
	speed = _ramp.step(delta, wanted, k.roll_up_time, k.roll_up_shape, down_time, down_shape) * k.roll_speed
	return heading * speed


## LO QUE DE VERDAD AVANZÓ hacia adelante (m/s): si chocó y avanzó menos, la rampa baja hasta ahí.
func moved(forward: float, k: BallBossSettings) -> void:
	if absf(forward) < absf(speed) - 0.5:
		_ramp.level = clampf(forward / maxf(k.roll_speed, 0.01), -1.0, 1.0)
		speed = _ramp.level * k.roll_speed


## Cuánto dobla ahora (°/s): menos cuanto más rápido va.
func turn_rate(k: BallBossSettings) -> float:
	return lerpf(k.roll_turn, k.roll_turn_fast, absf(_ramp.level))


## LA BOLA GIRA según lo que avanzó (`flat`, m/s); abriéndose, vuelve derecha.
func turn_ball(flat: Vector3, radius: float, delta: float) -> void:
	if fold > 0.0 and flat.length_squared() > 0.0001:
		var axis := Vector3.UP.cross(flat.normalized())
		spin = (Quaternion(axis, flat.length() / radius * delta) * spin).normalized()
	if fold < 1.0:
		spin = spin.slerp(Quaternion.IDENTITY, clampf(6.0 * delta, 0.0, 1.0))


## PEGA a lo suelto que toca la bola en `center`, rodando a `flat`.
func strike(k: BallBossSettings, space: PhysicsDirectSpaceState3D, center: Vector3, radius: float, flat: Vector3) -> void:
	var fast := flat.length()
	if fold <= 0.0 or fast < k.hit_min_speed:
		return
	var sphere := SphereShape3D.new()
	sphere.radius = radius + TOUCH
	for body in AreaStrike.loose_in(space, sphere, Transform3D(Basis(), center)):
		var id := body.get_instance_id()
		if _clock - float(_last_hit.get(id, -100.0)) < REHIT:
			continue
		_last_hit[id] = _clock
		var away := (body.global_position - center).slide(Vector3.UP).normalized()
		var way := (away + flat / fast).normalized()
		way = (way * 0.8 + Vector3.UP * 0.2).normalized()
		BalanceBody.hit(body, way * k.hit_push * clampf(fast / k.roll_speed, 0.3, 1.0) * body.mass)
		hits += 1
