class_name TorsoShapes
extends Resource

## LAS FORMAS DE TORSO GUARDADAS, una por arquetipo, y lo que les da PERMANENCIA.
##
## ── VA AL REPO, NO A `user://` ──────────────────────────────────────────────────────────────────
## Lo que el panel del sandbox edita acá no es una preferencia de una máquina: es el DISEÑO del
## personaje, igual que el resto del arquetipo. Así que el archivo vive en `res://` junto a
## `archetypes.gd`, entra al repo, viaja con el proyecto y lo ve el juego — no solo el sandbox donde se
## editó. Guardado en `user://` cada máquina tendría su propio gordo.
##
## ⚠ `res://` SE PUEDE ESCRIBIR CORRIENDO DESDE EL EDITOR, que es donde se usa el sandbox, y NO en un
## export (ahí es un .pck). Guardar en un export no es un caso que exista: es una herramienta de diseño.
## Si alguna vez hace falta, `save()` avisa y no pretende haber guardado.
##
## ── EL CÓDIGO SIGUE TENIENDO LOS DEFECTOS, Y LO GUARDADO ES SOLO LA DIFERENCIA ──────────────────
## Cada arquetipo deriva su forma de sus propios knobs (ver SkeletonSizesUtil.create) y lo que está acá es
## **la capa de lo que se le cambió** (ver ShapeLayer), no la forma entera. Tres razones:
##
##   · el repo sigue arrancando sin el archivo, y borrarlo devuelve al personaje que el código describe
##   · lo que el archivo no dice NO ES UN DATO, así que un campo nuevo —o uno que no existía cuando se
##     guardó— se resuelve con el defecto del arquetipo en vez de con el defecto de la CLASE
##   · y por lo mismo, cambiar un número en `archetypes.gd` llega a todos los arquetipos que no lo tocaron
##
## El segundo punto es un bug que pasó: ver el encabezado de ShapeLayer, que lo cuenta con nombres.

## Dónde se guarda. Es `static var` y no `const` por una sola razón: el test lo apunta a `user://` para
## no escribirle al repo mientras prueba que guardar y olvidar funcionan.
## (Los datos del low poly, el único estilo desde el 22/10/2026: el archivo conserva su sufijo «_low» hasta que el dios del
## juego lo renombre.)
static var path := "res://game/character/archetypes/torso_shapes_low.tres"

## Arquetipo (el int del enum) → CAPA (ver ShapeLayer): lo que esa forma tiene de distinto al defecto del
## código. Diccionario y no un array para que agregar un arquetipo al enum no corra las demás entradas.
##
## Las entradas del formato viejo —la forma entera como recurso— se leen igual: `ShapeLayer.from_saved` las
## convierte, y el próximo guardado las deja en el formato nuevo.
@export var by_archetype: Dictionary = {}

## LO QUE EL PANEL ESTÁ TOCANDO Y TODAVÍA NO GUARDÓ: arquetipo → capa, solo en memoria.
##
## Existe para que arrastrar un slider se vea en vivo sin escribirle al disco en cada píxel, y para que
## GUARDAR sea un acto explícito — lo que uno probó y no guardó se va al cerrar el juego, que es lo que
## uno espera de una prueba. Gana sobre lo guardado mientras exista (ver `shape_for`).
static var preview: Dictionary = {}

## Lo cargado, una vez por sesión. Se relee poniendo `_loaded` en null.
static var _loaded: TorsoShapes = null
static var _tried := false


## La tabla guardada, o una vacía si no hay archivo. Nunca devuelve null.
static func table() -> TorsoShapes:
	if not _tried:
		_tried = true
		if ResourceLoader.exists(path):
			_loaded = ResourceLoader.load(path, "TorsoShapes", ResourceLoader.CACHE_MODE_IGNORE) \
				as TorsoShapes
	if _loaded == null:
		_loaded = TorsoShapes.new()
	return _loaded


## LA FORMA QUE VALE para un arquetipo: el defecto del código con la capa encima. `base` es ese defecto —lo
## que el arquetipo describe— y nunca se modifica: lo que sale es una copia.
static func shape_for(archetype: int, base: TorsoShape) -> TorsoShape:
	if base == null:
		return null
	var out := base.copy()
	ShapeLayer.apply(out, layer_for(archetype))
	return out


## LA CAPA QUE VALE: la que el panel está tocando, si no la guardada, si no vacía —y ahí manda el código—.
## Es el único lugar donde se decide ese orden.
static func layer_for(archetype: int) -> Dictionary:
	# LO QUE ESTÉ EN LA CAPA DE PRUEBA se interpreta igual que lo que esté en el archivo (ver
	# ShapeLayer.from_saved): una capa pasa derecho, y una forma entera —lo que deja un test, o un
	# formato viejo— se convierte. Un solo camino para leer, sea de donde venga.
	if preview.has(archetype):
		return ShapeLayer.from_saved(preview[archetype], TorsoShape.new())
	return saved_layer(archetype)


## La capa guardada de un arquetipo, vacía si no hay. Convierte sola lo guardado en el formato viejo.
static func saved_layer(archetype: int) -> Dictionary:
	return ShapeLayer.from_saved(table().by_archetype.get(archetype), TorsoShape.new())


## Si este arquetipo tiene algo guardado. Es distinto de "su capa está vacía": guardar una forma idéntica al
## defecto es una decisión, y el panel la tiene que poder mostrar.
static func is_saved(archetype: int) -> bool:
	return table().by_archetype.has(archetype)


## Guarda la forma de UN arquetipo sin tocar las demás, como la DIFERENCIA contra el defecto del código
## (`base`). Devuelve si pudo.
## ── UNA ESCALA APLICADA (22/10/2026, lo pidió el dios del juego, ver MeasuresPanel) ──────────────────────────────────
## La capa de `archetype` —`layer`, la guardada o la que se está probando— con el personaje entero `factor` veces más
## grande, horneado como en Blender: los metros de la forma multiplicados, y lo que no es de ella en su `skeleton_scale`
## (ver TorsoShape.skeleton_scale). Con `factor` 1 da la misma capa.
static func baked_layer(archetype: int, layer: Dictionary, factor: float) -> Dictionary:
	var inst := EntityInstantiation.create(EntityInstantiation.debug_seed(archetype as EntityArchetype.Archetype, 1))
	var held: Variant = preview.get(archetype)
	preview.erase(archetype)
	var sizes := SkeletonSizesUtil.create(inst)
	if held != null:
		preview[archetype] = held
	var base: TorsoShape = sizes.torso_default.copy()
	var shape := base.copy()
	ShapeLayer.apply(shape, layer)
	SkeletonSizesUtil.migrate_stance(shape, layer)
	SkeletonSizesUtil._scale_shape(shape, factor)
	shape.skeleton_scale *= factor
	return ShapeLayer.of(shape, base)


static func store(archetype: int, shape: TorsoShape, base: TorsoShape) -> bool:
	var all := table()
	all.by_archetype[archetype] = ShapeLayer.of(shape, base)
	preview.erase(archetype)
	var error := ResourceSaver.save(all, path)
	if error != OK:
		push_warning("TorsoShapes: no se pudo guardar en %s (error %d). " % [path, error]
			+ "Pasa en un export, donde res:// es un .pck de solo lectura.")
		return false
	return true


## GUARDA UN SOLO NÚMERO de la forma de un arquetipo, sin rearmar la diferencia entera: lo usa el panel del canónico
## para la escala de la cabeza (ver CharacterLookPanel), que es un número sin unidad —la lupa del sandbox no lo toca—,
## así que se puede escribir derecho en la capa. Devuelve si pudo.
static func store_value(archetype: int, prop: String, value: Variant) -> bool:
	var all := table()
	var layer := saved_layer(archetype).duplicate()
	layer[prop] = value
	all.by_archetype[archetype] = layer
	preview.erase(archetype)
	return ResourceSaver.save(all, path) == OK


## Olvida lo guardado de un arquetipo y lo devuelve al defecto del código.
static func forget(archetype: int) -> bool:
	preview.erase(archetype)
	var all := table()
	if not all.by_archetype.has(archetype):
		return true
	all.by_archetype.erase(archetype)
	return ResourceSaver.save(all, path) == OK


