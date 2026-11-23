class_name BombPower
extends BossPower

## EL BOMBARDEO (ver BossPower; de entrada, sólo volando): larga bombas por las chimeneas, una tras otra, que caen
## alrededor tuyo (BossShot). CADA BOMBA, AL CAER, pega en su círculo (BossZone) y, si se quiere, LARGA UN ANILLO que se
## abre por el piso y hay que saltar (el evento encadenado: «al caer, una onda»). Variantes: cuántas y cada cuánto, la
## zona, la dispersión, si son FÍSICAS (rebotan y no se sabe dónde terminan: no llevan marca; estallan al cabo de sus
## rebotes o si te tocan) y si largan el anillo.
## No pide nada del cuerpo: se usa en el piso o volando.

@export_group("Bombardeo")
## El aviso (s); cuántas bombas y cada cuánto (s); cuánto vuelan (s) y cuánto sube el arco (m); el radio del golpe (m)
## y a cuánto de vos caen como mucho (m: la primera, encima). Si te alcanza, cuánta vida te saca y cuánto te tira (m).
## Después se queda (s).
@export_range(0.2, 4.0, 0.05) var windup := 0.8
@export_range(1, 12, 1) var count := 4
@export_range(0.1, 3.0, 0.05) var interval := 0.5
@export_range(0.4, 5.0, 0.05) var flight := 1.6
@export_range(0.0, 80.0, 1.0) var arc := 8.0
@export_range(2.0, 30.0, 0.5) var radius := 3.0
@export_range(0.0, 60.0, 1.0) var scatter := 5.0
@export_range(0.0, 100.0, 1.0) var damage := 18.0
@export_range(0.0, 40.0, 0.5) var push := 3.0
@export_range(0.2, 4.0, 0.05) var recover := 1.0
## FÍSICAS: rebotan tantas veces antes de estallar (sin marca en el piso).
@export var physical := false
@export_range(0, 5, 1) var bounces := 2
## AL CAER, UN ANILLO que se abre por el piso (se salta): a qué velocidad (m/s) y hasta dónde (m).
@export var ring := false
@export_range(5.0, 80.0, 1.0) var ring_speed := 10.0
@export_range(5.0, 120.0, 1.0) var ring_reach := 10.0

@export_group("Cuerpo")
## Lo que usa del cuerpo (se elige entre lo que el cuerpo ofrece: ver BossPower).
@export var from_point := 5
@export var ready_pose := int(Brawler.Pose.FLAME_READY)
@export var strike_pose := int(Brawler.Pose.SLAM_READY)

## Los anillos que se abren (cada uno pega una vez).
var rings: Array[BossZone] = []
## Las bombas físicas en el aire (estallan también si te tocan).
var loose: Array[BossShot] = []
var _left := 0
var _next_at := 0.0
var _brain: BrawlerBrain = null


func _init() -> void:
	reach_from = 4.0
	reach_to = 13.0
	in_calm = false
	in_mode_1 = false
	in_mode_2 = true


func reach_knobs() -> PackedStringArray:
	return PackedStringArray(["arc", "radius", "scatter", "push", "ring_speed", "ring_reach"])


func title() -> String:
	return "bombardeo"


func labels() -> Dictionary:
	return BODY_LABELS.merged({"windup": "aviso (s)", "count": "cuántas bombas", "interval": "cada (s)", "flight": "vuelan (s)",
		"arc": "el arco sube (m)", "radius": "radio del golpe (m)", "scatter": "caen a hasta (m) de vos",
		"damage": "te saca (vida)", "push": "te tira (m)", "recover": "se queda después (s)",
		"physical": "físicas: rebotan (sin marca)", "bounces": "rebotes antes de estallar",
		"ring": "al caer, un anillo que se abre", "ring_speed": "el anillo corre a (m/s)", "ring_reach": "llega hasta (m)"})


func start(b: BrawlerBrain) -> void:
	_brain = b
	_left = count
	_next_at = 0.0


func act(b: BrawlerBrain, _delta: float) -> void:
	var boss := b.boss
	b.face()
	match b.step:
		0:
			b.stage = "bombardeo: carga"
			boss.pose = ready_pose as Brawler.Pose
			if b.clock >= windup:
				uses += 1
				b.next(1)
		1:
			b.stage = "¡bombardeo!"
			boss.pose = strike_pose as Brawler.Pose
			if _left > 0 and b.clock >= _next_at:
				_next_at += interval
				_drop_one(b, _left == count)
				_left -= 1
			if _left <= 0:
				b.next(2)
		_:
			b.stage = "bombardeo: se recupera"
			boss.pose = Brawler.Pose.REST
			if b.clock >= recover:
				b.finish()


## UNA BOMBA: sale de arriba suyo hacia vos (la primera, encima; las demás, alrededor).
func _drop_one(b: BrawlerBrain, first: bool) -> void:
	var from := b.boss.point(from_point)
	var off := Vector3.ZERO
	if not first:
		off = Vector3.RIGHT.rotated(Vector3.UP, b.random.randf() * TAU) * b.random.randf_range(scatter * 0.3, scatter)
	var to := b.ground() + off
	var size := radius * 0.35
	var shot: BossShot
	var mark: BossZone = null
	if physical:
		shot = b.boss.net.fx_make("toss", [from, to, flight, bounces, flight * 3.0, size]) as BossShot
		loose.append(shot)
	else:
		shot = b.boss.net.fx_make("shot", [from, to, flight, arc, size]) as BossShot
		mark = b.boss.net.fx_make("circle", [radius]) as BossZone
		b.boss.net.fx_set(mark, "locked", true)
		b.boss.net.fx_do(mark, "place", [to])
	BossSounds.play(BossSounds.Kind.WINDUP, from, b.world(), -8.0)
	shot.landed.connect(_blast.bind(mark))


## CAYÓ: el estallido (tierra, ruido), el golpe en su círculo y, si va, el anillo.
func _blast(at: Vector3, mark: BossZone) -> void:
	var b := _brain
	if b == null or not is_instance_valid(b):
		return
	var spot := Vector3(at.x, b.ground().y, at.z)
	if OS.get_cmdline_user_args().has("--ver-bombas"):
		print("   bomba: estalló a %.1f m de la meca, a %.1f m de alto" % [Vector2(at.x - b.ground().x, at.z - b.ground().z).length(), at.y])
	if mark == null or not is_instance_valid(mark):
		mark = BossZone.circle(b.world(), radius)
		mark.marked = false
		mark.place(spot)
	b.boss.net.fx_dirt(spot, radius / 8.0)
	BossSounds.play(BossSounds.Kind.KNOCKDOWN, spot, b.world())
	if mark.covers(b.ground(), b.half_width()) and b.feet_over(spot.y) < radius:
		hits += int(b.strike(damage, "una bomba", HitReaction.Kind.KNOCKDOWN, b.ground() - spot, push,
			spot + Vector3.UP * 2.0))
	mark.queue_free()
	if ring:
		var wave := b.boss.net.fx_make("ring", [radius, 3.0, ring_speed, ring_reach]) as BossZone
		b.boss.net.fx_set(wave, "locked", true)
		b.boss.net.fx_do(wave, "place", [spot])
		rings.append(wave)


## LOS ANILLOS: si uno te pasa por debajo apoyada, te pega (una vez cada uno); saltando, no.
func tick(b: BrawlerBrain, _delta: float) -> void:
	_brain = b
	rings.assign(rings.filter(func(each: Variant) -> bool: return is_instance_valid(each)))
	# LAS FÍSICAS: además de sus rebotes, estallan si te tocan.
	loose.assign(loose.filter(func(each: Variant) -> bool: return is_instance_valid(each)))
	for shot: BossShot in loose.duplicate():
		if b.touches_target(shot.at(), radius * 0.35):
			b.boss.net.fx_do(shot, "burst")
	for wave: BossZone in rings.duplicate():
		if b.feet_over(wave.origin.y) > 1.5 or not wave.covers(b.ground(), b.half_width()):
			continue
		rings.erase(wave)
		hits += int(b.strike(damage * 0.5, "el anillo de una bomba", HitReaction.Kind.PUSH, b.ground() - wave.origin,
			push, b.ground() + Vector3.UP * 2.0))
