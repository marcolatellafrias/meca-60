class_name MechInsideStairs
extends RefCounted

## LA ESCALERA DE ADENTRO (13/11/2026): la variante de la estructura «sin nada y escaleras adentro» (ver
## CabinGrid.STRUCTURE). El usuario: «que las escaleras de atrás estén, en vez de estar atrás, estén metidas adentro y
## que no tengan esas puertas hacia afuera… la primera variante… sin nada y escaleras adentro»; contra la pared de atrás,
## en tramos paralelos («sí»), y se entra sólo por el ascensor («sí»).
##
## UN TRAMO POR PISO, CONTRA LA PARED DE ATRÁS, todos subiendo para el mismo lado (+x), uno encima del otro: como la
## escalera de afuera de la variante de siempre (MechExterior), pero en el carril de adentro de la pared.
##   · LA LOSA DE ARRIBA TIENE UN HUECO sobre cada tramo (`hole`): se llega por él. Encima del hueco arranca el tramo
##     siguiente, así que la altura libre sobre cada escalón es la de un piso.
##   · SE SUBE Y SE BAJA DE COSTADO: las barandas dejan abierto el final de cada tramo (`EXIT`, del ancho del carril), y
##     uno se baja de los últimos escalones al piso. *Con la caja de 3 módulos, adentro hay 5,7 m y un tramo mide 5,67 (la
##     pisada de toda escalera del juego, Stairs.TREAD): la escalera va de pared a pared y no queda losa en las puntas
##     (`landing_room`).* Se sube igual: los primeros escalones, bajos, se pisan de costado.
##   · BARANDAS DONDE HAY CAÍDA: del lado de adentro de cada tramo (al piso de abajo), y en el borde del hueco de cada
##     piso, donde el tramo de ese piso ya va más alto que una persona (más bajo, el tramo mismo tapa el hueco: se lo
##     pisa de costado).
## Se arma con Stairs (la regla de toda escalera: escalones para los pies, rampa para la cápsula) y MechExterior._rail.

## El ancho del carril de la escalera (m): el de la pasarela de afuera.
const LANE := MechExterior.WALK
## Lo libre que tiene que quedar sobre un tramo para que pase una persona por abajo (m): de ahí en adelante, la baranda
## del hueco.
const UNDER := 2.1
## Lo que las barandas dejan abierto al final de cada tramo, para bajarse de costado al piso (m).
const EXIT := LANE


## El carril: de dónde a dónde va, en z (contra la cara de adentro de la pared de atrás).
static func lane() -> Vector2:
	return Vector2(CabinGrid.INNER - LANE, CabinGrid.INNER)


## Dónde arranca y termina cada tramo (x): centrado en el ancho de adentro.
static func foot() -> float:
	return -MechExterior.flight_run() * 0.5


static func head() -> float:
	return MechExterior.flight_run() * 0.5


## Lo que queda de losa a cada punta del tramo, en el carril (m): por donde se sube y se baja.
static func landing_room() -> float:
	return CabinGrid.INNER - head()


## EL HUECO de la losa `index` (1 a FLOORS − 1), en planta: x de `foot` a `head`, z del carril. Vacío si no tiene.
static func hole(index: int) -> Rect2:
	if index < 1 or index > CabinGrid.FLOORS - 1:
		return Rect2()
	var z := lane()
	return Rect2(foot(), z.x, head() - foot(), z.y - z.x)


## LA LOSA `index`, con su hueco si tiene: en pedazos, para el dibujo y para las formas de choque.
static func slab(holder: Node3D, solid: PhysicsBody3D, index: int, color: Color) -> void:
	var y := CabinGrid.slab_y(index)
	var size := CabinGrid.SIZE
	var half := CabinGrid.HALF
	var gap := hole(index)
	if gap.size == Vector2.ZERO:
		MechInsideStairs._piece(holder, solid, Rect2(-half, -half, size, size), y, color)
		return
	# Adelante del carril, atrás del carril (lo de debajo de la pared) y las dos puntas del carril.
	MechInsideStairs._piece(holder, solid, Rect2(-half, -half, size, gap.position.y + half), y, color)
	MechInsideStairs._piece(holder, solid, Rect2(-half, gap.end.y, size, half - gap.end.y), y, color)
	MechInsideStairs._piece(holder, solid, Rect2(-half, gap.position.y, gap.position.x + half, gap.size.y), y, color)
	MechInsideStairs._piece(holder, solid, Rect2(gap.end.x, gap.position.y, half - gap.end.x, gap.size.y), y, color)


## Un pedazo de losa: `area` en planta (x, z), a la altura `y`.
static func _piece(holder: Node3D, solid: PhysicsBody3D, area: Rect2, y: float, color: Color) -> void:
	if area.size.x <= 0.001 or area.size.y <= 0.001:
		return
	var size := Vector3(area.size.x, CabinGrid.SLAB, area.size.y)
	var at := Vector3(area.get_center().x, y, area.get_center().y)
	Clay.box(holder, size, at, color)
	Clay.shape_box(solid, size, at)


## LOS TRAMOS Y SUS BARANDAS (ver arriba).
static func build(holder: Node3D, solid: PhysicsBody3D) -> void:
	var z := lane()
	var middle := (z.x + z.y) * 0.5
	var inner := z.x
	var run := MechExterior.flight_run()
	for index in CabinGrid.FLOORS - 1:
		var low := CabinGrid.ground(index)
		var high := CabinGrid.ground(index + 1)
		var rise := high - low
		var from := Vector3(foot(), low, middle)
		var to := Vector3(head(), high, middle)
		# Las dos zancas.
		for edge: float in [-1.0, 1.0]:
			MechExterior._bar(holder, from + Vector3(0, -0.1, edge * LANE * 0.5), to + Vector3(0, -0.1, edge * LANE * 0.5), 0.1)
		Stairs.flight(holder, from, Vector3.RIGHT, rise, LANE, MechExterior.GRATE)
		# La baranda del lado de adentro del tramo, desde donde ya hay caída.
		var start := foot() + run * 0.5 / rise
		var end := head() - EXIT
		MechExterior._rail(holder, solid, Vector3(start, low + rise * (start - foot()) / run, inner),
			Vector3(end, low + rise * (end - foot()) / run, inner))
	# La baranda del borde de cada hueco: donde el tramo de ese piso ya va más alto que una persona (en el de arriba de
	# todo no hay tramo: todo el borde).
	for index in range(1, CabinGrid.FLOORS):
		var gap := hole(index)
		var floor_y := CabinGrid.ground(index)
		var start := gap.position.x
		if index < CabinGrid.FLOORS - 1:
			start = foot() + run * UNDER / (CabinGrid.ground(index + 1) - floor_y)
		MechExterior._rail(holder, solid, Vector3(start, floor_y, inner), Vector3(gap.end.x - EXIT, floor_y, inner))
