class_name KinematicPillar
extends AnimatableBody3D

## EL CUBO CINEMÁTICO (13/11/2026) — EXPERIMENTO: una caja sobre dos pies, cinemática, para probar por separado CÓMO SE
## LLEVA LO CINEMÁTICO CON LO FÍSICO y la locomoción de la meca futura, sin la cabina, el ascensor ni el péndulo. El
## usuario: «un cubo alargado… y así yo pruebo los distintos approaches de interacción de cinemático con físico… vamos
## por partes»; «empezar a trabajar en todo lo de locomoción de la meca futura, pero con este cubo».
##
## SE MUEVE A MANO: Jolt no lo mueve; cada paso se pone donde calculó (el motor sabe su velocidad).
##   · MOVERSE: una velocidad y el tiempo para llegar a ella (PillarSettings). Sin correr.
##   · GIRAR: con tope de velocidad y de aceleración. NADA LO TRABA al girar: contra el mundo es un cilindro.
##   · EL DASH (Shift): un impulso hacia donde apretás, en el piso y en el aire, el mismo. SIN DIRECCIÓN NO PASA NADA.
##     Tiene su barra, que se llena sola. Un rato (`dash_hold`) moverse no lo frena.
##   · SALTAR (espacio) y EL VUELO (espacio otra vez, en el aire): empuja para arriba mientras le quede su barra, que se
##     llena apoyado.
##   · AGACHARSE (Ctrl): las piernas se acortan de a poco y el cubo baja.
##   · LAS TOBERAS (PillarNozzles): placeholder, sólo se ven.
##
## CON QUÉ CHOCA CADA COSA (13/11/2026, lo charlado con el usuario):
##   · CONTRA LO FIJO DEL MUNDO (edificios, paredes, el piso), UN CILINDRO más grande que el cubo, del piso al techo:
##     «para los obstáculos del mundo… va a ser cilíndrica la hitbox. Así evitamos que se trabe con cosas cuando gira».
##     Sólo se prueba contra lo fijo: lo suelto no lo frena nunca.
##   · CONTRA LO SUELTO, LO QUE SE VE, por el motor y sin reglas extra: la caja de arriba empuja lo alto, y LOS PIES
##     (PillarFeet) patean de costado y ACHATAN lo que pisan. *Se probaron cuatro reglas a mano (una «topadora con tope»,
##     entre ellas): la del tope arrastraba las cajas como un imán y las hacía saltar con el cubo —medía la velocidad de
##     la caja respecto del cubo, y un cubo que se aleja es lo mismo que una caja que se aleja—; se sacaron las cuatro.*
##   · LO QUE QUEDA DEBAJO de algo suyo que baja (un pie, o la caja al agacharse o al caer) SE ACHATA, no se aprieta:
##     apretar algo suelto contra el piso con algo que pesa infinito era lo que hacía explotar al motor.

## La caja de arriba: ancho, alto y fondo (m). Y el radio del cilindro contra lo fijo: la caja entra entera.
const TORSO := Vector3(6.0, 12.0, 6.0)
const RADIUS := 4.6
## El margen con que se prueba el cilindro sobre el piso (m; ver `_move`).
const SKIN := 0.05

## ── LO QUE SE LE PIDE ──
var move := Vector2.ZERO
var crouch := false
var jump := false
var dash := false
var aim_yaw := 0.0

## ── LO QUE MIDE ──
var velocity := Vector3.ZERO
var grounded := false
## Cuánto está agachado (0 a 1), a qué altura va la cara de abajo de la caja y su alto entero.
var crouched := 0.0
var hip := 6.0
var height := 18.0
## Las barras (0 a 1): la del dash y la del vuelo.
var dash_fuel := 1.0
var fly_fuel := 1.0
var feet: PillarFeet = null
## Cuántas cosas acható con la caja (las de los pies, en `feet.flattened`).
var flattened := 0

## Dónde está (el punto del piso debajo de su centro): lo guarda él, no lo lee del nodo (ver `put`).
var _at := Vector3.ZERO
var _yaw := 0.0
var _yaw_speed := 0.0
var _jump_was := false
var _dash_was := false
var _fly_armed := false
var _dash_clock := 0.0
var _nozzles: PillarNozzles = null
var _holder: CollisionShape3D = null
var _look: Node3D = null
var _cylinder := CylinderShape3D.new()
var _below := BoxShape3D.new()
var _last_hip := 0.0
var _driving := false
var _chase_yaw := 0.0


func _init() -> void:
	sync_to_physics = true


func _ready() -> void:
	_holder = Clay.shape_box(self, TORSO, Vector3.ZERO)
	_look = Node3D.new()
	add_child(_look)
	Clay.box(_look, TORSO, Vector3.ZERO, Clay.METAL.darkened(0.1))
	# El frente, para saber hacia dónde mira.
	Clay.box(_look, Vector3(TORSO.x * 0.6, 0.8, 0.3), Vector3(0.0, TORSO.y * 0.4, -TORSO.z * 0.5 - 0.1), Clay.YELLOW)
	_nozzles = PillarNozzles.new()
	add_child(_nozzles)
	_nozzles.build(TORSO)
	_nozzles.fit(TORSO.y)
	feet = PillarFeet.new()
	feet.born_at = Transform3D(Basis(), global_position + Vector3.UP * PillarFeet.FOOT.y * 0.5)
	add_child(feet)
	_cylinder.radius = RADIUS
	_below.size = Vector3(TORSO.x, 0.6, TORSO.z)
	_yaw = global_rotation.y
	_at = global_position
	aim_yaw = _yaw
	_fit(PillarSettings.current)
	_last_hip = _at.y + hip
	feet.place_now(PillarSettings.current, _at, _yaw)
	add_to_group(SandboxPossession.GROUP)


func _physics_process(delta: float) -> void:
	var k := PillarSettings.current
	_read()
	var place := _at
	# AGACHARSE: las piernas se acortan de a poco.
	crouched = move_toward(crouched, 1.0 if crouch else 0.0, k.crouch_rate * delta)
	_fit(k)
	# MOVERSE (ver PillarSettings): hacia la velocidad pedida, en `reach_time` (0: al instante); en el aire, con su
	# parte de control.
	var wanted := Basis(Vector3.UP, _yaw) * Vector3(move.x, 0.0, -move.y).limit_length(1.0) * k.walk_speed
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var control := 1.0 if grounded else k.air_control
	_dash_clock = maxf(_dash_clock - delta, 0.0)
	# Recién salido de un dash, moverse no lo frena.
	if _dash_clock > 0.0 and flat.length() > wanted.length():
		control = 0.0
	if control > 0.0:
		if k.reach_time <= 0.0 and control >= 1.0:
			flat = wanted
		else:
			flat = flat.move_toward(wanted, k.walk_speed / maxf(k.reach_time, 0.05) * control * delta)
	velocity = Vector3(flat.x, velocity.y, flat.z)
	# EL DASH: al apretar, con una dirección y con barra.
	dash_fuel = minf(dash_fuel + delta / k.dash_refill, 1.0)
	if dash and not _dash_was and move.length() > 0.1 and dash_fuel >= k.dash_cost:
		_dash(k)
	_dash_was = dash
	# SALTAR (al apretar) Y CAER; EL VUELO, en el aire, apretando otra vez.
	var gravity := BalanceBody.gravity()
	if jump and not _jump_was and grounded:
		velocity.y = sqrt(2.0 * gravity * k.air_gravity * k.jump_height)
		grounded = false
		_fly_armed = false
	_jump_was = jump
	if grounded:
		fly_fuel = minf(fly_fuel + delta / k.thrust_refill, 1.0)
	else:
		if not jump:
			_fly_armed = true
		var flying := jump and _fly_armed and fly_fuel > 0.0
		if flying:
			fly_fuel = maxf(fly_fuel - delta / k.thrust_time, 0.0)
			velocity.y += k.thrust * delta
			_nozzles.fly(1.0)
		# Volando pesa lo de siempre (como la meca: si no, no la levantaría); si no, lo del aire.
		velocity.y -= gravity * (1.0 if flying else k.air_gravity) * delta
	# MOVERSE PROBANDO, con el cilindro y sólo contra lo fijo: de costado y, aparte, para arriba o abajo.
	place = _move(place, Vector3(velocity.x, 0.0, velocity.z) * delta)
	var moved := _move(place, Vector3.UP * velocity.y * delta)
	if velocity.y < 0.0 and moved.y > place.y + velocity.y * delta + 0.0001:
		velocity.y = 0.0
		grounded = true
	place = moved
	if grounded:
		# Sigue apoyado si abajo, cerca, hay algo fijo; si no, cae.
		if _move(place, Vector3.DOWN * 0.1).y < place.y - 0.09:
			grounded = false
		velocity.y = minf(velocity.y, 0.0)
	_turn(k, delta)
	_at = place
	global_transform = Transform3D(Basis(Vector3.UP, _yaw), place + Vector3.UP * (hip + TORSO.y * 0.5))
	# LO QUE QUEDA DEBAJO DE LA CAJA CUANDO BAJA, se achata (ver arriba).
	if place.y + hip < _last_hip - 0.0001:
		_squash()
	_last_hip = place.y + hip
	feet.step(k, delta, _floor_under(place), _yaw, Vector3(velocity.x, 0.0, velocity.z), grounded, place.y + hip - _floor_under(place).y)
	_nozzles.show_flames(delta)


## Las medidas de ahora: las piernas (enteras o agachado) y el alto entero; el cilindro, del piso al techo.
func _fit(k: PillarSettings) -> void:
	hip = k.leg_height * lerpf(1.0, k.crouch_share, crouched)
	height = hip + TORSO.y
	_cylinder.height = height
	_nozzles.position.y = -TORSO.y * 0.5


## El punto del piso debajo de `place` (lo fijo), para apoyar los pies; en el aire, colgando a la altura de las piernas.
func _floor_under(place: Vector3) -> Vector3:
	if grounded:
		return place
	var query := PhysicsRayQueryParameters3D.create(place + Vector3.UP, place + Vector3.DOWN * 2.0)
	query.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty() and hit["collider"] is StaticBody3D and not hit["collider"] is AnimatableBody3D:
		return hit["position"]
	return place


## EL DASH: hacia donde se pide (en el espacio del cubo), suma `dash_speed` a lo que ya iba para allá; en el aire,
## además, sube a `dash_lift`.
func _dash(k: PillarSettings) -> void:
	var stick := Vector3(move.x, 0.0, -move.y).normalized()
	var way := Basis(Vector3.UP, _yaw) * stick
	var flat := Vector3(velocity.x, 0.0, velocity.z)
	var along := maxf(flat.dot(way), 0.0)
	var sideways := flat - way * flat.dot(way)
	var now := sideways + way * (along + k.dash_speed)
	velocity = Vector3(now.x, velocity.y if grounded else maxf(velocity.y, k.dash_lift), now.z)
	dash_fuel -= k.dash_cost
	_dash_clock = k.dash_hold
	_nozzles.dash(stick)


## LO PONE en `where` (el punto del piso debajo de su centro), quieto. *Con la física sincronizada, poner su posición
## desde afuera no alcanza: el cuerpo la pisa con la suya (medido: el test lo reiniciaba y seguía donde había quedado).*
func put(where: Transform3D) -> void:
	_at = where.origin
	_yaw = where.basis.get_euler().y
	aim_yaw = _yaw
	_yaw_speed = 0.0
	velocity = Vector3.ZERO
	grounded = false
	_last_hip = _at.y + hip
	feet.place_now(PillarSettings.current, _at, _yaw)
	# Él también, sin barrer el camino (ver PillarFeet.place_now).
	sync_to_physics = false
	global_transform = Transform3D(Basis(Vector3.UP, _yaw), _at + Vector3.UP * (hip + TORSO.y * 0.5))
	sync_to_physics = true


## EL GIRO: hacia `aim_yaw`, con tope de velocidad y de aceleración. Nada lo traba: contra el mundo es un cilindro.
func _turn(k: PillarSettings, delta: float) -> void:
	var error := clampf(wrapf(aim_yaw - _yaw, -PI, PI), -PI * 0.6, PI * 0.6)
	aim_yaw = _yaw + error
	var top := deg_to_rad(k.turn_speed)
	_yaw_speed = move_toward(_yaw_speed, clampf(error * 6.0, -top, top), deg_to_rad(k.turn_accel) * delta)
	_yaw += _yaw_speed * delta


## ── CONTRA LO FIJO: EL CILINDRO ──────────────────────────────────────────────────────────────────────────────────

## MOVERSE PROBANDO: `motion` desde `from` (el punto del piso). EL CILINDRO SE PRUEBA LEVANTADO `SKIN` del piso: una
## prueba que arranca tocando algo no lo cuenta como choque, y apoyado justo en el piso lo atravesaba (medido el
## 13/11/2026: caía sin fin). Bajando, la prueba se alarga ese mismo `SKIN`, así frena justo en el piso.
func _move(from: Vector3, motion: Vector3) -> Vector3:
	if motion.length_squared() < 0.00000001:
		return from
	if motion.y < 0.0:
		return _cast(from + Vector3.UP * SKIN, motion + Vector3.DOWN * SKIN)
	return _cast(from + Vector3.UP * SKIN, motion) - Vector3.UP * SKIN


## La prueba: el cilindro con su base en `from`, hasta `motion`. Contra lo fijo se desliza y pierde la velocidad que iba
## contra eso; lo suelto se saltea. Devuelve dónde queda su base.
func _cast(from: Vector3, motion: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = _cylinder
	query.collision_mask = 1
	query.margin = 0.01
	var skip: Array[RID] = [get_rid()]
	skip.append_array(feet.rids())
	# Lo suelto se saltea de a uno: con pocas vueltas, una pila de más cajas que vueltas hacía de pared (medido).
	for attempt in 256:
		query.exclude = skip
		query.transform = Transform3D(Basis(), from + Vector3.UP * height * 0.5)
		query.motion = motion
		var reach := space.cast_motion(query)
		if reach[1] >= 1.0:
			return from + motion
		# Qué lo frenó, un poco más allá de hasta donde llegó.
		query.transform.origin += motion * reach[1]
		query.motion = Vector3.ZERO
		var info := space.get_rest_info(query)
		if info.is_empty():
			return from + motion * reach[0]
		var other := instance_from_id(int(info["collider_id"]))
		if not (other is StaticBody3D and not other is AnimatableBody3D):
			skip.append(info["rid"])
			continue
		var normal: Vector3 = info["normal"]
		var into := velocity.dot(normal)
		if into < 0.0 and absf(normal.y) < 0.5:
			velocity -= normal * into
		from += motion * reach[0]
		motion = (motion * (1.0 - reach[0])).slide(normal)
		if motion.length_squared() < 0.00000001:
			return from
	return from


## ── CONTRA LO SUELTO ─────────────────────────────────────────────────────────────────────────────────────────────

## LO QUE QUEDA DEBAJO de la caja cuando baja (agachándose, o cayendo): se achata.
func _squash() -> void:
	var under := global_transform * Transform3D(Basis(), Vector3.DOWN * (TORSO.y * 0.5 + 0.2))
	for body in AreaStrike.loose_in(get_world_3d().direct_space_state, _below, under):
		if PillarFeet.is_under(body, global_transform, TORSO) and PillarFeet.flatten(body):
			flattened += 1


## ── POSEERLO (ver SandboxPossession) ─────────────────────────────────────────────────────────────────────────────

func _read() -> void:
	var mine := _driving and UIState.gameplay_active()
	if not mine:
		return
	move = Vector2(MechKeys.axis(KEY_D, KEY_A), MechKeys.axis(KEY_W, KEY_S))
	crouch = Input.is_physical_key_pressed(KEY_CTRL)
	jump = Input.is_physical_key_pressed(KEY_SPACE)
	dash = Input.is_physical_key_pressed(KEY_SHIFT)


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if not _driving or motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	aim_yaw -= motion.relative.x * 0.0025 * GameOptions.mouse_sensitivity
	get_viewport().set_input_as_handled()


func possess_name() -> String:
	return "Cubo cinemático"


func possess_controls() -> PackedStringArray:
	return PackedStringArray([
		"W/S adelante y atrás · A/D de costado · mouse gira (con tope)",
		"Ctrl se agacha (baja de a poco) · espacio salta",
		"en el aire, espacio otra vez: vuela (su barra se llena apoyado)",
		"Shift con una dirección: dash, en el piso y en el aire (su barra se llena sola)",
	])


func possess_status() -> String:
	return "dash %s   vuelo %s\n%.1f m/s · alto %.1f m%s · acható %d" % [BodyMoves._bar(dash_fuel),
		BodyMoves._bar(fly_fuel), Vector2(velocity.x, velocity.z).length(), height,
		"" if grounded else " · en el aire", flattened + feet.flattened]


func possess_begin() -> void:
	_driving = true
	_chase_yaw = _yaw


func possess_end() -> void:
	_driving = false
	move = Vector2.ZERO
	crouch = false
	jump = false
	dash = false


func possess_camera(first: bool, delta: float) -> Transform3D:
	if first:
		return Transform3D(Basis(Vector3.UP, _yaw), _at + Vector3.UP * (height + 1.5))
	_chase_yaw = lerp_angle(_chase_yaw, _yaw, 1.0 - exp(-4.0 * delta))
	var at := _at + Vector3.UP * height * 0.6
	var from := at + Basis(Vector3.UP, _chase_yaw) * Vector3(0.0, 12.0, 30.0)
	return Transform3D(Basis(), from).looking_at(at, Vector3.UP)
