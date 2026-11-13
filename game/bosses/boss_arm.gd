class_name BossArm
extends Node3D

## UN BRAZO DE UNA MECA ENEMIGA (13/11/2026) — TRABAJO EN CURSO, en bloques: hombro, brazo, codo, antebrazo y, por
## separado, LA MANO y LO MONTADO EN EL ANTEBRAZO (ver BossDesign; una ametralladora en el antebrazo no le saca la mano).
## Sólo dibujo, como los brazos discretos de la meca propia: va adonde se lo pide y atraviesa.
##
## UN ATAQUE (`attack(target, with_gear)`, lo pide el cerebro, BossBrain; devuelve cuánto dura) es PREPARAR (se ve
## venir), HACER y VOLVER. Lo que empuja o tira lo hace sólo el host (el cerebro sólo corre ahí).
## CON LA MANO:
##   · PUÑO: de cerca, una piña que empuja. De lejos, golpea el piso: una onda al ras que hay que SALTAR.
##   · SIERRA y TALADRO: de cerca, se la deja puesta y te sacude mientras estés al alcance (el usuario: «solamente si te
##     acercas y te la mantiene puesta te hace daño»). De lejos, la sierra se TIRA: una pared alta que viene hacia vos y
##     se pasa AGACHADO.
## CON LO DEL ANTEBRAZO:
##   · AMETRALLADORA: una ráfaga a donde vas a estar: cambiar de rumbo.
##   · COHETES (no guiados): una andanada de mortero, donde estás, donde vas a estar y alrededor.
##   · MISILES GUIADOS: dos, que te siguen hasta poco antes de caer.
##   · BOMBAS: una sola, grande y lenta.
## Todavía no hay daño a la meca propia: no tiene vida (ver docs/conceptual/la-meca.md); lo que le hacen es empujarla.

enum Phase { REST, READY, DO, BACK }

## Lo que tarda cada parte de cada ataque (s): preparar, hacer, volver.
const HAND_TIMES := {
	BossDesign.Hand.FIST: [0.7, 0.3, 0.7],
	BossDesign.Hand.SAW: [0.5, 2.5, 0.6],
	BossDesign.Hand.DRILL: [0.5, 2.5, 0.6],
}
const GEAR_TIMES := {
	BossDesign.Gear.GUN: [0.6, 1.6, 0.5],
	BossDesign.Gear.ROCKETS: [0.8, 0.7, 0.6],
	BossDesign.Gear.GUIDED: [0.6, 0.5, 0.6],
	BossDesign.Gear.BOMBS: [1.0, 0.3, 1.0],
}
## Cada cuánto sacude la sierra o el taladro (s) y cuánto (m/s).
const GRIND_EVERY := 0.2
const GRIND_PUSH := 1.8
## La piña: cuánto le cambia la velocidad a lo que agarra (m/s).
const PUNCH_PUSH := 9.0
## La ráfaga: cuántas balas, a qué velocidad (m/s) y cuánto se abren (m).
const BULLETS := 16
const BULLET_SPEED := 90.0
const SPREAD := 3.0

var boss: BossMech = null
var side := 1.0
var hand := BossDesign.Hand.FIST
var gear := BossDesign.Gear.NONE
var shoulder_local := Vector3.ZERO
var upper := 5.0
var forearm := 5.0
var radius := 0.8

var phase := Phase.REST
var _with_gear := false
var _clock := 0.0
var _target: Node3D = null
var _far := false
var _wrist := Vector3.ZERO
var _placed := false
var _grind_clock := 0.0
var _struck := {}
var _spin := 0.0
var _upper_part: Node3D = null
var _fore_part: Node3D = null
var _elbow: Node3D = null
var _shoulder: Node3D = null
var _hand: Node3D = null
var _hand_spinner: Node3D = null
var _gear: Node3D = null
var _gear_spinner: Node3D = null
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	top_level = true
	global_transform = Transform3D()
	_random.randomize()
	var colors := boss.design.colors()
	_shoulder = Clay.sphere(self, radius * 1.6, Vector3.ZERO, colors["joint"])
	_upper_part = Clay.limb(self, radius, upper, Vector3.ZERO, colors["limb"])
	_elbow = Clay.sphere(self, radius * 1.3, Vector3.ZERO, colors["joint"])
	_fore_part = Clay.limb(self, radius * 0.9, forearm, Vector3.ZERO, (colors["limb"] as Color).darkened(0.1))
	_hand = Node3D.new()
	add_child(_hand)
	_gear = Node3D.new()
	add_child(_gear)
	_build_hand(colors)
	_build_gear(colors)


## LA MANO (en el espacio de `_hand`: su −Z sigue al antebrazo, el origen en la muñeca).
func _build_hand(colors: Dictionary) -> void:
	var r := radius
	match hand:
		BossDesign.Hand.FIST:
			Clay.box(_hand, Vector3(r * 2.8, r * 2.4, r * 2.6), Vector3(0, 0, -r * 1.2), colors["joint"])
			Clay.box(_hand, Vector3(r * 2.9, r * 0.6, r * 0.5), Vector3(0, r * 0.5, -r * 2.5), colors["accent"])
		BossDesign.Hand.SAW:
			Clay.box(_hand, Vector3(r * 1.6, r * 1.6, r * 2.0), Vector3(0, 0, -r * 0.8), colors["hull"])
			_hand_spinner = Node3D.new()
			_hand_spinner.position = Vector3(0, 0, -r * 3.6)
			_hand.add_child(_hand_spinner)
			Clay.cylinder(_hand_spinner, r * 3.2, r * 0.25, Vector3.ZERO, Clay.METAL.lightened(0.15), Vector3(0, 0, 90))
			Clay.cylinder(_hand_spinner, r * 0.8, r * 0.5, Vector3.ZERO, colors["accent"], Vector3(0, 0, 90))
			for i in 12:
				var angle := TAU * i / 12.0
				var tooth := Clay.box(_hand_spinner, Vector3(r * 0.3, r * 0.7, r * 0.5),
					Vector3(0, cos(angle), sin(angle)) * r * 3.3, Clay.METAL.lightened(0.25))
				tooth.rotation.x = -angle
		BossDesign.Hand.DRILL:
			_hand_spinner = Node3D.new()
			_hand.add_child(_hand_spinner)
			var cone := CylinderMesh.new()
			cone.top_radius = 0.0
			cone.bottom_radius = r * 1.5
			cone.height = r * 6.0
			cone.radial_segments = 8
			var part := MeshInstance3D.new()
			part.mesh = cone
			part.material_override = Clay.material(Clay.METAL.lightened(0.1))
			part.rotation.x = -PI * 0.5
			part.position = Vector3(0, 0, -r * 3.0)
			_hand_spinner.add_child(part)
			for i in 3:
				var ridge := Clay.box(_hand_spinner, Vector3(r * 0.3, r * 2.2 - i * r * 0.5, r * 0.3),
					Vector3(0, 0, -r * (1.2 + i * 1.4)), colors["accent"])
				ridge.rotation = Vector3(0.0, 0.0, i * 0.8)


## LO DEL ANTEBRAZO (en el espacio de `_gear`: su −Z sigue al antebrazo, el origen en el medio del antebrazo, arriba).
func _build_gear(colors: Dictionary) -> void:
	var r := radius
	var hull: Color = colors["hull"]
	var accent: Color = colors["accent"]
	match gear:
		BossDesign.Gear.GUN:
			Clay.box(_gear, Vector3(r * 2.0, r * 1.6, r * 3.0), Vector3.ZERO, hull)
			_gear_spinner = Node3D.new()
			_gear_spinner.position = Vector3(0, 0, -r * 1.5)
			_gear.add_child(_gear_spinner)
			for i in 6:
				var angle := TAU * i / 6.0
				Clay.cylinder(_gear_spinner, r * 0.18, forearm * 0.8, Vector3(cos(angle), sin(angle), 0) * r * 0.5
					+ Vector3(0, 0, -forearm * 0.4), Clay.DARK, Vector3(90, 0, 0))
			Clay.cylinder(_gear_spinner, r * 0.75, r * 0.4, Vector3(0, 0, -forearm * 0.75), accent, Vector3(90, 0, 0))
		BossDesign.Gear.ROCKETS:
			Clay.box(_gear, Vector3(r * 3.2, r * 2.2, r * 3.6), Vector3.ZERO, hull)
			for x in 3:
				for y in 2:
					Clay.cylinder(_gear, r * 0.4, r * 0.3, Vector3((x - 1) * r * 1.0, r * (-0.45 + y * 0.9), -r * 1.85),
						Clay.DARK, Vector3(90, 0, 0))
		BossDesign.Gear.GUIDED:
			for x: float in [-1.0, 1.0]:
				Clay.cylinder(_gear, r * 0.7, r * 4.6, Vector3(x * r * 0.8, 0.0, 0.0), colors["joint"], Vector3(90, 0, 0))
				Clay.sphere(_gear, r * 0.7, Vector3(x * r * 0.8, 0.0, -r * 2.3), accent)
		BossDesign.Gear.BOMBS:
			Clay.cylinder(_gear, r * 1.5, r * 4.0, Vector3.ZERO, hull, Vector3(90, 0, 0))
			Clay.cylinder(_gear, r * 1.7, r * 0.5, Vector3(0, 0, -r * 2.0), accent, Vector3(90, 0, 0))


func busy() -> bool:
	return phase != Phase.REST


## LO QUE ALCANZA LA MANO, del hombro a la punta (m).
func reach() -> float:
	return upper + forearm + radius * 4.0


## LOS ATAQUES QUE TIENE: con la mano, con lo del antebrazo, o los dos.
func can_hand() -> bool:
	return hand != BossDesign.Hand.NONE


func can_gear() -> bool:
	return gear != BossDesign.Gear.NONE


## EMPIEZA UN ATAQUE contra `target`, con la mano o con lo del antebrazo (ver arriba). Devuelve cuánto dura entero.
func attack(target: Node3D, with_gear: bool) -> float:
	_target = target
	_with_gear = with_gear
	phase = Phase.READY
	_clock = 0.0
	_struck.clear()
	_grind_clock = 0.0
	_far = BossBrain.gap(boss, target) > reach() * 0.75
	var times := _times()
	return float(times[0]) + float(times[1]) + float(times[2])


func _times() -> Array:
	return GEAR_TIMES[gear] if _with_gear else HAND_TIMES[hand]


func _physics_process(delta: float) -> void:
	var was := phase
	if phase != Phase.REST:
		_clock += delta
		if _clock >= float(_times()[phase - 1]):
			_clock = 0.0
			phase = ((phase + 1) % Phase.size()) as Phase
	if boss.broken or boss.state != BalanceBody.State.STANDING:
		phase = Phase.REST
	if was == Phase.READY and phase == Phase.DO:
		_begin_doing()
	if was == Phase.DO and phase == Phase.BACK:
		_end_doing()
	var shoulder := boss.global_transform * shoulder_local
	var want := _wanted(shoulder)
	var fast := phase == Phase.DO and not _with_gear and hand == BossDesign.Hand.FIST
	_wrist = want if not _placed else _wrist.move_toward(want, (70.0 if fast else 25.0) * delta)
	_placed = true
	_pose(shoulder, delta)
	if phase == Phase.DO and is_instance_valid(_target) and not _with_gear:
		_doing(delta)


## ADÓNDE VA LA MUÑECA (mundo): en reposo, adelante y abajo; preparando y haciendo, hacia lo que ataca.
func _wanted(shoulder: Vector3) -> Vector3:
	var basis := boss.global_basis
	var rest := shoulder + basis * Vector3(side * radius * 1.5, -upper * 0.75, -forearm * 0.6)
	if phase == Phase.REST or phase == Phase.BACK or not is_instance_valid(_target):
		return rest
	var toward := (BossBrain.centre_of(_target) - shoulder).normalized()
	var flat := Vector3(toward.x, 0.0, toward.z).normalized()
	var length := (upper + forearm) * 0.92
	if _with_gear:
		match gear:
			BossDesign.Gear.ROCKETS, BossDesign.Gear.GUIDED:
				return shoulder + (flat * 0.5 + Vector3.UP * 0.7).normalized() * length
			BossDesign.Gear.BOMBS:
				return shoulder + (flat * 0.4 + Vector3.UP * 1.2).normalized() * length
		return shoulder + toward * length
	match hand:
		BossDesign.Hand.FIST:
			if phase == Phase.READY:
				return shoulder + basis * Vector3(side * radius * 2.0, -radius, upper * 0.3)
			if _far:
				return shoulder + (flat * 0.6 + Vector3.DOWN).normalized() * length
		BossDesign.Hand.SAW:
			if _far:
				return shoulder + (flat + Vector3.UP * 0.2).normalized() * length
	return shoulder + toward * length


## EL BRAZO, del hombro a la muñeca (IK de dos huesos, como el de la meca propia); la mano en la punta y lo del
## antebrazo encima de él.
func _pose(shoulder: Vector3, delta: float) -> void:
	var hint := boss.global_basis * Vector3(side, -0.8, 0.5)
	var elbow := MechBody.joint(shoulder, _wrist, upper, forearm, hint)
	var wrist := shoulder + (_wrist - shoulder).limit_length(upper + forearm - 0.01)
	_shoulder.position = shoulder
	_upper_part.transform = MechBody.segment(shoulder, elbow, hint)
	_elbow.position = elbow
	_fore_part.transform = MechBody.segment(elbow, wrist, hint)
	var along := (wrist - elbow).normalized()
	var up := boss.global_basis.y
	if absf(along.dot(up)) > 0.95:
		up = -boss.global_basis.z
	var lay := Basis.looking_at(along, up)
	_hand.global_transform = Transform3D(lay, wrist)
	_gear.global_transform = Transform3D(lay, elbow.lerp(wrist, 0.5) + lay.y * radius * 1.9)
	var hand_on := phase == Phase.DO and not _with_gear
	var gear_on := (phase == Phase.DO or phase == Phase.READY) and _with_gear
	_spin += delta * 18.0
	if _hand_spinner != null:
		if hand == BossDesign.Hand.SAW:
			_hand_spinner.rotation.x = -_spin * (1.0 if hand_on else 0.1)
		else:
			_hand_spinner.rotation.z = _spin * (1.0 if hand_on else 0.1)
	if _gear_spinner != null:
		_gear_spinner.rotation.z = _spin * (1.0 if gear_on else 0.05)


## DONDE SALE lo que tira lo del antebrazo, en el mundo.
func muzzle() -> Vector3:
	return _gear.global_transform * Vector3(0.0, 0.0, -forearm * 0.6)


## LA PUNTA de la mano, en el mundo.
func tip() -> Vector3:
	var ahead := radius * (6.0 if hand == BossDesign.Hand.DRILL else 3.6)
	return _hand.global_transform * Vector3(0.0, 0.0, -ahead)


## ── LO QUE HACE (sólo el host: el cerebro sólo corre ahí) ──────────────────────────────────────────────────────

func _begin_doing() -> void:
	var field := boss.field
	if not is_instance_valid(_target) or field == null:
		return
	var here := BossBrain.ground_of(_target, boss)
	var going := BossBrain.velocity_of(_target)
	going.y = 0.0
	if not _with_gear:
		if hand == BossDesign.Hand.SAW and _far:
			var base := Vector3(boss.global_position.x, here.y, boss.global_position.z)
			var way := (here - base).normalized()
			boss.strike({"shape": AreaStrike.Shape.WAVE_BAND, "element": AreaStrike.Element.BLAST,
				"at": base + way * (boss.size.z * 0.5 + 4.0), "way": way, "length": 34.0, "delay": 0.9,
				"speed": 32.0, "reach": base.distance_to(here) + 30.0, "push": 9.0,
				"low": BossBrain.standing_top(_target) - AreaStrike.WAVE_HEIGHT - 0.4})
		return
	match gear:
		BossDesign.Gear.ROCKETS:
			var spots: Array[Vector3] = [here, here + going * 2.6]
			for i in 3:
				var angle := _random.randf() * TAU
				spots.append(here + Vector3(cos(angle), 0.0, sin(angle)) * _random.randf_range(8.0, 22.0))
			for i in spots.size():
				boss.launch(Missile.Kind.MORTAR, muzzle(), spots[i], 2.4, i * 0.12)
		BossDesign.Gear.GUIDED:
			for i in 2:
				boss.launch(Missile.Kind.GUIDED, muzzle(), here + Vector3(i * 6.0 - 3.0, 0.0, 0.0), 3.4, i * 0.35, _target)
		BossDesign.Gear.BOMBS:
			boss.launch(Missile.Kind.BOMB, muzzle(), here + going * 1.5, 4.0)
		BossDesign.Gear.GUN:
			var from := muzzle()
			var step := float(GEAR_TIMES[gear][1]) / BULLETS
			for i in BULLETS:
				var when := i * step
				var flight := from.distance_to(here) / BULLET_SPEED
				var spot := here + going * (when + flight) + Vector3(_random.randf_range(-SPREAD, SPREAD), 0.0,
					_random.randf_range(-SPREAD, SPREAD))
				boss.launch(Missile.Kind.BULLET, from, spot, flight, when)


func _end_doing() -> void:
	if _with_gear or hand != BossDesign.Hand.FIST or not _far or boss.field == null:
		return
	# EL PUÑO GOLPEA EL PISO: una onda al ras, para saltar.
	var hit := tip()
	boss.strike({"shape": AreaStrike.Shape.WAVE_RING, "element": AreaStrike.Element.BLAST,
		"at": Vector3(hit.x, boss.support.y, hit.z), "delay": 0.15, "speed": 30.0, "reach": 80.0, "push": 9.0})


## MIENTRAS HACE CON LA MANO: la piña empuja; la sierra y el taladro sacuden lo que está al alcance.
func _doing(delta: float) -> void:
	match hand:
		BossDesign.Hand.FIST:
			if not _far:
				_hit_near(tip(), radius * 3.0, PUNCH_PUSH, true)
		BossDesign.Hand.SAW, BossDesign.Hand.DRILL:
			if hand == BossDesign.Hand.SAW and _far:
				return
			_grind_clock += delta
			if _grind_clock >= GRIND_EVERY:
				_grind_clock = 0.0
				_hit_near(tip(), radius * (3.6 if hand == BossDesign.Hand.SAW else 2.6) + 1.5, GRIND_PUSH, false)


## EMPUJA lo suelto cerca de `point` (no a sí misma): una vez por ataque (`once`) o cada vez.
func _hit_near(point: Vector3, size: float, push: float, once: bool) -> void:
	var ball := SphereShape3D.new()
	ball.radius = size
	var touched := false
	for body in AreaStrike.loose_in(get_world_3d().direct_space_state, ball, Transform3D(Basis(), point)):
		if AreaStrike.spares(body, boss.team) or (once and _struck.has(body.get_instance_id())):
			continue
		_struck[body.get_instance_id()] = true
		var away := body.global_position - boss.global_position
		away.y = 0.0
		var way := away.normalized() if away.length_squared() > 0.01 else -boss.global_basis.z
		if not once:
			way = (way + boss.global_basis.x * _random.randf_range(-0.8, 0.8)).normalized()
		body.apply_central_impulse((way + Vector3.UP * 0.1).normalized() * push * body.mass)
		touched = true
	if touched:
		var sparks := ParticleSystems.explosion_sparks(ParticleMeshes.Kind.LINE, 1.5)
		sparks.top_level = true
		add_child(sparks)
		sparks.global_transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), point)
		sparks.restart()
		get_tree().create_timer(1.5).timeout.connect(sparks.queue_free)
