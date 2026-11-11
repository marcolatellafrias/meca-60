class_name FaceFeatureMesh

## LA MALLA DE LOS RASGOS FACIALES: los ojos, la boca (ver FaceLayout) y los extra, caminos vectoriales convertidos en
## geometría y APOYADOS SOBRE LA CARA, punto por punto, con el mismo paño que el de la cabeza. UNA sola malla por cara,
## sin sombra.
##
## ── POR QUÉ GEOMETRÍA Y NO TEXTURA, DECAL NI SHADER ────────────────────────────────────────────
## El juego no tiene una sola textura, ni UVs, ni un render target: todo es geometría procedural con
## materiales de color plano. Un rasgo como geometría no trae nada nuevo, es nítido a cualquier distancia
## —no hay mipmap que ensucie justo los ojos de lejos—, sigue la cara exacto porque cada punto del contorno
## se apoya solo, y se apaga de un LOD sin más que no construir la malla. Las tres alternativas se miraron:
## la textura pide un pipeline entero (viewport, UVs, atlas) y ensucia a distancia; los decals proyectan en
## espacio mundo, así que pintan cualquier cosa que entre en su caja y cuestan por píxel con tope por
## cluster, que es lo contrario de lo que pide una ciudad con peatones; y el shader vuelve cada rasgo código
## en vez de datos, justo cuando lo que se quiere es un editor que escriba datos.
##
## ── SIN FORMAS ──────────────────────────────────────────────────────────────────────────────────
## Hasta el 15/10/2026 los ojos cambiaban de forma y la boca de pose como blend shapes de esta malla, para parpadear y
## hablar; se borraron con los gestos viejos (ver FaceLayout). Ahora cada cara es su malla tal cual.
##
## ── LAS CAPAS DE PROFUNDIDAD ────────────────────────────────────────────────────────────────────
## Lo que se pisa va en capas, cada una un pelo más afuera de la cara a lo largo de la normal (ver `lift_share`): los
## rellenos abajo, los que van encima (`FaceFeature.on_top`: la línea de la boca sobre los labios) y los trazos arriba.
##
## ── Y EL CONTEO ES DE PLANTILLA ─────────────────────────────────────────────────────────────────
## Los pasos por segmento son fijos, así que dos caras con los mismos rasgos tienen la MISMA malla de rasgos — el mismo
## invariante que el cuerpo (ver ProceduralBodyUtil).

## CUÁNTOS PASOS SE MUESTREA CADA SEGMENTO de un camino. Ocho: un círculo de cuatro cúbicas sale de 32 lados, y en un
## rasgo de 1 cm la diferencia contra el círculo exacto es de una décima de milímetro.
const CURVE_STEPS := 8

## CUÁNTO SE LEVANTA LA TINTA DE LA CARA, en fracción del alto de la cabeza y a lo largo de la NORMAL: lo que la
## separa de la superficie en la capa de abajo. Tres por mil del alto, 0,6 mm en una cabeza de 20 cm: alcanza para no
## pelear con la cara por el mismo píxel, y es relativo, así que se ve igual en cualquier tamaño y con la lupa.
const INK_LIFT_SHARE := 0.003
## CUÁNDO UN TRIÁNGULO DEL RELLENO NO TIENE ÁREA (ver `_with_area`): su alto, en fracción de su lado más largo. Es una
## proporción y no un área para que valga en cualquier tamaño, y porque los puntos son de 32 bits: alineados dan ruido de
## 1e-6 en esta cuenta, y el más flaco de verdad —tres lados seguidos del círculo de un ojo— da 0,05.
const FLAT_RATIO := 1e-4

## LAS CAPAS, de la cara para afuera: los rellenos, los rellenos que van encima y los trazos.
const LAYER_FILL := 0
const LAYER_DETAIL := 1
const LAYER_STROKE := 2
## Cuánto más flota cada capa que la de abajo, en fracción de `INK_LIFT_SHARE`.
const LAYER_STEP := 0.3



## CUÁNTO FLOTA UNA CAPA, en fracción del alto de la cabeza.
static func lift_share(layer: int) -> float:
	return INK_LIFT_SHARE * (1.0 + LAYER_STEP * float(layer))


## LA MALLA DE TODOS LOS RASGOS DE UNA CARA, o null si no hay nada que dibujar.
static func build(features: Array, cloth: FacePlane.Cloth, bone: int) -> ArrayMesh:
	var surface := arrays(features, cloth, bone)
	if surface.is_empty():
		return null
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface)
	return mesh


## LO MISMO QUE `build` PERO SIN ARMAR LA MALLA: los arrays que se le pasan a `add_surface_from_arrays`, o vacío. Lo usa
## el test de los rasgos, que los mira sin pedírselos de vuelta a la malla.
static func arrays(features: Array, cloth: FacePlane.Cloth, bone: int) -> Array:
	if cloth == null or features.is_empty():
		return []
	var pieces: Array[_Piece] = []
	for each in features:
		var feature := each as FaceFeature
		if feature != null:
			pieces.append_array(_path(feature, cloth))
	return _Assembly.new(cloth, bone).collect(pieces)


## ── UN CAMINO ───────────────────────────────────────────────────────────────────────────────────
## El relleno, triangulado plano (`Geometry2D` resuelve cóncavos, que es lo que un rasgo dibujado a mano va a tener), y
## el contorno, una cinta de ancho constante.
static func _path(feature: FaceFeature, cloth: FacePlane.Cloth) -> Array[_Piece]:
	var out: Array[_Piece] = []
	if feature.nodes.size() < 6:
		return out
	var flat := _tessellate(feature.curve(), feature.small_polygon)
	if flat.size() < 2:
		return out
	for side in ([1.0, -1.0] if feature.mirror else [1.0]):
		var placed := _Placer.new(feature, cloth, side).all(flat)
		if feature.filled and feature.closed and placed.size() >= 4:
			var ring := placed.slice(0, placed.size() - 1)
			var fill := _Piece.new(LAYER_DETAIL if feature.on_top else LAYER_FILL)
			fill.points = ring
			fill.finish(_with_area(ring, Geometry2D.triangulate_polygon(ring)), feature.fill_color)
			out.append(fill)
		var half: float = cloth.height * feature.stroke * 0.5
		if half > 0.0:
			var stroke := _Piece.new(LAYER_STROKE)
			var middle := PackedVector2Array()
			var offsets := PackedVector2Array()
			for i in placed.size():
				var across := _across(placed, i, feature.closed) * half
				middle.append_array(PackedVector2Array([placed[i], placed[i]]))
				offsets.append_array(PackedVector2Array([across, -across]))
			stroke.points = middle
			stroke.moved = offsets
			stroke.finish(_ribbon_index(placed.size(), false), feature.stroke_color)
			out.append(stroke)
	return out


## SÓLO LOS TRIÁNGULOS CON ÁREA EN EL PLANO. Un lado recto se tesela en puntos alineados (ver `_tessellate`), y
## `Geometry2D` los triangula también a ellos: planos no se ven, pero apoyados en la cara curva quedan parados de canto,
## con área y mirando al costado. Pasó en la boca, en el medio, donde se tocan dos tramos (face_features: 4 dados vuelta).
static func _with_area(points: PackedVector2Array, index: PackedInt32Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	for t in index.size() / 3:
		var a := points[index[t * 3]]
		var b := points[index[t * 3 + 1]]
		var c := points[index[t * 3 + 2]]
		var longest := maxf((b - a).length_squared(), maxf((c - b).length_squared(), (a - c).length_squared()))
		if absf((b - a).cross(c - a)) > FLAT_RATIO * longest:
			out.append_array(PackedInt32Array([index[t * 3], index[t * 3 + 1], index[t * 3 + 2]]))
	return out


## HACIA DÓNDE VA EL CONTORNO DE UN CAMINO en un punto, su perpendicular: el promedio de los dos segmentos que lo tocan,
## así la cinta no pega un escalón al cruzar un nodo. En un camino cerrado el último punto ES el primero.
static func _across(points: PackedVector2Array, i: int, closed: bool) -> Vector2:
	var count := points.size()
	var before: Vector2 = points[i] - points[maxi(i - 1, 0)]
	var after: Vector2 = points[mini(i + 1, count - 1)] - points[i]
	if closed:
		if i == 0:
			before = points[0] - points[count - 2]
		if i == count - 1:
			after = points[1] - points[count - 1]
	var sum := before + after
	if sum.length_squared() < 1e-12:
		sum = after if after.length_squared() > 1e-12 else Vector2.RIGHT
	sum = sum.normalized()
	return Vector2(-sum.y, sum.x)


## Los triángulos de una cinta de `count` puntos (dos vértices cada uno), cerrada o no.
static func _ribbon_index(count: int, closed: bool) -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in (count if closed else count - 1):
		var a: int = i * 2
		var b: int = ((i + 1) % count) * 2
		out.append_array(PackedInt32Array([a, a + 1, b, a + 1, b + 1, b]))
	return out


## ── EL CAMINO MUESTREADO, EN SU PROPIA CAJA ─────────────────────────────────────────────────────
## Cada segmento en `CURVE_STEPS` pasos. La curva de un camino cerrado ya trae el nodo que cierra (ver
## FaceFeature.curve), así que acá no hay caso especial: el último punto termina siendo el primero.
static func _tessellate(path: Curve2D, straight_whole := false) -> PackedVector2Array:
	var out := PackedVector2Array()
	var segments: int = path.point_count - 1
	if segments < 1:
		return out
	for s in segments:
		# EN UN POLÍGONO CHICO (ver FaceFeature.small_polygon), UN TRAMO RECTO VA ENTERO, sin partir: sus pasos caerían todos
		# sobre la misma recta, y un polígono con puntos alineados se triangula distinto según el tamaño —triángulos chatos que
		# a veces se descartan—, así que la malla cambiaba de conteo de una cara a otra (pasó con las puntas de las ojeras).
		# Un rasgo grande sí los parte: así su borde se apoya en la cara curva.
		if straight_whole and path.get_point_out(s) == Vector2.ZERO and path.get_point_in(s + 1) == Vector2.ZERO:
			out.append(path.get_point_position(s))
			continue
		for k in CURVE_STEPS:
			out.append(path.sample(s, float(k) / float(CURVE_STEPS)))
	out.append(path.get_point_position(segments))
	return out


## EL MATERIAL DE LA TINTA: color por vértice y el mismo material que la piel (ver CharacterBodyVisual.body_material), así
## los rasgos reciben la luz y la sombra como la cara en la que están. Los colores van a lineal al armar (ver `arrays`).
static func ink_material() -> Material:
	return CharacterBodyVisual.body_material(Color.WHITE, true)


## ── DE LA CAJA DEL RASGO A LOS METROS DE LA CARA ────────────────────────────────────────────────
## El rasgo dice dónde va (`at_u`, fracción del medio-ancho del frente a esa altura; `at_v`, del alto) y de qué tamaño
## (fracciones del alto en los dos ejes); esto pasa un punto de su caja, de −0,5 a 0,5, a metros de la cara. Del otro
## lado (`side` −1) es el espejo exacto.
class _Placer:
	var _x: float
	var _y: float
	var _sx: float
	var _sy: float
	var _side: float

	func _init(feature: FaceFeature, cloth: FacePlane.Cloth, side: float) -> void:
		_side = side
		_x = side * feature.at_u * cloth.reach(feature.at_v)
		_y = feature.at_v * cloth.height
		_sx = feature.size_x * cloth.height
		_sy = feature.size_y * cloth.height

	func one(p: Vector2) -> Vector2:
		return Vector2(_x + _side * p.x * _sx, _y + p.y * _sy)

	func all(points: PackedVector2Array) -> PackedVector2Array:
		var out := PackedVector2Array()
		out.resize(points.size())
		for i in points.size():
			out[i] = one(points[i])
		return out


## ── UNA PIEZA: un relleno o una cinta ───────────────────────────────────────────────────────────
## Sus puntos en metros de la cara, un color y una capa para todos, y sus triángulos. Para qué lado mira cada triángulo
## no se escribe: se decide al apoyarla, contra la normal de la cara.
class _Piece:
	var layer: int
	var points := PackedVector2Array()
	## Lo que cada vértice se corre de su punto, por la superficie, en metros de la cara; vacío si nada se corre. Es lo
	## que usa una cinta: sus dos vértices se apoyan en el punto del recorrido —que ya apoyó el relleno que bordea— y se
	## corren a cada lado por el plano tangente, en vez de apoyarse cada uno por su cuenta.
	var moved := PackedVector2Array()
	var index := PackedInt32Array()
	var color := Color.WHITE

	func _init(new_layer: int) -> void:
		layer = new_layer

	func finish(new_index: PackedInt32Array, new_color: Color) -> void:
		index = new_index
		color = new_color


## ── EL ARMADO: apoyar cada pieza en la cara y juntarlas en una malla ────────────────────────────
class _Assembly:
	var _cloth: FacePlane.Cloth
	var _bone: int
	var _rest: Transform3D
	## Lo ya apoyado, por `(|x|, v)`: la cara es simétrica, así que un ojo y su espejo se apoyan una sola vez.
	var _memo := {}

	func _init(cloth: FacePlane.Cloth, bone: int) -> void:
		_cloth = cloth
		_bone = bone
		_rest = cloth.rest

	func collect(pieces: Array[_Piece]) -> Array:
		var verts := PackedVector3Array()
		var normals := PackedVector3Array()
		var colors := PackedColorArray()
		var index := PackedInt32Array()
		for piece in pieces:
			if piece.points.is_empty() or piece.index.is_empty():
				continue
			var lift: float = _cloth.height * FaceFeatureMesh.lift_share(piece.layer)
			var placed: Array = _wrap(piece.points, piece.moved, lift)
			var piece_verts: PackedVector3Array = placed[0]
			var piece_normals: PackedVector3Array = placed[1]
			var start := verts.size()
			verts.append_array(piece_verts)
			normals.append_array(piece_normals)
			for _i in piece_verts.size():
				# EN LINEAL: el shader de los personajes lee así el color de los vértices (ver `ink_material`).
				colors.append(piece.color.srgb_to_linear())
			for t in piece.index.size() / 3:
				var a: int = piece.index[t * 3]
				var b: int = piece.index[t * 3 + 1]
				var c: int = piece.index[t * 3 + 2]
				# ⚠ EL BOBINADO SALE DE LA NORMAL, igual que en el cuerpo (ver GridPart._add_face), y en Godot el frente
				# de una cara es el sentido HORARIO: bien orientado, `(b−a)×(c−a)` apunta CONTRA la normal. Escrito a
				# mano se rompe en el primer espejo —espejar da vuelta todos los triángulos—.
				var outward: Vector3 = piece_normals[a] + piece_normals[b] + piece_normals[c]
				var geometric: Vector3 = (piece_verts[b] - piece_verts[a]).cross(piece_verts[c] - piece_verts[a])
				if geometric.dot(outward) <= 0.0:
					index.append_array(PackedInt32Array([start + a, start + b, start + c]))
				else:
					index.append_array(PackedInt32Array([start + a, start + c, start + b]))
		if index.is_empty():
			return []
		var bones := PackedInt32Array()
		var weights := PackedFloat32Array()
		bones.resize(verts.size() * 4)
		weights.resize(verts.size() * 4)
		# RÍGIDO AL HUESO DE LA CABEZA, igual que el paño: un rasgo no se deforma por su cuenta, se mueve con la cabeza.
		for i in verts.size():
			bones[i * 4] = _bone
			weights[i * 4] = 1.0
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_NORMAL] = normals
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		arrays[Mesh.ARRAY_INDEX] = index
		return arrays

	## Una pieza apoyada en la cara: `[posiciones, normales]` en el espacio del esqueleto, levantadas `lift` por la
	## normal.
	##
	## Un vértice con corrimiento (una cinta) se corre desde su punto por el PLANO TANGENTE: la cara en el espacio de la
	## cabeza es `(x, y, z(x, y))`, así que correrse `(dx, dy)` sube o baja `−(nx·dx + ny·dy)/nz`. Para el medio ancho de
	## un trazo, un par de milímetros, la diferencia con apoyarlo de nuevo es de centésimas de milímetro.
	func _wrap(points: PackedVector2Array, moved: PackedVector2Array, lift: float) -> Array:
		var verts := PackedVector3Array()
		var normals := PackedVector3Array()
		verts.resize(points.size())
		normals.resize(points.size())
		var height: float = maxf(_cloth.height, 1e-5)
		for i in points.size():
			var p: Vector2 = points[i]
			var key := Vector2(absf(p.x), p.y)
			var found: Array = _memo.get(key, [])
			if found.is_empty():
				found = _cloth.local_face(key.x, key.y / height)
				_memo[key] = found
			var at: Vector3 = found[0]
			var normal: Vector3 = found[1]
			if p.x < 0.0:
				at.x = -at.x
				normal.x = -normal.x
			if not moved.is_empty():
				var o: Vector2 = moved[i]
				var nz: float = normal.z if absf(normal.z) > 0.2 else signf(normal.z + 1e-9) * 0.2
				at += Vector3(o.x, o.y, -(normal.x * o.x + normal.y * o.y) / nz)
			normal = (_rest.basis * normal).normalized()
			verts[i] = _rest * at + normal * lift
			normals[i] = normal
		return [verts, normals]
