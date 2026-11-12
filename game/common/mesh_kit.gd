class_name MeshKit
extends RefCounted

## LAS PIEZAS SUELTAS CON SU MATERIAL, en un solo lugar: la caja, el cilindro, la esfera y el material mate de color.
## Estaban copiadas casi letra por letra en una veintena de archivos —los componentes y artefactos de los tableros, el
## equipo de la nave, las expendedoras, la sucursal— (ver censo-codigo, el punto 1), cada una a su manera de nombrar lo
## mismo. Acá hacen exactamente lo que hacían aquellas: las mismas primitivas de Godot, los mismos campos y en el
## mismo orden, así que migrar un archivo no mueve ni un vértice.
##
## Lo que NO es esto: las cajas que además llevan colisión, o un material con transparencia, o que se arman sobre una
## malla horneada (`UnitMesh`, `SurfaceTool`) siguen en su archivo. Esto es sólo «una primitiva de Godot con su
## material, colgada de un nodo».


## UNA CAJA de `size`, centrada en `at` en el marco de `parent`, con `material`. Sin `parent`, queda suelta.
static func box(parent: Node3D, size: Vector3, at: Vector3, material: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = material
	mi.position = at
	if parent != null:
		parent.add_child(mi)
	return mi


## UN CILINDRO ACOSTADO SOBRE Z, como salen las piezas de un tablero hacia el jugador: centrado en el eje, con la base
## a `z` de la cara y la tapa `height` más adelante. `top_radius` negativo es igual a `radius` (si no, un cono). Sin
## `parent`, queda suelto. `sides` y `rings` son los de `CylinderMesh` (64 y 4 si no se dicen, sus valores por defecto).
static func cylinder_z(parent: Node3D, radius: float, height: float, z: float, material: Material, sides := 64,
		rings := 4, top_radius := -1.0) -> MeshInstance3D:
	return _lying_cylinder(parent, radius, height, Vector3(0.0, 0.0, z + height * 0.5), material, sides, rings,
		top_radius)


## Lo mismo con la base en un punto cualquiera, `base`, en vez de en el eje.
static func cylinder_z_at(parent: Node3D, radius: float, height: float, base: Vector3, material: Material, sides := 64,
		rings := 4, top_radius := -1.0) -> MeshInstance3D:
	return _lying_cylinder(parent, radius, height, base + Vector3(0.0, 0.0, height * 0.5), material, sides, rings,
		top_radius)


## Las dos de arriba calculan el centro cada una a su manera —la cuenta en el eje y la del punto redondean distinto el
## último bit— porque así lo calculaban los archivos de donde vienen.
static func _lying_cylinder(parent: Node3D, radius: float, height: float, centre: Vector3, material: Material,
		sides: int, rings: int, top_radius: float) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = cylinder_mesh(radius, height, sides, rings, top_radius)
	mi.material_override = material
	mi.rotation.x = PI * 0.5
	mi.position = centre
	if parent != null:
		parent.add_child(mi)
	return mi


## LA MALLA DE UN CILINDRO, parado sobre Y (ver `cylinder_z`).
static func cylinder_mesh(radius: float, height: float, sides := 64, rings := 4, top_radius := -1.0) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius if top_radius < 0.0 else top_radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = sides
	mesh.rings = rings
	return mesh


## UNA ESFERA de `radius`, centrada en `at`, con `material`. Sin `parent`, queda suelta.
static func sphere(parent: Node3D, radius: float, at: Vector3, material: Material, segments := 16,
		rings := 8) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	mi.mesh = mesh
	mi.material_override = material
	mi.position = at
	if parent != null:
		parent.add_child(mi)
	return mi


## UN MATERIAL DE COLOR, nuevo en cada llamada. Sin `roughness` ni `metallic`, los de `StandardMaterial3D` (1 y 0).
static func material(color: Color, roughness := 1.0, metallic := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	m.metallic = metallic
	return m
