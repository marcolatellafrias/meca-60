class_name SpinPower
extends BossPower

## EL TROMPO (ver BossPower): AVISO, abre los brazos y empieza a girar; GOLPE, gira andando derecho hacia donde
## estabas; LA ZONA DE GOLPE es la parte de afuera de cada brazo, hasta el puño (barriendo entre paso y paso; escala
## con él); te empuja de costado. Después queda mareado con el horno abierto (la ventana). Pide dos brazos.

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

@export_group("Cuerpo")
## Lo que usa del cuerpo (se elige entre lo que el cuerpo ofrece: ver BossPower).
@export var hit_zone := 3
@export var ready_pose := int(Brawler.Pose.SPIN_READY)
@export var strike_pose := int(Brawler.Pose.SPIN)
@export var exposes := true

func _init() -> void:
	reach_from = 30.0
	reach_to = 110.0


func title() -> String:
	return "trompo"


func needs() -> PackedStringArray:
	return PackedStringArray(["suelo"])


func labels() -> Dictionary:
	return BODY_LABELS.merged({"windup": "aviso: abre los brazos (s)", "time": "gira (s)", "turn": "a (°/s)", "move": "anda a (m/s)",
		"homing": "corrige hacia vos (°/s)", "dizzy": "mareado, horno abierto (s)", "damage": "te saca (vida)",
		"push": "te empuja (m)"})


func act(b: BrawlerBrain, delta: float) -> void:
	var boss := b.boss
	match b.step:
		0:
			b.stage = "trompo: abre los brazos"
			boss.pose = ready_pose as Brawler.Pose
			b.face()
			boss.spin = turn * 0.25 * clampf(b.clock / maxf(windup, 0.01), 0.0, 1.0)
			if b.clock >= windup:
				uses += 1
				b.next(1)
		1:
			b.stage = "¡trompo!"
			boss.pose = strike_pose as Brawler.Pose
			boss.spin = turn
			boss.rush(move, 0.3)
			var correct := homing / maxf(BrawlerSettings.current.turn_speed, 1.0)
			boss.move = Vector2(clampf(-b.error_to(b.to_target()) * 3.0, -correct, correct), 1.0)
			# LA ZONA DE GOLPE: la punta de cada brazo, mientras gira.
			hits += int(b.hit_with([Brawler.ZONES[hit_zone]], 1.0, damage, "el trompo", HitReaction.Kind.PUSH,
				Vector3.UP.cross(b.to_target().normalized()) * signf(boss.spin), push))
			if b.clock >= time:
				boss.rush(0.0)
				b.next(2)
		_:
			b.stage = "trompo: mareado"
			boss.pose = Brawler.Pose.STUNNED
			boss.spin = move_toward(boss.spin, 0.0, turn * 2.0 * delta)
			boss.move = Vector2.ZERO
			b.expose(exposes)
			if b.clock >= dizzy:
				b.finish()


func drop(b: BrawlerBrain) -> void:
	b.boss.rush(0.0)
