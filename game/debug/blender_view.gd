class_name BlenderView
extends RefCounted

## LA VISTA BLENDER: LOS TRIÁNGULOS DE UNA MALLA ENCIMA DE SUS CARAS, como la vista sólida de Blender con el modo edición.
## Las caras se siguen viendo y encima van TODOS LOS LADOS DE TODOS LOS TRIÁNGULOS, en negro —diagonales incluidas: la
## triangulación tal cual—, y en rojo LAS ARISTAS MARCADAS sharp (ver `MARKED_META`). Es una de las DOS MANERAS DE
## MIRAR UNA MALLA; la otra es el alambre de quads (ver QuadWire), que sólo tiene sentido donde lo armado son quads con
## intención —el personaje en su F1, la cara, las caderas—. Esta sirve para todo: la nave y los personajes, en el juego
## y en el sandbox (ver docs/technical/design-sandbox.md).
##
## VA COMO HIJA DE LA MALLA, en su espacio: si la malla se mueve —una compuerta que se abre— los triángulos van con ella.
## Y SI LA MALLA ESTÁ SKINNEADA, las líneas llevan LOS MISMOS HUESOS Y PESOS y el mismo `Skin` (como QuadWire): la GPU las
## deforma con el cuerpo, así que siguen la pose sin costar nada por cuadro. Corridas apenas por la normal, para no
## pelearse con las caras.
##
## *Fue EdgeOverlay, con un modo más —las aristas como las muestra Blender, sin las diagonales ni lo de adentro de una
## cara plana—, y convivía con el alambre del viewport, que dibujaba todo en líneas y obligaba a esconder la ciudad.
## Quedaron dos vistas: ésta y la de quads.* LO QUE QUEDÓ DE AQUEL MODO es `visible_edges`, que el inspector usa para
## apuntar de a arista (ver HullInspectorSource).

const COMMON := Color(0.05, 0.05, 0.06)
const SHARP := Color(0.0, 0.85, 1.0)
const MARKED := Color(0.95, 0.12, 0.1)
## El meta de una malla con sus aristas MARCADAS a mano, de a pares de puntas (ver RoundedBox.mark_faces_sharp): van en
## rojo.
const MARKED_META := "marked_sharp"
const LIFT := 0.002
## Dos puntos a menos de esto son el mismo vértice.
const WELD := 0.0001
const NODE := "blender"

static var _material: StandardMaterial3D = null


## PONE LA VISTA sobre `view`, si no la tiene ya; nada si su malla no tiene triángulos.
static func show_on(view: MeshInstance3D) -> void:
	if not is_instance_valid(view) or of(view) != null:
		return
	var mesh := view.mesh as ArrayMesh
	if mesh == null:
		return
	var lines := _lines(mesh)
	if lines == null:
		return
	var overlay := MeshInstance3D.new()
	overlay.name = NODE
	overlay.mesh = lines
	overlay.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	overlay.material_override = _line_material()
	# SKINNEADA —la malla trae huesos—: el mismo `Skin` (o ninguno, y Godot lo arma del esqueleto, como al cuerpo) y el
	# mismo esqueleto, que para la hija está un nivel más arriba.
	if lines.surface_get_format(0) & Mesh.ARRAY_FORMAT_BONES:
		overlay.skin = view.skin
		overlay.skeleton = NodePath("../" + String(view.skeleton))
	view.add_child(overlay)


static func clear_from(view: MeshInstance3D) -> void:
	var overlay := of(view)
	if overlay == null:
		return
	view.remove_child(overlay)
	overlay.queue_free()


## La vista de `view`, o null.
static func of(view: MeshInstance3D) -> MeshInstance3D:
	if not is_instance_valid(view):
		return null
	return view.get_node_or_null(NODE) as MeshInstance3D


## LAS LÍNEAS: cada lado de cada triángulo una vez —dos lados con las mismas puntas son el mismo—, corrido por la normal
## de su vértice, con los huesos y los pesos de ese vértice si la malla los tiene. Null si no hay ninguno.
static func _lines(mesh: ArrayMesh) -> ArrayMesh:
	var marked := _marked_pairs(mesh)
	var seen := {}
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var skinned := false
	for surface in mesh.get_surface_count():
		if mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays := mesh.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if points.is_empty():
			continue
		var normals := PackedVector3Array()
		if arrays[Mesh.ARRAY_NORMAL] != null:
			normals = arrays[Mesh.ARRAY_NORMAL]
		var src_bones := PackedInt32Array()
		var src_weights := PackedFloat32Array()
		if arrays[Mesh.ARRAY_BONES] != null:
			src_bones = arrays[Mesh.ARRAY_BONES]
			src_weights = arrays[Mesh.ARRAY_WEIGHTS]
		# Cuántos huesos por vértice: se cuenta, no se asume.
		var per_vertex := src_bones.size() / points.size()
		skinned = skinned or per_vertex > 0
		var index := PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] != null:
			index = arrays[Mesh.ARRAY_INDEX]
		var count := index.size() if not index.is_empty() else points.size()
		var k := 0
		while k + 2 < count:
			var ids: Array[int] = [k, k + 1, k + 2]
			if not index.is_empty():
				ids = [index[k], index[k + 1], index[k + 2]]
			for e in 3:
				var i: int = ids[e]
				var j: int = ids[(e + 1) % 3]
				var pair := _pair(points[i], points[j])
				if pair.is_empty() or seen.has(pair):
					continue
				seen[pair] = true
				var color := MARKED if marked.has(pair) else COMMON
				for at: int in [i, j]:
					var lift := normals[at] if not normals.is_empty() else Vector3.ZERO
					verts.append(points[at] + lift * LIFT)
					colors.append(color)
					for b in per_vertex:
						bones.append(src_bones[at * per_vertex + b])
						weights.append(src_weights[at * per_vertex + b])
			k += 3
	if verts.is_empty():
		return null
	var arrays_out := []
	arrays_out.resize(Mesh.ARRAY_MAX)
	arrays_out[Mesh.ARRAY_VERTEX] = verts
	arrays_out[Mesh.ARRAY_COLOR] = colors
	if skinned:
		arrays_out[Mesh.ARRAY_BONES] = bones
		arrays_out[Mesh.ARRAY_WEIGHTS] = weights
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays_out)
	return out


## Las aristas marcadas de `mesh`, por su par de puntas (ver `_pair`).
static func _marked_pairs(mesh: ArrayMesh) -> Dictionary:
	var out := {}
	var ends: PackedVector3Array = mesh.get_meta(MARKED_META, PackedVector3Array())
	for m in ends.size() / 2:
		out[_pair(ends[m * 2], ends[m * 2 + 1])] = true
	return out


## EL NOMBRE DE UN LADO: sus dos puntas soldadas, en orden. Vacío si son la misma.
static func _pair(a: Vector3, b: Vector3) -> String:
	var ka := _weld(a)
	var kb := _weld(b)
	if ka == kb:
		return ""
	return "%s|%s" % [ka, kb] if str(ka) < str(kb) else "%s|%s" % [kb, ka]


## Sin sombreado y con el color del vértice: las líneas no participan de la luz.
static func _line_material() -> StandardMaterial3D:
	if _material == null:
		_material = StandardMaterial3D.new()
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.vertex_color_use_as_albedo = true
	return _material


# ── LAS ARISTAS COMO LAS MUESTRA BLENDER, para el inspector ─────────────────────────────────────────
## Cada lado de cada triángulo se compara con los lados de LOS OTROS TRIÁNGULOS QUE CAEN SOBRE LA MISMA RECTA y se le
## superponen:
##   · SHARP: alguno de ellos tiene otra normal —el sombreado se corta ahí—.
##   · NO VA, como en Blender: si todos están en su mismo plano —el adentro de una cara plana, sus cortes en la grilla— o
##     si es la DIAGONAL de un cuadrilátero —la arista más larga de los dos triángulos que la comparten—.
##   · COMÚN: todas las demás, y la que no tiene a nadie del otro lado (el borde de la malla).
## POR RECTA Y NO POR PAR DE PUNTAS: una cara y el canto de al lado se parten en la grilla en lugares distintos, así que
## su borde común son tramos distintos de cada lado.

## LAS ARISTAS QUE SE VEN de `mesh`, en su espacio: cada una `{"ends": [a, b], "normals": [na, nb], "sharp": bool,
## "marked": bool}`. Es lo que el inspector deja apuntar (ver HullInspectorSource).
static func visible_edges(mesh: ArrayMesh, auto_sharp := true) -> Array[Dictionary]:
	var sides: Array[Dictionary] = []
	for surface in mesh.get_surface_count():
		if mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			continue
		var arrays := mesh.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var index := PackedInt32Array()
		if arrays[Mesh.ARRAY_INDEX] != null:
			index = arrays[Mesh.ARRAY_INDEX]
		var count := index.size() if not index.is_empty() else points.size()
		var k := 0
		while k + 2 < count:
			var ids: Array[int] = [k, k + 1, k + 2]
			if not index.is_empty():
				ids = [index[k], index[k + 1], index[k + 2]]
			_add_triangle(sides, points, normals, ids, sides.size())
			k += 3
	# Los pares exactos (los mismos dos vértices). SÓLO LO QUE NO TIENE GEMELO va además sobre su recta, a buscar los
	# tramos del otro lado de una unión en T: en una malla bien cosida eso es casi nada, y buscar la recta de cada lado
	# —entre las veintisiete vecinas, con claves de texto— era lo que más costaba.
	var pairs := {}
	for i in sides.size():
		var pair: String = sides[i]["pair"]
		if not pairs.has(pair):
			pairs[pair] = []
		(pairs[pair] as Array).append(i)
	var lines := {}
	for i in sides.size():
		var side := sides[i]
		if (pairs[side["pair"]] as Array).size() == 2:
			continue
		var key: String = _line_key(lines, side)
		(lines[key] as Array).append(i)
		side["line"] = key
	var marked := _marked_pairs(mesh)
	var out: Array[Dictionary] = []
	var drawn := {}
	var lonely: Array = []
	for i in sides.size():
		var side := sides[i]
		if drawn.has(side["pair"]):
			continue
		var group: Array = lines.get(side.get("line", ""), lonely)
		var color := _classify(side, group, sides, pairs)
		if color.a <= 0.0:
			continue
		drawn[side["pair"]] = true
		out.append({"ends": side["ends"], "normals": side["normals"], "sharp": auto_sharp and color == SHARP,
			"marked": marked.has(side["pair"])})
	return out


## Anota los tres lados de un triángulo: sus puntas, la normal en cada una, el plano del triángulo, de qué triángulo es y
## si es su lado más largo.
static func _add_triangle(sides: Array[Dictionary], points: PackedVector3Array, normals: PackedVector3Array,
		ids: Array[int], first: int) -> void:
	var p: Array[Vector3] = [points[ids[0]], points[ids[1]], points[ids[2]]]
	var plane := (p[1] - p[0]).cross(p[2] - p[0])
	if plane.length_squared() < 1e-14:
		return
	plane = plane.normalized()
	var lengths: Array[float] = [p[0].distance_to(p[1]), p[1].distance_to(p[2]), p[2].distance_to(p[0])]
	var longest: float = lengths.max()
	for e in 3:
		var i: int = ids[e]
		var j: int = ids[(e + 1) % 3]
		var a := points[i]
		var b := points[j]
		var pair := _pair(a, b)
		if pair.is_empty():
			continue
		var na := normals[i] if not normals.is_empty() else plane
		var nb := normals[j] if not normals.is_empty() else plane
		sides.append({"ends": [a, b], "normals": [na, nb], "plane": plane, "tri": first,
			"longest": lengths[e] >= longest - 1e-6, "pair": pair})


## LA RECTA DE UN LADO, por su dirección redondeada —con el signo siempre igual— y su pie al milímetro, buscando una ya
## nombrada en los milímetros de al lado. Le anota al lado su tramo sobre
## la recta (`span`).
static func _line_key(lines: Dictionary, side: Dictionary) -> String:
	var a: Vector3 = (side["ends"] as Array)[0]
	var b: Vector3 = (side["ends"] as Array)[1]
	var dir := (b - a).normalized()
	for axis in 3:
		if absf(dir[axis]) > 1e-4:
			if dir[axis] < 0.0:
				dir = -dir
			break
	var snapped_dir: Vector3 = snapped(dir, Vector3.ONE * 0.001)
	var along := snapped_dir.normalized()
	var foot := a - along * a.dot(along)
	var ray := str(Vector3i((snapped_dir * 1000.0).round()))
	var cell := Vector3i((foot / 0.001).round())
	var key := ""
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			for dz in [-1, 0, 1]:
				var near := "%s/%s" % [ray, cell + Vector3i(dx, dy, dz)]
				if key.is_empty() and lines.has(near):
					key = near
	if key.is_empty():
		key = "%s/%s" % [ray, cell]
		lines[key] = []
	var t0 := a.dot(along)
	var t1 := b.dot(along)
	side["span"] = Vector2(minf(t0, t1), maxf(t0, t1))
	return key


## EL COLOR DE UN LADO, o transparente si no se dibuja (ver arriba): contra los lados de otros triángulos que se le
## superponen sobre la misma recta, Y SIEMPRE CONTRA LOS QUE TIENEN SUS MISMOS DOS VÉRTICES. La recta se nombra con la
## dirección redondeada a milésimas, y una componente que cae justo en el borde del redondeo (0,14749 contra 0,14751)
## mandaba los dos triángulos de una misma diagonal a dos rectas distintas: no se veían, y la diagonal se dibujaba en
## algunos cuadriláteros y en otros no.
static func _classify(side: Dictionary, group: Array, sides: Array[Dictionary], pairs: Dictionary) -> Color:
	var span: Vector2 = side.get("span", Vector2.ZERO)
	var ours: Array = side["normals"]
	var normal: Vector3 = ((ours[0] as Vector3) + (ours[1] as Vector3)).normalized()
	var others := 0
	var flat := true
	var twins: Array = pairs[side["pair"]]
	var seen := {}
	for j: int in twins + group:
		if seen.has(j):
			continue
		seen[j] = true
		var other := sides[j]
		if other["tri"] == side["tri"]:
			continue
		if not twins.has(j):
			var reach: Vector2 = other["span"]
			if minf(span.y, reach.y) - maxf(span.x, reach.x) <= 0.0001:
				continue
		others += 1
		var their_ends: Array = other["normals"]
		var theirs: Vector3 = ((their_ends[0] as Vector3) + (their_ends[1] as Vector3)).normalized()
		if normal.dot(theirs) < 0.9999:
			return SHARP
		if (side["plane"] as Vector3).dot(other["plane"]) < 0.9999:
			flat = false
	if others == 0:
		return COMMON
	if flat:
		return Color.TRANSPARENT
	var pair: Array = pairs[side["pair"]]
	if pair.size() == 2 and sides[pair[0]]["longest"] and sides[pair[1]]["longest"]:
		return Color.TRANSPARENT
	return COMMON


static func _weld(p: Vector3) -> Vector3i:
	return Vector3i((p / WELD).round())
