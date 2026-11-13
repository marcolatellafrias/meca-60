class_name BossLegs
extends BodyLegs

## LAS PATAS DE UNA MECA ENEMIGA (13/11/2026) — TRABAJO EN CURSO: dos, cuatro o seis, sólo dibujo, que siguen al apoyo
## del péndulo como las piernas de la meca propia (ver BodyLegs, BalanceBody). Lo que cambia es de dónde sale cada pata
## y dónde pisa (ver docs/technical/base-comun.md: «las piernas no siempre salen de la pelvis… una araña larga con las
## patas saliendo de los costados»):
##   · DOS PIERNAS: de los costados de la pelvis (o de abajo de la caja), la rodilla hacia adelante.
##   · CUATRO PATAS: de las cuatro esquinas de abajo, abiertas, la rodilla para arriba y afuera.
##   · ARAÑA: seis, de los costados de la caja a media altura, muy abiertas, la rodilla bien arriba.
## LOS PASOS van POR GRUPOS que se turnan (dos piernas: de a una; cuatro: las cruzadas juntas; seis: de a tres, en
## trípode), de largo fijo como los de la meca propia: más rápido, más seguido. Quieta, un grupo se acomoda si un pie
## quedó lejos de su lugar.
## Cada pata calcula sus largos al armarse, para pisar su lugar con la rodilla doblada (`STRETCH`).

const STRETCH := 0.8

var design: BossDesign = null

## Cada pata: `hip` (en la caja), `rest` (dónde pisa, en el espacio del apoyo girado como el torso), `thigh`, `shin`,
## `radius`, `up_knee` (la rodilla para arriba y afuera, o adelante) y sus piezas.
var _legs_data: Array[Dictionary] = []
var _groups: Array = []
var _swing_group := -1
var _last_group := -1
var _from: Array[Vector3] = []
var _ground_feet: Array[Vector3] = []
var _step_clock := 0.0
var _step_time := 1.0
var _was_planted := false
var _fold := 0.0


func _ready() -> void:
	var colors := design.colors()
	for leg in _legs_data:
		leg["thigh_part"] = Clay.limb(self, leg["radius"], leg["thigh"], Vector3.ZERO, colors["limb"])
		leg["shin_part"] = Clay.limb(self, float(leg["radius"]) * 0.85, leg["shin"], Vector3.ZERO, (colors["limb"] as Color).darkened(0.12))
		leg["hip_part"] = Clay.sphere(self, float(leg["radius"]) * 1.35, Vector3.ZERO, colors["joint"])
		leg["knee_part"] = Clay.sphere(self, float(leg["radius"]) * 1.2, Vector3.ZERO, colors["joint"])
		var pad := float(leg["radius"]) * 2.4
		leg["foot_part"] = Clay.box(self, Vector3(pad, float(leg["radius"]) * 0.9, pad * 1.2), Vector3.ZERO, colors["joint"])
	top_level = true


## ARMA LAS PATAS para `body_size` (la caja) a `hover` del piso (de la cara de abajo), con la pelvis de `pelvis_drop`
## de alto debajo de la caja. Antes de entrar al árbol.
func setup(made: BossDesign, body_size: Vector3, hover: float, pelvis_drop: float) -> void:
	design = made
	var half := body_size * 0.5
	var bottom := -half.y
	var specs: Array[Dictionary] = []
	match made.legs:
		BossDesign.Legs.BIPED:
			var hip_x := body_size.x * 0.32
			var hip_y := bottom - pelvis_drop * 0.6
			for side: float in [-1.0, 1.0]:
				specs.append({"hip": Vector3(side * hip_x, hip_y, 0.0), "rest": Vector3(side * (hip_x + 0.4), 0.0, 0.0),
					"up_knee": false, "radius": body_size.x * 0.09})
			_groups = [[0], [1]]
		BossDesign.Legs.QUAD:
			var corner := Vector2(half.x * 0.8, half.z * 0.75)
			var hip_y := bottom - pelvis_drop * 0.4
			for z: float in [-1.0, 1.0]:
				for x: float in [-1.0, 1.0]:
					specs.append({"hip": Vector3(x * corner.x, hip_y, z * corner.y),
						"rest": Vector3(x * (corner.x + hover * 0.7), 0.0, z * (corner.y + hover * 0.45)),
						"up_knee": true, "radius": body_size.x * 0.07})
			# Las cruzadas juntas: adelante izquierda con atrás derecha.
			_groups = [[0, 3], [1, 2]]
		BossDesign.Legs.SPIDER:
			for z: float in [-1.0, 0.0, 1.0]:
				for x: float in [-1.0, 1.0]:
					specs.append({"hip": Vector3(x * half.x, bottom * 0.2, z * half.z * 0.7),
						"rest": Vector3(x * (half.x + hover * 2.2 + 3.0), 0.0, z * half.z * 1.5),
						"up_knee": true, "radius": body_size.x * 0.055})
			# Trípodes: adelante y atrás de un lado con el medio del otro.
			_groups = [[0, 3, 4], [1, 2, 5]]
	# EL OFFSET (ver BossDesign): abre las caderas a cada lado, las sube y las corre; los pies lo siguen de costado.
	var shift := made.legs_offset
	for spec in specs:
		var mirror := signf((spec["hip"] as Vector3).x)
		spec["hip"] = (spec["hip"] as Vector3) + Vector3(mirror * shift.x, shift.y, shift.z)
		spec["rest"] = (spec["rest"] as Vector3) + Vector3(mirror * shift.x, 0.0, shift.z)
		var hip: Vector3 = spec["hip"]
		var rest: Vector3 = spec["rest"]
		# Parada derecha, la cadera está a la altura del centro de la caja (`half.y + hover`) más la suya.
		var hip_height := half.y + hover + hip.y
		var reach := Vector2(Vector2(rest.x - hip.x, rest.z - hip.z).length(), hip_height).length()
		spec["thigh"] = reach / (2.0 * STRETCH)
		spec["shin"] = reach / (2.0 * STRETCH)
		_legs_data.append(spec)
	_feet.clear()
	_feet_yaw.clear()
	for i in _legs_data.size():
		_feet.append(Vector3.ZERO)
		_from.append(Vector3.ZERO)
		_ground_feet.append(Vector3.ZERO)


func replant() -> void:
	_was_planted = false


func place(k: BodySettings, delta: float) -> void:
	var standing := body.state == BalanceBody.State.STANDING and body.grounded
	var folded := body.state == BalanceBody.State.DOWN or body.state == BalanceBody.State.LIFT
	_fold = move_toward(_fold, 1.0 if folded else 0.0, delta / maxf(k.fold_time if folded else k.unfold_time, 0.01))
	var share := smoothstep(0.0, 1.0, _fold)
	var yaw := body.yaw()
	var centre := body.global_position
	var under := body.support if standing else Vector3(centre.x, centre.y - body.ground_distance(centre), centre.z)
	if standing:
		if not _was_planted:
			for i in _legs_data.size():
				_feet[i] = _spot_of(i, yaw, 0.0)
			_swing_group = -1
			_was_planted = true
		_step(k, delta, yaw)
	else:
		_was_planted = false
		_swing_group = -1
	var turn := Basis(Vector3.UP, yaw)
	for i in _legs_data.size():
		var leg := _legs_data[i]
		var hip: Vector3 = body.global_transform * (leg["hip"] as Vector3)
		# Parada, donde pisa; en el aire, colgando debajo de la cadera (no clavada en el piso).
		var hang := hip + Vector3.DOWN * (float(leg["thigh"]) + float(leg["shin"])) * 0.8 			+ turn * Vector3((leg["rest"] as Vector3).x - (leg["hip"] as Vector3).x, 0.0, 0.0) * 0.3
		var ground: Vector3 = _foot_at(k, i, yaw) if standing else (hang if body.airborne else under + turn * (leg["rest"] as Vector3))
		# Recogida: el pie, cerca y debajo de la cadera.
		var tucked := hip + body.global_basis * (Vector3((leg["hip"] as Vector3).x, -1.0, (leg["hip"] as Vector3).z).normalized()
			* float(leg["thigh"]) * 0.9)
		ground = ground.lerp(tucked, share)
		_ground_feet[i] = ground
		var ankle := ground + Vector3.UP * float(leg["radius"]) * 0.6
		var thigh: float = leg["thigh"]
		var shin: float = leg["shin"]
		if (ankle - hip).length() > thigh + shin - 0.1:
			ankle = hip + (ankle - hip).normalized() * (thigh + shin - 0.1)
		var out := Vector3(ankle.x - hip.x, 0.0, ankle.z - hip.z)
		out = out.normalized() if out.length_squared() > 0.01 else turn.x
		var hint := (Vector3.UP * 1.2 + out * 0.5) if bool(leg["up_knee"]) else (-turn.z + out * 0.15)
		var knee := MechBody.joint(hip, ankle, thigh, shin, hint)
		(leg["thigh_part"] as Node3D).transform = MechBody.segment(hip, knee, hint)
		(leg["shin_part"] as Node3D).transform = MechBody.segment(knee, ankle, hint)
		(leg["hip_part"] as Node3D).position = hip
		(leg["knee_part"] as Node3D).position = knee
		(leg["foot_part"] as Node3D).transform = Transform3D(turn, ground + Vector3.UP * float(leg["radius"]) * 0.45)


## LOS PASOS POR GRUPOS (ver arriba).
func _step(k: BodySettings, delta: float, yaw: float) -> void:
	if _swing_group >= 0:
		_step_clock += delta
		if _step_clock < _step_time:
			return
		for i: int in _groups[_swing_group]:
			_feet[i] = _spot_of(i, yaw, 0.0)
		_last_group = _swing_group
		_swing_group = -1
	var speed := body.support_speed.length()
	var moving := speed > STILL
	var time := k.step_slowest
	if moving:
		time = clampf(2.0 * k.step_reach / speed, k.step_fastest, k.step_slowest)
	var best := -1
	var worst := 0.0
	for g in _groups.size():
		# Andando, se turnan: no sale dos veces seguidas el mismo grupo.
		if moving and g == _last_group and _groups.size() > 1:
			continue
		var gap := 0.0
		for i: int in _groups[g]:
			var at := _spot_of(i, yaw, time)
			gap = maxf(gap, Vector2(at.x - _feet[i].x, at.z - _feet[i].z).length())
		var due := gap > 0.05 if moving else gap > k.settle_gap
		if due and gap > worst:
			worst = gap
			best = g
	if best < 0:
		return
	_swing_group = best
	for i: int in _groups[best]:
		_from[i] = _feet[i]
	_step_clock = 0.0
	_step_time = time
	steps_taken += 1


## DÓNDE PISA la pata `index` si le quedan `left` segundos de paso: su lugar alrededor de donde va a estar el apoyo,
## adelantado lo que avanza el cuerpo en medio paso.
func _spot_of(index: int, yaw: float, left: float) -> Vector3:
	var speed := body.support_speed.length()
	var lead := Vector3.ZERO
	if speed > 0.01:
		lead = body.support_speed / speed * minf(body.knobs.step_reach, speed * maxf(left, _step_time) * 0.5)
	var at := body.support + body.support_speed * left + Basis(Vector3.UP, yaw) * (_legs_data[index]["rest"] as Vector3) + lead
	at.y = body.support.y
	return at


## EL PIE: plantado donde pisó o, si su grupo está en el aire, de donde salió hacia donde va, en arco.
func _foot_at(k: BodySettings, index: int, yaw: float) -> Vector3:
	if _swing_group < 0 or not (_groups[_swing_group] as Array).has(index):
		return _feet[index]
	var share := clampf(_step_clock / _step_time, 0.0, 1.0)
	var to := _spot_of(index, yaw, maxf(_step_time - _step_clock, 0.0))
	var eased := smoothstep(0.0, 1.0, share)
	return _from[index].lerp(to, eased) + Vector3.UP * sin(share * PI) * k.step_height
