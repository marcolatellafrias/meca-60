class_name PoleTip
extends HeavyFistTip

## EL PALO ELÉCTRICO: el puño pesado SIEMPRE CERRADO, AGARRANDO EL PALO (la 147 de tests/cage_ideas_look; el usuario:
## «un palo eléctrico… que lo esté agarrando con la mano»). Pega las piñas de siempre; el palo, por ahora, sólo se ve
## (no choca). *Era el brazo derecho de la meca jaula (PoleArm, un brazo con músculos) hasta el 16/11/2026.*

## El palo, en la medida de la mano (el puño en el origen; la mayor parte arriba).
const POLE_LOW := -2.2
const POLE_HIGH := 6.5
const SPARK := Color(0.55, 0.78, 0.9)
## El radio del palo (en la medida de la mano): lo que agarra el puño (ver MechHand.grip_on).
const POLE_RADIUS := 0.3
## EL MAZAZO (17/11/2026; el usuario: «haría una animación para cuando está pegando con un palo… está pegando con la misma
## animación del puño»; y después: «la muñeca no la quebraría, se haría solamente movimiento de brazo, con un swing»):
## el puño sube por encima del hombro y baja adelante, estirado. El palo va SIEMPRE FIJO EN EL PUÑO (ver `_build`): el
## arco lo hace el brazo. La punta del palo hace el arco más largo: es la que más rápido va.
const CHOP := [[0.5, Vector3(-0.2, 2.6, -2.4)], [0.24, Vector3(-0.2, -7.8, -2.8)], [0.25, Vector3(-0.2, -7.8, -2.8)]]
## EL CODO, EN UN PLANO PARADO (ver `_bend`): el brazo dobla como el de quien lleva un garrote, así el pulgar —y el palo—
## van para arriba y no cruzados delante del cuerpo; cuánto sale hacia afuera.
const ELBOW_OUT := 0.15

## Donde el puño agarra el palo: el eje del palo, en el medio del hueco de los dedos.
var grip: Node3D = null


## LA MANO DE SIEMPRE, montada derecha en el antebrazo (sin quebrar la muñeca), en puño pesado AGARRANDO EL PALO: los
## dedos se cierran alrededor (MechHand.grip_on) y el palo pasa por el medio de su hueco, a lo largo de los cuatro dedos,
## con la punta del lado del pulgar. Palo y puño son una sola pieza.
func _build() -> void:
	_mouth()
	arm.mount_common_hand(forearm)
	var hand := arm._hand
	hand.fist = true
	ArmoryParts.make_heavy(hand, arm.measures.thick)
	grip = Node3D.new()
	grip.name = "Palo"
	hand.add_child(grip)
	grip.position = hand.grip_on(POLE_RADIUS)
	_pole()


## SU ZONA: una línea, a lo largo del palo.
func zone() -> Dictionary:
	return MechSkills.pole()


## Siempre cerrado: agarra el palo. Y el codo, en su plano (ver `_bend`).
func step(_delta: float) -> void:
	if arm._hand != null:
		arm._hand.fist = true
	_bend()


## EL CODO EN UN PLANO PARADO, SIEMPRE DEL MISMO LADO (MechArm.elbow_hint): perpendicular a la línea del hombro al puño
## pedido, girada un cuarto de vuelta hacia atrás —abajo y atrás con el puño adelante, arriba y adelante con el puño
## atrás de la cabeza—, como un codo de verdad, que dobla siempre para el mismo lado. Si el codo cambiara de lado a mitad
## del golpe, el antebrazo daría media vuelta sobre su largo y el palo con él.
func _bend() -> void:
	var asked := arm._moves()
	var way := Vector3(0.0, asked.y, asked.z)
	if way.length() < 0.001:
		return
	way = way.normalized()
	arm.elbow_hint = Vector3(ELBOW_OUT, way.z, -way.y)


func strike_path() -> Array:
	return CHOP


## LA VARA, sus topes, cuatro bobinas debajo de la cabeza y dos puntas con una bola entre ellas.
func _pole() -> void:
	var shaft := Clay.DARK.lightened(0.18)
	Clay.cylinder(grip, POLE_RADIUS, POLE_HIGH - POLE_LOW, Vector3(0, (POLE_HIGH + POLE_LOW) * 0.5, 0), shaft)
	Clay.cylinder(grip, 0.42, 0.4, Vector3(0, POLE_LOW, 0), MechBody.JOINT_COLOR)
	Clay.cylinder(grip, 0.4, 0.2, Vector3(0, 1.3, 0), MechBody.JOINT_COLOR)
	for i in 4:
		Clay.cylinder(grip, 0.5, 0.14, Vector3(0, POLE_HIGH - 1.6 + i * 0.32, 0), Clay.METAL.darkened(0.25))
	Clay.cylinder(grip, 0.45, 0.4, Vector3(0, POLE_HIGH, 0), MechBody.JOINT_COLOR)
	for x: float in [-0.3, 0.3]:
		Clay.cylinder(grip, 0.09, 1.2, Vector3(x, POLE_HIGH + 0.8, 0), ArmoryParts.STEEL)
	Clay.sphere(grip, 0.24, Vector3(0, POLE_HIGH + 0.85, 0), SPARK)
