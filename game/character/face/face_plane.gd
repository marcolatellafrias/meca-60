class_name FacePlane

## EL PLANO DE LA CARA — un paño plano puesto delante de la cabeza y SHRINKWRAPEADO sobre ella, que es donde
## van a vivir los rasgos faciales (boca, ojos, arrugas) como decals intercambiables.
##
## ── DE DÓNDE SALE LA IDEA ───────────────────────────────────────────────────────────────────────
## De los Mii de Wii. En vez de pegar cada rasgo DIRECTO sobre la cabeza —donde su posición depende de la
## curvatura, de la forma del cráneo y de cada vuelta que uno mueva en el panel—, se toma un paño un poco más
## grande que la cara, se lo acerca como si fuera una tela y se deja que la cabeza lo deforme. Una vez que el
## paño tiene la forma de la cara, los rasgos se colocan DENTRO DEL PAÑO, en sus coordenadas, y eso los
## vuelve predecibles: "la boca está en el 50% de ancho y el 30% de alto" significa lo mismo en una cabeza
## redonda, en una alargada y en una que todavía no se esculpió.
##
## ── SE APOYA EN LA CABEZA, PUNTO POR PUNTO ──────────────────────────────────────────────────────
## Cada nudo cae sobre la superficie de la forma (ver HeadForm), con el mismo punto de anillo que arma su malla.
## Y lo que no toca nada —el borde que le sobra alrededor de la cara— se queda PLANO, en el plano de apoyo, sin
## curvatura, en vez de amontonarse contra la silueta.
##
## ── EL PAÑO ES SIEMPRE EL MISMO ─────────────────────────────────────────────────────────────────
## Mismo tamaño y mismas subdivisiones en todas las caras (ver `SIZE` y `CELLS`). Una cara más chica no
## recibe un paño más chico: recibe el mismo paño con más borde plano. Es lo que hace que una coordenada del
## paño sea un lugar del PAÑO y no de una cabeza en particular, y por lo tanto que un rasgo colocado una vez
## sirva para todas.
##
## ── LO QUE ESTE ARCHIVO NO HACE ─────────────────────────────────────────────────────────────────
## No sabe qué es una boca. Solo arma el paño y lo deja en el cuerpo como una capa aparte —con sus datos de
## herramienta, así que el alambre de quads lo dibuja igual que a cualquier malla (ver QuadWire)—. Los
## rasgos, su colocación y su catálogo vienen después y se van a apoyar en estas coordenadas.

## ── CUÁNTOS QUADS TIENE EL PAÑO: columnas × filas ───────────────────────────────────────────────
## Es un conteo de PLANTILLA, igual para todos los personajes (ver ProceduralBodyUtil): dos caras distintas
## tienen el mismo paño con los nudos en otro lado, y por eso un rasgo colocado en coordenadas del paño vale
## para las dos.
##
## Denso a propósito, y al doble de lo que estaba. Un paño toca la superficie EN SUS NUDOS, así que el medio
## de cada cuadro es una cuerda que pasa por DENTRO de la curva: es de ahí que sale el clipping contra la
## cara, y la subdivisión es la mitad de la solución (la otra es `LIFT_SHARE`). Con 10 × 12 la frente de una
## cabeza redonda se hundía; con 18 × 20 todavía se notaba de cerca.
##
## El precio es malla: 37 × 41 nudos son ~1500 vértices y 2880 caras por personaje. Se paga porque de esto
## cuelga la precisión de CADA rasgo facial — y porque la capa nace apagada y solo se enciende para mirarla.
const CELLS := Vector2i(36, 40)

## ── CUÁNTO LE SOBRA AL PAÑO ALREDEDOR DE LA CARA, en fracción ───────────────────────────────────
## El paño mide la CARA más este borde: de alto, el alto de la cabeza; de ancho, lo que su frente alcanza a
## lo más ancho (ver Cloth.of). Un 12% deja un reborde de nudos que no tocan, que es lo que un rasgo necesita
## para pasarse un poco del contacto sin caerse del paño.
##
## ⚠ ANTES ERA UN TAMAÑO FIJO —0,36 × 0,34 m, dimensionado para la cara más grande que el sistema permite— y
## ESO TENÍA SENTIDO MIENTRAS LOS RASGOS SE COLOCABAN EN COORDENADAS DEL PAÑO: con un paño igual en toda
## cara, una coordenada era un lugar del paño y un rasgo colocado una vez servía para todas.
##
## No es así desde que los rasgos se colocan en coordenadas DE LA CARA (ver FaceFeature: ±1 del medio-ancho
## del frente, 0..1 del alto), que es lo único que hace que "al 30% del alto" quiera decir lo mismo en una
## cabeza de 20 cm y en una de 10. Desde entonces el tamaño fijo no le servía a nadie y solo dejaba al paño
## enorme alrededor de la cara: medido, la tela daba 0,36 × 0,34 contra una proyección de frente de
## 0,128 × 0,20 — el 21% del paño tocaba la cara y el resto sobraba.
##
## LO QUE SIGUE SIENDO IGUAL EN TODA CARA SON LAS SUBDIVISIONES (ver `CELLS`), que es lo que mantiene el
## conteo de malla de plantilla. Lo que cambia es cuántos metros mide cada cuadro.
const MARGIN_SHARE := 0.12

## CUÁNTO FLOTA EL PAÑO SOBRE LA CARA, en fracción del alto de la cabeza. Es RELATIVO y no un número de
## milímetros: el clipping que se ve no es el del nudo —que apoya exacto— sino el del medio de cada cuadro,
## que pasa por dentro de la curva, y eso escala con el tamaño de la cabeza.
##
## Con 2% son 4 mm en una cabeza de 20 cm: invisible de lejos y suficiente para que ni el medio de un cuadro
## ni un decal entren en la cara.
const LIFT_SHARE := 0.02

## ── CÓMO SE VE EL PAÑO EN LA VISTA, Y QUÉ DISTINGUE ─────────────────────────────────────────────
## Casi transparente y SIN CULLING. Lo que se mira de esta vista es el ALAMBRE (ver QuadWire): el relleno
## está para saber dónde está el paño, no para taparlo. Y sin culling porque un paño de una sola cara
## desaparece de un lado y se ve del otro — que es exactamente el síntoma de "está invertido" aunque no lo
## esté, y una capa de diagnóstico no puede generar dudas sobre sí misma.
##
## ⚠ Y SE PINTA DISTINTO LO QUE TOCA LA CARA, que es la pregunta que uno le hace al paño: dónde se va a
## poder poner un rasgo. Lo apoyado va en verde y el borde suelto en azul apagado, los dos translúcidos. Sin
## eso hay que adivinar dónde termina el contacto, y adivinar es justo lo que este sistema vino a evitar.
## Los alfas son los que se ven: con 0,16 y 0,07 la distinción estaba ahí y no se leía de un metro.
const CONTACT_COLOR := Color(0.40, 1.0, 0.50, 0.40)
const LOOSE_COLOR := Color(0.40, 0.60, 0.95, 0.18)


## Las llaves con las que la malla lleva sus datos de herramienta. Son las mismas que usa el cuerpo, así que
## el alambre de quads no necesita saber que esto es una cara (ver ProceduralBodyUtil y QuadWire).
const GRID_EDGES_META := ProceduralBodyUtil.GRID_EDGES_META
const VERTEX_RING_META := ProceduralBodyUtil.VERTEX_RING_META
const VERTEX_COLUMN_META := ProceduralBodyUtil.VERTEX_COLUMN_META


## ARMA EL PAÑO sobre el frente de una cabeza.
##
## `form` es la forma de la cabeza ya escalada (ver HeadForm) y `rest` el transform de reposo de su hueso, con el que
## los puntos pasan al espacio del esqueleto, igual que hace `GridPart`. `bone` es el índice al que pesa todo: la cara
## es rígida a la cabeza.
##
## Devuelve `[ArrayMesh, grid_edges, vertex_ring, vertex_column]`, o vacío si no hay con qué armarlo.
static func build(form: HeadForm, rest: Transform3D, bone: int) -> Array:
	if form == null or form.total_height() <= 0.0:
		return []
	var columns: int = maxi(2, CELLS.x) + 1
	var rows: int = maxi(2, CELLS.y) + 1
	var cloth := Cloth.of(form, rest)

	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var ring := PackedInt32Array()
	var column := PackedInt32Array()

	for r in rows:
		for c in columns:
			# EL NUDO LO RESUELVE EL MISMO PAÑO que después van a consultar los rasgos (ver `Cloth`): una
			# sola definición de dónde apoya un punto, o un rasgo flotaría sobre la tela que se le ve debajo.
			var found := cloth.at_cloth(float(c) / float(columns - 1), float(r) / float(rows - 1))
			verts.append(found[0])
			normals.append(found[1])
			# EL COLOR DICE SI ESE NUDO TOCA LA CARA: un quad con nudos de los dos tipos mezcla los dos
			# colores solo, así que el límite del contacto se lee como un degradé y no como un escalón.
			colors.append(CONTACT_COLOR if bool(found[2]) else LOOSE_COLOR)
			bones.append_array(PackedInt32Array([bone, 0, 0, 0]))
			weights.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
			ring.append(r)
			column.append(c)

	var index := PackedInt32Array()
	var edges := PackedInt32Array()
	for r in rows - 1:
		for c in columns - 1:
			var a: int = r * columns + c
			var b: int = a + 1
			var d: int = a + columns
			var e: int = d + 1
			# ── EL BOBINADO SALE DE LA NORMAL, no de una corazonada ──────────────────────────────
			# ⚠ EL SIGNO ES "CONTRA la normal", porque en Godot el frente de una cara es el sentido HORARIO
			# (ver también GridPart._add_face).
			var outward: Vector3 = normals[a] + normals[b] + normals[d] + normals[e]
			var geometric: Vector3 = (verts[b] - verts[a]).cross(verts[d] - verts[a])
			if geometric.dot(outward) <= 0.0:
				index.append_array(PackedInt32Array([a, b, d, b, e, d]))
			else:
				index.append_array(PackedInt32Array([a, d, b, b, d, e]))
	# LAS ARISTAS DEL GRID, para el alambre: las del quad y no las diagonales de la triangulación (ver
	# GridPart.grid_edges, que explica por qué no se pueden deducir de los triángulos).
	for r in rows:
		for c in columns:
			var here: int = r * columns + c
			if c + 1 < columns:
				edges.append_array(PackedInt32Array([here, here + 1]))
			if r + 1 < rows:
				edges.append_array(PackedInt32Array([here, here + columns]))

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	arrays[Mesh.ARRAY_INDEX] = index
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return [mesh, edges, ring, column]


## ── EL PAÑO COMO FUNCIÓN: DÓNDE APOYA CUALQUIER PUNTO ───────────────────────────────────────────
## Lo mismo que el paño visible, pero consultable punto por punto y no solo en los nudos del grid. Es lo que
## hace que un rasgo facial pueda tener la precisión que quiera sin depender de la subdivisión de la tela
## (ver FaceFeatureMesh): el contorno de un ojo se muestrea donde el contorno lo pida.
##
## ⚠ Y ES LA ÚNICA DEFINICIÓN: el paño que se dibuja y los rasgos que se le apoyan encima salen de la misma cuenta, y
## esa cuenta es la de la malla de la cabeza —cada punto se apoya con el MISMO punto de anillo con que se arma
## (HeadForm.ring_point)—. Así los rasgos siguen la cara aplanada y el corrimiento hacia adelante sin una segunda
## cuenta que pueda discrepar (lo pidió el dios del juego, 13/10/2026).
##
## ── DOS SISTEMAS DE COORDENADAS, Y PARA QUÉ CADA UNO ────────────────────────────────────────────
## `at_cloth` habla del PAÑO (0..1 sobre el rectángulo, que es lo que el grid necesita) y `at_face` habla de
## LA CARA: `v` fracción del alto total de la forma —0 el fondo del domo de abajo, 1 la punta del de arriba— y `x` en
## metros desde el centro. Los rasgos se colocan en coordenadas de la CARA, nunca del paño.
class Cloth:
	## Cuánto del medio-ancho alcanza el frente, para los rasgos: lo que ellos llaman el borde de la cara.
	const FRONT_SHARE := 0.85

	var height: float
	var rest: Transform3D
	var size: Vector2
	var lift: float
	var plane_z: float
	var form: HeadForm

	## ── EL PAÑO DE ESTA CABEZA, Y MIDE LO QUE ELLA MIDE ──────────────────────────────────
	## De alto, el alto de la forma; de ancho, lo más ancho de ella; los dos con el borde de `MARGIN_SHARE`
	## alrededor. El plano de apoyo —donde se quedan los nudos que no tocan nada— va justo delante de lo más
	## adelantado de la cara.
	static func of(new_form: HeadForm, new_rest := Transform3D.IDENTITY) -> Cloth:
		var out := Cloth.new()
		out._fill(new_form, new_rest)
		return out

	func _fill(new_form: HeadForm, new_rest: Transform3D) -> void:
		form = new_form
		height = new_form.total_height()
		rest = new_rest
		lift = height * LIFT_SHARE
		var widest := 0.0
		var front := 0.0
		for k in 21:
			var y := height * float(k) / 20.0
			var here := new_form.section_at_height(y)
			widest = maxf(widest, here.x * 0.5)
			front = minf(front, new_form.ring_point(here.x, here.y, here.z, 0.0, y).z)
		size = Vector2(widest * 2.0, height) * (1.0 + MARGIN_SHARE)
		plane_z = front - lift

	## Un punto en coordenadas DEL PAÑO (0..1 en las dos), como `[posición, normal, tocó]`, con el flote del paño.
	func at_cloth(u: float, v: float) -> Array:
		return _point(size.x * (u - 0.5), height * 0.5 + size.y * (v - 0.5), lift)

	## ── UN PUNTO EN COORDENADAS DE LA CARA, Y SOBRE LA CARA MISMA ────────────────────────
	## `x` en metros desde el centro y `v` fracción del alto. A diferencia de `at_cloth`, esto NO lleva el flote del
	## paño: un rasgo pone el suyo (ver FaceFeatureMesh.INK_LIFT_SHARE).
	func at_face(x: float, v: float) -> Array:
		var found := local_face(x, v)
		return [rest * (found[0] as Vector3), (rest.basis * (found[1] as Vector3)).normalized(), true]

	## LO MISMO QUE `at_face` PERO EN EL ESPACIO DE LA CABEZA, sin el reposo del hueso: `[posición, normal]`. Es lo
	## que pide quien espeja (ver FaceFeatureMesh). El ángulo sale del `x` (en el anillo, `x = sin(ángulo)·ancho/2`
	## también con la cara aplanada), y la normal, de los dos vecinos del anillo y del de arriba.
	func local_face(x: float, v: float) -> Array:
		var y := v * height
		var here := form.section_at_height(y)
		var angle := asin(clampf(2.0 * x / maxf(here.x, 1e-5), -1.0, 1.0))
		var point := form.ring_point(here.x, here.y, here.z, angle, y)
		var side := form.ring_point(here.x, here.y, here.z, angle + 0.02, y) \
			- form.ring_point(here.x, here.y, here.z, angle - 0.02, y)
		var dy := height * 0.01
		var above_s := form.section_at_height(minf(y + dy, height))
		var below_s := form.section_at_height(maxf(y - dy, 0.0))
		var up := form.ring_point(above_s.x, above_s.y, above_s.z, angle, minf(y + dy, height)) \
			- form.ring_point(below_s.x, below_s.y, below_s.z, angle, maxf(y - dy, 0.0))
		var normal := side.cross(up).normalized()
		if normal.z > 0.0:
			normal = -normal
		return [point, normal]

	## CUÁNTO ALCANZA EL FRENTE DE LA CARA a esa altura, en metros desde el centro (medio-ancho): el borde de lo que
	## un rasgo puede usar.
	func reach(v: float) -> float:
		return form.section_at_height(v * height).x * 0.5 * FRONT_SHARE

	## Lo que toca la cara se apoya en ella, despegado `raise`; lo que no —más allá del costado, arriba de la punta,
	## abajo del fondo— se queda en el plano de apoyo, sin curva.
	func _point(x: float, y: float, raise: float) -> Array:
		if y >= 0.0 and y <= height and absf(x) < form.section_at_height(y).x * 0.5:
			var found := local_face(x, y / maxf(height, 1e-5))
			var normal: Vector3 = found[1]
			return [rest * ((found[0] as Vector3) + normal * raise), (rest.basis * normal).normalized(), true]
		return [rest * Vector3(x, y, plane_z + lift - raise), (rest.basis * Vector3(0.0, 0.0, -1.0)).normalized(),
			false]


## ── EL PAÑO PLANO: LA MISMA CARA, SIN CURVA ─────────────────────────────────────────────────────
## Lo que esta cabeza mide —su alto, cuánto alcanza su frente a cada altura— pero apoyado en una HOJA: cada punto
## queda donde cae, en z = 0, mirando a −Z como la cara. Es donde se MIRAN los rasgos (ver FeatureChart): son como
## calcos que se proyectan sobre la cara, y para analizarlos se los ve planos, sin la curva —lo pidió el dios del juego
## el 11/10/2026—. Como el alcance es el de la cabeza, un rasgo cae en la hoja en la misma proporción que en la cara.
class Flat extends Cloth:
	func at_face(x: float, v: float) -> Array:
		return [Vector3(x, v * height, 0.0), Vector3(0.0, 0.0, -1.0), true]

	func local_face(x: float, v: float) -> Array:
		return [Vector3(x, v * height, 0.0), Vector3(0.0, 0.0, -1.0)]


## El paño plano de esta cabeza (ver `Flat`).
static func flat_of(form: HeadForm) -> Cloth:
	var out := Flat.new()
	out._fill(form, Transform3D.IDENTITY)
	return out


