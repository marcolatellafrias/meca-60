class_name MechLegs
extends Node3D

## LA PELVIS Y LAS PIERNAS DE LA MECA: DIBUJO (IK, MechBody; cada pierna, un MechLeg). No sostienen nada: siguen al
## apoyo del péndulo (ver Mech). El usuario: «las piernas van a seguir siendo IK».
##   · PISAN POR RADIO alrededor del punto de apoyo, mirando hacia donde mira el torso: cada pie queda donde pisó hasta
##     que su lugar —al costado del apoyo, adelantado con la marcha— se aleja más que `step_radius`; ahí da un paso
##     hasta ese lugar, de a un pie.
##   · Cada pie guarda hacia dónde miraba al pisar y LA PELVIS, una sola pieza, mira al promedio de los dos pies (va
##     atrás del torso al girar, y lo alcanza). Es un tambor redondo y hueco: por adentro pasa el ascensor (PelvisLift).
##   · CAÍDA, SE PLIEGAN (no se achican: las piezas no se estiran) con easing; al empezar a enderezarse, se estiran
##     hacia debajo de las caderas: al quedar derecha ya está parada.
##   · EL PIE, NUNCA MÁS LEJOS DE LO QUE LA PIERNA ALCANZA: en el aire cuelga de la cadera.

var mech: Mech = null
var steps_taken := 0

var _feet: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]
var _feet_yaw: Array[float] = [0.0, 0.0]
var _step := {}
var _planted := false
var _tuck := 0.0
var _pelvis: MeshInstance3D = null
var _legs: Array[MechLeg] = []


func _ready() -> void:
	_pelvis = PelvisLift.tube(Clay.METAL.darkened(0.15))
	_pelvis.top_level = true
	add_child(_pelvis)
	for i in 2:
		var leg := MechLeg.new()
		add_child(leg)
		_legs.append(leg)


## Los pies vuelven a plantarse debajo (al aterrizar).
func replant() -> void:
	_planted = false


func place(k: MechSettings, delta: float) -> void:
	var standing := mech.state == Mech.State.STANDING and mech.grounded
	# RECOGIDAS tirada y subiendo; ESTIRADAS parada y ya al empezar a enderezarse.
	var folded := mech.state == Mech.State.DOWN or mech.state == Mech.State.LIFT
	_tuck = move_toward(_tuck, 1.0 if folded else 0.0, delta / maxf(k.fold_time if folded else k.unfold_time, 0.01))
	var share := smoothstep(0.0, 1.0, _tuck)
	var yaw := mech.yaw()
	var centre := mech.global_position
	var under := mech.support if standing else Vector3(centre.x, centre.y - mech.ground_distance(centre), centre.z)
	var root := Transform3D(Basis(Vector3.UP, yaw), under)
	if standing:
		if not _planted:
			_feet = [MechBody.foot_rest(root, -1.0), MechBody.foot_rest(root, 1.0)]
			_feet_yaw = [yaw, yaw]
			_planted = true
		_stepping(k, delta, root, yaw)
	else:
		_planted = false
		_step = {}
	# LA PELVIS: cuelga de la caja, inclinada como ella, mirando al promedio de los dos pies.
	var pelvis_yaw := lerp_angle(_feet_yaw[0], _feet_yaw[1], 0.5) if standing else yaw
	var leaning := Basis(Quaternion(Vector3.UP, mech.global_basis.y.normalized())) if mech.tilt > 0.01 else Basis()
	var waist := Transform3D(leaning * Basis(Vector3.UP, pelvis_yaw),
		mech.global_transform * Vector3(0.0, -Mech.SIZE * 0.5, 0.0))
	if not standing:
		waist.basis = mech.global_basis
	_pelvis.global_transform = MechBody.pelvis(waist)
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		# Estiradas: parada, donde pisan; recién caída, donde pisaban; enderezándose o en el aire, debajo de las caderas.
		var ground := _foot_ground(k, i) if standing else (_feet[i] if folded else MechBody.foot_rest(root, side))
		var facing := Basis(Vector3.UP, _feet_yaw[i]) if standing else root.basis
		var hip := MechBody.hip(waist, side)
		var to_ankle := ground + Vector3.UP * MechBody.ANKLE - hip
		var reach := MechBody.THIGH + MechBody.SHIN - 0.5
		if to_ankle.length() > reach:
			ground = hip + to_ankle.normalized() * reach - Vector3.UP * MechBody.ANKLE
		var open := MechBody.leg(hip, ground, facing)
		_legs[i].pose(MechLegs._blend(open, _tucked_leg(waist, side), share) if share > 0.001 else open)


## LOS PASOS POR RADIO (ver arriba).
func _stepping(k: MechSettings, delta: float, root: Transform3D, yaw: float) -> void:
	var ahead := Transform3D(root.basis, root.origin + mech.support_speed * k.step_lead)
	if not _step.is_empty():
		var foot := int(_step["foot"])
		_step["clock"] = float(_step["clock"]) + delta
		_step["to"] = MechBody.foot_rest(ahead, -1.0 if foot == 0 else 1.0)
		_feet_yaw[foot] = lerp_angle(float(_step["yaw_from"]), yaw, clampf(float(_step["clock"]) / k.step_time, 0.0, 1.0))
		if float(_step["clock"]) >= k.step_time:
			_feet[foot] = _step["to"]
			_step = {}
		return
	var worst := -1
	var farthest := k.step_radius
	for i in 2:
		var rest := MechBody.foot_rest(ahead, -1.0 if i == 0 else 1.0)
		var away := Vector2(rest.x - _feet[i].x, rest.z - _feet[i].z).length()
		if away > farthest:
			worst = i
			farthest = away
	if worst < 0:
		return
	_step = {"foot": worst, "from": _feet[worst], "to": MechBody.foot_rest(ahead, -1.0 if worst == 0 else 1.0),
		"clock": 0.0, "yaw_from": _feet_yaw[worst]}
	steps_taken += 1


func _foot_ground(k: MechSettings, index: int) -> Vector3:
	if _step.is_empty() or int(_step["foot"]) != index:
		return _feet[index]
	var share := clampf(float(_step["clock"]) / k.step_time, 0.0, 1.0)
	var from: Vector3 = _step["from"]
	var to: Vector3 = _step["to"]
	return from.lerp(to, share) + Vector3.UP * sin(share * PI) * k.step_height


## UNA PIERNA RECOGIDA, en el espacio de la cintura: el muslo adelante y casi horizontal, la canilla de vuelta abajo y
## el pie debajo de la cadera.
func _tucked_leg(waist: Transform3D, side: float) -> Dictionary:
	var hip := Vector3(side * MechBody.HIP_X, -MechBody.HIP_DROP, 0.0)
	var knee := hip + Vector3(0.0, 0.15, -1.0).normalized() * MechBody.THIGH
	var ankle := knee + Vector3(0.0, -0.45, 1.0).normalized() * MechBody.SHIN
	var up := waist.basis.y
	return {
		"thigh": MechBody.segment(waist * hip, waist * knee, up),
		"shin": MechBody.segment(waist * knee, waist * ankle, up),
		"foot": Transform3D(waist.basis, waist * (ankle + Vector3(0.0, MechBody.FOOT_SIZE.y * 0.5 - MechBody.ANKLE,
			-MechBody.FOOT_AHEAD))),
		"knee": waist * knee,
	}


static func _blend(from: Dictionary, to: Dictionary, share: float) -> Dictionary:
	return {
		"thigh": (from["thigh"] as Transform3D).interpolate_with(to["thigh"], share),
		"shin": (from["shin"] as Transform3D).interpolate_with(to["shin"], share),
		"foot": (from["foot"] as Transform3D).interpolate_with(to["foot"], share),
		"knee": (from["knee"] as Vector3).lerp(to["knee"], share),
	}
