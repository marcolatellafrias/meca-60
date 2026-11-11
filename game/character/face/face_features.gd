class_name FaceFeatures
extends Resource

## LOS RASGOS EXTRA GUARDADOS: los que el dios del juego crea desde el editor vectorial (ver FeatureEditor) —arrugas,
## una nariz, lo que sea—. Los ojos y la boca no están acá: son de todos y los arma la forma de la cabeza (ver
## FaceLayout); hasta el 15/10/2026 eran dos ranuras con su capa guardada, borradas con los gestos viejos.
##
## ── VA AL REPO, NO A `user://` ──────────────────────────────────────────────────────────────────
## Igual que los torsos (ver TorsoShapes, que lo explica en detalle): lo que el editor dibuja es DISEÑO del personaje,
## así que el archivo vive en `res://` y lo ve el juego, no solo el sandbox.
##
## Se guardan ENTEROS y no como diferencia, porque no hay un defecto del código del que diferenciarlos; y en orden, que
## es el de sus parcelas. Cada uno cuelga de los ojos, la boca o la nariz y dice qué cuerpos lo llevan (ver
## FaceFeature).

## Dónde se guarda. `static var` y no `const`: el test lo apunta a `user://` para no escribirle al repo.
static var path := "res://game/character/archetypes/face_features.tres"

@export var extras: Array[FaceFeature] = []

## LO QUE EL EDITOR ESTÁ DIBUJANDO Y TODAVÍA NO GUARDÓ: la lista entera de extras, o null. Gana sobre lo guardado
## mientras exista, y se va al cerrar el juego.
static var extras_draft: Variant = null

## DÓNDE QUEDA LA NARIZ entre la boca (0) y los ojos (1): no es un rasgo sino un punto fijo del medio de la cara,
## del que cuelgan los extra que la eligen (ver `anchor_point`).
const NOSE_BETWEEN := 0.5

## SI LOS RASGOS SE DIBUJAN —los ojos, la boca y los extra—. Es de herramienta y no de diseño: apagarlos deja la cara
## limpia para mirarla. En el juego están siempre prendidos.
static var shown := true

static var _loaded: FaceFeatures = null
static var _tried := false


## La tabla guardada, o una vacía si no hay archivo. Nunca devuelve null.
static func table() -> FaceFeatures:
	if not _tried:
		_tried = true
		if ResourceLoader.exists(path):
			_loaded = ResourceLoader.load(path, "FaceFeatures", ResourceLoader.CACHE_MODE_IGNORE) \
				as FaceFeatures
	if _loaded == null:
		_loaded = FaceFeatures.new()
	return _loaded


## TODOS LOS RASGOS DE UNA FORMA, ya ubicados: los ojos y la boca de todos (ver FaceLayout) y después cada extra en su
## orden, lo lleve quien lo lleve —así el extra `i` es el `size() − extra_list().size() + i`—. Lo leen la hoja plana (ver
## FeatureChart) y el lienzo del editor (ver FeatureCanvas), que los muestran todos para ubicar el que se mira.
static func all(form: HeadForm) -> Array:
	var out: Array = FaceLayout.features(form)
	for extra: FaceFeature in extra_list():
		out.append(resolved(extra, form))
	return out


## Los extra, del borrador del editor si lo hay o de lo guardado.
static func extra_list() -> Array[FaceFeature]:
	var out: Array[FaceFeature] = []
	var source: Array = extras_draft if extras_draft != null else table().extras
	for each in source:
		if each is FaceFeature:
			out.append(each as FaceFeature)
	return out


## UN EXTRA YA UBICADO en esa forma: su corrimiento sumado al punto del que cuelga.
static func resolved(extra: FaceFeature, form: HeadForm) -> FaceFeature:
	var out := extra.copy()
	var at := anchor_point(extra.anchor, form)
	out.at_u = at.x + extra.at_u
	out.at_v = at.y + extra.at_v
	return out


## DE DÓNDE CUELGA UN EXTRA, en coordenadas de la cara (`at_u`, `at_v`): los ojos, la boca o la nariz —entre las dos—.
static func anchor_point(anchor: int, form: HeadForm) -> Vector2:
	var eyes := FaceLayout.eyes(form)
	var mouth := FaceLayout.mouth_place(form)
	match anchor:
		FaceFeature.ANCHOR_EYES:
			return Vector2(eyes.at_u, eyes.at_v)
		FaceFeature.ANCHOR_MOUTH:
			return Vector2(mouth.at_u, mouth.at_v)
	return Vector2(0.0, lerpf(mouth.at_v, eyes.at_v, NOSE_BETWEEN))


## GUARDA LOS EXTRA enteros y suelta el borrador. Devuelve si se pudo escribir.
static func store_extras(list: Array) -> bool:
	var all_of := table()
	var kept: Array[FaceFeature] = []
	for each in list:
		if each is FaceFeature:
			kept.append((each as FaceFeature).copy())
	all_of.extras = kept
	extras_draft = null
	var error := ResourceSaver.save(all_of, path)
	if error != OK:
		push_warning("FaceFeatures: no se pudo guardar en %s (error %d)." % [path, error])
		return false
	return true
