class_name FlamePower
extends BossPower

## EL LANZALLAMAS DEL HORNO, EN BOCANADAS (ver BossPower; de entrada, sólo con ira): abre el horno y larga bocanadas;
## cada una TE SIGUE con la cintura (el cono en el piso), SE QUEDA QUIETA y titila (apuntó) y QUEMA en esa dirección
## (BrawlerFlame: LA ZONA DE GOLPE es un cono que sale de él, de tamaño propio). Se esquiva con un dash de costado
## cuando apuntó. El horno queda abierto: la ventana. Pide el horno.

@export_group("Lanzallamas")
## Abre el horno (s); cada bocanada te sigue (s), se queda quieta (s) y quema (s); cuántas; hasta dónde llega (m) y su
## medio ancho (°). Si te toca, cuánta vida te saca y cuánto te empuja (m). Después, el horno abierto (s).
@export_range(0.2, 4.0, 0.05) var windup := 0.8
@export_range(0.2, 3.0, 0.05) var aim := 0.9
@export_range(0.0, 2.0, 0.05) var lock := 0.45
@export_range(0.1, 3.0, 0.05) var burn := 0.8
@export_range(1, 6, 1) var bursts := 3
@export_range(10.0, 120.0, 1.0) var length := 60.0
@export_range(2.0, 45.0, 0.5) var angle := 14.0
@export_range(0.0, 100.0, 1.0) var damage := 25.0
@export_range(0.0, 40.0, 0.5) var push := 12.0
@export_range(0.2, 6.0, 0.1) var recover := 1.8

@export_group("Cuerpo")
## Lo que usa del cuerpo (se elige entre lo que el cuerpo ofrece: ver BossPower).
@export var from_point := 0
@export var ready_pose := int(Brawler.Pose.FLAME_READY)
@export var strike_pose := int(Brawler.Pose.FLAME)
@export var exposes := true

## El chorro (mientras dura el ataque).
var flame: BrawlerFlame = null
var _yaw := 0.0
var _left := 0


func _init() -> void:
	reach_from = 20.0
	reach_to = 60.0
	in_calm = false
	in_mode_2 = true


func title() -> String:
	return "lanzallamas"


func needs() -> PackedStringArray:
	return PackedStringArray()


func labels() -> Dictionary:
	return BODY_LABELS.merged({"windup": "abre el horno (s)", "aim": "cada bocanada te sigue (s)", "lock": "apuntó, quieta (s)",
		"burn": "quema (s)", "bursts": "bocanadas", "length": "llega hasta (m)", "angle": "medio ancho (°)",
		"damage": "te saca (vida)", "push": "te empuja (m)", "recover": "después, horno abierto (s)"})


func act(b: BrawlerBrain, _delta: float) -> void:
	var boss := b.boss
	var waist := b.waist()
	if flame == null:
		flame = BrawlerFlame.new()
		flame.name = "Lanzallamas"
		b.world().add_child(flame)
		flame.setup(length, angle, 0.0)
		_left = bursts
	b.expose(exposes)
	boss.move = Vector2.ZERO
	match b.step:
		0:
			b.stage = "lanzallamas: abre el horno"
			boss.pose = ready_pose as Brawler.Pose
			b.face()
			if b.clock >= windup:
				uses += 1
				b.next(1)
		1:
			b.stage = "lanzallamas: apunta"
			boss.pose = ready_pose as Brawler.Pose
			b.face()
			flame.warn(boss.global_position, waist)
			if b.clock >= aim:
				_yaw = boss.waist_yaw
				b.next(2)
		2:
			b.stage = "lanzallamas: ¡apuntó!"
			boss.aim_yaw = _yaw
			flame.warn(boss.global_position, waist, true)
			if b.clock >= lock:
				BossSounds.play(BossSounds.Kind.FLAME, boss.point(from_point), b.world(), -2.0)
				b.hit_once = false
				b.next(3)
		3:
			b.stage = "¡lanzallamas!"
			boss.pose = strike_pose as Brawler.Pose
			boss.aim_yaw = _yaw
			flame.blow(boss.point(from_point), waist, true)
			if not b.hit_once and flame.covers(b.ground(), b.half_width()):
				var landed := b.strike(damage, "el lanzallamas", HitReaction.Kind.PUSH, b.to_target(), push,
					b.ground() + Vector3.UP * 8.0)
				b.hit_once = b.hit_once or landed
				hits += int(landed)
			if b.clock >= burn:
				flame.blow(boss.point(from_point), waist, false)
				_left -= 1
				b.next(1 if _left > 0 else 4)
		_:
			b.stage = "lanzallamas: horno abierto"
			boss.pose = Brawler.Pose.STUNNED
			if b.clock >= recover:
				b.finish()


func drop(_b: BrawlerBrain) -> void:
	if flame != null and is_instance_valid(flame):
		flame.queue_free()
	flame = null
