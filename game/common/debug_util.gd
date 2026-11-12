# res://utils/debug_utils.gd
class_name DebugUtil


static func create_debug_line(color: Color, length: float, on_top: bool = false, to_down: bool = true) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = Vector3(0.01, length, 0.01)
	mesh_instance.mesh = cube
	mesh_instance.position = Vector3(0.0, (-length * 0.5) if to_down else (length * 0.5), 0.0)

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	
	if on_top:
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS 
	mesh_instance.material_override = material
	return mesh_instance

static func update_debug_line_mesh(mesh_instance: MeshInstance3D, length: float, to_down: bool = true) -> MeshInstance3D:
	if mesh_instance == null:
		return mesh_instance
	var prev: float = mesh_instance.get_meta("_dline_len", -1.0)
	if is_equal_approx(prev, length):
		return mesh_instance
	mesh_instance.set_meta("_dline_len", length)
	var box := mesh_instance.mesh as BoxMesh
	if box == null:
		box = BoxMesh.new()
		mesh_instance.mesh = box
	box.size = Vector3(0.01, length, 0.01)
	mesh_instance.position = Vector3(0.0, (-length * 0.5) if to_down else (length * 0.5), 0.0)
	return mesh_instance
	
static func create_debug_sphere(color: Color, size: float = 0.1, on_top: bool = false, radial_segments: int = 8, rings: int = 8) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radial_segments = radial_segments
	sphere.rings = rings
	mesh_instance.mesh = sphere
	mesh_instance.scale = Vector3(size, size, size)
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if on_top:
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS 
	mesh_instance.material_override = material
	return mesh_instance

static func create_debug_cube(color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var cube := BoxMesh.new()
	mesh_instance.mesh = cube
	mesh_instance.scale = Vector3(0.05,0.05,0.05)

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	mesh_instance.material_override = material
	return mesh_instance

static func create_debug_capsule(radius: float, height: float, y_offset: float) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	
	# Crear una cápsula con los parámetros dados
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	mesh_instance.mesh = capsule

	# Crear un material blanco semitransparente
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1, 1, 1, 0.2) # Blanco con opacidad 0.5
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.flags_transparent = true

	mesh_instance.material_override = material
	mesh_instance.position= Vector3(0,y_offset,0)
	
	return mesh_instance

static func create_debug_ring(color: Color, radius: float, segments: int = 64) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		st.set_color(color)
		st.add_vertex(Vector3(x, 0, z))

	var mesh := st.commit()
	mesh_instance.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.flags_transparent = true
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_instance.material_override = material
	return mesh_instance


static func create_debug_ring_mesh(radius: float, segments: int = 64) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(segments + 1):
		var angle := TAU * float(i) / float(segments)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		st.add_vertex(Vector3(x, 0, z))

	var mesh := st.commit()
	return mesh

static func create_debug_line_to_from(from: Vector3, to: Vector3, color: Color, width: float) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var cube := BoxMesh.new()
	
	var distance := from.distance_to(to)
	cube.size = Vector3(width, distance, width)
	mesh_instance.mesh = cube
	
	var midpoint := (from + to) / 2.0
	mesh_instance.position = midpoint
	
	# Construir la base manualmente para alinear el eje Y con la dirección
	var direction := (to - from).normalized()
	if direction.length() > 0.001:
		var y_axis = direction
		var x_axis = y_axis.cross(Vector3.UP)
		
		# Si la línea está vertical, usar otro vector de referencia
		if x_axis.length() < 0.001:
			x_axis = y_axis.cross(Vector3.RIGHT)
		
		x_axis = x_axis.normalized()
		var z_axis = x_axis.cross(y_axis).normalized()
		
		# Aplicar la base personalizada
		mesh_instance.basis = Basis(x_axis, y_axis, z_axis)
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color

	mesh_instance.material_override = material
	# ⚠ ESTE CORTE MIDE MAL. `visibility_range_end` compara la distancia al ORIGEN del nodo, y esta malla
	# se arma con vertices en el espacio de LA CIUDAD, o sea con su origen en (0,0,0) —la esquina de la
	# ciudad—. Resultado: todas estas piezas aparecen y desaparecen A LA VEZ, sin relacion con lo que
	# uno tiene enfrente. Hoy no molesta porque los `show_*` que llegan aca estan apagados. Si se
	# prende alguno, hay que centrar el origen primero (ver technical/city-generation.md, "Meshes are built
	# in the city's space").
	mesh_instance.visibility_range_end = WorldSettings.spawn_radius
	return mesh_instance

static func get_skewed_cube_from_planes_geometry(plane1: Array, plane2: Array) -> Dictionary:
	if plane1.size() != 4 or plane2.size() != 4:
		return {}
	var p1: Array = plane1
	var p2: Array = plane2
	var mesh_center := Vector3.ZERO
	for v: Vector3 in p1: mesh_center += v
	for v: Vector3 in p2: mesh_center += v
	mesh_center /= 8.0
	var verts := PackedVector3Array()
	var norms  := PackedVector3Array()
	var idxs   := PackedInt32Array()
	_add_quad(verts, idxs, norms, p1[0], p1[1], p1[2], p1[3], mesh_center)
	_add_quad(verts, idxs, norms, p2[3], p2[2], p2[1], p2[0], mesh_center)
	_add_quad(verts, idxs, norms, p1[0], p2[0], p2[1], p1[1], mesh_center)
	_add_quad(verts, idxs, norms, p1[3], p1[2], p2[2], p2[3], mesh_center)
	_add_quad(verts, idxs, norms, p1[0], p1[3], p2[3], p2[0], mesh_center)
	_add_quad(verts, idxs, norms, p1[1], p2[1], p2[2], p1[2], mesh_center)
	return {vertices = verts, normals = norms, indices = idxs}

static func _quad_outward_normal(a: Vector3, b: Vector3, c: Vector3, d: Vector3, mesh_center: Vector3) -> Vector3:
	var n = (b - a).cross(c - a).normalized()
	var face_center = (a + b + c + d) * 0.25
	if n.dot(face_center - mesh_center) < 0:
		n = -n
	return n

static func _add_quad_normals(normals: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, mesh_center: Vector3) -> void:
	var n = _quad_outward_normal(a, b, c, d, mesh_center)
	normals.append(n)
	normals.append(n)
	normals.append(n)
	normals.append(n)

static func _add_quad(
	verts: PackedVector3Array, indices: PackedInt32Array, normals: PackedVector3Array,
	a: Vector3, b: Vector3, c: Vector3, d: Vector3,
	mesh_center: Vector3
) -> void:
	var n = (b - a).cross(c - a)
	var face_center = (a + b + c + d) * 0.25
	if n.dot(face_center - mesh_center) > 0.0:
		var tmp = b; b = d; d = tmp
	_add_quad_to_arrays(verts, indices, a, b, c, d)
	_add_quad_normals(normals, a, b, c, d, mesh_center)

# Función helper para agregar un quad a los arrays de mesh
static func _add_quad_to_arrays(
	vertices: PackedVector3Array, 
	indices: PackedInt32Array,
	v1: Vector3, v2: Vector3, v3: Vector3, v4: Vector3
) -> void:
	var start_idx = vertices.size()
	
	vertices.append(v1)
	vertices.append(v2)
	vertices.append(v3)
	vertices.append(v4)
	
	# Primer triángulo
	indices.append(start_idx + 0)
	indices.append(start_idx + 1)
	indices.append(start_idx + 2)
	
	# Segundo triángulo
	indices.append(start_idx + 0)
	indices.append(start_idx + 2)
	indices.append(start_idx + 3)

# DebugUtil.gd - Agregar este método estático

# Crea un CollisionShape3D (convex) a partir de dos planos paralelos
# plane1_vertices: Array de 4 Vector3 representando el primer plano [v1_base, v2_base, v3_top, v4_top]
# plane2_vertices: Array de 4 Vector3 representando el segundo plano [v1_base, v2_base, v3_top, v4_top]
# Retorna: CollisionShape3D con ConvexPolygonShape3D
static func create_collision_shape_from_planes(
	plane1_vertices: Array,
	plane2_vertices: Array
) -> CollisionShape3D:
	
	if plane1_vertices.size() != 4 or plane2_vertices.size() != 4:
		push_error("create_collision_shape_from_planes requiere 4 vértices por plano")
		return null
	
	var points = PackedVector3Array()
	
	# Agregar los 4 vértices del primer plano
	for v in plane1_vertices:
		points.append(v)
	
	# Agregar los 4 vértices del segundo plano
	for v in plane2_vertices:
		points.append(v)
	
	# Crear la forma convexa
	var convex_shape = ConvexPolygonShape3D.new()
	convex_shape.points = points
	
	# Crear el CollisionShape3D
	var collision_shape = CollisionShape3D.new()
	collision_shape.shape = convex_shape
	
	return collision_shape

static func create_debug_path3d(
	points: Array,  # Array de Dictionary con {pos: Vector3, in: Vector3, out: Vector3}
	segments_per_curve: int,
	color: Color,
	width: float
) -> MeshInstance3D:
	var curve := Curve3D.new()
	
	# Construir el Curve3D con los puntos y control points
	for point_data in points:
		curve.add_point(
			point_data.pos,
			point_data.get("in", Vector3.ZERO),
			point_data.get("out", Vector3.ZERO)
		)
	
	# Muestrear la curva
	var total_segments = (points.size() - 1) * segments_per_curve
	var sampled_points: Array[Vector3] = []
	
	for i in range(total_segments + 1):
		var offset = curve.get_baked_length() * (float(i) / total_segments)
		sampled_points.append(curve.sample_baked(offset))
	
	# Crear mesh combinado
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	var vertices: PackedVector3Array = []
	var indices: PackedInt32Array = []
	
	# Generar geometría de cilindros para cada segmento
	var vertex_offset = 0
	for i in range(sampled_points.size() - 1):
		var from = sampled_points[i]
		var to = sampled_points[i + 1]
		var direction = (to - from).normalized()
		var distance = from.distance_to(to)
		
		if distance < 0.001:
			continue
		
		# Crear base para orientar el cilindro
		var y_axis = direction
		var x_axis = y_axis.cross(Vector3.UP)
		if x_axis.length() < 0.001:
			x_axis = y_axis.cross(Vector3.RIGHT)
		x_axis = x_axis.normalized()
		var z_axis = x_axis.cross(y_axis).normalized()
		var basis = Basis(x_axis, y_axis, z_axis)
		
		# 8 vértices del cubo (box) para este segmento
		var half_width = width * 0.5
		var local_verts = [
			Vector3(-half_width, 0, -half_width),
			Vector3(half_width, 0, -half_width),
			Vector3(half_width, 0, half_width),
			Vector3(-half_width, 0, half_width),
			Vector3(-half_width, distance, -half_width),
			Vector3(half_width, distance, -half_width),
			Vector3(half_width, distance, half_width),
			Vector3(-half_width, distance, half_width)
		]
		
		# Transformar y agregar vértices
		for v in local_verts:
			var transformed = from + basis * v
			vertices.append(transformed)
		
		# Índices para las caras del cubo
		var faces = [
			[0,1,2, 0,2,3], # Bottom
			[4,6,5, 4,7,6], # Top
			[0,4,5, 0,5,1], # Front
			[1,5,6, 1,6,2], # Right
			[2,6,7, 2,7,3], # Back
			[3,7,4, 3,4,0]  # Left
		]
		
		for face in faces:
			for idx in face:
				indices.append(vertex_offset + idx)
		
		vertex_offset += 8
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = array_mesh
	
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	mesh_instance.material_override = material
	
	return mesh_instance

# En DebugUtil - versión actualizada
static func create_debug_sphere_2dprint(grid_coords: Vector2i, color: Color, size: float = 0.1, on_top: bool = false, radial_segments: int = 4, rings: int = 4) -> Node3D:
	var container := Node3D.new()

	var mesh_instance := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radial_segments = radial_segments
	sphere.rings = rings
	mesh_instance.mesh = sphere
	mesh_instance.scale = Vector3(size, size, size)

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if on_top:
		material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
	mesh_instance.material_override = material

	container.add_child(mesh_instance)

	var label := Label3D.new()
	label.text = "[%d, %d]" % [grid_coords.x, grid_coords.y]
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 16
	label.outline_size = 4
	label.outline_modulate = Color.BLACK
	label.modulate = Color.WHITE
	label.no_depth_test = true
	label.position = Vector3(0, size * 1.5, 0)

	container.add_child(label)

	return container
