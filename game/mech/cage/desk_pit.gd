class_name DeskPit
extends RefCounted

## EL MÓDULO DE ARRIBA DE LA JAULA: UN BLOQUE LLENO CON EL POZO DEL MEDIO TALLADO (16/11/2026, el usuario: «el tablero es
## como el punto 1… solamente las partes del tablero inclinadas y la que va conectada a ese y va hasta el piso del lado
## interior. Las de afuera no van, porque todo eso está como cubierto y es como un espacio lleno… como si fuera carved
## out el espacio central»). Caras propias (CageMesh), nada de cajas pegadas.
##   · EL POZO, OCTOGONAL: la pared de adentro sube del piso hasta la orilla del tablero; el tablero, inclinado
##     `tilt` grados, sube hacia afuera hasta lo alto del bloque.
##   · LO ALTO DEL BLOQUE: chato, del octógono al borde del cuadrado; las cuatro paredes de afuera bajan al piso.
## TRES PERILLAS (el usuario: «controlar la inclinación del tablero y qué tanto es el radio de este octógono
## individualmente, y también la altura desde el asiento de arriba»): `radius` (el apotema del pozo), `tilt` y `eye`
## (los ojos sobre el piso). Lo alto sale de ahí: el centro de cada cara del tablero mira derecho a los ojos.

## El ancho de cada cara del tablero, de la orilla de adentro a la de afuera: 11 celdas de tablero (44 cm; hasta el
## 17/11/2026, 45 cm), así su grilla termina entera (ver FaceBoard).
const DEPTH := 11 * ProceduralDashboard.CELL

var side := 3.2
## EN LA REDONDA, AFUERA ES UN OCTÓGONO de este apotema (0: el cuadrado de `side`), y sus paredes bajan `sink` por
## debajo del piso (lo que se hunde en el cuerpo; ver CageShape.octagon_sink).
var outer_octagon := 0.0
var sink := 0.0
var radius := 0.6
var tilt := 45.0
var eye := 1.38


## LA ALTURA DE LA ORILLA DE ADENTRO DEL TABLERO: el centro de la cara, sobre su normal, cae en los ojos.
func low() -> float:
	var t := deg_to_rad(tilt)
	var middle := radius + DEPTH * 0.5 * cos(t)
	return maxf(eye - middle / tan(t) - DEPTH * 0.5 * sin(t), 0.1)


## Lo alto del bloque: la orilla de afuera del tablero.
func top() -> float:
	return low() + DEPTH * sin(deg_to_rad(tilt))


## El apotema de la orilla de afuera.
func rim() -> float:
	return radius + DEPTH * cos(deg_to_rad(tilt))


## Dónde va el centro de la cara `k` del tablero (0 al frente, en sentido horario visto de arriba) y su base: x a lo
## largo, y la normal (mira a los ojos), z hacia abajo de la cara. Para poner controles.
func desk_frame(k: int) -> Transform3D:
	var t := deg_to_rad(tilt)
	var angle := TAU * k / 8.0
	var out := Vector3(sin(angle), 0.0, -cos(angle))
	var along := Vector3.UP.cross(out).normalized()
	var normal := (Vector3.UP * cos(t) - out * sin(t)).normalized()
	var at := out * (radius + DEPTH * 0.5 * cos(t)) + Vector3.UP * (low() + DEPTH * 0.5 * sin(t))
	return Transform3D(Basis(along, normal, along.cross(normal)), at)


## El ancho de una cara del tablero en su medio.
func desk_width() -> float:
	return 2.0 * (radius + DEPTH * 0.5 * cos(deg_to_rad(tilt))) * tan(PI / 8.0)


## LAS CARAS, con el piso del pozo en y = 0.
func build(tool: SurfaceTool) -> void:
	var bottom := low()
	var high := top()
	var inner := _octagon(radius)
	var outer := _octagon(rim())
	for k in 8:
		var j := (k + 1) % 8
		# La pared de adentro y la cara del tablero, mirando al centro.
		var middle := (inner[k] + inner[j]) * 0.5
		CageMesh.face(tool, [_at(inner[k], 0.0), _at(inner[j], 0.0), _at(inner[j], bottom), _at(inner[k], bottom)],
			-_at(middle, 0.0).normalized())
		var near := _at(middle, bottom)
		var far := _at((outer[k] + outer[j]) * 0.5, high)
		var along := Vector3(inner[j].x - inner[k].x, 0.0, inner[j].y - inner[k].y)
		var normal := (far - near).cross(along).normalized()
		if normal.y < 0.0:
			normal = -normal
		CageMesh.face(tool, [_at(inner[k], bottom), _at(inner[j], bottom), _at(outer[j], high), _at(outer[k], high)],
			normal)
	if outer_octagon > 0.0:
		# LA REDONDA: lo alto, del borde del tablero al octógono de afuera; y sus ocho paredes, hasta abajo del piso.
		var ring := _octagon(outer_octagon)
		for k in 8:
			var j := (k + 1) % 8
			CageMesh.face(tool, [_at(outer[k], high), _at(outer[j], high), _at(ring[j], high), _at(ring[k], high)],
				Vector3.UP)
			var out := _at((ring[k] + ring[j]) * 0.5, 0.0).normalized()
			CageMesh.face(tool, [_at(ring[k], -sink), _at(ring[j], -sink), _at(ring[j], high), _at(ring[k], high)], out)
		return
	# Lo alto: del octógono al cuadrado.
	CageMesh.fill_to_square(tool, outer, side * 0.5, func(p: Vector2) -> Vector3: return _at(p, high), Vector3.UP)
	# Las cuatro paredes de afuera.
	var edge := side * 0.5
	for normal: Vector3 in [Vector3.FORWARD, Vector3.BACK, Vector3.LEFT, Vector3.RIGHT]:
		var across := Vector3(normal.z, 0.0, -normal.x) * edge
		var center := normal * edge
		CageMesh.face(tool, [center - across, center + across, center + across + Vector3.UP * high,
			center - across + Vector3.UP * high], normal)


## LAS CARAS QUE PUEDEN LLEVAR TABLERO (ver FaceBoard), corridas `offset`: las ocho del tablero inclinado y las ocho de
## la pared de adentro del pozo, que baja del tablero al piso.
func boards(offset: Vector3) -> Array[FaceBoard]:
	var out: Array[FaceBoard] = []
	var bottom := low()
	var high := top()
	var inner := _octagon(radius)
	var outer := _octagon(rim())
	for k in 8:
		var j := (k + 1) % 8
		var middle := (inner[k] + inner[j]) * 0.5
		var outward := _at(middle, 0.0).normalized()
		var where := FaceBoard.direction_name(outward)
		# Hacia los ojos, como en `build`: la normal de la cara, hacia arriba.
		var along := Vector3(inner[j].x - inner[k].x, 0.0, inner[j].y - inner[k].y)
		var up_face := (_at((outer[k] + outer[j]) * 0.5, high) - _at(middle, bottom)).cross(along).normalized()
		if up_face.y < 0.0:
			up_face = -up_face
		# Las dos enganchan en la orilla de adentro, la que comparten (el lado del octógono es de celdas enteras,
		# CageShape.pit_apothem): la grilla del tablero sigue en la de la pared. Lo que no entra queda en las puntas del
		# trapecio y en la fila de abajo de la pared.
		var edge := _at(inner[k], bottom) + offset
		out.append(FaceBoard.from_points("tablero " + where, [edge, _at(inner[j], bottom) + offset,
			_at(outer[j], high) + offset, _at(outer[k], high) + offset], up_face, edge))
		out.append(FaceBoard.from_points("pozo " + where, [_at(inner[k], 0.0) + offset, _at(inner[j], 0.0) + offset,
			_at(inner[j], bottom) + offset, edge], -outward, edge))
	return out


## Las caras sueltas, en una malla con su color.
func mesh(color: Color) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	build(tool)
	return CageMesh.commit(tool, color)


## Los vértices del octógono de apotema `apothem`, con una cara mirando al frente (−Z), en (x, z).
static func _octagon(apothem: float) -> PackedVector2Array:
	return CageMesh.polygon(apothem / cos(PI / 8.0), 8, -PI * 0.5 - PI / 8.0)


static func _at(point: Vector2, y: float) -> Vector3:
	return Vector3(point.x, y, point.y)
