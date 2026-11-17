class_name HeavyFistTip
extends ArmTip

## EL PUÑO PESADO (el de la armería, ArmoryParts.make_heavy): la mano de siempre, más grande, con pinches en los
## nudillos, saliendo de la boca del antebrazo.


func _build() -> void:
	_mouth()
	super()
	ArmoryParts.make_heavy(arm._hand, arm.measures.thick)
