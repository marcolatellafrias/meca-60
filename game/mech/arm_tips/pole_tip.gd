class_name PoleTip
extends HeavyFistTip

## EL PALO ELÉCTRICO: el puño pesado SIEMPRE CERRADO, AGARRANDO EL PALO (la 147 de tests/cage_ideas_look; el usuario:
## «un palo eléctrico… que lo esté agarrando con la mano»). Pega las piñas de siempre; el palo, por ahora, sólo se ve
## (no choca). *Era el brazo derecho de la meca jaula (PoleArm, un brazo con músculos) hasta el 16/11/2026.*

## El palo, en la medida de la mano (el puño en el origen; la mayor parte arriba).
const POLE_LOW := -2.2
const POLE_HIGH := 6.5
const SPARK := Color(0.55, 0.78, 0.9)
## EL MAZAZO (17/11/2026; el usuario: «haría una animación para cuando está pegando con un palo… está pegando con la misma
## animación del puño»): el puño sube por encima del hombro y baja adelante, estirado, y LA MUÑECA lleva el palo: atrás
## por encima del hombro al armarse (`COCKED`) y adelante y abajo al pegar (`STRUCK`), direcciones en el espacio del
## torso (x afuera de su lado, y arriba, z atrás). La punta del palo hace el arco más largo: es la que más rápido va.
const CHOP := [[0.5, Vector3(0.8, 3.0, 0.8)], [0.24, Vector3(-0.4, -3.6, -8.4)], [0.25, Vector3(-0.4, -3.6, -8.4)]]
const COCKED := Vector3(0.0, 0.45, 1.0)
const STRUCK := Vector3(0.0, -0.4, -1.0)

## Donde el puño agarra el palo, y hacia dónde va el palo en reposo (en el espacio del torso).
var grip: Node3D = null
var _rest_way := Vector3.UP
## Hacia dónde iba el palo el paso anterior (en el torso): frenado donde pegó, se queda así.
var _way := Vector3.UP


## El puño pesado con los nudillos parados (el palo hacia arriba, inclinado hacia adelante, con el brazo en reposo) y
## el palo pasando por adentro del puño.
func _build() -> void:
	var k := arm.measures.thick
	_mouth()
	var hand := MechHand.build(forearm, arm.side)
	arm._hand = hand
	hand.fist = true
	hand.position = Vector3(0, 0, -arm.forearm_length() * 0.5)
	var torso := arm.anchor.global_basis.orthonormalized()
	var up := torso * (Basis(Vector3.RIGHT, -0.45) * Vector3.UP)
	var ahead := -forearm.global_basis.z.normalized()
	ahead = (ahead - up * ahead.dot(up)).normalized()
	hand.global_basis = Basis(up.cross(-ahead), up, -ahead)
	ArmoryParts.make_heavy(hand, k)
	# El hueco del puño: delante de la palma, del lado al que cierran los dedos.
	grip = Node3D.new()
	grip.name = "Palo"
	grip.position = Vector3(-arm.side * 0.75, 0.0, -1.35)
	hand.add_child(grip)
	_rest_way = torso.inverse() * hand.global_basis.y.normalized()
	_pole()


## LO QUE GOLPEA: el puño y el palo entero, de punta a punta, con puntos a menos de un radio uno del otro.
func strike_points() -> PackedVector3Array:
	var points := super()
	if grip == null:
		return points
	var low := grip.global_transform * Vector3(0, POLE_LOW, 0)
	var high := grip.global_transform * Vector3(0, POLE_HIGH + 0.85, 0)
	var count := maxi(int(ceil(low.distance_to(high) / maxf(arm.strike_radius(), 0.05))), 1)
	for i in count + 1:
		points.append(low.lerp(high, float(i) / count))
	return points


## Siempre cerrado: agarra el palo. Y la muñeca (ver `CHOP`): se echa atrás armándose, se suelta pegando, vuelve.
func step(_delta: float) -> void:
	if arm._hand != null:
		arm._hand.fist = true
	if grip == null:
		return
	if arm._aimed != CHOP:
		grip.basis = Basis()
		return
	var share := smoothstep(0.0, 1.0, arm.stage_share())
	var rest := _rest_way
	var cocked := Vector3(arm.side * COCKED.x, COCKED.y, COCKED.z).normalized()
	var struck := Vector3(arm.side * STRUCK.x, STRUCK.y, STRUCK.z).normalized()
	var way := rest
	if arm.stuck and arm.stage() != MechArm.Stage.RETURN:
		way = _way
	else:
		match arm.stage():
			MechArm.Stage.WINDUP:
				way = rest.slerp(cocked, share)
			MechArm.Stage.STRIKE:
				way = cocked.slerp(struck, share)
			MechArm.Stage.HOLD:
				way = struck
			MechArm.Stage.RETURN:
				way = (_way if arm.stuck else struck).slerp(rest, share)
	if arm.stage() != MechArm.Stage.RETURN:
		_way = way
	# El palo hacia `way` (en el mundo, desde el torso), de costado lo más cerca del eje del hombro.
	var torso := arm.anchor.global_basis.orthonormalized()
	var up := (torso * way).normalized()
	var across := torso.x - up * torso.x.dot(up)
	grip.global_basis = Basis(across.normalized(), up, across.normalized().cross(up)).scaled(grip.global_basis.get_scale())


func strike_path() -> Array:
	return CHOP


## LA VARA, sus topes, cuatro bobinas debajo de la cabeza y dos puntas con una bola entre ellas.
func _pole() -> void:
	var shaft := Clay.DARK.lightened(0.18)
	Clay.cylinder(grip, 0.3, POLE_HIGH - POLE_LOW, Vector3(0, (POLE_HIGH + POLE_LOW) * 0.5, 0), shaft)
	Clay.cylinder(grip, 0.42, 0.4, Vector3(0, POLE_LOW, 0), MechBody.JOINT_COLOR)
	Clay.cylinder(grip, 0.4, 0.2, Vector3(0, 1.3, 0), MechBody.JOINT_COLOR)
	for i in 4:
		Clay.cylinder(grip, 0.5, 0.14, Vector3(0, POLE_HIGH - 1.6 + i * 0.32, 0), Clay.METAL.darkened(0.25))
	Clay.cylinder(grip, 0.45, 0.4, Vector3(0, POLE_HIGH, 0), MechBody.JOINT_COLOR)
	for x: float in [-0.3, 0.3]:
		Clay.cylinder(grip, 0.09, 1.2, Vector3(x, POLE_HIGH + 0.8, 0), ArmoryParts.STEEL)
	Clay.sphere(grip, 0.24, Vector3(0, POLE_HIGH + 0.85, 0), SPARK)
