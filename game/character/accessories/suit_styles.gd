class_name SuitStyles
extends Resource

## LOS ESTILOS GUARDADOS DE LOS TRAJES (ver SuitStyle): traje → capa (ver ShapeLayer), la diferencia contra lo que el
## código dice de ese traje (ver Suits.DEFS). Lo que el archivo no diga lo pone el código.

## Dónde se guarda. `static var` y no `const`, para que un test lo apunte a `user://`.
static var path := "res://game/character/accessories/suit_styles.tres"

## Traje (int) → capa.
@export var by_suit: Dictionary = {}

## LO QUE EL PANEL ESTÁ TOCANDO Y TODAVÍA NO GUARDÓ: traje → capa, sólo en memoria.
static var preview: Dictionary = {}

static var _loaded: SuitStyles = null
static var _tried := false
## Los estilos ya armados, por traje: se piden en cada anillo que se pinta. Se tiran al probar, guardar u olvidar.
static var _cache: Dictionary = {}


## EL ESTILO QUE EL CÓDIGO LE DA A UN TRAJE (ver Suits.DEFS).
##
## UN TRAJE QUE ES COPIA DE OTRO (`copy_of` en DEFS: el mameluco low poly) arranca con el estilo que el otro tiene AHORA
## —sus colores guardados incluidos— y lo que se guarde de él es la diferencia contra eso.
static func code(index: int) -> SuitStyle:
	var def: Dictionary = Suits.DEFS[index]
	if def.has("copy_of") and int(def["copy_of"]) != index:
		var copied := style_for(int(def["copy_of"])).copy()
		# Y LO QUE ESE TRAJE DICE DISTINTO (`style_overrides`): la hebilla apagada del low poly.
		var overrides: Dictionary = def.get("style_overrides", {})
		for field: String in overrides:
			copied.set(field, overrides[field])
		return copied
	var out := SuitStyle.new()
	out.cloth_color = def["cloth"]
	out.sleeves_color = def.get("sleeves", def["cloth"])
	out.trousers_color = def["trousers"]
	out.shoes_color = def["shoes"]
	out.seam_color = def.get("seam", (def["cloth"] as Color).darkened(0.35))
	out.patch_color = def.get("patch", (def["cloth"] as Color).darkened(0.2))
	out.belt_color = def.get("belt", Belts.LEATHER)
	# (El acero de la hebilla y el cuero de las bolsitas, que eran de Buckle y Pouch, borrados el 07/11/2026.)
	out.buckle_color = def.get("buckle", Color(0.58, 0.60, 0.63))
	out.pouch_color = def.get("pouch", Color(0.36, 0.25, 0.18))
	out.button_count = int((def.get("buttons", {}) as Dictionary).get("count", 0))
	out.button_color = def.get("button", (def["cloth"] as Color).darkened(0.4))
	out.closure_color = def.get("closure", out.seam_color)
	out.collar_color = def.get("collar", Color(0.72, 0.56, 0.44))
	out.card_color = def.get("card", Color(0.89, 0.87, 0.82))
	out.card_text_color = def.get("card_text", Color(0.22, 0.16, 0.12))
	out.card_stripe_color = def.get("card_stripe", Color(0.60, 0.41, 0.38))
	out.card_stripe_text_color = def.get("card_stripe_text", Color(0.92, 0.88, 0.80))
	out.sleeves_seam_color = def.get("sleeves_seam", out.seam_color)
	out.trousers_seam_color = def.get("trousers_seam", out.seam_color)
	out.sleeve_cuff = float(def.get("sleeve_cuff", out.sleeve_cuff))
	return out


## EL ESTILO QUE VALE para un traje: el del código con la capa encima. Nunca null.
static func style_for(index: int) -> SuitStyle:
	if _cache.has(index):
		return _cache[index]
	var out := code(index)
	ShapeLayer.apply(out, layer_for(index))
	_cache[index] = out
	return out


## LA CAPA QUE VALE: la que el panel está tocando, si no la guardada, si no vacía.
static func layer_for(index: int) -> Dictionary:
	if preview.has(index):
		return preview[index]
	return ShapeLayer.from_saved(table().by_suit.get(index), code(index))


static func table() -> SuitStyles:
	if not _tried:
		_tried = true
		if ResourceLoader.exists(path):
			_loaded = ResourceLoader.load(path, "SuitStyles", ResourceLoader.CACHE_MODE_IGNORE) as SuitStyles
	if _loaded == null:
		_loaded = SuitStyles.new()
	return _loaded


static func is_saved(index: int) -> bool:
	return table().by_suit.has(index)


## Guarda el estilo de UN traje sin tocar los demás, como la diferencia contra el del código.
static func store(index: int, style: SuitStyle) -> bool:
	var all := table()
	all.by_suit[index] = ShapeLayer.of(style, code(index))
	preview.erase(index)
	_cache.clear()  # todos: un traje puede ser copia de otro (ver `code`)
	return ResourceSaver.save(all, path) == OK


static func forget(index: int) -> bool:
	var all := table()
	all.by_suit.erase(index)
	preview.erase(index)
	_cache.clear()  # todos: un traje puede ser copia de otro (ver `code`)
	return ResourceSaver.save(all, path) == OK
