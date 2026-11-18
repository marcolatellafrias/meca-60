class_name BaseBag
extends RefCounted

## LA BOLSA DEL GIMNASIO, LOW POLY (ver BaseLayout._bag; el usuario, 17/11/2026: «se ve muy como un cilindro muy duro…
## lo haría más low poly y… un chamfer en las dos tapas… así se ve un poquito más orgánico y redondeado»): un prisma de
## pocos lados con las dos tapas cortadas en bisel, de caras planas y color plano. Y LO QUE LA CUELGA, en ideas para
## elegir (tests/base_bag_ideas): las SOGAS (`Rope`) y CÓMO SE ATA AL TECHO (`Mount`). La física y la textura, después.

enum Rope { THICK, CHAIN, FOUR_STRAPS, CHAIN_AND_FOUR }
enum Mount { PLATE, BEAM, RAIL, WALL_ARM }
const ROPE_NAMES := ["una soga gruesa", "una cadena", "una soga y cuatro correas al borde",
	"una cadena y cuatro cadenas cortas al borde"]
const MOUNT_NAMES := ["una chapa atornillada al techo, con argolla", "una viga doble T, con gancho",
	"un riel con su carro (la bolsa se puede correr)", "un brazo desde la pared"]

## Los lados del prisma y cuánto se come el bisel de cada tapa (partes del radio).
const SIDES := 8
const CHAMFER := 0.35
const ROPE_COLOR := Color(0.62, 0.52, 0.36)
const METAL := Color(0.4, 0.41, 0.43)
const STRAP_COLOR := Color(0.3, 0.26, 0.22)


## LA BOLSA: centrada en `at`, de `radius` y `tall`, colgada de su tapa de arriba.
static func bag(parent: Node3D, radius: float, tall: float, at: Vector3, color: Color) -> MeshInstance3D:
	var cut := radius * CHAMFER
	var rings: Array[Vector2] = [Vector2(0.0, -tall * 0.5), Vector2(radius - cut, -tall * 0.5),
		Vector2(radius, -tall * 0.5 + cut), Vector2(radius, tall * 0.5 - cut), Vector2(radius - cut, tall * 0.5),
		Vector2(0.0, tall * 0.5)]
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	# caras planas: cada triángulo con su normal (sin suavizar)
	tool.set_smooth_group(-1)
	for i in SIDES:
		var a0 := TAU * i / SIDES
		var a1 := TAU * (i + 1) / SIDES
		for k in rings.size() - 1:
			var p := rings[k]
			var q := rings[k + 1]
			var v00 := Vector3(cos(a0) * p.x, p.y, sin(a0) * p.x)
			var v01 := Vector3(cos(a1) * p.x, p.y, sin(a1) * p.x)
			var v10 := Vector3(cos(a0) * q.x, q.y, sin(a0) * q.x)
			var v11 := Vector3(cos(a1) * q.x, q.y, sin(a1) * q.x)
			# el frente de una cara es horario (ver la memoria del proyecto): de afuera, v00 → v10 → v11
			if p.x > 0.0001:
				for v in [v00, v10, v01]:
					tool.add_vertex(v)
			if q.x > 0.0001:
				for v in [v01, v10, v11]:
					tool.add_vertex(v)
	tool.generate_normals()
	var part := MeshInstance3D.new()
	part.mesh = tool.commit()
	part.material_override = Clay.material(color)
	part.position = at
	parent.add_child(part)
	return part


## LO QUE LA CUELGA, de `top` (el punto del techo) a la bolsa (`radius`, con la tapa de arriba en `bag_top`).
static func rope(parent: Node3D, kind: Rope, top: Vector3, bag_top: Vector3, radius: float) -> void:
	var ring := bag_top + Vector3.UP * 1.2
	var edge: Array[Vector3] = []
	for i in 4:
		var angle := TAU * (i + 0.5) / 4.0
		edge.append(bag_top + Vector3(cos(angle), 0.0, sin(angle)) * radius * 0.75)
	match kind:
		Rope.THICK:
			_strand(parent, top, bag_top, 0.07, ROPE_COLOR, 6)
			Clay.box(parent, Vector3(0.3, 0.22, 0.3), bag_top + Vector3.UP * 0.1, STRAP_COLOR)
		Rope.CHAIN:
			_chain(parent, top, bag_top, 0.22)
		Rope.FOUR_STRAPS:
			_strand(parent, top, ring, 0.07, ROPE_COLOR, 6)
			Clay.cylinder(parent, 0.14, 0.08, ring, METAL)
			for point in edge:
				_strand(parent, ring, point, 0.035, STRAP_COLOR, 4)
		Rope.CHAIN_AND_FOUR:
			_chain(parent, top, ring, 0.22)
			Clay.cylinder(parent, 0.16, 0.1, ring, METAL)
			for point in edge:
				_chain(parent, ring, point, 0.12)


## CÓMO SE ATA AL TECHO (de alto `ceiling`), sobre `top` (el punto de donde cuelga). `wall_x`: dónde está la pared, para el
## brazo.
static func mount(parent: Node3D, kind: Mount, top: Vector3, ceiling: float, wall_x: float) -> void:
	match kind:
		Mount.PLATE:
			Clay.box(parent, Vector3(0.8, 0.06, 0.8), Vector3(top.x, ceiling - 0.03, top.z), METAL)
			for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]:
				Clay.cylinder(parent, 0.04, 0.05, Vector3(top.x + corner.x * 0.3, ceiling - 0.08, top.z + corner.y * 0.3),
					Clay.DARK)
			_strand(parent, Vector3(top.x, ceiling - 0.06, top.z), top + Vector3.UP * 0.1, 0.06, METAL, 6)
			_eye(parent, top)
		Mount.BEAM:
			var beam := 0.5
			for y: float in [ceiling - 0.04, ceiling - beam + 0.04]:
				Clay.box(parent, Vector3(0.36, 0.08, 14.0), Vector3(top.x, y, top.z), METAL)
			Clay.box(parent, Vector3(0.06, beam, 14.0), Vector3(top.x, ceiling - beam * 0.5, top.z), METAL)
			_strand(parent, Vector3(top.x, ceiling - beam, top.z), top + Vector3.UP * 0.25, 0.05, METAL, 6)
			# el gancho: una J
			Clay.box(parent, Vector3(0.06, 0.3, 0.06), top + Vector3(0, 0.2, 0), Clay.DARK)
			Clay.box(parent, Vector3(0.2, 0.06, 0.06), top + Vector3(0.07, 0.05, 0), Clay.DARK)
		Mount.RAIL:
			Clay.box(parent, Vector3(0.24, 0.24, 14.0), Vector3(top.x, ceiling - 0.12, top.z), METAL)
			for along: float in [-0.25, 0.25]:
				Clay.cylinder(parent, 0.11, 0.08, Vector3(top.x + 0.17, ceiling - 0.12, top.z + along), Clay.DARK,
					Vector3(0, 0, 90))
				Clay.cylinder(parent, 0.11, 0.08, Vector3(top.x - 0.17, ceiling - 0.12, top.z + along), Clay.DARK,
					Vector3(0, 0, 90))
			Clay.box(parent, Vector3(0.5, 0.12, 0.7), Vector3(top.x, ceiling - 0.3, top.z), STRAP_COLOR)
			_strand(parent, Vector3(top.x, ceiling - 0.36, top.z), top + Vector3.UP * 0.1, 0.05, METAL, 6)
			_eye(parent, top)
		Mount.WALL_ARM:
			# un brazo horizontal desde la pared, con su diagonal, a 1 m del techo
			var arm_y := ceiling - 1.0
			var from := Vector3(wall_x, arm_y, top.z)
			Clay.box(parent, Vector3(absf(top.x - wall_x) + 0.4, 0.22, 0.22), Vector3((top.x + wall_x) * 0.5, arm_y,
				top.z), METAL)
			var brace := Clay.box(parent, Vector3.ONE, Vector3.ZERO, METAL)
			var low := Vector3(wall_x, arm_y - 2.0, top.z)
			var high := Vector3(lerpf(wall_x, top.x, 0.7), arm_y, top.z)
			Clay.segment(brace, low, high, 0.14)
			Clay.box(parent, Vector3(0.1, 0.8, 0.6), Vector3(wall_x, arm_y - 0.6, top.z), Clay.DARK)
			_strand(parent, Vector3(top.x, arm_y - 0.11, top.z), top + Vector3.UP * 0.1, 0.05, METAL, 6)
			_eye(parent, top)


## UNA SOGA de `from` a `to`: un prisma de pocos lados.
static func _strand(parent: Node3D, from: Vector3, to: Vector3, radius: float, color: Color, sides: int) -> void:
	var part := Clay.cylinder(parent, radius, from.distance_to(to), (from + to) * 0.5, color)
	(part.mesh as CylinderMesh).radial_segments = sides
	(part.mesh as CylinderMesh).rings = 0
	var along := (to - from).normalized()
	var side := Vector3.RIGHT if absf(along.dot(Vector3.RIGHT)) < 0.9 else Vector3.BACK
	var x := side.cross(along).normalized()
	part.basis = Basis(x, along, x.cross(along))


## UNA CADENA de `from` a `to`: eslabones de cuatro barras, uno de frente y el otro de costado.
static func _chain(parent: Node3D, from: Vector3, to: Vector3, link: float) -> void:
	var along := to - from
	var count := maxi(1, int(along.length() / (link * 0.75)))
	var step := along / count
	var dir := along.normalized()
	var side := Vector3.RIGHT if absf(dir.dot(Vector3.RIGHT)) < 0.9 else Vector3.BACK
	var x := side.cross(dir).normalized()
	var z := x.cross(dir)
	var bar := link * 0.13
	for i in count:
		var center := from + step * (i + 0.5)
		var wide := x if i % 2 == 0 else z
		var holder := Node3D.new()
		holder.basis = Basis(wide, dir, wide.cross(dir))
		holder.position = center
		parent.add_child(holder)
		for s: float in [-1.0, 1.0]:
			Clay.box(holder, Vector3(bar, link, bar), Vector3(s * link * 0.25, 0, 0), METAL)
			Clay.box(holder, Vector3(link * 0.5 + bar, bar, bar), Vector3(0, s * link * 0.5, 0), METAL)


## UNA ARGOLLA: un aro de pocos lados, de canto.
static func _eye(parent: Node3D, at: Vector3) -> void:
	var holder := Node3D.new()
	holder.position = at + Vector3.UP * 0.1
	parent.add_child(holder)
	var sides := 6
	for i in sides:
		var a := TAU * i / sides
		var piece := Clay.box(holder, Vector3(0.05, 0.1, 0.05), Vector3(cos(a), sin(a), 0) * 0.1, Clay.DARK)
		piece.basis = Basis(Vector3.BACK, a)
