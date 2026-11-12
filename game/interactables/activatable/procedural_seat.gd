@tool
class_name ProceduralSeat
extends Node3D

## LA SILLA DE LAS ESTACIONES, sin una sola malla de Blender (29/10/2026, lo pidió el dios del juego: «dos cubos estirados
## y el pie… el asiento déjalo bien simple, así yo después lo modelo en Blender»):
##
##   • el PIE: un disco atornillado al piso, con sus bulones a la vista, y una columna que sube o baja hasta dejar al que
##     se sienta a su altura (ver ALTURA en seat_interactable.gd);
##   • el ASIENTO: una caja;
##   • el RESPALDO: otra caja, que baja hasta adentro del asiento para que las dos se lean como UNA PIEZA. Se reclina con la
##     espalda del que está sentado, girando sobre SU ESQUINA, donde se junta con el asiento (29/10/2026, lo pidió el dios
##     del juego: «que la silla solamente se articule desde su esquina»; ver EL RESPALDO SE RECLINA en seat_interactable.gd).
##
## Low poly y mate. El frente de la silla mira a −Z: el respaldo queda hacia +Z. Todo en metros de la silla sin agrandar.
##
## ── CADA SECCIÓN SE MODELA EN BLENDER (2/11/2026, lo pidió el dios del juego: «la opción para abrir en Blender cada
## sección de la silla en otro menú F»): el pie, el asiento y el respaldo son cada uno un modelo de tamaño fijo con su
## caja (ver ModelBox, `SECTIONS`). Si está su .glb se dibuja ese; si no, la caja de código de siempre. Se abren y se
## traen desde su panel (ver SeatPanel). LA COLUMNA NO: es lo único que cambia de largo, y una pieza modelada no se
## estira; queda de código, al largo justo.

## ── EL PIE ──────────────────────────────────────────────────────────────────────────────────────
const DISC_RADIUS := 0.25
const DISC_HEIGHT := 0.03
const SCREW_COUNT := 6
const SCREW_RADIUS := 0.018
const SCREW_HEIGHT := 0.012
const SCREW_RING := 0.17
const COLUMN_RADIUS := 0.05
## Cuánto se mete la columna dentro del asiento: sin esto, al subirlo se vería la junta.
const COLUMN_OVERLAP := 0.03
## De cuántos lados son los cilindros: low poly.
const SIDES := 8

## ── EL ASIENTO Y EL RESPALDO ────────────────────────────────────────────────────────────────────
## VISTOS DESDE ARRIBA, ASIENTO Y RESPALDO SON UN CUADRADO de este lado, con la columna en el centro (29/10/2026, lo
## pidió el dios del juego: «así cuando gira el asiento no sobresale más de un lado que del otro»).
const SIDE := 0.5
const SEAT_THICKNESS := 0.1
const BACK_THICKNESS := 0.1
const WIDTH := SIDE
## El borde de adelante del asiento, desde el eje de la columna: ahí abajo van las pantorrillas.
const FRONT := SIDE * 0.5
## La cara del respaldo, desde el eje de la columna: contra ella va la espalda (ver SeatInteractable.SEAT_FITS).
const BACK_FACE := SIDE * 0.5 - BACK_THICKNESS
## Lo que se ve del respaldo sobre el asiento.
const BACK_HEIGHT := 0.6
## Cuánto se mete el respaldo dentro del asiento: la junta no se ve, y reclinado no se despega.
const BACK_INTO_SEAT := 0.05

## Lo alto del pie: el disco con sus bulones arriba.
const FOOT_HEIGHT := DISC_HEIGHT + SCREW_HEIGHT

## ── LAS SECCIONES MODELADAS ─────────────────────────────────────────────────────────────────────
## Dónde viven: `art-source/silla/<sección>` (la caja y el .blend) y `assets/models/silla/<sección>.glb`.
const MODEL_AREA := "silla"
const SECTIONS := ["pie", "asiento", "respaldo"]
const SECTION_TITLES := {"pie": "el pie", "asiento": "el asiento", "respaldo": "el respaldo"}
## Todas las sillas armadas, para rearmarlas cuando llega un modelo nuevo (ver `reload_all`).
const GROUP := "procedural_seats"

const UPHOLSTERY := Color(0.55, 0.49, 0.55)
const METAL := Color(0.62, 0.63, 0.66)

## La altura de la pelvis del que se sienta, sobre la base, con la silla a su altura de modelo. La escribe
## `SeatInteractable` al instanciar la silla, desde su `rest_height`. Arma la silla vacía hasta el primer `set_pose`.
var rest_pelvis_height := 0.42

var _column: MeshInstance3D = null
## Cada sección es un nodo centrado en su caja, con el modelo o la caja de código adentro (ver `_fill`).
var _foot: Node3D = null
var _seat: Node3D = null
## El respaldo cuelga de este nodo, que va en la esquina entre su cara y la del asiento: reclinarlo es girarlo.
var _hinge: Node3D = null
var _back: Node3D = null


func _ready() -> void:
	add_to_group(GROUP)
	_build()
	set_pose(rest_pelvis_height - 0.12, 0.0)


## CÓMO QUEDA LA SILLA: la cara de arriba del asiento a `seat_top`, y el respaldo reclinado `recline` radianes sobre la
## esquina. Todo en ejes de la silla.
func set_pose(seat_top: float, recline: float) -> void:
	if _seat == null:
		return
	_seat.position = Vector3(0.0, seat_top - SEAT_THICKNESS * 0.5, 0.0)

	var length := maxf(seat_top - SEAT_THICKNESS + COLUMN_OVERLAP - DISC_HEIGHT, 0.01)
	_column.scale.y = length
	_column.position = Vector3(0.0, DISC_HEIGHT + length * 0.5, 0.0)

	_hinge.transform = Transform3D(Basis(Vector3.RIGHT, recline), Vector3(0.0, seat_top, BACK_FACE))
	_back.position = Vector3(0.0, (BACK_HEIGHT - BACK_INTO_SEAT) * 0.5, BACK_THICKNESS * 0.5)


func _build() -> void:
	# EL PIE.
	_foot = _section_node(self)
	_foot.position.y = FOOT_HEIGHT * 0.5
	# De un metro, estirada por su escala.
	_column = _piece(_cylinder(COLUMN_RADIUS, 1.0, SIDES), MeshKit.material(METAL, 1.0, 0.0), self)

	# EL ASIENTO Y EL RESPALDO.
	_seat = _section_node(self)
	_hinge = Node3D.new()
	add_child(_hinge)
	_back = _section_node(_hinge)
	_fill_all()


func _section_node(parent: Node) -> Node3D:
	var node := Node3D.new()
	parent.add_child(node)
	return node


## Cada sección con lo que haya: su modelo, o la caja de código.
func _fill_all() -> void:
	_fill(_foot, "pie")
	_fill(_seat, "asiento")
	_fill(_back, "respaldo")


func _fill(holder: Node3D, section: String) -> void:
	for child in holder.get_children():
		holder.remove_child(child)
		child.queue_free()
	var loaded := ModelBox.load_into(holder, MODEL_AREA, section, section_box(section),
		func(color: Color) -> Material: return MeshKit.material(color, 0.9, 0.0))
	if loaded.is_empty():
		_sketch(section, holder)


## REARMA TODAS LAS SILLAS con los modelos de hoy: lo llama el panel después de traer uno de Blender.
static func reload_all(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group(GROUP):
		var seat := node as ProceduralSeat
		if seat != null and seat._foot != null:
			seat._fill_all()


## LA CAJA DE UNA SECCIÓN, en metros y centrada en el origen: lo que ocupa su boceto, y adentro de lo que se modela.
static func section_box(section: String) -> Vector3:
	match section:
		"pie":
			return Vector3(DISC_RADIUS * 2.0, FOOT_HEIGHT, DISC_RADIUS * 2.0)
		"asiento":
			return Vector3(SIDE, SEAT_THICKNESS, SIDE)
		_:
			return Vector3(WIDTH, BACK_HEIGHT + BACK_INTO_SEAT, BACK_THICKNESS)


## EL BOCETO DE CÓDIGO de una sección, centrado en su caja, colgado de `parent`.
static func _sketch(section: String, parent: Node3D) -> void:
	var metal := MeshKit.material(METAL, 1.0, 0.0)
	var cloth := MeshKit.material(UPHOLSTERY, 0.85, 0.0)
	match section:
		"pie":
			var disc := _piece(_cylinder(DISC_RADIUS, DISC_HEIGHT, SIDES), metal, parent)
			disc.name = "disco"
			disc.position.y = DISC_HEIGHT * 0.5 - FOOT_HEIGHT * 0.5
			# Un bulón es un cilindro de seis lados: un prisma hexagonal.
			var screw_mesh := _cylinder(SCREW_RADIUS, SCREW_HEIGHT, 6)
			for i in SCREW_COUNT:
				var angle := TAU * float(i) / float(SCREW_COUNT)
				var screw := _piece(screw_mesh, metal, parent)
				screw.name = "bulon_%d" % i
				screw.position = Vector3(cos(angle) * SCREW_RING, FOOT_HEIGHT * 0.5 - SCREW_HEIGHT * 0.5,
					sin(angle) * SCREW_RING)
		_:
			var box := _piece(_box(section_box(section)), cloth, parent)
			box.name = section


## ESCRIBE LA CAJA de una sección para modelarla en Blender (ver ModelBox.write_box), con su boceto de referencia.
## Devuelve la ruta del .json, o "" si no se pudo.
static func write_box(section: String) -> String:
	var reference := Node3D.new()
	_sketch(section, reference)
	var path := ModelBox.write_box(MODEL_AREA, section, "Silla: %s" % SECTION_TITLES[section], section_box(section),
		0.0, {}, reference)
	reference.free()
	return path


static func _piece(mesh: Mesh, material: Material, parent: Node) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	parent.add_child(node)
	return node


static func _cylinder(radius: float, height: float, sides: int) -> ArrayMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = 0
	return _faceted(mesh)


static func _box(size: Vector3) -> ArrayMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _faceted(mesh)


## UNA MALLA CON LAS NORMALES DE CADA CARA: cada triángulo con sus tres vértices propios y la normal de su plano, del
## lado de las que traía (así no importa el sentido en que esté armado). Es lo que la hace low poly, y por ser ArrayMesh la
## vista Blender (la M) la dibuja.
static func _faceted(mesh: Mesh) -> ArrayMesh:
	var out := ArrayMesh.new()
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL] if arrays[Mesh.ARRAY_NORMAL] != null \
			else PackedVector3Array()
		var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		var count := index.size() if not index.is_empty() else verts.size()
		var points := PackedVector3Array()
		var flat := PackedVector3Array()
		for t in range(0, count - 2, 3):
			var ids := [t, t + 1, t + 2] if index.is_empty() else [index[t], index[t + 1], index[t + 2]]
			var a: Vector3 = verts[ids[0]]
			var b: Vector3 = verts[ids[1]]
			var c: Vector3 = verts[ids[2]]
			var normal := (b - a).cross(c - a)
			if normal.length_squared() < 1e-14:
				continue
			normal = normal.normalized()
			if not normals.is_empty() and normal.dot(normals[ids[0]] + normals[ids[1]] + normals[ids[2]]) < 0.0:
				normal = -normal
			for v in [a, b, c]:
				points.append(v)
				flat.append(normal)
		var built: Array = []
		built.resize(Mesh.ARRAY_MAX)
		built[Mesh.ARRAY_VERTEX] = points
		built[Mesh.ARRAY_NORMAL] = flat
		out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, built)
	return out
