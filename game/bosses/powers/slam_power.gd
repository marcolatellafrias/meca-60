class_name SlamPower
extends BossPower

## EL GOLPE AL PISO (ver BossPower): AVISO, levanta los brazos y en el piso aparece la franja por donde va a salir la
## onda (sigue a la cintura); GOLPE, los puños al piso (LA ZONA DE GOLPE: los puños, si estás justo adelante) y salen
## LAS ONDAS (BrawlerWave): lomos de tierra que corren derecho; se saltan o se esquivan de costado. Variantes: cuántas
## ondas (y con ira), abiertas en abanico. Pide dos brazos («brazos»).

## Cuánto tarda el golpe en llegar al piso (s) y a cuánto adelante de su frente salen las ondas (m).
const FALL := 0.15
const AHEAD := 4.0

@export_group("Golpe al piso")
## El aviso (s: los brazos arriba) y cuánto se queda después (s); la onda: a qué velocidad corre (m/s), hasta dónde
## (m) y qué ancho tiene (m); cuántas salen (y con ira), abiertas cuántos grados entre sí. Si te alcanza (la onda o los
## puños), cuánta vida te saca y cuánto te tira (m).
@export_range(0.3, 4.0, 0.05) var windup := 1.3
@export_range(0.2, 4.0, 0.05) var recover := 1.4
@export_range(5.0, 120.0, 1.0) var wave_speed := 60.0
@export_range(20.0, 250.0, 5.0) var wave_reach := 140.0
@export_range(2.0, 40.0, 0.5) var wave_width := 14.0
@export_range(1, 7, 1) var count := 1
@export_range(1, 7, 1) var count_rage := 3
@export_range(0.0, 60.0, 1.0) var fan := 28.0
@export_range(0.0, 100.0, 1.0) var damage := 20.0
@export_range(0.0, 40.0, 0.5) var push := 8.0

## Las ondas que corren (ya lanzadas) y las que avisan (todavía no).
var waves: Array[BrawlerWave] = []
var _aiming: Array[BrawlerWave] = []


func _init() -> void:
	reach_from = 25.0
	reach_to = 120.0


func title() -> String:
	return "golpe al piso"


func needs() -> PackedStringArray:
	return PackedStringArray(["brazos", "suelo"])


func labels() -> Dictionary:
	return {"windup": "aviso: los brazos arriba (s)", "recover": "se queda después (s)",
		"wave_speed": "la onda corre a (m/s)", "wave_reach": "llega hasta (m)", "wave_width": "ancho (m)",
		"count": "cuántas ondas", "count_rage": "cuántas, en modo fuerte", "fan": "abiertas entre sí (°)",
		"damage": "te saca (vida)", "push": "te tira (m)"}


func act(b: BrawlerBrain, _delta: float) -> void:
	var boss := b.boss
	var waist := b.waist()
	var mouth := boss.global_position + waist * (boss.box().z * 0.5 + AHEAD)
	match b.step:
		0:
			b.stage = "golpe al piso: levanta los brazos"
			boss.pose = Brawler.Pose.SLAM_READY
			b.face()
			var wanted := count_rage if b.strong() else count
			while _aiming.size() < wanted:
				var wave := BrawlerWave.new()
				wave.name = "Onda"
				b.world().add_child(wave)
				wave.setup(wave_width, wave_reach)
				_aiming.append(wave)
			# En abanico, centradas en la cintura.
			for index in _aiming.size():
				var turn := deg_to_rad(fan) * (index - (_aiming.size() - 1) * 0.5)
				_aiming[index].aim(mouth, waist.rotated(Vector3.UP, turn))
			if b.clock >= windup:
				uses += 1
				boss.pose = Brawler.Pose.SLAM
				b.next(1)
		1:
			b.stage = "¡golpe al piso!"
			boss.move = Vector2.ZERO
			# LOS PUÑOS: si estás justo adelante, te pegan ellos (derriba).
			hits += int(b.hit_with(["puños"], 2.0, damage, "los puños al piso", HitReaction.Kind.KNOCKDOWN,
				b.to_target(), push))
			if b.clock >= FALL:
				for wave in _aiming:
					wave.launch(wave_speed)
					waves.append(wave)
				_aiming.clear()
				b.next(2)
		_:
			b.stage = "golpe al piso: se recupera"
			boss.move = Vector2.ZERO
			if b.clock >= recover:
				b.finish()


## LAS ONDAS QUE CORREN: si una te pasa por debajo apoyada, te saca vida (una vez cada una); saltando más alto que el
## lomo, no.
func tick(b: BrawlerBrain, _delta: float) -> void:
	waves.assign(waves.filter(func(wave: Variant) -> bool: return is_instance_valid(wave)))
	var body := b.target as BalanceBody
	for wave: BrawlerWave in waves.duplicate():
		var over := body != null and not body.grounded
		if over and body.mover != null:
			over = body.mover.global_position.y - wave.origin.y > BrawlerWave.RIDGE.x
		if over or not wave.covers(b.ground(), b.half_width()):
			continue
		waves.erase(wave)
		hits += int(b.strike(damage, "el golpe al piso", HitReaction.Kind.KNOCKDOWN, wave.way, push,
			b.ground() + Vector3.UP * BrawlerWave.RIDGE.x))


## Las franjas que avisaban sin onda (lo cortaron) se van.
func drop(_b: BrawlerBrain) -> void:
	for wave in _aiming:
		if is_instance_valid(wave):
			wave.queue_free()
	_aiming.clear()
