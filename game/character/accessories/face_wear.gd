class_name FaceWear
extends RefCounted

## LO QUE SE LLEVA EN LA CARA: la pipa, el cigarrillo y tres lentes —de alambre redondos, de medialuna para leer y
## quevedos, que se sostienen en la nariz sin patillas—, pedidos por el dios del juego el 10/10/2026.
##
## (SU FORMA —se ubicaban con los rasgos, los lentes de alambre— se borró el 07/11/2026 con la malla vieja del personaje;
## vive en la etiqueta de git `malla-personaje-archivada`. Quedan los nombres y los lugares: el aspecto los sortea.)

const NAMES: Array[String] = ["pipa", "cigarrillo", "lentes de alambre", "lentes de medialuna", "quevedos"]

## ── DÓNDE VA CADA UNO: UN LUGAR DE LA CARA, UNO DE CADA (22/10/2026, lo pidió el dios del juego) ──────────────────────
## Lo de la boca y lo de los ojos no se pisan: un personaje puede llevar un cigarrillo y lentes a la vez. Eran un solo
## lugar para los cinco. Cada uno dice el suyo, en el orden de `NAMES`; el aspecto lleva uno por lugar (ver CharacterLook,
## `eye_wear` y `mouth_wear`).
enum Slot { MOUTH, EYES }
const SLOT_OF: Array[int] = [Slot.MOUTH, Slot.MOUTH, Slot.EYES, Slot.EYES, Slot.EYES]


## Los de un lugar, por su número en `NAMES`.
static func in_slot(slot: int) -> Array[int]:
	var out: Array[int] = []
	for i in NAMES.size():
		if SLOT_OF[i] == slot:
			out.append(i)
	return out
