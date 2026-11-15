class_name ArmoryCatalog
extends RefCounted

## LO QUE VENDE LA ARMERÍA (ver docs/conceptual/progresion.md y armamento.md): un ejemplar de cada herramienta de brazo y
## de cada arma de espalda, y las placas del acorazado, que se reponen cuantas veces haga falta. Los precios y los textos
## son de prueba.

enum Kind { ARM_TOOL, BACK, PLATE_HULL, PLATE_ARM, PLATE_LEG }

const KIND_NAMES := {
	Kind.ARM_TOOL: "herramienta de brazo", Kind.BACK: "arma de espalda", Kind.PLATE_HULL: "placa del casco",
	Kind.PLATE_ARM: "placa de brazo", Kind.PLATE_LEG: "placa de pierna",
}

## Los colores de cada clase, para que en la grilla se lea qué va dónde.
const KIND_COLORS := {
	Kind.ARM_TOOL: Color(0.78, 0.52, 0.3), Kind.BACK: Color(0.45, 0.58, 0.72), Kind.PLATE_HULL: Color(0.6, 0.62, 0.6),
	Kind.PLATE_ARM: Color(0.6, 0.62, 0.6), Kind.PLATE_LEG: Color(0.6, 0.62, 0.6),
}

const ITEMS := [
	{"id": "spring_fist", "name": "Puño de resorte", "kind": Kind.ARM_TOOL, "price": 300, "unique": true,
		"text": "El puño sale disparado con un resorte: pega más lejos.", "stats": "alcance +60 %"},
	{"id": "rocket_fist", "name": "Puño cohete", "kind": Kind.ARM_TOOL, "price": 350, "unique": true,
		"text": "Un cohete en la muñeca: la piña llega antes.", "stats": "velocidad del golpe +40 %"},
	{"id": "shock_fist", "name": "Puño eléctrico", "kind": Kind.ARM_TOOL, "price": 400, "unique": true,
		"text": "Cada piña descarga: aturde un momento los sistemas del jefe.", "stats": "aturde 0,6 s"},
	{"id": "mace", "name": "Maza", "kind": Kind.ARM_TOOL, "price": 300, "unique": true,
		"text": "Reemplaza a la mano. Lenta y pesada: desequilibra.", "stats": "daño alto · lenta"},
	{"id": "circular_saw", "name": "Sierra circular", "kind": Kind.ARM_TOOL, "price": 450, "unique": true,
		"text": "Corta placas mientras se la apoya.", "stats": "daño continuo · rompe placas"},
	{"id": "chainsaw", "name": "Motosierra", "kind": Kind.ARM_TOOL, "price": 450, "unique": true,
		"text": "Larga: corta lo que tenga delante.", "stats": "daño continuo · alcance medio"},
	{"id": "drill", "name": "Taladro", "kind": Kind.ARM_TOOL, "price": 400, "unique": true,
		"text": "Perfora en un punto: atraviesa el acorazado.", "stats": "ignora placas · corto"},
	{"id": "blade", "name": "Hoja", "kind": Kind.ARM_TOOL, "price": 350, "unique": true,
		"text": "Una hoja larga, de tajos amplios.", "stats": "tajo amplio"},
	{"id": "energy_cannon", "name": "Cañón de energía", "kind": Kind.ARM_TOOL, "price": 600, "unique": true,
		"text": "Dispara a distancia con la energía de la meca.", "stats": "a distancia · gasta energía"},
	{"id": "flamethrower", "name": "Lanzallamas", "kind": Kind.ARM_TOOL, "price": 550, "unique": true,
		"text": "Un chorro de fuego corto, en el brazo.", "stats": "en cono · gasta energía"},
	{"id": "machine_gun", "name": "Ametralladora", "kind": Kind.BACK, "price": 500, "unique": true,
		"text": "Tiros seguidos desde la espalda.", "stats": "cadencia alta · munición"},
	{"id": "missile_launcher", "name": "Lanzamisiles", "kind": Kind.BACK, "price": 700, "unique": true,
		"text": "Misiles de a uno, que se guían con la mira.", "stats": "guiados · munición"},
	{"id": "mega_missile", "name": "Mega misil", "kind": Kind.BACK, "price": 900, "unique": true,
		"text": "Uno solo, enorme: tira a la meca para atrás al salir.", "stats": "daño enorme · retroceso"},
	{"id": "plate_hull", "name": "Placa del casco", "kind": Kind.PLATE_HULL, "price": 200, "unique": false,
		"text": "Cubre la caja. Rota, no vuelve sola: se repone acá.", "stats": "acorazado del casco"},
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
