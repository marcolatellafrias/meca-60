class_name BossPalette
extends RefCounted

## LOS COLORES DE UNA MECA ENEMIGA (13/11/2026): cuatro, uno por clase de parte. El usuario: «que cada boss tenga una
## paleta de colores distinta… 3 o 4, 2 creo que es muy poco, porque por un lado están detalles como las
## articulaciones, a diferencia de los tubos o la cabina, pero también están las toberas y otros detalles más».
##   · `hull`    la cabina (el torso) y la pelvis.
##   · `limb`    los tubos: brazos y piernas, las orugas.
##   · `joint`   las articulaciones, los pies, las ruedas.
##   · `accent`  los detalles: el ojo, las puntas de las armas, las franjas.
## Apagados, de tierra (nada chillón): como todo lo de la meca.

const PALETTES := [
	{"name": "oliva", "hull": Color(0.42, 0.45, 0.30), "limb": Color(0.33, 0.35, 0.27), "joint": Color(0.20, 0.21, 0.19), "accent": Color(0.85, 0.62, 0.18)},
	{"name": "óxido", "hull": Color(0.55, 0.30, 0.22), "limb": Color(0.40, 0.38, 0.36), "joint": Color(0.22, 0.20, 0.19), "accent": Color(0.92, 0.82, 0.55)},
	{"name": "hueso", "hull": Color(0.80, 0.76, 0.66), "limb": Color(0.45, 0.46, 0.48), "joint": Color(0.25, 0.26, 0.28), "accent": Color(0.75, 0.20, 0.16)},
	{"name": "marino", "hull": Color(0.24, 0.31, 0.42), "limb": Color(0.50, 0.52, 0.55), "joint": Color(0.18, 0.19, 0.22), "accent": Color(0.95, 0.55, 0.15)},
	{"name": "ocre", "hull": Color(0.72, 0.56, 0.26), "limb": Color(0.30, 0.30, 0.31), "joint": Color(0.17, 0.17, 0.18), "accent": Color(0.25, 0.55, 0.62)},
	{"name": "pizarra", "hull": Color(0.36, 0.38, 0.40), "limb": Color(0.55, 0.56, 0.57), "joint": Color(0.22, 0.23, 0.25), "accent": Color(0.80, 0.25, 0.20)},
	{"name": "musgo", "hull": Color(0.30, 0.40, 0.33), "limb": Color(0.62, 0.58, 0.48), "joint": Color(0.21, 0.22, 0.20), "accent": Color(0.90, 0.80, 0.30)},
	{"name": "ladrillo", "hull": Color(0.62, 0.36, 0.30), "limb": Color(0.70, 0.66, 0.58), "joint": Color(0.26, 0.22, 0.21), "accent": Color(0.20, 0.35, 0.45)},
]


static func count() -> int:
	return PALETTES.size()


static func of(index: int) -> Dictionary:
	return PALETTES[posmod(index, PALETTES.size())]
