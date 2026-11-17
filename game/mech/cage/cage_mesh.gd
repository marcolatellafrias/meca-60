class_name CageMesh
extends RefCounted

## LAS MALLAS DE CARAS PROPIAS DE LA MECA JAULA (el usuario, 16/11/2026: «haría todo con mallas… con caras individuales…
## en vez de hacer todo con planos con espesor pegados entre sí que genera espacios huecos y ángulos raros»). Todo se
## agrega a un SurfaceTool con `face` (una cara plana convexa con su normal).


## UNA CARA PLANA CONVEXA, en abanico, con su normal; el orden se da vuelta si hace falta (el frente es horario).
static func face(tool: SurfaceTool, points: Array, normal: Vector3) -> void:
	var a: Vector3 = points[0]
	var b: Vector3 = points[1]
	var c: Vector3 = points[2]
	var flip := (b - a).cross(c - a).dot(normal) > 0.0
	for i in range(1, points.size() - 1):
		var tri: Array = [points[0], points[i], points[i + 1]]
		if flip:
			tri = [points[0], points[i + 1], points[i]]
		for vertex: Vector3 in tri:
			tool.set_normal(normal)
			tool.add_vertex(vertex)


## DEL CONTORNO CONVEXO `inner` (alrededor del origen) AL CUADRADO de mitad `edge`: el anillo que los une (ver
## `fill_to_rect`).
static func fill_to_square(tool: SurfaceTool, inner: PackedVector2Array, edge: float, place: Callable,
		normal: Vector3) -> void:
	fill_to_rect(tool, inner, Vector2(-edge, -edge), Vector2(edge, edge), place, normal)


## DEL CONTORNO CONVEXO `inner` (alrededor del origen) AL RECTÁNGULO de `low` a `high`: el anillo que los une, cara por
## cara, por los rayos desde el origen (las que cruzan una esquina, con la esquina). `place` lleva un punto del plano al
## espacio.
static func fill_to_rect(tool: SurfaceTool, inner: PackedVector2Array, low: Vector2, high: Vector2, place: Callable,
		normal: Vector3) -> void:
	for k in inner.size():
		var j := (k + 1) % inner.size()
		var reach_k := to_rect(inner[k], low, high)
		var reach_j := to_rect(inner[j], low, high)
		var points: Array = [place.call(inner[k]), place.call(reach_k)]
		var side_k := _rect_side(reach_k, low, high)
		var side_j := _rect_side(reach_j, low, high)
		if side_k != side_j:
			var on_x := side_k if side_k < 2 else side_j
			var on_y := side_k if side_k >= 2 else side_j
			points.append(place.call(Vector2(high.x if on_x == 0 else low.x, high.y if on_y == 2 else low.y)))
		points.append_array([place.call(reach_j), place.call(inner[j])])
		face(tool, points, normal)


## Donde el rayo del origen por `point` toca el borde del rectángulo de `low` a `high`.
static func to_rect(point: Vector2, low: Vector2, high: Vector2) -> Vector2:
	var scale := INF
	if point.x > 0.0:
		scale = minf(scale, high.x / point.x)
	elif point.x < 0.0:
		scale = minf(scale, low.x / point.x)
	if point.y > 0.0:
		scale = minf(scale, high.y / point.y)
	elif point.y < 0.0:
		scale = minf(scale, low.y / point.y)
	return point * scale


## Qué lado del rectángulo toca un punto de su borde: 0 x alto, 1 x bajo, 2 y alto, 3 y bajo.
static func _rect_side(point: Vector2, low: Vector2, high: Vector2) -> int:
	var gaps := [absf(point.x - high.x), absf(point.x - low.x), absf(point.y - high.y), absf(point.y - low.y)]
	var best := 0
	for i in 4:
		if gaps[i] < gaps[best]:
			best = i
	return best


## Donde el rayo del centro por `point` toca el cuadrado de mitad `edge`.
static func to_square(point: Vector2, edge: float) -> Vector2:
	return to_rect(point, Vector2(-edge, -edge), Vector2(edge, edge))


## Un polígono regular de `sides` lados y radio `radius` (a los vértices), empezando en `phase`.
static func polygon(radius: float, sides: int, phase := 0.0) -> PackedVector2Array:
	var points := PackedVector2Array()
	for k in sides:
		var a := phase + TAU * k / sides
		points.append(Vector2(cos(a), sin(a)) * radius)
	return points


## UN PRISMA DERECHO: el contorno convexo `outline` (x, z), de `from` a `to` de alto, con su tapa de arriba.
static func prism(tool: SurfaceTool, outline: PackedVector2Array, from: float, to: float) -> void:
	var low: Array = []
	var high: Array = []
	var center := Vector2.ZERO
	for point in outline:
		low.append(Vector3(point.x, from, point.y))
		high.append(Vector3(point.x, to, point.y))
		center += point / outline.size()
	face(tool, high, Vector3.UP)
	for i in outline.size():
		var j := (i + 1) % outline.size()
		var out := (outline[i] + outline[j]) * 0.5 - center
		face(tool, [low[i], low[j], high[j], high[i]], Vector3(out.x, 0.0, out.y).normalized())


## UNA FAJA DE ESFERA alrededor del eje del frente (−Z): de `from` a `to` radianes desde el frente (0, la punta de
## adelante; PI/2, el ecuador; PI, la de atrás). `inward`: las normales hacia el centro (vista de adentro).
static func sphere_band(tool: SurfaceTool, center: Vector3, radius: float, from: float, to: float, inward: bool,
		rings := 12, segments := 40) -> void:
	for r in rings:
		var a0 := lerpf(from, to, float(r) / rings)
		var a1 := lerpf(from, to, float(r + 1) / rings)
		for k in segments:
			var corners: Array = []
			for corner: Vector2 in [Vector2(a0, k), Vector2(a0, k + 1), Vector2(a1, k + 1), Vector2(a1, k)]:
				var turn := TAU * corner.y / segments
				corners.append(Vector3(sin(corner.x) * cos(turn), sin(corner.x) * sin(turn), -cos(corner.x)))
			var middle: Vector3 = (corners[0] + corners[1] + corners[2] + corners[3]).normalized()
			var points: Array = []
			for direction: Vector3 in corners:
				points.append(center + direction * radius)
			# En una punta, dos esquinas son el mismo punto: un triángulo.
			if is_zero_approx(sin(a0)):
				points = [points[0], points[2], points[3]]
			elif is_zero_approx(sin(a1)):
				points = [points[0], points[1], points[2]]
			face(tool, points, -middle if inward else middle)


## UN ANILLO DERECHO (un tubo corto de paredes chatas): entre los radios `inner` y `outer` alrededor de `center`, a lo
## largo de −Z desde `center` hasta `depth` adelante. Las dos caras planas, la de afuera y la de adentro. `sides`, los
## tramos de la vuelta.
static func ring(tool: SurfaceTool, center: Vector3, inner: float, outer: float, depth: float, sides := 40) -> void:
	var back := center
	var front := center + Vector3.FORWARD * depth
	for k in sides:
		var a := TAU * k / sides
		var b := TAU * (k + 1) / sides
		var da := Vector3(cos(a), sin(a), 0.0)
		var db := Vector3(cos(b), sin(b), 0.0)
		var out := ((da + db) * 0.5).normalized()
		face(tool, [front + da * inner, front + db * inner, front + db * outer, front + da * outer], Vector3.FORWARD)
		face(tool, [back + da * inner, back + db * inner, back + db * outer, back + da * outer], Vector3.BACK)
		face(tool, [back + da * outer, back + db * outer, front + db * outer, front + da * outer], out)
		face(tool, [back + da * inner, back + db * inner, front + db * inner, front + da * inner], -out)


## LAS CARAS DEL ROMBICUBOCTAEDRO (el cubo con las aristas y las esquinas cortadas: visto de frente, de costado o de arriba,
## un octógono) con apotema 1 en sus caras cuadradas: [{"normal", "points" (en orden), "square" (cuadrada o triangular)}].
## Las 6 de los ejes y las 12 de las aristas son cuadradas; las 8 de las esquinas, triangulares.
static func faceted_sphere() -> Array[Dictionary]:
	var k := 1.0 + sqrt(2.0)
	var vertices: Array[Vector3] = []
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			for c: float in [-k, k]:
				vertices.append(Vector3(a, b, c) / k)
				vertices.append(Vector3(a, c, b) / k)
				vertices.append(Vector3(c, a, b) / k)
	var normals: Array[Vector3] = []
	for axis: Vector3 in [Vector3.RIGHT, Vector3.UP, Vector3.BACK]:
		normals.append_array([axis, -axis])
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			normals.append_array([Vector3(a, b, 0.0).normalized(), Vector3(a, 0.0, b).normalized(),
				Vector3(0.0, a, b).normalized()])
			for c: float in [-1.0, 1.0]:
				normals.append(Vector3(a, b, c).normalized())
	var faces: Array[Dictionary] = []
	for normal in normals:
		var best := -INF
		for v in vertices:
			best = maxf(best, v.dot(normal))
		var on: Array[Vector3] = []
		for v in vertices:
			if v.dot(normal) > best - 0.001:
				on.append(v)
		var middle := Vector3.ZERO
		for v in on:
			middle += v / on.size()
		var u := (on[0] - middle).normalized()
		var w := normal.cross(u)
		on.sort_custom(func(p: Vector3, q: Vector3) -> bool:
			return atan2((p - middle).dot(w), (p - middle).dot(u)) < atan2((q - middle).dot(w), (q - middle).dot(u)))
		faces.append({"normal": normal, "points": on, "square": on.size() == 4})
	return faces


## CORTA UN POLÍGONO CONVEXO por el plano z = `cut`: [la parte de adelante (z < cut), la de atrás]; cualquiera puede quedar
## vacía.
static func split_by_z(points: Array, cut: float) -> Array:
	var front: Array = []
	var back: Array = []
	for i in points.size():
		var a: Vector3 = points[i]
		var b: Vector3 = points[(i + 1) % points.size()]
		if a.z < cut:
			front.append(a)
		else:
			back.append(a)
		if (a.z < cut) != (b.z < cut):
			var cross := a.lerp(b, (cut - a.z) / (b.z - a.z))
			front.append(cross)
			back.append(cross)
	return [front, back]


## UNA CARA con normales de esfera alrededor de `center` (se ve lisa aunque sea plana).
static func smooth_face(tool: SurfaceTool, points: Array, center: Vector3, normal: Vector3) -> void:
	var a: Vector3 = points[0]
	var b: Vector3 = points[1]
	var c: Vector3 = points[2]
	var flip := (b - a).cross(c - a).dot(normal) > 0.0
	for i in range(1, points.size() - 1):
		var tri: Array = [points[0], points[i], points[i + 1]]
		if flip:
			tri = [points[0], points[i + 1], points[i]]
		for vertex: Vector3 in tri:
			tool.set_normal((vertex - center).normalized())
			tool.add_vertex(vertex)


## UN ARO CON LA FORMA DE `outline` (convexo, alrededor de `center`, en el plano XY): de ese contorno hacia afuera `width`,
## a lo largo de −Z desde `center` hasta `depth` adelante.
static func outline_ring(tool: SurfaceTool, center: Vector3, outline: PackedVector2Array, width: float, depth: float) -> void:
	var front := Vector3.FORWARD * depth
	for k in outline.size():
		var a := outline[k]
		var b := outline[(k + 1) % outline.size()]
		var out_a := a + a.normalized() * width
		var out_b := b + b.normalized() * width
		var ia := center + Vector3(a.x, a.y, 0.0)
		var ib := center + Vector3(b.x, b.y, 0.0)
		var oa := center + Vector3(out_a.x, out_a.y, 0.0)
		var ob := center + Vector3(out_b.x, out_b.y, 0.0)
		var side := (a + b).normalized()
		var out := Vector3(side.x, side.y, 0.0)
		face(tool, [ia + front, ib + front, ob + front, oa + front], Vector3.FORWARD)
		face(tool, [ia, ib, ob, oa], Vector3.BACK)
		face(tool, [oa, ob, ob + front, oa + front], out)
		face(tool, [ia, ib, ib + front, ia + front], -out)


## El material de arcilla de la jaula, para una malla terminada.
static func commit(tool: SurfaceTool, color: Color) -> ArrayMesh:
	var mesh := tool.commit()
	mesh.surface_set_material(0, Clay.material(color))
	return mesh
