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
