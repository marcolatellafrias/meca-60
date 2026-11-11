class_name Belts
extends RefCounted

## EL CINTURÓN: UNO SOLO, el de cuero con bolsitas. De la primera tanda —cuero, canana de herramientas y faja de
## tela— el dios del juego eligió éste y pidió que fuera el único (10/10/2026): un poco más grueso, y las bolsitas más
## cuadradas. Es una lista por si algún día hay más, pero hoy tiene uno.
##
## ── LOS CUATRO LUGARES SON DEL DISEÑO ───────────────────────────────────────────────────────────
## El cinturón no es un adorno: es donde el personaje lleva lo que compra (ver consumables.md, The belt) —CUATRO
## LUGARES, DOS ADELANTE Y DOS ATRÁS, uno de cada cosa—. Así que todos los cinturones tienen esos cuatro, a ±40° y
## ±140° del frente, y lo que cambia es cómo son: una bolsita, un portabotellas, un bolsillo. Mostrar ahí los envases
## de lo que lleva, que es lo que el diseño dice que se ve, viene después.
##
## (LAS PIEZAS —las bolsitas, la hebilla— y cómo se dibujaba se borraron el 07/11/2026 con la malla vieja del
## personaje; viven en la etiqueta de git `malla-personaje-archivada`. Quedan los nombres, el cuero de la banda y su
## lugar en el torso, que leen el aspecto, los trajes y la forma del torso.)

const NAMES: Array[String] = ["cuero con bolsitas", "cuero con bolsitas low poly"]
## Entre cuántos de la lista sortea la gente al azar (ver CharacterLook.drawn): sólo el de siempre. El low poly es del
## mameluco low poly (ver Suits.COVERALL_LOW).
const DRAWN_COUNT := 1

## Cuero negro, como el de los concept arts (12/10/2026); era marrón.
const LEATHER := Color(0.11, 0.10, 0.10)

## `band`: de qué fracción a qué fracción del alto del torso va, cuánto se despega de él y su color.
##
## La banda va del 8 al 20% del alto del torso (era del 10 al 17%: «un poco más grueso»).
const DEFS := [
	{"band": [0.08, 0.20, 0.045, LEATHER]},
	{"band": [0.08, 0.20, 0.045, LEATHER]},
]


## LA LÍNEA DEL CINTURÓN, en fracción del alto del torso: el medio de su banda.
static func line() -> float:
	var spec: Array = (DEFS[0] as Dictionary)["band"]
	return (float(spec[0]) + float(spec[1])) * 0.5
