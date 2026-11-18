class_name ThrowPower
extends BossPower

## ARRANCAR EL PISO Y TIRARLO (ver BossPower): mete las manos y arranca un pedazo (queda el pozo, sale tierra); AVISO,
## lo levanta y en el piso aparece el círculo que te sigue; GOLPE, lo tira en arco y el círculo se queda donde estabas:
## la piedra (BrawlerRock) cae ahí. Variante: cuántas piedras (y con ira): la segunda va adonde vas. Pide dos brazos.

@export_group("Arrancar el piso")
## Cuánto tarda en arrancarlo (s), cuánto lo tiene arriba (s: el aviso), cuánto vuela (s), cuánto sube el arco (m), el
## radio del golpe (m), cuánto queda en el piso (s) y cuánto se queda después de tirarla (s). Cuántas piedras (y con
## ira). Si te alcanza, cuánta vida te saca y cuánto te tira (m).
@export_range(0.2, 4.0, 0.05) var rip_time := 1.0
@export_range(0.2, 4.0, 0.05) var lift_time := 1.1
@export_range(0.3, 4.0, 0.05) var flight := 1.8
@export_range(0.0, 80.0, 1.0) var arc := 35.0
@export_range(3.0, 25.0, 0.5) var radius := 12.0
@export_range(0.0, 30.0, 0.5) var stay := 8.0
@export_range(0.2, 4.0, 0.05) var recover := 1.2
@export_range(1, 3, 1) var count := 1
@export_range(1, 3, 1) var count_rage := 2
@export_range(0.0, 100.0, 1.0) var damage := 30.0
@export_range(0.0, 60.0, 0.5) var push := 10.0

## Las piedras en el aire.
var rocks: Array[BrawlerRock] = []
var _rock: BrawlerRock = null
var _dig := Vector3.ZERO
var _dirt_clock := 0.0


func _init() -> void:
	reach_from = 35.0
	reach_to = 130.0


func title() -> String:
	return "arrancar el piso"


func needs() -> PackedStringArray:
	return PackedStringArray(["brazos", "suelo"])


func labels() -> Dictionary:
	return {"rip_time": "mete las manos y lo arranca en (s)", "lift_time": "aviso: la tiene arriba (s)",
		"flight": "vuela (s)", "arc": "el arco sube (m)", "radius": "radio del golpe (m)", "stay": "queda en el piso (s)",
		"recover": "se queda después (s)", "count": "cuántas piedras", "count_rage": "cuántas, en modo fuerte",
		"damage": "te saca (vida)", "push": "te tira (m)"}


func act(b: BrawlerBrain, delta: float) -> void:
	var boss := b.boss
	var waist := b.waist()
	match b.step:
		0:
			b.stage = "arranca el piso: mete las manos"
			boss.pose = Brawler.Pose.DIG
			b.face()
			if _rock == null:
				_dig = boss.global_position + waist * (boss.box().z * 0.5 + BrawlerRock.SIZE.z * 0.5 + 1.0)
				_rock = _make(b)
			# Sale del piso de a poco, levantando tierra.
			var up := clampf(b.clock / maxf(rip_time, 0.01), 0.0, 1.0)
			_dirt_clock -= delta
			if _dirt_clock <= 0.0:
				_dirt_clock = 0.25
				BossBursts.dirt(b.world(), _dig + Vector3(b.random.randf_range(-6.0, 6.0), 0.0,
					b.random.randf_range(-5.0, 5.0)), 0.8)
			_rock.hold(_dig + Vector3.UP * lerpf(-BrawlerRock.SIZE.y * 0.5, BrawlerRock.SIZE.y * 0.5, up),
				boss.waist_yaw, null)
			if b.clock >= rip_time:
				b.next(1)
		1:
			b.stage = "arranca el piso: la levanta"
			boss.pose = Brawler.Pose.LIFT
			b.face()
			var hands := boss.body.fists()
			var over := (hands[0] + hands[1]) * 0.5 + Vector3.UP * (BrawlerRock.SIZE.y * 0.5 + 1.0)
			_rock.hold(_rock.held_at().lerp(over, 1.0 - exp(-6.0 * delta)), boss.waist_yaw, b.ground())
			if b.clock >= lift_time:
				uses += 1
				boss.pose = Brawler.Pose.THROW
				_rock.throw(b.ground(), flight, arc, stay)
				rocks.append(_rock)
				for extra in (count_rage if b.strong() else count) - 1:
					rocks.append(_ahead(b, extra))
				_rock = null
				b.next(2)
		_:
			b.stage = "arranca el piso: la tiró"
			boss.move = Vector2.ZERO
			if b.clock >= recover:
				b.finish()


## LAS PIEDRAS QUE CAEN: si te cae encima apoyada, te saca vida y se rompe; si cae sobre él, se rompe.
func tick(b: BrawlerBrain, _delta: float) -> void:
	rocks.assign(rocks.filter(func(rock: Variant) -> bool: return is_instance_valid(rock)))
	var body := b.target as BalanceBody
	for rock: BrawlerRock in rocks.duplicate():
		if not rock.just_landed:
			continue
		rock.just_landed = false
		rocks.erase(rock)
		var over := body != null and not body.grounded and body.mover != null
		over = over and body.mover.global_position.y - rock.spot.y > BrawlerRock.SIZE.y + 2.0
		if not over and rock.covers(b.ground(), b.half_width()):
			rock.shatter()
			hits += int(b.strike(damage, "la piedra", HitReaction.Kind.KNOCKDOWN, b.ground() - rock.spot, push,
				rock.spot + Vector3.UP * BrawlerRock.SIZE.y))
		elif rock.covers(b.boss.global_position, b.boss.box().x * 0.5):
			rock.shatter()


func drop(_b: BrawlerBrain) -> void:
	if _rock != null and is_instance_valid(_rock):
		_rock.queue_free()
	_rock = null


func _make(b: BrawlerBrain) -> BrawlerRock:
	var rock := BrawlerRock.new()
	rock.name = "Piedra"
	b.world().add_child(rock)
	rock.setup(_dig, b.boss.waist_yaw, radius)
	return rock


## UNA PIEDRA DE MÁS: sale de las mismas manos y va adonde vas (donde estarás cuando caiga); si estás quieta, al lado,
## para un costado (alternando).
func _ahead(b: BrawlerBrain, index: int) -> BrawlerRock:
	var other := _make(b)
	other.hold(_rock.held_at() + Vector3.UP * BrawlerRock.SIZE.y, b.boss.waist_yaw, null)
	var body := b.target as BalanceBody
	var going := body.velocity() if body != null else Vector3.ZERO
	going.y = 0.0
	var ahead := going * flight
	if ahead.length() < radius * 2.2:
		var side := Vector3.UP.cross(b.to_target().normalized()) * (1.0 if index % 2 == 0 else -1.0)
		if b.random.randf() < 0.5:
			side = -side
		ahead = side * radius * 2.2 * (1 + index / 2)
	other.throw(b.ground() + ahead, flight, arc, stay)
	return other
