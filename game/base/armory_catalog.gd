class_name ArmoryCatalog
extends RefCounted

## LO QUE VENDE LA ARMERÍA EN LA PRIMERA BUILD (ver docs/conceptual/progresion.md y armamento.md; la lista la eligió el
## usuario, 15/11/2026):
##   · EL PUÑO, la base de cada brazo: el común (lo trae la meca) y el pesado, más grande y con pinches (conos) en los
##     nudillos. Son dos variantes del mismo puño. *El liviano queda para cuando se sepa cómo se ve.*
##   · LA HERRAMIENTA que se le agrega al puño: el taladro, el cañón de energía y la sierra. Un ejemplar de cada una.
##   · LA ESPALDA: la ametralladora, el lanzamisiles y el cañón pesado. Un ejemplar de cada uno.
##   · LAS PLACAS del acorazado, de brazo y de pierna, que se reponen cuantas veces haga falta. El torso, por ahora, sin
##     placa (el usuario, 15/11/2026).
## Los precios y los textos son de prueba.

enum Kind { FIST, ARM_TOOL, BACK, PLATE_ARM, PLATE_LEG }

const KIND_NAMES := {
	Kind.FIST: "puño", Kind.ARM_TOOL: "herramienta de brazo", Kind.BACK: "arma de espalda",
	Kind.PLATE_ARM: "placa de brazo", Kind.PLATE_LEG: "placa de pierna",
}

## Los colores de cada clase, para que en la grilla se lea qué va dónde.
const KIND_COLORS := {
	Kind.FIST: Color(0.72, 0.62, 0.42), Kind.ARM_TOOL: Color(0.78, 0.52, 0.3), Kind.BACK: Color(0.45, 0.58, 0.72),
	Kind.PLATE_ARM: Color(0.6, 0.62, 0.6), Kind.PLATE_LEG: Color(0.6, 0.62, 0.6),
}

const ITEMS := [
	{"id": "fist", "name": "Puño común", "kind": Kind.FIST, "price": 100, "unique": false,
		"text": "El puño de la meca: pega, empuja y agarra. Cada brazo trae uno.", "stats": "equilibrado"},
	{"id": "heavy_fist", "name": "Puño pesado", "kind": Kind.FIST, "price": 400, "unique": false,
		"text": "Más grande, con pinches en los nudillos. Pega más fuerte, pero llega más lento.",
		"stats": "más daño · más lento"},
	{"id": "drill", "name": "Taladro", "kind": Kind.ARM_TOOL, "price": 450, "unique": true,
		"text": "Tarda en entrar, pero atraviesa la guardia y el acorazado.", "stats": "atraviesa placas · corto"},
	{"id": "energy_cannon", "name": "Cañón de energía", "kind": Kind.ARM_TOOL, "price": 600, "unique": true,
		"text": "Dispara a distancia con la energía de la meca.", "stats": "a distancia · gasta energía"},
	{"id": "circular_saw", "name": "Sierra circular", "kind": Kind.ARM_TOOL, "price": 500, "unique": true,
		"text": "Corta seguido mientras está apoyada.", "stats": "daño continuo · rompe placas"},
	{"id": "machine_gun", "name": "Ametralladora", "kind": Kind.BACK, "price": 500, "unique": true,
		"text": "Muchos tiros flojos, seguidos, desde la espalda.", "stats": "cadencia alta · munición"},
	{"id": "missile_launcher", "name": "Lanzamisiles", "kind": Kind.BACK, "price": 700, "unique": true,
		"text": "Un misil que se va llevando con la mira.", "stats": "guiado · munición"},
	{"id": "heavy_cannon", "name": "Cañón pesado", "kind": Kind.BACK, "price": 900, "unique": true,
		"text": "De largo alcance y recto; el retroceso empuja a la propia meca.", "stats": "daño alto · retroceso"},
	{"id": "plate_arm", "name": "Placa de brazo", "kind": Kind.PLATE_ARM, "price": 120, "unique": false,
		"text": "Cubre un brazo. Sirve en cualquiera de los dos.", "stats": "acorazado de un brazo"},
	{"id": "plate_leg", "name": "Placa de pierna", "kind": Kind.PLATE_LEG, "price": 150, "unique": false,
		"text": "Cubre una pierna. Sirve en cualquiera de las dos.", "stats": "acorazado de una pierna"},
]


static func item(id: String) -> Dictionary:
	for entry: Dictionary in ITEMS:
		if entry.id == id:
			return entry
	return {}


## La placa que va en un hueco de placa.
static func plate_for(kind: int) -> String:
	for entry: Dictionary in ITEMS:
		if int(entry.kind) == kind and str(entry.id).begins_with("plate_"):
			return entry.id
	return ""
