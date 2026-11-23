class_name BaseTubeButton
extends ActivatableInteractable

## EL BOTÓN AL LADO DEL TUBO DE MUNICIÓN: con la E o el clic cambia lo que sale. Lo puede usar cualquiera.

var tube: BaseSupplyTube = null


func _init() -> void:
	name = "Usar"


func can_interact() -> bool:
	var player := DesignSandbox.player_of(get_tree())
	return BaseSupplies.current != null and is_instance_valid(player) and not is_instance_valid(player.carried)


func activate(actor: Node = null) -> void:
	super.activate(actor)
	BaseSupplies.current.ask_next(tube.slot)


func get_outline_targets() -> Array[Node]:
	var targets: Array[Node] = [get_parent()]
	return targets
