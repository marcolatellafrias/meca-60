class_name HookPower
extends BossPower

## EL AGARRE Y REVOLEO, UN SKILLSHOT (ver BossPower): AVISO, los brazos atrás y una franja angosta que sigue a la
## cintura; al final se queda quieta y titila (apuntó); GOLPE, la mano sale derecho con su cadena (BrawlerHook). Si te
## toca, te arrastra, te revolea y te tira lejos (HitReaction: agarrada y revoleada); al caer te saca vida. Pide un
## brazo con mano («mano»).

## Revoleando: a cuánto adelante de su frente y a qué altura te tiene (m, en su escala).
const HOLD := Vector2(12.0, 8.0)

@export_group("Agarre")
## El aviso (s) y cuánto se queda quieta la franja antes del tiro (s); la mano: a qué velocidad sale (m/s), hasta dónde
## (m) y qué ancho tiene la franja (m). Si te agarra: cuánto te revolea (s, a tantos °/s), a cuánto te tira (m), con
## qué arco (m de alto, s de vuelo) y cuánta vida te saca al caer. Después se queda (s).
@export_range(0.2, 4.0, 0.05) var windup := 1.0
@export_range(0.0, 2.0, 0.05) var lock := 0.6
@export_range(20.0, 200.0, 5.0) var speed := 90.0
@export_range(20.0, 150.0, 5.0) var length := 85.0
@export_range(2.0, 20.0, 0.5) var width := 6.0
@export_range(0.2, 4.0, 0.05) var swing_time := 1.2
@export_range(90.0, 1080.0, 10.0) var swing_speed := 400.0
@export_range(10.0, 150.0, 5.0) var fling_distance := 70.0
@export_range(0.0, 60.0, 1.0) var fling_arc := 25.0
@export_range(0.3, 4.0, 0.05) var fling_time := 1.3
@export_range(0.0, 100.0, 1.0) var damage := 35.0
@export_range(0.2, 4.0, 0.05) var recover := 1.0

@export_group("Cuerpo")
## Lo que usa del cuerpo (se elige entre lo que el cuerpo ofrece: ver BossPower).
@export var ready_pose := int(Brawler.Pose.HOOK_READY)
@export var strike_pose := int(Brawler.Pose.HOOK)

## La mano (mientras apunta, sale o vuelve).
var hand: BrawlerHook = null


func _init() -> void:
	reach_from = 25.0
	reach_to = 80.0


func title() -> String:
	return "agarre"


func needs() -> PackedStringArray:
	return PackedStringArray(["suelo"])


func labels() -> Dictionary:
	return BODY_LABELS.merged({"windup": "aviso: la franja (s)", "lock": "ya apuntó, quieta (s)", "speed": "la mano sale a (m/s)",
		"length": "llega hasta (m)", "width": "ancho (m)", "swing_time": "te revolea (s)", "swing_speed": "a (°/s)",
		"fling_distance": "te tira a (m)", "fling_arc": "el arco sube (m)", "fling_time": "vuelo (s)",
		"damage": "al caer te saca (vida)", "recover": "se queda después (s)"})


func act(b: BrawlerBrain, _delta: float) -> void:
	var boss := b.boss
	var waist := b.waist()
	match b.step:
		0:
			boss.pose = ready_pose as Brawler.Pose
			b.face()
			if hand == null:
				hand = BrawlerHook.new()
				hand.name = "Mano"
				b.world().add_child(hand)
				hand.setup(width, length)
			if b.clock < windup:
				b.stage = "agarre: apunta"
				hand.aim(boss.global_position + waist * boss.box().z * 0.5, waist, false)
			else:
				# YA APUNTÓ: la franja (y la cintura) quietas.
				b.stage = "agarre: ¡apuntó!"
				boss.aim_yaw = atan2(-hand.way.x, -hand.way.z)
				hand.aim(hand.origin, hand.way, true)
			if b.clock >= windup + lock:
				uses += 1
				boss.pose = strike_pose as Brawler.Pose
				hand.launch(speed)
				b.next(1)
		1:
			b.stage = "agarre: ¡la mano!"
			boss.aim_yaw = atan2(-hand.way.x, -hand.way.z)
			boss.move = Vector2.ZERO
			if hand.touches(b.ground(), b.half_width()) and not HitReaction.of(b.target).untouchable():
				hits += 1
				hand.reel()
				var reaction := HitReaction.of(b.target)
				reaction.grab(hand.tip() + Vector3.UP * BrawlerHook.height())
				if reaction.state == HitReaction.State.HELD:
					b.next(2)
				else:
					# A LA FÍSICA no la lleva: la tira hacia él (y le saca lo mismo).
					var theirs := Health.of(b.target)
					if theirs != null:
						theirs.hurt(damage, "el agarre")
					reaction.react(HitReaction.Kind.KNOCKDOWN, -hand.way, 16.0, hand.tip())
					b.next(4)
			elif hand.state == BrawlerHook.State.BACK:
				b.next(4)
		2:
			b.stage = "agarre: ¡te agarró!"
			boss.aim_yaw = atan2(-hand.way.x, -hand.way.z)
			boss.move = Vector2.ZERO
			if not is_instance_valid(hand) or hand.front <= boss.box().z * 0.5:
				hand = null
				b.next(3)
			else:
				HitReaction.of(b.target).hold_at(hand.tip())
		3:
			b.stage = "¡revoleo!"
			boss.pose = Brawler.Pose.SWING
			boss.move = Vector2.ZERO
			boss.spin = swing_speed * clampf(b.clock / 0.4, 0.2, 1.0)
			var hold := boss.global_position + waist * (boss.box().z * 0.5 + HOLD.x * Brawler.scale()) \
				+ Vector3.UP * HOLD.y * Brawler.scale()
			HitReaction.of(b.target).hold_at(hold)
			if b.clock >= swing_time:
				boss.spin = 0.0
				boss.pose = Brawler.Pose.THROW
				var to := hold + waist * fling_distance
				to.y = 0.0
				if boss.arena != null:
					to = boss.arena.hold(to, b.half_width() + 2.0)
				HitReaction.of(b.target).fling(to, fling_arc, fling_time, damage, "el revoleo")
				BossSounds.play(BossSounds.Kind.WINDUP, hold, b.world(), -4.0)
				b.next(4)
		_:
			b.stage = "agarre: se recupera"
			boss.move = Vector2.ZERO
			if b.clock >= recover:
				b.finish()


## La mano: si todavía apuntaba, se va; si salió, vuelve sola.
func drop(_b: BrawlerBrain) -> void:
	if hand != null and is_instance_valid(hand) and hand.state == BrawlerHook.State.AIM:
		hand.queue_free()
	hand = null
