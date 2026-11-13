class_name BossDesign
extends RefCounted

## CÓMO ESTÁ ARMADA UNA MECA ENEMIGA (13/11/2026) — TRABAJO EN CURSO, para maquetar en bloques. A propósito SUELTO, no un
## catálogo rígido: los jefes se arman de a uno, a mano (el usuario: «prefiero hacer un sistema más o menos e ir haciendo
## unos bosses de uno a uno… no me quiero limitar a que un brazo se reemplace por algo… una ametralladora puede ir en el
## antebrazo y mantener la mano»).
##
## No tiene cabinas adentro (ni puertas, ni controles, ni ascensor): EL TORSO ES LIBRE, y los brazos, las patas y lo del
## pecho SE ENCAJAN CON UN OFFSET cada uno (el usuario: «se encajan solamente con una variable que es un offset que las
## pone bien»). Se mueve igual que la meca propia (BalanceBody).
##   · el TORSO: una caja o redondo, de `torso_size`.
##   · la PELVIS: su alto (0, sin pelvis).
##   · las PATAS: cuántas y de qué clase (`Legs`), corridas `legs_offset`.
##   · los BRAZOS (`arms`, cuantos haya): cada uno con su `offset`, su largo, su MANO (`Hand`: puño, sierra, taladro o
##     nada) y, aparte, lo que lleve MONTADO EN EL ANTEBRAZO (`Gear`: ametralladora, cohetes, misiles guiados, bombas).
##   · lo del PECHO (`Chest`), corrido `chest_offset`.
##   · los COLORES (BossPalette).

enum Torso { BOX, ROUND }
## Dos piernas desde la pelvis, cuatro patas, seis que salen de los costados (araña), orugas o ruedas.
enum Legs { BIPED, QUAD, SPIDER, TREADS, WHEELS }
## La mano: nada, puño (pega; agarrar cosas, después), sierra o taladro (dañan si te quedás cerca).
enum Hand { NONE, FIST, SAW, DRILL }
## Lo montado en el antebrazo: nada, ametralladora, cohetes (no guiados), misiles guiados o bombas.
enum Gear { NONE, GUN, ROCKETS, GUIDED, BOMBS }
## Lo del pecho: nada, un cañón que sube y tiene que apuntarte para tirar, o un ojo que barre el piso con un láser.
enum Chest { NONE, CANNON, LASER_EYE }

const HAND_NAMES := ["sin mano", "puño", "sierra", "taladro"]
const GEAR_NAMES := ["nada", "ametralladora", "cohetes", "misiles guiados", "bombas"]
const CHEST_NAMES := ["nada", "cañón", "ojo láser"]

var title := "meca enemiga"
var torso := Torso.BOX
var torso_size := Vector3(10.0, 8.0, 9.0)
var pelvis := 1.8
var legs := Legs.BIPED
## Corre las caderas (x: más abiertas, a cada lado; y: arriba; z: atrás).
var legs_offset := Vector3.ZERO
## Cada brazo (ver `arm`).
var arms: Array[Dictionary] = []
var chest := Chest.NONE
var chest_offset := Vector3.ZERO
var palette := 0


## UN BRAZO: de qué lado (−1 izquierdo, 1 derecho), su mano, lo de su antebrazo, cuánto se corre el hombro de su lugar
## (x afuera, en espejo; y arriba; z atrás) y su largo (en partes del de siempre: el alto del torso).
static func arm(side: float, hand: Hand, gear := Gear.NONE, offset := Vector3.ZERO, length := 1.0) -> Dictionary:
	return {"side": side, "hand": hand, "gear": gear, "offset": offset, "length": length}


func colors() -> Dictionary:
	return BossPalette.of(palette)


## LA MASA: la de la meca propia, por su volumen.
func mass() -> float:
	var own := CabinGrid.box()
	return Mech.MASS * clampf((torso_size.x * torso_size.y * torso_size.z) / (own.x * own.y * own.z), 0.5, 3.0)


## Si algo suyo pega de cerca (y entonces se acerca).
func melee() -> bool:
	for one in arms:
		if int(one["hand"]) != Hand.NONE:
			return true
	return false
