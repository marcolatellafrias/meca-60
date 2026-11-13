class_name BossBrain
extends RefCounted

## EL CEREBRO DE UNA MECA ENEMIGA (13/11/2026) — TRABAJO EN CURSO: escribe LO QUE SE LE PIDE al cuerpo (`move`,
## `aim_yaw`, `jump`), como las teclas de la meca propia, y elige los ataques. Corre SÓLO EN EL HOST.
##   · QUIETA: no hace nada (para mirarla).
##   · PELEA: busca la meca propia más cercana, la mira, se queda a su distancia (cerca si tiene algo que pega de cerca;
##     lejos si no, moviéndose de costado) y la ataca de a un ataque por vez, con una pausa entre uno y otro. Con patas,
##     también SALTA Y CAE: una onda al ras que hay que saltar. Con menos vida, pausas más cortas.

enum Mode { STILL, FIGHT }

## Lejos: cuánto deja entre su caja y la otra, si no pega de cerca (m). Cerca, lo que alcanzan sus manos (ver
## BossMech.melee_gap). Y la pausa entre ataques (s).
const FAR := 40.0
const PAUSE := 1.6
## El salto: cuánto lo carga (s).
const JUMP_HOLD := 0.5

var mode := Mode.FIGHT
var boss: BossMech = null

var _wait := 2.0
var _turn := 0
var _strafe := 1.0
var _strafe_clock := 0.0
var _jump_clock := -1.0
var _random := RandomNumberGenerator.new()


func _init(owner: BossMech) -> void:
	boss = owner
	_random.randomize()


func think(delta: float) -> void:
	boss.move = Vector2.ZERO
	boss.jump = false
	if boss.broken or ProjectileField.is_client(boss):
		return
	if _jump_clock >= 0.0:
		_jump_clock += delta
		boss.jump = _jump_clock < JUMP_HOLD
		if _jump_clock >= JUMP_HOLD:
			_jump_clock = -1.0
	if mode == Mode.FIGHT:
		var target := _target()
		if target == null:
			return
		_approach(delta, target)
		_attacks(delta, target)


## LA MIRA Y LA DISTANCIA (ver arriba).
func _approach(delta: float, target: Node3D) -> void:
	var flat := target.global_position - boss.global_position
	flat.y = 0.0
	if boss.rooted():
		return
	boss.aim_yaw = atan2(-flat.x, -flat.z)
	# LA DISTANCIA, DE BORDE A BORDE: las dos cajas son grandes.
	var gap := flat.length() - boss.size.x * 0.5 - BossBrain.half_of(target)
	var want := boss.melee_gap() if boss.design.melee() else FAR
	var forward := clampf((gap - want) / 8.0, -1.0, 1.0)
	_strafe_clock -= delta
	if _strafe_clock <= 0.0:
		_strafe_clock = _random.randf_range(2.0, 4.0)
		_strafe = -_strafe
	var sideways := 0.0 if boss.design.melee() else _strafe * 0.5
	boss.move = Vector2(sideways, forward)


## LOS ATAQUES: de a uno, con una pausa; con menos vida, más seguido.
func _attacks(delta: float, target: Node3D) -> void:
	if target == null:
		return
	if boss.busy() or _jump_clock >= 0.0:
		return
	_wait -= delta
	if _wait > 0.0:
		return
	var options := boss.attack_names()
	if options.is_empty():
		return
	var name: String = options[_turn % options.size()]
	_turn += 1
	var length := start(name, target)
	var calm := lerpf(0.45, 1.0, boss.health / boss.max_health)
	_wait = length + PAUSE * calm


## EMPIEZA EL ATAQUE `name` (ver BossMech.attack_names) contra `target`; devuelve cuánto dura.
func start(name: String, target: Node3D) -> float:
	if name == "salto":
		_jump_clock = 0.0
		boss.stomp_armed = true
		return 1.5
	return boss.attack_with(name, target)


## El próximo ataque, ya (la tecla de la parcela).
func attack_now() -> void:
	_wait = 0.0


## A QUIÉN: la meca propia (con brazos) más cercana de su parcela.
func _target() -> Mech:
	var parcel := SandboxParcel.owner_of(boss)
	var holder: Node = parcel if parcel != null else boss.get_parent()
	var best: Mech = null
	var nearest := INF
	for mech: Mech in holder.find_children("*", "Mech", true, false):
		if mech.arms_kind == Mech.Arms.NONE:
			continue
		var far := mech.global_position.distance_to(boss.global_position)
		if far < nearest:
			nearest = far
			best = mech
	return best


## ── LO QUE SE MIDE DE LO QUE SE ATACA (una meca, o un punto en el piso) ────────────────────────────────────────

## Media caja de costado (m): lo que hay del centro al borde.
static func half_of(target: Node3D) -> float:
	var body := target as BalanceBody
	return body.size.x * 0.5 if body != null else 0.0


## De borde a borde, en el piso (m).
static func gap(boss: BalanceBody, target: Node3D) -> float:
	return BossBrain.flat_distance(boss, target) - boss.size.x * 0.5 - BossBrain.half_of(target)


static func flat_distance(from: Node3D, to: Node3D) -> float:
	var flat := to.global_position - from.global_position
	return Vector2(flat.x, flat.z).length()


## Su punto en el piso.
static func ground_of(target: Node3D, boss: BalanceBody) -> Vector3:
	var floor_y := boss.support.y
	var body := target as BalanceBody
	if body != null and body.grounded:
		floor_y = body.support.y
	return Vector3(target.global_position.x, floor_y, target.global_position.z)


## Su centro (adonde se apunta).
static func centre_of(target: Node3D) -> Vector3:
	return target.global_position


static func velocity_of(target: Node3D) -> Vector3:
	var body := target as RigidBody3D
	return body.linear_velocity if body != null else Vector3.ZERO


## CUÁN ALTO LLEGA SU CAJA PARADA DERECHA, sobre su piso (m; para tirarle algo alto que se esquiva agachándose).
static func standing_top(target: Node3D) -> float:
	var body := target as BalanceBody
	if body == null:
		return 14.0
	return body.size.y + body.knobs.hover_height
