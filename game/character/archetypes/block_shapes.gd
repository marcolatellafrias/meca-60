class_name BlockShapes
extends Resource

## ── LAS FORMAS DE BLOQUES DE TODOS LOS ARQUETIPOS (31/10/2026, ver BlockShape) ───────────────────────────────────────
## Las que mandan: las que el F1 de la fila Personajes está editando o guardó, una por arquetipo. Un arquetipo que no
## está arranca con lo que tenía con el sistema viejo (ver BlockShape.from_sizes). El botón Guardar del panel (ver
## LocomotionTuner, la pestaña Cuerpo) las escribe en `PATH`; se leen al arrancar.
##
## ⚠ El archivo es del usuario (lo escribe el panel cuando él guarda): no se commitea a mano.

const PATH := "res://game/character/archetypes/block_shapes.tres"

## Arquetipo (EntityArchetype.Archetype) → BlockShape.
@export var shapes: Dictionary = {}

static var live: Dictionary = _saved()


static func _saved() -> Dictionary:
	if not ResourceLoader.exists(PATH):
		return {}
	var saved := ResourceLoader.load(PATH, "", ResourceLoader.CACHE_MODE_IGNORE) as BlockShapes
	return saved.shapes.duplicate() if saved != null else {}


## La forma de `archetype`, o null si no tiene (arranca con la de antes).
static func for_archetype(archetype: int) -> BlockShape:
	return live.get(archetype) as BlockShape


## La pone a mano (el panel): desde ahí, los personajes de ese arquetipo que se armen la usan.
static func set_for(archetype: int, shape: BlockShape) -> void:
	live[archetype] = shape


## Vuelve a la de antes: la del sistema viejo.
static func forget(archetype: int) -> void:
	live.erase(archetype)


## VUELVE A LA GUARDADA de `archetype` (o a la de antes, si no tiene).
static func restore(archetype: int) -> void:
	var saved := _saved()
	if saved.has(archetype):
		live[archetype] = (saved[archetype] as BlockShape).copy()
	else:
		live.erase(archetype)


## GUARDA todas las que están puestas. Verdadero si salió bien.
static func store() -> bool:
	var out := BlockShapes.new()
	for archetype: int in live:
		out.shapes[archetype] = (live[archetype] as BlockShape).copy()
	return ResourceSaver.save(out, PATH) == OK
