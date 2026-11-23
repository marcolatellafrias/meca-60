class_name OrbsPower
extends BossPower

## TIRAR BOLITAS (22/11/2026; ver BossOrbField): el poder del contrato «muchas cosas para esquivar». Avisa con los brazos
## arriba y larga UN PATRÓN, elegido al azar:
##   · ABANICO: tres tandas abiertas hacia vos, cada una de un tipo.
##   · ANILLO: dos anillos para todos lados, de lentas y comunes, con un hueco para pasar.
##   · CHORRO: una fila de rápidas que te sigue.
##   · ESPIRAL: dos brazos que giran, de comunes y las que rebotan.
##   · MEZCLA: una de cada tipo, varias veces, repartidas alrededor tuyo.
## Apagado de entrada: lo prende su contrato (Experiments). La eléctrica aturde (MechStun); el escudo las frena y el dash
## intocable les pasa a través.

enum Pattern { FAN, RING, STREAM, SPIRAL, MIX }

@export_group("Bolitas")
## La velocidad de la común (m/s; las otras son partes de ésta), el aviso y lo que se queda después (s).
@export_range(2.0, 40.0, 0.5) var speed := 9.0
@export_range(0.1, 3.0, 0.05) var windup := 0.6
@export_range(0.1, 4.0, 0.05) var recover := 0.8
## Lo que sacan, lo que dura el stun de la eléctrica (s) y el radio del anillo donde rebotan (m).
@export_range(0.0, 50.0, 0.5) var damage := 4.0
@export_range(0.0, 50.0, 0.5) var slow_damage := 9.0
@export_range(0.1, 5.0, 0.05) var stun_time := 1.2
@export_range(6.0, 60.0, 0.5) var ring_radius := 20.0
## Cuántas salen: en cada tanda del abanico y en cada anillo.
@export_range(3, 15, 1) var fan_count := 7
@export_range(6, 40, 1) var ring_count := 20

@export_group("Cuerpo")
@export var from_point := 0
@export var ready_pose := int(Brawler.Pose.LIFT)
@export var strike_pose := int(Brawler.Pose.THROW)

const FAN_SPREAD := 62.0
const FAN_VOLLEYS := 3
const FAN_GAP := 0.5
const RING_VOLLEYS := 2
const RING_GAP := 0.9
const RING_HOLE := 3
const STREAM_SHOTS := 12
const STREAM_GAP := 0.11
const SPIRAL_SHOTS := 26
const SPIRAL_GAP := 0.09
const SPIRAL_TURN := 0.42
const MIX_VOLLEYS := 3
const MIX_GAP := 0.65
const MIX_SPREAD := 34.0

var field: BossOrbField = null
## Si no es -1, siempre este patrón (para las pruebas).
var forced := -1
var _pattern := Pattern.FAN
var _shots := 0
var _wait := 0.0
var _turn := 0.0
var _next_id := 1


func _init() -> void:
	in_calm = false
	in_mode_1 = false
	reach_from = 3.0
	reach_to = 40.0


func reach_knobs() -> PackedStringArray:
	return PackedStringArray(["speed", "ring_radius"])


func title() -> String:
	return "bolitas"


func labels() -> Dictionary:
	return BODY_LABELS.merged({"speed": "velocidad de la común (m/s)", "windup": "aviso (s)", "recover": "se queda después (s)",
		"damage": "te saca cada una (vida)", "slow_damage": "te saca la lenta (vida)", "stun_time": "la eléctrica aturde (s)",
		"ring_radius": "anillo donde rebotan (m)", "fan_count": "abanico: cuántas por tanda",
		"ring_count": "anillo: cuántas"})


func start(b: BrawlerBrain) -> void:
	_pattern = (forced if forced >= 0 else b.random.randi() % Pattern.size()) as Pattern
	_shots = 0
	_wait = 0.0
	_turn = b.yaw_to_target()
	uses += 1
	_ensure_field(b)


func act(b: BrawlerBrain, delta: float) -> void:
	var boss := b.boss
	match b.step:
		0:
			b.stage = "bolitas: junta energía"
			boss.pose = ready_pose as Brawler.Pose
			b.face()
			if b.clock >= windup:
				boss.pose = strike_pose as Brawler.Pose
				b.next(1)
		1:
			b.stage = "bolitas: tira"
			b.face()
			_wait -= delta
			if _wait <= 0.0 and not _fire(b):
				b.next(2)
		_:
			b.stage = "bolitas: terminó"
			boss.pose = Brawler.Pose.REST
			boss.move = Vector2.ZERO
			if b.clock >= recover:
				b.finish()


## SI ALGUNA TE ALCANZA: pega y se apaga. Con el dash intocable te pasa a través; el escudo la frena.
func tick(b: BrawlerBrain, _delta: float) -> void:
	if field == null or not is_instance_valid(field):
		return
	var reaction := HitReaction.of(b.target)
	if reaction.untouchable():
		return
	for orb: Dictionary in field.live():
		var at: Vector3 = orb["at"]
		if not b.touches_target(at, float(orb["radius"])):
			continue
		var id := int(orb["id"])
		if reaction.blocks(at):
			b.boss.net.fx_do(field, "pop", [id])
			continue
		var kind := int(orb["kind"])
		var hurt := slow_damage if kind == BossOrbField.Kind.SLOW else damage
		var away := Vector3(at.x, 0.0, at.z).direction_to(Vector3(b.ground().x, 0.0, b.ground().z))
		b.boss.net.fx_do(field, "pop", [id])
		if HitReaction.land(b.target, hurt, "una bolita", HitReaction.Kind.FLINCH, away, 0.0, at):
			hits += 1
			if kind == BossOrbField.Kind.STUN and b.target is ToolMech:
				(b.target as ToolMech).stun.hit(stun_time)


func _ensure_field(b: BrawlerBrain) -> void:
	if field != null and is_instance_valid(field):
		return
	field = b.boss.net.fx_make("orbs") as BossOrbField
	var floor_at := b.boss.global_position
	floor_at.y = b.ground().y
	b.boss.net.fx_do(field, "setup", [floor_at, ring_radius])


## LA TANDA QUE SIGUE del patrón. Devuelve false cuando ya no queda ninguna.
func _fire(b: BrawlerBrain) -> bool:
	var aim := b.yaw_to_target()
	var list: Array = []
	match _pattern:
		Pattern.FAN:
			if _shots >= FAN_VOLLEYS:
				return false
			var kinds := [BossOrbField.Kind.NORMAL, BossOrbField.Kind.FAST, BossOrbField.Kind.BOUNCE]
			var kind: int = kinds[b.random.randi() % kinds.size()]
			for index in fan_count:
				var share := float(index) / maxf(fan_count - 1, 1) - 0.5
				list.append([kind, aim + deg_to_rad(FAN_SPREAD) * share])
			_wait = FAN_GAP
		Pattern.RING:
			if _shots >= RING_VOLLEYS:
				return false
			var hole := b.random.randi() % ring_count
			var offset := b.random.randf() * TAU
			for index in ring_count:
				if posmod(index - hole, ring_count) < RING_HOLE:
					continue
				var each := BossOrbField.Kind.SLOW if index % 2 == 0 else BossOrbField.Kind.NORMAL
				list.append([each, offset + TAU * index / ring_count])
			_wait = RING_GAP
		Pattern.STREAM:
			if _shots >= STREAM_SHOTS:
				return false
			list.append([BossOrbField.Kind.FAST, aim])
			_wait = STREAM_GAP
		Pattern.SPIRAL:
			if _shots >= SPIRAL_SHOTS:
				return false
			_turn += SPIRAL_TURN
			list.append([BossOrbField.Kind.NORMAL, _turn])
			list.append([BossOrbField.Kind.BOUNCE, _turn + PI])
			_wait = SPIRAL_GAP
		Pattern.MIX:
			if _shots >= MIX_VOLLEYS:
				return false
			var mixed := [BossOrbField.Kind.STUN, BossOrbField.Kind.SPLIT, BossOrbField.Kind.SLOW, BossOrbField.Kind.BOUNCE,
				BossOrbField.Kind.FAST]
			mixed.shuffle()
			for index in mixed.size():
				var part := float(index) / (mixed.size() - 1) - 0.5
				list.append([mixed[index], aim + deg_to_rad(MIX_SPREAD) * part])
			_wait = MIX_GAP
	_shots += 1
	send(b, list)
	return true


## LANZA `list` ([tipo, rumbo]) desde su punto: una sola orden para todas las máquinas.
func send(b: BrawlerBrain, list: Array) -> void:
	send_from(b, b.boss.point(from_point), list)


func send_from(b: BrawlerBrain, from: Vector3, list: Array) -> void:
	_ensure_field(b)
	var items: Array = []
	for entry: Array in list:
		items.append([_next_id, from, float(entry[1]), int(entry[0]), speed])
		_next_id += 1
	b.boss.net.fx_do(field, "launch", [items])
