class_name BossParts
extends RefCounted

## EL CATÁLOGO DE PIEZAS DE LOS JEFES (17/11/2026): piernas, torsos, brazos y cabezas que se combinan. El usuario:
## «empezar a hacer un sistema modular de mecas… 2 o 3 modelos de piernas, de brazos, de torso y de cabeza… pensar en
## las mecas no como estéticas, sino simplemente como superficies que soportan o no soportan ciertos tipos de
## attachments… yo después en un futuro puedo agarrar módulos y empezar a modelarlos a mano».
## Cada pieza es UN DATO y UN DIBUJO DE ARCILLA provisorio (`draw_*`), en medidas de maqueta (un jefe de unos 30 m; la
## escala de todos, BossSettings). Cambiar el dibujo por un modelo no toca el dato.
## UNA PIEZA NO DICE QUÉ ES («tiene un horno», «tiene una mano»): dice QUÉ OFRECE, por nombre libre (el usuario: «no
## está el concepto de que existe un horno… yo decido desde qué punto sale algo»):
##   · sus PUNTOS (`points`: de dónde puede salir algo: «pecho», «punta», «cabeza»): en un modelo, los que se marquen;
##   · sus ZONAS DE GOLPE (`zones`: lo que puede pegar: «brazo», «punta», «cuerpo»);
##   · y lo físico (`gives`: «suelo», si pisa).
## Además, las piernas dicen cómo se mueven (`move`: orugas, patas, vuelo) y a qué altura dejan la cadera (`hip`); el
## torso, cuántos hombros tiene y de qué tamaño (`shoulders`, `shoulder_size`: 1 chico, 2 medio, 3 grande); el brazo,
## qué tamaño de hombro pide (`size`).
## QUÉ ENCAJA (BossRecipe.problems): sólo lo que es de lugar: un brazo entra en un hombro de su tamaño o más grande.

enum Kind { LEGS, TORSO, ARM, HEAD }
const KIND_NAMES := ["piernas", "torso", "brazos", "cabeza"]

const LEGS := {
	"orugas": {"title": "orugas", "move": "orugas", "hip": 7.0, "gives": ["suelo"], "zones": ["cuerpo"], "points": []},
	"bipedo": {"title": "dos patas", "move": "patas", "hip": 13.0, "gives": ["suelo"], "zones": ["cuerpo"], "points": [],
		"walk": WALK_TWO},
	"cuatro": {"title": "cuatro patas", "move": "patas", "hip": 9.0, "gives": ["suelo"], "zones": ["cuerpo"], "points": [],
		"walk": WALK_FOUR},
	"flotante": {"title": "flotante", "move": "vuelo", "hip": 10.0, "gives": [], "zones": ["cuerpo"], "points": ["abajo"]},
}
## CÓMO CAMINAN LAS PATAS (BossLegs, 18/11/2026): por pata, de adelante para atrás y de a pares (izquierda, derecha),
## la cadera (en los ejes de la cintura, que va a la altura `hip`), dónde se para su pie quieta (en el piso, debajo del
## medio) y hacia dónde dobla la rodilla; el largo del muslo y de la canilla, el grueso, el largo de un ciclo de la
## marcha (dos pasos) y lo que sube el pie. Adelante es −Z.
const WALK_TWO := {
	"hips": [Vector3(-4.5, -1.5, 0.0), Vector3(4.5, -1.5, 0.0)],
	"feet": [Vector3(-4.5, 0.0, 0.0), Vector3(4.5, 0.0, 0.0)],
	"bends": [Vector3(-0.15, 0.0, -1.0), Vector3(0.15, 0.0, -1.0)],
	"thigh": 6.6, "shin": 6.6, "thick": 3.0, "stride": 14.0, "lift": 2.5,
}
const WALK_FOUR := {
	"hips": [Vector3(-6.0, -1.0, -5.0), Vector3(6.0, -1.0, -5.0), Vector3(-6.0, -1.0, 5.0), Vector3(6.0, -1.0, 5.0)],
	"feet": [Vector3(-11.0, 0.0, -10.0), Vector3(11.0, 0.0, -10.0), Vector3(-11.0, 0.0, 10.0), Vector3(11.0, 0.0, 10.0)],
	"bends": [Vector3(-1.0, 1.4, -0.4), Vector3(1.0, 1.4, -0.4), Vector3(-1.0, 1.4, 0.4), Vector3(1.0, 1.4, 0.4)],
	"thigh": 8.0, "shin": 10.0, "thick": 2.4, "stride": 12.0, "lift": 2.5,
}
const TORSOS := {
	"ancho": {"title": "ancho", "size": Vector3(22, 13, 13), "shoulders": 2, "shoulder_size": 3,
		"points": ["pecho", "espalda"], "zones": ["torso"]},
	"angosto": {"title": "angosto", "size": Vector3(12, 14, 9), "shoulders": 2, "shoulder_size": 2,
		"points": ["pecho"], "zones": ["torso"]},
	"cuatro": {"title": "de cuatro brazos", "size": Vector3(16, 18, 11), "shoulders": 4,
		"shoulder_size": 2, "points": ["pecho", "espalda"], "zones": ["torso"]},
}
const ARMS := {
	"puno": {"title": "puño", "size": 3, "points": ["punta"], "zones": ["brazo", "punta"]},
	"pinza": {"title": "pinza", "size": 2, "points": ["punta"], "zones": ["brazo", "punta"]},
	"canon": {"title": "cañón", "size": 2, "points": ["punta"], "zones": ["brazo"]},
	"escudo": {"title": "escudo", "size": 3, "points": ["punta"], "zones": ["brazo", "punta"]},
}
const HEADS := {
	"visor": {"title": "visor", "points": ["cabeza"], "zones": []},
	"antena": {"title": "antena", "points": ["cabeza"], "zones": []},
	"ninguna": {"title": "sin cabeza", "points": [], "zones": []},
}
const SIZE_NAMES := ["", "chico", "medio", "grande"]

const BODY := Color(0.36, 0.42, 0.5)
const TRIM := Color(0.22, 0.25, 0.3)
const GLOW := Color(1.0, 0.5, 0.12)


## El catálogo de `kind`.
static func of(kind: Kind) -> Dictionary:
	return [LEGS, TORSOS, ARMS, HEADS][kind]


## ── LOS DIBUJOS DE ARCILLA (provisorios) ─────────────────────────────────────────────────────────────────────────

## LAS PIERNAS, paradas en el piso de `at`, con la cadera arriba a su `hip`. Las que caminan (`walk`) dibujan acá sólo
## la cadera: sus patas las arma BossLegs.
static func draw_legs(at: Node3D, id: String) -> void:
	var hip: float = LEGS[id]["hip"]
	match id:
		"orugas":
			for side: float in [-1.0, 1.0]:
				Clay.box(at, Vector3(5.0, 5.5, 18.0), Vector3(side * 9.5, 2.75, 0.0), Clay.DARK)
			Clay.box(at, Vector3(15.0, 3.5, 12.5), Vector3(0.0, 4.5, 0.0), TRIM)
			Clay.cylinder(at, 5.0, hip - 6.0, Vector3(0.0, 6.0 + (hip - 6.0) * 0.5, 0.0), TRIM.darkened(0.2))
		"bipedo":
			Clay.box(at, Vector3(12.0, 3.0, 6.0), Vector3(0.0, hip - 1.5, 0.0), TRIM)
		"cuatro":
			Clay.cylinder(at, 7.5, 3.5, Vector3(0.0, hip - 1.75, 0.0), TRIM.darkened(0.2))
		"flotante":
			Clay.cylinder(at, 8.5, 3.0, Vector3(0.0, hip - 1.5, 0.0), TRIM)
			Clay.cylinder(at, 6.0, 3.0, Vector3(0.0, hip - 4.5, 0.0), BODY)
			for jet in 3:
				var around := Vector3(sin(jet * TAU / 3.0), 0.0, cos(jet * TAU / 3.0)) * 6.0
				Clay.cylinder(at, 1.8, 3.0, around + Vector3.UP * (hip - 6.5), Clay.DARK)
				_lit(Clay.cylinder(at, 1.3, 0.6, around + Vector3.UP * (hip - 8.2), GLOW))


## EL TORSO, parado sobre la cadera (el origen de `at`). Devuelve dónde van sus hombros (cada uno: el punto y el lado,
## −1 izquierda o 1 derecha) y dónde va la cabeza.
static func draw_torso(at: Node3D, id: String) -> Dictionary:
	var size: Vector3 = TORSOS[id]["size"]
	Clay.box(at, Vector3(size.x * 0.6, 3.0, size.z * 0.8), Vector3(0.0, 1.5, 0.0), TRIM)
	Clay.box(at, size, Vector3(0.0, 3.0 + size.y * 0.5, 0.0), BODY)
	var top := 3.0 + size.y
	match id:
		"ancho":
			Clay.box(at, Vector3(10.0, 6.0, 0.6), Vector3(0.0, 3.0 + size.y * 0.35, -size.z * 0.5 - 0.2), Clay.DARK)
			_lit(Clay.box(at, Vector3(8.5, 4.5, 0.4), Vector3(0.0, 3.0 + size.y * 0.35, -size.z * 0.5 - 0.5), GLOW))
		"cuatro":
			_lit(Clay.sphere(at, 2.6, Vector3(0.0, 3.0 + size.y * 0.55, -size.z * 0.5), GLOW))
	var shoulders := []
	var rows: Array = [0.8] if int(TORSOS[id]["shoulders"]) == 2 else [0.82, 0.4]
	for row: float in rows:
		for side: float in [-1.0, 1.0]:
			shoulders.append([Vector3(side * (size.x * 0.5 + 2.0), 3.0 + size.y * row, 0.0), side])
	return {"shoulders": shoulders, "head": Vector3(0.0, top, -size.z * 0.15)}


## UN BRAZO, colgando de su hombro (el origen de `at`), del lado `side`. Devuelve dónde queda su punta (local).
static func draw_arm(at: Node3D, id: String, side: float) -> Vector3:
	var big: float = 1.0 + 0.25 * (int(ARMS[id]["size"]) - 2)
	Clay.box(at, Vector3(5.0, 5.0, 5.0) * big, Vector3(side * 0.5, 0.5, 0.0), TRIM)
	Clay.box(at, Vector3(2.8, 8.0, 2.8) * big, Vector3(side * 1.0, -5.0 * big, -0.8), BODY)
	var elbow := Vector3(side * 1.0, -9.5 * big, -1.6)
	var tip := elbow + Vector3(0.0, -7.5 * big, -3.0)
	match id:
		"puno":
			Clay.box(at, Vector3(3.4, 8.0, 3.4) * big, (elbow + tip) * 0.5, BODY)
			Clay.box(at, Vector3.ONE * 4.8 * big, tip, TRIM)
		"pinza":
			Clay.box(at, Vector3(2.4, 8.0, 2.4) * big, (elbow + tip) * 0.5, BODY)
			for jaw: float in [-1.0, 1.0]:
				Clay.box(at, Vector3(0.9, 4.5, 2.2) * big, tip + Vector3(jaw * 1.6, -1.2, 0.0), Clay.DARK)
		"canon":
			tip = elbow + Vector3(0.0, -2.0, -10.0 * big)
			Clay.cylinder(at, 1.9 * big, 9.0 * big, (elbow + tip) * 0.5, Clay.DARK, Vector3(75.0, 0.0, 0.0))
			_lit(Clay.cylinder(at, 1.3 * big, 0.6, tip, GLOW, Vector3(75.0, 0.0, 0.0)))
		"escudo":
			Clay.box(at, Vector3(2.6, 6.0, 2.6) * big, (elbow + tip) * 0.5, BODY)
			tip = elbow + Vector3(side * 1.5, -3.0, -4.5)
			Clay.box(at, Vector3(11.0, 15.0, 1.4) * big, tip, TRIM.lightened(0.15))
	return tip


## LA CABEZA, sobre el torso (el origen de `at`).
static func draw_head(at: Node3D, id: String) -> void:
	match id:
		"visor":
			Clay.box(at, Vector3(5.0, 3.0, 4.0), Vector3(0.0, 1.5, 0.0), TRIM)
			_lit(Clay.box(at, Vector3(4.0, 0.8, 0.3), Vector3(0.0, 1.7, -2.05), Color(0.45, 0.95, 1.0)))
		"antena":
			Clay.cylinder(at, 1.6, 2.4, Vector3(0.0, 1.2, 0.0), TRIM)
			Clay.cylinder(at, 0.25, 6.0, Vector3(0.9, 5.2, 0.0), Clay.DARK)
			_lit(Clay.sphere(at, 0.8, Vector3(0.0, 2.6, -0.6), Color(1.0, 0.2, 0.15)))


static func _lit(part: MeshInstance3D) -> void:
	var paint := StandardMaterial3D.new()
	var mesh_paint := part.get_active_material(0) as StandardMaterial3D
	paint.albedo_color = mesh_paint.albedo_color if mesh_paint != null else GLOW
	paint.emission_enabled = true
	paint.emission = paint.albedo_color
	part.material_override = paint
