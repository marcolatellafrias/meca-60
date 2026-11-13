class_name BossChest
extends Node3D

## LO DEL PECHO DE UNA MECA ENEMIGA (13/11/2026) — TRABAJO EN CURSO. Como no tiene cabinas adentro, el torso puede
## llevar algo en el medio (el usuario: «un cañón que sube y baja, pero te tiene que apuntar para dispararse… un ojo que
## tira rayos láser»).
##   · EL CAÑÓN: sube de adentro del torso, GIRA HACIA VOS DESPACIO (un láser fino muestra adónde apunta) y recién tira
##     cuando te tiene en la mira: un obús rápido. Moverse de costado lo deja atrás.
##   · EL OJO: se carga (brilla) y barre el piso con un láser al ras, de un costado al otro: hay que SALTARLO. Mientras
##     barre, la meca no se mueve.

enum Phase { REST, RISE, AIM, HOLD, LOWER }

## El cañón: cuánto tarda en subir y bajar (s), cuánto gira (grados por segundo), cuánto puede apuntar antes de
## rendirse (s) y cuán cerca tiene que estar la mira para tirar (grados).
const RISE_TIME := 0.9
const TURN := 40.0
const GIVE_UP := 4.0
const AIMED := 2.5
const SHELL_SPEED := 70.0
## El ojo: cuánto se carga (s), cuánto barre (radianes para cada lado de donde estás) y a qué velocidad.
const CHARGE := 1.3
const SWEEP_SIDE := 0.9
const SWEEP_SPEED := 0.85
const SWEEP_REACH := 85.0

var boss: BossMech = null
var kind := BossDesign.Chest.NONE

var phase := Phase.REST
var _clock := 0.0
var _target: Node3D = null
var _raise := 0.0
var _yaw := 0.0
var _pitch := 0.0
var _turret: Node3D = null
var _barrel: Node3D = null
var _sight: MeshInstance3D = null
var _eye: MeshInstance3D = null
var _eye_material: StandardMaterial3D = null
var _sweep_end := 0.0


func _ready() -> void:
	var colors := boss.design.colors()
	var size := boss.size
	match kind:
		BossDesign.Chest.CANNON:
			# La tapa arriba, y el cañón adentro.
			Clay.box(self, Vector3(size.x * 0.45, 0.3, size.z * 0.45), Vector3(0, size.y * 0.5 + 0.1, -size.z * 0.1), colors["joint"])
			_turret = Node3D.new()
			_turret.position = Vector3(0, size.y * 0.5 - 1.5, -size.z * 0.1)
			add_child(_turret)
			Clay.cylinder(_turret, size.x * 0.18, 2.2, Vector3.ZERO, colors["hull"])
			_barrel = Node3D.new()
			_barrel.position = Vector3(0, 0.6, 0)
			_turret.add_child(_barrel)
			var length := size.z * 0.75
			Clay.cylinder(_barrel, size.x * 0.06, length, Vector3(0, 0, -length * 0.5), colors["limb"], Vector3(90, 0, 0))
			Clay.cylinder(_barrel, size.x * 0.08, 1.0, Vector3(0, 0, -length), colors["accent"], Vector3(90, 0, 0))
			var line := BoxMesh.new()
			line.size = Vector3(0.12, 0.12, 120.0)
			_sight = Missile.flat_part(line, Color(colors["accent"], 0.75), 0.0)
			_sight.position = Vector3(0, 0, -length - 60.0)
			_sight.visible = false
			_barrel.add_child(_sight)
		BossDesign.Chest.LASER_EYE:
			var radius := size.y * 0.16
			var front := -size.z * 0.5 if boss.design.torso == BossDesign.Torso.BOX else -size.x * 0.5
			Clay.cylinder(self, radius * 1.3, 0.6, Vector3(0, size.y * 0.12, front - 0.1), colors["joint"], Vector3(90, 0, 0))
			_eye = Clay.sphere(self, radius, Vector3(0, size.y * 0.12, front - 0.3), colors["accent"])
			_eye_material = StandardMaterial3D.new()
			_eye_material.albedo_color = colors["accent"]
			_eye_material.emission_enabled = true
			_eye_material.emission = colors["accent"]
			_eye_material.emission_energy_multiplier = 0.2
			_eye.material_override = _eye_material
			Clay.sphere(self, radius * 0.4, Vector3(0, size.y * 0.12, front - 0.3 - radius * 0.75), Clay.DARK)


func busy() -> bool:
	return phase != Phase.REST


## Si mientras dura la meca tiene que quedarse quieta (el barrido sale de donde está).
func roots() -> bool:
	return kind == BossDesign.Chest.LASER_EYE and busy()


## EMPIEZA contra `target` (ver arriba). Devuelve cuánto dura, más o menos.
func attack(target: Node3D) -> float:
	_target = target
	_clock = 0.0
	match kind:
		BossDesign.Chest.CANNON:
			phase = Phase.RISE
			return RISE_TIME * 2.0 + GIVE_UP * 0.5 + 1.0
		BossDesign.Chest.LASER_EYE:
			phase = Phase.AIM
			var field := boss.field
			var base := Vector3(boss.global_position.x, boss.support.y, boss.global_position.z)
			var here := BossBrain.ground_of(target, boss)
			var toward := atan2(-(here.x - base.x), -(here.z - base.z))
			var turn := SWEEP_SIDE if randf() < 0.5 else -SWEEP_SIDE
			var time := CHARGE + SWEEP_SIDE * 2.0 / SWEEP_SPEED
			_sweep_end = time
			if field != null:
				boss.strike({"shape": AreaStrike.Shape.SWEEP, "element": AreaStrike.Element.ELECTRIC, "at": base,
					"yaw_from": toward - turn, "yaw_to": toward + turn, "speed": SWEEP_SPEED, "reach": SWEEP_REACH,
					"delay": CHARGE, "push": 9.0})
			return time + 0.3
	return 0.0


func _physics_process(delta: float) -> void:
	if kind == BossDesign.Chest.NONE:
		return
	if boss.broken or boss.state != BalanceBody.State.STANDING:
		phase = Phase.REST
	_clock += delta
	if kind == BossDesign.Chest.CANNON:
		_cannon(delta)
	else:
		_laser()


func _cannon(delta: float) -> void:
	match phase:
		Phase.RISE:
			_raise = move_toward(_raise, 1.0, delta / RISE_TIME)
			if _raise >= 1.0:
				phase = Phase.AIM
				_clock = 0.0
		Phase.AIM:
			var aimed := _turn_toward(delta)
			if (aimed and _clock > 0.4) or _clock > GIVE_UP:
				_fire()
				phase = Phase.HOLD
				_clock = 0.0
		Phase.HOLD:
			if _clock > 0.8:
				phase = Phase.LOWER
		Phase.LOWER:
			_raise = move_toward(_raise, 0.0, delta / RISE_TIME)
			_yaw = move_toward(_yaw, 0.0, deg_to_rad(TURN) * delta)
			_pitch = move_toward(_pitch, 0.0, deg_to_rad(TURN) * delta)
			if _raise <= 0.0:
				phase = Phase.REST
	_turret.position.y = boss.size.y * 0.5 - 1.5 + _raise * 2.6
	_turret.rotation.y = _yaw
	_barrel.rotation.x = _pitch
	_sight.visible = phase == Phase.AIM


## GIRA HACIA LO QUE ATACA, despacio (en el espacio del torso). Devuelve si ya lo tiene en la mira.
func _turn_toward(delta: float) -> bool:
	if not is_instance_valid(_target):
		return false
	var local := global_transform.affine_inverse() * BossBrain.centre_of(_target)
	var from := _turret.position + Vector3(0, 0.6, 0)
	var way := local - from
	var want_yaw := atan2(-way.x, -way.z)
	var want_pitch := atan2(way.y, Vector2(way.x, way.z).length())
	var step := deg_to_rad(TURN) * delta
	_yaw += clampf(angle_difference(_yaw, want_yaw), -step, step)
	_pitch += clampf(angle_difference(_pitch, want_pitch), -step, step)
	var off := absf(angle_difference(_yaw, want_yaw)) + absf(angle_difference(_pitch, want_pitch))
	return rad_to_deg(off) < AIMED


## TIRA: un obús por donde apunta el caño, hasta el piso (o lo que ataca, si está más cerca).
func _fire() -> void:
	if boss.field == null or not is_instance_valid(_target):
		return
	var length := boss.size.z * 0.75
	var from := _barrel.global_transform * Vector3(0, 0, -length)
	var way := -_barrel.global_basis.z
	var here := BossBrain.ground_of(_target, boss)
	var far := from.distance_to(BossBrain.centre_of(_target))
	var spot := from + way * far
	spot.y = here.y
	boss.launch(Missile.Kind.SHELL, from, spot, maxf(far / SHELL_SPEED, 0.25))


func _laser() -> void:
	if phase == Phase.AIM:
		var charging := clampf(_clock / CHARGE, 0.0, 1.0)
		_eye_material.emission_energy_multiplier = lerpf(0.2, 6.0, charging) if _clock < _sweep_end else 0.2
		if _clock > _sweep_end + 0.3:
			phase = Phase.REST
	else:
		_eye_material.emission_energy_multiplier = 0.2
