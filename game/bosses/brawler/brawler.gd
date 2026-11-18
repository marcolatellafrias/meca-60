class_name Brawler
extends CharacterBody3D

## EL LUCHADOR DE ORUGAS (15/11/2026), PASO 1: el jefe humanoide, para ver cómo se mueve. El usuario eligió la maqueta:
## «iría con la de luchador, pero en vez de piernas les haría las huellas de un tanque»; los jefes van a ser «más
## humanoides (con brazos y cabeza)». Sin ataques todavía: lo maneja quien lo posee (la O). Ver docs/technical/luchador.md.
##
## CINEMÁTICO (el usuario: «empezaría con un jefe puramente cinemático»): el controlador de personaje del motor, con una
## caja que mira sólo lo fijo del mundo (PhysicsLayers.FIXED). Para las mecas, su cuerpo (un AnimatableBody3D que lo
## sigue) va también en esa capa: es una pared para ellas (ver docs/technical/pelea-jefes.md). Movimiento discreto, en
## metros y segundos (BrawlerSettings).
##   · LAS ORUGAS: adelante y atrás con rampas (MoveRamp): arranca pesado, soltando sigue un poco y frena apretando para
##     el otro lado. A/D giran las orugas (en el lugar o andando), con su rampa corta.
##   · LA CINTURA gira aparte, sobre el aro, hacia `aim_yaw`, con tope de giro: puede andar para un lado y mirarte.
##   · LA ARENA (BossArena): no sale del círculo; contra el borde se desliza.
##   · EL HORNO (`furnace`): la puerta se abre para arriba; es el punto débil (mañana, antes de embestir).
##   · LAS POSES (`pose`, Pose): cómo se para lo de arriba (el torso inclinado, los brazos, el temblor); las pone la
##     cabeza, y el cuerpo va hacia ellas en su tiempo (POSES).
##   · LA IRA (`rage`): otro color, el visor rojo, humo negro por las chimeneas, y anda y gira más rápido.

## SU ESCALA, LA DE TODOS LOS JEFES (BossSettings.scale, una sola perilla, en vivo): el dibujo (BrawlerBody) está en las
## medidas de la maqueta, y el Luchador entero va a esa escala (el dibujo, su caja, su cuerpo para las mecas y el
## alcance de lo que sale de él: la embestida, los puños). *Del 15/11/2026: 0,6 (el usuario: «bajar un poco la escala
## del jefe e igualarla un poco más a la meca»).*
## LO QUE EL CUERPO LES OFRECE A LOS PODERES, POR NOMBRE LIBRE (17/11/2026; el usuario: «no está el concepto de que
## existe un horno… yo decido desde qué punto sale algo… así como ahora es un horno, también podría ser un cañón»): sus
## PUNTOS (de dónde puede salir algo: `point`), sus ZONAS DE GOLPE (`hit_shapes`), sus POSES (`pose`) y cómo se ve
## (`LOOKS`). Un poder no sabe qué hay en cada uno: en el panel se elige cuál usa. Lo único que un poder puede PEDIR es
## físico: «suelo» (lo tiene mientras no vuela: ver `lacks_now`).
const PARTS: Array[String] = ["suelo"]
const POINTS: Array[String] = ["pecho", "cabeza", "puño izquierdo", "puño derecho", "entre los puños", "arriba",
	"frente"]
const ZONES: Array[String] = ["cuerpo", "puños", "brazos", "puntas"]
const LOOKS: Array[String] = ["normal", "con ira"]
## Los nombres de las poses, en el orden de `Pose`.
const POSE_NAMES: Array[String] = ["parado", "agachado, brazos atrás", "inclinado, puños adelante", "brazos arriba",
	"puños al piso", "desplomado", "manos al piso", "carga sobre la cabeza", "tira", "brazos abiertos",
	"brazos abiertos, girando", "brazos atrás", "brazos adelante", "brazos adelante (revoleo)", "echado atrás",
	"pecho adelante"]
## Volando: a cuánto sube y baja (m/s, en la maqueta).
const FLY_CLIMB := 22.0
## Lo que mide su caja contra lo fijo, en la maqueta (m): el ancho de las orugas, el alto y el largo.
const BOX_BASE := Vector3(24.0, 30.0, 20.0)
## Cuánto cae (m/s²) si no hay piso.
const GRAVITY := 30.0

## LAS POSES: parado; agachado para embestir (los brazos atrás, temblando); embistiendo (los puños adelante); los
## brazos arriba para el golpe al piso; el golpe (los puños al piso); aturdido (desplomado); las manos en el piso para
## arrancarlo; la piedra arriba de la cabeza; y el tiro (los brazos adelante); el trompo (los brazos abiertos, antes y
## girando); el agarre (los brazos atrás y el tiro de la mano); el revoleo (los brazos adelante, con la meca); y el
## lanzallamas (echado atrás, los brazos abiertos para atrás, el pecho adelante).
enum Pose { REST, CHARGE_READY, CHARGING, SLAM_READY, SLAM, STUNNED, DIG, LIFT, THROW, SPIN_READY, SPIN, HOOK_READY,
	HOOK, SWING, FLAME_READY, FLAME }
## De cada pose: cuánto se inclina el torso (°, adelante), cuánto giran los brazos en el hombro (°, adelante y arriba),
## cuánto tiembla (m), en cuánto llega a ella (s) y cuánto se abren los brazos para los costados (°).
const POSES := {
	Pose.REST: [0.0, 0.0, 0.0, 0.5, 0.0],
	Pose.CHARGE_READY: [14.0, -35.0, 0.35, 0.6, 0.0],
	Pose.CHARGING: [22.0, 70.0, 0.0, 0.25, 0.0],
	Pose.SLAM_READY: [-14.0, 165.0, 0.2, 0.8, 0.0],
	Pose.SLAM: [32.0, 50.0, 0.0, 0.1, 0.0],
	Pose.STUNNED: [28.0, 10.0, 0.0, 0.4, 0.0],
	Pose.DIG: [42.0, 25.0, 0.25, 0.5, 0.0],
	Pose.LIFT: [-12.0, 175.0, 0.15, 0.6, 0.0],
	Pose.THROW: [28.0, 80.0, 0.0, 0.12, 0.0],
	Pose.SPIN_READY: [-6.0, 10.0, 0.25, 0.6, 45.0],
	Pose.SPIN: [8.0, 0.0, 0.0, 0.3, 52.0],
	Pose.HOOK_READY: [6.0, -45.0, 0.2, 0.5, 0.0],
	Pose.HOOK: [14.0, 88.0, 0.0, 0.1, 0.0],
	Pose.SWING: [-6.0, 88.0, 0.0, 0.3, 0.0],
	Pose.FLAME_READY: [-10.0, -30.0, 0.3, 0.5, 35.0],
	Pose.FLAME: [-4.0, -15.0, 0.12, 0.3, 45.0],
}

## ── LO QUE SE LE PIDE ──
## Las orugas: y adelante (positivo) o atrás; x gira (positivo, a la derecha).
var move := Vector2.ZERO
## Hacia dónde mira la cintura (radianes, en el mundo).
var aim_yaw := 0.0
var furnace := false
var rage := false
## CORRIENDO (la embestida, el trompo: lo pide el poder con `rush`): las orugas van a esta velocidad (m/s; 0, la de
## siempre), con esta rampa (s).
var rush_speed := 0.0
var rush_up := 0.3
## CÓMO SE MUEVE (lo pone su cabeza, según el modo: ver BossMode):
##   · `hurry`: cuánto más rápido anda y gira (veces).
##   · `fly_height`: vuela a esta altura (m; 0, en el piso). Volando no usa las orugas: va PARA CUALQUIER LADO, hacia
##     `go` (en el mundo, de largo 0 a 1), y gira igual que siempre.
##   · `omni`: en el piso también va para cualquier lado (para un jefe de patas; el Luchador, no).
##   · `jump(to, time, arc)`: un salto en arco hasta un punto (cualquier poder lo puede pedir); `landed_now` es cierto
##     el paso en que cae.
var hurry := 1.0
## EL RESORTE DE DIBUJO (HitSpring), como el de la jaula: los golpes lo inclinan (HitReaction.sway, cuando la meca le
## pega) y al caer de un salto o de volar se hunde. Sólo lo de arriba: gira sobre la cintura y baja sobre las orugas.
var body_spring := HitSpring.new()
## Al caer se hunde LAND_SINK m (de la maqueta) cayendo a LAND_FULL m/s o más.
const LAND_SINK := 3.0
const LAND_FULL := 80.0
## Como la jaula (KinematicSettings, «Aterrizar»): el peso en el quiebre (land_push) y la vuelta rápida, con resorte:
## de vuelta en LAND_RECOVER s, con LAND_BOUNCE de rebote (0 a 1). El usuario: «en la oruga sigue volviendo más lento».
const LAND_RECOVER := 0.25
const LAND_BOUNCE := 0.7
var _height_was := 0.0
## A cuánto bajaba en el paso anterior (m/s, en el mundo): el arco del salto llega al piso un paso antes de terminar.
var _drop_was := 0.0
var fly_height := 0.0
var go := Vector3.ZERO
var omni := false
var landed_now := false
var pose := Pose.REST
## EL TROMPO: la cintura gira sola a tantos °/s (positivo, a la izquierda), sin mirar a `aim_yaw`; 0, como siempre.
var spin := 0.0
## LO QUE NO EMPUJA (el blanco de su cabeza): un punto del piso y su radio (m; 0, nada). No avanza dentro de él: se
## frena contra él, no lo arrastra (como los jefes de Souls; ver docs/technical/pelea-jefes.md).
var block_at := Vector3.ZERO
var block_radius := 0.0

## ── LO QUE MIDE ──
## A cuánto va adelante (m/s; atrás, negativo).
var speed := 0.0
## Hacia dónde miran las orugas y la cintura (radianes).
var hull_yaw := 0.0
var waist_yaw := 0.0
## La puerta del horno (0 cerrada, 1 abierta) y la ira (0 a 1).
var opened := 0.0
var fury := 0.0
## LA ARENA: el círculo del que no sale (sin arena, anda por donde sea).
var arena: BossArena = null
var body: BrawlerBody = null
## DONDE SE LE PEGA (BossHurtbox): la caja que encuentran los tiros y el taladro de la meca de tres.
var hurtbox: BossHurtbox = null

var _ahead := MoveRamp.new()
var _turn := MoveRamp.new()
var _box := BoxShape3D.new()
var _solid: AnimatableBody3D = null
var _torso_shape: CollisionShape3D = null
var _tracks_shape := CollisionShape3D.new()
var _holder := CollisionShape3D.new()
var _fitted := -1.0
var _aloft := false
var _drift := Vector3.ZERO
var _jump_from := Vector3.ZERO
var _jump_to := Vector3.ZERO
var _jump_time := 0.0
var _jump_clock := 0.0
var _jump_arc := 0.0
var _jets: CPUParticles3D = null
var _driving := false
var _chase_yaw := 0.0
var _furnace_was := false
var _rage_was := false
var _lean := 0.0
var _raise := 0.0
var _shake := 0.0
var _spread := 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.FIXED
	floor_snap_length = 0.5


func _ready() -> void:
	_holder.shape = _box
	add_child(_holder)
	hull_yaw = global_rotation.y
	waist_yaw = hull_yaw
	aim_yaw = hull_yaw
	body = BrawlerBody.new()
	body.build(self)
	# SU CUERPO PARA LAS MECAS: las orugas y una caja para lo de arriba, que gira con la cintura (así la meca llega al
	# pecho, y al horno, de frente). Nace en su lugar.
	_solid = AnimatableBody3D.new()
	_solid.name = "Cuerpo"
	_solid.top_level = true
	_solid.sync_to_physics = false
	_solid.transform = global_transform
	add_child(_solid)
	_solid.sync_to_physics = true
	_tracks_shape.shape = BoxShape3D.new()
	_solid.add_child(_tracks_shape)
	_torso_shape = CollisionShape3D.new()
	_torso_shape.shape = BoxShape3D.new()
	_solid.add_child(_torso_shape)
	# SÓLO lo fijo (no la capa común): así lo chocan las mecas, pero los tiros (que miran la común) pasan hasta
	# donde se le pega (BossHurtbox). Con la capa común, el tiro moría en el cuerpo.
	_solid.collision_layer = PhysicsLayers.FIXED
	add_collision_exception_with(_solid)
	hurtbox = BossHurtbox.new()
	_solid.add_child(hurtbox)
	_fit_scale()
	add_to_group(SandboxPossession.GROUP)
	_place_upper()


## A LA ESCALA DE AHORA (BossSettings.scale): el dibujo de las orugas, la caja contra lo fijo, el cuerpo para las mecas
## y donde se le pega. Lo de arriba se escala al ponerlo (`_place_upper`). Se llama de nuevo si la escala cambia.
func _fit_scale() -> void:
	var size := scale()
	_fitted = size
	var box_now := box()
	body.hull.scale = Vector3.ONE * size
	_box.size = box_now
	_holder.position.y = box_now.y * 0.5
	var tracks := Vector3((BrawlerBody.WAIST.x * 0.5 + BrawlerBody.TRACK.x + 1.5) * 2.0, BrawlerBody.TRACK.y + 3.0,
		BrawlerBody.TRACK.z) * size
	(_tracks_shape.shape as BoxShape3D).size = tracks
	_tracks_shape.position = Vector3.UP * tracks.y * 0.5
	var chest := Vector3((BrawlerBody.CHEST.x + 2.0) * size, box_now.y - tracks.y, BrawlerBody.CHEST.z * size)
	(_torso_shape.shape as BoxShape3D).size = chest
	_torso_shape.position.y = tracks.y + chest.y * 0.5
	hurtbox.shape(box_now, Vector3.UP * box_now.y * 0.5)


func _physics_process(delta: float) -> void:
	var k := BrawlerSettings.current
	if not is_equal_approx(_fitted, scale()):
		_fit_scale()
	_read()
	landed_now = false
	_height_was = global_position.y
	# LAS ORUGAS: girar y andar, cada una con su rampa.
	var turning := _turn.step(delta, clampf(move.x, -1.0, 1.0), k.turn_time, MoveCurve.Shape.LINEAR, k.turn_time,
		MoveCurve.Shape.LINEAR)
	hull_yaw = wrapf(hull_yaw - turning * deg_to_rad(k.turn_speed) * hurry * delta, -PI, PI)
	var wanted := clampf(move.y, -k.reverse_share, 1.0)
	var braking := wanted * _ahead.level < 0.0
	var rushing := rush_speed > 0.0
	var top := rush_speed if rushing else k.speed * hurry
	speed = _ahead.step(delta, wanted, rush_up if rushing else k.up_time, k.up_shape,
		k.brake_time if braking else k.coast_time, k.brake_shape if braking else k.coast_shape) * top
	rotation.y = hull_yaw
	var heading := Basis(Vector3.UP, hull_yaw) * Vector3.FORWARD
	if arena != null:
		arena.resize(k.arena_radius)
	if fly_height > 0.0:
		_aloft = true
	if _jump_time > 0.0:
		# SALTANDO: el arco, sin nada más.
		_jump_clock += delta
		var t := clampf(_jump_clock / _jump_time, 0.0, 1.0)
		global_position = _jump_from.lerp(_jump_to, t) + Vector3.UP * _jump_arc * 4.0 * t * (1.0 - t)
		velocity = Vector3.ZERO
		speed = 0.0
		_ahead.level = 0.0
		if t >= 1.0:
			_jump_time = 0.0
			landed_now = true
	elif _aloft or omni:
		# VOLANDO (o de patas): para cualquier lado, hacia `go`, con algo de peso.
		var top_now := top if rushing else k.speed * hurry
		_drift = _drift.move_toward(Vector3(go.x, 0.0, go.z).limit_length(1.0) * top_now, top_now / 0.6 * delta)
		var rise := 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
		if _aloft:
			var climb := FLY_CLIMB * scale()
			rise = clampf((fly_height - global_position.y) * 2.5, -climb, climb)
			# Bajando a tierra: hasta tocar el piso.
			if fly_height <= 0.0:
				rise = minf(rise, -climb * 0.25)
		velocity = _drift + Vector3.UP * rise
		speed = _drift.dot(heading)
		_ahead.level = 0.0
		floor_snap_length = 0.0 if _aloft else 0.5
		if arena != null:
			velocity = arena.keep(global_position, velocity, box().x * 0.5)
		move_and_slide()
		if _aloft and fly_height <= 0.0 and is_on_floor():
			_aloft = false
			_drift = Vector3.ZERO
			landed_now = true
	else:
		floor_snap_length = 0.5
		var fall := 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
		velocity = heading * speed + Vector3.UP * fall
		if arena != null:
			velocity = arena.keep(global_position, velocity, box().x * 0.5)
		if block_radius > 0.0:
			velocity = _blocked(velocity)
		move_and_slide()
		# Lo que de verdad avanzó: si chocó, la rampa baja hasta ahí.
		var forward := get_real_velocity().dot(heading)
		if absf(forward) < absf(speed) - 0.5:
			_ahead.level = clampf(forward / maxf(top, 0.01), -1.0, 1.0)
			speed = forward
	if arena != null:
		global_position = arena.hold(global_position, box().x * 0.5)
	# ATERRIZÓ: se hunde según a cuánto bajaba (en la maqueta; lo más rápido de este paso y el anterior).
	var drop := (_height_was - global_position.y) / maxf(delta, 0.001)
	if landed_now:
		var firm := 4.5 / LAND_RECOVER
		body_spring.land_stiffness = firm * firm
		body_spring.land_damping = 2.0 * lerpf(0.95, 0.3, LAND_BOUNCE) * firm
		body_spring.land_push = true
		body_spring.land_full_speed = LAND_FULL
		body_spring.land_threshold = LAND_FULL * 0.1
		body_spring.land(maxf(drop, _drop_was) / scale())
	_drop_was = drop
	body_spring.update(delta)
	_show_jets()
	_solid.global_transform = global_transform
	# Donde se le pega es un cuerpo aparte: no sigue solo a su padre (quedaba donde nació).
	hurtbox.global_transform = global_transform
	# LA CINTURA, hacia donde mira, con tope; en el trompo, gira sola.
	var most := deg_to_rad(k.waist_speed) * hurry * delta
	if spin != 0.0:
		waist_yaw = wrapf(waist_yaw + deg_to_rad(spin) * delta, -PI, PI)
	else:
		waist_yaw = wrapf(waist_yaw + clampf(wrapf(aim_yaw - waist_yaw, -PI, PI), -most, most), -PI, PI)
	opened = move_toward(opened, 1.0 if furnace else 0.0, delta / maxf(k.door_time, 0.01))
	fury = move_toward(fury, 1.0 if rage else 0.0, delta / maxf(k.rage_time, 0.01))
	_place_upper()
	body.show(opened, k.door_angle, fury)
	var wanted_pose: Array = POSES[pose]
	var follow := 1.0 - exp(-4.0 * delta / maxf(float(wanted_pose[3]), 0.01))
	_lean = lerpf(_lean, float(wanted_pose[0]), follow)
	_raise = lerpf(_raise, float(wanted_pose[1]), follow)
	_shake = lerpf(_shake, float(wanted_pose[2]), follow)
	_spread = lerpf(_spread, float(wanted_pose[4]), follow)
	body.pose(_lean, _raise, _shake, _spread)


func _place_upper() -> void:
	if _torso_shape != null:
		_torso_shape.transform = Transform3D(Basis(Vector3.UP, waist_yaw - hull_yaw), _torso_shape.position)
	var upright := Basis(Vector3.UP, waist_yaw)
	var tilt := body_spring.tilt_degrees()
	var sway := Basis(upright.x, deg_to_rad(tilt.x)) * Basis(upright.z, -deg_to_rad(tilt.y))
	body.upper.global_transform = Transform3D((sway * upright).scaled(Vector3.ONE * scale()),
		global_position + Vector3.UP * (BrawlerBody.HIP - body_spring.y * LAND_SINK) * scale())


## SU ESQUELETO PARA EL RAGDOLL AL MORIR (PartsRagdoll): el tronco es lo de abajo (las orugas); lo de arriba, unido a
## él en la cintura; cada brazo, unido a lo de arriba en su hombro.
func ragdoll_parts(ragdoll: PartsRagdoll) -> void:
	var top := ragdoll.add([body.upper], 0, global_position + Vector3.UP * BrawlerBody.HIP * scale())
	for shoulder in body.shoulders:
		ragdoll.add([shoulder], top, shoulder.global_position)


## Sin lo que lo metería dentro de `block_at`: si su caja está a menos de su radio (y un poco), no avanza hacia él.
func _blocked(wanted: Vector3) -> Vector3:
	var local := global_transform.affine_inverse() * block_at
	var box_now := box()
	var gap := Vector2(maxf(absf(local.x) - box_now.x * 0.5, 0.0), maxf(absf(local.z) - box_now.z * 0.5, 0.0)).length()
	var toward := block_at - global_position
	toward.y = 0.0
	if gap > block_radius + 1.0 or toward.length() < 0.01:
		return wanted
	toward = toward.normalized()
	var into := wanted.dot(toward)
	return wanted - toward * into if into > 0.0 else wanted


## CORRE a `top` m/s (llega en `up` s): la embestida, el trompo. 0, vuelve a lo de siempre.
func rush(top: float, up := 0.3) -> void:
	rush_speed = top
	rush_up = up


## SUS ZONAS DE GOLPE, POR PIEZA (17/11/2026; el usuario: «que cada componente pueda tener hitboxes y un poder activa
## una cierta cantidad de hitboxes durante un cierto periodo»): las cápsulas de `part` ahora, en el mundo, cada una
## [desde, hasta, radio]. Escalan con él. Un poder las prende con BrawlerBrain.hit_with mientras dura su golpe.
##   · "cuerpo": todo el casco, de atrás a adelante (la embestida).
##   · "puños": los dos puños. · "brazos": cada brazo, del hombro al puño. · "puntas": la punta de cada brazo.
func hit_shapes(part: String) -> Array:
	var shapes := []
	var size := box()
	var grip := fist()
	match part:
		"cuerpo":
			var middle := global_position + Vector3.UP * size.y * 0.4
			var along := heading() * maxf(size.z * 0.5 - size.x * 0.5, 0.0)
			shapes.append([middle - along, middle + along + heading() * 0.01, size.x * 0.5])
		"puños":
			for point in body.fists():
				shapes.append([point, point, grip * 0.75])
		"brazos", "puntas":
			var fists := body.fists()
			for index in body.shoulders.size():
				var from := body.shoulders[index].global_position
				if part == "puntas":
					from = from.lerp(fists[index], 0.9)
				shapes.append([from, fists[index], grip * 0.8])
	return shapes


## Su cuerpo para las mecas (lo fijo que lo sigue): lo que él lanza no rebota contra él.
func solid() -> PhysicsBody3D:
	return _solid


## Si está en el aire (volando, bajando o saltando).
func aloft() -> bool:
	return _aloft or _jump_time > 0.0


## UN SALTO en arco hasta `to` (el piso), en `time` s, subiendo `arc` m. Mientras dura no hace otra cosa.
func jump(to: Vector3, time: float, arc: float) -> void:
	_jump_from = global_position
	_jump_to = to
	_jump_time = maxf(time, 0.05)
	_jump_clock = 0.0
	_jump_arc = arc


## Lo que le falta AHORA de `needs`: sus piezas, y el suelo si está en el aire.
func lacks_now(needs: PackedStringArray) -> PackedStringArray:
	var missing := lacks(needs)
	if aloft() and needs.has("suelo"):
		missing.append("suelo")
	return missing


## LOS PROPULSORES (sólo se ven): fuego para abajo mientras está en el aire.
func _show_jets() -> void:
	if not _aloft and _jets == null:
		return
	if _jets == null:
		_jets = CPUParticles3D.new()
		_jets.name = "Propulsores"
		var ball := SphereMesh.new()
		ball.radius = 1.2
		ball.height = 2.4
		ball.radial_segments = 8
		ball.rings = 4
		var paint := StandardMaterial3D.new()
		paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		paint.vertex_color_use_as_albedo = true
		paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ball.material = paint
		_jets.mesh = ball
		_jets.local_coords = false
		_jets.amount = 90
		_jets.lifetime = 0.6
		_jets.direction = Vector3.DOWN
		_jets.spread = 18.0
		_jets.initial_velocity_min = 25.0
		_jets.initial_velocity_max = 40.0
		_jets.gravity = Vector3.ZERO
		_jets.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		var ramp := Gradient.new()
		ramp.set_color(0, Color(1.0, 0.9, 0.5, 0.9))
		ramp.set_color(1, Color(1.0, 0.3, 0.05, 0.0))
		_jets.color_ramp = ramp
		_jets.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_jets)
	var size := box()
	_jets.emission_box_extents = Vector3(size.x * 0.4, 0.2, size.z * 0.4)
	_jets.scale_amount_min = scale()
	_jets.scale_amount_max = scale() * 1.8
	_jets.emitting = _aloft


## Lo que le falta de `needs` (las piezas que pide un poder).
static func lacks(needs: PackedStringArray) -> PackedStringArray:
	var missing := PackedStringArray()
	for part in needs:
		if not PARTS.has(part):
			missing.append(part)
	return missing


## La escala de todos los jefes (ver BossSettings).
static func scale() -> float:
	return BossSettings.current.scale


## Lo que mide su caja, a escala (m).
static func box() -> Vector3:
	return BOX_BASE * scale()


## El puño, a escala (m).
static func fist() -> float:
	return BrawlerBody.FIST * scale()


## LO PARA EN SECO (se estrelló): sin velocidad.
func stop() -> void:
	_ahead.level = 0.0
	speed = 0.0
	velocity = Vector3.ZERO


## Hacia dónde miran las orugas (de costado, de largo 1).
func heading() -> Vector3:
	return Basis(Vector3.UP, hull_yaw) * Vector3.FORWARD


## Dónde está la boca del horno (mundo): el punto débil.
func furnace_point() -> Vector3:
	return body.furnace()


## DÓNDE ESTÁ EL PUNTO `index` de `POINTS`, ahora (mundo): de ahí puede salir lo que un poder lance.
func point(index: int) -> Vector3:
	var fists := body.fists()
	match POINTS[clampi(index, 0, POINTS.size() - 1)]:
		"pecho":
			return body.furnace()
		"cabeza":
			return global_position + Vector3.UP * box().y
		"puño izquierdo":
			return fists[0]
		"puño derecho":
			return fists[1]
		"entre los puños":
			return (fists[0] + fists[1]) * 0.5
		"arriba":
			return global_position + Vector3.UP * (box().y + 2.0)
	return global_position + Basis(Vector3.UP, waist_yaw) * Vector3.FORWARD * box().z * 0.5 + Vector3.UP * box().y * 0.4


## LO PONE en `where` (el punto del piso), quieto, mirando adonde mira `where`.
func put(where: Transform3D) -> void:
	global_position = where.origin
	hull_yaw = where.basis.get_euler().y
	waist_yaw = hull_yaw
	aim_yaw = hull_yaw
	rotation.y = hull_yaw
	velocity = Vector3.ZERO
	speed = 0.0
	_ahead.level = 0.0
	_turn.level = 0.0
	_aloft = false
	_drift = Vector3.ZERO
	_jump_time = 0.0
	fly_height = 0.0
	body_spring.reset()
	_solid.sync_to_physics = false
	_solid.global_transform = global_transform
	# Donde se le pega es un cuerpo aparte: no sigue solo a su padre (quedaba donde nació).
	hurtbox.global_transform = global_transform
	_solid.sync_to_physics = true
	_place_upper()


## ── POSEERLO (ver SandboxPossession) ─────────────────────────────────────────────────────────────────────────────

func _read() -> void:
	if not (_driving and UIState.gameplay_active()):
		return
	move = Vector2(MechKeys.axis(KEY_D, KEY_A), MechKeys.axis(KEY_W, KEY_S))
	var door_key := Input.is_physical_key_pressed(KEY_Q)
	if door_key and not _furnace_was:
		furnace = not furnace
	_furnace_was = door_key
	var rage_key := Input.is_physical_key_pressed(KEY_G)
	if rage_key and not _rage_was:
		rage = not rage
	_rage_was = rage_key


func _unhandled_input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion
	if not _driving or motion == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	aim_yaw = wrapf(aim_yaw - motion.relative.x * 0.0025 * GameOptions.mouse_sensitivity, -PI, PI)
	get_viewport().set_input_as_handled()


## Si alguien lo posee (entonces su cabeza no hace nada).
func driven() -> bool:
	return _driving


func possess_name() -> String:
	return "Luchador de orugas"


func possess_controls() -> PackedStringArray:
	return PackedStringArray([
		"W/S las orugas adelante y atrás (arranca pesado, soltando sigue un poco) · A/D giran las orugas",
		"el mouse gira la cintura: puede andar para un lado y mirar para otro",
		"Q abre o cierra el horno del pecho (la puerta, para arriba) · G la ira (humo negro)",
	])


func possess_status() -> String:
	return "%.1f m/s · orugas a %.0f° · cintura a %.0f°%s%s" % [speed, rad_to_deg(hull_yaw), rad_to_deg(waist_yaw),
		" · horno abierto" if opened > 0.9 else "", " · CON IRA" if fury > 0.9 else ""]


func possess_begin() -> void:
	_driving = true
	_chase_yaw = waist_yaw


func possess_end() -> void:
	_driving = false
	move = Vector2.ZERO
	_furnace_was = false
	_rage_was = false


func possess_camera(first: bool, delta: float) -> Transform3D:
	if first:
		var eye := global_position + Vector3.UP * 27.0 * scale() + Basis(Vector3.UP, waist_yaw) * Vector3(0.0, 0.0, -5.0 * scale())
		return Transform3D(Basis(Vector3.UP, waist_yaw), eye)
	_chase_yaw = lerp_angle(_chase_yaw, waist_yaw, 1.0 - exp(-3.0 * delta))
	var at := global_position + Vector3.UP * 18.0 * scale()
	var from := at + Basis(Vector3.UP, _chase_yaw) * Vector3(0.0, 25.0, 70.0) * scale()
	return Transform3D(Basis(), from).looking_at(at, Vector3.UP)
