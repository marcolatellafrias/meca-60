class_name SpinPower
extends BossPower

## EL TROMPO (ver BossPower): AVISO, abre los brazos y empieza a girar; GOLPE, gira andando derecho hacia donde
## estabas; LA ZONA DE GOLPE es la parte de afuera de cada brazo, hasta el puño (barriendo entre paso y paso; escala
## con él); te empuja de costado. Después queda mareado con el horno abierto (la ventana). Pide dos brazos.

## Desde qué parte del camino del hombro al puño pega.
const INNER := 0.9

@export_group("Trompo")
## El aviso (s), cuánto gira (s) y a cuántos °/s, a qué velocidad anda (m/s) y cuánto corrige hacia vos (°/s; 0,
## derecho), y cuánto queda mareado (s). Si te tocan los brazos, cuánta vida te saca y cuánto te empuja (m).
@export_range(0.2, 4.0, 0.05) var windup := 1.0
@export_range(0.5, 8.0, 0.1) var time := 3.5
@export_range(90.0, 1440.0, 10.0) var turn := 1080.0
@export_range(1.0, 40.0, 0.5) var move := 20.0
@export_range(0.0, 90.0, 1.0) var homing := 0.0
@export_range(0.2, 6.0, 0.1) var dizzy := 2.0
@export_range(0.0, 100.0, 1.0) var damage := 20.0
@export_range(0.0, 60.0, 0.5) var push := 16.0

var _arms_were: Array[Vector3] = []


func _init() -> void:
	reach_from = 30.0
	reach_to = 110.0


func title() -> String:
	return "trompo"


func needs() -> PackedStringArray:
	return PackedStringArray(["brazos"])


func labels() -> Dictionary:
	return {"windup": "aviso: abre los brazos (s)", "time": "gira (s)", "turn": "a (°/s)", "move": "anda a (m/s)",
		"homing": "corrige hacia vos (°/s)", "dizzy": "mareado, horno abierto (s)", "damage": "te saca (vida)",
		"push": "te empuja (m)"}


func start(_b: BrawlerBrain) -> void:
	_arms_were.clear()


func act(b: BrawlerBrain, delta: float) -> void:
	var boss := b.boss
	match b.step:
		0:
			b.stage = "trompo: abre los brazos"
			boss.pose = Brawler.Pose.SPIN_READY
			b.face()
			boss.spin = turn * 0.25 * clampf(b.clock / maxf(windup, 0.01), 0.0, 1.0)
			if b.clock >= windup:
				uses += 1
				b.next(1)
		1:
			b.stage = "¡trompo!"
			boss.pose = Brawler.Pose.SPIN
			boss.spin = turn
			boss.rush(move, 0.3)
			var correct := homing / maxf(BrawlerSettings.current.turn_speed, 1.0)
			boss.move = Vector2(clampf(-b.error_to(b.to_target()) * 3.0, -correct, correct), 1.0)
			_check_arms(b)
			if b.clock >= time:
				boss.rush(0.0)
				b.next(2)
		_:
			b.stage = "trompo: mareado"
			boss.pose = Brawler.Pose.STUNNED
			boss.spin = move_toward(boss.spin, 0.0, turn * 2.0 * delta)
			boss.move = Vector2.ZERO
			boss.furnace = true
			if b.clock >= dizzy:
				b.finish()


func drop(b: BrawlerBrain) -> void:
	b.boss.rush(0.0)


## LOS BRAZOS (la zona de golpe: de `INNER` al puño, barriendo entre un paso y el otro). Una vez por trompo.
func _check_arms(b: BrawlerBrain) -> void:
	var boss := b.boss
	var arms: Array[Vector3] = []
	var fists := boss.body.fists()
	for index in boss.body.shoulders.size():
		arms.append(boss.body.shoulders[index].global_position.lerp(fists[index], INNER))
		arms.append(fists[index])
	var were := _arms_were if _arms_were.size() == arms.size() else arms
	_arms_were = arms
	if b.hit_once:
		return
	for sub in 4:
		var t := (sub + 1) / 4.0
		for pair in range(0, arms.size(), 2):
			var from := were[pair].lerp(arms[pair], t)
			var to := were[pair + 1].lerp(arms[pair + 1], t)
			for along in 7:
				var point := from.lerp(to, along / 6.0)
				if b.touches_target(point, boss.fist() * 0.8):
					if b.strike(damage, "el trompo", HitReaction.Kind.PUSH,
							Vector3.UP.cross(b.to_target().normalized()) * signf(boss.spin), push, point):
						b.hit_once = true
						hits += 1
					return
