class_name PoseShapes
extends Resource

## LAS POSTURAS Y LOS ANDARES GUARDADOS, uno por arquetipo (ver PoseShape), y lo que les da permanencia.
##
## Es el mismo mecanismo que `TorsoShapes` —que explica en detalle por qué el archivo va al repo y no a
## `user://`, y por qué el código sigue teniendo los defectos— aplicado a las otras perillas del
## personaje: cómo se para y cómo camina.
##
## ── SE APLICA DONDE EL ARQUETIPO NACE ───────────────────────────────────────────────────────────
## `EntityArchetype.create` pide lo guardado y lo escribe sobre las perillas del código. Ese es el único
## punto, y es el que hace que todo lo de abajo siga funcionando sin saber que esto existe: la mezcla de
## dos arquetipos pasa a mezclar las posturas guardadas, los multiplicadores de especie se aplican encima,
## y la variación por individuo sigue viva.

## Dónde se guarda. `static var` y no `const` por lo mismo que en TorsoShapes: el test lo apunta a
## `user://` para no escribirle al repo mientras prueba guardar y olvidar.
## (Los datos del low poly, el único estilo desde el 22/10/2026: el archivo conserva su sufijo «_low» hasta que el dios del
## juego lo renombre.)
static var path := "res://game/character/archetypes/pose_shapes_low.tres"

## Arquetipo (el int del enum) → CAPA (ver ShapeLayer): las perillas que ese arquetipo tiene distintas de
## lo que dice `archetypes.gd`, y nada más. Lo que el archivo no dice no es un dato, así que una perilla
## nueva se resuelve con el código y no con el defecto de la clase.
@export var by_archetype: Dictionary = {}

## LO QUE EL PANEL ESTÁ TOCANDO Y TODAVÍA NO GUARDÓ: arquetipo → capa, solo en memoria. Gana sobre lo
## guardado mientras exista, y se va al cerrar el juego.
static var preview: Dictionary = {}

static var _loaded: PoseShapes = null
static var _tried := false


## La tabla guardada, o una vacía si no hay archivo. Nunca devuelve null.
static func table() -> PoseShapes:
	if not _tried:
		_tried = true
		if ResourceLoader.exists(path):
			_loaded = ResourceLoader.load(path, "PoseShapes", ResourceLoader.CACHE_MODE_IGNORE) \
				as PoseShapes
	if _loaded == null:
		_loaded = PoseShapes.new()
	return _loaded


## LA CAPA QUE VALE: la que el panel está tocando, si no la guardada, si no vacía. Es el único lugar donde
## se decide ese orden.
static func layer_for(archetype: int) -> Dictionary:
	# LO QUE ESTÉ EN LA CAPA DE PRUEBA se interpreta igual que lo que esté en el archivo (ver
	# ShapeLayer.from_saved): una capa pasa derecho, y una forma entera —lo que deja un test, o un
	# formato viejo— se convierte. Un solo camino para leer, sea de donde venga.
	if preview.has(archetype):
		return ShapeLayer.from_saved(preview[archetype], PoseShape.new())
	return saved_layer(archetype)


## La capa guardada, vacía si no hay. Lee igual lo guardado en el formato viejo (ver ShapeLayer).
static func saved_layer(archetype: int) -> Dictionary:
	return ShapeLayer.from_saved(table().by_archetype.get(archetype), PoseShape.new())


static func is_saved(archetype: int) -> bool:
	return table().by_archetype.has(archetype)


## LA POSTURA QUE VALE para un arquetipo: la del código con la capa encima.
static func shape_for(archetype: int, base: PoseShape) -> PoseShape:
	if base == null:
		return null
	var out := base.copy()
	ShapeLayer.apply(out, layer_for(archetype))
	return out


## ESCRIBE LA CAPA SOBRE UN ARQUETIPO RECIÉN CREADO. Es todo lo que el resto del juego necesita saber de
## este archivo (ver EntityArchetype.create), y es una escritura directa: las perillas de `PoseShape` se
## llaman igual que las del arquetipo porque SON las del arquetipo.
static func apply(arch: EntityArchetype, archetype: int) -> void:
	ShapeLayer.apply(arch, layer_for(archetype))


## Guarda la postura de UN arquetipo sin tocar las demás, como la diferencia contra lo que dice el código.
static func store(archetype: int, shape: PoseShape, base: PoseShape) -> bool:
	var all := table()
	all.by_archetype[archetype] = ShapeLayer.of(shape, base)
	preview.erase(archetype)
	var error := ResourceSaver.save(all, path)
	if error != OK:
		push_warning("PoseShapes: no se pudo guardar en %s (error %d). " % [path, error]
			+ "Pasa en un export, donde res:// es un .pck de solo lectura.")
		return false
	return true


## Olvida lo guardado de un arquetipo y lo devuelve al defecto del código.
static func forget(archetype: int) -> bool:
	preview.erase(archetype)
	var all := table()
	if not all.by_archetype.has(archetype):
		return true
	all.by_archetype.erase(archetype)
	return ResourceSaver.save(all, path) == OK


