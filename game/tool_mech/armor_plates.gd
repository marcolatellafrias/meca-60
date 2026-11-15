class_name ArmorPlates
extends RefCounted

## LAS PLACAS DE BLINDAJE de la Meca de tres (el usuario, 15/11/2026: «paneles para brazos y piernas de armadura»; «la
## placa de blindaje me refiero»): sólo se ven. Una funda de chapa más oscura alrededor del medio de cada pieza de los
## brazos y las piernas, con una franja en cada punta.

const PLATE := Color(0.4, 0.42, 0.46)
const BAND := Color(0.28, 0.29, 0.32)


## LA FUNDA de una pieza (`limb`: su largo sobre Z, centrada; ver Clay.limb) de grosor `thick` y largo `length`.
static func sleeve(limb: Node3D, thick: float, length: float) -> void:
	var cover := length * 0.62
	var side := thick * 1.18
	Clay.box(limb, Vector3(side, side, cover), Vector3.ZERO, PLATE)
	for end: float in [-1.0, 1.0]:
		Clay.box(limb, Vector3(side + 0.08, side + 0.08, 0.12), Vector3(0.0, 0.0, end * cover * 0.5), BAND)


## LAS DE LAS PIERNAS de `body`: el muslo y la canilla de cada una (ver MechLeg).
static func dress_legs(body: Node) -> void:
	for found in body.find_children("*", "MechLeg", true, false):
		var leg := found as MechLeg
		sleeve(leg._thigh, leg.measures.LEG_THICKNESS, leg.measures.THIGH)
		sleeve(leg._shin, leg.measures.LEG_THICKNESS, leg.measures.SHIN)
