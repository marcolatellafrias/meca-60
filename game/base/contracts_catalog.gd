class_name ContractsCatalog
extends RefCounted

## LOS CONTRATOS DE LA CONSOLA (ver docs/conceptual/contratos.md): qué jefe ir a matar. HOY SON SÓLO LOS CUATRO EXPERIMENTOS
## (22/11/2026; los que nombraban jefes sin hacer se sacaron: todos armaban al Luchador). Con `experiment`, firmarlo cambia
## las perillas de los paneles por las de esa prueba (Experiments). En el juego final van a ser contratos de verdad.

const CONTRACTS := [
	{"boss": "Prueba: esquivar por posición", "stars": 1, "pay": 0, "affixes": ["experimento"],
		"experiment": "posicion",
		"text": "El peleador con zonas y cosas lanzadas, marcadas en el piso. El dash no es intocable."},
	{"boss": "Prueba: esquivar por tiempo", "stars": 1, "pay": 0, "affixes": ["experimento"],
		"experiment": "timing",
		"text": "El peleador con la embestida y el trompo, sin marcas. El dash es corto e intocable."},
	{"boss": "Prueba: posición y tiempo", "stars": 2, "pay": 0, "affixes": ["experimento"],
		"experiment": "mixto",
		"text": "El peleador con todos sus ataques. La meca tiene dash intocable (Shift) y sobrevuelo (Ctrl)."},
	{"boss": "Prueba: lluvia de bolitas", "stars": 2, "pay": 0, "affixes": ["experimento"],
		"experiment": "bolitas",
		"text": "Bolitas comunes, rápidas, lentas, que rebotan, que se parten y eléctricas que aturden."},
]


## El experimento de un contrato ("" si no es una prueba, o si no hay contrato).
static func experiment_of(index: int) -> String:
	if index < 0 or index >= CONTRACTS.size():
		return ""
	return str(CONTRACTS[index].get("experiment", ""))


static func stars_text(stars: int) -> String:
	return "●".repeat(stars) + "○".repeat(5 - stars)
