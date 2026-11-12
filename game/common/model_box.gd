class_name ModelBox
extends RefCounted

## LOS MODELOS DE TAMAÑO FIJO: una CAJA que sale del juego, se modela a mano en Blender y vuelve como .glb (ver
## docs/technical/model-boxes.md, y el concepto en docs/planes-maestros/conceptos/modelos-fijos-y-parametricos.md).
## Acá están las dos puntas del lado de Godot: ESCRIBIR LA CAJA —un .json en `art-source/`, que un script de Blender
## vuelve un .blend listo para modelar— y CARGAR EL MODELO cuando existe.
##
## ── LA CAJA MANDA ────────────────────────────────────────────────────────────────────────────────
## Al revés que el auto pobre (ver CarImport), donde la caja sigue las proporciones del modelo: acá la caja es del
## juego —el collider, las celdas, lo que ocupa— y se modela ADENTRO de ella, a escala real. Por eso al cargar no se
## escala nada; sólo se avisa si algo asoma, porque lo que asoma atraviesa paredes que el collider no.
##
## ── DOS CAJAS: LA FÍSICA Y LA VISUAL ─────────────────────────────────────────────────────────────
## La caja de arriba es la FÍSICA: el collider, las celdas, el agarre, lo que ocupa. Un objeto puede tener además una
## caja VISUAL más grande (`visual`, en los ejes del objeto): lo que se dibuja y no choca ni se agarra —los aros de la
## vasija, lo que sobresale de un componente hacia quien lo mira—. Sin `visual`, las dos son la misma, como siempre.
## Lo que asoma se mide contra la visual; la física no se toca.
##
## ── SI NO HAY MODELO, NO CAMBIA NADA ─────────────────────────────────────────────────────────────
## `load_into` no devuelve nada y quien llama dibuja lo de siempre (el boceto de código). Así se puede ir modelando
## de a uno, y mientras no haya un .glb el juego se ve exactamente como antes.
##
## ── LOS EJES ─────────────────────────────────────────────────────────────────────────────────────
## En Blender el frente del modelo mira a −Y, que es la vista de frente (la tecla 1 del teclado numérico), y arriba
## es +Z. En el juego el frente es −Z y arriba +Y. La caja se escribe ya en los ejes de Blender (`to_blender`), y el
## .glb, que el importador de glTF pasa a los ejes de Godot con el frente mirando a +Z, se gira media vuelta al
## cargarlo. Se modela en metros, con la caja centrada en el origen.
##
## ── LO QUE TRAE EL MODELO ADEMÁS DE LA FORMA ─────────────────────────────────────────────────────
## · PUNTOS CON NOMBRE: un vacío (empty) de Blender llamado `PUNTO_algo` llega como un nodo y se devuelve como
##   transformada, para lo que el código tiene que seguir mandando —dónde se agarra, el eje de lo que se mueve, el
##   pivote de una aguja— (ver `load_into`).
## · PIEZAS: cada objeto de Blender llega con su nombre, así una parte móvil se modela aparte y se encuentra por
##   nombre.
## · COLOR: el color base de cada material de Blender. Sin texturas: el juego pinta con colores planos, y quien
##   carga decide con qué material (`make_material`), así un paquete modelado se oscurece con el daño igual que su
##   boceto.

## Dónde viven los modelos: `assets/models/<área>/<nombre>.glb`.
const MODELS_DIR := "res://assets/models"
## Dónde viven las cajas y los .blend de trabajo: `art-source/<área>/`. Godot no importa esa carpeta.
const ART_DIR := "res://art-source"
## El prefijo de los vacíos que son puntos con nombre.
const POINT_PREFIX := "PUNTO_"
## Cuánto puede asomar el modelo de su caja antes de avisar, en metros: lo que no se ve.
const SLACK := 0.002

static func glb_path(area: String, key: String) -> String:
	return "%s/%s/%s.glb" % [MODELS_DIR, area, key]


## Si hay modelo: importado por Godot, o recién exportado y todavía sin importar (el sandbox lo trae sin reiniciar,
## ver SandboxModels; en un export sólo cuenta el importado, que es lo que va en el .pck).
static func has_model(area: String, key: String) -> bool:
	var path := glb_path(area, key)
	return ResourceLoader.exists(path) or FileAccess.file_exists(path)


## LOS MODELOS TRAÍDOS EN ESTA SESIÓN (ver SandboxModels, la tecla F5): se cargan del .glb directo, sin el
## importador. Lo importado queda en caché con la versión de antes, y el editor recién lo reimporta la próxima vez
## que abre: sin esto, un modelo que se volvió a exportar se seguiría viendo como era. Medido al construirlo: el
## .glb cargado así da los mismos nodos, nombres, posiciones y medidas que importado.
static var _fresh := {}


## Que `area/key` se vuelva a leer del .glb, ya: lo pide el sandbox después de exportarlo.
static func forget(area: String, key: String) -> void:
	_fresh[glb_path(area, key)] = true


## El modelo instanciado, fuera del árbol: lo importado, o el .glb leído en el momento si es nuevo o se trajo en esta
## sesión. Null si no se puede leer.
static func _instantiate(path: String) -> Node3D:
	if _fresh.has(path) or not ResourceLoader.exists(path):
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		if document.append_from_file(ProjectSettings.globalize_path(path), state) != OK:
			return null
		return document.generate_scene(state) as Node3D
	var scene := load(path) as PackedScene
	return scene.instantiate() as Node3D if scene != null else null


## CARGA EL MODELO de `area/key` como hijos de `parent`, si existe. Cada superficie de cada malla queda como una
## pieza propia, con el material que da `make_material(color)` —el color base del material de Blender—: el mismo
## camino que un boceto de primitivas, así lo que se le hace a un boceto (el daño, la vista traslúcida) se le hace
## igual al modelo.
##
## Devuelve `{"points": nombre → transformada, "parts": nombre → MeshInstance3D}`, en los ejes del objeto; VACÍO si
## no hay modelo, y entonces no toca nada.
static func load_into(parent: Node3D, area: String, key: String, box: Vector3, make_material: Callable,
		visual := AABB()) -> Dictionary:
	if not has_model(area, key):
		return {}
	var source := _instantiate(glb_path(area, key))
	if source == null:
		push_warning("[ModelBox] %s no se pudo leer: se queda el boceto." % glb_path(area, key))
		return {}
	var points := {}
	var parts := {}
	# El importador de glTF deja el frente mirando a +Z; el juego lo quiere en −Z (ver el bloque de arriba).
	var turn := Transform3D(Basis(Vector3.UP, PI), Vector3.ZERO)
	var bounds := AABB()
	var first := true
	for node in source.find_children("*", "Node3D", true, false):
		var at := turn * _relative(source, node as Node3D)
		if node.name.begins_with(POINT_PREFIX):
			points[node.name.trim_prefix(POINT_PREFIX)] = at
			continue
		var mesh_node := node as MeshInstance3D
		if mesh_node == null or mesh_node.mesh == null:
			continue
		for surface in mesh_node.mesh.get_surface_count():
			var piece := MeshInstance3D.new()
			piece.name = "%s_%d" % [mesh_node.name, surface] if surface > 0 else String(mesh_node.name)
			piece.mesh = _surface_mesh(mesh_node.mesh, surface)
			piece.transform = at
			piece.material_override = make_material.call(_surface_color(mesh_node, surface))
			parent.add_child(piece)
			if surface == 0:
				parts[String(mesh_node.name)] = piece
			var piece_bounds := at * piece.mesh.get_aabb()
			bounds = piece_bounds if first else bounds.merge(piece_bounds)
			first = false
	source.free()
	var allowed := visual_box(box, visual).grow(SLACK)
	if not first and not allowed.encloses(bounds):
		push_warning("[ModelBox] %s asoma de su caja visual (%s en %s)." % [glb_path(area, key), bounds, allowed])
	return {"points": points, "parts": parts}


## LA CAJA VISUAL de un objeto: `visual` si la tiene, y si no, la física (`box`, centrada en el origen).
static func visual_box(box: Vector3, visual := AABB()) -> AABB:
	return visual if visual.has_volume() else AABB(-box * 0.5, box)


## LA TRANSFORMADA DE `node` RESPECTO DE `root`, sin que estén en el árbol: el .glb recién instanciado no está en
## ninguna escena, así que `global_transform` no sirve.
static func _relative(root: Node3D, node: Node3D) -> Transform3D:
	var at := Transform3D.IDENTITY
	var current := node
	while current != null and current != root:
		at = current.transform * at
		current = current.get_parent() as Node3D
	return at


## Una superficie sola de una malla, como malla propia: cada pieza lleva un solo material.
static func _surface_mesh(mesh: Mesh, surface: int) -> Mesh:
	if mesh.get_surface_count() == 1:
		return mesh
	var out := ArrayMesh.new()
	out.add_surface_from_arrays(mesh.surface_get_primitive_type(surface), mesh.surface_get_arrays(surface))
	return out


## El color base del material de una superficie: el que se eligió en Blender. Gris si no tiene.
static func _surface_color(node: MeshInstance3D, surface: int) -> Color:
	var material := node.get_active_material(surface) as BaseMaterial3D
	return material.albedo_color if material != null else Color(0.5, 0.5, 0.5)


# ── La caja ──────────────────────────────────────────────────────────────────────────────────────

## UN PUNTO DE GODOT EN LOS EJES DE BLENDER, con el frente del modelo mirando a −Y (ver el bloque de arriba): la
## conversión de glTF (x, −z, y) más media vuelta alrededor de la vertical.
static func to_blender(p: Vector3) -> Array:
	return [-p.x, p.z, p.y]


## Una caja de Godot en los ejes de Blender, como [mínimo, máximo]: el cambio de ejes da vuelta un signo, así que
## las esquinas se reordenan.
static func _blender_corners(box: AABB) -> Array:
	var a := to_blender(box.position)
	var b := to_blender(box.end)
	return [[minf(a[0], b[0]), minf(a[1], b[1]), minf(a[2], b[2])],
		[maxf(a[0], b[0]), maxf(a[1], b[1]), maxf(a[2], b[2])]]


## ESCRIBE LA CAJA de `area/key` en `art-source/<área>/<nombre>.json`: lo que el script de Blender vuelve un .blend
## listo para modelar (ver art-source/tools/caja_a_blend.py). Trae el tamaño de la caja, la celda de su grilla (0
## si no tiene), los puntos con nombre y el boceto de hoy como referencia —cada pieza de `reference` con sus
## triángulos y su color—. Se puede volver a escribir sin miedo: el .blend, que es el trabajo, no se toca.
##
## `points` es nombre → posición en los ejes del juego; `reference` es un nodo cuyas piezas se copian. `start`, si
## está, son piezas que el .blend pone ya en MODELO, editables, para arrancar de ellas en vez de modelar de cero.
static func write_box(area: String, key: String, title: String, box: Vector3, cell: float,
		points_in: Dictionary, reference: Node3D, visual := AABB(), start: Node3D = null) -> String:
	var spec := {
		"nombre": key,
		"titulo": title,
		"area": area,
		"caja": to_blender(box).map(func(v: float) -> float: return absf(v)),
		"caja_visual": _blender_corners(visual_box(box, visual)),
		"celda": cell,
		"salida": "assets/models/%s/%s.glb" % [area, key],
		"puntos": [],
		"boceto": [],
		"inicio": [],
	}
	for point_name: String in points_in:
		spec["puntos"].append({"nombre": point_name, "pos": to_blender(points_in[point_name])})
	if reference != null:
		for node in reference.find_children("*", "MeshInstance3D", true, false):
			# Los cables se arman sólo en código (ver NetworkParts.CABLE_MESH): no llegan a la caja, ni su lugar.
			if node.has_meta(NetworkParts.CABLE_MESH):
				continue
			var piece := _reference_piece(reference, node as MeshInstance3D)
			if not piece.is_empty():
				# Las piezas sin nombre propio (`@MeshInstance3D@9`) llegan a Blender numeradas.
				if String(piece["nombre"]).begins_with("@"):
					piece["nombre"] = "boceto_%d" % spec["boceto"].size()
				spec["boceto"].append(piece)
	if start != null:
		for node in start.find_children("*", "MeshInstance3D", true, false):
			var piece := _reference_piece(start, node as MeshInstance3D)
			if not piece.is_empty():
				spec["inicio"].append(piece)
	var dir := ProjectSettings.globalize_path("%s/%s" % [ART_DIR, area])
	DirAccess.make_dir_recursive_absolute(dir)
	var path := "%s/%s.json" % [dir, key]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[ModelBox] No se pudo escribir %s" % path)
		return ""
	file.store_string(JSON.stringify(spec, "\t"))
	return path


## Una pieza del boceto como triángulos en los ejes de Blender, con su color. Las primitivas (cajas, cilindros,
## toros) se arman en la CPU, así que esto anda también sin ventana.
static func _reference_piece(root: Node3D, node: MeshInstance3D) -> Dictionary:
	var arrays: Array = []
	if node.mesh is PrimitiveMesh:
		arrays = (node.mesh as PrimitiveMesh).get_mesh_arrays()
	elif node.mesh != null and node.mesh.get_surface_count() > 0:
		arrays = node.mesh.surface_get_arrays(0)
	if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX] == null:
		return {}
	var at := _relative(root, node)
	var vertices: Array = []
	for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		vertices.append_array(to_blender(at * v))
	var order := PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] != null:
		order = arrays[Mesh.ARRAY_INDEX]
	else:
		for i in (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size():
			order.append(i)
	# EL BOBINADO SE DA VUELTA: en Godot el frente de un triángulo es el horario, en Blender el antihorario, y la
	# conversión de ejes no lo cambia (es una rotación). Sin esto el boceto llega a Blender con las caras del revés.
	var indices: Array = []
	for t in range(0, order.size() - 2, 3):
		indices.append_array([order[t], order[t + 2], order[t + 1]])
	var color := Color(0.5, 0.5, 0.5)
	var material := node.material_override
	if material is ShaderMaterial and (material as ShaderMaterial).get_shader_parameter("tint") != null:
		color = (material as ShaderMaterial).get_shader_parameter("tint")
	elif material is BaseMaterial3D:
		color = (material as BaseMaterial3D).albedo_color
	return {"nombre": String(node.name), "color": [color.r, color.g, color.b], "vertices": vertices,
		"indices": indices}
