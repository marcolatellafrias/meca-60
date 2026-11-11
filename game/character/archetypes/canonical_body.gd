class_name CanonicalBody
extends Resource

## LO QUE EL PANEL DEL CANÓNICO EDITA COMO NÚMEROS (F4 en la fila Personajes, ver CharacterLookPanel): la escala de la
## cabeza. No se guarda así: es la hoja que el panel le muestra a PropertyTuner, y cada cambio vuelve al torso del
## arquetipo (ver TorsoShape.head_scale, la misma del F1). *La pose base que tuvo se borró el 07/11/2026: la postura es
## del F3.*

@export_group("Cabeza")
## LA ESCALA DE LA CABEZA, la del cuerpo (ver TorsoShape.head_scale): el mismo número que el F1, no uno más.
@export_range(0.4, 2.5, 0.01, "suffix:×") var head_scale := 1.0


## LA HOJA con la escala de cabeza `head`.
static func of(head: float) -> CanonicalBody:
	var out := CanonicalBody.new()
	out.head_scale = head
	return out
