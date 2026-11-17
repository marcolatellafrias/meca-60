class_name PodMech
extends ToolMech

## LA MECA DE CÁPSULAS (ver PodCabin): la Meca de tres (ToolMech: cinemática, la energía común, el cañón a la izquierda,
## sus teclas, las placas) con la cabina de cápsulas y, a la derecha, EL PUÑO DE SIEMPRE en vez del taladro, sin placa
## (el usuario, 15/11/2026: «con cañón y en el otro puño normal»).


func _init() -> void:
	super()
	cabin_shape = Cabin.PODS


func _ready() -> void:
	super()
	name = "Meca de cápsulas"


func default_loadout() -> Array[ArmLoadout]:
	return PodMech.default_arms()


## Lo suyo: el cañón a la izquierda, con placa, y el puño común a la derecha, sin; discretos.
static func default_arms() -> Array[ArmLoadout]:
	return [ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.CANNON, true),
		ArmLoadout.of(ArmLoadout.Motion.POSE, ArmLoadout.Tip.FIST)]
