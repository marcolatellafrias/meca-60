class_name UnitMesh
extends RefCounted

## UNA MESH DISEÑADA EN EL CUBO UNITARIO — `x`, `y`, `z` de 0 a 1 — sin saber dónde va a ir.
##
## Es la mitad "qué" de la interfaz de colocación: el diseñador arma el objeto acá, en un cubo abstracto, y
## `GridPlacer` lo lleva a una región de celdas de una grilla (un módulo, o la superficie de una pared). Quien diseña la mesh nunca
## piensa en metros, ni en grillas, ni en terreno: solo en proporciones dentro del cubo.
##
## Cada triángulo lleva su color y hacia dónde MIRA (en el espacio del cubo). Se guarda la dirección y no
## el orden de los vértices porque la grilla puede espejar ejes, y el orden solo se puede decidir después,
## en el mundo (lo hace `GridPlacer.place`). Los constructores de acá calculan esa dirección con un punto
## interior del sólido.

const DEFAULT_SEGMENTS := 12

var vertices := PackedVector3Array()
## Tres índices por triángulo.
var indices := PackedInt32Array()
## Un color por triángulo.
var colors := PackedColorArray()
## Hacia dónde mira cada triángulo, en el espacio del cubo.
var facings := PackedVector3Array()
## LOS TRIÁNGULOS SUAVES (1) y los facetados (0), uno por triángulo; más corto que los triángulos, lo que falta es
## facetado. Al colocar la pieza, los vértices de los suaves que caen en el mismo punto del cubo comparten la normal
## (ver GridPlacer._write_on_frame): así se sombrea suave un torneado (ver ClayKit.lathe).
var smooth := PackedByteArray()
## Mientras está prendido, los triángulos que se agregan son suaves.
var smoothing := false
## UNA COORDENADA POR VÉRTICE, opcional: la de una textura, en metros (ver RoofTiles). Vale sólo si tiene una por vértice;
## vacía en casi todo.
var uvs := PackedVector2Array()


func triangle_count() -> int:
	return indices.size() / 3


## Un triángulo mirando hacia afuera de `inside`.
func add_tri(a: Vector3, b: Vector3, c: Vector3, inside: Vector3, color: Color) -> void:
	var centroid := (a + b + c) / 3.0
	var facing := centroid - inside
	if facing.length_squared() <= 0.0:
		facing = (b - a).cross(c - a)
	add_tri_facing(a, b, c, facing, color)


## Un triángulo mirando hacia `facing`.
func add_tri_facing(a: Vector3, b: Vector3, c: Vector3, facing: Vector3, color: Color) -> void:
	var base := vertices.size()
	vertices.append(a); vertices.append(b); vertices.append(c)
	indices.append(base); indices.append(base + 1); indices.append(base + 2)
	colors.append(color)
	facings.append(facing.normalized())
	if smoothing or not smooth.is_empty():
		while smooth.size() < facings.size() - 1:
			smooth.append(0)
		smooth.append(1 if smoothing else 0)


## Si el triángulo `t` es suave (ver `smooth`).
func is_smooth(t: int) -> bool:
	return t < smooth.size() and smooth[t] == 1


## LOS SUAVES DE `source`, AGREGADOS AL FINAL de los de esta, que ya tiene sus triángulos agregados: lo de antes que
## no tenía marca, facetado.
func append_smooth(source: UnitMesh) -> void:
	if source.smooth.is_empty():
		return
	while smooth.size() < triangle_count() - source.triangle_count():
		smooth.append(0)
	smooth.append_array(source.smooth)


func add_quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, inside: Vector3, color: Color) -> void:
	add_tri(a, b, c, inside, color)
	add_tri(a, c, d, inside, color)


func add_quad_facing(a: Vector3, b: Vector3, c: Vector3, d: Vector3, facing: Vector3, color: Color) -> void:
	add_tri_facing(a, b, c, facing, color)
	add_tri_facing(a, c, d, facing, color)


# ── ROTACIÓN ────────────────────────────────────────────────────────────────────────────────────

## La mesh girada `k` cuartos de vuelta alrededor de Y, dentro del cubo. Un cuarto de vuelta lleva el lado
## -z al lado +x, así que una pieza canónica con el exterior en -z (dirección 0) queda con el exterior en
## la dirección `k`. Con `k = 0` devuelve la misma mesh, no una copia.
func rotated(k: int) -> UnitMesh:
	k = posmod(k, 4)
	if k == 0:
		return self
	var out := UnitMesh.new()
	for v: Vector3 in vertices:
		out.vertices.append(_rot_point(v, k))
	out.indices = indices.duplicate()
	out.colors = colors.duplicate()
	for f: Vector3 in facings:
		out.facings.append(_rot_dir(f, k))
	out.uvs = uvs.duplicate()
	out.smooth = smooth.duplicate()
	return out


static func _rot_point(p: Vector3, k: int) -> Vector3:
	var x := p.x
	var z := p.z
	for _i in k:
		var nx := 1.0 - z
		var nz := x
		x = nx
		z = nz
	return Vector3(x, p.y, z)


static func _rot_dir(d: Vector3, k: int) -> Vector3:
	var x := d.x
	var z := d.z
	for _i in k:
		var nx := -z
		var nz := x
		x = nx
		z = nz
	return Vector3(x, d.y, z)


# ── PRIMITIVAS ──────────────────────────────────────────────────────────────────────────────────
# Todas reciben su caja dentro del cubo unitario: `lo` y `hi` de 0 a 1 en los tres ejes.

## Una caja alineada a los ejes del cubo.
func add_box(lo: Vector3, hi: Vector3, color: Color) -> void:
	var inside := (lo + hi) * 0.5
	var p000 := Vector3(lo.x, lo.y, lo.z); var p100 := Vector3(hi.x, lo.y, lo.z)
	var p110 := Vector3(hi.x, lo.y, hi.z); var p010 := Vector3(lo.x, lo.y, hi.z)
	var p001 := Vector3(lo.x, hi.y, lo.z); var p101 := Vector3(hi.x, hi.y, lo.z)
	var p111 := Vector3(hi.x, hi.y, hi.z); var p011 := Vector3(lo.x, hi.y, hi.z)
	add_quad(p000, p100, p110, p010, inside, color)  # abajo
	add_quad(p001, p101, p111, p011, inside, color)  # arriba
	add_quad(p000, p100, p101, p001, inside, color)  # -z
	add_quad(p010, p110, p111, p011, inside, color)  # +z
	add_quad(p000, p010, p011, p001, inside, color)  # -x
	add_quad(p100, p110, p111, p101, inside, color)  # +x


## UN HEXAEDRO CUALQUIERA, por sus ocho esquinas: las cuatro de una cara (`p[0..3]`, en vuelta) y las cuatro de la
## opuesta (`p[4..7]`, cada una enfrente de la de su índice menos 4). Es lo que no puede `add_box`: una caja girada,
## una viga en diagonal, una lona en pendiente.
func add_hexa(p: Array[Vector3], color: Color) -> void:
	var inside := Vector3.ZERO
	for corner in p:
		inside += corner
	inside /= 8.0
	add_quad(p[0], p[1], p[2], p[3], inside, color)
	add_quad(p[4], p[5], p[6], p[7], inside, color)
	for i in 4:
		var j := (i + 1) % 4
		add_quad(p[i], p[j], p[j + 4], p[i + 4], inside, color)


## UNA VIGA de sección cuadrada `thickness` de `a` a `b`, en cualquier dirección.
func add_beam(a: Vector3, b: Vector3, thickness: float, color: Color) -> void:
	var along := b - a
	if along.length_squared() < 1e-10:
		return
	var dir := along.normalized()
	var reference := Vector3.UP if absf(dir.y) < 0.9 else Vector3.RIGHT
	var side := dir.cross(reference).normalized() * thickness * 0.5
	var up := side.cross(dir).normalized() * thickness * 0.5
	add_hexa([a - side - up, a + side - up, a + side + up, a - side + up,
		b - side - up, b + side - up, b + side + up, b - side + up] as Array[Vector3], color)


## UNA PLACA PARADA: de `a` a `b` en el plano (las dos a la misma altura), `height` de alto y `thickness` de espesor,
## centrada en la línea. La hoja de un cartel, una pared fina.
func add_slab(a: Vector3, b: Vector3, height: float, thickness: float, color: Color) -> void:
	var across := (b - a).cross(Vector3.UP).normalized() * thickness * 0.5
	var lift := Vector3.UP * height
	add_hexa([a - across, b - across, b + across, a + across,
		a - across + lift, b - across + lift, b + across + lift, a + across + lift] as Array[Vector3], color)


## LA PIEZA, ESCRITA EN METROS, LLEVADA AL CUBO UNITARIO de la caja `size` con el pivote del cubo en `pivot` (el
## mismo de `build_mesh`): quien diseña en metros —una viga de 35 cm se lee igual en cualquier pieza— y la pieza
## sigue siendo un UnitMesh que el placer estira. Escrita con el pivote en el origen, `build_mesh(size)` la devuelve
## exacta. La dirección hacia donde mira cada triángulo pasa con la escala inversa (ver `build_mesh`).
func to_unit(size: Vector3, pivot := Vector3(0.5, 0.0, 0.5)) -> UnitMesh:
	var out := UnitMesh.new()
	for v: Vector3 in vertices:
		out.vertices.append(Vector3(v.x / size.x, v.y / size.y, v.z / size.z) + pivot)
	out.indices = indices.duplicate()
	out.colors = colors.duplicate()
	for f: Vector3 in facings:
		out.facings.append(Vector3(f.x * size.x, f.y * size.y, f.z * size.z).normalized())
	return out


## La caja de todos los vértices.
func bounds() -> AABB:
	if vertices.is_empty():
		return AABB()
	var out := AABB(vertices[0], Vector3.ZERO)
	for v: Vector3 in vertices:
		out = out.expand(v)
	return out


## LA PIEZA EN METROS LLEVADA AL CUBO JUSTO DE SU CAJA (ver `to_unit`): para lo que se arma primero y se mide después,
## como una palabra de letras. El tamaño que hay que darle al placer es `bounds().size`.
func fitted() -> UnitMesh:
	var box := bounds()
	var size := box.size.max(Vector3.ONE * 0.001)
	return to_unit(size, -box.position / size)


## UN TRONCO DE CONO con el eje en Y: la elipse inscrita en la caja, escalada `bottom` abajo y `top` arriba (1 es la
## caja entera). Con las dos tapas. Lo que se afina de a poco —una chimenea industrial— o se ensancha hacia arriba —un
## tanque—, sin escalones.
func add_frustum(lo: Vector3, hi: Vector3, bottom: float, top: float, color: Color,
		segments: int = DEFAULT_SEGMENTS) -> void:
	var centre := (lo + hi) * 0.5
	var radius := (hi - lo) * 0.5
	var inside := centre
	var low := PackedVector3Array()
	var high := PackedVector3Array()
	for i in segments:
		var a := TAU * float(i) / float(segments)
		low.append(Vector3(centre.x + cos(a) * radius.x * bottom, lo.y, centre.z + sin(a) * radius.z * bottom))
		high.append(Vector3(centre.x + cos(a) * radius.x * top, hi.y, centre.z + sin(a) * radius.z * top))
	var low_centre := Vector3(centre.x, lo.y, centre.z)
	var high_centre := Vector3(centre.x, hi.y, centre.z)
	for i in segments:
		var j := (i + 1) % segments
		add_quad(low[i], low[j], high[j], high[i], inside, color)
		add_tri_facing(low_centre, low[j], low[i], Vector3.DOWN, color)
		add_tri_facing(high_centre, high[i], high[j], Vector3.UP, color)


## Un cilindro con el eje en Y, con la elipse inscrita en la caja.
func add_cylinder(lo: Vector3, hi: Vector3, color: Color, segments: int = DEFAULT_SEGMENTS) -> void:
	_add_cylinder(lo, hi, color, segments, Vector3.AXIS_Y)


## Un cilindro con el eje en Z: lo que sale de un tablero (ver ControlArchetype), donde +z es hacia quien
## lo mira.
func add_cylinder_z(lo: Vector3, hi: Vector3, color: Color, segments: int = DEFAULT_SEGMENTS) -> void:
	_add_cylinder(lo, hi, color, segments, Vector3.AXIS_Z)


## Un cilindro con el eje en X: un disco PARADO a lo largo de una pared, que es lo que es un cartel circular
## volado —en el marco de una fachada `x` es el espesor (ver FacadeProps)—.
func add_cylinder_x(lo: Vector3, hi: Vector3, color: Color, segments: int = DEFAULT_SEGMENTS) -> void:
	_add_cylinder(lo, hi, color, segments, Vector3.AXIS_X)


func _add_cylinder(lo: Vector3, hi: Vector3, color: Color, segments: int, axis: int) -> void:
	var centre := (lo + hi) * 0.5
	var radius := (hi - lo) * 0.5
	var u := (axis + 1) % 3
	var v := (axis + 2) % 3
	var bottom := centre
	bottom[axis] = lo[axis]
	var top := centre
	top[axis] = hi[axis]
	for i in segments:
		var a1 := TAU * float(i) / float(segments)
		var a2 := TAU * float(i + 1) / float(segments)
		var b1 := bottom
		b1[u] += cos(a1) * radius[u]
		b1[v] += sin(a1) * radius[v]
		var b2 := bottom
		b2[u] += cos(a2) * radius[u]
		b2[v] += sin(a2) * radius[v]
		var t1 := b1
		t1[axis] = hi[axis]
		var t2 := b2
		t2[axis] = hi[axis]
		add_quad(b1, b2, t2, t1, centre, color)
		add_tri(bottom, b1, b2, centre, color)
		add_tri(top, t1, t2, centre, color)


## Un anillo con el eje en Z: la elipse inscrita en la caja, hueca hasta `thickness` de su radio.
func add_ring_z(lo: Vector3, hi: Vector3, thickness: float, color: Color, segments: int = DEFAULT_SEGMENTS) -> void:
	_add_ring(lo, hi, thickness, color, segments, Vector3.AXIS_Z)


## Un anillo con el eje en X: el MARCO de un cartel circular volado (ver FacadeProps.disc_unit).
func add_ring_x(lo: Vector3, hi: Vector3, thickness: float, color: Color, segments: int = DEFAULT_SEGMENTS) -> void:
	_add_ring(lo, hi, thickness, color, segments, Vector3.AXIS_X)


## El anillo, con el eje donde se pida. `u` y `v` son los dos ejes del plano del anillo y `axis` su espesor,
## con la misma terna que `_add_cylinder` — para `AXIS_Z` eso da `u` = x y `v` = y, que es exactamente lo que
## esta función hacía cuando era solo la de Z.
func _add_ring(lo: Vector3, hi: Vector3, thickness: float, color: Color, segments: int, axis: int) -> void:
	var centre := (lo + hi) * 0.5
	var u := (axis + 1) % 3
	var v := (axis + 2) % 3
	var outer := Vector2(hi[u] - lo[u], hi[v] - lo[v]) * 0.5
	var inner := outer * (1.0 - thickness)
	var depth := Vector3.ZERO
	depth[axis] = hi[axis] - lo[axis]
	for i in segments:
		var d1 := Vector2.from_angle(TAU * float(i) / float(segments))
		var d2 := Vector2.from_angle(TAU * float(i + 1) / float(segments))
		var o1 := _ring_point(centre, lo, u, v, axis, d1, outer)
		var o2 := _ring_point(centre, lo, u, v, axis, d2, outer)
		var i1 := _ring_point(centre, lo, u, v, axis, d1, inner)
		var i2 := _ring_point(centre, lo, u, v, axis, d2, inner)
		# Cada cara mira desde el centro de su tramo del anillo.
		var mid := (o1 + o2 + i1 + i2) * 0.25 + depth * 0.5
		add_quad(o1, o2, o2 + depth, o1 + depth, mid, color)
		add_quad(i1, i2, i2 + depth, i1 + depth, mid, color)
		add_quad(o1, o2, i2, i1, mid, color)
		add_quad(o1 + depth, o2 + depth, i2 + depth, i1 + depth, mid, color)


static func _ring_point(centre: Vector3, lo: Vector3, u: int, v: int, axis: int, dir: Vector2,
		radius: Vector2) -> Vector3:
	var p := Vector3.ZERO
	p[u] = centre[u] + dir.x * radius.x
	p[v] = centre[v] + dir.y * radius.y
	p[axis] = lo[axis]
	return p


## Media esfera (o casquete) con el eje en Y: la elipse inscrita en la base de la caja, y el alto de la caja
## como alto, en `rings` paralelos hasta la punta. Sin base: se apoya sobre otra cosa.
func add_dome(lo: Vector3, hi: Vector3, color: Color, segments: int = DEFAULT_SEGMENTS, rings: int = 4) -> void:
	var centre := (lo + hi) * 0.5
	var radius := (hi - lo) * 0.5
	var inside := Vector3(centre.x, lo.y, centre.z)
	var apex := Vector3(centre.x, hi.y, centre.z)
	var previous := PackedVector3Array()
	for j in rings + 1:
		var phi := PI * 0.5 * float(j) / float(rings)
		var ring := PackedVector3Array()
		for i in segments:
			var a := TAU * float(i) / float(segments)
			ring.append(Vector3(centre.x + cos(a) * radius.x * cos(phi), lo.y + (hi.y - lo.y) * sin(phi),
				centre.z + sin(a) * radius.z * cos(phi)))
		if j > 0:
			for i in segments:
				var i2 := (i + 1) % segments
				if j == rings:
					add_tri(previous[i], previous[i2], apex, inside, color)
				else:
					add_quad(previous[i], previous[i2], ring[i2], ring[i], inside, color)
		previous = ring


## Una pirámide con la base en la de la caja, alineada a sus ejes, y la punta arriba.
func add_pyramid(lo: Vector3, hi: Vector3, color: Color) -> void:
	var apex := Vector3((lo.x + hi.x) * 0.5, hi.y, (lo.z + hi.z) * 0.5)
	var inside := Vector3(apex.x, lo.y + (hi.y - lo.y) * 0.25, apex.z)
	var base: Array[Vector3] = [Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z),
		Vector3(hi.x, lo.y, hi.z), Vector3(lo.x, lo.y, hi.z)]
	for i in 4:
		add_tri(base[i], base[(i + 1) % 4], apex, inside, color)
	add_quad(base[0], base[1], base[2], base[3], inside, color)


## Un cono con el eje en Y, apoyado en la elipse inscrita en la base de la caja y con la punta arriba.
func add_cone(lo: Vector3, hi: Vector3, color: Color, segments: int = DEFAULT_SEGMENTS) -> void:
	var cx := (lo.x + hi.x) * 0.5
	var cz := (lo.z + hi.z) * 0.5
	var rx := (hi.x - lo.x) * 0.5
	var rz := (hi.z - lo.z) * 0.5
	var inside := Vector3(cx, lo.y + (hi.y - lo.y) * 0.25, cz)
	var apex := Vector3(cx, hi.y, cz)
	var base_centre := Vector3(cx, lo.y, cz)
	for i in segments:
		var a1 := TAU * float(i) / float(segments)
		var a2 := TAU * float(i + 1) / float(segments)
		var b1 := Vector3(cx + cos(a1) * rx, lo.y, cz + sin(a1) * rz)
		var b2 := Vector3(cx + cos(a2) * rx, lo.y, cz + sin(a2) * rz)
		add_tri(b1, b2, apex, inside, color)
		add_tri(base_centre, b1, b2, inside, color)


# ── ENTIDAD ─────────────────────────────────────────────────────────────────────────────────────

## LA MESH COMO ENTIDAD: el cubo escalado a `size` metros con `pivot` en el origen —por defecto centrado
## en `x` y `z` y apoyado en `y = 0`—, con normales planas y el color de cada triángulo. Es lo que se
## instancia en un free placement (ver FreePlacement): la pieza entera, sin deformar, en un transform.
## Indexada, así el índice de piezas la copia como a cualquier otra.
func build_mesh(size: Vector3, pivot := Vector3(0.5, 0.0, 0.5)) -> ArrayMesh:
	var arrays := build_arrays(size, pivot)
	var mesh := ArrayMesh.new()
	if not (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).is_empty():
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## Lo mismo que `build_mesh`, como arreglos de superficie: para sumarla a una malla con otras (ver
## City.place_entity).
func build_arrays(size: Vector3, pivot := Vector3(0.5, 0.0, 0.5)) -> Array:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	# LOS SUAVES (ver `smooth`): la normal de cada vértice, la de sus triángulos suaves en ese punto, sumadas.
	var smooth_sum := {}
	var smooth_at := {}
	for t in triangle_count():
		var a := (vertices[indices[t * 3]] - pivot) * size
		var b := (vertices[indices[t * 3 + 1]] - pivot) * size
		var c := (vertices[indices[t * 3 + 2]] - pivot) * size
		# ⚠ CONVENCIÓN DEL PROYECTO: para el orden (a, b, c) la cara visible tiene normal (c - a) x (b - a).
		# La dirección diseñada en el cubo se lleva al escalado con la inversa de la escala.
		var facing := Vector3(facings[t].x / size.x, facings[t].y / size.y, facings[t].z / size.z)
		var normal := (c - a).cross(b - a)
		if normal.dot(facing) < 0.0:
			var swap := b
			b = c
			c = swap
			normal = -normal
		normal = normal.normalized()
		var base := verts.size()
		for p: Vector3 in [a, b, c]:
			if is_smooth(t):
				smooth_sum[p] = smooth_sum.get(p, Vector3.ZERO) + normal * (c - a).cross(b - a).length()
				smooth_at[base] = p
			verts.append(p)
			normals.append(normal)
			cols.append(colors[t])
			idx.append(base)
			base += 1
	for i: int in smooth_at:
		var sum: Vector3 = smooth_sum[smooth_at[i]]
		if sum.length_squared() > 0.0:
			normals[i] = sum.normalized()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = cols
	arrays[Mesh.ARRAY_INDEX] = idx
	return arrays
