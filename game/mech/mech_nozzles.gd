class_name MechNozzles
extends RefCounted

## LAS TOBERAS DE LA MECA: cuatro por cara; cada una empuja hacia adentro de su cara, en su lugar, y echa el humo de
## propulsor. Sólo empujan (no tiran) y tienen tope (`nozzle_push`): lo que no alcanza, no se hace. Sirven para dos
## cosas:
##   · LEVANTARSE (`get_up`), cuando se cayó: SUBIENDO Y ENDEREZÁNDOSE A LA VEZ. Las de la cara que mira al piso la
##     suben y las de los costados la enderezan TANTO COMO EL LUGAR LE DEJA —mira cuánto baja su punto más bajo, tal
##     como está girada, y gira sólo con lo que le sobra de altura—. Lo pidió el usuario el 12/11/2026 («primero se
##     levanta y después se endereza… prefiero… algo un poco más continuo»).
##   · EL PROPULSOR (`push` hacia arriba, ver MechMoves).
## Quien pide un empuje lo suma al `throttle` de cada tobera; `fire`, una vez por paso, lo aplica y lo muestra.

## Qué tan cerca de las esquinas van (parte de la mitad del lado).
const SPREAD := 0.65
## ENDEREZARSE SEGÚN EL LUGAR: lo que tiene que sobrar entre su punto más bajo y el piso para empezar a girar (m), y en
## cuántos metros más gira con todo.
const RIGHT_ROOM := 0.3
const RIGHT_BAND := 1.0

var _mech: Mech = null
var _all: Array[Dictionary] = []


## Las arma en `holder` (el dibujo de la meca): su lugar en la caja, hacia dónde echa (afuera de su cara), su malla y
## su humo.
func _init(mech: Mech, holder: Node3D) -> void:
	_mech = mech
	var half := Mech.SIZE * 0.5
	for normal: Vector3 in [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]:
		# Dos ejes sobre la cara.
		var u := normal.cross(Vector3.UP if absf(normal.y) < 0.5 else Vector3.RIGHT).normalized()
		var v := normal.cross(u).normalized()
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
			var at := normal * half + (u * corner.x + v * corner.y) * half * SPREAD
			var mount := Node3D.new()
			mount.transform = Transform3D(Basis.looking_at(normal, v), at)
			holder.add_child(mount)
			var mouth := Clay.cylinder(mount, 0.45, 0.6, Vector3(0, 0, -0.2), Clay.DARK, Vector3(90, 0, 0))
			var glow := StandardMaterial3D.new()
			glow.albedo_color = Clay.DARK
			glow.emission = Color(1.0, 0.55, 0.15)
			mouth.material_override = glow
			# El humo sale hacia −Z del emisor: hacia afuera de la cara.
			var smoke := ParticleSystems.thruster_smoke(ParticleMeshes.Kind.SPHERE, 4.0)
			smoke.emitting = false
			smoke.position = Vector3(0, 0, -0.5)
			mount.add_child(smoke)
			_all.append({"at": at, "out": normal, "smoke": smoke, "glow": glow, "throttle": 0.0})


## Al empezar el paso: nadie pidió nada todavía.
func rest() -> void:
	for nozzle in _all:
		nozzle["throttle"] = 0.0


## ── LEVANTARSE ───────────────────────────────────────────────────────────────────────────────────────────────────

func get_up(k: MechSettings) -> void:
	_lift(k)
	_right_as_room_allows(k)


## SUBIR: las que empujan para arriba (las de la cara que mira al piso) llevan el centro a la altura de ir parada, con
## un resorte y la gravedad compensada.
func _lift(k: MechSettings) -> void:
	var target := k.hover_height * k.lift_share + Mech.SIZE * 0.5
	_mech.height = _mech.ground_distance(_mech.global_position)
	var accel := k.lift_kp * (target - _mech.height) - k.lift_kd * _mech.linear_velocity.y + Mech.gravity()
	push(Vector3.UP * maxf(accel, 0.0) * Mech.MASS, Vector3.ZERO, k)


## ENDEREZARSE TANTO COMO EL LUGAR LE DEJA: su punto más bajo está, debajo del centro, a medio lado por la suma de lo
## que «abajo» tiene de cada eje de la caja (4 m apoyada en una cara, 5,7 en un canto, 6,9 en una punta). Con lo que le
## sobra de altura sobre eso gira (`RIGHT_ROOM`, `RIGHT_BAND`); con lo que no, frena el giro. Girar la lleva a un canto
## o a una punta, que bajan más: se regula sola, y sube y se endereza de corrido.
func _right_as_room_allows(k: MechSettings) -> void:
	var down := _mech.global_basis.inverse() * Vector3.DOWN
	var lowest := Mech.SIZE * 0.5 * (absf(down.x) + absf(down.y) + absf(down.z))
	var room := clampf((_mech.height - lowest - RIGHT_ROOM) / RIGHT_BAND, 0.0, 1.0)
	var up := _mech.global_basis.y.normalized()
	var error_axis := up.cross(Vector3.UP)
	var angle := up.angle_to(Vector3.UP)
	# Dada vuelta (el eje se pierde cerca de 180°), gira igual hacia algún lado.
	var axis := error_axis.normalized() if error_axis.length() > 0.0001 else _mech.global_basis.x
	push(Vector3.ZERO, (axis * angle * k.right_kp - _mech.angular_velocity * k.right_kd) * _mech.inertia() * room, k)
	push(Vector3.ZERO, -_mech.angular_velocity * 2.0 * _mech.inertia() * (1.0 - room), k)


## ── EMPUJAR ──────────────────────────────────────────────────────────────────────────────────────────────────────

## REPARTE ENTRE LAS TOBERAS una fuerza (`force`, en el mundo) y un giro (`torque`): para la fuerza, las que empujan
## para su lado; para el giro, cada una según cuánto gira para el lado pedido. Se suman en el `throttle` de cada una.
func push(force: Vector3, torque: Vector3, k: MechSettings) -> void:
	var most := k.nozzle_push * Mech.MASS
	var basis := _mech.global_basis
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


## Las toberas empujan, en su lugar, y se ven: brillan y echan humo.
func fire(k: MechSettings) -> void:
	var most := k.nozzle_push * Mech.MASS
	var basis := _mech.global_basis
	for nozzle in _all:
		var throttle := float(nozzle["throttle"])
		var smoke := nozzle["smoke"] as GPUParticles3D
		var glow := nozzle["glow"] as StandardMaterial3D
		glow.emission_enabled = throttle > 0.02
		glow.emission_energy_multiplier = throttle * 4.0
		smoke.emitting = throttle > 0.05
		if throttle <= 0.0:
			continue
		_mech.apply_force(-(basis * (nozzle["out"] as Vector3)) * most * throttle, basis * (nozzle["at"] as Vector3))
