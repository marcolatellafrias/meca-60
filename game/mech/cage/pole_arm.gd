class_name PoleArm
extends MuscleArm

## EL BRAZO DEL PALO DE LA MECA JAULA, brazo derecho: un brazo con músculos (MuscleArm: el camino físico, choca y se
## traba) con EL PUÑO PESADO de la armería (ArmoryParts.make_heavy) siempre cerrado, AGARRANDO UN PALO ELÉCTRICO (la
## 147 de tests/cage_ideas_look; el usuario: «un palo eléctrico… que lo esté agarrando con la mano»). Pega las piñas de
## siempre; el palo, por ahora, sólo se ve (no choca). Con las placas del acorazado en el brazo y el antebrazo.

## El palo, en la medida de la mano (el puño en el origen; la mayor parte arriba).
const POLE_LOW := -2.2
const POLE_HIGH := 6.5
const SPARK := Color(0.55, 0.78, 0.9)

## Donde el puño agarra el palo.
var grip: Node3D = null


func _ready() -> void:
	super()
	var out := anchor.global_basis * Vector3.RIGHT * side
	CageMech.plate(upper, out, measures.thick, float(MechBody.BASE["UPPER_ARM"]) * 0.75)
	CageMech.plate(forearm, out, measures.thick, float(MechBody.BASE["FOREARM"]) * 0.7)


## EL PUÑO PESADO en la punta del antebrazo, con la boca de la armería; los nudillos parados (el palo hacia arriba,
## inclinado hacia adelante, con el brazo en reposo) y el palo pasando por adentro del puño.
func _mount_hand(piece: Node3D) -> void:
	var k := measures.thick
	var tip := -forearm_length() * 0.5
	Clay.cylinder(piece, ArmoryParts.MOUTH * k, 0.7 * k, Vector3(0, 0, tip + 0.05 * k),
		ArmoryParts.FOREARM_COLOR.darkened(0.15), Vector3(90, 0, 0))
	_hand = MechHand.build(piece, side)
	_hand.fist = true
	_hand.position = Vector3(0, 0, tip)
	var torso := anchor.global_basis.orthonormalized()
	var up := torso * (Basis(Vector3.RIGHT, -0.45) * Vector3.UP)
	var ahead := -piece.global_basis.z.normalized()
	ahead = (ahead - up * ahead.dot(up)).normalized()
	_hand.global_basis = Basis(up.cross(-ahead), up, -ahead)
	ArmoryParts.make_heavy(_hand, k)
	# El hueco del puño: delante de la palma, del lado al que cierran los dedos.
	grip = Node3D.new()
	grip.name = "Palo"
	grip.position = Vector3(-side * 0.75, 0.0, -1.35)
	_hand.add_child(grip)
	_pole()


## Siempre cerrado: agarra el palo.
func _advance(delta: float) -> void:
	super(delta)
	if _hand != null:
		_hand.fist = true


## EL PALO ELÉCTRICO: la vara, sus topes, cuatro bobinas debajo de la cabeza y dos puntas con una bola entre ellas.
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
