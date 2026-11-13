class_name CharacterLooks
extends Resource

## LOS ASPECTOS CANÓNICOS: uno por arquetipo (ver CharacterLook), lo que el usuario elige en la fila Personajes
## para que los seis se parezcan a sus concept arts (11/10/2026).
##
## Va a `res://`, como las cabezas y los torsos (ver TorsoShapes): es diseño del personaje. Y se guarda ENTERO, no como
## diferencia contra un defecto: el defecto es el personaje sin nada —ojos redondos, sin labios, sin accesorios—, lo
## mismo que un `CharacterLook` nuevo, así que no hay nada del código que se pueda perder.
##
## ⚠ El archivo lo escribe el sandbox cuando el usuario cambia algo: es suyo, no se commitea a mano.

## Dónde se guarda. `static var` y no `const`, como en las otras tablas, para que un test lo apunte a `user://`.
## (Los datos del low poly, el único estilo desde el 22/10/2026: el archivo conserva su sufijo «_low» hasta que el dios del
## juego lo renombre.)
static var path := "res://game/character/archetypes/character_looks_low.tres"

## Arquetipo (int) → CharacterLook.
@export var by_archetype: Dictionary = {}

static var _loaded: CharacterLooks = null
static var _tried := false


## La tabla guardada, o una vacía si no hay archivo. Nunca devuelve null.
static func table() -> CharacterLooks:
	if not _tried:
		_tried = true
		if ResourceLoader.exists(path):
			_loaded = ResourceLoader.load(path, "CharacterLooks", ResourceLoader.CACHE_MODE_IGNORE) as CharacterLooks
	if _loaded == null:
		_loaded = CharacterLooks.new()
	return _loaded


## ── LA FORMA DE CABEZA DE CADA ARQUETIPO ────────────────────────────────────────────────────────
## Las de arranque, elegidas por el maestro de la estética (15/10/2026) entre las formas que eligió el usuario
## (ver HeadForms.CHOSEN), hasta que él elija otra con el panel de la fila Personajes. Al quedar diez formas
## (16/10/2026) él eligió el reemplazo de las que se fueron: el niño, la redonda de abajo 6 cm (era la pelota); el flaco
## alto, la larga de mentón largo (el pepino); el viejo, la larga de pómulos bajos (la alargada sin pómulos); el
## genérico, el huevo con mentón adelante (el huevo suave). El gordo, la un poco más larga, que es la que él eligió; el
## musculoso, la pera recta. Arquetipo (int) → ranura.
const DEFAULT_HEAD_FORMS := {
	EntityArchetype.Archetype.fat_man: 3,
	EntityArchetype.Archetype.kid: 6,
	EntityArchetype.Archetype.lanky: 5,
	EntityArchetype.Archetype.buff: 9,
	EntityArchetype.Archetype.old: 4,
	EntityArchetype.Archetype.generic: 0,
}


## LA FORMA DE CABEZA DE UN ARQUETIPO: la que tiene elegida su canónico, o la de arranque. Es la de todos los de ese
## arquetipo (ver SkeletonSizesUtil), no sólo la del canónico.
static func head_form_for(archetype: int) -> int:
	var saved := table().by_archetype.get(archetype) as CharacterLook
	if saved != null and saved.head_form >= 0:
		return saved.head_form
	return int(DEFAULT_HEAD_FORMS.get(archetype, 0))


## EL ASPECTO CANÓNICO DE UN ARQUETIPO, una copia —para tocarla sin tocar la tabla—, o el de nada si no hay guardado.
static func for_archetype(archetype: int) -> CharacterLook:
	var saved := table().by_archetype.get(archetype) as CharacterLook
	return saved.duplicate() as CharacterLook if saved != null else CharacterLook.new()


## LO GUARDA para ese arquetipo y escribe el archivo. Devuelve si se pudo escribir.
static func store(archetype: int, look: CharacterLook) -> bool:
	var data := table()
	data.by_archetype[archetype] = look.duplicate()
	return ResourceSaver.save(data, path) == OK


## EL ASPECTO GUARDADO DE UN ARQUETIPO TAL CUAL, sin copiar, o null. Para leer en el armado de cada personaje, donde
## copiarlo sería gastar; quien lo quiera tocar pide `for_archetype`.
static func saved(archetype: int) -> CharacterLook:
	return table().by_archetype.get(archetype) as CharacterLook


## LO PONE EN LA TABLA SIN ESCRIBIR EL ARCHIVO: lo que el panel está probando, que vale para todo lo que se arme desde
## ahora (ver CharacterLookPanel). `store` lo escribe.
static func put(archetype: int, look: CharacterLook) -> void:
	table().by_archetype[archetype] = look

