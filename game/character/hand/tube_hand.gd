class_name TubeHand

## ── LA MANO DE TUBOS (29/10/2026, sesión de siluetas de los personajes) ────────────────────────────────────────────
## Lo pidió el usuario al ver la mano estilizada: «no me gustan y no van con este estilo de juego… algo un poco más
## realista. Que sean 5 dedos y un poco más largos… los dedos unidos a la mesh los vamos a sacar por ahora. Vamos a
## dejar dedos separados. Así podemos ir iterando más rápido». Una palma y cinco dedos, cada uno su tubo low poly con
## domo en las dos puntas, sueltos (se tocan, no se cosen), y un hueso por falange (ver `bones`). Se probó en el banco
## del codo (ver ArmBendClip) y eligió la maciza (`CHOSEN`): es la del personaje, la palma de la muñeca y cada falange de
## su hueso (ver ProceduralBodyUtil._add_tube_hand_bones).
##
## El marco de la mano: la muñeca en el origen, −Y hacia los dedos, +X hacia la palma (el cuerpo), −Z hacia adelante
## (el pulgar). Las medidas, en metros para la muñeca de referencia (`REFERENCE_WIDTH`); otra muñeca la escala entera.

## Una muñeca de verdad mide unos 6 cm de lado a lado y su palma, 8,5; la del brazo del juego, 10: la mano se agranda con
## ella, así que queda de su tamaño y no de muñeca de juguete.
const REFERENCE_WIDTH := 0.075
const FINGER_SIDES := 8
const PALM_SIDES := 12

## LAS VARIANTES: `palm` [largo, ancho de lado a lado de los nudillos, grueso en la muñeca, grueso en los nudillos];
## `fingers` los largos del índice, el medio, el anular y el meñique; `finger_r` el radio en la base y en la punta;
## `thumb` [largo, radio en la base, radio en la punta]; `spread` cuánto se abren los dedos, en grados entre vecinos.
const VARIANTS := [
	{"name": "realista", "palm": [0.10, 0.092, 0.05, 0.034], "fingers": [0.085, 0.095, 0.088, 0.07],
	 "finger_r": [0.0105, 0.0085], "thumb": [0.072, 0.0125, 0.0095], "spread": 3.0},
	{"name": "dedos largos", "palm": [0.095, 0.088, 0.048, 0.032], "fingers": [0.1, 0.112, 0.104, 0.083],
	 "finger_r": [0.0098, 0.0078], "thumb": [0.08, 0.0118, 0.009], "spread": 3.5},
	{"name": "maciza", "palm": [0.10, 0.1, 0.056, 0.04], "fingers": [0.082, 0.092, 0.086, 0.068],
	 "finger_r": [0.0125, 0.0105], "thumb": [0.07, 0.0145, 0.0115], "spread": 2.0},
	# LA DE BLOQUES (01/11/2026, el usuario: «la muñeca, el alto y el ancho… sea el mismo que la del brazo. Así
	# siempre encaja a la perfección… y que los dedos escalen para llenar el espacio disponible y se lo dividan entre
	# ellos… el pulgar también copia el grosor de los otros»). La muñeca es el ancho del brazo: la palma es tan ancha y
	# tan gruesa como él, los cuatro dedos se reparten su ancho en cuartos (radio = ancho / 8), rectos, y el pulgar es
	# igual de grueso. AL RAS (`flush`, el usuario: «los dedos no están pegados a la pared opuesta a la palma…
	# las primeras falanges… tienen como un offset»): los dedos van pegados al dorso y nacen justo en el borde de la palma,
	# en línea, sin arco. Los largos, tres cuartos de los de una mano de verdad para esa palma: crecen con el brazo, y el del
	# musculoso, a largo entero, llegaba a 33 cm.
	{"name": "bloques", "palm": [0.06, 0.075, 0.075, 0.075], "fingers": [0.05, 0.056, 0.052, 0.042],
	 "finger_r": [0.009375, 0.009375], "thumb": [0.042, 0.009375, 0.009375], "spread": 0.0, "flush": true},
]
## LA ELEGIDA (29/10/2026, el usuario: «vamos a ir con… la mano maciza por ahora»).
const CHOSEN := 2
## La del cuerpo de bloques (ver arriba): es la de todos (ver `current`).
const BLOCKS := 3


## LA MANO QUE LLEVAN LOS PERSONAJES: la de bloques (la malla vieja, que llevaba la elegida, se borró el 07/11/2026). Su
## muñeca es el ancho del brazo (ver BlockShape.apply_to).
static func current() -> int:
	return BLOCKS


## ── LOS HUESOS DE LA MANO (29/10/2026, el usuario: «obviamente le agregaría huesos a la mano, así seguimos con el
## sistema ese que creo que es más simple, que mover objetos») ──────────────────────────────────────────────────────────
## Cada dedo, un tubo que se dobla en sus nudillos, con un hueso por falange: tres en los cuatro dedos y dos en el pulgar
## (el tercero, el metacarpiano, es la palma). El primero de cada dedo cuelga de la muñeca y nace en la base del tubo; los
## demás, del anterior, en su nudillo. La palma es toda de la muñeca. Los huesos en reposo son la mano recta, como se arma
## la malla: las poses vienen después, de cero.
##
## El marco de cada hueso, en el de la mano: el origen en su nudillo, +Y a lo largo del dedo hacia la punta, +Z de lado a
## lado de los nudillos (hacia atrás, el meñique) y +X lo que queda —hacia la palma—. Así, girar un hueso sobre su +Z
## cierra el dedo hacia la palma. El pulgar, con su +Z torcido: al cerrarse cruza hacia los dedos.

const DIGITS := ["thumb", "index", "middle", "ring", "pinky"]
## Lo largo de cada falange, en fracción del dedo: de la base a la punta.
const FINGER_PHALANGES := [0.48, 0.30, 0.22]
const THUMB_PHALANGES := [0.5, 0.5]
## La curva de un nudillo, en radios del dedo a cada lado: angosta, así el dedo se dobla en el nudillo y no a lo largo.
const KNUCKLE_BAND := 0.55


## ── APRETAR: CON EL PUÑO O CON EL DEDO (29/10/2026, la primera categoría de agarre, ver Interactable.Grip.PRESS) ──
## Las dos maneras quedan, y se elige con `press_with` (el F1 de la fila de botones del sandbox): el usuario
## prefería el puño —«es algo que se lee mejor a la distancia… esto de hacer el dedo y que coincida con el dedo, eso es
## todo muy complicado»—, con botones de un tamaño mínimo, pero «hay que hacer las dos versiones y mantener las dos… así
## yo las pruebo… no podemos definirlo ahora sin siquiera tener un componente de minijuegos para probarlo».
enum Press { FIST, FINGER }
static var press_with: Press = _saved_press()


## Lo guardado con el F1 (ver GripSettings); sin guardar, el puño.
static func _saved_press() -> Press:
	var saved := GripSettings.saved()
	return saved.press_with as Press if saved != null else Press.FIST

## Cuánto gira cada falange sobre su +Z, en grados, de la base a la punta. EL PUÑO: los cuatro dedos cerrados y el
## pulgar encima. Probada en el banco (ArmBendClip, `--vista=dedos`).
const FIST := {"thumb": [35, 45], "index": [85, 95, 65], "middle": [85, 95, 65], "ring": [85, 95, 65],
	"pinky": [85, 95, 65]}


## EL DEDO: el índice derecho y los otros tres cerrados, el pulgar encima.
const POINT := {"thumb": [35, 45], "middle": [85, 95, 65], "ring": [85, 95, 65], "pinky": [85, 95, 65]}

## La pose de apretar elegida (ver `press_with`).
static func press_pose() -> Dictionary:
	return FIST if press_with == Press.FIST else POINT


## LA PUNTA DEL ÍNDICE, en el marco de la mano: el final de su tubo con el domo de la punta.
static func index_tip(variant: int, wrist_width := REFERENCE_WIDTH) -> Vector3:
	for digit: Dictionary in digits(variant, wrist_width):
		if digit.name == "index":
			var dir: Vector3 = digit.dir
			return (digit.base as Vector3) + dir * (float(digit.length) + float(digit.r1))
	return Vector3.ZERO


## LOS NUDILLOS DEL PUÑO, en el marco de la mano: lo que toca al apretar. Al cerrarse, los dedos se doblan en su base y lo
## más adelante de la mano queda ahí, en el medio de la línea de los nudillos, casi sobre el eje del antebrazo: es
## apuntar con la punta de la mano, como cuando el brazo terminaba en un muñón.
static func knuckles(variant: int, wrist_width := REFERENCE_WIDTH) -> Vector3:
	var spec: Dictionary = VARIANTS[variant]
	var k := wrist_width / REFERENCE_WIDTH
	var palm: Array = spec.palm
	var radius: Array = spec.finger_r
	return Vector3(0.0, -(float(palm[0]) + float(radius[0]) * 1.2) * k, 0.0)


## EL HUECO DEL PUÑO, en el marco de la mano: donde queda lo que se empuña —un aro, una barra—, entre la palma y los dedos
## cerrados (TubeHand.FIST): del lado de la palma, a la altura de la primera falange del dedo del medio.
static func fist_hole(variant: int, wrist_width := REFERENCE_WIDTH) -> Vector3:
	for digit: Dictionary in digits(variant, wrist_width):
		if digit.name == "middle":
			var base: Vector3 = digit.base
			var first: float = float(digit.length) * float(FINGER_PHALANGES[0])
			return Vector3(base.x + first * 0.6, base.y + float(digit.r0) * 1.4, 0.0)
	return Vector3.ZERO


## EL MEDIO DE LA PALMA, en el marco de la mano.
static func palm_centre(variant: int, wrist_width := REFERENCE_WIDTH) -> Vector3:
	var palm: Array = VARIANTS[variant].palm
	return Vector3(0.0, -float(palm[0]) * wrist_width / REFERENCE_WIDTH * 0.5, 0.0)


## LOS DEDOS DE UNA MANO: por dedo, `name`, `base` (donde nace, en el marco de la mano), `dir`, `length`, `r0` y `r1`
## (los radios en la base y en la punta) y `phalanges` (lo largo de cada falange, en fracción).
static func digits(variant: int, wrist_width := REFERENCE_WIDTH) -> Array:
	var spec: Dictionary = VARIANTS[variant]
	var k := wrist_width / REFERENCE_WIDTH
	var palm: Array = spec.palm
	var length: float = palm[0] * k
	var width: float = palm[1] * k
	var out: Array = []
	# EL PULGAR: del costado de adelante de la palma, cerca de la muñeca, hacia abajo, un poco adelante y hacia la palma.
	var thumb: Array = spec.thumb
	out.append({"name": "thumb", "base": Vector3(palm[2] * k * 0.2, -length * 0.3, -width * 0.42),
		"dir": Vector3(0.35, -1.0, -0.25).normalized(), "length": float(thumb[0]) * k,
		"r0": float(thumb[1]) * k, "r1": float(thumb[2]) * k, "phalanges": THUMB_PHALANGES})
	# LOS CUATRO DEDOS, del índice (adelante) al meñique (atrás), sobre la línea de los nudillos (el del medio, más abajo).
	var fingers: Array = spec.fingers
	var radius: Array = spec.finger_r
	var r0: float = radius[0] * k
	var flush: bool = spec.get("flush", false)
	for i in 4:
		var f := float(i) / 3.0
		var z := lerpf(-width * 0.5 + r0, width * 0.5 - r0, f)
		var arch := 0.006 * k * (1.0 - absf(f - 0.4) * 2.0)
		var base := Vector3(-palm[3] * k * 0.08, -length + r0 * 0.6 - arch, z)
		if flush:
			base = Vector3(-palm[3] * k * 0.5 + r0, -length, z)
		out.append({"name": DIGITS[i + 1], "base": base,
			"dir": Vector3.DOWN.rotated(Vector3.RIGHT, deg_to_rad(spec.spread * (f - 0.4) * 3.0)),
			"length": float(fingers[i]) * k, "r0": r0, "r1": float(radius[1]) * k, "phalanges": FINGER_PHALANGES})
	return out


## LOS HUESOS, en orden de padre a hijo: cada uno `{"key", "parent"` ("" = la muñeca)`, "frame"}`, con el marco en el de
## la mano (ver arriba). `key` es "<dedo>_<falange>", de 1 en la base.
static func bones(variant: int, wrist_width := REFERENCE_WIDTH) -> Array:
	var out: Array = []
	for digit: Dictionary in digits(variant, wrist_width):
		var dir: Vector3 = digit.dir
		# El eje que cierra el dedo: de lado a lado de los nudillos, así la punta va hacia la palma (+X); el del pulgar,
		# torcido, así su punta cruza hacia los dedos y la palma a la vez.
		var hinge := Vector3(-1.0, 0.0, 1.0).normalized() if digit.name == "thumb" else Vector3.BACK
		var across := (hinge - dir * hinge.dot(dir)).normalized()
		var basis := Basis(dir.cross(across), dir, across)
		var along := 0.0
		var phalanges: Array = digit.phalanges
		for p in phalanges.size():
			out.append({"key": "%s_%d" % [digit.name, p + 1], "parent": "" if p == 0 else "%s_%d" % [digit.name, p],
				"frame": Transform3D(basis, (digit.base as Vector3) + dir * float(digit.length) * along)})
			along += float(phalanges[p])
	return out


## LA MANO ENTERA COMO GEOMETRÍA, en su marco, para una muñeca de `wrist_width` de lado a lado: `points` (los vértices,
## compartidos dentro de cada pieza), `normals` (las de la forma, por vértice), `faces` (cada una `[esquinas, afuera]`,
## quads y triángulos) y los pesos de cada vértice —`bone_a` y `bone_b`, índices en `bones()` (−1, la muñeca), y
## `weight_b`, lo que pesa el segundo—. Es lo que lee GridPart.add_skinned_geometry.
static func geometry(variant: int, wrist_width := REFERENCE_WIDTH) -> Dictionary:
	var spec: Dictionary = VARIANTS[variant]
	var k := wrist_width / REFERENCE_WIDTH
	var geo := {"points": PackedVector3Array(), "normals": PackedVector3Array(), "faces": [],
		"bone_a": PackedInt32Array(), "bone_b": PackedInt32Array(), "weight_b": PackedFloat32Array()}
	var palm: Array = spec.palm
	var length: float = palm[0] * k
	var width: float = palm[1] * k
	# LA PALMA: de la muñeca (un poco adentro del brazo) a los nudillos, gruesa arriba y chata abajo. Toda de la muñeca.
	tube(geo, PackedVector3Array([Vector3(0.0, 0.01 * k, 0.0), Vector3(0.0, -length * 0.5, 0.0),
		Vector3(0.0, -length, 0.0)]),
		[Vector2(palm[2] * k * 0.5, width * 0.42), Vector2((palm[2] + palm[3]) * k * 0.25, width * 0.5),
			Vector2(palm[3] * k * 0.5, width * 0.5)], 3.0, PALM_SIDES, 0.012 * k, 0.008 * k)
	# LOS DEDOS: un anillo en cada nudillo, mitad y mitad, y uno a cada lado, entero de su falange.
	var first := 0
	for digit: Dictionary in digits(variant, wrist_width):
		var base: Vector3 = digit.base
		var dir: Vector3 = digit.dir
		var long: float = digit.length
		var r0: float = digit.r0
		var r1: float = digit.r1
		var flat := 0.92 if digit.name != "thumb" else 0.9
		var phalanges: Array = digit.phalanges
		var stops: Array = [[0.0, first, first, 0.0]]
		var along := 0.0
		for p in phalanges.size() - 1:
			along += float(phalanges[p])
			var band: float = KNUCKLE_BAND * lerpf(r0, r1, along) / long
			stops.append([along - band, first + p, first + p, 0.0])
			stops.append([along, first + p, first + p + 1, 0.5])
			stops.append([along + band, first + p + 1, first + p + 1, 0.0])
		stops.append([1.0, first + phalanges.size() - 1, first + phalanges.size() - 1, 0.0])
		var centers := PackedVector3Array()
		var halves: Array = []
		var rig: Array = []
		for stop: Array in stops:
			var r := lerpf(r0, r1, float(stop[0]))
			centers.append(base + dir * long * float(stop[0]))
			halves.append(Vector2(r, r * flat))
			rig.append([stop[1], stop[2], stop[3]])
		tube(geo, centers, halves, 2.0, FINGER_SIDES, r0 * 0.8, r1, rig)
		first += phalanges.size()
	return geo


## LA MANO COMO MALLA SUELTA, para los bancos: la misma geometría, en triángulos con el frente afuera.
static func build(variant: int, wrist_width := REFERENCE_WIDTH) -> ArrayMesh:
	var geo := geometry(variant, wrist_width)
	var points: PackedVector3Array = geo.points
	var tris := PackedInt32Array()
	for face: Array in geo.faces:
		var c: PackedInt32Array = face[0]
		var out: Vector3 = face[1]
		for k in range(1, c.size() - 1):
			var a := points[c[0]]
			# El frente de Godot: el de `(a − c) × (a − b)` (ver GridPart._add_face).
			if (a - points[c[k + 1]]).cross(a - points[c[k]]).dot(out) >= 0.0:
				tris.append_array(PackedInt32Array([c[0], c[k], c[k + 1]]))
			else:
				tris.append_array(PackedInt32Array([c[0], c[k + 1], c[k]]))
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = geo.normals
	arrays[Mesh.ARRAY_INDEX] = tris
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


## ── UN TUBO CON DOMOS ─────────────────────────────────────────────────────────────────────────────────────────────
## Por `centers`, cada vuelta una superelipse de medio ancho `halves[i].x` (en X, o lo que quede de X perpendicular al
## eje) y medio fondo `halves[i].y`, de exponente `power` y `sides` lados; un domo de `start_dome` y `end_dome` en cada
## punta, cerrado en un polo. Se suma a `geo` (ver `geometry`).
## `rig`, por vuelta, `[hueso a, hueso b, peso de b]` (ver `geometry`); sin darlo, todo de la muñeca (−1).
static func tube(geo: Dictionary, centers: PackedVector3Array, halves: Array, power: float, sides: int,
		start_dome: float, end_dome: float, rig: Array = []) -> void:
	var points: PackedVector3Array = geo.points
	var normals: PackedVector3Array = geo.normals
	var faces: Array = geo.faces
	var bone_a: PackedInt32Array = geo.bone_a
	var bone_b: PackedInt32Array = geo.bone_b
	var weight_b: PackedFloat32Array = geo.weight_b
	var path := PackedVector3Array()
	var sizes: Array[Vector2] = []
	var skin: Array = []
	var n := centers.size()
	var first := (centers[1] - centers[0]).normalized()
	var last := (centers[n - 1] - centers[n - 2]).normalized()
	var steps := [0.92, 0.71, 0.38]
	var none := [-1, -1, 0.0]
	for s: float in steps:
		path.append(centers[0] - first * start_dome * s)
		sizes.append((halves[0] as Vector2) * sqrt(1.0 - s * s))
		skin.append(rig[0] if not rig.is_empty() else none)
	for i in n:
		path.append(centers[i])
		sizes.append(halves[i] as Vector2)
		skin.append(rig[i] if not rig.is_empty() else none)
	for k in range(steps.size() - 1, -1, -1):
		var s: float = steps[k]
		path.append(centers[n - 1] + last * end_dome * s)
		sizes.append((halves[n - 1] as Vector2) * sqrt(1.0 - s * s))
		skin.append(rig[n - 1] if not rig.is_empty() else none)
	var count := path.size()
	var start := points.size()
	for i in count:
		var t := (path[mini(i + 1, count - 1)] - path[maxi(i - 1, 0)]).normalized()
		var side := Vector3.RIGHT - t * t.dot(Vector3.RIGHT)
		if side.length() < 0.1:
			side = Vector3.BACK - t * t.dot(Vector3.BACK)
		side = side.normalized()
		var back := side.cross(t).normalized()
		for j in sides:
			var a := TAU * j / sides
			var c := cos(a)
			var s := sin(a)
			var x := signf(c) * pow(absf(c), 2.0 / power)
			var z := signf(s) * pow(absf(s), 2.0 / power)
			points.append(path[i] + side * x * sizes[i].x + back * z * sizes[i].y)
			var gx := signf(c) * pow(absf(x), power - 1.0) / maxf(sizes[i].x, 1e-5)
			var gz := signf(s) * pow(absf(z), power - 1.0) / maxf(sizes[i].y, 1e-5)
			normals.append((side * gx + back * gz).normalized())
			bone_a.append(int(skin[i][0]))
			bone_b.append(int(skin[i][1]))
			weight_b.append(float(skin[i][2]))
	for i in count - 1:
		for j in sides:
			var j2 := (j + 1) % sides
			var quad := PackedInt32Array([start + i * sides + j, start + i * sides + j2,
				start + (i + 1) * sides + j2, start + (i + 1) * sides + j])
			var out := Vector3.ZERO
			for q in quad:
				out += normals[q]
			faces.append([quad, out])
	var bottom := points.size()
	points.append(path[0] - first * start_dome * 0.08)
	normals.append(-first)
	var top := points.size()
	points.append(path[count - 1] + last * end_dome * 0.08)
	normals.append(last)
	for end: Array in [skin[0], skin[count - 1]]:
		bone_a.append(int(end[0]))
		bone_b.append(int(end[1]))
		weight_b.append(float(end[2]))
	for j in sides:
		var j2 := (j + 1) % sides
		faces.append([PackedInt32Array([bottom, start + j, start + j2]), -first])
		faces.append([PackedInt32Array([top, start + (count - 1) * sides + j, start + (count - 1) * sides + j2]), last])
	geo.points = points
	geo.normals = normals
	geo.bone_a = bone_a
	geo.bone_b = bone_b
	geo.weight_b = weight_b
