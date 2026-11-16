class_name CageCannonArm
extends CannonArm

## EL CAÑÓN DE LA MECA JAULA, brazo izquierdo: el cañón de energía de la Meca de tres (CannonArm: sus cuatro modos, la
## palanca que el brazo sigue tarde), con la forma de la maqueta (tests/cage_ideas_look, 147 a 173): EL CAÑÓN EN LUGAR
## DEL ANTEBRAZO (el usuario: «el cañón… debería reemplazar el antebrazo»), del codo hasta donde terminaría el puño («que
## quede con el cañón el mismo largo que tendría con el puño»). Con la placa del acorazado en el brazo.


func _ready() -> void:
	super()
	CageMech.plate(_upper, anchor.global_basis * Vector3.RIGHT * side, measures.thick,
		float(MechBody.BASE["UPPER_ARM"]) * 0.75)


## EL CAÑÓN en vez del antebrazo y la mano: sin el cilindro del antebrazo; desde el codo, un cuello y el cañón gris
## oscuro con dos aros y la boca, armado en la medida de la meca entera y achicado al ancho de esta.
func _mount_hand(forearm: Node3D) -> void:
	(forearm.get_child(0) as Node3D).visible = false
	var k := measures.thick
	var holder := Node3D.new()
	holder.name = "Cañón"
	holder.scale = Vector3.ONE * k
	forearm.add_child(holder)
	var elbow := forearm_length() * 0.5 / k
	var muzzle := ArmoryParts.TIP - 1.4
	Clay.cylinder(holder, 1.15, 1.0, Vector3(0, 0, elbow - 0.9), Clay.METAL.darkened(0.1), Vector3(90, 0, 0))
	var from := elbow - 1.4
	var to := muzzle + 0.8
	Clay.cylinder(holder, 1.45, from - to, Vector3(0, 0, (from + to) * 0.5), ArmoryParts.CANNON_COLOR, Vector3(90, 0, 0))
	for z: float in [from - 0.6, (from + to) * 0.5]:
		Clay.cylinder(holder, 1.55, 0.25, Vector3(0, 0, z), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
	Clay.cylinder(holder, 1.05, 0.8, Vector3(0, 0, muzzle + 0.4), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
	Clay.cylinder(holder, 0.6, 0.1, Vector3(0, 0, muzzle - 0.02), Clay.DARK, Vector3(90, 0, 0))
	# Los tiros salen de la boca (ver CannonArm.muzzle: el largo más allá de la punta del antebrazo).
	_barrel = -muzzle * k - forearm_length() * 0.5
