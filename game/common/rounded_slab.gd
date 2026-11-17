class_name RoundedSlab

## UNA PLACA DE ESQUINAS REDONDEADAS: un rectángulo con espesor, con las cuatro esquinas redondeadas o solo las dos de
## arriba (una pestaña), y un MARCO de esquinas redondeadas (`frame`). Centrados en el origen, la cara de adelante a +Z. Lo
## usan las tarjetas perforadas y las superficies de tablero.


## La placa de `size` (ancho, alto) y `thick` de espesor, con esquinas de `radius`; con `top_only`, abajo quedan rectas.
static func mesh(size: Vector2, radius: float, thick: float, top_only := false, steps := 4) -> ArrayMesh:
	var outline := _outline(size, minf(radius, minf(size.x, size.y) * 0.5), top_only, steps)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var front := thick * 0.5
	var n := outline.size()
	# Las dos caras: un abanico desde el centro (el contorno es convexo).
	for face: float in [1.0, -1.0]:
		for i in n:
			var a := Vector3(0.0, 0.0, front * face)
			var b := Vector3(outline[i].x, outline[i].y, front * face)
			var c := Vector3(outline[(i + 1) % n].x, outline[(i + 1) % n].y, front * face)
			_tri(st, a, b, c, Vector3(0.0, 0.0, face))
	# El canto, tramo por tramo.
	for i in n:
		var p := outline[i]
		var q := outline[(i + 1) % n]
		var out := Vector3(q.y - p.y, p.x - q.x, 0.0).normalized()
		if out.dot(Vector3(p.x + q.x, p.y + q.y, 0.0)) < 0.0:
			out = -out
		var p0 := Vector3(p.x, p.y, -front)
		var p1 := Vector3(p.x, p.y, front)
		var q0 := Vector3(q.x, q.y, -front)
		var q1 := Vector3(q.x, q.y, front)
		_tri(st, p0, p1, q1, out)
		_tri(st, p0, q1, q0, out)
	return st.commit()


## UN MARCO de esquinas redondeadas: el anillo entre el contorno de afuera (`outer`, radio `outer_r`) y el de adentro
## (`inner`, radio `inner_r`), de `thick` de espesor, centrado en el origen; el hueco puede ir corrido del centro
## (`inner_at`). Con su cara de adelante y la de atrás, y las dos paredes: la de afuera mira afuera y la de adentro, al hueco.
static func frame(outer: Vector2, outer_r: float, inner: Vector2, inner_r: float, thick: float, steps := 4,
		inner_at := Vector2.ZERO) -> ArrayMesh:
	var out_line := _outline(outer, minf(outer_r, minf(outer.x, outer.y) * 0.5), false, steps)
	var in_line := _outline(inner, minf(inner_r, minf(inner.x, inner.y) * 0.5), false, steps)
	for i in in_line.size():
		in_line[i] += inner_at
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := thick * 0.5
	var n := out_line.size()
	for i in n:
		var j := (i + 1) % n
		for face: float in [1.0, -1.0]:
			var a := Vector3(out_line[i].x, out_line[i].y, h * face)
			var b := Vector3(out_line[j].x, out_line[j].y, h * face)
			var c := Vector3(in_line[j].x, in_line[j].y, h * face)
			var d := Vector3(in_line[i].x, in_line[i].y, h * face)
			_tri(st, a, b, c, Vector3(0.0, 0.0, face))
			_tri(st, a, c, d, Vector3(0.0, 0.0, face))
		_wall(st, out_line[i], out_line[j], -h, h, 1.0)
		_wall(st, in_line[i], in_line[j], -h, h, -1.0, inner_at)
	return st.commit()


## UN BLOQUE BISELADO de esquinas redondeadas: de `size` y `height` de alto (de z = 0 a `height`), con las paredes
## derechas y el BORDE DE ARRIBA BISELADO —`bevel` hacia adentro y hacia abajo—, y la tapa de arriba. La base apoya y no
## se ve.
static func beveled(size: Vector2, radius: float, height: float, bevel: float, steps := 4) -> ArrayMesh:
	var r := minf(radius, minf(size.x, size.y) * 0.5)
	var low := _outline(size, r, false, steps)
	var high := _outline(size - Vector2.ONE * bevel * 2.0, maxf(r - bevel, 0.002), false, steps)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var shoulder := height - bevel
	var n := low.size()
	for i in n:
		var j := (i + 1) % n
		_wall(st, low[i], low[j], 0.0, shoulder, 1.0)
		# El bisel: del borde de la pared al borde de la tapa, mirando afuera y arriba.
		var a := Vector3(low[i].x, low[i].y, shoulder)
		var b := Vector3(low[j].x, low[j].y, shoulder)
		var c := Vector3(high[j].x, high[j].y, height)
		var d := Vector3(high[i].x, high[i].y, height)
		var mid := Vector3((low[i].x + low[j].x) * 0.5, (low[i].y + low[j].y) * 0.5, 0.0).normalized()
		var facing := (mid + Vector3.BACK).normalized()
		_tri(st, a, b, c, facing)
		_tri(st, a, c, d, facing)
		_tri(st, Vector3(0.0, 0.0, height), d, c, Vector3.BACK)
	return st.commit()


## UNA PLACA DE CUALQUIER POLÍGONO CONVEXO que rodee el origen (`outline`), de `thick` de espesor y centrada en z: sus dos
## caras, en abanico desde el origen, y el canto. La usan las placas de los estados del tablero (ver BoardLabel).
static func polygon(outline: PackedVector2Array, thick: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := thick * 0.5
	var n := outline.size()
	for i in n:
		var p := outline[i]
		var q := outline[(i + 1) % n]
		for face: float in [1.0, -1.0]:
			_tri(st, Vector3(0.0, 0.0, h * face), Vector3(p.x, p.y, h * face), Vector3(q.x, q.y, h * face),
				Vector3(0.0, 0.0, face))
		_wall(st, p, q, -h, h, 1.0)
	return st.commit()


## Una pared vertical del tramo `p`→`q` del contorno (centrado en `centre`), de `z0` a `z1`, mirando afuera (`side` 1) o
## adentro (−1).
static func _wall(st: SurfaceTool, p: Vector2, q: Vector2, z0: float, z1: float, side: float,
		centre := Vector2.ZERO) -> void:
	var out := Vector3(q.y - p.y, p.x - q.x, 0.0).normalized()
	var mid := (p + q) * 0.5 - centre
	if out.dot(Vector3(mid.x, mid.y, 0.0)) * side < 0.0:
		out = -out
	var p0 := Vector3(p.x, p.y, z0)
	var p1 := Vector3(p.x, p.y, z1)
	var q0 := Vector3(q.x, q.y, z0)
	var q1 := Vector3(q.x, q.y, z1)
	_tri(st, p0, p1, q1, out)
	_tri(st, p0, q1, q0, out)


## Un triángulo con su frente hacia `facing`: HORARIO visto desde ahí, que es el frente en Godot.
static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, facing: Vector3) -> void:
	if (b - a).cross(c - a).dot(facing) > 0.0:
		var swap := b
		b = c
		c = swap
	for v: Vector3 in [a, b, c]:
		st.set_normal(facing)
		st.add_vertex(v)


## El contorno, antihorario desde la esquina de abajo a la derecha.
static func _outline(size: Vector2, r: float, top_only: bool, steps: int) -> PackedVector2Array:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var out := PackedVector2Array()
	var corners := [[Vector2(hx, -hy), -PI * 0.5, not top_only], [Vector2(hx, hy), 0.0, true],
		[Vector2(-hx, hy), PI * 0.5, true], [Vector2(-hx, -hy), PI, not top_only]]
	for corner: Array in corners:
		var at: Vector2 = corner[0]
		if not bool(corner[2]) or r <= 0.0:
			out.append(at)
			continue
		var centre := at - Vector2(signf(at.x), signf(at.y)) * r
		for k in steps + 1:
			var a := float(corner[1]) + PI * 0.5 * float(k) / float(steps)
			out.append(centre + Vector2(cos(a), sin(a)) * r)
	return out
