class_name BaseTerminal
extends ActivatableInteractable

## UNA CONSOLA DE LA BASE QUE SE USA (ver BaseLayout._console): se mira, se aprieta E y se abre su pantalla
## (TerminalScreen). Cuelga del cuerpo de la consola, que es lo que se contornea al mirarla.

enum Screen { ARMORY, CONTRACTS }

var screen := Screen.ARMORY


func activate(actor: Node = null) -> void:
	super.activate(actor)
	var opened: TerminalScreen
	match screen:
		Screen.ARMORY:
			opened = ArmoryScreen.new()
		Screen.CONTRACTS:
			opened = ContractsScreen.new()
	TerminalScreen.open_screen(opened, get_tree())


func get_outline_targets() -> Array[Node]:
	var targets: Array[Node] = [get_parent()]
	return targets

