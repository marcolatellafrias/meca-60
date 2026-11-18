class_name FaceCosmetic
extends RefCounted

## ── UN COSMÉTICO DE LA CARA: BIGOTE, CEJAS (18/11/2026) ─────────────────────────────────────────────────────────────
## Lo pidió el usuario: «cosméticos de barba y de pelo… lentes y anteojos y cigarrillos… cada forma de cabeza tiene una
## altura de boca, una altura de ojos… cuando quiero poner un bigote… lo hago relativo a la altura de boca»; el bigote
## y las cejas son «modelos low poly… completos».
##
## Uno es UNA TIRA (o dos, espejadas) DIBUJADA EN LA CARA: una línea de puntos `(x, arriba, medio alto)` desde su
## ancla (la altura de los ojos o de la boca de la forma, ver HeadForm.eye_height) que se apoya sobre la malla de la
## cabeza que toque (ver HeadForm.surface_point) y sale hacia afuera `depth`. Así el mismo bigote calza en todas las
## formas —se dobla con la cara, plana o con su esquina—. Los números son de una cabeza de referencia (`REF_HEIGHT` de
## alto, `REF_WIDTH` de ancho en el ancla): lo de arriba y abajo crece con el alto de la cabeza; lo de costado, con su
## ancho ahí. Las caras son planas (low poly, como un modelo).

enum Anchor { EYES, MOUTH }

const REF_HEIGHT := 0.24
const REF_WIDTH := 0.17
## Lo que se mete adentro de la cara, para que no quede luz entre las dos.
const SINK := 0.002

var name := ""
var anchor := Anchor.MOUTH
## Los puntos de la mitad derecha (+X) de la tira, de adentro hacia afuera: `Vector3(x, arriba del ancla, medio alto)`.
var points: Array[Vector3] = []
## `true`: una tira de punta a punta, la mitad espejada pegada (un bigote). `false`: dos tiras, una de cada lado (cejas).
var joined := true
var depth := 0.005
var color := Color(0.22, 0.14, 0.09)


static func make(p_name: String, p_anchor: Anchor, p_points: Array, p_joined: bool, p_depth: float,
		p_color := Color(0.22, 0.14, 0.09)) -> FaceCosmetic:
	var out := FaceCosmetic.new()
	out.name = p_name
	out.anchor = p_anchor
	for p: Vector3 in p_points:
		out.points.append(p)
	out.joined = p_joined
	out.depth = p_depth
	out.color = p_color
	return out


## LA MALLA, APOYADA EN `form` (en sus metros, con su frente a −Z como la cabeza). `front_face`: el giro de la malla de
## la cabeza (ver HeadForm.build_arrays), para apoyarse en la que se ve.
func build_mesh(form: HeadForm, front_face := false) -> ArrayMesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	tool.set_smooth_group(-1)
	for strip in _strips():
		_add_strip(tool, form, front_face, strip)
	tool.generate_normals()
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 1.0
	tool.set_material(material)
	return tool.commit()


## Las tiras en la cara de referencia: una de punta a punta o dos espejadas.
func _strips() -> Array:
	var mirrored: Array[Vector3] = []
	for p in points:
		mirrored.append(Vector3(-p.x, p.y, p.z))
	if not joined:
		mirrored.reverse()
		return [points, mirrored]
	var whole: Array[Vector3] = []
	for i in range(mirrored.size() - 1, -1, -1):
		if i == 0 and is_zero_approx(points[0].x):
			continue
		whole.append(mirrored[i])
	whole.append_array(points)
	return [whole]


func _add_strip(tool: SurfaceTool, form: HeadForm, front_face: bool, strip: Array) -> void:
	var total := form.total_height()
	var base_y := (form.eye_height if anchor == Anchor.EYES else form.mouth_height) * total
	var ky := total / REF_HEIGHT
	var kx := form.width_at(base_y) / REF_WIDTH
	var out_by := depth * ky
	var sink := SINK * ky
	# Cada punto: arriba y abajo sobre la cara, y adelante y atrás de eso por la normal.
	var corners: Array = []
	for p: Vector3 in strip:
		var x := p.x * kx
		var y := base_y + p.y * ky
		var n := form.surface_normal(y, x, front_face)
		var top := form.surface_point(y + p.z * ky, x, front_face)
		var bottom := form.surface_point(y - p.z * ky, x, front_face)
		corners.append([top - n * sink, bottom - n * sink, top + n * out_by, bottom + n * out_by])
	for i in corners.size() - 1:
		var a: Array = corners[i]
		var b: Array = corners[i + 1]
		var center := Vector3.ZERO
		for v: Vector3 in a + b:
			center += v / 8.0
		_quad(tool, center, a[2], b[2], b[3], a[3])
		_quad(tool, center, a[0], b[0], b[2], a[2])
		_quad(tool, center, a[1], b[1], b[3], a[3])
		_quad(tool, center, a[0], b[0], b[1], a[1])
		if i == 0:
			_quad(tool, center, a[0], a[2], a[3], a[1])
		if i == corners.size() - 2:
			_quad(tool, center, b[0], b[2], b[3], b[1])


## Un cuadrilátero con la cara hacia afuera de `center` (el frente de Godot es horario: la normal de afuera es
## `(c - a).cross(b - a)`, se mide y se da vuelta si hace falta).
static func _quad(tool: SurfaceTool, center: Vector3, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	for tri in [[a, b, c], [a, c, d]]:
		var p: Vector3 = tri[0]
		var q: Vector3 = tri[1]
		var r: Vector3 = tri[2]
		if (r - p).cross(q - p).dot((p + q + r) / 3.0 - center) < 0.0:
			var swap := q
			q = r
			r = swap
		tool.add_vertex(p)
		tool.add_vertex(q)
		tool.add_vertex(r)
