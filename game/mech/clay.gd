class_name Clay
extends RefCounted

## LA ARCILLA DE LOS BOCETOS: cajas, cilindros y esferas de un color, con o sin su caja de choque. Todo el boceto de la
## meca, el bicho y la arena se arma con esto; el modelado de verdad viene después.

const METAL := Color(0.52, 0.54, 0.57)
const DARK := Color(0.2, 0.21, 0.23)
const GLASS := Color(0.55, 0.75, 0.85, 0.25)
const RED := Color(0.78, 0.18, 0.15)
const YELLOW := Color(0.95, 0.75, 0.15)

static var _materials := {}


static func material(color: Color) -> StandardMaterial3D:
	if _materials.has(color):
		return _materials[color]
	var made := StandardMaterial3D.new()
	made.albedo_color = color
	made.roughness = 0.85
	if color.a < 1.0:
		made.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		made.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[color] = made
	return made


## Una caja que se ve, de `size`, centrada en `at`.
static func box(parent: Node3D, size: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _instance(parent, mesh, at, color)


static func cylinder(parent: Node3D, radius: float, height: float, at: Vector3, color: Color,
		rotation_deg := Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	var part := _instance(parent, mesh, at, color)
	part.rotation_degrees = rotation_deg
	return part


static func sphere(parent: Node3D, radius: float, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	return _instance(parent, mesh, at, color)


## Una caja de choque (sin malla) colgada de un cuerpo, centrada en `at`, girada `basis`.
static func shape_box(body: CollisionObject3D, size: Vector3, at: Vector3, basis := Basis()) -> CollisionShape3D:
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	shape.transform = Transform3D(basis, at)
	body.add_child(shape)
	return shape


## Una caja que se ve y choca, colgada de un cuerpo.
static func solid(body: CollisionObject3D, size: Vector3, at: Vector3, color: Color, basis := Basis()) -> MeshInstance3D:
	shape_box(body, size, at, basis)
	var part := box(body, size, at, color)
	part.basis = basis
	return part


## Pone `part` (una caja de lado 1) entre `from` y `to`, con `thickness` de grueso: para las patas y los brazos.
static func segment(part: Node3D, from: Vector3, to: Vector3, thickness: float) -> void:
	var along := to - from
	var length := maxf(along.length(), 0.001)
	var up := Vector3.UP if absf(along.normalized().dot(Vector3.UP)) < 0.95 else Vector3.BACK
	var basis := Basis.looking_at(along / length, up)
	part.transform = Transform3D(basis.scaled_local(Vector3(thickness, thickness, length)), (from + to) * 0.5)


static func _instance(parent: Node3D, mesh: Mesh, at: Vector3, color: Color) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.material_override = material(color)
	part.position = at
	parent.add_child(part)
	return part
