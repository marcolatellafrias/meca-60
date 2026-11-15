class_name BrawlerBrain
extends Node

## LA CABEZA DEL LUCHADOR (15/11/2026): lo maneja la computadora, como un jefe de Souls (ver docs/technical/pelea-jefes.md):
## cada ataque tiene AVISO, GOLPE y RECUPERACIÓN; entre ataques te rodea. Hoy, un ataque: LA EMBESTIDA.
##   · RODEA: la cintura te mira siempre; las orugas se acercan si estás lejos, se alejan si estás encima y, en el medio,
##     andan de costado a vos (un tanque no camina de costado: va en diagonal). Al rato, si estás a tiro, embiste.
##   · LA EMBESTIDA: AVISO, frena, se da vuelta hacia vos y ABRE EL HORNO (la ventana para pegarle; el usuario: «una
##     window antes de que empiece a embestir que… se abre la puerta»); GOLPE, arranca derecho, corrigiendo poco; si te
##     alcanza, te saca vida (y a la meca física la empuja). Si llega al BORDE DE LA ARENA, SE ESTRELLA y queda aturdido
##     con el horno abierto (otra ventana). Si no, frena y se recupera, y cierra el horno.
##   · EL GOLPE DOBLE AL PISO (15/11/2026): AVISO, levanta los dos brazos y en el piso aparece la franja por donde va a
##     salir la onda (sigue a la cintura, que te mira); GOLPE, los puños al piso y sale LA ONDA (BrawlerWave), un lomo
##     de tierra que corre derecho; si te alcanza, te saca vida (si la saltás más alto que el lomo o te corrés de costado, no).
##   · CUÁL: al terminar de rodear, uno de los que tengan tu distancia a tiro, al azar (la L de la parcela deja uno).
## LA VIDA, POR CÓDIGO (Health): las piñas de la meca que tocan el cuerpo le sacan poco; en el horno abierto, mucho.
## Mientras alguien lo posee, la cabeza no hace nada.

enum Act { STALK, CHARGE, SLAM }
## QUÉ ATAQUES USA (la L de la parcela): todos, o uno solo.
enum Moves { ALL, CHARGE, SLAM }
const MOVES_NAMES := ["todos", "sólo la embestida", "sólo el golpe al piso"]
static var moves := Moves.ALL

## Las distancias que deciden (m, del medio del Luchador al blanco): se queda entre `KEEP`; embiste entre `CHARGE_RANGE`.
const KEEP := Vector2(45.0, 80.0)
const CHARGE_RANGE := Vector2(35.0, 140.0)
## El golpe al piso, entre estas (m).
const SLAM_RANGE := Vector2(25.0, 120.0)
## Cuánto tarda el golpe en llegar al piso (s) y a cuánto adelante de él sale la onda (m, desde su frente).
const SLAM_FALL := 0.15
const WAVE_AHEAD := 4.0
## Rodeando: cuánto (s, entre los dos).
const STALK_TIME := Vector2(2.0, 4.0)
## La embestida: cuánto tiene que estar de frente para arrancar (radianes) y la recuperación (s).
const AIMED := 0.12
const RECOVER := 1.5
## A cuánto de su frente cuenta que te alcanzó (m, además de tu radio).
const REACH := 3.0
## Las piñas: a cuánto del horno cuentan en él (m), y a cuánto de su caja en el cuerpo.
const FURNACE_REACH := 5.0
const BODY_REACH := 3.0
## El blanco, si no dice el suyo: su radio y su alto (m).
const TARGET_RADIUS := 4.0
const TARGET_HEIGHT := 18.0

## A quién pelea (lo pone quien arma la parcela).
var target: Node3D = null
## Si piensa (la tecla de la parcela lo apaga).
var awake := true
## Qué está haciendo, y en qué tiempo (para mirar).
var act := Act.STALK
var stage := ""
## Lo que pasó (para mirar): cuántas embestidas, cuántas te alcanzaron, cuántas veces se estrelló, y las piñas que
## recibió en el cuerpo y en el horno.
var charges := 0
var landed := 0
var crashes := 0
var body_hits := 0
var furnace_hits := 0
var slams := 0
var waved := 0

var _boss: Brawler = null
var _clock := 0.0
var _step := 0
var _side := 1.0
var _stalk_time := 3.0
var _hit_this_act := false
var _random := RandomNumberGenerator.new()
var _punched := {}
var _label: Label3D = null
var _wave: BrawlerWave = null
var _waves: Array[BrawlerWave] = []


func _ready() -> void:
	_boss = get_parent() as Brawler
	_random.randomize()
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 320
	_label.outline_size = 80
	_label.pixel_size = 0.02
	_label.no_depth_test = true
	_label.position = Vector3.UP * 40.0
	_boss.add_child(_label)
	_begin(Act.STALK)


func _physics_process(delta: float) -> void:
	_show()
	if target == null or not is_instance_valid(target):
		return
	# Las piñas de la meca cuentan aunque no piense o lo posea alguien.
	_check_punches()
	_check_waves()
	if _boss.driven():
		return
	if not awake:
		if stage != "quieto":
			_still()
		return
	var own := Health.of(_boss)
	if own != null and own.dead():
		_end("derrotado")
		return
	var theirs := Health.of(target)
	if theirs != null and theirs.dead():
		_end("ganó")
		return
	if stage in ["quieto", "derrotado", "ganó"]:
		_begin(Act.STALK)
	_clock += delta
	_boss.aim_yaw = _yaw_to_target()
	match act:
		Act.STALK:
			_stalk()
		Act.CHARGE:
			_charge()
		Act.SLAM:
			_slam()


## ── LOS ACTOS ────────────────────────────────────────────────────────────────────────────────────────────────────

## RODEA: se acerca, se aleja o va en diagonal, mirándote; al rato, si estás a tiro, embiste.
func _stalk() -> void:
	stage = "rodea"
	var gap := _distance()
	var toward := _to_target().normalized()
	var way := toward
	if gap < KEEP.x:
		way = -toward
	elif gap < KEEP.y:
		way = toward.rotated(Vector3.UP, _side * deg_to_rad(70.0))
	_drive(way, 0.8)
	if _clock < _stalk_time:
		return
	var can: Array[Act] = []
	if moves != Moves.SLAM and gap > CHARGE_RANGE.x and gap < CHARGE_RANGE.y:
		can.append(Act.CHARGE)
	if moves != Moves.CHARGE and gap > SLAM_RANGE.x and gap < SLAM_RANGE.y:
		can.append(Act.SLAM)
	if not can.is_empty():
		_begin(can[_random.randi() % can.size()])


## LA EMBESTIDA, por tiempos (`_step`): 0 el aviso, 1 arranca, 2 frena, 3 aturdido, 4 se recupera.
func _charge() -> void:
	var k := BrawlerSettings.current
	match _step:
		0:
			stage = "embestida: abre el horno"
			_boss.furnace = true
			_boss.pose = Brawler.Pose.CHARGE_READY
			# Se da vuelta hacia vos, quieto.
			var error := _error_to(_to_target())
			_boss.move = Vector2(clampf(-error * 3.0, -1.0, 1.0), 0.0)
			if _clock >= k.charge_windup and absf(error) < AIMED:
				charges += 1
				_next(1)
		1:
			stage = "embestida: ¡arranca!"
			_boss.charging = true
			_boss.pose = Brawler.Pose.CHARGING
			var error := _error_to(_to_target())
			var correct := k.charge_homing / maxf(k.turn_speed, 1.0)
			_boss.move = Vector2(clampf(-error * 3.0, -correct, correct), 1.0)
			_check_ram(k)
			var ahead := _boss.heading()
			var passed := ahead.dot(_to_target()) < 0.0 and _distance() > 20.0
			if _boss.arena != null and _boss.arena.at_edge(_boss.global_position, Brawler.BOX.x * 0.5 + 0.5):
				# CONTRA EL BORDE: se estrella.
				crashes += 1
				_boss.stop()
				_boss.charging = false
				_boss.move = Vector2.ZERO
				_next(3)
			elif _clock >= k.charge_time or passed:
				_next(2)
		2:
			stage = "embestida: frena"
			_boss.pose = Brawler.Pose.REST
			_boss.move = Vector2(0.0, -1.0) if _boss.speed > 1.0 else Vector2.ZERO
			if _boss.speed <= 1.0:
				_boss.charging = false
				_boss.furnace = false
				_next(4)
		3:
			stage = "¡se estrelló! aturdido"
			_boss.pose = Brawler.Pose.STUNNED
			_boss.move = Vector2.ZERO
			if _clock >= k.stun_time:
				_boss.furnace = false
				_next(4)
		_:
			stage = "embestida: se recupera"
			_boss.pose = Brawler.Pose.REST
			_boss.move = Vector2.ZERO
			if _clock >= RECOVER:
				_begin(Act.STALK)


## EL GOLPE AL PISO, por tiempos (`_step`): 0 los brazos arriba y la franja, 1 el golpe (sale la onda), 2 se queda.
func _slam() -> void:
	var k := BrawlerSettings.current
	var waist := Basis(Vector3.UP, _boss.waist_yaw) * Vector3.FORWARD
	var mouth := _boss.global_position + waist * (Brawler.BOX.z * 0.5 + WAVE_AHEAD)
	match _step:
		0:
			stage = "golpe al piso: levanta los brazos"
			_boss.pose = Brawler.Pose.SLAM_READY
			# Las orugas, de frente a vos, quietas; la franja sigue a la cintura.
			_boss.move = Vector2(clampf(-_error_to(_to_target()) * 3.0, -1.0, 1.0), 0.0)
			if _wave == null:
				_wave = BrawlerWave.new()
				_wave.name = "Onda"
				_boss.get_parent().add_child(_wave)
				_wave.setup(k.wave_width, k.wave_reach)
			_wave.aim(mouth, waist)
			if _clock >= k.slam_windup:
				slams += 1
				_boss.pose = Brawler.Pose.SLAM
				_next(1)
		1:
			stage = "¡golpe al piso!"
			_boss.move = Vector2.ZERO
			if _clock >= SLAM_FALL:
				_wave.launch(k.wave_speed)
				_waves.append(_wave)
				_wave = null
				_next(2)
		_:
			stage = "golpe al piso: se recupera"
			_boss.move = Vector2.ZERO
			if _clock >= k.slam_recover:
				_begin(Act.STALK)


## LAS ONDAS QUE CORREN: si una te pasa por debajo apoyada, te saca vida (una vez cada una).
func _check_waves() -> void:
	var k := BrawlerSettings.current
	var body := target as BalanceBody
	for wave in _waves.duplicate():
		if not is_instance_valid(wave):
			_waves.erase(wave)
			continue
		# SALTANDO, la pasa si va más alto que el lomo (la cinemática: lo que la mueve está en el piso de sus pies).
		var over := body != null and not body.grounded
		if over and body.mover != null:
			over = body.mover.global_position.y - wave.origin.y > BrawlerWave.RIDGE.x
		if over or not wave.covers(_ground(), _target_half_width()):
			continue
		_waves.erase(wave)
		waved += 1
		var theirs := Health.of(target)
		if theirs != null:
			theirs.hurt(k.wave_damage, "el golpe al piso")
		if body != null and not body.kinematic:
			BalanceBody.hit(body, (wave.way * 0.3 + Vector3.UP).normalized() * k.wave_push * body.mass)


## SI TE ALCANZA: una vez por embestida, si su frente llega a vos: estás adelante, a menos de `REACH` de su frente, y
## de costado, dentro del ancho de las orugas (lo que se ve: si te corriste lo suficiente, te pasa al lado).
func _check_ram(k: BrawlerSettings) -> void:
	if _hit_this_act:
		return
	var gap := _to_target()
	var ahead := _boss.heading().dot(gap)
	var aside := absf(_boss.heading().cross(Vector3.UP).dot(gap))
	var radius := _target_radius()
	var half := _target_half_width()
	if ahead < 0.0 or ahead > Brawler.BOX.z * 0.5 + radius + REACH or aside > Brawler.BOX.x * 0.5 + half:
		return
	_hit_this_act = true
	landed += 1
	var theirs := Health.of(target)
	if theirs != null:
		theirs.hurt(k.charge_damage, "la embestida")
	var body := target as RigidBody3D
	if body != null and not (target is BalanceBody and (target as BalanceBody).kinematic):
		var way := (_boss.heading() * 0.8 + Vector3.UP * 0.2).normalized()
		BalanceBody.hit(body, way * k.charge_push * body.mass)


## ── MANEJAR ──────────────────────────────────────────────────────────────────────────────────────────────────────

## LAS ORUGAS HACIA `way` (de costado): giran hacia ahí y, si ya miran más o menos para ahí, andan (a `push`).
func _drive(way: Vector3, push: float) -> void:
	var error := _error_to(way)
	_boss.move = Vector2(clampf(-error * 2.0, -1.0, 1.0), push if absf(error) < 0.6 else 0.15)


## Cuánto les falta a las orugas para mirar hacia `way` (radianes; positivo, a la izquierda).
func _error_to(way: Vector3) -> float:
	return wrapf(atan2(-way.x, -way.z) - _boss.hull_yaw, -PI, PI)


func _begin(next: Act) -> void:
	act = next
	_clock = 0.0
	_step = 0
	_hit_this_act = false
	_boss.charging = false
	_boss.pose = Brawler.Pose.REST
	_drop_warning()
	if next == Act.STALK:
		_boss.furnace = false
		_side = -1.0 if _random.randf() < 0.5 else 1.0
		_stalk_time = _random.randf_range(STALK_TIME.x, STALK_TIME.y)


func _next(step: int) -> void:
	_step = step
	_clock = 0.0


## ── EL BLANCO ────────────────────────────────────────────────────────────────────────────────────────────────────

func _to_target() -> Vector3:
	var gap := _ground() - _boss.global_position
	gap.y = 0.0
	return gap


func _distance() -> float:
	return _to_target().length()


func _yaw_to_target() -> float:
	var way := _to_target()
	return atan2(-way.x, -way.z)


## EL PUNTO DEL PISO debajo del blanco: de una meca cinemática, el de lo que la mueve; de una física, debajo de su caja.
func _ground() -> Vector3:
	var body := target as BalanceBody
	if body != null and body.mover != null:
		return body.mover.global_position
	if body != null:
		var from := body.global_position
		var ray := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 60.0, PhysicsLayers.FIXED)
		var hit := body.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			return hit["position"]
	return target.global_position


## El medio ancho del blanco (m): de costado, lo que tiene que correrse para que el Luchador le pase al lado.
func _target_half_width() -> float:
	var body := target as BalanceBody
	if body != null:
		return maxf(body.size.x, body.size.z) * 0.5
	return TARGET_RADIUS


func _target_radius() -> float:
	var body := target as BalanceBody
	if body != null:
		return Vector2(body.size.x, body.size.z).length() * 0.5
	return TARGET_RADIUS


## ── LO QUE LE PEGA A ÉL ──────────────────────────────────────────────────────────────────────────────────────────

## LAS PIÑAS DE LA MECA: el puño (su MechHand), con el brazo estirado, cerca del horno abierto le saca mucho; en el
## cuerpo, poco. Una vez por piña.
func _check_punches() -> void:
	var mech := target as Mech
	var own := Health.of(_boss)
	if mech == null or own == null:
		return
	var k := BrawlerSettings.current
	var mouth := _boss.furnace_point()
	var center := _boss.global_position + Vector3.UP * Brawler.BOX.y * 0.5
	for arm in mech.arms:
		var key := arm.get_instance_id()
		var now := arm.stage()
		if now == MechArm.Stage.IDLE or now == MechArm.Stage.WINDUP:
			_punched.erase(key)
			continue
		# Se decide con el brazo estirado (al empezar el golpe, el puño todavía está lejos del horno).
		if _punched.has(key) or now != MechArm.Stage.HOLD:
			continue
		for hand: Node3D in arm.find_children("*", "MechHand", true, false):
			var at := hand.global_position
			if _boss.opened > 0.5 and at.distance_to(mouth) < FURNACE_REACH:
				_punched[key] = true
				furnace_hits += 1
				own.hurt(k.furnace_damage, "una piña en el horno")
				break
			var local := _boss.global_transform.affine_inverse() * at
			var half := Brawler.BOX * 0.5 + Vector3.ONE * BODY_REACH
			if absf(local.x) < half.x and absf(local.z) < half.z and local.y > -1.0 and local.y < Brawler.BOX.y + 1.0:
				_punched[key] = true
				body_hits += 1
				own.hurt(k.punch_damage, "una piña")
				break


## ── LO DEMÁS ─────────────────────────────────────────────────────────────────────────────────────────────────────

func _end(why: String) -> void:
	if stage == why:
		return
	_still()
	stage = why


## Si quedó una franja de aviso sin onda (lo cortaron), se va.
func _drop_warning() -> void:
	if _wave != null and is_instance_valid(_wave):
		_wave.queue_free()
	_wave = null


func _still() -> void:
	_drop_warning()
	_boss.pose = Brawler.Pose.REST
	_boss.move = Vector2.ZERO
	_boss.charging = false
	_boss.furnace = false
	stage = "quieto"


func _show() -> void:
	var head := stage if awake or stage == "derrotado" else "quieto (J lo despierta)"
	_label.text = "%s\nembistió %d · te alcanzó %d · se estrelló %d\ngolpes al piso %d · te alcanzaron %d" % [head,
		charges, landed, crashes, slams, waved]
	_label.modulate = Color(1.0, 0.55, 0.3) if stage.ends_with("abre el horno") or stage.begins_with("¡se") \
		or stage.ends_with("brazos") else Color(1, 1, 1)
