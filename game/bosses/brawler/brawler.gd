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

## Lo que mide su caja contra lo fijo (m): el ancho de las orugas, el alto y el largo.
const BOX := Vector3(24.0, 30.0, 20.0)
## Cuánto cae (m/s²) si no hay piso.
const GRAVITY := 30.0

## LAS POSES: parado; agachado para embestir (los brazos atrás, temblando); embistiendo (los puños adelante); los
## brazos arriba para el golpe al piso; el golpe (los puños al piso); aturdido (desplomado).
enum Pose { REST, CHARGE_READY, CHARGING, SLAM_READY, SLAM, STUNNED }
## De cada pose: cuánto se inclina el torso (°, adelante), cuánto giran los brazos en el hombro (°, adelante y arriba),
## cuánto tiembla (m) y en cuánto llega a ella (s).
const POSES := {
	Pose.REST: [0.0, 0.0, 0.0, 0.5],
	Pose.CHARGE_READY: [14.0, -35.0, 0.35, 0.6],
	Pose.CHARGING: [22.0, 70.0, 0.0, 0.25],
	Pose.SLAM_READY: [-14.0, 165.0, 0.2, 0.8],
	Pose.SLAM: [32.0, 50.0, 0.0, 0.1],
	Pose.STUNNED: [28.0, 10.0, 0.0, 0.4],
}

## ── LO QUE SE LE PIDE ──
## Las orugas: y adelante (positivo) o atrás; x gira (positivo, a la derecha).
var move := Vector2.ZERO
## Hacia dónde mira la cintura (radianes, en el mundo).
var aim_yaw := 0.0
var furnace := false
var rage := false
## EMBISTIENDO: las orugas van a la velocidad de la embestida (BrawlerSettings), con su rampa corta.
var charging := false
var pose := Pose.REST

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

var _ahead := MoveRamp.new()
var _turn := MoveRamp.new()
var _box := BoxShape3D.new()
var _solid: AnimatableBody3D = null
var _torso_shape: CollisionShape3D = null
var _driving := false
var _chase_yaw := 0.0
var _furnace_was := false
var _rage_was := false
var _lean := 0.0
var _raise := 0.0
var _shake := 0.0


func _init() -> void:
	collision_layer = 0
	collision_mask = PhysicsLayers.FIXED
	floor_snap_length = 0.5


func _ready() -> void:
	_box.size = BOX
	var holder := CollisionShape3D.new()
	holder.shape = _box
	holder.position.y = BOX.y * 0.5
	add_child(holder)
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
	var tracks := Vector3((BrawlerBody.WAIST.x * 0.5 + BrawlerBody.TRACK.x + 1.5) * 2.0, BrawlerBody.TRACK.y + 3.0,
		BrawlerBody.TRACK.z)
	Clay.shape_box(_solid, tracks, Vector3.UP * tracks.y * 0.5)
	_torso_shape = CollisionShape3D.new()
	var chest := BoxShape3D.new()
	chest.size = Vector3(BrawlerBody.CHEST.x + 2.0, BOX.y - tracks.y, BrawlerBody.CHEST.z)
	_torso_shape.shape = chest
	_torso_shape.position.y = tracks.y + chest.size.y * 0.5
	_solid.add_child(_torso_shape)
	PhysicsLayers.mark_fixed(_solid)
	add_collision_exception_with(_solid)
	add_to_group(SandboxPossession.GROUP)
	_place_upper()


func _physics_process(delta: float) -> void:
	var k := BrawlerSettings.current
	_read()
	var hurry := lerpf(1.0, k.rage_speed, fury)
	# LAS ORUGAS: girar y andar, cada una con su rampa.
	var turning := _turn.step(delta, clampf(move.x, -1.0, 1.0), k.turn_time, MoveCurve.Shape.LINEAR, k.turn_time,
		MoveCurve.Shape.LINEAR)
	hull_yaw = wrapf(hull_yaw - turning * deg_to_rad(k.turn_speed) * hurry * delta, -PI, PI)
	var wanted := clampf(move.y, -k.reverse_share, 1.0)
	var braking := wanted * _ahead.level < 0.0
	var top := k.charge_speed if charging else k.speed * hurry
	speed = _ahead.step(delta, wanted, k.charge_up_time if charging else k.up_time, k.up_shape,
		k.brake_time if braking else k.coast_time, k.brake_shape if braking else k.coast_shape) * top
	rotation.y = hull_yaw
	var heading := Basis(Vector3.UP, hull_yaw) * Vector3.FORWARD
	var fall := 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
	velocity = heading * speed + Vector3.UP * fall
	if arena != null:
		arena.resize(k.arena_radius)
		velocity = arena.keep(global_position, velocity, BOX.x * 0.5)
	move_and_slide()
	if arena != null:
		global_position = arena.hold(global_position, BOX.x * 0.5)
	# Lo que de verdad avanzó: si chocó, la rampa baja hasta ahí.
	var forward := get_real_velocity().dot(heading)
	if absf(forward) < absf(speed) - 0.5:
		_ahead.level = clampf(forward / maxf(top, 0.01), -1.0, 1.0)
		speed = forward
	_solid.global_transform = global_transform
	# LA CINTURA, hacia donde mira, con tope.
	var most := deg_to_rad(k.waist_speed) * hurry * delta
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
	body.pose(_lean, _raise, _shake)


func _place_upper() -> void:
	if _torso_shape != null:
		_torso_shape.transform = Transform3D(Basis(Vector3.UP, waist_yaw - hull_yaw), _torso_shape.position)
	body.upper.global_transform = Transform3D(Basis(Vector3.UP, waist_yaw),
		global_position + Vector3.UP * BrawlerBody.HIP)


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
	_solid.sync_to_physics = false
	_solid.global_transform = global_transform
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
		var eye := global_position + Vector3.UP * 27.0 + Basis(Vector3.UP, waist_yaw) * Vector3(0.0, 0.0, -5.0)
		return Transform3D(Basis(Vector3.UP, waist_yaw), eye)
	_chase_yaw = lerp_angle(_chase_yaw, waist_yaw, 1.0 - exp(-3.0 * delta))
	var at := global_position + Vector3.UP * 18.0
	var from := at + Basis(Vector3.UP, _chase_yaw) * Vector3(0.0, 25.0, 70.0)
	return Transform3D(Basis(), from).looking_at(at, Vector3.UP)
