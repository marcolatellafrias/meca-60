class_name GridPart
extends RefCounted

## UNA PARTE DEL CUERPO COMO UNA MALLA-GRILLA: un tubo de `R` anillos × `C` columnas a lo largo de una
## cadena de huesos, cerrado por dos tapas que son LA MISMA GRILLA. Todo quads, con pesos de skinning.
##
## REEMPLAZÓ A `PrismPart`, que emitía caras sueltas de ocho lados con chaflanes, y las tres razones son
## medidas:
##
##   1. **Los vértices se duplicaban.** Cada quad recalculaba sus cuatro esquinas desde cero, así que el
##      mismo punto salía por dos caminos aritméticos —`_corner(lado, 1.0)` en un quad y
##      `_corner(lado+1, 0.0)` en el vecino— y difería en los últimos bits. Medido sobre el genérico: 7104
##      vértices en 1322 posiciones, **5.37 copias por posición**, y 3617 de ellas compartían posición,
##      normal, huesos y pesos. O sea que no había ninguna razón para no unirlas: `SurfaceTool.index()` une
##      por igualdad EXACTA y no podía. Acá la grilla se calcula UNA vez y las caras la indexan, como una
##      malla de Blender — vértices y caras que los referencian, no caras que cargan sus esquinas.
##   2. **Las tapas eran un parche aparte.** Un Coons sobre un octógono, con su propia trama y sus propias
##      costuras. Acá la tapa es la grilla `(nx+1) × (nz+1)` de la sección y COMPARTE su borde con el
##      anillo de la punta: no hay dos topologías que empalmar.
##   3. **El chaflán era una curva facetada a mano.** Ver `_section_point`: ahora la sección es una
##      SUPERELIPSE con un exponente continuo, que contiene la caja y la elipse como extremos.
##
## ── UNA PARTE ES UNA PILA DE LOOP CUTS ──────────────────────────────────────────────────────────
## Cada vuelta trae los siete números que la definen (ver BodyLoop): dónde cae, su ancho, su fondo, su
## redondez, y su ALTURA punto por punto — cuánto se inclina y cuánto se arquea. No hay otra clase de
## control: una tapa abovedada, un hombro que cae y un torso de caja son la misma cosa con otros números.
##
## ── LA SECCIÓN ES UNA SUPERELIPSE, Y ESO BORRA EL CHAFLÁN ────────────────────────────────────────
## `|x/a|^n + |z/b|^n = 1`. El exponente es el único parámetro de forma de la sección:
##
##   · `n → ∞`  → LA CAJA exacta (las esquinas no se cortan, se quedan donde están).
##   · `n ≈ 8`  → una caja de esquinas redondeadas.
##   · `n ≈ 4`  → un torso blando.
##   · `n = 2`  → la elipse.
##
## Es continuo y suave: no hay cortes, no hay facetas más allá de cuántas columnas tenga la grilla, y un
## chaflán no es más que la aproximación cruda y discreta de lo que esto hace de una. Era para tener pocos
## polígonos; con la grilla, los polígonos salen del tamaño de celda y el chaflán no compra nada.
##
## ── LOS CONTEOS SON CONSTANTES, LOS TAMAÑOS SON DATOS ──────────────────────────────────────────
## Cuántos anillos y cuántas columnas tiene una parte NO sale de su tamaño: lo dice la plantilla (ver
## ProceduralBodyUtil). Así el enano y el gordo tienen la MISMA malla — los mismos vértices en el mismo
## orden, movidos a otro lado — y eso habilita tres cosas que sin ello son imposibles:
##
##   · INTERPOLAR ARQUETIPOS EN RUNTIME: un peón 60% gordo y 40% fortachón es mezclar los números de la
##     tabla, no dos mallas que no se corresponden.
##   · NOMBRAR UN LOOP CUT: "el anillo de la cintura" es el mismo anillo en todos los personajes, así que
##     el arquetipo le puede guardar un valor y el panel editarlo.
##   · UNA ARTICULACIÓN SIEMPRE CON ANILLOS ADENTRO DE SU BANDA: con N anillos por hueso y la banda en
##     fracción del hueso, la cuenta de anillos que caen en la banda es la misma para cualquier largo.
##
## Antes los anillos salían de un tamaño de celda en metros, y de ahí que el torso del kid tuviera 444
## vértices y el del gordo 1048. Aparte de romper lo de arriba, la topología dependía de un `ceil` que
## caía del lado que quisiera cuando el cociente daba justo — un anillo que aparecía y desaparecía con el
## tamaño del personaje.
##
## Lo que SÍ cambia con el tamaño es cuánto mide un cuadrito: el de un enano es más chico. Para deformar no
## importa (importan los anillos por articulación, que ahora son constantes) y es lo que hace cualquier
## personaje de juego: una malla, movida por variante.
##
## ── LA GRILLA SE MUESTREA COMO EL BORDE DE UN CUADRADO ──────────────────────────────────────────
## Los puntos de un anillo son el BORDE de la grilla `(nx+1) × (nz+1)` de la tapa, mapeado por la misma
## función. Dos cosas salen gratis de ahí: el anillo y la tapa comparten vértices por construcción, y el
## muestreo se adapta solo —el mapa comprime cerca de las esquinas, así que donde la curvatura es mayor
## caen más columnas por centímetro—.
##
## ── LAS NORMALES SE PARTEN POR ÁNGULO, COMO EL AUTO SMOOTH DE BLENDER ───────────────────────────
## Un cuerpo curvo quiere normales suaves y una caja quiere sus aristas filosas, y las dos cosas salen de
## la misma regla: en cada punto de la grilla se agrupan las caras vecinas cuyas normales estén dentro de
## `SMOOTH_ANGLE` y se emite un vértice por grupo. Un punto en el interior de una cara plana da UNA copia,
## uno sobre una arista viva da dos, una esquina de caja da tres — exactamente lo que el sombreado pide y
## nada más.
##
## ── EL BOBINADO SE DEDUCE DE LA GEOMETRÍA ───────────────────────────────────────────────────────
## Cada cara se emite con la vuelta que deja su normal mirando para AFUERA, y el afuera lo dice el
## llamador porque no es el mismo en un lado que en una tapa: en un lado es alejarse del eje y en una tapa
## es el eje mismo. Deducirlo de una regla sola fue uno de los errores que ya se cometieron acá — las
## tapas quedaban sin decidir y las que caían para adentro no se veían.
##
## ⚠ EL FRENTE DE UNA CARA EN GODOT ES EL SENTIDO HORARIO, así que una malla bien orientada da volumen con
## signo NEGATIVO con la fórmula estándar. El chequeo de `tests/procedural_body_test.tscn` lo espera
## negativo por eso, verificado contra el cuerpo de cápsulas como control.

## Debajo de este medio-lado una sección es un PUNTO: sus quads degeneran y se saltean (el polo del domo
## del hombro es eso).
const EPSILON := 1e-5

## A partir de este ángulo entre dos caras vecinas, la arista es VIVA y el vértice se parte. 35° deja
## suave una superelipse de exponente 8 —sus facetas rondan los 20°— y filosas las aristas de una caja.
## Es el DEFECTO: cada parte puede traer el suyo (ver `smooth_angle`).
const SMOOTH_ANGLE := 35.0


## CON QUÉ ÁNGULO SE PARTEN LAS NORMALES DE ESTA PARTE. Es por parte y no por archivo porque la elección es
## de la pieza: una cabeza y un brazo quieren leerse redondos a cualquier densidad, y un pie o un torso de
## caja quieren su arista. El panel lo elige por parte y lo guarda con el arquetipo (ver TorsoShape).
var smooth_angle := SMOOTH_ANGLE
## SECCIONES DE RADIO PAREJO (la pierna, lo pidió el dios del juego, 20/10/2026): cada vuelta es un rectángulo con las
## esquinas redondeadas del radio de su lado más corto —un círculo si ancho y fondo son iguales, y estirada, lados rectos
## con las dos puntas redondas, no un óvalo—. Su redondez no cuenta. Ver `_placed_point`.
var stadium := false


## LO QUE LA PARTE SABE DE SÍ MISMA, y que la malla no puede contar: a qué anillo y a qué COLUMNA pertenece
## cada vértice, y cuáles de sus aristas son del GRID (las otras son diagonales de la triangulación).
##
## Es para las herramientas, no para dibujar: el inspector pinta el alambre de quads con `grid_edges` y
## nombra "anillo 3" con `vertex_ring`, y el editor de loop cuts que viene mueve la fila del arquetipo que
## `vertex_ring` apunta. Se pueden apagar con `keep_tool_data` si algún día el juego dibuja esto con mil
## personajes en pantalla; sin ellos la malla es idéntica.
##
## `vertex_column` es −1 DONDE NO HAY COLUMNA, o sea en el interior de una tapa, y es lo único que distingue
## una arista DE UN LOOP CUT de una de la grilla de la tapa: las dos tienen sus dos puntas en el mismo
## anillo, porque los puntos de una tapa llevan el anillo de su borde. Sin eso, resaltar la vuelta de arriba
## pinta también toda la tapa (ver QuadWire).
static var keep_tool_data := true

var mesh: ArrayMesh = null
var vertex_ring := PackedInt32Array()
var vertex_column := PackedInt32Array()
var grid_edges := PackedInt32Array()

## La grilla, antes de partirla por normales. Un punto por posición, con su anillo y sus pesos.
##
## Una parte puede tener VARIOS TUBOS —la mano son seis: la palma, cuatro dedos y el pulgar— y todos van a
## la misma lista: comparten malla, no vertices. Los anillos se numeran corrido entre tubos, así que
## "anillo 7" es uno solo en toda la parte.
var _points := PackedVector3Array()
var _point_ring := PackedInt32Array()
var _point_column := PackedInt32Array()
var _point_bones: Array[PackedInt32Array] = []
var _point_weights: Array[PackedFloat32Array] = []
var _ring_count := 0
## Las caras como listas de índices de punto (3 o 4), ya bobinadas hacia afuera.
var _faces: Array[PackedInt32Array] = []
var _face_normals := PackedVector3Array()
## EL COLOR DE CADA CARA (ver BodyLoop.color), y si alguna no es blanca. Una parte sin pintar no escribe colores
## de vértice y su malla sale idéntica a la de antes de que esto existiera.
var _face_colors := PackedColorArray()
## Qué caras van con sombreado plano (ver `flat`): 1 sí, 0 no, una por cara.
var _face_flat := PackedByteArray()
## EL ÁNGULO DE AUTOSMOOTH de cada cara, como coseno: dos caras se suavizan juntas si su ángulo no lo pasa. -2, el de la
## parte (`smooth_angle`). Lo pone `auto_smooth` (ver ahí).
var _face_limit := PackedFloat32Array()
## ── EL UNWRAP (20/10/2026) ────────────────────────────────────────────────────────────────────────
## Lo pidió el dios del juego para poder ponerle a un traje un patrón como textura: cada tubo —el torso, los brazos, las
## piernas— sale DESENVUELTO, en METROS, así un patrón repetido tiene el mismo tamaño en cualquier cuerpo. El cuerpo es
## una caja de seis caras redondeada: las costuras son sus aristas (ver `_ring_around`). En cada lado del tubo `u` es lo
## que se recorre alrededor desde la esquina donde empieza ese lado y `v` lo que se recorre a lo largo, medido en la
## malla columna por columna. Las tapas,
## planas: los metros de su grilla. La costura parte los vértices (ver `commit`): el `u` de una cara es POR ESQUINA
## (`_face_uvs`), así la columna de la costura tiene 0 de un lado y la vuelta entera del otro.
var _face_uvs: Array[PackedVector2Array] = []
## ── Y AFLOJADO, CONFORME (LSCM, 20/10/2026) ───────────────────────────────────────────────────────
## El unwrap de arriba es de fórmulas, y donde el cuerpo se hincha o se angosta rápido las caras se tuercen y un
## circulito sale ovalado. Lo pidió el dios del juego: «marcar las costuras y desenvolver», como el Unwrap de Blender.
## Con `relax_uv`, cada ISLA —los lados de un tubo, cada tapa: lo que las costuras separan— se aplana por mínimos
## cuadrados conformes (LSCM: que cada triángulo conserve sus ángulos), arrancando del unwrap de fórmulas y vuelto a
## llevar a sus metros (ver `_relax_uv`). Cuesta, así que sólo lo pide una parte con patrón, y se guarda por forma.
var relax_uv := false
static var _relaxed_cache: Dictionary = {}
const RELAX_SWEEPS := 40
const RELAX_CACHE_MAX := 48

## SOMBREADO PLANO PARA LO QUE SE ARME MIENTRAS ESTÉ PRENDIDO: cada cara con su normal, sin compartir vértices con
## ninguna, aunque la parte se suavice por ángulo (`smooth_angle`). Lo pidió el dios del juego para los dedos y la mano
## (11/10/2026): suavizados no se leían; planos, cada falange se lee. Es por pieza y no por parte porque la mano va en
## la misma malla que el brazo, que sigue redondo.
var flat := false
## AUTOSMOOTH PARA LO QUE SE ARME MIENTRAS ESTÉ PUESTO, en grados (negativo: el de la parte). Como el Auto Smooth de
## Blender: lo redondo sale suave y las aristas más vivas que el ángulo quedan marcadas. Lo pidió el dios del juego para
## los botones (20/10/2026): suaves, pero que se note su borde (ver `stud_at`).
var auto_smooth := -1.0
var _painted := false
## EL COLOR DE LO QUE NO SE PINTÓ, en una parte que sí se pintó. Una cara blanca quiere decir "el color del material", y
## una parte pintada lleva el material en blanco: sin esto, la pelvis de un tronco con el saco pintado —que no sale de
## vueltas, ver `pelvis_fill`— saldría blanca. Lo pone quien arma la parte; blanco no cambia nada.
var base_color := Color.WHITE
## Las aperturas que esta parte dejó para que otra pieza salga por ellas, en orden de columna. Es el handle
## con el que una rama se engancha (ver `branch`), y las deja `pelvis_fill`.
var _hole_rings: Array[PackedInt32Array] = []

## EL ANILLO DEL ARRANQUE cuando se armó sin tapa (`build`'s `open_start`), para que otra cosa lo cierre.
var start_ring := PackedInt32Array()


## ARMA LA PARTE. `loops` son las vueltas de una punta a la otra y en orden, con su `at` ya en METROS sobre
## la cadena — puede ser negativo o pasarse del largo, que es cómo una parte arranca dentro de la vecina y
## la costura queda escondida.
##
## `bone_ids`, `lengths` y `rests` son la cadena —índices de Skeleton3D, largos, y transforms de reposo EN
## EL ESPACIO DEL ESQUELETO—, en paralelo y en orden padre→hijo. `blend_bands` lleva una entrada por
## ARTICULACIÓN (tamaño = huesos − 1); cero deja los pesos duros ahí.
## `open_start` deja el ARRANQUE SIN TAPA y se acuerda de ese anillo (`start_ring`), para que otra cosa lo
## cierre — es lo que hace el tronco, que no termina en un plano sino en la pelvis (ver `pelvis_fill`). Un
## arranque abierto y nada que lo cierre deja la malla agujereada, a propósito: el chequeo de aristas de
## `tests/procedural_body_test.tscn` lo delata.
func build(loops: Array[BodyLoop], bone_ids: PackedInt32Array, lengths: PackedFloat32Array,
		rests: Array[Transform3D], blend_bands: PackedFloat32Array,
		cells := Vector2i(6, 6), open_start := false) -> void:
	_tube(loops, bone_ids, lengths, rests, blend_bands, cells, open_start,
		PackedInt32Array(), -1, 0.0)


## ARMA UNA RAMA: un tubo que no arranca en el aire sino EN EL AGUJERO de una tapa ya armada, COMPARTIENDO
## sus vértices. Es lo que hace que el torso y las piernas sean una malla y no dos meténdose una en la otra:
## la unión no tiene costura, ni caras adentro, ni dos normales, ni dos superficies que se cruzan al doblar.
##
## El primer anillo de `loops` es el COMPARTIDO: su tamaño y su altura ya los decidió la tapa, así que de él
## solo se usa el `at` — dónde cae la unión sobre la cadena de la rama, que es desde donde arranca la banda
## de peso.
##
## `anchor_bone` y `band` son esa banda: el anillo compartido pesa lo que le dio la tapa (un hueso del
## tronco) y la rama tiene que pasar a su propio hueso en unos centímetros. Sin eso, el primer anillo de la
## pierna queda clavado a la pelvis y la unión se estira al levantarla.
func branch(hole: int, loops: Array[BodyLoop], bone_ids: PackedInt32Array,
		lengths: PackedFloat32Array, rests: Array[Transform3D], blend_bands: PackedFloat32Array,
		cells: Vector2i, anchor_bone: int, band: float, anchor_share := 1.0) -> void:
	if hole < 0 or hole >= _hole_rings.size():
		return
	_tube(loops, bone_ids, lengths, rests, blend_bands, cells, false,
		_hole_rings[hole], anchor_bone, band, anchor_share)


## CUÁNTOS ANILLOS LLEVA YA ESTA PARTE, o sea con qué número va a empezar a numerar el próximo tubo. Es lo
## que convierte el índice de un anillo DENTRO de un tubo en el número que lleva el vértice (`vertex_ring`),
## y lo necesita quien quiera anotar dónde cayó una vuelta en una parte de varios tubos.
func ring_count() -> int:
	return _ring_count


static func _mix_weights(bones_a: PackedInt32Array, values_a: PackedFloat32Array,
		bones_b: PackedInt32Array, values_b: PackedFloat32Array, f: float) -> Array:
	var total: Dictionary = {}
	for k in mini(bones_a.size(), values_a.size()):
		if values_a[k] > 0.0:
			total[bones_a[k]] = float(total.get(bones_a[k], 0.0)) + values_a[k] * (1.0 - f)
	for k in mini(bones_b.size(), values_b.size()):
		if values_b[k] > 0.0:
			total[bones_b[k]] = float(total.get(bones_b[k], 0.0)) + values_b[k] * f
	var order := total.keys()
	order.sort_custom(func(x: int, y: int) -> bool:
		return float(total[x]) > float(total[y]))
	var ids := PackedInt32Array([0, 0, 0, 0])
	var out := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
	var sum := 0.0
	for k in mini(4, order.size()):
		ids[k] = int(order[k])
		out[k] = float(total[order[k]])
		sum += out[k]
	if sum > 0.0:
		for k in 4:
			out[k] /= sum
	return [ids, out]


func _tube(loops: Array[BodyLoop], bone_ids: PackedInt32Array, lengths: PackedFloat32Array,
		rests: Array[Transform3D], blend_bands: PackedFloat32Array, cells: Vector2i,
		open_start: bool, from_ring: PackedInt32Array, anchor_bone: int,
		anchor_band: float, anchor_share := 1.0) -> void:
	if loops.size() < 2 or bone_ids.is_empty():
		return

	# ── Los anillos: dónde cae cada uno, con qué orientación y con qué pesos ────────────────────
	var count := loops.size()
	var centers := PackedVector3Array()
	var bases: Array[Basis] = []
	var w_bones: Array[PackedInt32Array] = []
	var w_values: Array[PackedFloat32Array] = []
	centers.resize(count)
	bases.resize(count)
	for i in count:
		var placed := _resolve(loops[i].at, lengths)
		var bone := int(placed.x)
		var rest: Transform3D = rests[bone]
		centers[i] = rest * Vector3(0.0, placed.y, 0.0)
		var pair := _weights(bone, placed.y, bone_ids, lengths, blend_bands)
		# Y si esto es una rama, los primeros anillos pasan del hueso del tronco al suyo.
		if anchor_bone >= 0 and bone == 0 and anchor_band > 0.0:
			var from_y: float = _resolve(loops[0].at, lengths).y
			if placed.y - from_y < anchor_band:
				pair = _anchor_weights(anchor_bone, bone_ids[0], placed.y - from_y, anchor_band,
					anchor_share)
		w_bones.append(pair[0])
		w_values.append(pair[1])

		# EL MARCO DE UN ANILLO SE MEZCLA IGUAL QUE SUS PESOS. Un anillo que pesa mitad y mitad entre dos
		# huesos tiene que estar orientado mitad y mitad, o la columna CODEA en el nudo en vez de curvarse.
		# Con el marco pegado a un solo hueso, los dos anillos a los lados del nudo quedan a milímetros uno
		# del otro y rotados por el doblez de reposo, así que el lado interno del pliegue se cruza.
		var other := int(pair[2])
		var share := float(pair[3])
		if other >= 0 and share > 0.0:
			var here := Quaternion(rest.basis.orthonormalized())
			var there := Quaternion((rests[other] as Transform3D).basis.orthonormalized())
			bases[i] = Basis(here.slerp(there, share))
		else:
			bases[i] = rest.basis

	# ── La resolución de la grilla ──────────────────────────────────────────────────────────────
	# Las celdas de la SECCIÓN las dice la plantilla, no el tamaño de la parte (ver el encabezado). De
	# ellas sale todo: las columnas son el perímetro de esa grilla, y la tapa es la grilla misma.
	var nx: int = maxi(2, cells.x)
	var nz: int = maxi(2, cells.y)
	var columns := 2 * (nx + nz)

	# ── Los puntos: los anillos, y después el interior de cada tapa ─────────────────────────────
	# POR ÍNDICE Y NO POR ARITMÉTICA: el primer anillo puede venir DADO —una rama arranca en el agujero de
	# otra tapa y comparte esos vértices— así que no se puede suponer que los puntos de un anillo son
	# contiguos ni que empiezan donde empezó esta llamada.
	var ring_uv := _ring_uv(nx, nz)
	var ring := PackedInt32Array()
	ring.resize(count * columns)
	var shared: bool = from_ring.size() == columns
	if shared:
		var aligned := _aligned(from_ring, loops[1], centers[1], bases[1], ring_uv, columns)
		for c in columns:
			ring[c] = aligned[c]
	for r in count:
		if r == 0 and shared:
			continue
		var loop: BodyLoop = loops[r]
		for c in columns:
			ring[r * columns + c] = _add_point(
				_placed_point(loop, centers[r], bases[r], ring_uv[c].x, ring_uv[c].y),
				_ring_count + r, w_bones[r], w_values[r], c)

	# Una rama no lleva tapa de arranque: su tapa es el agujero del que sale. Y el tronco tampoco: lo que
	# cierra su arranque es la pelvis.
	var capped: bool = not shared and not open_start
	var start_cap := _cap_points(ring, 0, loops, centers, bases, nx, nz, columns,
		w_bones, w_values) if capped else PackedInt32Array()
	# SIN TAPA AL FINAL si se pidió (`open_end`): lo cierra otra pieza cosida a su último anillo (ver `stitch`).
	var end_cap := PackedInt32Array() if open_end else _cap_points(ring, count - 1, loops, centers, bases, nx, nz,
		columns, w_bones, w_values)
	open_end = false
	last_ring = ring.slice((count - 1) * columns, count * columns)
	if open_start:
		start_ring = ring.slice(0, columns)

	# EL UNWRAP: alrededor de cada anillo, desde la columna del medio de la espalda (ver `_face_uvs`).
	var around := _ring_around(ring, count, columns, PackedInt32Array([0, nx, nx + nz, 2 * nx + nz]))
	# Y A LO LARGO, MEDIDO EN LA MALLA columna por columna (no la altura de los huesos, que con un hueso escalado no es
	# la de la superficie: los circulitos salían ovalados).
	var along: Array[PackedFloat32Array] = []
	for r in count:
		var row := PackedFloat32Array()
		row.resize(columns)
		for c in columns:
			row[c] = 0.0 if r == 0 else along[r - 1][c] + _points[ring[(r - 1) * columns + c]].distance_to(
				_points[ring[r * columns + c]])
		along.append(row)

	# ── Las caras ───────────────────────────────────────────────────────────────────────────────
	for r in count - 1:
		if loops[r].is_point() and loops[r + 1].is_point():
			continue
		for c in columns:
			var c2: int = (c + 1) % columns
			var a: int = ring[r * columns + c]
			var b: int = ring[r * columns + c2]
			var d: int = ring[(r + 1) * columns + c2]
			var e: int = ring[(r + 1) * columns + c]
			# AFUERA, para un lado, es el RADIO DE CADA ANILLO EN SU PROPIO PLANO, sumados: cada uno va del
			# centro de su anillo a su propio borde, así que apunta afuera por construcción sin importar
			# cómo estén orientados los dos anillos entre sí. Sacarlo del centroide de la cara falla justo
			# en una articulación doblada, donde el pliegue interno se solapa y el centroide cae adentro.
			#
			# EL CENTRO DEL ANILLO ES EL DE VERDAD, con su corrimiento (ver BodyLoop.forward y `sideways`, y
			# `_placed_point`) — 22/10/2026: con el del eje, una vuelta corrida más que su medio fondo dejaba su cara de
			# atrás "adelante" del centro, y la cara se daba vuelta (lo vio el dios del juego en las narices).
			var out := ((_points[a] + _points[b]) * 0.5 - _ring_centre(loops[r], centers[r])) \
				+ ((_points[d] + _points[e]) * 0.5 - _ring_centre(loops[r + 1], centers[r + 1]))
			# EL TRAMO SE PINTA DEL COLOR DE LA VUELTA DE LA QUE SALE: el borde entre dos colores cae justo en
			# un anillo, que es donde se lo puso.
			var c_next: int = (c + 1) % columns
			_add_face(PackedInt32Array([a, b, d, e]), out, loops[r].color, PackedVector2Array([
				Vector2(around[r][c * 2], along[r][c]), Vector2(around[r][c * 2 + 1], along[r][c_next]),
				Vector2(around[r + 1][c * 2 + 1], along[r + 1][c_next]), Vector2(around[r + 1][c * 2], along[r + 1][c])]))

	_add_cap_faces(start_cap, nx, nz, -bases[0].y.normalized(), loops[0].color, Transform3D(bases[0], centers[0]),
		loops[0])
	_add_cap_faces(end_cap, nx, nz, bases[count - 1].y.normalized(), loops[count - 1].color,
		Transform3D(bases[count - 1], centers[count - 1]), loops[count - 1])
	_ring_count += count
	# Y EL TUBO COMO SUPERFICIE, para dibujarle encima (ver `surface`).
	var heights := PackedFloat32Array()
	for loop in loops:
		heights.append(loop.at)
	# Y LA TAPA DE ARRIBA, para seguir sus vetas (ver `surface_or_cap`): su vuelta, su centro y su marco.
	_tubes.append({"ring": ring, "columns": columns, "centres": centers, "at": heights,
		"cap_loop": loops[count - 1], "cap_centre": centers[count - 1], "cap_basis": bases[count - 1],
		"start_loop": loops[0] if not start_cap.is_empty() else null, "start_centre": centers[0],
		"start_basis": bases[0]})


## EL CENTRO DE UN ANILLO: el punto de su eje más su corrimiento, el mismo que le suma `_placed_point`.
static func _ring_centre(loop: BodyLoop, axis_point: Vector3) -> Vector3:
	return axis_point + Vector3(loop.sideways, 0.0, -loop.forward)


## LAS NORMALES DE LAS ESQUINAS DE UNA CARA, fijadas: cara → {punto → normal}. Ganan a la de la cara (ver `stitch`).
var face_normal_override := {}


## EL PRÓXIMO TUBO SIN TAPA AL FINAL (ver `_tube`): se apaga solo después de armarlo.
var open_end := false
## Los puntos del último anillo del último tubo armado, en orden (para coserle otra pieza, ver `stitch`).
var last_ring := PackedInt32Array()


## Cierra la malla: parte los vértices por ángulo y por color, y escribe los arrays. Devuelve `null` si no hay
## nada.
## La normal de un punto en un grupo de caras: la que fijaron sus caras (ver `face_normal_override`), promediada, o la
## de siempre si ninguna la fijó.
func _fixed_normal(point: int, faces: PackedInt32Array, normal: Vector3) -> Vector3:
	if face_normal_override.is_empty():
		return normal
	var sum := Vector3.ZERO
	for f in faces:
		var fixed: Dictionary = face_normal_override.get(f, {})
		if fixed.has(point):
			sum += fixed[point]
	return sum.normalized() if sum.length_squared() > 1e-12 else normal


## LOS ARRAYS DE LA ÚLTIMA MALLA que armó `commit`, tal como se le pasaron: para sumarle formas (las poses de la mano,
## ver ProceduralBodyUtil._with_poses) sin pedírselos de vuelta a la malla, que sin ventana no los devuelve.
var last_arrays: Array = []
## Los flags con que se armó (`commit`): los de las líneas, si las lleva (ver `LINE_FLAGS`).
var last_flags := 0


func commit() -> ArrayMesh:
	if _faces.is_empty():
		return null
	if relax_uv and _uv_used:
		_relax_uv()

	# Las caras que toca cada punto.
	var touching: Array[PackedInt32Array] = []
	touching.resize(_points.size())
	for i in _points.size():
		touching[i] = PackedInt32Array()
	for f in _faces.size():
		for at in _faces[f]:
			var list: PackedInt32Array = touching[at]
			list.append(f)
			touching[at] = list

	# Un vértice por (punto, grupo suave). `slot[punto][cara]` dice qué vértice le toca a cada cara.
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var rings := PackedInt32Array()
	var cols := PackedInt32Array()
	var vpoint := PackedInt32Array()
	var slot: Array[Dictionary] = []
	slot.resize(_points.size())
	var limit: float = cos(deg_to_rad(smooth_angle))

	for i in _points.size():
		var faces: PackedInt32Array = touching[i]
		slot[i] = {}
		if faces.is_empty():
			continue
		# Agrupar por ángulo: cada cara entra al primer grupo que la acepta. Y POR COLOR: dos caras de distinto
		# color no comparten vértice aunque estén en el mismo plano, igual que dos caras de una arista viva — es
		# lo que deja filoso el borde de una manga en vez de un degradé de un anillo de alto.
		var groups: Array[PackedInt32Array] = []
		var group_normals := PackedVector3Array()
		var group_colors := PackedColorArray()
		var group_flat := PackedByteArray()
		var group_limits := PackedFloat32Array()
		var group_uvs := PackedVector2Array()
		for f in faces:
			var normal: Vector3 = _face_normals[f]
			# Y POR COORDENADA DE TEXTURA: la costura del unwrap parte el vértice como una arista viva (ver `_face_uvs`).
			var corner_uv := _corner_uv(f, i)
			var placed := false
			for g in groups.size():
				if _face_flat[f] == 0 and group_flat[g] == 0 \
						and group_normals[g].dot(normal) >= maxf(limit, maxf(_face_limit[f], group_limits[g])) \
						and group_colors[g] == _face_colors[f] and group_uvs[g].is_equal_approx(corner_uv):
					var list: PackedInt32Array = groups[g]
					list.append(f)
					groups[g] = list
					group_normals[g] = (group_normals[g] + normal).normalized()
					placed = true
					break
			if not placed:
				groups.append(PackedInt32Array([f]))
				group_normals.append(normal)
				group_colors.append(_face_colors[f])
				group_flat.append(_face_flat[f])
				group_limits.append(_face_limit[f])
				group_uvs.append(corner_uv)

		# LA COSTURA DEL UNWRAP NO ES UNA ARISTA VIVA PARA LA LUZ: parte el vértice para que cada lado tenga su coordenada,
		# pero la normal es la de todas las caras que lo comparten —las de los dos lados—, o cada lado promediaba sólo las
		# suyas y en la sombra se veía una línea en cada arista de la caja (lo vio el dios del juego, 20/10/2026).
		var shade_normals := PackedVector3Array()
		for g in groups.size():
			var shade := Vector3.ZERO
			for h in groups.size():
				if h == g or (group_flat[g] == 0 and group_flat[h] == 0 and group_colors[h] == group_colors[g]
						and group_normals[h].dot(group_normals[g]) >= maxf(limit, maxf(group_limits[g], group_limits[h]))):
					shade += group_normals[h] * float((groups[h] as PackedInt32Array).size())
			shade_normals.append(shade.normalized() if shade.length_squared() > 1e-12 else group_normals[g])

		for g in groups.size():
			var index := verts.size()
			verts.append(_points[i])
			vpoint.append(i)
			# (La de una cara que la fijó gana: la de la costura del antebrazo, ver `stitch`; la de la cara plana, o el promedio
			# de las fijadas de sus caras.)
			normals.append(_fixed_normal(i, groups[g], shade_normals[g]))
			# EN LINEAL: el material no marca los colores de vértice como sRGB (hacerlo dibujaba rayas), así que
			# el color de diseño, que es sRGB como el de cualquier material, se convierte acá.
			var paint: Color = base_color if group_colors[g] == Color.WHITE else group_colors[g]
			colors.append(paint.srgb_to_linear())
			uvs.append(group_uvs[g])
			rings.append(_point_ring[i])
			cols.append(_point_column[i])
			var bone_set: PackedInt32Array = _point_bones[i]
			var weight_set: PackedFloat32Array = _point_weights[i]
			for k in 4:
				bones.append(bone_set[k])
				weights.append(weight_set[k])
			for f in groups[g]:
				(slot[i] as Dictionary)[f] = index

	# Los triángulos, y de paso las aristas del grid.
	var index_array := PackedInt32Array()
	var seen: Dictionary = {}
	grid_edges = PackedInt32Array()
	# QUÉ CARAS SON PUENTE, para traducirlas a triángulos acá, que es donde se sabe en cuántos se parte cada
	# una (ver `_bridge_faces`).
	var bridge: Dictionary = {}
	for f in _bridge_faces:
		bridge[f] = true
	bridge_triangles = PackedInt32Array()
	for f in _faces.size():
		var corners: PackedInt32Array = _faces[f]
		var out := PackedInt32Array()
		for at in corners:
			out.append(int((slot[at] as Dictionary)[f]))
		if bridge.has(f):
			var first: int = index_array.size() / 3
			bridge_triangles.append(first)
			if out.size() == 4:
				bridge_triangles.append(first + 1)
		if out.size() == 4:
			index_array.append_array(PackedInt32Array([out[0], out[1], out[2]]))
			index_array.append_array(PackedInt32Array([out[0], out[2], out[3]]))
		else:
			index_array.append_array(out)
		if not keep_tool_data:
			continue
		# LAS ARISTAS DEL GRID SON LAS DEL PERÍMETRO DE LA CARA, nunca la diagonal con la que se la
		# triangula: por eso se anotan acá, donde todavía se sabe cuál es cuál.
		for k in out.size():
			var p: int = out[k]
			var q: int = out[(k + 1) % out.size()]
			var key: int = mini(p, q) * 1048576 + maxi(p, q)
			if seen.has(key):
				continue
			seen[key] = true
			grid_edges.append(p)
			grid_edges.append(q)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	if _painted:
		arrays[Mesh.ARRAY_COLOR] = colors
	if _uv_used:
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	arrays[Mesh.ARRAY_INDEX] = index_array
	# LAS LÍNEAS SOBRE LA MALLA (ver `mark_line`): los triángulos que las llevan, con lo que el shader necesita.
	last_flags = 0
	if not _line_edges.is_empty():
		var tool := _apply_lines(arrays, vpoint, rings, cols)
		rings = tool[0]
		cols = tool[1]
		last_flags = LINE_FLAGS
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, [], {}, last_flags)
	last_arrays = arrays
	vertex_ring = rings if keep_tool_data else PackedInt32Array()
	vertex_column = cols if keep_tool_data else PackedInt32Array()
	return mesh


# ── SECCIONES ───────────────────────────────────────────────────────────────────────────────────

## Una columna de medidas constantes entre `from_t` y `to_t`, cortada en `steps` tramos. Es la forma corta
## de pedir una pieza recta de un solo hueso.
static func column(from_t: float, to_t: float, half: Vector2, roundness: float,
		steps: int) -> Array[BodyLoop]:
	return taper_column(from_t, to_t, half, half, roundness, steps)


## UNA COLUMNA QUE SE AFINA: las medidas van de `half_head` a `half_tail` a lo largo del tramo, en `steps`
## tramos iguales. Con las dos mitades iguales es una columna pareja; en redondez 0, una caja.
##
## `steps` es un CONTEO de la plantilla, no una consecuencia del largo (ver el encabezado): la misma pieza
## tiene los mismos anillos en un enano y en un gordo.
##
## ⚠ TOMA UNA REDONDEZ y no un exponente de superelipse, igual que `dome`: los exponentes eran el lenguaje
## con el que se autoró el cuerpo viejo, y ahora el único que queda es el de las constantes de las piezas
## que no se autoran. Quien la llama con un número de panel ya tiene la redondez en la mano, y convertir de
## ida y de vuelta es la forma segura de que dos piezas vecinas dejen de coincidir.
static func taper_column(from_t: float, to_t: float, half_head: Vector2, half_tail: Vector2,
		roundness: float, steps: int) -> Array[BodyLoop]:
	var cuts: int = maxi(1, steps)
	var out: Array[BodyLoop] = []
	for i in cuts + 1:
		var f: float = float(i) / float(cuts)
		out.append(BodyLoop.make(lerpf(from_t, to_t, f),
			half_head.lerp(half_tail, f).x * 2.0, half_head.lerp(half_tail, f).y * 2.0,
			roundness))
	return out


## ── LAS VUELTAS QUE MANDAN, que son las que se interpolan ───────────────────────────────────────
## Una vuelta apagada (ver BodyLoop.active) se saca de la cuenta: su anillo sigue estando —el conteo de malla
## es de plantilla— pero su forma sale de interpolar entre las que quedaron. Así una forma simple no obliga a
## hacer coincidir cinco vueltas, y las que se apagan siguen guardadas con sus números.
##
## ⚠ LAS PUNTAS SIEMPRE QUEDAN: son las tapas de la pila y sin ellas no hay entre qué interpolar. Apagarlas
## dejaría la pila sin extremos y el tramo entero copiaría una sola vuelta.
static func _active(controls: Array[BodyLoop]) -> Array[BodyLoop]:
	if controls.size() < 3:
		return controls
	var out: Array[BodyLoop] = []
	for i in controls.size():
		if i == 0 or i == controls.size() - 1 or (controls[i] as BodyLoop).active:
			out.append(controls[i])
	return out


## Si `t` cae adentro de alguna banda. La holgura es un décimo de milímetro: un anillo puesto JUSTO en el
## borde de su propia banda tiene que contar, y en float de 32 el borde no cae exacto.
static func _within(bands: Array, t: float) -> bool:
	for each: Array in bands:
		if t >= float(each[0]) - 0.0001 and t <= float(each[1]) + 0.0001:
			return true
	return false


## UNA CÚPULA: del polo a la base, con `rings` anillos. El anillo del polo tiene radio ~0 y eso lo maneja
## todo solo — sus quads degeneran en triángulos y la tapa se saltea.
## ⚠ TOMA UNA REDONDEZ, no un exponente de superelipse. Eran exponentes porque así se autoró el cuerpo
## viejo, y quien la llama tiene en la mano la vuelta a la que la cúpula tiene que empalmar: convertir de ida
## y de vuelta era la forma segura de que las dos dejaran de coincidir.
static func dome(pole_t: float, base_t: float, half: Vector2, roundness: float,
		rings: int) -> Array[BodyLoop]:
	var out: Array[BodyLoop] = []
	var steps: int = maxi(rings, 1)
	for i in steps:
		var phi: float = PI * 0.5 * (1.0 - float(i) / float(steps))
		var t: float = base_t - (base_t - pole_t) * sin(phi)
		var shrink: float = cos(phi)
		out.append(BodyLoop.make(t, half.x * shrink * 2.0, half.y * shrink * 2.0, roundness))
	return out


## EL PUNTO DE LA GRILLA en el espacio del esqueleto: la sección en su plano, más la altura que esta
## vuelta le da a ese `(u, v)`.
func _placed_point(loop: BodyLoop, centre: Vector3, frame: Basis, u: float, v: float) -> Vector3:
	# LA REDONDEZ SALE DEL PUNTO y no de la vuelta entera: el frente puede ser más plano que el fondo (ver
	# BodyLoop.roundness_at), que es lo que deja apoyar un rasgo facial sin estirarlo.
	var half := loop.half()
	var flat := _section_point(half, loop.roundness_at_uv(u, v), u, v)
	if stadium:
		var at := _rounded_corner(Vector2(u, v), half, minf(half.x, half.y))
		flat = Vector2(at.x * half.x, at.y * half.y)
	# EL CORRIMIENTO (ver BodyLoop.forward): hacia el frente DEL CUERPO, −Z del esqueleto, y no el de la sección. Medido:
	# el marco del muslo tiene su Z dado vuelta (Z = (0, 0,02, −1)) y el del brazo no, así que en el marco la pierna se
	# corría para atrás.
	return centre + frame * Vector3(flat.x, _lift(loop, u, v), flat.y) + Vector3(loop.sideways, 0.0, -loop.forward)


## CUÁNTO SE LEVANTA un punto de la vuelta, a lo largo del eje, y es lo que hace que un loop cut no sea
## plano y que una tapa sea una cúpula CON LOS MISMOS TRES NÚMEROS (ver BodyLoop).
##
##   · `tilt_x` / `tilt_z` la inclinan: un plano de alturas, +tilt en un borde y −tilt en el opuesto.
##   · `arch_x` y `arch_z` la arquean, cada uno un perfil en su eje —parábola o cúpula, ver
##     `_arch_profile`— y se SUMAN: en las ESQUINAS no
##     levantan nada, en el medio de una cara levanta el del OTRO eje, y en el CENTRO —o sea, en el medio de
##     una tapa— la suma de los dos. Es el mismo campo a distinto radio, y por eso no hace falta un sistema
##     aparte para abovedar una tapa. Dos y no uno porque uno solo da una bóveda de cañón —curva en un eje,
##     recta en el otro— y eso es forma, no cantidad.
##
## ⚠ UN POLO LLEVA UN SOLO VALOR. Sus vértices están todos en el mismo punto pero con `(u, v)` distintos,
## así que darles alturas distintas abriría el polo en un abanico vertical.
static func _lift(loop: BodyLoop, u: float, v: float) -> float:
	if loop.is_point():
		return loop.arch_x + loop.arch_z
	var out: float = loop.tilt_x * u + loop.tilt_z * v
	if not is_zero_approx(loop.arch_x):
		out += loop.arch_x * _arch_profile(u, loop.arch_dome)
	if not is_zero_approx(loop.arch_z):
		out += loop.arch_z * _arch_profile(v, loop.arch_dome)
	# LOS COSTADOS MÁS ARRIBA O MÁS ABAJO (ver BodyLoop.sides_lift): por el ángulo alrededor —el coseno al cuadrado, 1 en el
	# medio de cada costado y 0 en el del frente y la espalda—, y adentro de una tapa, por lo lejos que está del centro.
	if not is_zero_approx(loop.sides_lift):
		var reach: float = maxf(absf(u), absf(v))
		if reach > 1e-6:
			var side: float = absf(u) / sqrt(u * u + v * v)
			out += loop.sides_lift * side * side * reach * reach
	return out


## EL CAMINO DEL ARQUEO entre el borde (0) y el centro (1). Los dos perfiles valen lo mismo en las dos
## puntas y se diferencian en cómo van: la parábola sube parejo y la cúpula sube de golpe en los bordes y se
## aplana arriba, llegando al canto vertical — o sea continuando la pared, sin arista. Ver BodyLoop.
static func _arch_profile(t: float, dome: bool) -> float:
	var flat: float = 1.0 - t * t
	return sqrt(maxf(flat, 0.0)) if dome else flat


static func _section_point(half: Vector2, roundness: float, u: float, v: float) -> Vector2:
	var box := Vector2(half.x * u, half.y * v)
	var f: float = clampf(roundness, 0.0, 1.0)
	if is_zero_approx(f):
		return box
	var round_section := Vector2(
		half.x * u * sqrt(maxf(1.0 - v * v * 0.5, 0.0)),
		half.y * v * sqrt(maxf(1.0 - u * u * 0.5, 0.0)))
	return box.lerp(round_section, f)


## El borde del cuadrado recorrido en orden, `2(nx + nz)` puntos. Arranca en la esquina `(−1, −1)` y va por
## −Z, +X, +Z, −X: el orden es parte del contrato, porque es el que hace que la columna `c` de un anillo
## sea la columna `c` del de al lado y de la tapa.
static func _ring_uv(nx: int, nz: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in nx:
		out.append(Vector2(-1.0 + 2.0 * float(i) / float(nx), -1.0))
	for j in nz:
		out.append(Vector2(1.0, -1.0 + 2.0 * float(j) / float(nz)))
	for i in nx:
		out.append(Vector2(1.0 - 2.0 * float(i) / float(nx), 1.0))
	for j in nz:
		out.append(Vector2(-1.0, 1.0 - 2.0 * float(j) / float(nz)))
	return out


## La columna del anillo que le toca a `(i, j)` del borde de la grilla, o −1 si el punto es interior. Es la
## inversa de `_ring_uv`, y de acá sale que la tapa COMPARTA vértices con el anillo en vez de empalmar.
static func _ring_column(i: int, j: int, nx: int, nz: int) -> int:
	if j == 0 and i < nx:
		return i
	if i == nx and j < nz:
		return nx + j
	if j == nz and i > 0:
		return nx + nz + (nx - i)
	if i == 0 and j > 0:
		return 2 * nx + nz + (nz - j)
	return -1


# ── TAPAS ───────────────────────────────────────────────────────────────────────────────────────

## Los índices de punto de la grilla de una tapa, `(nx+1) × (nz+1)` en orden `j * (nx+1) + i`. Los del
## borde son los del anillo; los de adentro se agregan. Vacío si el anillo es un punto.
func _cap_points(ring_index: PackedInt32Array, ring: int, loops: Array[BodyLoop],
		centers: PackedVector3Array, bases: Array[Basis], nx: int, nz: int, columns: int,
		w_bones: Array[PackedInt32Array],
		w_values: Array[PackedFloat32Array]) -> PackedInt32Array:
	var out := PackedInt32Array()
	var loop: BodyLoop = loops[ring]
	if loop.is_point():
		return out
	out.resize((nx + 1) * (nz + 1))
	for j in nz + 1:
		for i in nx + 1:
			var column := _ring_column(i, j, nx, nz)
			if column >= 0:
				out[j * (nx + 1) + i] = ring_index[ring * columns + column]
				continue
			var u: float = -1.0 + 2.0 * float(i) / float(nx)
			var v: float = -1.0 + 2.0 * float(j) / float(nz)
			out[j * (nx + 1) + i] = _add_point(
				_placed_point(loop, centers[ring], bases[ring], u, v),
				_ring_count + ring, w_bones[ring], w_values[ring])
	return out


func _add_cap_faces(grid: PackedInt32Array, nx: int, nz: int, outward: Vector3,
		color := Color.WHITE, frame := Transform3D(), loop: BodyLoop = null) -> void:
	if grid.is_empty():
		return
	# EL UNWRAP DE UNA TAPA (ver `_face_uvs`), DESDE SU CENTRO PARA AFUERA, como se pela una naranja (lo pidió el dios del
	# juego: proyectada en su plano, donde la tapa se arquea mucho los circulitos se aplastaban). Cada punto va a SU
	# DISTANCIA DEL CENTRO MEDIDA SOBRE LA TAPA —recorriendo la superficie de la vuelta (ver `_placed_point`) en línea
	# recta desde el medio de su grilla—, en la dirección en que cae en el plano. En metros, como el resto.
	# VISTA DE AFUERA: la tapa de abajo mira para el otro lado, así que su plano se ve espejado. Sin dar vuelta un eje su
	# unwrap queda al revés de sus caras, y el LSCM (ver `_relax_uv`), que conserva ángulos CON su sentido, la aplastaba
	# en una línea —los circulitos salían rayas—.
	var plane_x: Vector3 = frame.basis.x.normalized() * (-1.0 if outward.dot(frame.basis.y) < 0.0 else 1.0)
	var plane_z: Vector3 = frame.basis.z.normalized()
	var cap_uv := func(i: int, j: int) -> Vector2:
		var u: float = -1.0 + 2.0 * float(i) / float(nx)
		var v: float = -1.0 + 2.0 * float(j) / float(nz)
		var p: Vector3 = _points[grid[j * (nx + 1) + i]] - frame.origin
		var flat := Vector2(p.dot(plane_x), p.dot(plane_z))
		if loop == null or flat.length_squared() < 1e-12:
			return flat
		var walked := 0.0
		var prev := _placed_point(loop, frame.origin, frame.basis, 0.0, 0.0)
		for k in range(1, CAP_UV_STEPS + 1):
			var t: float = float(k) / float(CAP_UV_STEPS)
			var next := _placed_point(loop, frame.origin, frame.basis, u * t, v * t)
			walked += next.distance_to(prev)
			prev = next
		return flat.normalized() * walked
	var with_uv: bool = frame != Transform3D()
	for j in nz:
		for i in nx:
			var uvs := PackedVector2Array()
			if with_uv:
				uvs = PackedVector2Array([cap_uv.call(i, j), cap_uv.call(i + 1, j), cap_uv.call(i + 1, j + 1),
					cap_uv.call(i, j + 1)])
			_add_face(PackedInt32Array([
				grid[j * (nx + 1) + i],
				grid[j * (nx + 1) + i + 1],
				grid[(j + 1) * (nx + 1) + i + 1],
				grid[(j + 1) * (nx + 1) + i],
			]), outward, color, uvs)


## En cuántos pasos se mide la distancia de un punto de una tapa a su centro, sobre la superficie (ver `_add_cap_faces`).
const CAP_UV_STEPS := 12


## ALINEA LA VUELTA COMPARTIDA con el primer anillo propio de la rama: elige desde qué columna y en qué
## sentido se recorre el agujero para que cada par quede lo más cerca posible.
##
## ⚠ SE BUSCA, NO SE SUPONE, y es lo que evita un retorcimiento imposible de ver en el código: las dos
## vueltas están en el mismo orden cíclico, pero cada una en el marco de SU hueso, y la base de reposo del
## muslo no está alineada con la de la pelvis —apunta para abajo—, así que ni la esquina de arranque ni el
## sentido de giro tienen por qué coincidir. Son `2 · columnas` candidatas probadas una vez por rama.
func _aligned(from_ring: PackedInt32Array, loop: BodyLoop, centre: Vector3, frame: Basis,
		ring_uv: PackedVector2Array, columns: int) -> PackedInt32Array:
	var target := PackedVector3Array()
	for c in columns:
		target.append(_placed_point(loop, centre, frame, ring_uv[c].x, ring_uv[c].y))
	var best := INF
	var best_offset := 0
	var best_flip := false
	for flip in [false, true]:
		for offset in columns:
			var cost := 0.0
			for c in columns:
				var k: int = (offset + (columns - c if flip else c)) % columns
				cost += (_points[from_ring[k]] - target[c]).length_squared()
			if cost < best:
				best = cost
				best_offset = offset
				best_flip = flip
	var out := PackedInt32Array()
	for c in columns:
		var k: int = (best_offset + (columns - c if best_flip else c)) % columns
		out.append(from_ring[k])
	return out


# ── LO QUE SE DIBUJA ENCIMA ─────────────────────────────────────────────────────────────────────
# DOS COSAS DISTINTAS, como las separó el dios del juego (10/10/2026), y la diferencia es de quién es el dibujo:
#
#   · LA LÍNEA es PARAMÉTRICA: sale de números y sigue la malla —alrededor a una altura, como un loop cut, o a lo
#     largo a un ángulo, como una columna—. Una costura (ver `draw_line`).
#   · LA CALCOMANÍA es AUTORIAL: una textura dibujada a mano, pegada en una zona. Un bolsillo, un parche, un emblema
#     (ver `draw_decal`).
#
# Las dos se apoyan sobre la superficie de una parte YA ARMADA —esta u otra, ver `surface`— y llevan los pesos de lo
# que tienen debajo, así que se doblan con ella. Ninguna toca la malla de la parte de abajo: van en la suya, despegadas
# unos milímetros.

## LOS TUBOS DE ESTA PARTE COMO SUPERFICIE: por tubo, sus anillos como índices de punto —`columns` por anillo, en
## orden—, el centro de cada anillo y su altura sobre la cadena. Es lo que lee `surface`; no cambia la malla.
var _tubes: Array[Dictionary] = []
## LAS COORDENADAS DE TEXTURA de cada punto, y si algo las usa (una calcomanía): sin eso la malla no las escribe y sale
## idéntica a la de antes.
var _point_uv := PackedVector2Array()
var _uv_used := false


## UN PUNTO DE LA SUPERFICIE DE UN TUBO, por su altura sobre la cadena (`at`, en metros, como las vueltas) y su ÁNGULO
## ALREDEDOR: 0 es el frente (−Z) y crece hacia +X, medido en horizontal en el espacio del esqueleto. Sirve igual en el
## torso que en una pierna, porque los dos cuelgan derechos; en un brazo no.
##
## Devuelve `[posición, normal, huesos, pesos]`, con los pesos mezclados de los cuatro puntos de la grilla que lo rodean
## —así lo dibujado se dobla con la parte—, o vacío si no hay tubo. Una altura que se pasa se queda en la punta.
func surface(tube: int, at: float, angle: float) -> Array:
	if tube < 0 or tube >= _tubes.size():
		return []
	var data: Dictionary = _tubes[tube]
	var heights: PackedFloat32Array = data["at"]
	var centres: PackedVector3Array = data["centres"]
	var r := _segment(heights, at)
	var span: float = heights[r + 1] - heights[r]
	var f: float = clampf((at - heights[r]) / span, 0.0, 1.0) if absf(span) > EPSILON else 0.0
	var low := _ring_sample(data, r, angle)
	var high := _ring_sample(data, r + 1, angle)
	if low.is_empty() or high.is_empty():
		return []
	var position: Vector3 = (low[0] as Vector3).lerp(high[0], f)
	# LA NORMAL DEL PARCHE: a lo largo, de un anillo al otro, por alrededor, de una columna a la siguiente; y para
	# afuera, lejos del eje.
	var along: Vector3 = (high[0] as Vector3) - (low[0] as Vector3)
	var around: Vector3 = (low[1] as Vector3).lerp(high[1], f)
	var outward: Vector3 = position - centres[r].lerp(centres[r + 1], f)
	var normal := along.cross(around)
	if normal.length_squared() < 1e-14:
		normal = outward
	if normal.dot(outward) < 0.0:
		normal = -normal
	var pair := _mix_weights(low[2], low[3], high[2], high[3], f)
	return [position, normal.normalized(), pair[0], pair[1]]


## DIBUJA UNA LÍNEA sobre un tubo de `source`: una cinta de `width` despegada `lift` de la superficie, por el camino
## `path` —cada punto `(altura en metros, ángulo en radianes)`, ver `surface`—, que se recorre en línea recta EN ESAS
## COORDENADAS: a altura fija da la vuelta como un loop cut, a ángulo fijo baja como una columna. `closed` une la punta
## con el arranque, y una vuelta que termina donde empezó (de −180° a 180°) no repite el punto. Se muestrea cada `step`
## metros, más o menos.
func draw_line(source: GridPart, tube: int, path: PackedVector2Array, closed: bool, width: float, lift: float,
		color: Color, step: float) -> void:
	draw_ribbon(line_samples(source, tube, path, closed, step), closed, width, lift, color)


## LOS PUNTOS DE UNA LÍNEA sobre un tubo de `source` (ver `draw_line`), sin dibujarla: para seguirla por otro lado antes
## (ver `drape`).
##
## ── UNA LÍNEA VA POR LAS ARISTAS DE LA MALLA (21/10/2026, la regla de base) ───────────────────────────────────────────
## Lo vio el dios del juego: las líneas se acordonaban en la tapa de arriba del torso y clipeaban en muchos lados. Las dos
## cosas tenían la misma causa: un punto de la línea en el medio de una cara —con los pesos de un vértice, o mezclados— no
## se mueve como la cara al deformarse el cuerpo, y un tramo recto que cruza una arista de la malla se hunde en ella. Y la
## regla la dio él: «las costuras coinciden siempre con edges de geometría», siguen la estructura de la malla y no
## pelean contra ella. Así que UNA LÍNEA PASA SÓLO POR VÉRTICES DE LA MALLA: cada punto del camino (ver `_densify`, que
## pone uno en cada cruce con un anillo y con una columna) se lleva al vértice más cercano —en el tubo, el del anillo y
## la columna más cercanos (ver `_tube_vertex`); en una tapa, el de la cara que lo tiene (ver `from_above`)—, con su
## posición y sus pesos exactos, y dos seguidos iguales son uno. Cada tramo es una arista: una costura vertical va por una
## columna, una horizontal por un anillo, una en diagonal escalona por las aristas. Se deforma exactamente como la malla y
## no puede meterse en ella, con cualquier cantidad de malla.
static func line_samples(source: GridPart, tube: int, path: PackedVector2Array, closed: bool, step: float) -> Array:
	var samples: Array = []
	var last := -1
	for p in source._densify(source, tube, path, closed, step):
		var s := source.surface_or_cap(tube, p.x, p.y)
		if s.is_empty():
			continue
		var vertex: int = s[4] if s.size() > 4 else source._tube_vertex(tube, p.x, p.y)
		if vertex < 0:
			last = -1
			samples.append(s)
			continue
		if vertex == last:
			continue
		last = vertex
		samples.append([source._points[vertex], s[1], source._point_bones[vertex], source._point_weights[vertex], vertex])
	return samples


## ── MÁS ALLÁ DE LA VUELTA DE ARRIBA: LA TAPA (20/10/2026) ─────────────────────────────────────────────────────
## `surface`, pero una altura por encima de la última vuelta del tubo SIGUE POR LA TAPA de arriba, POR SUS VETAS. La tapa
## es una grilla en el cuadrado `(u, v)` de su vuelta (ver `_cap_points`): sus líneas van de adelante para atrás (`u`
## fijo) y de costado a costado (`v` fijo), y continúan las columnas del tubo. Así que desde el punto de la vuelta de
## arriba en ese ángulo —su `(u, v)` en el borde del cuadrado— se sigue la línea de la grilla que entra por ahí, midiendo
## lo que sobra de altura SOBRE la superficie, y el punto se apoya en la malla vista desde arriba (ver `from_above`). Lo
## pidió el dios del juego: el bolsillo del pecho tiene que poder subir a la tapa, siguiendo la estructura de la malla.
## Debajo de la última vuelta, `surface` tal cual.
const CAP_BORDER_SAMPLES := 96
const CAP_WALK_STEPS := 64
func surface_or_cap(tube: int, at: float, angle: float) -> Array:
	if tube < 0 or tube >= _tubes.size():
		return []
	var data: Dictionary = _tubes[tube]
	var heights: PackedFloat32Array = data["at"]
	var top: float = heights[heights.size() - 1]
	# DEBAJO DE LA PRIMERA VUELTA, por la tapa de abajo si la hay (la del torso, ver ProceduralBodyUtil._trunk), hasta
	# su centro.
	if at < heights[0] - EPSILON and data.get("start_loop") != null:
		return _along_cap(tube, heights[0] - at, angle, true)
	if at <= top + EPSILON:
		return surface(tube, at, angle)
	var edge := surface(tube, top, angle)
	if edge.is_empty():
		return []
	var line := cap_line(tube, angle)
	if line.size() < 2:
		return edge
	var left: float = at - top
	var point: Vector3 = (line.back() as Array)[1]
	for k in range(1, line.size()):
		var d0: float = (line[k - 1] as Array)[0]
		var d1: float = (line[k] as Array)[0]
		if d1 >= left:
			point = ((line[k - 1] as Array)[1] as Vector3).lerp((line[k] as Array)[1], (left - d0) / maxf(d1 - d0, EPSILON))
			break
	var on := from_above(point.x, point.z)
	return on if not on.is_empty() else [point, (data["cap_basis"] as Basis).y.normalized(), edge[2], edge[3]]


## UN PUNTO SOBRE UNA TAPA, a `distance` metros de su borde por la veta del ángulo (ver `cap_line`): la de abajo
## (`start`) llega hasta su centro y no lo pasa.
func _along_cap(tube: int, distance: float, angle: float, start: bool) -> Array:
	var line := cap_line(tube, angle, start)
	var data: Dictionary = _tubes[tube]
	var heights: PackedFloat32Array = data["at"]
	var edge := surface(tube, heights[0] if start else heights[heights.size() - 1], angle)
	if line.size() < 2:
		return edge
	var point: Vector3 = (line.back() as Array)[1]
	for k in range(1, line.size()):
		var d0: float = (line[k - 1] as Array)[0]
		var d1: float = (line[k] as Array)[0]
		if d1 >= distance:
			point = ((line[k - 1] as Array)[1] as Vector3).lerp((line[k] as Array)[1], (distance - d0) / maxf(d1 - d0, EPSILON))
			break
	var basis: Basis = data["start_basis" if start else "cap_basis"]
	var on := from_above(point.x, point.z) if not start else _from_below(point.x, point.z)
	return on if not on.is_empty() else [point, basis.y.normalized() * (-1.0 if start else 1.0), edge[2], edge[3]]


## Lo mismo que `from_above`, mirando desde abajo: el punto más BAJO de la malla en (`x`, `z`), con la normal hacia abajo.
func _from_below(x: float, z: float) -> Array:
	var best := INF
	var out: Array = []
	var at := Vector2(x, z)
	# SÓLO LOS TRIÁNGULOS DE SU CELDA, como `from_above` (ver `_above_index`: la grilla es en x, z, sirve para los dos).
	var index := _above_index()
	var cell: Variant = index.get(_above_cell(x, z))
	if cell == null:
		return out
	var tris: PackedInt32Array = cell
	for t in range(0, tris.size(), 2):
		var f: int = tris[t]
		var face: PackedInt32Array = _faces[f]
		for k in [tris[t + 1]]:
			var a: Vector3 = _points[face[0]]
			var b: Vector3 = _points[face[k]]
			var c: Vector3 = _points[face[k + 1]]
			var bary := _barycentric_xz(at, a, b, c)
			if bary.x < -1e-6 or bary.y < -1e-6 or bary.z < -1e-6:
				continue
			var y: float = a.y * bary.x + b.y * bary.y + c.y * bary.z
			if y >= best:
				continue
			best = y
			var nearest: int = face[0]
			if bary.y > bary.x and bary.y >= bary.z:
				nearest = face[k]
			elif bary.z > bary.x and bary.z > bary.y:
				nearest = face[k + 1]
			var normal: Vector3 = _face_normals[f]
			if normal.y > 0.0:
				normal = -normal
			out = [Vector3(x, y, z), normal, _point_bones[nearest], _point_weights[nearest], nearest]
	return out


## LA VETA DE LA TAPA que entra por el punto de la vuelta de arriba en ese ángulo (ver `surface_or_cap`), de borde a
## borde: `[[distancia sobre la superficie desde la vuelta de arriba, punto], …]`. Vacía si el tubo no tiene tapa. Con
## `start`, la de la tapa de abajo, y sólo hasta su centro.
func cap_line(tube: int, angle: float, start := false) -> Array:
	var out: Array = []
	if tube < 0 or tube >= _tubes.size():
		return out
	var data: Dictionary = _tubes[tube]
	var heights: PackedFloat32Array = data["at"]
	var edge := surface(tube, heights[0] if start else heights[heights.size() - 1], angle)
	var loop: BodyLoop = data.get("start_loop" if start else "cap_loop")
	if edge.is_empty() or loop == null or loop.is_point():
		return out
	var centre: Vector3 = data["start_centre" if start else "cap_centre"]
	var frame: Basis = data["start_basis" if start else "cap_basis"]
	# DÓNDE ENTRA: el punto del borde del cuadrado que cae más cerca del de la vuelta de arriba.
	var uv := Vector2.ZERO
	var nearest := INF
	for k in CAP_BORDER_SAMPLES:
		var t: float = 4.0 * float(k) / float(CAP_BORDER_SAMPLES)
		var side := int(t)
		var f: float = (t - float(side)) * 2.0 - 1.0
		var candidate: Vector2 = [Vector2(f, -1.0), Vector2(1.0, f), Vector2(-f, 1.0), Vector2(-1.0, -f)][side]
		var d: float = _placed_point(loop, centre, frame, candidate.x, candidate.y).distance_squared_to(edge[0])
		if d < nearest:
			nearest = d
			uv = candidate
	# POR LA VETA QUE ENTRA AHÍ: por el frente o la espalda, `v` con `u` fijo; por un costado, al revés. Hasta el borde de
	# enfrente.
	var along_v: bool = absf(uv.y) >= absf(uv.x)
	var heading: float = -signf(uv.y if along_v else uv.x)
	var walked := 0.0
	var prev := _placed_point(loop, centre, frame, uv.x, uv.y)
	out.append([0.0, prev])
	for i in (CAP_WALK_STEPS if start else CAP_WALK_STEPS * 2):
		if along_v:
			uv.y += heading / float(CAP_WALK_STEPS)
		else:
			uv.x += heading / float(CAP_WALK_STEPS)
		var next := _placed_point(loop, centre, frame, uv.x, uv.y)
		walked += next.distance_to(prev)
		out.append([walked, next])
		prev = next
	return out


## ── LO QUE SE VE DESDE ARRIBA ────────────────────────────────────────────────────────────────────
## El punto más alto de la malla en (`x`, `z`), mirando para abajo por −Y: `[posición, normal, huesos, pesos]` como
## `surface`, con la normal de su cara y los pesos de la esquina más cercana; vacío si ahí no hay malla. Es para lo que
## no está sobre un tubo: la tapa de arriba del torso, que se rellena y no es de vueltas (el cierre del mameluco cruza
## por ella hasta el cuello, ver `drape`).
func from_above(x: float, z: float) -> Array:
	var best := -INF
	var out: Array = []
	var at := Vector2(x, z)
	# SÓLO LOS TRIÁNGULOS DE SU CELDA (ver `_above_index`), en el mismo orden que recorriendo todos: mismo resultado.
	var index := _above_index()
	var cell: Variant = index.get(_above_cell(x, z))
	if cell == null:
		return out
	var tris: PackedInt32Array = cell
	for t in range(0, tris.size(), 2):
		var f: int = tris[t]
		var face: PackedInt32Array = _faces[f]
		for k in [tris[t + 1]]:
			var a: Vector3 = _points[face[0]]
			var b: Vector3 = _points[face[k]]
			var c: Vector3 = _points[face[k + 1]]
			var bary := _barycentric_xz(at, a, b, c)
			if bary.x < -1e-6 or bary.y < -1e-6 or bary.z < -1e-6:
				continue
			var y: float = a.y * bary.x + b.y * bary.y + c.y * bary.z
			if y <= best:
				continue
			best = y
			var nearest: int = face[0]
			if bary.y > bary.x and bary.y >= bary.z:
				nearest = face[k]
			elif bary.z > bary.x and bary.z > bary.y:
				nearest = face[k + 1]
			var normal: Vector3 = _face_normals[f]
			if normal.y < 0.0:
				normal = -normal
			out = [Vector3(x, y, z), normal, _point_bones[nearest], _point_weights[nearest], nearest]
	return out


## ── EL ÍNDICE VISTO DESDE ARRIBA (20/10/2026) ──────────────────────────────────────────────────────────────────────
## `from_above` (y `_from_below`) recorrían TODAS las caras por cada punto, y el cuello del mameluco y las costuras que
## pasan por la tapa de abajo les piden cientos: era medio segundo de cada personaje (lo midió el maestro de la estética de personajes cuando el dios del juego pidió
## que el sandbox respondiera más rápido). Ahora una grilla en x, z con, por celda, los triángulos que la tocan (su caja
## vista desde arriba, con un margen para la tolerancia de `from_above`), en orden de cara y de triángulo. Se rearma sola
## si los puntos o las caras cambiaron (la llave incluye la huella de los puntos, como `_relax_uv`).
const ABOVE_CELLS := 24
const ABOVE_MARGIN := 1e-4

var _above_key := ""
var _above_cells: Dictionary = {}
var _above_origin := Vector2.ZERO
var _above_size := Vector2.ONE


func _above_index() -> Dictionary:
	var key := "%d|%d|%d" % [_points.size(), _faces.size(), hash(_points)]
	if key == _above_key:
		return _above_cells
	_above_key = key
	_above_cells = {}
	if _points.is_empty():
		return _above_cells
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for p in _points:
		low = Vector2(minf(low.x, p.x), minf(low.y, p.z))
		high = Vector2(maxf(high.x, p.x), maxf(high.y, p.z))
	_above_origin = low - Vector2.ONE * ABOVE_MARGIN
	_above_size = Vector2(maxf(high.x - low.x, 1e-4), maxf(high.y - low.y, 1e-4)) / float(ABOVE_CELLS) \
		+ Vector2.ONE * (2.0 * ABOVE_MARGIN / float(ABOVE_CELLS))
	for f in _faces.size():
		var face: PackedInt32Array = _faces[f]
		for k in range(1, face.size() - 1):
			var a: Vector3 = _points[face[0]]
			var b: Vector3 = _points[face[k]]
			var c: Vector3 = _points[face[k + 1]]
			var c0 := _above_cell(minf(a.x, minf(b.x, c.x)) - ABOVE_MARGIN, minf(a.z, minf(b.z, c.z)) - ABOVE_MARGIN)
			var c1 := _above_cell(maxf(a.x, maxf(b.x, c.x)) + ABOVE_MARGIN, maxf(a.z, maxf(b.z, c.z)) + ABOVE_MARGIN)
			for i in range(c0.x, c1.x + 1):
				for j in range(c0.y, c1.y + 1):
					var cell := Vector2i(i, j)
					var list: PackedInt32Array = _above_cells.get(cell, PackedInt32Array())
					list.append(f)
					list.append(k)
					_above_cells[cell] = list
	return _above_cells


func _above_cell(x: float, z: float) -> Vector2i:
	return Vector2i(floori((x - _above_origin.x) / _above_size.x), floori((z - _above_origin.y) / _above_size.y))


## Las coordenadas baricéntricas de `p` en el triángulo `a b c` visto desde arriba (en x, z); con un triángulo de
## canto, todas negativas.
static func _barycentric_xz(p: Vector2, a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	var v0 := Vector2(b.x - a.x, b.z - a.z)
	var v1 := Vector2(c.x - a.x, c.z - a.z)
	var v2 := p - Vector2(a.x, a.z)
	var den: float = v0.x * v1.y - v1.x * v0.y
	if absf(den) < 1e-12:
		return Vector3(-1.0, -1.0, -1.0)
	var v: float = (v2.x * v1.y - v1.x * v2.y) / den
	var w: float = (v0.x * v2.y - v2.x * v0.y) / den
	return Vector3(1.0 - v - w, v, w)


## ── LAS LÍNEAS SON DE LA MALLA: EL SHADER LAS DIBUJA (21/10/2026) ───────────────────────────────────────────────────
## Lo pidió el dios del juego: las costuras coinciden siempre con aristas de la malla, y una cinta aparte —con su ancho y
## despegada por normales promediadas— nunca terminaba de calzar con la arista. Ahora una línea NO ES GEOMETRÍA: marca
## las aristas por las que pasa (`mark_line`), y al cerrar la malla cada triángulo que toca una arista marcada lleva, en
## sus vértices, su propio plano en metros y hasta dos SEGMENTOS en ese plano (ver `_apply_lines`); el shader del
## personaje pinta la distancia a esos segmentos (lo pintaba el shader de personajes, borrado el 29/10/2026: hoy no se dibujan). Así la línea está exactamente
## sobre la arista, se deforma con la malla, tiene un ancho parejo en metros y las uniones salen redondeadas.
##
## SEGMENTOS Y NO ARISTAS: una costura sobre una arista es el segmento de un vértice al otro; una DIAGONAL —de un punto
## de una arista a un punto de otra, que el dios del juego quiere poder hacer— es otro segmento en el mismo plano, sin
## tocar el shader.
##
## Los datos: CUSTOM0 = (x, y del vértice en el plano del triángulo, medio ancho, cuántos segmentos), CUSTOM1 y
## CUSTOM2 = los dos segmentos (ax, ay, bx, by), CUSTOM3 = el color (lineal). Un triángulo sin líneas los tiene en 0.
const LINE_FLAGS := (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM0_SHIFT) \
	| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM1_SHIFT) \
	| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM2_SHIFT) \
	| (Mesh.ARRAY_CUSTOM_RGBA_FLOAT << Mesh.ARRAY_FORMAT_CUSTOM3_SHIFT)

## Las aristas marcadas: `menor · 2²⁰ + mayor` (dos puntos) → [medio ancho, color].
var _line_edges := {}


static func _edge_key(a: int, b: int) -> int:
	return mini(a, b) * 1048576 + maxi(a, b)


## Los vecinos de cada punto por las aristas de la grilla (el borde de cada cara, nunca su diagonal).
var _grid_neighbours: Array[PackedInt32Array] = []
var _grid_neighbours_faces := -1


func _neighbours() -> Array[PackedInt32Array]:
	if _grid_neighbours_faces == _faces.size() and _grid_neighbours.size() == _points.size():
		return _grid_neighbours
	_grid_neighbours = []
	_grid_neighbours.resize(_points.size())
	for i in _points.size():
		_grid_neighbours[i] = PackedInt32Array()
	for face in _faces:
		for k in face.size():
			var a: int = face[k]
			var b: int = face[(k + 1) % face.size()]
			if not _grid_neighbours[a].has(b):
				_grid_neighbours[a].append(b)
			if not _grid_neighbours[b].has(a):
				_grid_neighbours[b].append(a)
	_grid_neighbours_faces = _faces.size()
	return _grid_neighbours


## LOS TRIÁNGULOS CON LÍNEAS, armados para el shader (ver arriba): cada uno que toca una arista marcada lleva vértices
## propios —copias de los suyos— con su plano y sus segmentos; los demás, ceros. Devuelve los anillos y columnas de las
## herramientas, alargados con las copias.
func _apply_lines(arrays: Array, vpoint: PackedInt32Array, rings: PackedInt32Array,
		cols: PackedInt32Array) -> Array:
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var has_colors: bool = arrays[Mesh.ARRAY_COLOR] != null
	var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR] if has_colors else PackedColorArray()
	var has_uvs: bool = arrays[Mesh.ARRAY_TEX_UV] != null
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV] if has_uvs else PackedVector2Array()
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var per := bones.size() / maxi(verts.size(), 1)
	var c0 := PackedFloat32Array()
	var c1 := PackedFloat32Array()
	var c2 := PackedFloat32Array()
	var c3 := PackedFloat32Array()
	c0.resize(verts.size() * 4)
	c1.resize(verts.size() * 4)
	c2.resize(verts.size() * 4)
	c3.resize(verts.size() * 4)
	for t in index.size() / 3:
		var corner := [index[t * 3], index[t * 3 + 1], index[t * 3 + 2]]
		var segments: Array = []
		var half := 0.0
		var paint := Color.BLACK
		for k in 3:
			var a: int = corner[k]
			var b: int = corner[(k + 1) % 3]
			var mark: Variant = _line_edges.get(_edge_key(vpoint[a], vpoint[b]))
			if mark != null:
				segments.append([k, (k + 1) % 3])
				half = maxf(half, float(mark[0]))
				paint = mark[1]
		if segments.is_empty():
			continue
		# EL PLANO DEL TRIÁNGULO, en metros: la primera esquina en el origen y la segunda sobre +x.
		var p0: Vector3 = verts[corner[0]]
		var p1: Vector3 = verts[corner[1]]
		var p2: Vector3 = verts[corner[2]]
		var ax := (p1 - p0).normalized()
		var n := (p1 - p0).cross(p2 - p0)
		if n.length_squared() < 1e-16:
			continue
		var ay := n.normalized().cross(ax)
		var flat := [Vector2.ZERO, Vector2((p1 - p0).dot(ax), 0.0), Vector2((p2 - p0).dot(ax), (p2 - p0).dot(ay))]
		var seg := []
		for s in mini(segments.size(), 2):
			var a2: Vector2 = flat[int(segments[s][0])]
			var b2: Vector2 = flat[int(segments[s][1])]
			seg.append([a2.x, a2.y, b2.x, b2.y])
		while seg.size() < 2:
			seg.append([0.0, 0.0, 0.0, 0.0])
		for k in 3:
			var v: int = corner[k]
			var copy := verts.size()
			verts.append(verts[v])
			normals.append(normals[v])
			if has_colors:
				colors.append(colors[v])
			if has_uvs:
				uvs.append(uvs[v])
			for m in per:
				bones.append(bones[v * per + m])
				weights.append(weights[v * per + m])
			if not rings.is_empty():
				rings.append(rings[v])
			if not cols.is_empty():
				cols.append(cols[v])
			var here: Vector2 = flat[k]
			c0.append_array([here.x, here.y, half, float(mini(segments.size(), 2))])
			c1.append_array(seg[0])
			c2.append_array(seg[1])
			c3.append_array([paint.r, paint.g, paint.b, 1.0])
			index[t * 3 + k] = copy
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	if has_colors:
		arrays[Mesh.ARRAY_COLOR] = colors
	if has_uvs:
		arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	arrays[Mesh.ARRAY_INDEX] = index
	arrays[Mesh.ARRAY_CUSTOM0] = c0
	arrays[Mesh.ARRAY_CUSTOM1] = c1
	arrays[Mesh.ARRAY_CUSTOM2] = c2
	arrays[Mesh.ARRAY_CUSTOM3] = c3
	return [rings, cols]


## UNA CINTA POR PUNTOS QUE YA ESTÁN SOBRE UNA SUPERFICIE, cada uno `[posición, normal, huesos, pesos]` como los dan
## `surface` y `cut_x`, en orden: de `width`, despegada `lift` por la normal de cada punto. Es lo que dibuja una línea.
func draw_ribbon(samples: Array, closed: bool, width: float, lift: float, color: Color) -> void:
	var count := samples.size()
	if count < 2:
		return
	var left := PackedInt32Array()
	var right := PackedInt32Array()
	for k in count:
		var s: Array = samples[k]
		var here: Vector3 = s[0]
		var normal: Vector3 = s[1]
		var prev: Vector3 = (samples[(k + count - 1) % count] as Array)[0] if closed or k > 0 else here
		var next: Vector3 = (samples[(k + 1) % count] as Array)[0] if closed or k < count - 1 else here
		var into: Vector3 = (here - prev).normalized()
		var out_of: Vector3 = (next - here).normalized()
		var tangent: Vector3 = into + out_of
		if tangent.length_squared() < 1e-12:
			tangent = out_of if out_of.length_squared() > 0.0 else into
		var side: Vector3 = normal.cross(tangent).normalized()
		# EL INGLETE: en una esquina la cinta se ensancha, para que sus bordes sigan paralelos a los dos tramos.
		var leg: Vector3 = out_of if out_of.length_squared() > 0.0 else into
		var miter: float = 1.0 / maxf(side.dot(normal.cross(leg).normalized()), 0.5)
		var lifted: Vector3 = here + normal * lift
		var half: Vector3 = side * width * 0.5 * miter
		left.append(_add_point(lifted - half, -1, s[2], s[3]))
		right.append(_add_point(lifted + half, -1, s[2], s[3]))
	for k in (count if closed else count - 1):
		var n: int = (k + 1) % count
		var outward: Vector3 = (samples[k] as Array)[1] + (samples[n] as Array)[1]
		_add_face(PackedInt32Array([left[k], right[k], right[n], left[n]]), outward, color)


## UN PUNTO DE LA GRILLA DE UN PARCHE (`at`, −1..1 en los dos ejes) llevado al rectángulo de esquinas redondeadas de
## `radius` metros: fuera de las esquinas no se mueve —los lados quedan rectos—, y adentro del cuadrado de cada esquina se
## lleva a su cuarto de círculo con el mapeo de grilla elíptica (el de las secciones, ver `_section_point`), que deja los
## quads parejos y empalma sin escalón con lo de al lado.
static func _rounded_corner(at: Vector2, half: Vector2, radius: float) -> Vector2:
	if radius <= 0.0 or half.x <= 0.0 or half.y <= 0.0:
		return at
	var metric := Vector2(at.x * half.x, at.y * half.y)
	var corner := Vector2(half.x - radius, half.y - radius)
	var d := Vector2(absf(metric.x) - corner.x, absf(metric.y) - corner.y)
	if d.x <= 0.0 or d.y <= 0.0:
		return at
	var s := d / radius
	var disc := Vector2(s.x * sqrt(maxf(1.0 - s.y * s.y * 0.5, 0.0)), s.y * sqrt(maxf(1.0 - s.x * s.x * 0.5, 0.0)))
	var moved := corner + disc * radius
	return Vector2(signf(at.x) * moved.x / half.x, signf(at.y) * moved.y / half.y)


## El tramo entre dos anillos en el que cae una altura; si cae afuera, el de la punta más cercana. Sirve para alturas
## que crecen o que decrecen.
static func _segment(heights: PackedFloat32Array, at: float) -> int:
	var last: int = heights.size() - 2
	for k in last + 1:
		if (at - heights[k]) * (at - heights[k + 1]) <= 0.0:
			return k
	return 0 if absf(at - heights[0]) < absf(at - heights[last + 1]) else last


## EL PUNTO DE UN ANILLO EN UN ÁNGULO, entre las dos columnas que lo rodean: `[posición, hacia dónde crece el ángulo,
## huesos, pesos]`, o vacío si el anillo es un punto.
## ── EL ÁNGULO ES DE LAS COLUMNAS, NO DE CADA ANILLO (20/10/2026) ────────────────────────────────────────────
## Lo pidió el dios del juego: todo lo que se dibuja sobre la malla tiene que seguir su estructura. El ángulo se medía en
## cada anillo por separado, y una columna no está al mismo ángulo en todos —el torso se angosta, se corre, se arquea—,
## así que una línea vertical fuera de los ejes cruzaba las columnas en diagonal (el bolsillo salía torcido). Ahora un
## ángulo cae SIEMPRE entre las mismas dos columnas y en la misma fracción entre ellas: la de un anillo de referencia, el
## del medio del tubo (`nominal`, que se mide en la geometría y por eso respeta el marco de cada pieza, aunque el del
## muslo tenga su Z dado vuelta). Así, a ángulo fijo se va por una columna y a altura fija por un anillo, en todo: las
## costuras, los trazos, los parches, las bandas.
func _ring_sample(data: Dictionary, r: int, angle: float) -> Array:
	var ring: PackedInt32Array = data["ring"]
	var columns: int = data["columns"]
	var nominal := _nominal_angles(data)
	for c in columns:
		var i: int = ring[r * columns + c]
		var j: int = ring[r * columns + (c + 1) % columns]
		var from: float = nominal[c]
		var step: float = wrapf(nominal[(c + 1) % columns] - from, -PI, PI)
		var into: float = wrapf(angle - from, -PI, PI)
		if absf(step) < EPSILON or into * step < 0.0 or absf(into) > absf(step):
			continue
		var f: float = into / step
		var pair := _mix_weights(_point_bones[i], _point_weights[i], _point_bones[j], _point_weights[j], f)
		# HACIA DONDE CRECE EL ÁNGULO, sea cual sea el sentido en que corren las columnas.
		return [_points[i].lerp(_points[j], f), (_points[j] - _points[i]) * signf(step), pair[0], pair[1]]
	return []


## EL VÉRTICE DEL TUBO más cercano a `(at, angle)`: el del anillo más cercano en altura y la columna más cercana en ángulo
## (ver `_nominal_angles`), o −1 si la altura cae fuera del tubo (en una tapa).
func _tube_vertex(tube: int, at: float, angle: float) -> int:
	if tube < 0 or tube >= _tubes.size():
		return -1
	var data: Dictionary = _tubes[tube]
	var heights: PackedFloat32Array = data["at"]
	if heights.size() < 2 or not _inside(heights, at):
		return -1
	var nominal := _nominal_angles(data)
	var best := 0
	for c in nominal.size():
		if absf(wrapf(angle - nominal[c], -PI, PI)) < absf(wrapf(angle - nominal[best], -PI, PI)):
			best = c
	var ring: PackedInt32Array = data["ring"]
	return ring[_nearest_height(heights, at) * int(data["columns"]) + best]


## LOS ÁNGULOS DE LAS COLUMNAS de un tubo, medidos una vez en su anillo del medio (ver `_ring_sample`).
func _nominal_angles(data: Dictionary) -> PackedFloat32Array:
	if data.has("nominal"):
		return data["nominal"]
	var ring: PackedInt32Array = data["ring"]
	var columns: int = data["columns"]
	var centres: PackedVector3Array = data["centres"]
	var mid: int = centres.size() / 2
	var out := PackedFloat32Array()
	for c in columns:
		out.append(_angle_of(_points[ring[mid * columns + c]] - centres[mid]))
	data["nominal"] = out
	return out


## El ángulo de un punto alrededor de su centro, en horizontal: 0 al frente (−Z), creciendo hacia +X.
static func _angle_of(offset: Vector3) -> float:
	return atan2(offset.x, -offset.z)


## LOS PUNTOS DE UN CAMINO, cada `step` metros más o menos: cada tramo se parte según cuánto mide sobre la superficie,
## medido recorriéndolo de a pedacitos (una vuelta entera empieza y termina en el mismo punto, así que de punta a punta
## mide cero). Un camino cerrado no repite su arranque.
static func _densify(source: GridPart, tube: int, path: PackedVector2Array, closed: bool,
		step: float) -> PackedVector2Array:
	var points := path.duplicate()
	if closed and points.size() > 1:
		var first: Vector2 = points[0]
		var last: Vector2 = points[points.size() - 1]
		var same: bool = absf(last.x - first.x) < EPSILON and absf(wrapf(last.y - first.y, -PI, PI)) < EPSILON
		if not same:
			points.append(first)
	# ── LOS PUNTOS DE UNA LÍNEA VAN EN LOS ANILLOS DE LA MALLA (20/10/2026) ─────────────────────────────────────────
	# Lo vio el dios del juego: al deformarse el cuerpo, las costuras y el cierre se movían en zigzag. Un punto ENTRE dos
	# anillos lleva sus pesos mezclados, y la piel deformada no es la mezcla de los dos anillos deformados (el skinning no
	# es lineal en eso): ese punto se despegaba o se hundía, y el de al lado —en un anillo— no. Así que una línea se
	# apoya sólo donde la malla es exacta: donde CRUZA un anillo (todos sus puntos pesan igual) y, la que da la vuelta a una
	# altura, SOBRE el anillo más cercano —una costura alrededor es un loop cut—, en cada columna. Entre esos puntos va
	# recta, como las aristas de la malla. Fuera del tubo —en una tapa— sigue el reparto parejo de antes, cada `step`.
	var data: Dictionary = source._tubes[tube] if tube >= 0 and tube < source._tubes.size() else {}
	var heights: PackedFloat32Array = data.get("at", PackedFloat32Array())
	var out := PackedVector2Array()
	for k in points.size() - 1:
		var a: Vector2 = points[k]
		var b: Vector2 = points[k + 1]
		if heights.size() >= 2 and _inside(heights, a.x) and _inside(heights, b.x):
			if absf(b.x - a.x) < EPSILON:
				# ALREDEDOR, A UNA ALTURA: sobre el anillo más cercano, en cada columna que cruza.
				var ring_at: float = heights[_nearest_height(heights, a.x)]
				out.append(Vector2(ring_at, a.y))
				for angle in _column_crossings(source._nominal_angles(data), a.y, b.y):
					out.append(Vector2(ring_at, angle))
				continue
			# A LO LARGO: en cada anillo que cruza y en cada columna (ver `line_samples`: así ningún tramo cruza una arista).
			out.append(a)
			var lo: float = minf(a.x, b.x)
			var hi: float = maxf(a.x, b.x)
			var crossings: Array[float] = []
			if absf(b.x - a.x) > EPSILON:
				for h in heights:
					if h > lo + EPSILON and h < hi - EPSILON:
						crossings.append((h - a.x) / (b.x - a.x))
			if absf(b.y - a.y) > EPSILON:
				for angle in _column_crossings(source._nominal_angles(data), a.y, b.y):
					crossings.append((angle - a.y) / (b.y - a.y))
			crossings.sort()
			for t in crossings:
				out.append(a.lerp(b, t))
			continue
		var length := 0.0
		var before: Array = source.surface(tube, a.x, a.y)
		for m in range(1, DENSIFY_PROBES + 1):
			var p: Vector2 = a.lerp(b, float(m) / float(DENSIFY_PROBES))
			var now: Array = source.surface(tube, p.x, p.y)
			if not before.is_empty() and not now.is_empty():
				length += (before[0] as Vector3).distance_to(now[0])
			before = now
		var pieces: int = maxi(1, ceili(length / maxf(step, 1e-4)))
		for m in pieces:
			out.append(a.lerp(b, float(m) / float(pieces)))
	if not closed:
		var tail: Vector2 = points[points.size() - 1]
		if points.size() >= 2 and heights.size() >= 2 and absf(tail.x - points[points.size() - 2].x) < EPSILON \
				and _inside(heights, tail.x):
			tail.x = heights[_nearest_height(heights, tail.x)]
		out.append(tail)
	return out


static func _inside(heights: PackedFloat32Array, at: float) -> bool:
	return at >= heights[0] - EPSILON and at <= heights[heights.size() - 1] + EPSILON


static func _nearest_height(heights: PackedFloat32Array, at: float) -> int:
	var best := 0
	for r in heights.size():
		if absf(heights[r] - at) < absf(heights[best] - at):
			best = r
	return best


## LOS ÁNGULOS DE LAS COLUMNAS que hay entre `from` y `to` (radianes, recorriendo de uno al otro), en orden.
static func _column_crossings(nominal: PackedFloat32Array, from: float, to: float) -> PackedFloat32Array:
	var span: float = to - from
	var out := PackedFloat32Array()
	if absf(span) < EPSILON:
		return out
	var found: Array = []
	for angle in nominal:
		# Cada columna, en todas sus vueltas que caigan dentro del tramo (un tramo puede pasar de una vuelta entera).
		var base: float = from + wrapf(angle - from, 0.0, TAU) if span > 0.0 else from - wrapf(from - angle, 0.0, TAU)
		var t: float = (base - from) / span
		while t > EPSILON and t < 1.0 - EPSILON:
			found.append(t)
			base += TAU * signf(span)
			t = (base - from) / span
	found.sort()
	for t: float in found:
		out.append(from + span * t)
	return out


## En cuántos pedacitos se recorre un tramo para medirlo (ver `_densify`).
const DENSIFY_PROBES := 24


# ── INTERNO ─────────────────────────────────────────────────────────────────────────────────────

func _add_point(at: Vector3, ring: int, bones: PackedInt32Array,
		weights: PackedFloat32Array, column := -1) -> int:
	var index := _points.size()
	_points.append(at)
	_point_uv.append(Vector2.ZERO)
	_point_ring.append(ring)
	_point_column.append(column)
	_point_bones.append(bones)
	_point_weights.append(weights)
	return index


## Agrega una cara con la vuelta que deja su normal mirando hacia `outward`, y descarta las degeneradas.
##
## LA NORMAL Y EL BOBINADO SALEN DE LA MISMA FÓRMULA: `(a − c) × (a − b)` sobre las tres primeras esquinas,
## que es la cuenta que hace `Plane(p1, p2, p3)` de Godot para decidir cuál es la cara de adelante. Con el
## producto cruzado de las DIAGONALES el signo sale al revés para este bobinado, así que la corrección daba
## vuelta el bobinado y dejaba la normal: la malla salía con todas las caras del revés.
## ── LAS CARAS QUE CRUZAN DE UNA PIERNA A LA OTRA ────────────────────────────────────────────────
## Índices de CARA, anotados mientras se arman, y de ahí salen los triángulos que el panel pinta aparte (ver
## `bridge_triangles` y QuadWire): la entrepierna y las dos caras con las que la banda de la pelvis cruza de
## un muslo al otro.
##
## Se marcan porque son la parte de la pelvis que NO es simétrica a nada: cada pierna tiene su banda, y
## entre las dos queda este puente, que es lo que decide si la entrepierna se lee como un pliegue o como una
## membrana. Verlo pintado de otro color es lo que permite discutirlo.
var _bridge_faces := PackedInt32Array()

## Los TRIÁNGULOS de esas caras, en la malla terminada: lo que el panel pinta. Se llena en `commit`, que es
## donde una cara se vuelve uno o dos triángulos.
var bridge_triangles := PackedInt32Array()


func _add_face(corners: PackedInt32Array, outward: Vector3, color := Color.WHITE,
		uvs := PackedVector2Array()) -> void:
	var a: Vector3 = _points[corners[0]]
	var b: Vector3 = _points[corners[1]]
	var c: Vector3 = _points[corners[2]]
	var normal := (a - c).cross(a - b)
	if normal.length_squared() < 1e-14 and corners.size() == 4:
		# Un quad con dos esquinas en el mismo punto —el polo de una cúpula— es un triángulo de verdad.
		var triangle := _as_triangle(corners)
		if triangle.is_empty():
			return
		# Sus coordenadas de textura, las de las esquinas que quedaron.
		if uvs.size() == corners.size():
			var kept := PackedVector2Array()
			for at in triangle:
				kept.append(uvs[corners.find(at)])
			uvs = kept
		corners = triangle
		a = _points[corners[0]]
		b = _points[corners[1]]
		c = _points[corners[2]]
		normal = (a - c).cross(a - b)
	if normal.length_squared() < 1e-14:
		return
	normal = normal.normalized()
	if outward.length_squared() > 1e-12 and normal.dot(outward) < 0.0:
		corners.reverse()
		uvs.reverse()
		normal = -normal
	if uvs.size() != corners.size():
		uvs = PackedVector2Array()
	else:
		_uv_used = true
	_face_uvs.append(uvs)
	_faces.append(corners)
	_face_normals.append(normal)
	_face_colors.append(color)
	_face_flat.append(1 if flat else 0)
	_face_limit.append(cos(deg_to_rad(auto_smooth)) if auto_smooth >= 0.0 else -2.0)
	if color != Color.WHITE:
		_painted = true


## EL UNWRAP AFLOJADO (ver `relax_uv`). Las incógnitas son las esquinas con su coordenada de partida —un punto en una
## costura es dos: uno por lado—; los triángulos de cada cara, las ecuaciones. Para cada triángulo, con sus esquinas en
## su plano como números complejos z, el mapeo es conforme si R = Σ W_k U_k = 0, con W_0 = z1 − z2, W_1 = z2 − z0,
## W_2 = z0 − z1; la energía es Σ |R|² / área. Se minimiza por Gauss-Seidel —cada incógnita, la mejor con las demás
## quietas—, desde el unwrap de fórmulas, que ya está cerca. Después, cada isla vuelve a sus metros y a su orientación:
## la semejanza (escala, giro y corrimiento) que mejor la lleva al unwrap de partida.
func _relax_uv() -> void:
	var key := "%d|%d|%d" % [_points.size(), _faces.size(), hash(_points)]
	if _relaxed_cache.has(key):
		var saved: Array = _relaxed_cache[key]
		if saved.size() == _face_uvs.size():
			for f in saved.size():
				_face_uvs[f] = saved[f]
			return
	# LAS INCÓGNITAS: (punto, coordenada de partida) → índice.
	var ids: Dictionary = {}
	var start := PackedVector2Array()
	var corner_ids: Array[PackedInt32Array] = []
	for f in _faces.size():
		var uvs: PackedVector2Array = _face_uvs[f]
		var row := PackedInt32Array()
		if uvs.is_empty():
			corner_ids.append(row)
			continue
		var corners: PackedInt32Array = _faces[f]
		for k in corners.size():
			var uv: Vector2 = uvs[k]
			var id_key := "%d|%d|%d" % [corners[k], roundi(uv.x * 100000.0), roundi(uv.y * 100000.0)]
			if not ids.has(id_key):
				ids[id_key] = start.size()
				start.append(uv)
			row.append(int(ids[id_key]))
		corner_ids.append(row)
	var count := start.size()
	if count < 3:
		return
	# LOS TRIÁNGULOS: sus tres incógnitas, sus W (complejos) y su peso 1/área.
	var tri := PackedInt32Array()
	var w := PackedVector2Array()
	var inv_area := PackedFloat32Array()
	var touching: Array[PackedInt32Array] = []
	touching.resize(count)
	for i in count:
		touching[i] = PackedInt32Array()
	for f in _faces.size():
		var row: PackedInt32Array = corner_ids[f]
		if row.is_empty():
			continue
		var corners: PackedInt32Array = _faces[f]
		var splits: Array = [[0, 1, 2]] if row.size() == 3 else [[0, 1, 2], [0, 2, 3]]
		for each: Array in splits:
			var p0: Vector3 = _points[corners[each[0]]]
			var p1: Vector3 = _points[corners[each[1]]]
			var p2: Vector3 = _points[corners[each[2]]]
			var e1 := p1 - p0
			var normal := e1.cross(p2 - p0)
			var area: float = normal.length() * 0.5
			if area < 1e-12:
				continue
			e1 = e1.normalized()
			var e2 := normal.normalized().cross(e1)
			var z0 := Vector2.ZERO
			var z1 := Vector2((p1 - p0).dot(e1), (p1 - p0).dot(e2))
			var z2 := Vector2((p2 - p0).dot(e1), (p2 - p0).dot(e2))
			var t := tri.size() / 3
			for k in 3:
				var at: int = row[each[k]]
				tri.append(at)
				touching[at].append(t * 3 + k)
			w.append(z1 - z2)
			w.append(z2 - z0)
			w.append(z0 - z1)
			inv_area.append(1.0 / area)
	# DOS FIJAS, para que la isla no se achique hasta un punto: la primera y la más lejana a ella, en cada isla —sin
	# separar islas: con dos fijas por la primera, las otras islas quedan libres de achicarse, así que se fijan las dos
	# de cada componente—.
	var island := PackedInt32Array()
	island.resize(count)
	island.fill(-1)
	var islands: Array[PackedInt32Array] = []
	for seed_id in count:
		if island[seed_id] >= 0 or touching[seed_id].is_empty():
			continue
		var members := PackedInt32Array([seed_id])
		island[seed_id] = islands.size()
		var head := 0
		while head < members.size():
			var at: int = members[head]
			head += 1
			for slot: int in touching[at]:
				var base: int = slot - slot % 3
				for k in 3:
					var other: int = tri[base + k]
					if island[other] < 0:
						island[other] = islands.size()
						members.append(other)
		islands.append(members)
	var pinned := PackedByteArray()
	pinned.resize(count)
	for members in islands:
		var first: int = members[0]
		var far: int = first
		var best := -1.0
		for at in members:
			var d: float = start[at].distance_squared_to(start[first])
			if d > best:
				best = d
				far = at
		pinned[first] = 1
		pinned[far] = 1
	# GAUSS-SEIDEL: cada incógnita, la que hace mínima su parte de la energía con las demás quietas.
	var uv := start.duplicate()
	for sweep in RELAX_SWEEPS:
		for i in count:
			if pinned[i] == 1:
				continue
			var num := Vector2.ZERO
			var den := 0.0
			for slot: int in touching[i]:
				var base: int = slot - slot % 3
				var t: int = base / 3
				var wi: Vector2 = w[slot]
				var s := Vector2.ZERO
				for k in 3:
					if base + k == slot:
						continue
					var wk: Vector2 = w[base + k]
					var uk: Vector2 = uv[tri[base + k]]
					s += Vector2(wk.x * uk.x - wk.y * uk.y, wk.x * uk.y + wk.y * uk.x)
				var a: float = inv_area[t]
				# conj(wi) * s
				num += Vector2(wi.x * s.x + wi.y * s.y, wi.x * s.y - wi.y * s.x) * a
				den += wi.length_squared() * a
			if den > 1e-12:
				uv[i] = -num / den
	# CADA ISLA, DE VUELTA A SUS METROS: la semejanza U' = a·U + b (a, b complejos) que mejor la lleva al de partida.
	for members in islands:
		var mean_u := Vector2.ZERO
		var mean_s := Vector2.ZERO
		for at in members:
			mean_u += uv[at]
			mean_s += start[at]
		mean_u /= float(members.size())
		mean_s /= float(members.size())
		var cross := Vector2.ZERO
		var norm := 0.0
		for at in members:
			var du: Vector2 = uv[at] - mean_u
			var ds: Vector2 = start[at] - mean_s
			# conj(du) * ds
			cross += Vector2(du.x * ds.x + du.y * ds.y, du.x * ds.y - du.y * ds.x)
			norm += du.length_squared()
		if norm < 1e-12:
			continue
		var a := cross / norm
		for at in members:
			var du: Vector2 = uv[at] - mean_u
			uv[at] = Vector2(a.x * du.x - a.y * du.y, a.x * du.y + a.y * du.x) + mean_s
	# A LAS CARAS.
	for f in _faces.size():
		var row: PackedInt32Array = corner_ids[f]
		if row.is_empty():
			continue
		var uvs := PackedVector2Array()
		for at in row:
			uvs.append(uv[at])
		_face_uvs[f] = uvs
	if _relaxed_cache.size() >= RELAX_CACHE_MAX:
		_relaxed_cache.clear()
	_relaxed_cache[key] = _face_uvs.duplicate(true)


## LA COORDENADA DE TEXTURA de la esquina de la cara `f` que es el punto `at`: la de la cara si la trae, si no la del
## punto (ver `_face_uvs`).
func _corner_uv(f: int, at: int) -> Vector2:
	var uvs: PackedVector2Array = _face_uvs[f]
	if uvs.is_empty():
		return _point_uv[at]
	return uvs[(_faces[f] as PackedInt32Array).find(at)]


## LO QUE SE RECORRE ALREDEDOR DE CADA ANILLO, en metros, POR CARA DE LA CAJA (ver `_face_uvs`). El cuerpo es una caja
## de seis caras con loop cuts, redondeada después (lo dijo el dios del juego): las costuras del unwrap son sus aristas,
## así que los lados del tubo son CUATRO ISLAS —el frente, un costado, la espalda, el otro—, partidas en las esquinas
## de la grilla (`corners`, las columnas donde empieza cada lado). `out[r][2c]` es el `u` de la columna `c` en su cara y
## `out[r][2c + 1]` el de la columna que le sigue, en la misma cara (en la esquina, el largo entero de esa cara).
func _ring_around(ring: PackedInt32Array, count: int, columns: int, corners: PackedInt32Array) -> Array[PackedFloat32Array]:
	var out: Array[PackedFloat32Array] = []
	for r in count:
		var row := PackedFloat32Array()
		row.resize(columns * 2)
		var walked := 0.0
		for c in columns:
			if corners.has(c):
				walked = 0.0
			row[c * 2] = walked
			walked += _points[ring[r * columns + c]].distance_to(_points[ring[r * columns + (c + 1) % columns]])
			row[c * 2 + 1] = walked
		out.append(row)
	return out


## Un quad con esquinas repetidas, reducido a sus puntos distintos. Vacío si no quedan tres.
func _as_triangle(corners: PackedInt32Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	for at in corners:
		var repeated := false
		for already in out:
			if _points[already].distance_squared_to(_points[at]) < 1e-12:
				repeated = true
				break
		if not repeated:
			out.append(at)
	return out if out.size() == 3 else PackedInt32Array()


## A qué hueso de la cadena cae un `t`, y con qué `y` local. Un `t` negativo cae en el primero con `y`
## negativo y uno que se pasa en el último con `y` mayor que su largo: las dos cosas son a propósito.
static func _resolve(t: float, lengths: PackedFloat32Array) -> Vector2:
	var acc := 0.0
	var last: int = lengths.size() - 1
	for i in lengths.size():
		var l: float = lengths[i]
		if t <= acc + l or i == last:
			return Vector2(float(i), t - acc)
		acc += l
	return Vector2(0.0, t)


## LOS PESOS DE UN ANILLO: el hueso en el que cae y, si está dentro de la banda de una articulación, el
## vecino con el que se mezcla. Devuelve `[huesos, pesos, otro, parte_del_otro]`, y es la misma cuenta que
## hacía `PrismPart` — 50/50 en el nudo mismo, cayendo a 0 en el borde de la banda.
static func _weights(bone: int, y: float, bone_ids: PackedInt32Array, lengths: PackedFloat32Array,
		blend_bands: PackedFloat32Array) -> Array:
	var ids := PackedInt32Array([bone_ids[bone], 0, 0, 0])
	var values := PackedFloat32Array([1.0, 0.0, 0.0, 0.0])

	var l: float = lengths[bone]
	var other := -1
	var share := 0.0
	var before: float = _band(blend_bands, bone - 1, l)
	var after: float = _band(blend_bands, bone, l)
	if bone > 0 and before > 0.0 and y < before:
		other = bone - 1
		share = 0.5 * (1.0 - maxf(y, 0.0) / before)
	elif bone < bone_ids.size() - 1 and after > 0.0 and (l - y) < after:
		other = bone + 1
		share = 0.5 * (1.0 - maxf(l - y, 0.0) / after)
	if other < 0 or share <= 0.0:
		return [ids, values, -1, 0.0]

	ids[1] = bone_ids[other]
	values[0] = 1.0 - share
	values[1] = share
	return [ids, values, other, share]


## LOS PESOS DEL ARRANQUE DE UNA RAMA: pasan del hueso del que cuelga el agujero al primer hueso de la rama
## a lo largo de la banda.
##
## ── ARRANCA EN 1 Y CON UNA CURVA, NO EN 50/50 ──────────────────────────────────────
## El 50/50 es la convención de una articulación INTERNA, donde el nudo tiene hueso a los dos lados. Acá no:
## el anillo de la unión es un vértice de la TAPA y ya pesa entero al tronco, así que arrancar la rampa en
## 50/50 mete la mitad de la transición en el primer tramo. Medido en el muslo del generic, de pie: el primer
## anillo de la pierna saltaba a 61% de muslo y quedaba 1,5 cm más profundo que el resto de la pierna — un
## abombamiento en el arranque— y los pasos entre anillos daban 24, 5, 4, 4 y 2 mm. El primero, cinco veces
## los otros: eso es lo que se ve como escalonado.
##
## Así que la rampa arranca en `at_start` — lo que el tronco todavía pesa en la unión — y cae a 0 al borde
## de la banda con un `smoothstep`, que llega plano a las dos puntas: ni salto en la unión ni quiebre donde
## la banda termina. Con una pelvis adelante, `at_start` es lo que ella no alcanzó a entregar, así que las
## dos rampas se encadenan sin escalón (ver `pelvis_fill`).
##
## ⚠ EL MARCO NO SE MEZCLA, y por eso devuelve −1 de vecino. La base de reposo del tronco apunta para arriba
## y la del muslo para abajo, así que mezclarlas —lo que sí corresponde en una articulación interna— giraría
## la sección media vuelta. Lo que se mezcla acá es el PESO; la sección se orienta con la rama.
static func _anchor_weights(anchor: int, bone: int, y: float, band: float,
		at_start := 1.0) -> Array:
	var share: float = at_start * (1.0 - smoothstep(0.0, maxf(band, 1e-5), y))
	var ids := PackedInt32Array([bone, anchor, 0, 0])
	var values := PackedFloat32Array([1.0 - share, share, 0.0, 0.0])
	return [ids, values, -1, 0.0]


## La banda de un nudo, clampeada a la mitad del hueso para que dos nudos no se solapen.
static func _band(blend_bands: PackedFloat32Array, joint: int, bone_length: float) -> float:
	if joint < 0 or joint >= blend_bands.size():
		return 0.0
	return minf(blend_bands[joint], bone_length * 0.5)


