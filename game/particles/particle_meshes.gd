class_name ParticleMeshes
extends RefCounted

## LAS TRES MALLAS DE PARTÍCULA DEL JUEGO. Todo sistema de partículas (ver ParticleSystems) dibuja con UNA DE
## ESTAS TRES, nunca con una malla propia: así todo lo que humea, chispea o salpica pertenece a la misma
## familia visual, y una malla mejor se cambia acá una vez y la usan todos.
##
##   · LÍNEA (`Kind.LINE`): una tira finita que se alinea con la velocidad de la partícula (chispas, estelas,
##     lluvia). El sistema le prende `particle_flag_align_y`: la tira va a lo largo de su Y, así una chispa sale
##     apuntando adonde va. Son DOS TIRAS CRUZADAS en ángulo recto (4 triángulos), y NO es billboard: mirar a la
##     cámara reemplaza la orientación de la partícula —el billboard de Godot pisa la base entera— y entonces las
##     chispas salen todas paradas; cruzadas, se ven desde cualquier lado sin necesitar billboard.
##   · ESFERA (`Kind.SPHERE`): un icosaedro —20 caras, lo mínimo para que se lea redondo— de verdad en 3D, con
##     las caras planas (humo, bocanadas, polvo). SE ATRAVIESA CON LAS DEMÁS como cualquier malla: escribe
##     profundidad (ver `_material` y `writes_depth`).
##   · CUADRADO (`Kind.SQUARE`): un cuadrado plano de cara a la cámara —no un cubo— (destellos, papeles, hojas).
##
## Cada una mide UNA UNIDAD (la esfera, de diámetro; el cuadrado, de lado; la línea, de largo, por `LINE_WIDTH`
## de ancho, a lo largo de su Y), así el tamaño lo pone el sistema en metros con `scale_min`/`scale_max`.
##
## COLORES PLANOS: el material no se sombrea y toma el color de cada partícula tal cual (`vertex_color_use_as_albedo`
## sobre el color que le da el sistema), con alfa. Una partícula es una mancha de color, no un objeto iluminado.

enum Kind { LINE, SPHERE, SQUARE }

## Cómo se llama cada una (panel del sandbox).
const NAMES := {Kind.LINE: "línea", Kind.SPHERE: "esfera", Kind.SQUARE: "cuadrado"}

## Ancho de la tira, como fracción de su largo.
const LINE_WIDTH := 0.12
## Caras del icosaedro.
const SPHERE_FACES := 20

static var _meshes := {}


## La malla de un tipo, con su material. Compartida: todos los sistemas que usan ese tipo dibujan la misma.
static func mesh(kind: Kind) -> Mesh:
	var cached: Mesh = _meshes.get(kind)
	if cached != null:
		return cached
	var made: Mesh
	match kind:
		Kind.SPHERE:
			made = _icosahedron()
		Kind.LINE:
			made = _strip(LINE_WIDTH)
		_:
			made = _quad()
	made.surface_set_material(0, _material(kind))
	_meshes[kind] = made
	return made


## Si la partícula se alinea con su velocidad: la tira sí (va a lo largo), la esfera y el cuadrado no.
static func aligns_to_velocity(kind: Kind) -> bool:
	return kind == Kind.LINE


## Si la malla escribe profundidad y se atraviesa con las otras: la esfera sí, porque es un cuerpo (ver
## `_material`). La tira y el cuadrado son superficies sin volumen —dos planos cruzados y un billboard—: con
## profundidad se recortarían a sí mismas y contra la que tienen al lado, que es justo lo que no se quiere de una
## chispa o un destello. Quien emite tiene que dibujarlas de atrás para adelante (`ParticleSystems._emitter`).
static func writes_depth(kind: Kind) -> bool:
	return kind == Kind.SPHERE


static func _material(kind: Kind) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	match kind:
		Kind.SPHERE:
			# Con alfa, las caras de atrás de la esfera se verían a través de las de adelante.
			material.cull_mode = BaseMaterial3D.CULL_BACK
			# ESCRIBE PROFUNDIDAD, como cualquier malla. Por defecto una superficie transparente no deja huella en
			# el z-buffer, y entonces dos esferas que se cruzan en el aire NO SE RECORTAN: una se compone entera
			# encima de la otra, sin la línea de intersección, y las dos se leen como calcomanías por más que la
			# malla sea un cuerpo. Con la huella puesta se atraviesan de verdad.
			#
			# El precio: una esfera semitransparente ahora TAPA lo que otro emisor dibuje después detrás de ella,
			# en vez de dejarlo transparentar. Dentro de un mismo emisor no pasa —las ordena por profundidad,
			# ver `ParticleSystems._emitter`—; entre dos emisores pegados (el fuego y el humo de una chatarra) el
			# de adelante puede comerse al de atrás. Se elige el recorte: es lo que hace que parezcan cuerpos.
			material.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		Kind.LINE:
			# Sin billboard, a propósito: la tira la orienta la partícula (ver arriba). Se ve de los dos lados.
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_:
			material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			material.billboard_keep_scale = true
			material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## El cuadrado: un plano de una unidad de lado, centrado.
static func _quad() -> ArrayMesh:
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, quad.get_mesh_arrays())
	return out


## La tira: dos planos cruzados en ángulo recto, de una unidad de largo (en Y) por `width` de ancho, centrados. Sin
## billboard, la partícula la orienta; cruzada, nunca se la ve de canto.
static func _strip(width: float) -> ArrayMesh:
	var half := width * 0.5
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var idx := PackedInt32Array()
	for plane in 2:
		var across := Vector3(half, 0.0, 0.0) if plane == 0 else Vector3(0.0, 0.0, half)
		var normal := Vector3.BACK if plane == 0 else Vector3.RIGHT
		var up := Vector3(0.0, 0.5, 0.0)
		var base := verts.size()
		for corner: Vector3 in [-across - up, across - up, across + up, -across + up]:
			verts.append(corner)
			normals.append(normal)
		idx.append_array(PackedInt32Array([base, base + 1, base + 2, base, base + 2, base + 3]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = idx
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## El icosaedro de diámetro 1, con las caras planas. Los 12 vértices son los del sólido (las tres parejas de
## rectángulos áureos); las caras salen de buscar los triángulos de lado mínimo, que son sus 20 caras, en vez de
## copiar una tabla de índices a mano.
static func _icosahedron() -> ArrayMesh:
	var phi := (1.0 + sqrt(5.0)) * 0.5
	var points: Array[Vector3] = []
	for a: float in [-1.0, 1.0]:
		for b: float in [-1.0, 1.0]:
			points.append(Vector3(0.0, a, b * phi).normalized())
			points.append(Vector3(a, b * phi, 0.0).normalized())
			points.append(Vector3(b * phi, 0.0, a).normalized())
	# Los 12 vértices normalizados no llegan a ±1 en los ejes: se agrandan hasta que sí, así la esfera mide una
	# unidad de punta a punta y el tamaño que pide un sistema es el que se ve.
	var reach := 0.0
	for p in points:
		reach = maxf(reach, maxf(absf(p.x), maxf(absf(p.y), absf(p.z))))
	for i in points.size():
		points[i] /= reach
	var edge := INF
	for i in points.size():
		for j in range(i + 1, points.size()):
			edge = minf(edge, points[i].distance_to(points[j]))
	var unit := UnitMesh.new()
	var centre := Vector3(0.5, 0.5, 0.5)
	for i in points.size():
		for j in range(i + 1, points.size()):
			if points[i].distance_to(points[j]) > edge * 1.1:
				continue
			for k in range(j + 1, points.size()):
				if points[i].distance_to(points[k]) > edge * 1.1 or points[j].distance_to(points[k]) > edge * 1.1:
					continue
				unit.add_tri(centre + points[i] * 0.5, centre + points[j] * 0.5, centre + points[k] * 0.5,
					centre, Color.WHITE)
	if unit.triangle_count() != SPHERE_FACES:
		push_warning("ParticleMeshes: el icosaedro salió con %d caras" % unit.triangle_count())
	return unit.build_mesh(Vector3.ONE, centre)
