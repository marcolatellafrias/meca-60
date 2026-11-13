class_name BallBrain
extends Node

## LA CABEZA DEL JEFE BOLA (13/11/2026), PASO 6: lo maneja la computadora. El usuario: «poné las variantes vos, pensá en
## bosses del Dark Souls». Lo que se toma de ahí:
##   · CADA ATAQUE TIENE TRES TIEMPOS: el AVISO (se ve venir: el cañón apunta, la bola se hunde, se pliega), el GOLPE y la
##     RECUPERACIÓN, el hueco para castigarlo. Los avisos son claros y las recuperaciones, largas en lo más fuerte.
##   · ELIGE POR DISTANCIA, con algo de azar, y NO REPITE el mismo ataque tres veces seguidas.
##   · ENTRE ATAQUES TE RODEA: de lejos se acerca, de cerca se aleja un poco, en el medio camina de costado mirándote.
##   · GIRA LENTO (su tope de giro): ponerse atrás es la forma de esquivarlo… salvo el barrido, que da la vuelta entera.
## Los ataques, por distancia (horizontal, del centro de la bola al blanco):
##   · CERCA (menos de `NEAR`): el BARRIDO (se hunde y barre) o, a veces, la CARGA.
##   · EN EL MEDIO: la RÁFAGA (apunta y tira tres derechos), la CARGA (se hace bola y rueda hacia vos, corrigiendo poco)
##     o los DEL CIELO.
##   · LEJOS (más de `FAR`): los DEL CIELO (uno donde estás y los otros adonde vas) o la ráfaga; si no, se acerca.
## LA VIDA (Health), TODO POR CÓDIGO: lo que agarra al blanco le saca vida según `DAMAGE` (y se cuenta, «te pegó»);
## las piñas del blanco que tocan la bola le sacan `PUNCH_DAMAGE` al jefe. A lo suelto lo empuja como siempre. Sin vida
## el jefe, se queda quieto; sin vida el blanco, deja de pelear. *El blanco de hoy es la meca simplificada, cinemática, que no se empuja: por eso sólo se cuenta.*
## Mientras alguien lo posee, la cabeza no hace nada.

enum Act { STALK, SHOTS, SKY, SWEEP, CHARGE }

const ACT_NAMES := {Act.STALK: "rodea", Act.SHOTS: "ráfaga", Act.SKY: "los del cielo", Act.SWEEP: "barrido",
	Act.CHARGE: "carga"}
## Las distancias que deciden (m).
const NEAR := 40.0
const FAR := 85.0
## Rodeando: cuánto (s, entre los dos) y a qué distancia se queda (m).
const STALK_TIME := Vector2(0.8, 1.8)
const STALK_KEEP := Vector2(30.0, 70.0)
## LA RÁFAGA: aviso (s), cuántos tiros, entre uno y otro (s) y la recuperación (s).
const SHOTS_WINDUP := 0.8
const SHOTS := 3
const SHOTS_GAP := 0.9
const SHOTS_RECOVER := 1.2
## LOS DEL CIELO: la recuperación (s) después del último (el aviso es el cañón subiendo).
const SKY_RECOVER := 1.6
## EL BARRIDO: aviso (s, la bola se hunde) y recuperación (s).
const SWEEP_WINDUP := 0.7
const SWEEP_RECOVER := 1.3
## LA CARGA: cuánto rueda como mucho (s), cuánto corrige hacia el blanco (radianes de error que acepta: poco) y la
## recuperación (s, ya abierta).
const CHARGE_TIME := 3.5
const CHARGE_HOMING := 0.12
const CHARGE_RECOVER := 1.8
## CUÁNTA VIDA SACA cada cosa (de 100 que tiene la meca).
const DAMAGE := {"el tiro": 6.0, "los del cielo": 10.0, "el barrido": 20.0, "la carga": 25.0}
## Lo que le saca al jefe una piña de la meca que toca la bola, y a cuánto de la bola cuenta (m).
const PUNCH_DAMAGE := 12.0
const PUNCH_REACH := 2.0
## El blanco, si no dice el suyo: su radio y su alto (m).
const TARGET_RADIUS := 4.0
const TARGET_HEIGHT := 18.0

## A quién pelea (lo pone quien arma al jefe).
var target: Node3D = null
## Si piensa (el panel chico lo apaga).
var awake := true
## Cuántas veces le pegó al blanco, y con qué la última (para mirar).
var landed := 0
var last_hit := ""
## Qué está haciendo, y en qué tiempo (para mirar).
var act := Act.STALK
var stage := ""

var _boss: BallBoss = null
var _clock := 0.0
var _count := 0
var _side := 1.0
var _history: Array[Act] = []
var _random := RandomNumberGenerator.new()
var _target_was := Vector3.ZERO
var _target_velocity := Vector3.ZERO
var _hit_this_act := false
var _label: Label3D = null
## Las piñas que ya pegaron (para contar una por piña): el brazo y su piña de ahora.
var _punched := {}
var _stalk_time := 1.0


func _ready() -> void:
	_boss = get_parent() as BallBoss
	_random.randomize()
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 320
	_label.outline_size = 80
	_label.pixel_size = 0.02
	_label.no_depth_test = true
	_boss.add_child(_label)
	if _boss.cannon.field != null:
		_boss.cannon.field.exploded.connect(_on_blast)
	_begin(Act.STALK)


func _physics_process(delta: float) -> void:
	_show()
	if target == null or not is_instance_valid(target):
		return
	# Las piñas de la meca cuentan aunque el jefe no piense o lo posea alguien.
	_check_punches()
	if _driven():
		return
	if not awake:
		# Al apagarse, lo deja quieto UNA vez: después no escribe nada (así lo puede manejar otro, como un test).
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
	if stage == "quieto" or stage == "derrotado" or stage == "ganó":
		_begin(Act.STALK)
	_track(delta)
	_clock += delta
	_check_touch()
	match act:
		Act.STALK:
			_stalk()
		Act.SHOTS:
			_shots()
		Act.SKY:
			_sky()
		Act.SWEEP:
			_sweep()
		Act.CHARGE:
			_charge()


## ── LOS ATAQUES ──────────────────────────────────────────────────────────────────────────────────────────────────

## RODEA: se acerca, se aleja o camina de costado, mirándote; al terminar, elige un ataque.
func _stalk() -> void:
	stage = "rodea"
	var gap := _distance()
	_face()
	var move := Vector2(_side * 0.6, 0.0)
	if gap > STALK_KEEP.y:
		move = Vector2(0.0, 1.0)
	elif gap < STALK_KEEP.x:
		move = Vector2(_side * 0.5, -0.6)
	_boss.move = move
	if _clock >= _stalk_time:
		_begin(_pick(gap))


## LA RÁFAGA: apunta (aviso), tira de a uno y se queda.
func _shots() -> void:
	_boss.move = Vector2.ZERO
	_face()
	_boss.aim_pitch = _pitch_to_target()
	if _clock < SHOTS_WINDUP:
		stage = "ráfaga: apunta"
		return
	if _count < SHOTS:
		stage = "ráfaga: tira"
		if _clock >= SHOTS_WINDUP + _count * SHOTS_GAP:
			_boss.cannon.shoot(BallBossSettings.current)
			_count += 1
		return
	stage = "ráfaga: se recupera"
	if _clock >= SHOTS_WINDUP + SHOTS * SHOTS_GAP + SHOTS_RECOVER:
		_boss.aim_pitch = 0.0
		_begin(Act.STALK)


## LOS DEL CIELO: uno donde estás y los otros adonde vas; el cañón sube solo (el aviso) y vuelve.
func _sky() -> void:
	_boss.move = Vector2.ZERO
	_face()
	if _count == 0:
		_boss.aim_pitch = 0.0
		_boss.cannon.barrage(BallBossSettings.current, _sky_targets())
		_count = 1
		_clock = 0.0
	if _boss.cannon.busy():
		stage = "los del cielo: tira"
		_clock = 0.0
		return
	stage = "los del cielo: se recupera"
	if _clock >= SKY_RECOVER:
		_begin(Act.STALK)


## EL BARRIDO: se hunde (el aviso), barre y se queda quieto mientras los pies vuelven.
func _sweep() -> void:
	_boss.move = Vector2.ZERO
	if _count == 0:
		stage = "barrido: se hunde"
		_boss.crouch = true
		if _clock >= SWEEP_WINDUP:
			_boss.crouch = false
			_boss.legs.sweep()
			_count = 1
			_hit_this_act = false
		return
	if _boss.legs.sweeping:
		stage = "barrido: barre"
		_clock = SWEEP_WINDUP
		return
	stage = "barrido: se recupera"
	if _clock >= SWEEP_WINDUP + SWEEP_RECOVER:
		_begin(Act.STALK)


## LA CARGA: se pliega (el aviso), rueda hacia vos corrigiendo poco, frena, se abre y queda expuesto.
func _charge() -> void:
	var roll := _boss.roll
	match _count:
		0:
			stage = "carga: se pliega"
			_boss.move = Vector2.ZERO
			_face()
			_boss.curl = true
			if roll.rolling():
				_count = 1
				_clock = 0.0
		1:
			stage = "carga: rueda"
			_boss.move = Vector2(0.0, 1.0)
			# Corrige poco: si te corrés a tiempo, pasa de largo.
			var error := wrapf(_yaw_to_target() - _boss.rotation.y, -PI, PI)
			_boss.aim_yaw = _boss.rotation.y + clampf(error, -CHARGE_HOMING, CHARGE_HOMING)
			var ahead := Basis(Vector3.UP, _boss.rotation.y) * Vector3.FORWARD
			var passed := ahead.dot(_to_target()) < 0.0 and _distance() > 25.0
			if _clock >= CHARGE_TIME or passed or _boss.is_on_wall():
				_count = 2
				_clock = 0.0
		2:
			stage = "carga: frena"
			_boss.move = Vector2.ZERO
			if absf(roll.speed) < 2.0:
				_boss.curl = false
				_count = 3
				_clock = 0.0
		_:
			stage = "carga: se recupera"
			if roll.fold <= 0.0 and _clock >= CHARGE_RECOVER:
				_begin(Act.STALK)


## ── ELEGIR ───────────────────────────────────────────────────────────────────────────────────────────────────────

func _pick(gap: float) -> Act:
	var weights := {}
	if gap < NEAR:
		weights = {Act.SWEEP: 3.0, Act.CHARGE: 1.0}
	elif gap < FAR:
		weights = {Act.SHOTS: 2.0, Act.CHARGE: 2.0, Act.SKY: 1.0}
	else:
		weights = {Act.SKY: 2.0, Act.SHOTS: 1.0}
	# No el mismo tres veces seguidas.
	if _history.size() >= 2 and _history[-1] == _history[-2] and weights.size() > 1:
		weights.erase(_history[-1])
	var total := 0.0
	for weight: float in weights.values():
		total += weight
	var roll := _random.randf() * total
	for choice: Act in weights.keys():
		roll -= float(weights[choice])
		if roll <= 0.0:
			return choice
	return weights.keys()[0]


func _begin(next: Act) -> void:
	act = next
	_clock = 0.0
	_count = 0
	_hit_this_act = false
	_boss.crouch = false
	if next == Act.STALK:
		_side = -1.0 if _random.randf() < 0.5 else 1.0
		_stalk_time = _random.randf_range(STALK_TIME.x, STALK_TIME.y)
	else:
		_history.append(next)
		if _history.size() > 4:
			_history.pop_front()


## ── EL BLANCO ────────────────────────────────────────────────────────────────────────────────────────────────────

## Dónde está y a cuánto va (se mide por diferencia: sirve para cualquier cosa).
func _track(delta: float) -> void:
	var here := _ground()
	if _target_was != Vector3.ZERO and delta > 0.0:
		_target_velocity = _target_velocity.lerp((here - _target_was) / delta, 0.2)
	_target_was = here


func _to_target() -> Vector3:
	var gap := _ground() - _boss.global_position
	gap.y = 0.0
	return gap


func _distance() -> float:
	return _to_target().length()


func _yaw_to_target() -> float:
	var way := _to_target()
	return atan2(-way.x, -way.z)


func _face() -> void:
	_boss.aim_yaw = _yaw_to_target()


## El ángulo del cañón para apuntarle al medio del blanco (desde el centro de la bola, que es donde gira).
func _pitch_to_target() -> float:
	var centre := _boss.global_position + Vector3.UP * _boss.center_height
	var aim := _ground() + Vector3.UP * _target_height() * 0.5
	return atan2(aim.y - centre.y, Vector2(aim.x - centre.x, aim.z - centre.z).length())


## LOS DEL CIELO: el primero donde estás y los otros adonde vas (cada uno cae un poco después), con algo de desorden.
func _sky_targets() -> Array[Vector3]:
	var k := BallBossSettings.current
	var out: Array[Vector3] = []
	var flat := _target_velocity
	flat.y = 0.0
	var space := _boss.get_world_3d().direct_space_state
	for i in k.barrage_count:
		var lead := 0.0 if i == 0 else (k.barrage_flight + i * k.barrage_gap) * 0.8
		var point := _ground() + flat * lead + Vector3(_random.randf_range(-4.0, 4.0), 0.0,
			_random.randf_range(-4.0, 4.0)) * float(mini(i, 1))
		var ray := PhysicsRayQueryParameters3D.create(point + Vector3.UP * 100.0, point + Vector3.DOWN * 100.0,
			PhysicsLayers.FIXED)
		ray.exclude = [_boss.ball().get_rid()]
		var hit := space.intersect_ray(ray)
		out.append(hit["position"] if not hit.is_empty() else point)
	return out


## EL PUNTO DEL PISO debajo del blanco: de una meca cinemática, el de lo que la mueve (su caja va arriba).
func _ground() -> Vector3:
	var body := target as BalanceBody
	if body != null and body.mover != null:
		return body.mover.global_position
	if body != null:
		# Una meca física: el piso debajo de su caja.
		var from := body.global_position
		var ray := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 60.0, PhysicsLayers.FIXED)
		var hit := body.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			return hit["position"]
	return target.global_position


## Su radio (m): de una meca, el de su cilindro (lo que abarca su caja); si no, `TARGET_RADIUS`.
func _target_radius() -> float:
	var body := target as BalanceBody
	if body != null:
		return Vector2(body.size.x, body.size.z).length() * 0.5 + 0.1
	return TARGET_RADIUS


## Su alto (m, del piso a lo más alto): de una meca, hasta el techo de su caja; si no, `TARGET_HEIGHT`.
func _target_height() -> float:
	var body := target as BalanceBody
	if body != null:
		return body.global_position.y + body.size.y * 0.5 - _ground().y
	return TARGET_HEIGHT


## ── LO QUE LE PEGA AL BLANCO (se cuenta; ver arriba) ─────────────────────────────────────────────────────────────

func _on_blast(at: Vector3, kind: Missile.Kind) -> void:
	if target == null or not is_instance_valid(target):
		return
	var reach: float = Missile.KINDS[kind]["radius"]
	var flat := Vector2(at.x - _ground().x, at.z - _ground().z).length()
	var height := at.y - _ground().y
	if flat < reach + _target_radius() and height > -2.0 and height < _target_height() + 2.0:
		_hit("el tiro" if kind == Missile.Kind.SHELL else "los del cielo")


## El barrido y la bola rodando: si la paleta o la bola tocan al blanco.
func _check_touch() -> void:
	var centre := _ground()
	var radius := _target_radius()
	if _boss.legs.sweeping and not _hit_this_act:
		for tentacle in _boss.legs.tentacles:
			var paddle := tentacle.rotor.global_position
			var flat := Vector2(paddle.x - centre.x, paddle.z - centre.z).length()
			if flat < BallLegs.SWEEP_TOUCH + radius and paddle.y < centre.y + _target_height():
				_hit_this_act = true
				_hit("el barrido")
				return
	# Rodando, una vez por carga: la bola lo atraviesa (no chocan), y si no contaría cada vez que lo toca.
	if _boss.roll.fold > 0.5 and absf(_boss.roll.speed) > BallBossSettings.current.hit_min_speed \
			and not _hit_this_act:
		var ball := _boss.global_position + Vector3.UP * _boss.center_height
		if Vector2(ball.x - centre.x, ball.z - centre.z).length() < BallBoss.RADIUS + radius:
			_hit_this_act = true
			_hit("la carga")


func _hit(what: String) -> void:
	landed += 1
	last_hit = what
	var theirs := Health.of(target)
	if theirs != null:
		theirs.hurt(float(DAMAGE.get(what, 10.0)), what)


## LAS PIÑAS DEL BLANCO: el puño (su MechHand) pegando, a menos de `PUNCH_REACH` de la bola, le saca vida al jefe. Una
## vez por piña.
func _check_punches() -> void:
	var mech := target as Mech
	var own := Health.of(_boss)
	if mech == null or own == null:
		return
	var ball := _boss.global_position + Vector3.UP * _boss.center_height
	for arm in mech.arms:
		var key := arm.get_instance_id()
		var stage_now := arm.stage()
		if stage_now == MechArm.Stage.IDLE or stage_now == MechArm.Stage.WINDUP:
			_punched.erase(key)
			continue
		if _punched.has(key) or (stage_now != MechArm.Stage.STRIKE and stage_now != MechArm.Stage.HOLD):
			continue
		for hand: Node3D in arm.find_children("*", "MechHand", true, false):
			if hand.global_position.distance_to(ball) < BallBoss.RADIUS + PUNCH_REACH:
				_punched[key] = true
				own.hurt(PUNCH_DAMAGE, "una piña (%s)" % MechArm.NAMES[arm.punching])
				break


## ── LO DEMÁS ─────────────────────────────────────────────────────────────────────────────────────────────────────

func _driven() -> bool:
	return _boss.driven()


## SE TERMINÓ LA PELEA (`why`): lo deja quieto y abierto, una vez.
func _end(why: String) -> void:
	if stage == why:
		return
	_still()
	_boss.cannon.cancel()
	stage = why


func _still() -> void:
	_boss.move = Vector2.ZERO
	_boss.crouch = false
	_boss.curl = false
	stage = "quieto"


func _show() -> void:
	_label.position = Vector3.UP * (_boss.center_height + BallBoss.RADIUS + 6.0)
	var head := stage if awake or stage == "derrotado" else "quieto (P lo despierta)"
	_label.text = "%s\nte pegó %d%s" % [head, landed, (" · %s" % last_hit) if landed > 0 else ""]
	_label.modulate = Color(1.0, 0.55, 0.3) if stage.ends_with("apunta") or stage.ends_with("se hunde") \
		or stage.ends_with("se pliega") else Color(1, 1, 1)
