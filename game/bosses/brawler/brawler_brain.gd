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
## LA VIDA, POR CÓDIGO (Health): las piñas de la meca que tocan el cuerpo le sacan poco; en el horno abierto, mucho.
## Mientras alguien lo posee, la cabeza no hace nada.

enum Act { STALK, CHARGE }

## Las distancias que deciden (m, del medio del Luchador al blanco): se queda entre `KEEP`; embiste entre `CHARGE_RANGE`.
const KEEP := Vector2(45.0, 80.0)
const CHARGE_RANGE := Vector2(35.0, 140.0)
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

var _boss: Brawler = null
var _clock := 0.0
var _step := 0
var _side := 1.0
var _stalk_time := 3.0
var _hit_this_act := false
var _random := RandomNumberGenerator.new()
var _punched := {}
var _label: Label3D = null


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
	if _clock >= _stalk_time and gap > CHARGE_RANGE.x and gap < CHARGE_RANGE.y:
		_begin(Act.CHARGE)


## LA EMBESTIDA, por tiempos (`_step`): 0 el aviso, 1 arranca, 2 frena, 3 aturdido, 4 se recupera.
func _charge() -> void:
	var k := BrawlerSettings.current
	match _step:
		0:
			stage = "embestida: abre el horno"
			_boss.furnace = true
			# Se da vuelta hacia vos, quieto.
			var error := _error_to(_to_target())
			_boss.move = Vector2(clampf(-error * 3.0, -1.0, 1.0), 0.0)
			if _clock >= k.charge_windup and absf(error) < AIMED:
				charges += 1
				_next(1)
		1:
			stage = "embestida: ¡arranca!"
			_boss.charging = true
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
			_boss.move = Vector2(0.0, -1.0) if _boss.speed > 1.0 else Vector2.ZERO
			if _boss.speed <= 1.0:
				_boss.charging = false
				_boss.furnace = false
				_next(4)
		3:
			stage = "¡se estrelló! aturdido"
			_boss.move = Vector2.ZERO
			if _clock >= k.stun_time:
				_boss.furnace = false
				_next(4)
		_:
			stage = "embestida: se recupera"
			_boss.move = Vector2.ZERO
			if _clock >= RECOVER:
				_begin(Act.STALK)


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


func _still() -> void:
	_boss.move = Vector2.ZERO
	_boss.charging = false
	_boss.furnace = false
	stage = "quieto"


func _show() -> void:
	var head := stage if awake or stage == "derrotado" else "quieto (J lo despierta)"
	_label.text = "%s\nembistió %d · te alcanzó %d · se estrelló %d" % [head, charges, landed, crashes]
	_label.modulate = Color(1.0, 0.55, 0.3) if stage.ends_with("abre el horno") or stage.begins_with("¡se") \
		else Color(1, 1, 1)
