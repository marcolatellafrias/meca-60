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
			var contracts := ContractsScreen.new()
			contracts.on_launch = _open_hatch
			opened = contracts
	TerminalScreen.open_screen(opened, get_tree())


func get_outline_targets() -> Array[Node]:
	var targets: Array[Node] = [get_parent()]
	return targets


## La compuerta del techo de la misma base (Plano/Compuerta).
func _open_hatch() -> void:
	# en la partida, en todos (BaseSync); en el sandbox, la de esta base
	if BaseSync.current != null:
		BaseSync.current.open_hatch()
		return
	var holder := get_parent()
	while holder and not holder.is_in_group(BaseLayout.GROUP):
		holder = holder.get_parent()
	var hatch := holder.get_node_or_null("Compuerta") as BaseHatch if holder else null
	if hatch:
		hatch.set_open(true)
