class_name ChargePower
extends BossPower

## LA EMBESTIDA (ver BossPower): AVISO, frena, se da vuelta hacia vos y abre el horno (la ventana); GOLPE, arranca
## derecho, corrigiendo poco; LA ZONA DE GOLPE es su cuerpo (Brawler.hit_shapes "cuerpo"; escala con él). Si llega al borde de la
## arena se estrella y queda aturdido con el horno abierto. Variante: con ira, rebota una vez en el borde y vuelve.
## Pide orugas que embistan («embestir»).

## Cuánto tiene que estar de frente para arrancar (radianes) y cuánto se queda después (s).
const AIMED := 0.12
const RECOVER := 1.5

@export_group("Embestida")
## El aviso (s), la velocidad (m/s) y en cuánto llega a ella (s), cuánto dura como mucho (s), cuánto corrige hacia vos
## (°/s: poco) y, estrellado, cuánto queda aturdido (s). Si te alcanza, cuánta vida te saca y cuánto te tira (m).
@export_range(0.2, 4.0, 0.05) var windup := 1.4
@export_range(5.0, 120.0, 0.5) var speed := 55.0
@export_range(0.0, 3.0, 0.05) var up_time := 0.3
@export_range(0.5, 8.0, 0.1) var time := 3.0
@export_range(0.0, 60.0, 1.0) var homing := 6.0
@export_range(0.2, 8.0, 0.1) var stun := 2.5
@export_range(0.0, 100.0, 1.0) var damage := 25.0
@export_range(0.0, 60.0, 0.5) var push := 22.0
## Con ira, rebota en el borde una vez (y vuelve) en vez de estrellarse.
@export var bounce_rage := true

@export_group("Cuerpo")
## Lo que usa del cuerpo (se elige entre lo que el cuerpo ofrece: ver BossPower).
@export var hit_zone := 0
@export var ready_pose := int(Brawler.Pose.CHARGE_READY)
@export var strike_pose := int(Brawler.Pose.CHARGING)
@export var exposes := true

## Cuántas veces se estrelló (para mirar).
var crashes := 0
var _bounced := false


func _init() -> void:
	reach_from = 35.0
	reach_to = 140.0


func title() -> String:
	return "embestida"


func needs() -> PackedStringArray:
	return PackedStringArray(["suelo"])


func labels() -> Dictionary:
	return BODY_LABELS.merged({"windup": "aviso: abre el horno (s)", "speed": "velocidad (m/s)", "up_time": "llega a ella en (s)",
		"time": "dura como mucho (s)", "homing": "corrige hacia vos (°/s)", "stun": "estrellado, aturdido (s)",
		"damage": "te saca (vida)", "push": "te tira (m)", "bounce_rage": "en modo fuerte, rebota en el borde"})


func start(_b: BrawlerBrain) -> void:
	_bounced = false


func act(b: BrawlerBrain, _delta: float) -> void:
	var boss := b.boss
	match b.step:
		0:
			b.stage = "embestida: abre el horno"
			b.expose(exposes)
			boss.pose = ready_pose as Brawler.Pose
			var error := b.error_to(b.to_target())
			boss.move = Vector2(clampf(-error * 3.0, -1.0, 1.0), 0.0)
			if b.clock >= windup and absf(error) < AIMED:
				uses += 1
				b.next(1)
		1:
			b.stage = "embestida: ¡arranca!"
			boss.rush(speed, up_time)
			boss.pose = strike_pose as Brawler.Pose
			var error := b.error_to(b.to_target())
			var correct := homing / maxf(BrawlerSettings.current.turn_speed, 1.0)
			boss.move = Vector2(clampf(-error * 3.0, -correct, correct), 1.0)
			# LA ZONA DE GOLPE: todo su cuerpo, mientras embiste.
			hits += int(b.hit_with([Brawler.ZONES[hit_zone]], 1.0, damage, "la embestida", HitReaction.Kind.KNOCKDOWN, boss.heading(),
				push))
			var passed := boss.heading().dot(b.to_target()) < 0.0 and b.distance() > 20.0
			var edge := boss.arena != null and boss.arena.at_edge(boss.global_position, boss.box().x * 0.5 + 0.5)
			if edge and bounce_rage and b.strong() and not _bounced:
				_bounced = true
				boss.stop()
				boss.rush(0.0)
				b.hit_once = false
				b.next(5)
			elif edge:
				crashes += 1
				boss.stop()
				boss.rush(0.0)
				boss.move = Vector2.ZERO
				b.next(3)
			elif b.clock >= time or passed:
				b.next(2)
		2:
			b.stage = "embestida: frena"
			boss.pose = Brawler.Pose.REST
			boss.move = Vector2(0.0, -1.0) if boss.speed > 1.0 else Vector2.ZERO
			if boss.speed <= 1.0:
				boss.rush(0.0)
				b.expose(false)
				b.next(4)
		3:
			b.stage = "¡se estrelló! aturdido"
			b.expose(true)
			boss.pose = Brawler.Pose.STUNNED
			boss.move = Vector2.ZERO
			if b.clock >= stun:
				b.expose(false)
				b.next(4)
		5:
			b.stage = "embestida: ¡rebota!"
			boss.pose = ready_pose as Brawler.Pose
			var error := b.error_to(b.to_target())
			boss.move = Vector2(clampf(-error * 3.0, -1.0, 1.0), 0.0)
			if b.clock >= 0.5 and absf(error) < AIMED * 2.0:
				b.next(1)
		_:
			b.stage = "embestida: se recupera"
			boss.pose = Brawler.Pose.REST
			boss.move = Vector2.ZERO
			if b.clock >= RECOVER:
				b.finish()


func drop(b: BrawlerBrain) -> void:
	b.boss.rush(0.0)
