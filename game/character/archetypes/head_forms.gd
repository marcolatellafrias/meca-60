class_name HeadForms
extends Resource

## LAS FORMAS DE CABEZA del sistema nuevo (ver HeadForm): unas ranuras que el dios del juego esculpe en la fila «Formas
## de cabeza» del sandbox, guardadas ENTERAS en `res://` (como los aspectos, ver CharacterLooks): el defecto del código
## es sólo de dónde arranca una ranura que nadie tocó.
##
## ⚠ El archivo lo escribe el sandbox cuando él guarda: es suyo, no se commitea a mano.

static var path := "res://game/character/archetypes/head_forms.tres"

## CUÁNTAS RANURAS hay: una por forma elegida (ver CHOSEN). Una parcela por ranura.
const SLOTS := 10

## Ranura (int) → HeadForm.
@export var by_slot: Dictionary = {}
## LA CARA APLANADA DE TODAS LAS CABEZAS (ver HeadForm.face_flat): una sola, para todos los personajes, y no una por
## forma (lo pidió el dios del juego, 16/10/2026). Se mueve con el F1 de la fila «Formas de cabeza» o con U y J, se ve
## en el momento y se guarda con «Guardar».
@export_range(0.0, 1.0, 0.05) var face_flat := 0.0

## La capa de prueba: lo que el panel está tocando y todavía no se guardó (ranura → HeadForm).
static var preview: Dictionary = {}

static var _loaded: HeadForms = null
static var _tried := false


static func table() -> HeadForms:
	if not _tried:
		_tried = true
		if ResourceLoader.exists(path):
			_loaded = ResourceLoader.load(path, "HeadForms", ResourceLoader.CACHE_MODE_IGNORE) as HeadForms
	if _loaded == null:
		_loaded = HeadForms.new()
	return _loaded


## LA FORMA DE UNA RANURA: la de prueba, si no la guardada, si no la del código. Siempre una copia.
static func form_for(slot: int) -> HeadForm:
	var found: HeadForm = preview.get(slot) as HeadForm
	if found == null:
		found = table().by_slot.get(slot) as HeadForm
	var out := found.copy() if found != null else code_form(slot)
	out.ensure_cuts()
	return out


## La cara aplanada de todas (ver `face_flat`), como está ahora: se mueve en vivo y la escribe «Guardar».
static func face_flat_all() -> float:
	return table().face_flat


static func is_saved(slot: int) -> bool:
	return table().by_slot.has(slot)


static func store(slot: int, form: HeadForm) -> bool:
	var all := table()
	all.by_slot[slot] = form.copy()
	preview.erase(slot)
	return ResourceSaver.save(all, path) == OK


static func forget(slot: int) -> bool:
	var all := table()
	all.by_slot.erase(slot)
	preview.erase(slot)
	return ResourceSaver.save(all, path) == OK


## LAS ELEGIDAS, como ranuras de arranque: lo que el dios del juego eligió de las variaciones (13/10/2026) —del huevo
## la 3, la 4 y la 7 (la 6 con la base hacia adelante se probó y se fue); de la alargada la 2; de la redonda la 1 y la 2; de las nuevas el
## pepino, la pelota y el tubo; de los pómulos alineados, con el frente plano, la 1, la 4 y la 8; de los
## más largos, la 1, la 2, la 4 y la 6; la más redonda con el domo de abajo en 6 y en 4,5 cm, y esas dos con la tapa de
## arriba de 15 cm, y esas dos con el medio como la tapa de abajo; el huevo suave con la tapa de abajo de 11 cm;
## de las peras, la 6 de las que se angostan de a poco y la 3 de las de medio como abajo (la 7 y su
## variante de domo bajo se probaron y se fueron)—. Cada una es una
## receta de números (ver `from_spec`), en metros de una cabeza de verdad (unos 24 cm de alto).
##
## DE VEINTICINCO A DIEZ (16/10/2026): el dios del juego las miró en grupos por semejanza y se quedó con éstas —de los
## huevos, el del mentón adelante; de los pómulos alineados, más abajo, mentón largo, un poco más larga, y las dos
## largas de pómulos bajos y de mentón largo; de las redondas, las de abajo 6 y 4,5 cm y la de abajo 6 con arriba 15;
## de las peras, la recta—. Las ranuras se renumeraron del 1 al 10, en este orden.
const CHOSEN := [
	["huevo con mentón adelante", {"h": 0.10, "b": [0.13, 0.15, 0.012, 0.06],
		"t": [0.17, 0.19, 0.0, 0.08]}],
	["pómulos alineados, más abajo", {"h": 0.10, "b": [0.13, 0.15, 0.014, 0.05], "t": [0.17, 0.19, 0.0, 0.08],
		"plano": true, "cuts": [[1, 0.165, 0.18, 0.0]]}],
	["pómulos alineados, mentón largo", {"h": 0.10, "b": [0.13, 0.15, 0.014, 0.07], "t": [0.17, 0.19, 0.0, 0.08],
		"plano": true, "cuts": [[2, 0.168, 0.182, 0.0]]}],
	["pómulos alineados, un poco más larga", {"h": 0.13, "b": [0.13, 0.15, 0.014, 0.05], "t": [0.17, 0.19, 0.0, 0.08],
		"plano": true, "cuts": [[2, 0.168, 0.182, 0.0]]}],
	["pómulos alineados, larga, pómulos bajos", {"h": 0.16, "b": [0.13, 0.15, 0.014, 0.05],
		"t": [0.17, 0.19, 0.0, 0.08], "plano": true, "cuts": [[1, 0.166, 0.18, 0.0]]}],
	["pómulos alineados, larga, mentón largo", {"h": 0.15, "b": [0.13, 0.15, 0.014, 0.07],
		"t": [0.17, 0.19, 0.0, 0.08], "plano": true, "cuts": [[2, 0.168, 0.182, 0.0]]}],
	["redonda, abajo 6 cm", {"h": 0.07, "b": [0.155, 0.175, 0.0, 0.06], "t": [0.16, 0.18, 0.0, 0.09]}],
	["redonda, abajo 4,5 cm", {"h": 0.07, "b": [0.155, 0.175, 0.0, 0.045], "t": [0.16, 0.18, 0.0, 0.09]}],
	["redonda, abajo 6, arriba 15", {"h": 0.07, "b": [0.155, 0.175, 0.0, 0.06], "t": [0.15, 0.17, 0.0, 0.09]}],
	["pera recta abajo 17, corte al 62 %", {"h": 0.11, "b": [0.17, 0.178, 0.0, 0.05], "t": [0.145, 0.17, 0.0, 0.07],
		"cuts": [[4, 0.17, 0.178, 0.0]]}],
]


static func code_form(slot: int) -> HeadForm:
	var spec: Array = CHOSEN[clampi(slot, 0, CHOSEN.size() - 1)]
	return from_spec(spec[0], spec[1])


## UNA FORMA DE UNA RECETA DE NÚMEROS: `h` el alto del cilindro; `b` y `t` las tapas de abajo y de arriba como [ancho,
## fondo, adelante, domo]; `cuts` los cortes que mandan, cada uno [índice, ancho, fondo, adelante]. Los demás cortes
## quedan apagados, en su lugar de siempre. EL FONDO YA NO CUENTA: los anillos son círculos del ancho (ver HeadForm,
## 16/10/2026); queda en las recetas porque así se escribieron todas, las de acá y las de las capturas.
##
## `plano` prende el frente plano (ver HeadForm.flat_front) y `cara` es cuánto se aplana la cara (HeadForm.face_flat). «adelante» de un corte puede ser `"frente"`: el corte se corre lo justo para que SU FRENTE quede a plomo con el de la tapa de abajo
## —los pómulos alineados que pidió el dios del juego (13/10/2026)—, así de perfil no hay escalón y el corte sólo
## ensancha hacia los costados.
static func from_spec(new_name: String, spec: Dictionary) -> HeadForm:
	var f := HeadForm.new()
	f.name = new_name
	f.height = spec["h"]
	var b: Array = spec["b"]
	var t: Array = spec["t"]
	f.bottom_width = b[0]
	f.bottom_forward = b[2]
	f.bottom_dome = b[3]
	f.top_width = t[0]
	f.top_forward = t[2]
	f.top_dome = t[3]
	f.flat_front = spec.get("plano", false)
	if spec.has("cara"):
		f.face_flat = spec["cara"]
	f.ensure_cuts()
	for c: Array in spec.get("cuts", []):
		var cut: HeadCut = f.cuts[int(c[0])]
		cut.active = true
		cut.width = c[1]
		cut.forward = (f.bottom_width * 0.5 + f.bottom_forward - cut.width * 0.5) if c[3] is String else float(c[3])
	return f


