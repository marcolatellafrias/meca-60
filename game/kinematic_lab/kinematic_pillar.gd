class_name KinematicPillar
extends CharacterBody3D

## *VIEJO (13/11/2026): el Laboratorio cinemático ya usa la meca simplificada (Mech sin brazos ni cabina, que se mueve
## con KinematicMover y pisa con StompFeet). Este cubo queda sólo porque lo usa el módulo Jefes como blanco del jefe
## bola; cuando pasen a la meca, se borra con sus piezas (PillarFeet, PillarNozzles, PillarSettings, PillarPanel).*
##
## EL CUBO CINEMÁTICO (13/11/2026) — EXPERIMENTO: una caja sobre dos pies, para probar por separado CÓMO SE LLEVA LO
## CINEMÁTICO CON LO FÍSICO y la locomoción de la meca futura, sin la cabina, el ascensor ni el péndulo. El usuario: «un
## cubo alargado… y así yo pruebo los distintos approaches de interacción de cinemático con físico… vamos por partes»;
## «un sistema simple, barebones, sólido y que use las cosas del motor, y no reglas inventadas».
##
## LO MUEVE EL CONTROLADOR DE PERSONAJE DEL MOTOR (CharacterBody3D, `move_and_slide`): se le da una velocidad y él frena
## y se desliza contra paredes y esquinas, sabe si está en el piso y se sale solo si queda metido en algo. *Hasta el
## 13/11/2026 era un AnimatableBody3D —que va adonde se lo pone y nada lo frena— con un «pruebo y deslizo» escrito a
## mano: la prueba era ciega a lo que ya tenía encimado, en una esquina quedaba un centímetro adentro y de ahí en más
## atravesaba el edificio; y para saltear lo suelto daba hasta 256 vueltas por movimiento (bajaban los FPS). El usuario:
## «¿estamos peleando con el motor de Godot?». Sí.*
##
## CON QUÉ CHOCA CADA COSA (lo charlado con el usuario):
##   · CONTRA LO FIJO DEL MUNDO (edificios, paredes, el piso), UN CILINDRO más grande que el cubo, del piso al techo:
##     es la forma de este cuerpo, y mira SÓLO LA CAPA DE LO FIJO (PhysicsLayers.FIXED). «Para los obstáculos del
##     mundo… va a ser cilíndrica la hitbox. Así evitamos que se trabe con cosas cuando gira». A él no lo ve nadie: no es
##     un campo de fuerza para lo suelto ni para la tripulación.
##   · CONTRA LO SUELTO, LO QUE SE VE, por el motor y sin reglas extra: la caja de arriba (un AnimatableBody3D que lo
##     sigue) empuja lo alto, y LOS PIES (PillarFeet) patean de costado.
##   · LO QUE QUEDA DEBAJO de algo suyo que baja (un pie, o la caja al agacharse o al caer) SE ACHATA, no se aprieta:
##     apretar algo suelto contra el piso con algo que pesa infinito era lo que hacía explotar al motor. Es una regla del
##     juego («si pisan algo, lo rompen y lo achatan»), no un parche de la física.
##
## EL MOVIMIENTO ES DISCRETO, EN METROS Y SEGUNDOS (PillarSettings; el usuario: «pasar más a como funciona un character
## normal en un juego… movimiento más discreto y menos físico», para probar jefes; *puede que más adelante vuelva algo de
## física encima —inercia—: por eso todo pasa por `velocity`, que es donde se sumaría*):
##   · MOVERSE: una velocidad y el tiempo para llegar a ella. Sin correr. En el aire no se mueve de costado.
##   · GIRAR: con tope de velocidad y de aceleración.
##   · SALTAR (espacio): sólo para arriba; sube tantos metros en tanto tiempo.
##   · EL VUELO (espacio otra vez, en el aire): sube a una velocidad fija mientras le quede su barra.
##   · EL DASH (Shift, con una dirección): tantos metros en tanto tiempo, en línea recta, en el piso y en el aire. SIN
##     DIRECCIÓN NO PASA NADA. Tiene su barra, que se llena sola.
##   · AGACHARSE (Ctrl): las piernas se acortan de a poco y el cubo baja.
##   · LAS TOBERAS (PillarNozzles): placeholder, sólo se ven.

## La caja de arriba: ancho, alto y fondo (m). Y el radio del cilindro contra lo fijo: la caja entra entera.
const TORSO := Vector3(6.0, 12.0, 6.0)
const RADIUS := 4.6

## ── LO QUE SE LE PIDE ──
var move := Vector2.ZERO
var crouch := false
var jump := false
var dash := false
var aim_yaw := 0.0

## ── LO QUE MIDE ──
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

var _yaw := 0.0
var _yaw_speed := 0.0
var _jump_was := false
var _dash_was := false
var _fly_armed := false
## El dash de ahora: cuánto le queda (s) y a qué velocidad va.
var _dash_left := 0.0
var _dash_velocity := Vector3.ZERO
var _nozzles: PillarNozzles = null
var _cylinder := CylinderShape3D.new()
var _holder: CollisionShape3D = null
var _torso: AnimatableBody3D = null
var _below := BoxShape3D.new()
var _last_hip := 0.0
var _driving := false
var _chase_yaw := 0.0


func _init() -> void:
	# A él no lo ve nadie, y él ve sólo lo fijo del mundo.
	collision_layer = 0
	collision_mask = PhysicsLayers.FIXED
	floor_snap_length = 0.2


func _ready() -> void:
	_cylinder.radius = RADIUS
	_holder = CollisionShape3D.new()
	_holder.shape = _cylinder
	add_child(_holder)
	_yaw = global_rotation.y
	aim_yaw = _yaw
	_fit(PillarSettings.current)
	# LA CAJA DE ARRIBA: la que se ve y la que empuja lo suelto. Nace ya en su lugar (ver PillarFeet).
	_torso = AnimatableBody3D.new()
	_torso.name = "Caja"
	_torso.top_level = true
	_torso.sync_to_physics = false
	_torso.transform = _torso_place()
	add_child(_torso)
	_torso.sync_to_physics = true
	Clay.solid(_torso, TORSO, Vector3.ZERO, Clay.METAL.darkened(0.1))
	# El frente, para saber hacia dónde mira.
	Clay.box(_torso, Vector3(TORSO.x * 0.6, 0.8, 0.3), Vector3(0.0, TORSO.y * 0.4, -TORSO.z * 0.5 - 0.1), Clay.YELLOW)
	_nozzles = PillarNozzles.new()
	_torso.add_child(_nozzles)
	_nozzles.build(TORSO)
	_nozzles.fit(TORSO.y)
	_nozzles.position.y = -TORSO.y * 0.5
	feet = PillarFeet.new()
	feet.born_at = Transform3D(Basis(), global_position + Vector3.UP * PillarFeet.FOOT.y * 0.5)
	add_child(feet)
	feet.place_now(PillarSettings.current, global_position, _yaw)
	_below.size = Vector3(TORSO.x, 0.6, TORSO.z)
	_last_hip = global_position.y + hip
	add_to_group(SandboxPossession.GROUP)


func _physics_process(delta: float) -> void:
	var k := PillarSettings.current
	_read()
	# AGACHARSE: las piernas se acortan de a poco.
	crouched = move_toward(crouched, 1.0 if crouch else 0.0, k.crouch_rate * delta)
	_fit(k)
	grounded = is_on_floor()
	dash_fuel = minf(dash_fuel + delta / k.dash_refill, 1.0)
	if _dash_left > 0.0:
		# EN UN DASH: derecho, sin teclas ni gravedad.
		_dash_left -= delta
		velocity = _dash_velocity
	else:
		var flat_now := _walk(k, delta)
		velocity = Vector3(flat_now.x, _rise(k, delta), flat_now.z)
		if dash and not _dash_was and move.length() > 0.1 and dash_fuel >= k.dash_cost:
			_dash(k)
	_dash_was = dash
	_jump_was = jump
	_turn(k, delta)
	rotation.y = _yaw
	move_and_slide()
	grounded = is_on_floor()
	var flat := get_real_velocity()
	flat.y = 0.0
	# LA CAJA Y LOS PIES LO SIGUEN.
	_torso.global_transform = _torso_place()
	# Lo que queda debajo de la caja cuando baja, se achata (ver arriba).
	if global_position.y + hip < _last_hip - 0.0001:
		_squash()
	_last_hip = global_position.y + hip
	feet.step(k, delta, global_position, _yaw, flat, grounded, hip)
	_nozzles.show_flames(delta)


## MOVERSE: de costado, hacia la velocidad pedida, en `reach_time` (0: al instante). En el aire, nada.
func _walk(k: PillarSettings, delta: float) -> Vector3:
	if not grounded:
		return Vector3.ZERO
	var wanted := Basis(Vector3.UP, _yaw) * Vector3(move.x, 0.0, -move.y).limit_length(1.0) * k.walk_speed
	if k.reach_time <= 0.0:
		return wanted
	return Vector3(velocity.x, 0.0, velocity.z).move_toward(wanted, k.walk_speed / k.reach_time * delta)


## SUBIR Y BAJAR: el salto (al apretar, apoyado), el vuelo (apretando otra vez en el aire) y la caída. Devuelve la
## velocidad para arriba.
func _rise(k: PillarSettings, delta: float) -> float:
	# De subir `jump_height` en `jump_time`: g = 2·h / t², y sale a v = 2·h / t.
	var gravity := 2.0 * k.jump_height / (k.jump_time * k.jump_time)
	if grounded:
		fly_fuel = minf(fly_fuel + delta / k.fly_refill, 1.0)
		if jump and not _jump_was:
			_fly_armed = false
			return 2.0 * k.jump_height / k.jump_time
		return 0.0
	if not jump:
		_fly_armed = true
	if jump and _fly_armed and fly_fuel > 0.0:
		fly_fuel = maxf(fly_fuel - delta / k.fly_time, 0.0)
		_nozzles.fly(1.0)
		return k.fly_speed
	return velocity.y - gravity * delta


## EL DASH: hacia donde se pide (en el espacio del cubo), `dash_distance` en `dash_time`.
func _dash(k: PillarSettings) -> void:
	var stick := Vector3(move.x, 0.0, -move.y).normalized()
	_dash_velocity = Basis(Vector3.UP, _yaw) * stick * (k.dash_distance / k.dash_time)
	_dash_left = k.dash_time
	velocity = _dash_velocity
	dash_fuel -= k.dash_cost
	_nozzles.dash(stick)


## Las medidas de ahora: las piernas (enteras o agachado) y el alto entero; el cilindro, del piso al techo.
func _fit(k: PillarSettings) -> void:
	hip = k.leg_height * lerpf(1.0, k.crouch_share, crouched)
	height = hip + TORSO.y
	_cylinder.height = height
	_holder.position.y = height * 0.5


## Dónde va la caja de arriba: sobre las piernas, mirando como él.
func _torso_place() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, _yaw), global_position + Vector3.UP * (hip + TORSO.y * 0.5))


## LO PONE en `where` (el punto del piso debajo de su centro), quieto, sin barrer el camino con la caja ni con los pies
## (ver PillarFeet.place_now).
func put(where: Transform3D) -> void:
	global_position = where.origin
	_yaw = where.basis.get_euler().y
	rotation.y = _yaw
	aim_yaw = _yaw
	_yaw_speed = 0.0
	velocity = Vector3.ZERO
	_dash_left = 0.0
	grounded = false
	_last_hip = global_position.y + hip
	_torso.sync_to_physics = false
	_torso.global_transform = _torso_place()
	_torso.sync_to_physics = true
	feet.place_now(PillarSettings.current, global_position, _yaw)


## EL GIRO: hacia `aim_yaw`, con tope de velocidad y de aceleración. Nada lo traba: contra el mundo es un cilindro.
func _turn(k: PillarSettings, delta: float) -> void:
	var error := clampf(wrapf(aim_yaw - _yaw, -PI, PI), -PI * 0.6, PI * 0.6)
	aim_yaw = _yaw + error
	var top := deg_to_rad(k.turn_speed)
	_yaw_speed = move_toward(_yaw_speed, clampf(error * 6.0, -top, top), deg_to_rad(k.turn_accel) * delta)
	_yaw += _yaw_speed * delta


## LO QUE QUEDA DEBAJO de la caja cuando baja (agachándose, o cayendo): se achata.
func _squash() -> void:
	var place := _torso_place()
	var under := place * Transform3D(Basis(), Vector3.DOWN * (TORSO.y * 0.5 + 0.2))
	for body in AreaStrike.loose_in(get_world_3d().direct_space_state, _below, under):
		if PillarFeet.is_under(body, place, TORSO) and PillarFeet.flatten(body):
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
		"Ctrl se agacha (baja de a poco) · espacio salta (sólo para arriba)",
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
		return Transform3D(Basis(Vector3.UP, _yaw), global_position + Vector3.UP * (height + 1.5))
	_chase_yaw = lerp_angle(_chase_yaw, _yaw, 1.0 - exp(-4.0 * delta))
	var at := global_position + Vector3.UP * height * 0.6
	var from := at + Basis(Vector3.UP, _chase_yaw) * Vector3(0.0, 12.0, 30.0)
	return Transform3D(Basis(), from).looking_at(at, Vector3.UP)
