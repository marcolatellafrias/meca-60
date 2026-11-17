class_name GuardedButton
extends KeyComponent

## UN BOTÓN CON TAPA: se aprieta y se hunde como una tecla (ver KeyComponent), pero SOLO CON LA TAPA ABIERTA (ver
## SafetyCover). Lo usa el botón de peligro.

var cover: SafetyCover = null


func can_interact() -> bool:
	return super.can_interact() and (cover == null or cover.open)
