class_name BodyDensity
extends Resource

## CUÁNTA MALLA TIENE CADA PARTE DEL CUERPO: los anillos a lo largo y las columnas alrededor (celdas de lado a lado y
## de adelante a atrás de la sección) del torso, los miembros, el cuello, la mano y la cabeza. Eran constantes del
## armado (ver ProceduralBodyUtil, HeadForm); desde el 21/10/2026 se editan en el F2 de la fila de personajes (ver
## BodyDensityTuner). Sin nada guardado, los del low poly (ver `low_poly`), el único estilo desde el 22/10/2026.
##
## Las formas no cambian con esto: los loop cuts autorados siguen donde estaban, cada uno cae en el anillo más cercano
## (ver GridPart._snapped), así que con menos anillos una vuelta se corre a su anillo.

## (Los datos del low poly, el único estilo desde el 22/10/2026: el archivo conserva su sufijo «_low» hasta que el dios del
## juego lo renombre.)
static var path := "res://game/character/rig/body_density_low.tres"

@export_group("Torso")
## Columnas de la sección del torso: de lado a lado y de adelante a atrás (alrededor son el doble de la suma).
@export_range(2, 40) var torso_across := 22
@export_range(1, 20) var torso_deep := 10
## Anillos a lo largo del torso.
@export_range(2, 32) var torso_rings := 16

@export_group("Piernas y brazos")
## Anillos a lo largo de una pierna y de un brazo (los dos iguales: las vueltas autoradas se ordenan sobre ellos, ver
## BodyLoop.limb_ordered).
@export_range(2, 32) var limb_rings := 16
## Columnas de la sección de una pierna (y del pie, que la continúa) y de un brazo.
@export_range(1, 12) var leg_across := 6
@export_range(1, 12) var leg_deep := 6
@export_range(1, 12) var arm_across := 5
@export_range(1, 12) var arm_deep := 5
## Anillos de la media esfera de arriba de cada pierna y de la cúpula del hombro.
@export_range(1, 8) var hip_dome_rings := 4
@export_range(1, 8) var shoulder_dome_rings := 3

@export_group("Cuello")
@export_range(1, 8) var neck_across := 4
@export_range(1, 8) var neck_deep := 4
@export_range(1, 8) var neck_rings := 4


@export_group("Cabeza")
## Lados alrededor de la cabeza, anillos del cilindro y de cada domo (ver HeadForm.build_arrays).
@export_range(4, 48) var head_around := 32
@export_range(1, 32) var head_rings := 24
@export_range(1, 12) var head_dome_rings := 10
## Las celdas de la cara de cada oreja (un disco: alrededor son el doble de la suma).
@export_range(1, 6) var ear_across := 3
@export_range(1, 6) var ear_deep := 3
## EL PIE DE CAJA DEL LOW POLY (ver ProceduralBodyUtil._box_foot): sus cortes a lo largo, de lado a lado (dos como
## mínimo: es lo menos que arma una grilla, ver GridPart), y cuántos anillos más van entre dos de sus loop cuts, a lo
## largo del pie, interpolados. De arriba a abajo no se corta: dos celdas, lo mínimo (`FOOT_DEEP`).
@export_range(2, 8) var foot_across := 2
@export_range(0, 6) var foot_span_rings := 0
const FOOT_DEEP := 2


## LOS DE ARRANQUE DEL LOW POLY: unas cuatro veces menos malla en cada dirección, lo justo para que cada parte siga
## leyéndose como lo que es.
static func low_poly() -> BodyDensity:
	var d := BodyDensity.new()
	d.torso_across = 6
	d.torso_deep = 3
	d.torso_rings = 6
	d.limb_rings = 6
	d.leg_across = 2
	d.leg_deep = 2
	d.arm_across = 2
	d.arm_deep = 2
	d.hip_dome_rings = 1
	d.shoulder_dome_rings = 1
	d.neck_across = 2
	d.neck_deep = 2
	d.neck_rings = 2
	d.head_around = 8
	d.head_rings = 4
	d.head_dome_rings = 2
	d.ear_across = 1
	d.ear_deep = 1
	return d


static var _loaded: BodyDensity = null


## LA DE LOS PERSONAJES: la guardada si hay, si no la de arranque del low poly (ver `low_poly`).
static func current() -> BodyDensity:
	if _loaded == null:
		if ResourceLoader.exists(path):
			_loaded = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE) as BodyDensity
		if _loaded == null:
			_loaded = low_poly()
	return _loaded


static func store() -> bool:
	return ResourceSaver.save(current(), path) == OK


func arm_cells() -> Vector2i:
	return Vector2i(arm_across, arm_deep)


func ear_cells() -> Vector2i:
	return Vector2i(ear_across, ear_deep)

