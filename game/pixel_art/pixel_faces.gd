class_name PixelFaces
extends RefCounted

## DETECTA LAS CARAS RECTAS DE UN MODELO. Un `.glb` llega de Blender todo en triángulos, aunque se haya modelado en
## quads: acá se juntan los triángulos VECINOS (comparten una arista) que están EN EL MISMO PLANO, y cada grupo es una
## cara (PixelFace) con su grilla de píxeles a densidad fija. No hace falta nada de Blender: ni UVs ni datos extra.
##
## LO QUE SALE DE ESA REGLA:
##   · Un quad plano vuelve a ser un quad; dos quads vecinos en el mismo plano son UNA cara (mejor: sin costura entre
##     ellos).
##   · Una cara que no es un rectángulo (una L, un trapecio) recibe el rectángulo que la contiene; los píxeles que no
##     toca quedan apagados (`mask`).
##   · Una superficie curva queda en una cara por triángulo o por quad: se pinta, pero de a pedacitos.
##   · La grilla se apoya en la arista del contorno que da el rectángulo más chico, con «arriba» hacia arriba del mundo
##     (en las caras horizontales, hacia el fondo, −Z).
##
## LA GRILLA ARRANCA EN LA ESQUINA de arriba a la izquierda: si la cara mide un número entero de píxeles (modelada sobre
## la grilla), sus bordes caen justo entre píxeles y los de la cara vecina coinciden con los suyos. Si no, la última
## fila o columna queda cortada.

## Dos puntos a menos de esto son el mismo vértice.
const WELD := 0.0005
## Dos triángulos son del mismo plano si sus normales coinciden así (coseno) y uno está a menos de `PLANE` del otro.
const FLAT := 0.9995
const PLANE := 0.0005


## Las caras de un modelo: `triangles` son tres puntos por triángulo (el frente, en sentido horario, como en Godot) y
## `colors` el color de material de cada triángulo. `pixel` es el lado de un píxel, en metros.
static func detect(triangles: PackedVector3Array, colors: PackedColorArray, pixel: float) -> Array[PixelFace]:
	var count := colors.size()
	var ids := {}
	var corner := PackedInt32Array()
	for point in triangles:
		var key := Vector3i((point / WELD).round())
		if not ids.has(key):
			ids[key] = ids.size()
		corner.append(int(ids[key]))
	var normals := PackedVector3Array()
	var edges := {}
	for tri in count:
		var a := triangles[tri * 3]
		var cross := (triangles[tri * 3 + 2] - a).cross(triangles[tri * 3 + 1] - a)
		normals.append(cross.normalized() if cross.length() > 1e-10 else Vector3.ZERO)
		for side in 3:
			var key := _edge(corner, tri, side)
			# Un PackedInt32Array dentro de un Dictionary es una copia: se agrega a la variable y se reasigna.
			var list: PackedInt32Array = edges.get(key, PackedInt32Array())
			list.append(tri)
			edges[key] = list
	var group := PackedInt32Array()
	group.resize(count)
	group.fill(-1)
	var out: Array[PixelFace] = []
	for start in count:
		if group[start] != -1 or normals[start] == Vector3.ZERO:
			continue
		var members := PackedInt32Array([start])
		group[start] = start
		var head := 0
		while head < members.size():
			var tri := members[head]
			head += 1
			for side in 3:
				for other: int in edges[_edge(corner, tri, side)]:
					if group[other] == -1 and normals[other].dot(normals[start]) > FLAT \
							and absf((triangles[other * 3] - triangles[start * 3]).dot(normals[start])) < PLANE:
						group[other] = start
						members.append(other)
		out.append(_face(members, start, triangles, colors, corner, edges, group, normals[start], pixel))
	return out


## Acomoda las caras en un atlas cuadrado (por estantes, las más altas primero), cada una con un borde de un píxel
## alrededor, y devuelve el lado del atlas (una potencia de dos).
static func pack(faces: Array[PixelFace]) -> int:
	var order: Array[PixelFace] = faces.duplicate()
	order.sort_custom(func(a: PixelFace, b: PixelFace) -> bool: return a.height > b.height)
	var side := 32
	while not _place(order, side):
		side *= 2
	return side


static func _place(order: Array[PixelFace], side: int) -> bool:
	var x := 0
	var y := 0
	var shelf := 0
	for face in order:
		if face.width + 2 > side:
			return false
		if x + face.width + 2 > side:
			x = 0
			y += shelf
			shelf = 0
		if y + face.height + 2 > side:
			return false
		face.at = Vector2i(x + 1, y + 1)
		x += face.width + 2
		shelf = maxi(shelf, face.height + 2)
	return true


static func _edge(corner: PackedInt32Array, tri: int, side: int) -> Vector2i:
	var a := corner[tri * 3 + side]
	var b := corner[tri * 3 + (side + 1) % 3]
	return Vector2i(mini(a, b), maxi(a, b))


static func _face(members: PackedInt32Array, start: int, triangles: PackedVector3Array, colors: PackedColorArray,
		corner: PackedInt32Array, edges: Dictionary, group: PackedInt32Array, normal: Vector3, pixel: float) -> PixelFace:
	var face := PixelFace.new()
	face.normal = normal
	for tri in members:
		for side in 3:
			face.triangles.append(triangles[tri * 3 + side])
			# El contorno: las aristas que en este grupo tienen un solo triángulo.
			var shared := 0
			for other: int in edges[_edge(corner, tri, side)]:
				if group[other] == start:
					shared += 1
			if shared == 1:
				face.outline.append(triangles[tri * 3 + side])
				face.outline.append(triangles[tri * 3 + (side + 1) % 3])
		face.colors.append(colors[tri])
	# LOS EJES: la arista del contorno que da el rectángulo más chico.
	var first := face.triangles[0]
	var axis := Vector3.ZERO
	var smallest := INF
	for index in range(0, face.outline.size(), 2):
		var along := face.outline[index + 1] - face.outline[index]
		if along.length() < WELD:
			continue
		along = along.normalized()
		var span := _span(face.triangles, first, along, normal.cross(along))
		var area := span.size.x * span.size.y
		if area < smallest - 1e-9:
			smallest = area
			axis = along
	if axis == Vector3.ZERO:
		axis = normal.cross(Vector3.UP if absf(normal.y) < 0.9 else Vector3.RIGHT).normalized()
	# «ARRIBA»: de los cuatro giros, el que más mira hacia arriba del mundo (o hacia el fondo, en una cara horizontal).
	var wanted := Vector3.UP if absf(normal.y) < 0.9 else Vector3.FORWARD
	var other_axis := normal.cross(axis)
	face.up = axis
	for option: Vector3 in [-axis, other_axis, -other_axis]:
		if option.dot(wanted) > face.up.dot(wanted) + 1e-6:
			face.up = option
	face.right = face.up.cross(normal)
	var box := _span(face.triangles, first, face.right, face.up)
	face.origin = first + face.right * box.position.x + face.up * box.end.y
	face.width = maxi(1, ceili(box.size.x / pixel - 0.02))
	face.height = maxi(1, ceili(box.size.y / pixel - 0.02))
	_rasterize(face, pixel)
	var centroid := Vector3.ZERO
	for point in face.triangles:
		centroid += point
	centroid /= face.triangles.size()
	var direction := Vector3i((normal * 100.0).round())
	var middle := Vector3i((centroid / pixel * 2.0).round())
	face.key = "%d,%d,%d|%d,%d,%d" % [direction.x, direction.y, direction.z, middle.x, middle.y, middle.z]
	return face


## ESTIRA LA GRILLA DE UNA CARA entre sus esquinas (ver PixelFace.stretched), si es un quad o un triángulo: la cuenta de
## píxeles de cada lado sale del más largo de cada par de lados opuestos (en un trapecio, el lado corto queda con
## píxeles más angostos). En un triángulo, la punta es un lado de largo cero: las columnas se juntan en ella. Devuelve
## false (y la deja como estaba) si la cara tiene más esquinas.
static func stretch(face: PixelFace, pixel: float) -> bool:
	var loop := _corners(face)
	if loop.size() < 3 or loop.size() > 4:
		return false
	# En el plano (derecha, arriba), arriba a la izquierda → arriba a la derecha → abajo… es el sentido horario.
	var flat := PackedVector2Array()
	for point in loop:
		flat.append(Vector2((point - face.origin).dot(face.right), (point - face.origin).dot(face.up)))
	var area := 0.0
	for i in flat.size():
		area += flat[i].x * flat[(i + 1) % flat.size()].y - flat[(i + 1) % flat.size()].x * flat[i].y
	if area > 0.0:
		loop.reverse()
		flat.reverse()
	var count := loop.size()
	var corners := PackedVector3Array()
	if count == 4:
		# El lado de arriba: de los que van hacia la derecha, el más alto.
		var top := 0
		var best := -INF
		for i in 4:
			var j := (i + 1) % 4
			if flat[j].x - flat[i].x > 1e-6 and (flat[i].y + flat[j].y) * 0.5 > best:
				best = (flat[i].y + flat[j].y) * 0.5
				top = i
		for i in 4:
			corners.append(loop[(top + i) % 4])
	else:
		# La base: el lado más acostado; la punta, del otro lado.
		var base := 0
		var flattest := -1.0
		for i in 3:
			var along := flat[(i + 1) % 3] - flat[i]
			var lying := absf(along.x) / maxf(along.length(), 1e-9)
			if lying > flattest:
				flattest = lying
				base = i
		var tip := (base + 2) % 3
		if flat[tip].y > (flat[base].y + flat[(base + 1) % 3].y) * 0.5:
			corners = PackedVector3Array([loop[tip], loop[tip], loop[(tip + 1) % 3], loop[(tip + 2) % 3]])
		else:
			corners = PackedVector3Array([loop[base], loop[(base + 1) % 3], loop[tip], loop[tip]])
	face.stretched = true
	face.corners = corners
	var across := maxf(corners[0].distance_to(corners[1]), corners[3].distance_to(corners[2]))
	var down := maxf(corners[0].distance_to(corners[3]), corners[1].distance_to(corners[2]))
	face.width = maxi(1, roundi(across / pixel))
	face.height = maxi(1, roundi(down / pixel))
	face.mask.resize(face.width * face.height)
	face.mask.fill(1)
	face.base.resize(face.width * face.height)
	var corners_flat := PackedVector2Array()
	for point in face.triangles:
		corners_flat.append(face.local(point, pixel))
	for y in face.height:
		for x in face.width:
			var probe := face.local(face.centre(x, y, pixel), pixel)
			var color := face.colors[0]
			for tri in face.colors.size():
				if Geometry2D.point_is_inside_triangle(probe, corners_flat[tri * 3], corners_flat[tri * 3 + 1],
						corners_flat[tri * 3 + 2]):
					color = face.colors[tri]
					break
			face.base[y * face.width + x] = color
	return true


## Las esquinas de una cara, en orden: el contorno encadenado, sin los puntos que están en medio de un lado.
static func _corners(face: PixelFace) -> PackedVector3Array:
	var next := {}
	for index in range(0, face.outline.size(), 2):
		next[Vector3i((face.outline[index] / WELD).round())] = face.outline[index + 1]
	var loop := PackedVector3Array()
	if face.outline.is_empty():
		return loop
	var point := face.outline[0]
	for step in next.size() + 1:
		loop.append(point)
		var key := Vector3i((point / WELD).round())
		if not next.has(key):
			return PackedVector3Array()
		point = next[key]
		if point.distance_to(loop[0]) < WELD:
			break
	if loop.size() != next.size():
		return PackedVector3Array()
	var out := PackedVector3Array()
	for i in loop.size():
		var before := (loop[i] - loop[(i - 1 + loop.size()) % loop.size()]).normalized()
		var after := (loop[(i + 1) % loop.size()] - loop[i]).normalized()
		if before.dot(after) < 0.9999:
			out.append(loop[i])
	return out


## Lo que ocupan los puntos sobre dos ejes, medido desde `from`.
static func _span(points: PackedVector3Array, from: Vector3, right: Vector3, up: Vector3) -> Rect2:
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for point in points:
		var flat := Vector2((point - from).dot(right), (point - from).dot(up))
		low = low.min(flat)
		high = high.max(flat)
	return Rect2(low, high - low)


## Qué píxeles toca la cara y con qué color de base: se prueba el centro de cada píxel y, si cae afuera, sus cuatro
## esquinas apenas metidas hacia adentro (un píxel cortado por el borde igual se ve).
static func _rasterize(face: PixelFace, pixel: float) -> void:
	var flat := PackedVector2Array()
	for point in face.triangles:
		flat.append(face.local(point, pixel))
	face.mask.resize(face.width * face.height)
	face.base.resize(face.width * face.height)
	var samples: Array[Vector2] = [Vector2(0.5, 0.5), Vector2(0.03, 0.03), Vector2(0.97, 0.03), Vector2(0.03, 0.97),
		Vector2(0.97, 0.97)]
	for y in face.height:
		for x in face.width:
			var found := -1
			for sample in samples:
				var probe := Vector2(x, y) + sample
				for tri in face.colors.size():
					if Geometry2D.point_is_inside_triangle(probe, flat[tri * 3], flat[tri * 3 + 1], flat[tri * 3 + 2]):
						found = tri
						break
				if found != -1:
					break
			face.mask[y * face.width + x] = 1 if found != -1 else 0
			face.base[y * face.width + x] = face.colors[maxi(found, 0)]
