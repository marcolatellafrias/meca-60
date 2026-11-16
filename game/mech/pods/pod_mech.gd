class_name PodMech
extends ToolMech

## LA MECA DE CÁPSULAS (ver PodCabin): la Meca de tres (ToolMech: cinemática, la energía común, el cañón a la izquierda,
## sus teclas, las placas) con la cabina de cápsulas y, a la derecha, EL PUÑO DE SIEMPRE en vez del taladro (el usuario,
## 15/11/2026: «con cañón y en el otro puño normal»).


func _init() -> void:
	super()
	cabin_shape = Cabin.PODS


func _ready() -> void:
	super()
	name = "Meca de cápsulas"


## EL BRAZO DERECHO: el discreto de siempre, con su puño.
func _right_arm() -> MechArm:
	return PoseArm.new()
