class_name BodyNozzles
extends RefCounted

## LAS TOBERAS DE UN CUERPO CON EQUILIBRIO (ver BalanceBody). DOS COSAS SEPARADAS (13/11/2026):
##   · LO QUE EMPUJA: cuatro toberas por cara, INVISIBLES; cada una empuja hacia adentro de su cara, en su lugar. Sólo
##     empujan (no tiran) y tienen tope (`nozzle_push`): lo que no alcanza, no se hace.
##   · LO QUE SE VE: CUATRO TOBERAS EN LAS ESQUINAS DE ABAJO (`_shown`), chunky, que GIRAN JUNTAS EN SU RÓTULA hacia
##     el lado contrario de lo que empujan las invisibles y echan su llama (ThrusterFlame) y el humo de propulsor. El
##     usuario, 13/11/2026: «nos vamos a quedar con los tobares de estos solamente… son más estéticos»; eligió las
##     cuatro de las esquinas entre varias maquetas (`tests/nozzle_ideas_look.tscn`), «más chunky y que no sobresalgan
##     tanto para abajo». *Hasta entonces se veían las veinticuatro de las caras, y tapaban el vidrio.*
## Lo que empuja sirve para dos cosas:
##   · LEVANTARSE (`get_up`), cuando se cayó: SUBIENDO Y ENDEREZÁNDOSE A LA VEZ. Las de la cara que mira al piso la
##     suben y las de los costados la enderezan TANTO COMO EL LUGAR LE DEJA —mira cuánto baja su punto más bajo, tal
##     como está girada, y gira sólo con lo que le sobra de altura—. Lo pidió el usuario el 12/11/2026 («primero se
##     levanta y después se endereza… prefiero… algo un poco más continuo»).
##   · EL PROPULSOR (`push` hacia arriba, ver BodyMoves).
## Quien pide un empuje lo suma al `throttle` de cada tobera; `fire`, una vez por paso, lo aplica y lo muestra.

## LAS QUE SE VEN: cuánto adentro de las esquinas van (m, en la caja de siempre), lo más que se inclinan desde abajo
## (grados) y qué tan rápido giran (por s).
const SHOWN_INSET := 0.8
const SHOWN_TILT := 40.0
const SHOWN_TURN := 8.0
## El humo de cada una, cuántas veces el de propulsor.
const SMOKE_SIZE := 2.5

## Qué tan cerca de las esquinas van (parte de la mitad del lado).
const SPREAD := 0.65
## ENDEREZARSE SEGÚN EL LUGAR: lo que tiene que sobrar entre su punto más bajo y el piso para empezar a girar (m), y en
## cuántos metros más gira con todo.
const RIGHT_ROOM := 0.3
const RIGHT_BAND := 1.0

var _body: BalanceBody = null
var _all: Array[Dictionary] = []
## Las cuatro que se ven: su rótula (la que gira), su llama y su humo.
var _shown: Array[Dictionary] = []
## Hasta cuándo se ven prendidas sin empujar (un dash), y hacia dónde empujan (en el mundo).
var _show_until := 0
var _show_way := Vector3.ZERO


## Las arma: las que empujan, en su lugar en la caja, hacia dónde echan (afuera de su cara); y las cuatro que se ven,
## colgadas de `holder` (el dibujo de la meca).
func _init(body: BalanceBody, holder: Node3D) -> void:
	_body = body
	var half := body.size * 0.5
	for normal: Vector3 in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		# Dos ejes sobre la cara.
		var u := normal.cross(Vector3.UP if absf(normal.y) < 0.5 else Vector3.RIGHT).normalized()
		var v := normal.cross(u).normalized()
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var at := normal * half + (u * corner.x + v * corner.y) * half * SPREAD
			_all.append({"at": at, "out": normal, "throttle": 0.0})
	var k := 1.0
	var corner := half.x - SHOWN_INSET * k
	if not body.show_nozzles:
		return
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			_shown.append(_build_shown(holder, Vector3(sx * corner, -half.y, sz * corner), k))


## UNA TOBERA QUE SE VE, en la esquina `at` de abajo: la base ancha y baja pegada a la caja, la rótula que gira con la
## campana corta y ancha, la llama y el humo. Del tamaño `k` (por ahora, siempre el mismo).
func _build_shown(holder: Node3D, at: Vector3, k: float) -> Dictionary:
	var steel := Color(0.3, 0.31, 0.34)
	var base := Node3D.new()
	base.position = at
	base.scale = Vector3.ONE * k
	holder.add_child(base)
	Clay.box(base, Vector3(1.7, 0.3, 1.7), Vector3(0, -0.15, 0), steel)
	var ball := Node3D.new()
	ball.position = Vector3(0, -0.55, 0)
	base.add_child(ball)
	Clay.sphere(ball, 0.55, Vector3.ZERO, steel)
	# La campana va sobre −Z de la rótula, que mira hacia donde echa.
	var bell := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.72
	cone.bottom_radius = 0.5
	cone.height = 0.7
	bell.mesh = cone
	bell.material_override = Clay.material(Clay.DARK)
	bell.rotation_degrees = Vector3(-90, 0, 0)
	bell.position = Vector3(0, 0, -0.55)
	ball.add_child(bell)
	var flame := ThrusterFlame.new()
	flame.position = Vector3(0, 0, -0.9)
	ball.add_child(flame)
	# El humo nace pasada la punta de la llama: encima, la tapaba.
	var smoke := ParticleSystems.thruster_smoke(ParticleMeshes.Kind.SPHERE, SMOKE_SIZE * k)
	smoke.emitting = false
	smoke.position = Vector3(0, 0, -0.9 - ThrusterFlame.LENGTH)
	ball.add_child(smoke)
	ball.basis = Basis.looking_at(Vector3.DOWN, Vector3.FORWARD)
	return {"ball": ball, "flame": flame, "smoke": smoke}


## SE VEN PRENDIDAS, SIN EMPUJAR, `seconds` segundos: las que empujan hacia `way` (mundo). Para lo que empuja con un
## impulso, como el dash.
func show(way: Vector3, seconds: float) -> void:
	_show_until = Time.get_ticks_msec() + int(seconds * 1000.0)
	_show_way = way


## Al empezar el paso: nadie pidió nada todavía.
func rest() -> void:
	for nozzle in _all:
		nozzle["throttle"] = 0.0


## ── LEVANTARSE ───────────────────────────────────────────────────────────────────────────────────────────────────

func get_up(k: BodySettings) -> void:
	_lift(k)
	_right_as_room_allows(k)


## SUBIR: las que empujan para arriba (las de la cara que mira al piso) llevan el centro a la altura de ir parada, con
## un resorte y la gravedad compensada.
func _lift(k: BodySettings) -> void:
	var target := _body.hover * k.lift_share + _body.size.y * 0.5
	_body.height = _body.ground_distance(_body.global_position)
	var accel := k.lift_kp * (target - _body.height) - k.lift_kd * _body.velocity().y + BalanceBody.gravity()
	push(Vector3.UP * maxf(accel, 0.0) * _body.mass, Vector3.ZERO, k)


## ENDEREZARSE TANTO COMO EL LUGAR LE DEJA: su punto más bajo está, debajo del centro, a medio lado por la suma de lo
## que «abajo» tiene de cada eje de la caja (4 m apoyada en una cara, 5,7 en un canto, 6,9 en una punta). Con lo que le
## sobra de altura sobre eso gira (`RIGHT_ROOM`, `RIGHT_BAND`); con lo que no, frena el giro. Girar la lleva a un canto
## o a una punta, que bajan más: se regula sola, y sube y se endereza de corrido.
func _right_as_room_allows(k: BodySettings) -> void:
	var down := _body.global_basis.inverse() * Vector3.DOWN
	var half := _body.size * 0.5
	var lowest := absf(down.x) * half.x + absf(down.y) * half.y + absf(down.z) * half.z
	var room := clampf((_body.height - lowest - RIGHT_ROOM) / RIGHT_BAND, 0.0, 1.0)
	var up := _body.global_basis.y.normalized()
	var error_axis := up.cross(Vector3.UP)
	var angle := up.angle_to(Vector3.UP)
	# Dada vuelta (el eje se pierde cerca de 180°), gira igual hacia algún lado.
	var axis := error_axis.normalized() if error_axis.length() > 0.0001 else _body.global_basis.x
	push(Vector3.ZERO, (axis * angle * k.right_kp - _body.angular_velocity * k.right_kd) * _body.inertia() * room, k)
	push(Vector3.ZERO, -_body.angular_velocity * 2.0 * _body.inertia() * (1.0 - room), k)


## ── EMPUJAR ──────────────────────────────────────────────────────────────────────────────────────────────────────

## REPARTE ENTRE LAS TOBERAS una fuerza (`force`, en el mundo) y un giro (`torque`): para la fuerza, las que empujan
## para su lado; para el giro, cada una según cuánto gira para el lado pedido. Se suman en el `throttle` de cada una.
func push(force: Vector3, torque: Vector3, k: BodySettings) -> void:
	var most := k.nozzle_push * _body.mass
	var basis := _body.global_basis
	if force.length() > 0.001:
		var lifters: Array[Dictionary] = []
		var share := 0.0
		for nozzle in _all:
			var pushes := -(basis * (nozzle["out"] as Vector3))
			var along := pushes.dot(force.normalized())
			if along > 0.7:
				lifters.append(nozzle)
				share += along
		for nozzle in lifters:
			nozzle["throttle"] = clampf(float(nozzle["throttle"]) + force.length() / maxf(share * most, 0.001), 0.0, 1.0)
	if torque.length() > 0.001:
		var wanted := torque.normalized()
		var arms: Array[float] = []
		var total := 0.0
		for nozzle in _all:
			var pushes := -(basis * (nozzle["out"] as Vector3)) * most
			var turns := (basis * (nozzle["at"] as Vector3)).cross(pushes)
			var useful := maxf(turns.dot(wanted), 0.0)
			arms.append(useful)
			total += useful
		for i in _all.size():
			if arms[i] > 0.0 and total > 0.0:
				_all[i]["throttle"] = clampf(float(_all[i]["throttle"]) + torque.length() / total, 0.0, 1.0)


## Las toberas empujan, en su lugar; y las que se ven giran hacia el lado contrario de lo que empujan entre todas, y
## echan su llama y su humo.
func fire(k: BodySettings) -> void:
	var most := k.nozzle_push * _body.mass
	var basis := _body.global_basis
	var total := Vector3.ZERO
	var strongest := 0.0
	for nozzle in _all:
		var throttle := float(nozzle["throttle"])
		if throttle <= 0.0:
			continue
		var pushes := -(basis * (nozzle["out"] as Vector3))
		_body.push_force(pushes * most * throttle, basis * (nozzle["at"] as Vector3))
		total += pushes * throttle
		strongest = maxf(strongest, throttle)
	if Time.get_ticks_msec() < _show_until:
		total += _show_way.normalized() * 2.0
		strongest = 1.0
	_aim(basis.inverse() * total, strongest)


## LAS QUE SE VEN: echan para abajo y, si lo que se empuja tiene un costado, se inclinan hacia el contrario, hasta
## `SHOWN_TILT`. Giran de a poco; prendidas según la que más empuja.
func _aim(push: Vector3, strength: float) -> void:
	var out := Vector3.DOWN
	var side := Vector3(push.x, 0.0, push.z)
	if strength > 0.02 and side.length() > 0.05 * push.length():
		var tilt := deg_to_rad(SHOWN_TILT) * clampf(side.length() / maxf(push.length(), 0.001) * 1.5, 0.0, 1.0)
		out = (Vector3.DOWN * cos(tilt) - side.normalized() * sin(tilt)).normalized()
	var wanted := Basis.looking_at(out, Vector3.FORWARD)
	var step := clampf(SHOWN_TURN * _body.get_physics_process_delta_time(), 0.0, 1.0)
	for nozzle in _shown:
		var ball := nozzle["ball"] as Node3D
		ball.basis = Basis(ball.basis.get_rotation_quaternion().slerp(wanted.get_rotation_quaternion(), step))
		(nozzle["flame"] as ThrusterFlame).throttle = strength
		(nozzle["smoke"] as GPUParticles3D).emitting = strength > 0.05
