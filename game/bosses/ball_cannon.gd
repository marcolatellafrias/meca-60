class_name BallCannon
extends Node3D

## EL CAÑÓN DEL JEFE BOLA (13/11/2026), PASO 2: corre por la rendija, que da toda la vuelta de adelante, por arriba,
## hacia atrás. Apunta SÓLO PARA ARRIBA Y PARA ABAJO; de costado apunta la bola entera, girando con las patas (el
## usuario: «la rendija es en la otra dirección, si quiere rotar en y, va a usar las piernas»). Todavía no dispara.
##
## Cuelga del centro de la bola y gira sobre el eje de la rendija (su X): a 0° mira adelante, a 90° al cielo y a 180°
## atrás. Va hacia el ángulo pedido con tope de velocidad, y da la vuelta entera si se le pide.
##
## LOS TIROS (paso 3), por ProjectileField (por red, como los misiles de la arena):
##   · EL SIMPLE (`shoot`): derecho adonde apunta, hasta lo primero que encuentra (Missile.Kind.SHELL).
##   · LOS DEL CIELO (`barrage`): el cañón sube a 90°, tira UNO TRAS OTRO (es un solo cañón: no es una lluvia, es una
##     sucesión; el usuario: «tendría más sentido que no sea una lluvia sino una sucesión de misiles del cielo») y vuelve
##     adonde estaba. Cada uno es un mortero (Missile.Kind.MORTAR) que cae de arriba sobre su punto, con su marca.
##
## HECHA BOLA SE METE (`tuck`, de 0 a 1): corre hacia adentro por su eje hasta quedar dentro de la rendija (el usuario:
## «el cañón se tiene que meter también»).

## Exagerado, como de tanque (el usuario: «más exagerado y agregale un cilindro más grande… en la punta así parece más
## un cañón de tanque»). El carro que va metido en la rendija (alto y fondo, m; el ancho es el de la rendija), el caño
## (radio y largo, m) y, en la punta, la boca más gruesa (radio y largo, m), con el hueco bien a la vista.
## *Después volvió a los anchos de antes, un poco más largo, con la boca más larga: «más larga la parte ensanchada en
## relación al largo del cañón, y volvamos a los anchos antes de la exageración (solamente un poco más largos)».*
const CARRIAGE := Vector2(5.0, 3.0)
const BARREL_RADIUS := 1.6
const BARREL_LENGTH := 12.0
const MUZZLE_RADIUS := 2.4
const MUZZLE_LENGTH := 5.5
## Hasta dónde llega el tiro simple si no encuentra nada (m).
const SHELL_RANGE := 400.0

## Hacia dónde apunta ahora (radianes, sobre la rendija; 0 adelante, positivo para arriba).
var pitch := 0.0
## Por dónde salen los tiros (ver ProjectileField): lo pone quien arma al jefe.
var field: ProjectileField = null
## Cuántos tiros salieron (para mirar).
var fired := 0

## Lo que le queda por tirar al cielo (los puntos donde caen) y cuánto falta para el próximo (s).
var _queue: Array[Vector3] = []
var _gap := 0.0
var _cooldown := 0.0
var _tip := 0.0


## LO ARMA en la bola de `radius`, con la rendija de `slit` de ancho y `depth` de fondo.
func build(radius: float, slit: float, depth: float) -> void:
	var bottom := radius - depth
	_tip = bottom + BARREL_LENGTH
	Clay.box(self, Vector3(slit * 0.9, CARRIAGE.x, CARRIAGE.y), Vector3(0.0, 0.0, -(bottom + CARRIAGE.y * 0.5 - 0.3)),
		Clay.DARK.lightened(0.15))
	Clay.cylinder(self, BARREL_RADIUS, BARREL_LENGTH, Vector3(0.0, 0.0, -(bottom + BARREL_LENGTH * 0.5)), Clay.YELLOW,
		Vector3(90.0, 0.0, 0.0))
	var tip := bottom + BARREL_LENGTH
	Clay.cylinder(self, MUZZLE_RADIUS, MUZZLE_LENGTH, Vector3(0.0, 0.0, -(tip - MUZZLE_LENGTH * 0.5)), Clay.YELLOW.darkened(0.15),
		Vector3(90.0, 0.0, 0.0))
	# El hueco, oscuro, para ver adónde mira.
	Clay.cylinder(self, BARREL_RADIUS * 0.8, 0.3, Vector3(0.0, 0.0, -(tip + 0.1)), Clay.DARK.darkened(0.5),
		Vector3(90.0, 0.0, 0.0))


## UN PASO: hacia `aim` (radianes), por el camino más corto, a `pitch_speed` grados por segundo como mucho. Con tiros
## del cielo pendientes, apunta al cielo y los va tirando.
func step(k: BallBossSettings, aim: float, delta: float, tuck := 0.0) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	var wanted := PI * 0.5 if not _queue.is_empty() else aim
	var error := wrapf(wanted - pitch, -PI, PI)
	var most := deg_to_rad(k.pitch_speed) * delta
	pitch = wrapf(pitch + clampf(error, -most, most), -PI, PI)
	rotation = Vector3(pitch, 0.0, 0.0)
	# Metido: hacia adentro por su eje (su +Z), lo que mide el caño y el carro.
	position = basis.z * (BARREL_LENGTH + CARRIAGE.y) * smoothstep(0.0, 1.0, tuck)
	if _queue.is_empty() or absf(wrapf(PI * 0.5 - pitch, -PI, PI)) > deg_to_rad(2.0):
		return
	_gap -= delta
	if _gap <= 0.0:
		_gap = k.barrage_gap
		_launch(Missile.Kind.MORTAR, _queue.pop_front(), k.barrage_flight)


## Si está tirando al cielo.
func busy() -> bool:
	return not _queue.is_empty()


## EL TIRO SIMPLE: derecho adonde apunta, hasta lo primero que encuentra (o hasta `SHELL_RANGE`).
func shoot(k: BallBossSettings) -> void:
	if busy() or _cooldown > 0.0 or field == null:
		return
	_cooldown = k.shot_cooldown
	var start := muzzle().origin
	var way := -muzzle().basis.z
	var end := start + way * SHELL_RANGE
	var ray := PhysicsRayQueryParameters3D.create(start, end)
	var ball := get_parent() as CollisionObject3D
	if ball != null:
		ray.exclude = [ball.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		end = hit["position"]
	_launch(Missile.Kind.SHELL, end, start.distance_to(end) / k.shell_speed)


## LOS DEL CIELO: uno tras otro, en los puntos de `targets` (mundo), en ese orden.
func barrage(k: BallBossSettings, targets: Array[Vector3]) -> void:
	if busy() or _cooldown > 0.0 or field == null:
		return
	_cooldown = k.shot_cooldown
	_queue = targets.duplicate()
	_gap = 0.0


## Deja de tirar los del cielo que le quedaban.
func cancel() -> void:
	_queue.clear()


## Por dónde sale un tiro (mundo): la boca, mirando hacia afuera (su −Z).
func muzzle() -> Transform3D:
	return global_transform * Transform3D(Basis(), Vector3(0.0, 0.0, -_tip))


func _launch(kind: Missile.Kind, to: Vector3, flight: float) -> void:
	fired += 1
	field.launch(kind, muzzle().origin, to, maxf(flight, 0.05))
