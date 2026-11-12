class_name ActivatableInteractable
extends Interactable

signal activated()

func activate(actor: Node = null) -> void:
	activated.emit()
