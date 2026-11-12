class_name BlockBody

## ── EL CUERPO DE CAJAS Y CÁPSULAS (31/10/2026, sesión de siluetas de los personajes) ──────────────────────────────────
## Lo pidió el dios del juego para iterar las poses, las animaciones y las manos sin que el modelo distraiga: «los modelos
## actuales, low poly de los personajes, me distraen de las animaciones… todo hecho con cubos estirados y con cápsulas».
## Cada pieza va PEGADA RÍGIDA a su hueso (pesa entera a él): cápsulas el brazo, el antebrazo, el muslo, la pierna y el
## cuello; cajas cada vértebra, los pies, la palma y cada falange; y la cabeza, SU FORMA DE CABEZA low poly (ver HeadForm). Las medidas son las de la forma de bloques
## del personaje (ver BlockShape, sus cinco reglas): un ancho por miembro, el hombro y la cadera adentro de sus cajas, el
## tobillo adentro del pie, el cuello saliendo del tope del pecho y la cabeza girando en su atlas.
##
## La malla vieja se borró el 07/11/2026 (vive en la etiqueta de git `malla-personaje-archivada`): ProceduralBodyUtil arma
## sus huesos —los del rig, las muñecas, los de los dedos— y después esto.
## Como cuelga del mismo esqueleto, la IK, la marcha, el agarre, la mano que se cierra, el giro de la muñeca y el ragdoll
## lo mueven igual.

## Lo bajas que son las cápsulas: pocas caras, que se lea el volumen y no la superficie.
const CAPSULE_SIDES := 12
const CAPSULE_RINGS := 2


## ARMA LAS PIEZAS de `body` sobre su esqueleto de dibujo, ya con todos sus huesos, con `skin` (el de su reposo).
static func build(body: ProceduralBodyUtil, sizes: SkeletonSizesUtil, skin: Skin) -> void:
	var shape := sizes.block_shape
	if shape == null:
		return
	var u := sizes.block_unit
	var parts := {}
	_trunk(body, shape, u, parts)
	_neck_and_head(body, sizes, shape, u, parts)
	for side in ["left", "right"]:
		_limb(body, ["%s_upper_arm" % side, "%s_lower_arm" % side], shape.arm_width * 0.5 * u, "%s_arm" % side, parts)
		_hand(body, sizes, side, parts)
		_limb(body, ["%s_higher_leg" % side, "%s_lower_leg" % side], shape.leg_width * 0.5 * u, "%s_leg" % side, parts)
		_foot(body, shape, u, side, parts)
	for part_name: String in parts:
		var mesh := _commit(parts[part_name])
		if mesh != null:
			body._hang(part_name, mesh, skin)


## ── LA COLUMNA: tres cajas del mismo alto ─────────────────────────────────────────────────────────────────────────
## Del fondo de la caja de abajo al tope de la del pecho mide el alto del torso; cada una, un tercio, con su ancho y su
## fondo. La columna nace un radio de pierna sobre el fondo y termina un radio de brazo debajo del tope (reglas 1 y 2),
## así que cada caja va corrida respecto de su vértebra: se arma en el marco del torso y se cuelga de ella.
static func _trunk(body: ProceduralBodyUtil, shape: BlockShape, u: float, parts: Dictionary) -> void:
	var chain := body._chain(["lower_spine", "higher_spine", "chest"])
	if chain.is_empty():
		return
	var lengths: PackedFloat32Array = chain[1]
	var third := shape.torso_height * u / 3.0
	var sizes := [Vector2(shape.lower_width, shape.lower_depth), Vector2(shape.middle_width, shape.middle_depth),
		Vector2(shape.chest_width, shape.chest_depth)]
	# Dónde nace cada vértebra, desde el fondo del torso.
	var from := shape.leg_width * 0.5 * u
	for i in 3:
		var centre := third * (float(i) + 0.5) - from
		var size: Vector2 = sizes[i] * u
		var placed: Transform3D = (chain[2] as Array)[i] * Transform3D(Basis(), Vector3(0.0, centre, 0.0))
		if i == 2 and _split_chest(body, parts, placed, Vector3(size.x, third, size.y), shape.neck_width * u):
			from += lengths[i]
			continue
		_box(parts, "trunk", (chain[0] as PackedInt32Array)[i], placed, Vector3(size.x, third, size.y))
		from += lengths[i]


## ── EL PECHO PARTIDO EN DOS (04/11/2026, lo pidió el dios del juego: «cuando agarran algo y sus hombros se van hacia
## adelante, se descolocan totalmente los brazos… que el hueso del pecho esté dividido en dos, así se puede doblar junto
## con los hombros»; «yo decía dos cajas») ─────────────────────────────────────────────────────────────────────────
## La caja del pecho, en DOS MITADES, cada una pesando a SU HOMBRO: cuando el hombro se va adelante o se levanta, su mitad
## del pecho va con él y el brazo no se despega. Se pisan un poco en el medio, así al girar no se abre una ranura. Falso
## si el esqueleto no tiene hombros (y queda la caja entera). *Un rato fueron tres: una franja del medio en el pecho.*
static func _split_chest(body: ProceduralBodyUtil, parts: Dictionary, placed: Transform3D, size: Vector3,
		_strip: float) -> bool:
	var left := body._chain(["left_shoulder"])
	var right := body._chain(["right_shoulder"])
	if left.is_empty() or right.is_empty():
		return false
	var overlap := size.x * 0.04
	var half := size.x * 0.5 + overlap
	for side: float in [-1.0, 1.0]:
		var bone := (left[0] as PackedInt32Array)[0] if side < 0.0 else (right[0] as PackedInt32Array)[0]
		var at := placed * Transform3D(Basis(), Vector3(side * (size.x * 0.5 - half * 0.5), 0.0, 0.0))
		_box(parts, "trunk", bone, at, Vector3(half, size.y, size.z * (1.0 if side < 0.0 else 0.995)))
	return true


## ── EL CUELLO, una cápsula; LA CABEZA, su forma ──────────────────────────────────────�
## El cuello va de la punta de la columna al atlas: su esfera de abajo queda en el pecho y la de arriba en la cabeza. La
## cabeza es la forma de su arquetipo (ver SkeletonSizesUtil.head_form, ya de su alto), en su marco bajado por el atlas
## (ver ProceduralBodyUtil._chain): de su fondo a la coronilla, que es como va la malla de la forma.
static func _neck_and_head(body: ProceduralBodyUtil, sizes: SkeletonSizesUtil, shape: BlockShape, u: float,
		parts: Dictionary) -> void:
	var neck := body._chain(["neck"])
	if not neck.is_empty():
		_capsule(parts, "neck", (neck[0] as PackedInt32Array)[0], (neck[2] as Array)[0],
			(neck[1] as PackedFloat32Array)[0], shape.neck_width * 0.5 * u)
	var head := body._chain(["head"])
	if head.is_empty() or sizes.head_form == null:
		return
	_add(parts, "head", (head[0] as PackedInt32Array)[0], (head[2] as Array)[0], sizes.head_form.build_arrays())


## ── UN MIEMBRO, dos cápsulas del mismo radio ──────────────────────────────────────────────────────────────────────
## Cada una con sus dos esferas centradas en las articulaciones de sus puntas: el codo y la rodilla quedan cerrados al
## doblarse, y la del hombro y la de la cadera, adentro de sus cajas.
static func _limb(body: ProceduralBodyUtil, fields: Array, radius: float, part_name: String, parts: Dictionary) -> void:
	var chain := body._chain(fields)
	if chain.is_empty():
		return
	for i in fields.size():
		_capsule(parts, part_name, (chain[0] as PackedInt32Array)[i], (chain[2] as Array)[i],
			(chain[1] as PackedFloat32Array)[i], radius)


## ── LA MANO: la palma, una caja; cada falange, una caja ──────────────────────────────────────────────────────────
## Las medidas de la mano de bloques (TubeHand.current()) para la muñeca del personaje (`hand_width`). La palma pesa a la
## muñeca; cada falange, a su hueso, así la mano se cierra igual (ver ProceduralBodyUtil.pose_hand).
static func _hand(body: ProceduralBodyUtil, sizes: SkeletonSizesUtil, side: String, parts: Dictionary) -> void:
	var wrist_field := "%s_wrist" % side
	if not body._index_of.has(wrist_field) or body._chain(["%s_upper_arm" % side, "%s_lower_arm" % side]).is_empty():
		return
	var k := sizes.hand_width / TubeHand.REFERENCE_WIDTH
	var palm: Array = (TubeHand.VARIANTS[TubeHand.current()] as Dictionary).palm
	var length: float = float(palm[0]) * k
	var thick := (float(palm[2]) + float(palm[3])) * k * 0.5
	_box(parts, "%s_hand" % side, int(body._index_of[wrist_field]),
		body._tube_hand_frame(side) * Transform3D(Basis(), Vector3(0.0, -length * 0.5, 0.0)),
		Vector3(thick, length, float(palm[1]) * k))
	for digit: Dictionary in TubeHand.digits(TubeHand.current(), sizes.hand_width):
		var phalanges: Array = digit.phalanges
		var along := 0.0
		for p in phalanges.size():
			var bone_name := "%s_tube_%s_%d" % [side, digit.name, p + 1]
			if body._index_of.has(bone_name):
				var bone := int(body._index_of[bone_name])
				var long: float = float(phalanges[p]) * float(digit.length)
				var r := lerpf(float(digit.r0), float(digit.r1), along + float(phalanges[p]) * 0.5)
				_box(parts, "%s_fingers" % side, bone,
					(body._rest_global[bone] as Transform3D) * Transform3D(Basis(), Vector3(0.0, long * 0.5, 0.0)),
					Vector3(r * 2.0, long, r * 2.0))
			along += float(phalanges[p])


## ── EL PIE, una caja ─────────────────────────────────────────────────────────────────────────────────────────────
## Del ancho de la pierna y de alto su radio, del piso al tobillo (regla 3), centrado bajo él. Arranca atrás en la línea
## de la cápsula —un radio detrás del tobillo—, sin escalón, y el resto de su largo va hacia adelante.
static func _foot(body: ProceduralBodyUtil, shape: BlockShape, u: float, side: String, parts: Dictionary) -> void:
	var shin := body._chain(["%s_lower_leg" % side])
	var foot_field := "%s_foot" % side
	if shin.is_empty() or not body._index_of.has(foot_field):
		return
	var radius := shape.leg_width * 0.5 * u
	var height := radius
	var heel := radius
	var length := maxf(shape.foot_length * u, radius * 2.0)
	var width := radius * 2.0
	var ankle: Vector3 = (shin[2] as Array)[0] * Vector3(0.0, (shin[1] as PackedFloat32Array)[0], 0.0)
	var centre := Vector3(ankle.x, ankle.y - height * 0.5, ankle.z + heel - length * 0.5)
	_box(parts, "%s_foot" % side, int(body._index_of[foot_field]), Transform3D(Basis(), centre),
		Vector3(width, height, length))


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────
## Una cápsula a lo largo de un hueso (su +Y, desde `rest`), de `radius`, con sus dos esferas centradas en las puntas.
static func _capsule(parts: Dictionary, part_name: String, bone: int, rest: Transform3D, length: float,
		radius: float) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = length + radius * 2.0
	mesh.radial_segments = CAPSULE_SIDES
	mesh.rings = CAPSULE_RINGS
	_add(parts, part_name, bone, rest * Transform3D(Basis(), Vector3(0.0, length * 0.5, 0.0)), mesh.get_mesh_arrays())


## Una caja de `size`, centrada en `placed` (en el espacio del esqueleto).
static func _box(parts: Dictionary, part_name: String, bone: int, placed: Transform3D, size: Vector3) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size.max(Vector3.ONE * 0.002)
	_add(parts, part_name, bone, placed, mesh.get_mesh_arrays())


## Suma la geometría `arrays`, llevada a `placed`, a la parte `part_name`, toda pesando a `bone`. Un marco espejado (la
## mano de un lado) se endereza dando vuelta su X: las dos piezas son simétricas en X, así que dan lo mismo, y no quedan
## al revés.
static func _add(parts: Dictionary, part_name: String, bone: int, placed: Transform3D, arrays: Array) -> void:
	if placed.basis.determinant() < 0.0:
		placed.basis = placed.basis * Basis.from_scale(Vector3(-1.0, 1.0, 1.0))
	if not parts.has(part_name):
		parts[part_name] = {"points": PackedVector3Array(), "normals": PackedVector3Array(), "indices": PackedInt32Array(),
			"bones": PackedInt32Array(), "weights": PackedFloat32Array()}
	var into: Dictionary = parts[part_name]
	var points: PackedVector3Array = into.points
	var normals: PackedVector3Array = into.normals
	var indices: PackedInt32Array = into.indices
	var bones: PackedInt32Array = into.bones
	var weights: PackedFloat32Array = into.weights
	var first := points.size()
	var normal_basis := placed.basis.inverse().transposed()
	for v: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
		points.append(placed * v)
		bones.append_array(PackedInt32Array([bone, 0, 0, 0]))
		weights.append_array(PackedFloat32Array([1.0, 0.0, 0.0, 0.0]))
	for n: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
		normals.append((normal_basis * n).normalized())
	for i: int in arrays[Mesh.ARRAY_INDEX]:
		indices.append(first + i)
	# (Los Packed dentro de un diccionario son copias: se vuelven a guardar.)
	into.points = points
	into.normals = normals
	into.indices = indices
	into.bones = bones
	into.weights = weights


## La malla de una parte, skinneada.
static func _commit(into: Dictionary) -> ArrayMesh:
	if (into.points as PackedVector3Array).is_empty():
		return null
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = into.points
	arrays[Mesh.ARRAY_NORMAL] = into.normals
	arrays[Mesh.ARRAY_INDEX] = into.indices
	arrays[Mesh.ARRAY_BONES] = into.bones
	arrays[Mesh.ARRAY_WEIGHTS] = into.weights
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
