class_name ContractsCatalog
extends RefCounted

## LOS CONTRATOS DE LA CONSOLA (ver docs/conceptual/contratos.md): qué jefe ir a matar. Más riesgo, más paga. Por ahora
## una lista a mano con los jefes que existen (el peleador y las maquetas); los afijos, de prueba.

const CONTRACTS := [
	{"boss": "El peleador", "stars": 1, "pay": 900, "affixes": [],
		"text": "Una meca humanoide que pelea a las piñas. Para aprender a moverse juntos."},
	{"boss": "Trípode faro", "stars": 2, "pay": 1400, "affixes": ["lento"],
		"text": "Alto y lento, en tres patas. El núcleo está arriba de la cabeza: hay que tirarse desde lo alto."},
	{"boss": "Cuadrúpedo bastión", "stars": 3, "pay": 2100, "affixes": ["acorazado"],
		"text": "Cuatro patas y un cañón. Después del cañonazo abre las compuertas."},
	{"boss": "Hexápodo plataforma", "stars": 4, "pay": 3000, "affixes": ["acorazado", "rápido"],
		"text": "Camina en seis patas; tras el pisotón deja ver lo de adentro."},
	{"boss": "El peleador, furioso", "stars": 5, "pay": 4200, "affixes": ["rápido", "regenera"],
		"text": "El mismo peleador, más rápido, y se arregla solo si no se lo apura."},
]


static func stars_text(stars: int) -> String:
	return "●".repeat(stars) + "○".repeat(5 - stars)
