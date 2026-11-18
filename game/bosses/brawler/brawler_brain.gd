class_name BrawlerBrain
extends Node

## LA CABEZA DEL LUCHADOR (15/11/2026; poderes, 17/11/2026): lo maneja la computadora, como un jefe de Souls (ver
## docs/technical/pelea-jefes.md). LOS ATAQUES SON PODERES (BossPower, en game/bosses/powers/: cada uno con su aviso,
## su golpe y su recuperación, y sus variantes como perillas; se tildan en el panel). Esta cabeza es lo común:
##   · RODEA: la cintura te mira siempre; las orugas se acercan si estás lejos, se alejan si estás encima y, en el medio,
##     andan de costado a vos. Al rato, ELIGE uno de los poderes tildados que tengan tu distancia a tiro (los «sólo con
##     ira», si tiene ira), al azar (la L de la parcela deja uno solo).
##   · LOS MODOS (BossMode, de BrawlerSettings: la ira, el vuelo…): entra en uno cada tanto tiempo tranquilo o cuando su
##     vida baja, y sale cuando se le termina; siempre mientras rodea. El modo dice cuánto más rápido anda, si ENCADENA
##     (al terminar un ataque, a veces sigue con otro sin rodearte), si los poderes usan sus variantes fuertes, si VUELA
##     (y entonces va para cualquier lado), a qué distancia rodea y si se ve con ira. Cada poder dice en qué modos se usa.
##   · LO COMÚN A LOS PODERES: el blanco (dónde está, su ancho y su alto), los golpes (`strike`, por HitReaction), si
##     un punto lo toca (`touches_target`), manejar las orugas (`face`, `error_to`) y los tiempos (`step`, `clock`,
##     `next`, `finish`).
##   · NO SE EMPUJAN: el Luchador no avanza dentro del blanco (lo frena).
## LA VIDA, POR CÓDIGO (Health): las piñas de la meca que tocan el cuerpo le sacan poco; en el horno abierto, mucho; los
## tiros y el taladro llegan por BossHurtbox (`take_hit`). Mientras alguien lo posee, la cabeza no hace nada.

## Los poderes del Luchador, en este orden (Act: 0, rodea).
enum Act { STALK, CHARGE, SLAM, THROW, SPIN, HOOK, FLAME }
## QUÉ PODERES USA (la L de la parcela): -1, todos los tildados; si no, uno solo (su índice), aunque no tenga ira.
static var moves := -1

## Las distancias a las que se queda rodeando (m, de su medio al blanco).
const KEEP := Vector2(45.0, 80.0)
## Rodeando: cuánto (s, entre los dos).
const STALK_TIME := Vector2(2.0, 4.0)
## Cuántos ataques encadena como mucho seguidos (además del primero).
const CHAIN_MAX := 2
## Las piñas: a cuánto del horno cuentan en él (m), y a cuánto de su caja en el cuerpo.
const FURNACE_REACH := 5.0
const BODY_REACH := 3.0
## El blanco, si no dice el suyo: su radio y su alto (m).
const TARGET_RADIUS := 4.0
const TARGET_HEIGHT := 18.0

## A quién pelea (lo pone quien arma la parcela).
var target: Node3D = null
## Si piensa (la tecla de la parcela lo apaga).
var awake := true
## Qué está haciendo (el poder de ahora: `act`, y él), y en qué tiempo (para mirar).
var act := Act.STALK
var current: BossPower = null
var stage := ""
## Sus poderes (copias de los de BrawlerSettings: ver BossPower), en el orden de Act (sin STALK).
var powers: Array[BossPower] = []
## Sus modos (los de BrawlerSettings) y en cuál está (-1, tranquilo).
var modes: Array[BossMode] = []
var mode := -1
## Las piñas que recibió en el cuerpo y en el horno (para mirar).
var body_hits := 0
var furnace_hits := 0

## ── LO QUE USAN LOS PODERES ──
## El cuerpo, el paso del ataque de ahora y su reloj (s), si ya pegó en este ataque, y el azar.
var boss: Brawler = null
var step := 0
var clock := 0.0
var hit_once := false
var random := RandomNumberGenerator.new()

var _side := 1.0
var _stalk_time := 3.0
var _punched := {}
var _label: Label3D = null
var _mode_clock := 0.0
var _calm_clocks: Array[float] = []
var _phases_spent := {}
var _chain := 0
var _shown_at := 0
var _shapes_were := []


## Los nombres para la L: todos, y cada poder solo.
static func move_names() -> Array:
	var names := ["todos"]
	for power in BrawlerSettings.current.powers():
		names.append("sólo " + power.title())
	return names


func _ready() -> void:
	boss = get_parent() as Brawler
	random.randomize()
	refresh_powers(true)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 320
	_label.outline_size = 80
	_label.pixel_size = 0.02
	_label.no_depth_test = true
	boss.add_child(_label)
	_begin(Act.STALK)


## SUS PODERES, de las perillas guardadas: la primera vez, copias; después (el panel guardó), las perillas nuevas pasan
## a las copias (lo que llevan peleando, no).
func refresh_powers(fresh := false) -> void:
	modes = BrawlerSettings.current.modes()
	var defs := BrawlerSettings.current.powers()
	if fresh or powers.size() != defs.size():
		powers.clear()
		for def in defs:
			powers.append(def.duplicate() as BossPower)
		return
	for index in defs.size():
		powers[index].copy_knobs(defs[index])


## El poder de `which` (Act).
func power(which: Act) -> BossPower:
	return powers[int(which) - 1] if which != Act.STALK else null


func _physics_process(delta: float) -> void:
	_show()
	if boss.hurtbox != null and boss.hurtbox.owner_of_hits == null:
		boss.hurtbox.owner_of_hits = self
	if target == null or not is_instance_valid(target):
		return
	# Las piñas de la meca y lo que lanzó (las ondas, las piedras) cuentan aunque no piense o lo posea alguien.
	_check_punches()
	for each in powers:
		each.tick(self, delta)
	_block()
	if boss.driven():
		return
	if not awake:
		if stage != "quieto":
			_still()
		return
	var own := Health.of(boss)
	if own != null and own.dead():
		_end("derrotado")
		return
	var theirs := Health.of(target)
	if theirs != null and theirs.dead():
		_end("ganó")
		return
	if stage in ["quieto", "derrotado", "ganó"]:
		_begin(Act.STALK)
	_mode_cycle(delta)
	clock += delta
	boss.aim_yaw = yaw_to_target()
	if current == null:
		_stalk()
	else:
		current.act(self, delta)


## RODEA: se acerca, se aleja o va en diagonal, mirándote; al rato, si estás a tiro, ataca.
func _stalk() -> void:
	stage = "rodea"
	var gap := distance()
	var toward := to_target().normalized()
	var way := toward
	var keep := KEEP
	var now := mode_now()
	if now != null and now.keep_to > 0.0:
		keep = Vector2(now.keep_from, now.keep_to)
	if gap < keep.x:
		way = -toward
	elif gap < keep.y:
		way = toward.rotated(Vector3.UP, _side * deg_to_rad(70.0))
	drive(way, 0.8)
	if clock < _stalk_time:
		return
	var can := _can()
	if not can.is_empty():
		_begin(can[random.randi() % can.size()])


## Los poderes que puede usar ahora: tildados (o el de la L), con tu distancia a tiro, y los de ira si tiene ira.
func _can() -> Array[Act]:
	var gap := distance()
	var can: Array[Act] = []
	for index in powers.size():
		var each := powers[index]
		var chosen := moves == index if moves >= 0 else each.used_in(mode)
		if chosen and each.ready_at(gap) and boss.lacks_now(each.needs()).is_empty():
			can.append((index + 1) as Act)
	return can


## ── LO QUE USAN LOS PODERES ──────────────────────────────────────────────────────────────────────────────────────

## Al paso `which` del ataque de ahora (el reloj vuelve a 0).
func next(which: int) -> void:
	step = which
	clock = 0.0


## Terminó el ataque de ahora: vuelve a rodear (o, con ira, encadena).
func finish() -> void:
	_begin(Act.STALK)


## Las orugas de frente a vos, sin andar.
func face() -> void:
	boss.move = Vector2(clampf(-error_to(to_target()) * 3.0, -1.0, 1.0), 0.0)


## Hacia dónde mira la cintura (de costado, largo 1).
func waist() -> Vector3:
	return Basis(Vector3.UP, boss.waist_yaw) * Vector3.FORWARD


## Dónde se cuelga lo que lanza (las ondas, las piedras): donde está él.
func world() -> Node:
	return boss.get_parent()


## UN GOLPE AL BLANCO: el daño y la reacción, empujado `distance` m hacia `away`; `at`, dónde pegó. Devuelve si entró
## (tirado o agarrado no se le puede pegar).
func strike(damage: float, what: String, kind: HitReaction.Kind, away: Vector3, push_distance: float, at: Vector3) -> bool:
	return HitReaction.land(target, damage, what, kind, away, push_distance, at)


## Si el punto `point` (mundo), con su radio, toca al blanco: un cilindro parado del piso de sus pies hasta arriba.
func touches_target(point: Vector3, point_radius: float) -> bool:
	var at := ground()
	var flat := Vector2(point.x - at.x, point.z - at.z).length()
	return flat < half_width() + point_radius and point.y > at.y - point_radius \
		and point.y < at.y + _target_height() + point_radius


## PRENDE LAS ZONAS DE GOLPE de las piezas `parts` del cuerpo (Brawler.hit_shapes) en este paso: si alguna toca al
## blanco (barriendo desde donde estaba el paso anterior; `grow`: el radio, tantas veces), le pega: `damage` por
## `what`, la reacción `kind`, empujado `push_distance` m hacia `away`. UNA VEZ por ataque (`hit_once`; si no entró,
## puede entrar después). El poder la llama en cada paso mientras dura su golpe. Devuelve si pegó ahora.
func hit_with(parts: Array, grow: float, damage: float, what: String, kind: HitReaction.Kind, away: Vector3,
		push_distance: float) -> bool:
	var now := []
	for part: String in parts:
		now.append_array(boss.hit_shapes(part))
	var were: Array = _shapes_were if _shapes_were.size() == now.size() else now
	_shapes_were = now
	if hit_once:
		return false
	for sub in 4:
		var t := (sub + 1) / 4.0
		for index in now.size():
			var from: Vector3 = (were[index][0] as Vector3).lerp(now[index][0], t)
			var to: Vector3 = (were[index][1] as Vector3).lerp(now[index][1], t)
			for along in 7:
				var point := from.lerp(to, along / 6.0)
				if touches_target(point, float(now[index][2]) * grow):
					hit_once = strike(damage, what, kind, away, push_distance, point)
					return hit_once
	return false


func _target_height() -> float:
	var body := target as BalanceBody
	if body != null:
		return body.hover + body.size.y
	return TARGET_HEIGHT


## NO SE EMPUJAN: el Luchador no avanza dentro del blanco (lo frena, como en Souls); si está tirado o agarrado, pasa.
func _block() -> void:
	var free := not HitReaction.of(target).down()
	boss.block_at = ground()
	boss.block_radius = half_width() if free else 0.0


## EL MODO DE AHORA (null, tranquilo).
func mode_now() -> BossMode:
	return modes[mode] if mode >= 0 and mode < modes.size() else null


## Si los poderes usan sus variantes fuertes (lo dice el modo).
func strong() -> bool:
	var now := mode_now()
	return now != null and now.strong


## ENTRA EN EL MODO `which` (-1, vuelve a tranquilo): lo que cambia en el cuerpo, y su sonido.
func enter_mode(which: int) -> void:
	if which == mode:
		return
	mode = which
	_mode_clock = 0.0
	var now := mode_now()
	var angry := now != null and now.fury_look
	if angry != boss.rage:
		var at := boss.global_position + Vector3.UP * Brawler.box().y
		BossSounds.play(BossSounds.Kind.RAGE_ON if angry else BossSounds.Kind.RAGE_OFF, at, world())
	boss.rage = angry
	boss.hurry = now.hurry if now != null else 1.0
	boss.fly_height = now.fly_height if now != null else 0.0
	boss.go = Vector3.ZERO


## LOS MODOS, MIENTRAS RODEA: tranquilo, entra en el primero al que le llegó la hora (cada tanto tiempo tranquilo) o
## la vida (una vez); en un modo, sale cuando se le termina.
func _mode_cycle(delta: float) -> void:
	if _calm_clocks.size() != modes.size():
		_calm_clocks.resize(modes.size())
		_calm_clocks.fill(0.0)
	var now := mode_now()
	if now != null:
		_mode_clock += delta
		if current == null and (not now.on or (now.lasts > 0.0 and _mode_clock >= now.lasts)):
			enter_mode(-1)
		return
	var own := Health.of(boss)
	for index in modes.size():
		var each := modes[index]
		if not each.on:
			continue
		_calm_clocks[index] += delta
		var by_time := each.every > 0.0 and _calm_clocks[index] >= each.every
		var by_health := each.below_health > 0.0 and own != null and own.share() < each.below_health \
			and not _phases_spent.has(index)
		if current == null and (by_time or by_health):
			_calm_clocks[index] = 0.0
			if by_health:
				_phases_spent[index] = true
			enter_mode(index)
			return


## HACIA `way` (de costado), a `push` de su velocidad: con las orugas, giran hacia ahí y, si ya miran más o menos para
## ahí, andan; volando (o de patas), va derecho para ahí (`go`) y las orugas sólo giran.
func drive(way: Vector3, push: float) -> void:
	var error := error_to(way)
	boss.go = way * push
	boss.move = Vector2(clampf(-error * 2.0, -1.0, 1.0), push if absf(error) < 0.6 else 0.15)


## Cuánto les falta a las orugas para mirar hacia `way` (radianes; positivo, a la izquierda).
func error_to(way: Vector3) -> float:
	return wrapf(atan2(-way.x, -way.z) - boss.hull_yaw, -PI, PI)


func _begin(which: Act) -> void:
	# ENCADENA (si el modo lo dice): en vez de volver a rodear, a veces sigue con otro ataque.
	var now := mode_now()
	if which == Act.STALK and act != Act.STALK and now != null and _chain < CHAIN_MAX \
			and random.randf() < now.chain:
		var can := _can()
		if not can.is_empty():
			_chain += 1
			which = can[random.randi() % can.size()]
	elif which == Act.STALK:
		_chain = 0
	if current != null:
		current.drop(self)
	act = which
	current = power(which)
	clock = 0.0
	step = 0
	hit_once = false
	_shapes_were = []
	boss.rush(0.0)
	boss.spin = 0.0
	boss.pose = Brawler.Pose.REST
	if current != null:
		current.start(self)
		BossSounds.play(BossSounds.Kind.WINDUP, boss.global_position + Vector3.UP * Brawler.box().y, world(), -6.0)
	else:
		boss.furnace = false
		_side = -1.0 if random.randf() < 0.5 else 1.0
		_stalk_time = random.randf_range(STALK_TIME.x, STALK_TIME.y)


## ── EL BLANCO ────────────────────────────────────────────────────────────────────────────────────────────────────

func to_target() -> Vector3:
	var gap := ground() - boss.global_position
	gap.y = 0.0
	return gap


func distance() -> float:
	return to_target().length()


func yaw_to_target() -> float:
	var way := to_target()
	return atan2(-way.x, -way.z)


## EL PUNTO DEL PISO debajo del blanco: de una meca cinemática, el de lo que la mueve; de una física, debajo de su caja.
func ground() -> Vector3:
	var body := target as BalanceBody
	if body != null and body.mover != null:
		return body.mover.global_position
	if body != null:
		var from := body.global_position
		var ray := PhysicsRayQueryParameters3D.create(from, from + Vector3.DOWN * 60.0, PhysicsLayers.FIXED)
		var hit := body.get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.is_empty():
			return hit["position"]
	return target.global_position


## El medio ancho del blanco (m): de costado, lo que tiene que correrse para que el Luchador le pase al lado.
func half_width() -> float:
	var body := target as BalanceBody
	if body != null:
		return maxf(body.size.x, body.size.z) * 0.5
	return TARGET_RADIUS


func radius() -> float:
	var body := target as BalanceBody
	if body != null:
		return Vector2(body.size.x, body.size.z).length() * 0.5
	return TARGET_RADIUS


## ── LO QUE LE PEGA A ÉL ──────────────────────────────────────────────────────────────────────────────────────────

## LAS PIÑAS DE LA MECA: el puño (su MechHand), con el brazo estirado, cerca del horno abierto le saca mucho; en el
## cuerpo, poco. Una vez por piña.
func _check_punches() -> void:
	var mech := target as Mech
	var own := Health.of(boss)
	if mech == null or own == null:
		return
	var k := BrawlerSettings.current
	var mouth := boss.furnace_point()
	var center := boss.global_position + Vector3.UP * Brawler.box().y * 0.5
	for arm in mech.arms:
		# El taladro (o la sierra) pega por take_hit (no contarlo dos veces).
		if arm.tip is SpinTip:
			continue
		var key := arm.get_instance_id()
		var now := arm.stage()
		if now == MechArm.Stage.IDLE or now == MechArm.Stage.WINDUP:
			_punched.erase(key)
			continue
		# Se decide con el brazo estirado (al empezar el golpe, el puño todavía está lejos del horno).
		if _punched.has(key) or now != MechArm.Stage.HOLD:
			continue
		for hand: Node3D in arm.find_children("*", "MechHand", true, false):
			var at := hand.global_position
			if boss.opened > 0.5 and at.distance_to(mouth) < FURNACE_REACH:
				_punched[key] = true
				furnace_hits += 1
				own.hurt(k.furnace_damage, "una piña en el horno")
				HitReaction.of(boss).show_hit(at, true)
				break
			var local := boss.global_transform.affine_inverse() * at
			var half := Brawler.box() * 0.5 + Vector3.ONE * BODY_REACH
			if absf(local.x) < half.x and absf(local.z) < half.z and local.y > -1.0 and local.y < Brawler.box().y + 1.0:
				_punched[key] = true
				body_hits += 1
				own.hurt(k.punch_damage, "una piña")
				HitReaction.of(boss).show_hit(at, false)
				break


## LOS GOLPES DE LA MECA DE TRES (sus tiros, el rayo, el taladro; llegan por BossHurtbox): le sacan según cuánto
## empujan; en el horno abierto, mucho más. Se ven (blanco, chispas, sonido), el rayo de a ratos.
func take_hit(strength: float, at: Vector3, source: String) -> void:
	var own := Health.of(boss)
	if own == null:
		return
	var k := BrawlerSettings.current
	var furnace := boss.opened > 0.5 and at.distance_to(boss.furnace_point()) < FURNACE_REACH
	var damage := minf(strength / 100000.0 * k.energy_damage, k.energy_cap)
	if furnace:
		damage *= k.furnace_damage / maxf(k.punch_damage, 0.01)
	own.hurt(damage, "%s en el horno" % source if furnace else source)
	var now := Time.get_ticks_msec()
	if source != "rayo" or now - _shown_at > 250:
		_shown_at = now
		HitReaction.of(boss).show_hit(at, furnace or strength > 300000.0)
	if source != "rayo":
		if furnace:
			furnace_hits += 1
		else:
			body_hits += 1


## ── LO DEMÁS ─────────────────────────────────────────────────────────────────────────────────────────────────────

func _end(why: String) -> void:
	if stage == why:
		return
	_still()
	stage = why


## Lo que quedó a medio armar (lo cortaron) se va.
func _drop_warning() -> void:
	if current != null:
		current.drop(self)


func _still() -> void:
	_drop_warning()
	boss.pose = Brawler.Pose.REST
	boss.move = Vector2.ZERO
	boss.rush(0.0)
	boss.furnace = false
	boss.spin = 0.0
	stage = "quieto"


## EL LETRERO: qué hace y, de cada poder, cuántas veces lo usó y cuántas te pegó.
func _show() -> void:
	var head := stage if awake or stage == "derrotado" else "quieto (J lo despierta)"
	if mode_now() != null:
		head += " · " + mode_now().title.to_upper()
	var lines := PackedStringArray([head])
	for each in powers:
		if each.used() or each.uses > 0:
			lines.append("%s %d · te pegó %d" % [each.title(), each.uses, each.hits])
	_label.text = "\n".join(lines)
	_label.position = Vector3.UP * (Brawler.box().y + 12.0)
	_label.modulate = Color(1.0, 0.55, 0.3) if stage.ends_with("abre el horno") or stage.begins_with("¡se") \
		or stage.ends_with("brazos") or stage.ends_with("la levanta") or stage.ends_with("apuntó!") else Color(1, 1, 1)
