class_name BaseDoorUse
extends ActivatableInteractable

## LA PUERTA DE LA ESCLUSA SE USA ELLA MISMA (22/11/2026; el usuario: «lo que yo tengo que apuntar sea la puerta nomás…
## que sublinee la puerta»): se la apunta, se resalta entera y la E la abre. Sólo el capitán, y sólo mientras no se abrió.

var airlock: BaseAirlock = null


func _init() -> void:
	name = "Usar"


func can_interact() -> bool:
	return is_instance_valid(airlock) and airlock.armed and BaseState.is_captain(get_tree())


func activate(actor: Node = null) -> void:
	super.activate(actor)
	airlock._on_front_pressed()


func get_outline_targets() -> Array[Node]:
	var targets: Array[Node] = [get_parent()]
	return targets
