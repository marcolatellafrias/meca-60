class_name QuadWire
extends MeshInstance3D

## EL ALAMBRE DE QUADS DE UNA PARTE DEL CUERPO: las aristas que el generador autoró, dibujadas encima de
## la malla sólida y siguiendo el pose. Existe para no editar una silueta a ciegas.
##
## ── UNA DE LAS DOS VISTAS ────────────────────────────────────────────────────────────────────────
## Las maneras de mirar una malla son dos: ésta y la vista Blender (ver BlenderView), que dibuja todos los
## triángulos y sirve para cualquier malla. Ésta sólo tiene sentido donde lo armado son quads con intención —el
## personaje en su F1, la cara, las caderas—: la diagonal con la que se tesela cada quad es ruido ahí,
## indistinguible de una arista de verdad.
##
## ── Y LAS ZONAS DE DEFORMACIÓN SE PINTAN COMO CARAS ──────────────────────────────
## Una zona es una REGIÓN — la banda de caras donde una articulación dobla — y una vuelta autorada es una
## LÍNEA. Pintar las dos como líneas de colores las confunde: se veían como un montón de loop cuts rosas
## entre los de autoría. Así que las zonas son una capa de caras translúcidas, y las vueltas siguen siendo
## cintas: cosas distintas, lenguajes distintos.
##
## Una cara es de una zona si sus TRES vértices caen en anillos de articulación (ver
## ProceduralBodyUtil.JOINT_RINGS_META, que la propia malla trae).
##
## ── DOS JERARQUÍAS, Y POR ESO DOS GEOMETRÍAS ────────────────────────────────────────────────────
## El alambre dice dos cosas a la vez y no pueden pesar igual: "así está tejida esta malla" y "ESTA vuelta
## es la que mueve ese slider". Así que lo de fondo son LÍNEAS TRANSLÚCIDAS —están, se leen, no tiran del
## ojo— y lo marcado son CINTAS: una tira de triángulos apoyada sobre la superficie, con ancho de verdad.
##
## Las cintas no son un lujo: en Godot una línea mide **1 píxel y no se puede cambiar** (ni por material ni
## por instancia, es lo mismo que le pasa al inspector con sus gizmos), así que "más gruesa" no existe para
## una línea y la única forma de tener grosor es tener superficie. Y una cinta apoyada en el plano de la
## cara —no un tubo, no un billboard— es justo lo que se quiere acá: se lee como una raya pintada sobre el
## cuerpo, que es lo que un loop cut resaltado es.
##
## ── CÓMO SIGUE AL PERSONAJE SIN COSTAR NADA POR FRAME ───────────────────────────────────────────
## Las dos geometrías llevan LOS MISMOS huesos, pesos y `Skin` que la parte, y el nodo cuelga como HIJO de
## ella. Dos cosas salen gratis de eso: las skinnea la GPU igual que al cuerpo, así que no hay nada que
## recalcular cuando el personaje camina; y la visibilidad la HEREDA del padre, así que aislar una parte,
## esconder el cuerpo o entrar en primera persona se la llevan puesta sin que nadie la consulte. Eso
## último es a propósito: la regla de visibilidad es una sola y vive en `CharacterBodyVisual.part_shown`.
##
## El intento que fracasó, y por qué este no es el mismo: el alambre por objeto se había probado sobre la
## malla importada de Blender, donde no seguía los shape keys —`surface_get_blend_shape_arrays` devuelve
## vacío en Godot 4.5— y se descartó. Las partes generadas no tienen shape keys: su forma ES la geometría,
## así que acá la objeción no aplica.
##
## ⚠ TODO SE CORRE POR SU NORMAL. Una arista dibujada exactamente sobre la cara que la contiene empata en
## el buffer de profundidad y sale punteada. Se corre en REPOSO y a lo largo de la normal del vértice, así
## que el skinning se lo lleva igual que al resto y no hay nada que mantener por frame.

## Cómo se llama el nodo dentro de la parte. Es el handle: ponerlo dos veces actualiza el mismo.
const NODE_NAME := "alambre"

## EL ALAMBRE QUE NO ES NADA EN PARTICULAR: casi negro y TRANSLÚCIDO. Translúcido a propósito — es el
## contexto, no el tema: dice cómo está tejida la malla sin competir con la vuelta que se está editando, y
## deja que el crema del cuerpo se siga leyendo como volumen debajo.
const BASE_COLOR := Color(0.07, 0.08, 0.10, 0.40)

## CUÁNTO SE CORRE CADA PUNTO por su normal, en metros. Un milímetro y medio: es el mínimo que el inspector
## midió que hace falta para que una arista no empate en el buffer y salga punteada (ver
## Inspector.SURFACE_LIFT_MIN), y a esa distancia la línea sigue siendo el borde de la cara.
##
## Es un número fijo y no proporcional a la cámara como el del inspector, porque esto se hornea EN REPOSO
## una vez: lo que se gana con eso —que la GPU lo skinnee gratis— es lo que impide moverlo por frame.
const LIFT := 0.0015

## EL ANCHO DE UNA CINTA, en fracción de la diagonal de la parte. Es relativo y no en metros para que el
## grosor se lea igual en el torso de un pibe y en el de un gordo, y sobre todo para que la LUPA del
## sandbox —que agranda al personaje de verdad, ver `size_scale`— no lo deje como un pelo. En el torso del
## generic da unos 8 mm, o sea tres o cuatro veces el píxel de una línea.
const MARK_SHARE := 0.010

## Y la cinta se levanta un poco más que las líneas, para que cruzarse con una no la deje parpadeando.
const MARK_LIFT := 0.0022

## EL COLOR DE UNA ZONA DE DEFORMACIÓN: rojo y bien translúcido, para que se lea como una mancha sobre la
## superficie y no compita con las cintas de las vueltas.
const ZONE_COLOR := Color(1.0, 0.25, 0.20, 0.30)

## EL COLOR DEL PUENTE ENTRE LAS PIERNAS: la entrepierna y las dos caras que cruzan de un muslo al otro (ver
## ProceduralBodyUtil.BRIDGE_FACES_META). Azul y no rojo porque no es lo mismo que una zona de deformación:
## esas son estructura que deforma, y esto es la unión que todavía hay que decidir cómo se resuelve — se
## pinta aparte justo para poder mirarla sola.
const BRIDGE_COLOR := Color(0.35, 0.65, 1.0, 0.45)

static var _line_mat: StandardMaterial3D = null
static var _mark_mat: StandardMaterial3D = null
static var _zone_mat: StandardMaterial3D = null


## PONE (o actualiza) el alambre de `part`. `marks` es anillo → color: las vueltas que alguien está
## editando se dibujan como cintas de ese color, y todo lo demás como líneas translúcidas. Una parte sin
## datos de herramienta —las cápsulas— no dibuja nada, sin una rama de por medio.
static func show_on(part: MeshInstance3D, marks: Dictionary) -> void:
	if not is_instance_valid(part) or part.mesh == null:
		return
	var wire := part.get_node_or_null(NODE_NAME) as QuadWire
	if wire == null:
		wire = QuadWire.new()
		wire.name = NODE_NAME
		part.add_child(wire)
	# LAS CINTAS QUE PINTÓ, anillo → color: un click en una abre su sección (ver ModelClick.mark_under).
	wire.set_meta(MARKS, marks)
	wire.rebuild(part, marks)


## Dónde guarda el alambre sus cintas (ver `show_on`).
const MARKS := "marks"

## ── LA CINTA APUNTADA, RESALTADA (22/10/2026, lo pidió el dios del juego) ─────────────────────────────────────────────
## La que está bajo el mouse con un panel abierto (ver ModelClick): más ancha y más clara, como se resalta una parte.
const HOVER_GROW := 2.2
const HOVER_LIGHTEN := 0.45
var hovered_ring := -1


## RESALTA UNA CINTA de `part` (−1: ninguna), si cambió.
static func hover(part: MeshInstance3D, ring: int) -> void:
	var wire := of(part)
	if wire == null or wire.hovered_ring == ring:
		return
	wire.hovered_ring = ring
	wire.rebuild(part, wire.get_meta(MARKS, {}))


static func clear_from(part: MeshInstance3D) -> void:
	if not is_instance_valid(part):
		return
	var wire := part.get_node_or_null(NODE_NAME)
	if wire == null:
		return
	part.remove_child(wire)
	wire.queue_free()


## El alambre de `part`, o null. Para los tests y para quien quiera mirar lo que se dibujó.
static func of(part: MeshInstance3D) -> QuadWire:
	if not is_instance_valid(part):
		return null
	return part.get_node_or_null(NODE_NAME) as QuadWire


## ARMA LAS DOS GEOMETRÍAS. Se hace una vez por reconstrucción, no por frame.
##
## Los vértices NO se comparten entre aristas: un punto de la malla pertenece a una arista del anillo y a
## una vertical, así que compartiéndolo no se puede pintar una y no la otra.
##
## ⚠ UNA ARISTA ES DE UN LOOP CUT si sus dos puntas están en el mismo anillo Y LAS DOS TIENEN COLUMNA. Lo
## segundo es lo que deja afuera la grilla de las tapas, cuyos puntos llevan el anillo de su borde (ver
## GridPart.vertex_column): sin eso, resaltar la vuelta de arriba pintaba también toda la tapa, que con
## cintas de 8 mm tapa justo la bóveda que se está tratando de mirar.
func rebuild(part: MeshInstance3D, marks: Dictionary) -> void:
	var edges: PackedInt32Array = part.get_meta(
		ProceduralBodyUtil.GRID_EDGES_META, PackedInt32Array())
	var rings: PackedInt32Array = part.get_meta(
		ProceduralBodyUtil.VERTEX_RING_META, PackedInt32Array())
	var columns: PackedInt32Array = part.get_meta(
		ProceduralBodyUtil.VERTEX_COLUMN_META, PackedInt32Array())
	if edges.is_empty() or part.mesh.get_surface_count() == 0:
		mesh = null
		return

	var src := part.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = src[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = src[Mesh.ARRAY_NORMAL]
	var bones: PackedInt32Array = src[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = src[Mesh.ARRAY_WEIGHTS]
	if verts.is_empty():
		mesh = null
		return
	# Cuántos huesos por vértice trae la malla: se cuenta, no se asume, porque un día una parte puede venir
	# con ocho y el alambre tiene que copiar los mismos que tiene su cara.
	var per_vertex: int = bones.size() / verts.size()
	var half: float = part.mesh.get_aabb().size.length() * MARK_SHARE * 0.5

	# LAS ZONAS: los anillos que la malla declara como de articulación, y las caras que caen enteras ahí.
	var zones: PackedInt32Array = part.get_meta(
		ProceduralBodyUtil.JOINT_RINGS_META, PackedInt32Array())
	var in_zone: Dictionary = {}
	for ring in zones:
		in_zone[ring] = true

	var line := _Build.new()
	var mark := _Build.new()
	var zone := _Build.new()
	# LAS DEMÁS SUPERFICIES, sólo sus líneas (las marcas y las zonas son de la primera): las orejas en la malla de la
	# cabeza (ver ProceduralBodyUtil.surface_edges_meta).
	for s in range(1, part.mesh.get_surface_count()):
		var more: PackedInt32Array = part.get_meta(ProceduralBodyUtil.surface_edges_meta(s), PackedInt32Array())
		if more.is_empty():
			continue
		var other := part.mesh.surface_get_arrays(s)
		var other_verts: PackedVector3Array = other[Mesh.ARRAY_VERTEX]
		var other_bones: PackedInt32Array = other[Mesh.ARRAY_BONES]
		if other_verts.is_empty():
			continue
		for e in more.size() / 2:
			line.line(more[e * 2], more[e * 2 + 1], other_verts, other[Mesh.ARRAY_NORMAL], other_bones,
				other[Mesh.ARRAY_WEIGHTS], other_bones.size() / other_verts.size(), BASE_COLOR)
	for e in edges.size() / 2:
		var p: int = edges[e * 2]
		var q: int = edges[e * 2 + 1]
		var color: Color = _mark_color(p, q, rings, columns, marks)
		if color.a < 0.0:
			line.line(p, q, verts, normals, bones, weights, per_vertex, BASE_COLOR)
		elif hovered_ring >= 0 and rings[p] == hovered_ring:
			var lit := color.lightened(HOVER_LIGHTEN)
			lit.a = 1.0
			mark.ribbon(p, q, verts, normals, bones, weights, per_vertex, lit, half * HOVER_GROW)
		else:
			mark.ribbon(p, q, verts, normals, bones, weights, per_vertex, color, half)

	# EL PUENTE ENTRE LAS PIERNAS, que la malla declara por TRIÁNGULO y no por anillo: no es una banda a lo
	# largo de la pieza, son las caras sueltas con las que la pelvis cruza de un muslo al otro.
	var bridges: Dictionary = {}
	for t in part.get_meta(ProceduralBodyUtil.BRIDGE_FACES_META, PackedInt32Array()):
		bridges[t] = true

	# Y las caras de las zonas, levantadas igual que todo lo demás para no pelear con la superficie.
	var index: PackedInt32Array = src[Mesh.ARRAY_INDEX]
	if (not in_zone.is_empty() or not bridges.is_empty()) and not rings.is_empty():
		for t in index.size() / 3:
			var a: int = index[t * 3]
			var b: int = index[t * 3 + 1]
			var c: int = index[t * 3 + 2]
			var bridge: bool = bridges.has(t)
			if not bridge and not (in_zone.has(rings[a]) and in_zone.has(rings[b])
					and in_zone.has(rings[c])):
				continue
			# EL PUENTE GANA sobre la zona: donde se superponen, lo que uno quiere ver es el puente.
			var tint: Color = BRIDGE_COLOR if bridge else ZONE_COLOR
			for at: int in [a, b, c]:
				zone.point(at, verts[at] + normals[at] * LIFT, bones, weights, per_vertex, tint)

	var built := ArrayMesh.new()
	zone.flush(built, Mesh.PRIMITIVE_TRIANGLES, _zone_material())
	line.flush(built, Mesh.PRIMITIVE_LINES, _line_material())
	mark.flush(built, Mesh.PRIMITIVE_TRIANGLES, _mark_material())
	mesh = built if built.get_surface_count() > 0 else null

	# Los mismos huesos que la parte, y el esqueleto es el abuelo: la parte cuelga del Skeleton3D y esto
	# cuelga de la parte.
	skin = part.skin
	skeleton = NodePath("../..")


## El color con el que se marca esta arista, o uno con alfa NEGATIVO si no se marca — un centinela y no un
## booleano aparte, que es lo que deja el bucle de arriba en dos líneas.
static func _mark_color(p: int, q: int, rings: PackedInt32Array, columns: PackedInt32Array,
		marks: Dictionary) -> Color:
	const NONE := Color(0.0, 0.0, 0.0, -1.0)
	if rings.is_empty() or rings[p] != rings[q] or not marks.has(rings[p]):
		return NONE
	if columns.is_empty() or columns[p] < 0 or columns[q] < 0:
		return NONE
	return marks[rings[p]] as Color


## Sin sombreado y con el color del vértice: el alambre no participa de la luz, es una anotación sobre la
## superficie. El de las líneas además mezcla, que es de dónde sale que sean translúcidas.
static func _line_material() -> StandardMaterial3D:
	if _line_mat == null:
		_line_mat = StandardMaterial3D.new()
		_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_line_mat.vertex_color_use_as_albedo = true
		_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _line_mat


## El de las zonas mezcla y NO ESCRIBE PROFUNDIDAD: son manchas sobre la superficie, y escribiendo
## profundidad taparían las cintas y las líneas que van encima.
static func _zone_material() -> StandardMaterial3D:
	if _zone_mat == null:
		_zone_mat = StandardMaterial3D.new()
		_zone_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_zone_mat.vertex_color_use_as_albedo = true
		_zone_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_zone_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_zone_mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
	return _zone_mat


## El de las cintas es opaco y SIN DESCARTE DE CARAS: una cinta es una tira plana apoyada en la superficie
## y no un volumen, así que no tiene un adentro, y pedirle a su bobinado que sea el correcto es pedirle una
## garantía que no hace falta (ver `GridPart._add_face`, donde sí importa y por qué).
static func _mark_material() -> StandardMaterial3D:
	if _mark_mat == null:
		_mark_mat = StandardMaterial3D.new()
		_mark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mark_mat.vertex_color_use_as_albedo = true
		_mark_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		# CON ALFA: una vuelta apagada va casi transparente (ver TorsoTuner.ring_color); las demás, opacas.
		_mark_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _mark_mat


## UN MONTÓN DE VÉRTICES CON SUS PESOS, que es lo único que las dos geometrías tienen en común. Está acá
## para que agregar una línea y agregar una cinta no repitan la copia de huesos y pesos, que es donde un
## índice mal escrito no se ve hasta que el personaje camina.
class _Build:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()

	func line(p: int, q: int, src: PackedVector3Array, normals: PackedVector3Array,
			src_bones: PackedInt32Array, src_weights: PackedFloat32Array, per_vertex: int,
			color: Color) -> void:
		point(p, src[p] + normals[p] * QuadWire.LIFT, src_bones, src_weights, per_vertex, color)
		point(q, src[q] + normals[q] * QuadWire.LIFT, src_bones, src_weights, per_vertex, color)

	## UNA CINTA: el quad que va de `p` a `q` con `half` de ancho a cada lado, apoyado en el plano de la
	## cara —o sea, cruzado con la normal— y como dos triángulos, porque este arreglo no lleva índices.
	##
	## Se ALARGA media anchura en las dos puntas: las cintas de dos aristas vecinas se encuentran en ángulo
	## y, a tope, dejan una cuña abierta del lado de afuera del codo. Alargadas se solapan, y como son del
	## mismo color opaco el solape no se ve y la cuña desaparece.
	func ribbon(p: int, q: int, src: PackedVector3Array, normals: PackedVector3Array,
			src_bones: PackedInt32Array, src_weights: PackedFloat32Array, per_vertex: int,
			color: Color, half: float) -> void:
		var along: Vector3 = src[q] - src[p]
		if along.length_squared() < 1e-12:
			return
		var normal: Vector3 = (normals[p] + normals[q]).normalized()
		var side: Vector3 = along.normalized().cross(normal)
		if side.length_squared() < 1e-12:
			return
		side = side.normalized() * half
		var grow: Vector3 = along.normalized() * half
		var a: Vector3 = src[p] + normals[p] * QuadWire.MARK_LIFT - grow
		var b: Vector3 = src[q] + normals[q] * QuadWire.MARK_LIFT + grow
		var of_point := PackedInt32Array([p, p, q, p, q, q])
		var at := PackedVector3Array([a - side, a + side, b + side,
			a - side, b + side, b - side])
		for k in 6:
			point(of_point[k], at[k], src_bones, src_weights, per_vertex, color)

	## Un vértice que PESA LO QUE PESA `from`: la posición es nueva, los huesos son los de la malla. Es lo
	## que hace que la anotación se deforme con el cuerpo en vez de quedarse en el reposo.
	func point(from: int, at: Vector3, src_bones: PackedInt32Array,
			src_weights: PackedFloat32Array, per_vertex: int, color: Color) -> void:
		verts.append(at)
		colors.append(color)
		for k in per_vertex:
			bones.append(src_bones[from * per_vertex + k])
			weights.append(src_weights[from * per_vertex + k])

	## Agrega esto como una superficie de `into`, con su material. Vacío no agrega nada: una parte sin nada
	## marcado tiene UNA superficie, no una vacía.
	func flush(into: ArrayMesh, primitive: Mesh.PrimitiveType, material: Material) -> void:
		if verts.is_empty():
			return
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = verts
		arrays[Mesh.ARRAY_COLOR] = colors
		arrays[Mesh.ARRAY_BONES] = bones
		arrays[Mesh.ARRAY_WEIGHTS] = weights
		into.add_surface_from_arrays(primitive, arrays)
		into.surface_set_material(into.get_surface_count() - 1, material)
