class_name CharacterInspectorSource
extends InspectorSource

## APUNTÁ A UN PERSONAJE Y DECIME QUÉ ES — el resolvedor de mallas, huesos, caras y vértices.
##
## Existe para UNA cosa: mirar la topología de los personajes mientras se los esculpe por código (ver
## ProceduralBodyUtil). No es un inspector de geometría del mundo y no tiene por qué serlo — a un ladrillo
## de un edificio nadie le va a querer el id de un vértice, y la ciudad ya se identifica preguntándole al
## índice, que es gratis. Acá se baja al triángulo porque es el único lugar donde hace falta.
##
## ── CADA MODO DEFINE QUÉ ES UN "ELEMENTO" ────────────────────────────────────────────────────────
## No hay cuatro sistemas de apuntado, hay UNO: el rayo contra los triángulos de la piel. Lo que cambia
## por modo es QUÉ ELEMENTO devuelve ese impacto, y cada elemento trae puesto qué hacer con él:
##
##   · MALLAS   → la malla entera. Apretar la pone EN ESTUDIO y apretar de nuevo sale: la forma de salir es
##                el mismo gesto, sobre la única pieza que quedó en pantalla. Con CTRL esconde solo esa,
##                que es para pelar capas de adelante hacia atrás.
##
## ── EL ESTUDIO DE UNA PARTE ES EL FLUJO, NO UN EXTRA ─────────────────────────────────────────────
## Aislar sirve para UNA cosa: mirarle la geometría de cerca. Así que no es solo esconder a las vecinas —
## la parte en estudio se dibuja como el modo sólido de Blender: la malla real, sólida, con SUS ARISTAS
## encima y CON PROFUNDIDAD, así la superficie tapa las aristas de atrás. Un alambre de rayos X muestra los
## dos lados superpuestos y no se puede leer, que es lo que hacía imposible analizar nada.
##
## Y el estado vive en el CUERPO (`CharacterBodyVisual.study_part`), no acá: cualquier toggle del panel
## recalcula qué se ve, así que con el estado afuera prender el alambre devolvía todas las partes. Lo mismo
## vale para el próximo modo: sea brazo, pierna o cara, el estudio es de la parte y lo sabe la parte.
##
## El estudio SOBREVIVE AL CAMBIO DE MODO a propósito: poner el torso en estudio y pasar a caras o a
## vértices es el flujo entero.
##   · HUESOS   → el hueso que más pesa en el triángulo. Resaltarlo PINTA SUS PESOS sobre las mallas que
##                mueve, con la rampa de Blender. (Es un gancho del elemento, no un modo del inspector:
##                el inspector no sabe lo que es un peso — ver InspectorPick.)
##   · CARAS    → el triángulo, con su id y sus tres esquinas.
##   · VÉRTICES → la esquina más cercana al impacto, con su id, y las caras que la tocan. Un vértice es
##                demasiado chico para rellenarlo, así que se marca con un diamante: eso es "aproximarse
##                a los vértices por las caras" y no hay un collider por vértice en ningún lado.
##
## El próximo modo (loop cuts) entra igual: un elemento más, con su propio gancho para abrirle opciones.
##
## ── EL COSTO ESTÁ ACOTADO A PROPÓSITO ────────────────────────────────────────────────────────────
## Las mallas son SKINNEADAS: `surface_get_arrays` devuelve el REPOSO y el posado lo hace la GPU, así que
## para acertarle a una cara con el personaje en cualquier pose hay que skinnear en CPU
## —`Σ wᵢ · global(huesoᵢ) · bindᵢ · v`—. Son ~7000 vértices por personaje: impensable por frame.
##
## Pero resolver POR FRAME es lo que hace que la herramienta se sienta como el resto del inspector, y con
## un personaje que CAMINA es la única opción: un impacto resuelto una vez se queda flotando donde el
## personaje estaba. Así que el rayo se descarta en tres pasos, de barato a caro:
##
##   1. la distancia del rayo al centro de la cápsula de cada personaje;
##   2. la distancia del rayo a los huesos QUE ESA MALLA USA DE VERDAD — de ahí salen 3 candidatas y no 9;
##   3. el AABB de la malla ya skinneada, antes de mirarle un solo triángulo.
##
## ⚠ "LOS HUESOS QUE ESA MALLA USA" SALEN DE SUS PESOS, NO DE SU `Skin`. Las nueve partes del cuerpo
## comparten UN solo `Skin` —uno por esqueleto, con un bind por hueso (ver ProceduralBodyUtil)—, así que
## preguntarle a qué huesos está atada una malla devuelve LOS DIECINUEVE para todas. Con eso las nueve
## partes empataban en puntaje y las candidatas salían siempre las dos primeras de la lista: el torso y la
## cabeza, y los brazos, las piernas y los pies no se podían apuntar nunca.
##
## Los arrays de reposo, la lista de aristas y la de huesos usados se cachean por malla: la geometría se
## genera una vez y no cambia más, así que leerlos por frame era copiar los mismos 7000 vértices para nada.
##
## ⚠ UN PERSONAJE PUEDE SER MÁS GRANDE QUE OTRO, y no por una escala de nodo: la lupa del sandbox agranda
## sus TAMAÑOS (ver SkeletonSizesUtil.size_scale), así que sus huesos y sus mallas son más grandes de
## verdad. Todo lo que acá se compara contra una distancia —los dos alcances del descarte, el tamaño del
## puntito, el ancho del gizmo del hueso— se multiplica por `_draw_scale`. Sin eso, a ×3 el rayo no
## enganchaba nada por encima del pecho (el alcance es del orden de media persona) y el gizmo del hueso
## salía del grosor de un alfiler.
##
## ── LO QUE NO SABE ───────────────────────────────────────────────────────────────────────────────
## Nada de arquetipos, de generadores ni de qué parte del cuerpo es cada malla. Pregunta por el grupo de
## personajes, le pide al cuerpo visible su lista de mallas (`CharacterBodyVisual.meshes`) y trabaja con
## eso. Un cuerpo nuevo —otra implementación de `CharacterBodyVisual`— aparece acá solo, con la única
## condición de llenar esa lista. Vale para los dos cuerpos de hoy.

enum Mode {MESH, BONE, FACE, VERTEX}

## EL MODO ES ESTÁTICO, igual que los toggles de `CharacterDebugView`: sobrevive al respawn y al cambio de
## mundo, que es lo que uno espera de un modo de debug. El inspector se rehace en cada respawn.
static var mode: Mode = Mode.MESH

## PASO 1 del descarte: a qué distancia del centro de un personaje tiene que pasar el rayo para que valga
## mirarle las mallas. Del orden de "media persona más un brazo estirado". Los dos alcances se multiplican
## por la escala del cuerpo dibujado: con la lupa puesta, el personaje mide el triple.
const BODY_REACH := 1.8
## PASO 2: a qué distancia de un hueso que la malla usa tiene que pasar el rayo para que sea candidata.
const BONE_REACH := 0.9
## Cuántas candidatas se skinnean. Cuatro, porque en una costura se superponen hasta tres partes —el hombro
## es torso, brazo y cuello— y la que gana es la que el rayo toca primero, no la que está más cerca de un
## hueso; y en la del cuello con la cabeza, la tinta de la cara es una malla más del mismo hueso que la cabeza, así
## que con tres el cuello quedaba afuera (15/10/2026, con la cabeza nueva, que ya no baja una pollera sobre el cuello).
const CANDIDATES := 4

## El ancho del hueso que se dibuja resaltado, en metros. Un hueso es una LÍNEA y una línea de 1 píxel no
## se ve contra el cuerpo, así que se dibuja como el octaedro de Blender.
const BONE_WIDTH := 0.022
## El radio del diamante que marca un vértice, en metros.
const DOT_SIZE := 0.011
## Por debajo de esto un hueso no tiene largo y no hay octaedro que dibujarle.
const EPSILON := 1e-5

## LOS PESOS, PINTADOS COMO EN BLENDER: azul lo que ese hueso no mueve, verde el medio, rojo lo que mueve
## del todo.
const WEIGHT_COLD := Color(0.1, 0.2, 0.9)
const WEIGHT_MID := Color(0.1, 0.9, 0.3)
const WEIGHT_HOT := Color(1.0, 0.15, 0.1)

## Lo último que resolvió el rayo. Vive acá y no en el pick porque los ganchos lo necesitan.
var _bi: BoneInstantiator = null
var _skeleton: Skeleton3D = null
var _mesh: MeshInstance3D = null
var _skinned := PackedVector3Array()
var _index := PackedInt32Array()
var _bones := PackedInt32Array()
var _weights := PackedFloat32Array()
var _face := -1
var _vertex := -1
var _bone := -1
var _point := Vector3.ZERO

## Los cuerpos a los que este resolvedor les cambió qué partes se ven, para poder devolverlos. Lo que
## cambió lo sabe cada cuerpo (ver CharacterBodyVisual.study_part); acá solo se anota a quién.
var _touched: Array[CharacterBodyVisual] = []
var _painted: Array[MeshInstance3D] = []
var _painted_meshes: Array[Mesh] = []
var _painted_overrides: Array[Material] = []

## Por malla: los arrays de reposo, la lista de aristas y los huesos que usa. Ver el encabezado.
var _cache: Dictionary = {}


static func mode_name() -> String:
	match mode:
		Mode.BONE:
			return "huesos"
		Mode.FACE:
			return "caras"
		Mode.VERTEX:
			return "vértices"
		_:
			return "mallas"


func has_modes() -> bool:
	return true


func mode_label() -> String:
	return mode_name()


func cycle_mode() -> void:
	mode = ((int(mode) + 1) % Mode.size()) as Mode


# ── RESOLVER ────────────────────────────────────────────────────────────────────────────────────

func aim(tree: SceneTree, from: Vector3, to: Vector3) -> InspectorPick:
	_forget()
	if tree == null:
		return null
	var dir := to - from
	var reach := dir.length()
	if reach < 0.001:
		return null
	dir /= reach

	var best := reach
	var hit: Dictionary = {}
	for rb in tree.get_nodes_in_group(CharacterRigidBody3D.CHARACTER_GROUP):
		var bi := (rb as Node).get_parent() as BoneInstantiator
		if not is_instance_valid(bi) or not is_instance_valid(bi.body_visual):
			continue
		var drawn := _draw_scale(bi)
		if _ray_distance((rb as Node3D).global_position, from, dir, reach) > BODY_REACH * drawn:
			continue
		var skeleton := _skeleton_of(bi.body_visual)
		for m in _candidates(bi.body_visual, skeleton, from, dir, reach, drawn):
			var found := _probe_mesh(m, skeleton, from, dir, best)
			if found.is_empty():
				continue
			best = float(found["distance"])
			hit = found
			_bi = bi
			_skeleton = skeleton
			_mesh = m

	if hit.is_empty():
		_forget()
		return null

	_point = hit["point"]
	_face = int(hit["face"])
	_skinned = hit["skinned"]
	_index = hit["index"]
	_bones = hit["bones"]
	_weights = hit["weights"]
	_vertex = _nearest_vertex()
	_bone = _dominant_bone()
	return _describe()


## Las mallas que vale la pena skinnear, las más cerca del rayo primero.
##
## El puntaje de una malla es la distancia del rayo al hueso MÁS CERCANO DE LOS QUE LA MUEVEN, y cuáles son
## sale de SUS PESOS y no de su `Skin` — ver el encabezado, el `Skin` es compartido y los nombra todos. Sin
## esto habría que skinnear las nueve partes del cuerpo para descubrir que el rayo le pegó a la cabeza.
func _candidates(body: CharacterBodyVisual, skeleton: Skeleton3D, from: Vector3, dir: Vector3,
		reach: float, drawn: float) -> Array[MeshInstance3D]:
	var scored: Array = []
	for m in body.meshes:
		if not is_instance_valid(m) or m.mesh == null or not m.visible:
			continue
		var score := INF
		var used := _bones_used(m, skeleton)
		if skeleton != null and not used.is_empty():
			var to_world := skeleton.global_transform
			for at in used:
				var world: Vector3 = to_world * skeleton.get_bone_global_pose(at).origin
				score = minf(score, _ray_distance(world, from, dir, reach))
		else:
			# El cuerpo de cápsulas no tiene esqueleto: sus mallas cuelgan del hueso y su nodo YA está
			# donde se ve.
			score = _ray_distance(m.global_position, from, dir, reach)
		if score <= BONE_REACH * drawn:
			scored.append([score, m])

	scored.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var out: Array[MeshInstance3D] = []
	for entry in scored:
		if out.size() >= CANDIDATES:
			break
		out.append(entry[1] as MeshInstance3D)
	return out


## Skinnea una malla y le tira el rayo. Vacío si no le pega más cerca que `limit`.
func _probe_mesh(m: MeshInstance3D, skeleton: Skeleton3D, from: Vector3, dir: Vector3,
		limit: float) -> Dictionary:
	var data := _mesh_data(m)
	if data.is_empty():
		return {}
	var index: PackedInt32Array = data["index"]
	var skinned := _skin(m, skeleton, data["rest"], data["bones"], data["weights"])

	# PASO 3 del descarte: el AABB de lo ya skinneado, antes de mirar un triángulo.
	var box := AABB(skinned[0], Vector3.ZERO)
	for v in skinned:
		box = box.expand(v)
	if not box.grow(0.001).intersects_ray(from, dir):
		return {}

	var best := limit
	var best_face := -1
	var best_point := Vector3.ZERO
	for t in index.size() / 3:
		var a: Vector3 = skinned[index[t * 3]]
		var b: Vector3 = skinned[index[t * 3 + 1]]
		var c: Vector3 = skinned[index[t * 3 + 2]]
		var at = Geometry3D.ray_intersects_triangle(from, dir, a, b, c)
		if at == null:
			continue
		var distance: float = (at as Vector3).distance_to(from)
		if distance >= best:
			continue
		best = distance
		best_face = t
		best_point = at

	if best_face < 0:
		return {}
	return {"distance": best, "face": best_face, "point": best_point, "skinned": skinned,
		"index": index, "bones": data["bones"], "weights": data["weights"]}


# ── EL ELEMENTO DE CADA MODO ────────────────────────────────────────────────────────────────────

func _describe() -> InspectorPick:
	var pick := InspectorPick.new()
	# ¿LA PARTE APUNTADA ES LA QUE SE ESTÁ ESTUDIANDO? Eso cambia CÓMO se dibuja todo lo demás.
	var studied: bool = is_instance_valid(_bi.body_visual) \
			and _bi.body_visual.studied.has(String(_mesh.name))
	pick.xray = not studied
	# UN PERSONAJE SE MUEVE: las capas se rearman por frame aunque no cambie lo apuntado. Es la diferencia
	# con la ciudad, que está quieta y se arma una vez.
	pick.live = true
	pick.centre = _point
	var who: String = str(_bi.get_path()) if _bi.is_inside_tree() else String(_bi.name)
	# El puntito al tamaño del cuerpo: el de la ciudad son 35 cm y sobre una cara tapa media cabeza. La
	# escala del cuerpo DIBUJADO va incluida, porque con la lupa puesta mide el triple.
	var body_scale := _draw_scale(_bi)
	var faces: int = _index.size() / 3

	match mode:
		Mode.BONE:
			pick.key = "%s#hueso#%d" % [who, _bone]
			pick.marker_scale = 0.22 * body_scale
			var bone_lines: Array[String] = ["HUESO %s" % _bone_name(_bone),
				"pesos pintados: azul 0 · rojo 1"]
			pick.lines = bone_lines
			pick.parent_lines = _skeleton_lines(body_scale)
			var shape := _bone_shape(_bone, body_scale)
			pick.target_fill = shape
			pick.target_lines = _edges_of_shape(shape)
			# EL GANCHO, y la razón de que exista: el elemento dice qué hacer cuando lo resaltan. El
			# inspector no sabe lo que es un peso.
			pick.on_show = _paint_weights.bind(_bi, _bone)
			pick.on_hide = _unpaint
		Mode.FACE:
			pick.key = "%s#cara#%s#%d" % [who, _mesh.name, _face]
			pick.marker_scale = 0.12 * body_scale
			var face_lines: Array[String] = ["CARA %d" % _face,
				"%s · %d caras" % [_mesh.name, faces]]
			pick.lines = face_lines
			pick.parent_fill = _triangles_of(_index)
			pick.target_fill = _face_triangles(PackedInt32Array([_face]))
			pick.target_lines = _edges_of_shape(pick.target_fill)
			var corners := PackedVector3Array()
			for k in 3:
				corners.append_array(_diamond(_skinned[_index[_face * 3 + k]], DOT_SIZE * body_scale))
			pick.dots = corners
		Mode.VERTEX:
			pick.key = "%s#vértice#%s#%d" % [who, _mesh.name, _vertex]
			pick.marker_scale = 0.12 * body_scale
			var star := _star_of(_vertex)
			var vertex_lines: Array[String] = ["VÉRTICE %d" % _vertex,
				"%s · %d vértices" % [_mesh.name, _skinned.size()],
				"%d caras lo tocan" % star.size()]
			pick.lines = vertex_lines
			pick.parent_fill = _triangles_of(_index)
			pick.target_fill = _face_triangles(star)
			pick.target_lines = _edges_of_shape(pick.target_fill)
			pick.dots = _diamond(_skinned[_vertex], DOT_SIZE * body_scale)
		_:
			pick.key = "%s#malla#%s" % [who, _mesh.name]
			pick.marker_scale = 0.22 * body_scale
			var mesh_lines: Array[String] = ["MALLA %s" % _mesh.name,
				"%d caras · %d vértices" % [faces, _skinned.size()]]
			pick.lines = mesh_lines
			pick.target_lines = _lines_of(_edge_list(_mesh, _index))
			if not studied:
				# Sin estudio hay que ENCONTRARLA entre las otras: el relleno la separa del resto y el
				# esqueleto dice de qué personaje es. En estudio no hay nada de qué separarla, y un
				# relleno encima de la malla real solo la ensucia.
				pick.parent_lines = _skeleton_lines(body_scale)
				pick.target_fill = _triangles_of(_index)
			pick.action = ("salir del estudio" if studied else "estudiarla sola") \
					+ " · ctrl+rueda = ocultarla"
			pick.on_press = _press_mesh.bind(_mesh)

	pick.report = "[personaje] modo %s\n  %s\n  malla %s · cara %d · vértice %d · hueso %s\n" \
			% [mode_name(), who, _mesh.name, _face, _vertex, _bone_name(_bone)] \
			+ "  impacto: (%.3f, %.3f, %.3f)\n  seed: %d" \
			% [_point.x, _point.y, _point.z, _bi.master_seed]
	return pick


# ── LOS GANCHOS ─────────────────────────────────────────────────────────────────────────────────

## EL BOTÓN EN MODO MALLAS: poner la apuntada en estudio, o esconderla con el modificador.
##
## El estudio es lo que uno quiere casi siempre —mirar una parte de cerca— así que es el gesto pelado, y la
## SALIDA es el MISMO gesto sobre la misma malla: no hay un estado del que haya que acordarse cómo salir,
## porque lo único que quedó en pantalla es justo lo que lo apaga. (Y `shift+rueda` sigue devolviendo todo
## desde cualquier parte, incluso apuntando al aire.)
##
## Esconder una sola queda en CTRL: sirve para pelar capas de adelante hacia atrás, que es otra cosa.
##
## Es por PERSONAJE y no por escena: en la fila del sandbox hay seis, y lo que se está mirando es una parte
## de uno — esconder los otros cinco sería perder la comparación, que es para lo que está la fila.
func _press_mesh(alternate: bool, m: MeshInstance3D) -> void:
	if not is_instance_valid(m) or not is_instance_valid(_bi) \
			or not is_instance_valid(_bi.body_visual):
		return
	var body := _bi.body_visual
	if not _touched.has(body):
		_touched.append(body)
	var part := String(m.name)
	if alternate:
		# Una parte escondida deja de ser apuntable —a propósito— así que no se la puede esconder dos
		# veces y perderla.
		body.hide_part(part)
	elif body.studied.has(part):
		body.show_all_parts()
	else:
		body.study_part(part)


## LOS PESOS DE UN HUESO, PINTADOS SOBRE TODAS LAS MALLAS QUE MUEVE: azul lo que no mueve, verde el medio,
## rojo lo que mueve del todo. En todas y no solo en la apuntada porque la pregunta interesante está justo
## en las costuras —cuánto del torso se lleva el hombro—, y eso cruza dos mallas.
##
## Se pinta REEMPLAZANDO LA MALLA por una copia con color por vértice, no con un shader. El motivo es
## concreto: el skinning lo hace la GPU ANTES del shader de vértices, así que desde un shader espacial los
## pesos no se pueden leer —no están expuestos—. Y agregarle `COLOR` a todas las mallas del cuerpo en el
## generador sería pintar siempre para pintar una vez.
##
## La copia CONSERVA huesos y pesos, así que la malla pintada sigue deformándose: se le puede prender la
## marcha y ver cómo se mueve lo que ese hueso manda.
func _paint_weights(bi: BoneInstantiator, bone: int) -> void:
	_unpaint()
	if bone < 0 or not is_instance_valid(bi) or not is_instance_valid(bi.body_visual):
		return
	for m in bi.body_visual.meshes:
		if not is_instance_valid(m) or m.mesh == null or m.skin == null:
			continue
		var bind := -1
		for b in m.skin.get_bind_count():
			if m.skin.get_bind_bone(b) == bone:
				bind = b
				break
		if bind < 0:
			continue

		var arrays := m.mesh.surface_get_arrays(0)
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		if bones.is_empty():
			continue
		var count: int = (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
		var colors := PackedColorArray()
		colors.resize(count)
		for i in count:
			var w := 0.0
			for k in 4:
				if bones[i * 4 + k] == bind:
					w = weights[i * 4 + k]
					break
			colors[i] = _ramp(clampf(w, 0.0, 1.0))
		arrays[Mesh.ARRAY_COLOR] = colors

		var painted := ArrayMesh.new()
		painted.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var material := StandardMaterial3D.new()
		material.vertex_color_use_as_albedo = true
		# Sin luz: un peso es un NÚMERO y tiene que leerse igual de los dos lados del personaje. Con
		# sombreado, la mitad en sombra se ve siempre "menos pesada".
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

		_painted.append(m)
		_painted_meshes.append(m.mesh)
		_painted_overrides.append(m.material_override)
		m.mesh = painted
		m.material_override = material


func _unpaint() -> void:
	for i in _painted.size():
		var m: MeshInstance3D = _painted[i]
		if is_instance_valid(m):
			m.mesh = _painted_meshes[i]
			m.material_override = _painted_overrides[i]
	_painted.clear()
	_painted_meshes.clear()
	_painted_overrides.clear()


## Devuelve TODO lo que los ganchos dejaron puesto. Una malla escondida o pintada que no vuelve es un
## personaje roto hasta el próximo respawn, así que hay un solo camino de salida y lo llama el inspector
## al apagarse, al cambiar de modo y con el gesto de deshacer.
func undo() -> void:
	for body in _touched:
		if is_instance_valid(body):
			body.show_all_parts()
	_touched.clear()
	_unpaint()


# ── GEOMETRÍA ───────────────────────────────────────────────────────────────────────────────────

## Los triángulos de una lista de índices, en coordenadas del mundo.
func _triangles_of(indices: PackedInt32Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(indices.size())
	for i in indices.size():
		out[i] = _skinned[indices[i]]
	return out


## Los triángulos de una lista de CARAS.
func _face_triangles(faces: PackedInt32Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(faces.size() * 3)
	for f in faces.size():
		for k in 3:
			out[f * 3 + k] = _skinned[_index[faces[f] * 3 + k]]
	return out


## Las caras que tocan un vértice. Es un barrido del índice —no hay estructura de adyacencia y no hace
## falta una: son un par de miles de comparaciones de enteros.
func _star_of(at: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	if at < 0:
		return out
	for t in _index.size() / 3:
		if _index[t * 3] == at or _index[t * 3 + 1] == at or _index[t * 3 + 2] == at:
			out.append(t)
	return out


## Las líneas de una lista de pares de índices.
func _lines_of(edges: PackedInt32Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(edges.size())
	for i in edges.size():
		out[i] = _skinned[edges[i]]
	return out


## Las aristas de una lista de triángulos ya en mundo, sin deduplicar: es para formas chicas (un hueso,
## una cara), donde deduplicar cuesta más que dibujar la arista dos veces.
static func _edges_of_shape(tris: PackedVector3Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	for t in tris.size() / 3:
		var a: Vector3 = tris[t * 3]
		var b: Vector3 = tris[t * 3 + 1]
		var c: Vector3 = tris[t * 3 + 2]
		out.append_array(PackedVector3Array([a, b, b, c, c, a]))
	return out


## El diamante que marca un punto: ocho triángulos, que es lo mínimo que se lee como un volumen desde
## cualquier ángulo. Un vértice es un PUNTO y no se puede rellenar ni contornear.
static func _diamond(at: Vector3, radius: float) -> PackedVector3Array:
	var px := at + Vector3(radius, 0.0, 0.0)
	var nx := at - Vector3(radius, 0.0, 0.0)
	var py := at + Vector3(0.0, radius, 0.0)
	var ny := at - Vector3(0.0, radius, 0.0)
	var pz := at + Vector3(0.0, 0.0, radius)
	var nz := at - Vector3(0.0, 0.0, radius)
	return PackedVector3Array([
		py, px, pz, py, pz, nx, py, nx, nz, py, nz, px,
		ny, pz, px, ny, nx, pz, ny, nz, nx, ny, px, nz,
	])


## EL HUESO, COMO EL OCTAEDRO DE BLENDER: de su nacimiento a su punta, con cuatro puntas al 15%. Una línea
## de 1 píxel sobre un cuerpo claro no se ve, y el ancho de línea en Godot no se puede cambiar.
func _bone_shape(bone: int, body_scale: float) -> PackedVector3Array:
	var pose := _bone_pose(bone)
	# EL LARGO NO SE MULTIPLICA: el hueso de un personaje grande YA es largo (la lupa agranda sus tamaños,
	# no escala un nodo). Lo que sí escala es el ANCHO, que es un metro absoluto de este archivo. Estuvo
	# multiplicado y el gizmo salía ×9 en un personaje al triple.
	var length := _bone_length(bone, body_scale)
	if length < EPSILON:
		return PackedVector3Array()
	var base := pose.origin
	var axis: Vector3 = pose.basis.y.normalized()
	var side: Vector3 = pose.basis.x.normalized() * BONE_WIDTH * body_scale
	var ahead: Vector3 = pose.basis.z.normalized() * BONE_WIDTH * body_scale
	var tip := base + axis * length
	var ring := base + axis * (length * 0.15)
	var a := ring + side
	var b := ring + ahead
	var c := ring - side
	var d := ring - ahead
	return PackedVector3Array([
		base, a, b, base, b, c, base, c, d, base, d, a,
		tip, b, a, tip, c, b, tip, d, c, tip, a, d,
	])


## El esqueleto entero como líneas: es la marca del OBJETO PADRE, el equivalente del relleno oscuro del
## edificio en la ciudad. Son 19 segmentos leídos de las poses, así que cuesta nada y se puede rearmar por
## frame mientras el personaje camina.
func _skeleton_lines(body_scale: float) -> PackedVector3Array:
	var out := PackedVector3Array()
	if _skeleton == null:
		return out
	for i in _skeleton.get_bone_count():
		var pose := _bone_pose(i)
		var length := _bone_length(i, body_scale)
		if length < EPSILON:
			continue
		out.append(pose.origin)
		out.append(pose.origin + pose.basis.y.normalized() * length)
	return out


## La pose de un hueso del esqueleto de dibujo, en coordenadas del mundo. Lleva la escala del cuerpo.
func _bone_pose(bone: int) -> Transform3D:
	if _skeleton == null or bone < 0 or bone >= _skeleton.get_bone_count():
		return Transform3D()
	return _skeleton.global_transform * _skeleton.get_bone_global_pose(bone)


## EL LARGO DE UN HUESO, en metros del mundo: el del rig, que ya viene a la escala del personaje.
##
## Sale del `CustomBone` del rig, buscado POR NOMBRE: el esqueleto de dibujo espeja al rig y usa sus mismos
## nombres (ver ProceduralBodyUtil.FIELDS). Un hueso que el rig no tiene —la muñeca, que es un attachment—
## no tiene largo propio y se dibuja cortito.
##
## ⚠ Es un NÚMERO y no una punta: `CustomBone.get_end_position()` NO es una posición del mundo, es el
## offset LOCAL `(0, largo, 0)` —está así porque lo usa `create` para colgar al hijo del padre—. Tomarlo
## como mundo daba un esqueleto cuyas líneas iban todas a un punto cerca del ORIGEN, y un gizmo de hueso de
## 1,6 m apuntando para arriba en la cabeza.
func _bone_length(bone: int, body_scale: float) -> float:
	if _skeleton == null or bone < 0 or bone >= _skeleton.get_bone_count():
		return 0.0
	if is_instance_valid(_bi) and is_instance_valid(_bi.custom_bones_util):
		var cb: CustomBone = _bi.custom_bones_util.get(_skeleton.get_bone_name(bone)) as CustomBone
		if is_instance_valid(cb):
			return cb.length
	# El fallback sí se escala: es un número de este archivo, no del rig.
	return 0.08 * body_scale


## CUÁN GRANDE ES ESTE PERSONAJE EN EL MUNDO, como múltiplo de lo normal. Ver el encabezado.
##
## Son dos cosas multiplicadas, porque las dos cambian cuánto ocupa en pantalla y ninguna implica la otra:
## el TAMAÑO del personaje (la lupa del sandbox, que agranda sus huesos) y la ESCALA DEL NODO del que
## cuelga (una parcela del design sandbox puede ir escalada, como las muestras de ciudad a 1:25).
static func _draw_scale(bi: BoneInstantiator) -> float:
	if not is_instance_valid(bi):
		return 1.0
	var out := 1.0
	if bi.skel_sizes_util != null:
		out = bi.skel_sizes_util.size_scale
	if is_instance_valid(bi.body_visual):
		out *= bi.body_visual.global_transform.basis.get_scale().x
	return maxf(out, 0.0001)


# ── INTERNO ─────────────────────────────────────────────────────────────────────────────────────

func _forget() -> void:
	_bi = null
	_skeleton = null
	_mesh = null
	_face = -1
	_vertex = -1
	_bone = -1
	_skinned = PackedVector3Array()
	_index = PackedInt32Array()
	_bones = PackedInt32Array()
	_weights = PackedFloat32Array()


## El Skeleton3D que deforma este cuerpo.
static func _skeleton_of(body: CharacterBodyVisual) -> Skeleton3D:
	var procedural := body as ProceduralBodyUtil
	return procedural.skeleton if procedural != null else null


## Los arrays de reposo de una malla, cacheados por nodo: la geometría se genera una vez y no cambia, así
## que leerlos por frame era copiar miles de vértices para nada.
func _mesh_data(m: MeshInstance3D) -> Dictionary:
	var id := m.get_instance_id()
	if _cache.has(id):
		return _cache[id]
	var arrays := m.mesh.surface_get_arrays(0)
	var rest: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if rest.is_empty() or index.is_empty():
		return {}
	# Los personajes se regeneran (respawn, cambio de arquetipo) y los nodos viejos se van con su id, así
	# que las entradas muertas solo ocupan lugar. A partir de unas cuantas, de vuelta a cero.
	if _cache.size() > 64:
		_cache.clear()
	var data := {"rest": rest, "index": index, "bones": arrays[Mesh.ARRAY_BONES],
		"weights": arrays[Mesh.ARRAY_WEIGHTS], "edges": PackedInt32Array(),
		"used": PackedInt32Array()}
	_cache[id] = data
	return data


## LAS ARISTAS DE UNA MALLA, DEDUPLICADAS Y CACHEADAS. Son índices, no posiciones: la posición se resuelve
## por frame con el skinning, la topología no cambia nunca.
##
## ⚠ SI LA MALLA TRAE SUS ARISTAS DE QUAD, son esas. El cuerpo generado es todo quads y los triangula para
## dibujar (ver GridPart), así que derivarlas de los triángulos agrega la DIAGONAL de cada quad — y una
## diagonal es indistinguible de una arista real mirando solo la topología. El generador las anota al
## armar la parte, que es donde todavía se sabe cuál es cuál, y así el alambre muestra la trama de verdad:
## la que uno escribió, no la que la GPU necesita.
func _edge_list(m: MeshInstance3D, index: PackedInt32Array) -> PackedInt32Array:
	var data := _mesh_data(m)
	if data.is_empty():
		return PackedInt32Array()
	var cached: PackedInt32Array = data["edges"]
	if not cached.is_empty():
		return cached
	var authored: PackedInt32Array = m.get_meta(
		ProceduralBodyUtil.GRID_EDGES_META, PackedInt32Array())
	if not authored.is_empty():
		data["edges"] = authored
		return authored
	var seen: Dictionary = {}
	var out := PackedInt32Array()
	for t in index.size() / 3:
		for k in 3:
			var a: int = index[t * 3 + k]
			var b: int = index[t * 3 + (k + 1) % 3]
			var key: int = mini(a, b) * 1048576 + maxi(a, b)
			if seen.has(key):
				continue
			seen[key] = true
			out.append(a)
			out.append(b)
	data["edges"] = out
	return out


## LOS HUESOS QUE UNA MALLA USA DE VERDAD: los que tienen peso en algún vértice. Cacheado, porque es un
## barrido de sus pesos y la topología no cambia nunca.
##
## No se le pregunta al `Skin` a propósito: es uno por esqueleto y nombra los diecinueve huesos para todas
## las partes (ver el encabezado). Esto es lo único que distingue a la pierna del torso antes de skinnear.
func _bones_used(m: MeshInstance3D, skeleton: Skeleton3D) -> PackedInt32Array:
	var data := _mesh_data(m)
	if data.is_empty() or skeleton == null or m.skin == null:
		return PackedInt32Array()
	var cached: PackedInt32Array = data["used"]
	if not cached.is_empty():
		return cached

	var bones: PackedInt32Array = data["bones"]
	var weights: PackedFloat32Array = data["weights"]
	var seen: Dictionary = {}
	var out := PackedInt32Array()
	for i in bones.size():
		if weights[i] <= 0.0:
			continue
		var bind: int = bones[i]
		if bind < 0 or bind >= m.skin.get_bind_count():
			continue
		var bone: int = m.skin.get_bind_bone(bind)
		if bone < 0 or bone >= skeleton.get_bone_count() or seen.has(bone):
			continue
		seen[bone] = true
		out.append(bone)
	data["used"] = out
	return out


## Los vértices de una malla en coordenadas del MUNDO, con el skinning hecho a mano.
##
## Sin esqueleto —o sin pesos— la malla va pegada a su nodo y alcanza su transform. Con esqueleto hay que
## hacer la cuenta: la GPU la hace y no la devuelve, y `surface_get_arrays` da el REPOSO.
static func _skin(m: MeshInstance3D, skeleton: Skeleton3D, rest: PackedVector3Array,
		bones: PackedInt32Array, weights: PackedFloat32Array) -> PackedVector3Array:
	var out := PackedVector3Array()
	out.resize(rest.size())
	if skeleton == null or bones.is_empty() or m.skin == null:
		var at := m.global_transform
		for i in rest.size():
			out[i] = at * rest[i]
		return out

	# El transform de cada bind: del espacio de la malla al hueso, y del hueso al mundo con su pose.
	var skin: Skin = m.skin
	var binds: Array[Transform3D] = []
	for b in skin.get_bind_count():
		var bone_index: int = skin.get_bind_bone(b)
		if bone_index < 0 or bone_index >= skeleton.get_bone_count():
			binds.append(Transform3D())
			continue
		binds.append(skeleton.get_bone_global_pose(bone_index) * skin.get_bind_pose(b))

	var to_world := skeleton.global_transform
	for i in rest.size():
		var v := rest[i]
		var acc := Vector3.ZERO
		var total := 0.0
		for k in 4:
			var w: float = weights[i * 4 + k]
			if w <= 0.0:
				continue
			var b: int = bones[i * 4 + k]
			if b < 0 or b >= binds.size():
				continue
			acc += (binds[b] * v) * w
			total += w
		out[i] = to_world * (acc / total if total > 0.0 else v)
	return out


## De los tres vértices de la cara, el más cercano al impacto. ESA es la aproximación que reemplaza tener
## un collider por vértice: el rayo acierta la cara, y la cara tiene tres candidatos.
func _nearest_vertex() -> int:
	if _face < 0:
		return -1
	var best := -1
	var best_distance := INF
	for k in 3:
		var at: int = _index[_face * 3 + k]
		var distance: float = _skinned[at].distance_to(_point)
		if distance < best_distance:
			best_distance = distance
			best = at
	return best


## El hueso que más pesa en la cara apuntada. Es el que MANEJA esa superficie, que es lo que uno quiere
## saber apuntándole a la piel — y es más útil que el hueso más cercano, que a veces es el de al lado.
func _dominant_bone() -> int:
	if _face < 0 or _bones.is_empty():
		return -1
	var totals: Dictionary = {}
	var best := -1
	var best_weight := 0.0
	for k in 3:
		var at: int = _index[_face * 3 + k]
		for j in 4:
			var w: float = _weights[at * 4 + j]
			if w <= 0.0:
				continue
			var b: int = _bones[at * 4 + j]
			var sum: float = float(totals.get(b, 0.0)) + w
			totals[b] = sum
			if sum > best_weight:
				best_weight = sum
				best = b
	return _skeleton_bone(best)


## El índice de hueso del esqueleto detrás de un índice de bind de la malla.
func _skeleton_bone(bind: int) -> int:
	if bind < 0 or _mesh == null or _mesh.skin == null:
		return bind
	if bind >= _mesh.skin.get_bind_count():
		return bind
	return _mesh.skin.get_bind_bone(bind)


## LO QUE TOCÓ EL ÚLTIMO RAYO, por nombre: la malla y el hueso que más la mueve ahí (ver ModelClick, que de eso saca
## qué parte del cuerpo es). Vacíos si no tocó nada.
## La malla que tocó el último rayo, el punto y la malla skinneada como estaba (para buscar una cinta cerca, ver
## ModelClick.mark_under).
func hit_mesh() -> MeshInstance3D:
	return _mesh if is_instance_valid(_mesh) else null


func hit_point() -> Vector3:
	return _point


func hit_skinned() -> PackedVector3Array:
	return _skinned


func hit_mesh_name() -> String:
	return String(_mesh.name) if is_instance_valid(_mesh) else ""


func hit_bone_name() -> String:
	return _bone_name(_bone)


## El cuerpo que tocó el último rayo, o null.
func hit_body() -> CharacterBodyVisual:
	return _bi.body_visual if is_instance_valid(_bi) and is_instance_valid(_bi.body_visual) else null


func _bone_name(index: int) -> String:
	if index < 0 or _skeleton == null or index >= _skeleton.get_bone_count():
		return "?"
	return _skeleton.get_bone_name(index)


## La distancia de un punto al rayo, acotada a su largo.
static func _ray_distance(point: Vector3, from: Vector3, dir: Vector3, reach: float) -> float:
	var t: float = clampf((point - from).dot(dir), 0.0, reach)
	return point.distance_to(from + dir * t)


## La rampa de peso: azul → verde → rojo, como el weight paint de Blender. Dos tramos y no un degradé
## directo de azul a rojo, porque el verde del medio es lo que hace legible dónde está el 0.5 —que es
## justo el valor que importa en una banda de mezcla—.
static func _ramp(w: float) -> Color:
	if w <= 0.5:
		return WEIGHT_COLD.lerp(WEIGHT_MID, w * 2.0)
	return WEIGHT_MID.lerp(WEIGHT_HOT, (w - 0.5) * 2.0)
