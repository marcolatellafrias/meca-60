class_name BaseLiftUse
extends ActivatableInteractable

## EL PEDESTAL DEL ASCENSOR SE USA ENTERO (22/11/2026; el usuario no llegaba a resaltar el botoncito): se lo apunta, se
## resalta y la E o el clic arrancan. Si falta algo, no arranca y el cartel de arriba dice qué.

var elevator: BaseElevator = null


func _init() -> void:
	name = "Usar"


func can_interact() -> bool:
	return is_instance_valid(elevator) and not elevator.launched and BaseState.is_captain(get_tree())


func activate(actor: Node = null) -> void:
	super.activate(actor)
	elevator._on_pressed()


func get_outline_targets() -> Array[Node]:
	var targets: Array[Node] = [get_parent()]
	return targets
