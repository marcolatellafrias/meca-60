class_name SupplyKinds
extends RefCounted

## QUÉ PUEDE TRAER UN PAQUETE (22/11/2026, elegido por el usuario; ver docs/conceptual/recursos.md). La munición especial dura
## una carga: al vaciarse, el arma vuelve sola a la común.
##   · BALAS: comunes; INCENDIARIAS (prenden al blanco); ELÉCTRICAS (lo cargan hasta aturdirlo); PERFORANTES (menos balas, más
##     daño y atraviesan).
##   · MISILES: comunes; REBOTADOR (explota y salta a explotar de nuevo); RACIMO (suelta cuatro chicos); MINA (espera en el piso).
##   · KIT DE REPARACIÓN: le devuelve vida a la meca.

enum Kind { BULLETS, INCENDIARY, ELECTRIC, PIERCING, MISSILES, BOUNCER, CLUSTER, MINE, REPAIR }

const INFO := {
	Kind.BULLETS: {"name": "BALAS COMUNES", "color": Color(0.38, 0.39, 0.32), "tag": Color(0.45, 0.46, 0.48)},
	Kind.INCENDIARY: {"name": "BALAS INCENDIARIAS", "color": Color(0.62, 0.27, 0.14), "tag": Color(0.95, 0.42, 0.12)},
	Kind.ELECTRIC: {"name": "BALAS ELÉCTRICAS", "color": Color(0.24, 0.42, 0.56), "tag": Color(0.3, 0.75, 1.0)},
	Kind.PIERCING: {"name": "BALAS PERFORANTES", "color": Color(0.3, 0.31, 0.36), "tag": Color(0.72, 0.74, 0.8)},
	Kind.MISSILES: {"name": "MISILES COMUNES", "color": Color(0.47, 0.4, 0.27), "tag": Color(0.45, 0.46, 0.48)},
	Kind.BOUNCER: {"name": "MISILES REBOTADORES", "color": Color(0.3, 0.48, 0.27), "tag": Color(0.35, 0.85, 0.4)},
	Kind.CLUSTER: {"name": "MISILES DE RACIMO", "color": Color(0.58, 0.42, 0.14), "tag": Color(1.0, 0.68, 0.15)},
	Kind.MINE: {"name": "MISILES MINA", "color": Color(0.4, 0.24, 0.42), "tag": Color(0.75, 0.42, 0.95)},
	Kind.REPAIR: {"name": "KIT DE REPARACIÓN", "color": Color(0.78, 0.76, 0.7), "tag": Color(0.8, 0.2, 0.17)},
}
## Lo que sale del tubo de munición, en el orden de su botón.
const AMMO: Array[int] = [Kind.BULLETS, Kind.INCENDIARY, Kind.ELECTRIC, Kind.PIERCING, Kind.MISSILES, Kind.BOUNCER,
	Kind.CLUSTER, Kind.MINE]
## Cuánta vida devuelve un kit.
const REPAIR_AMOUNT := 40.0


static func title(kind: int) -> String:
	return INFO[kind]["name"]


static func body_color(kind: int) -> Color:
	return INFO[kind]["color"]


static func tag_color(kind: int) -> Color:
	return INFO[kind]["tag"]


static func is_bullets(kind: int) -> bool:
	return kind >= Kind.BULLETS and kind <= Kind.PIERCING


static func is_missiles(kind: int) -> bool:
	return kind >= Kind.MISSILES and kind <= Kind.MINE
