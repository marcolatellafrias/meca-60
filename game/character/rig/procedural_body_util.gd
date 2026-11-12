class_name ProceduralBodyUtil
extends CharacterBodyVisual

## EL CUERPO DE LOS PERSONAJES: un `Skeleton3D` de dibujo que espeja el rig lógico, con las piezas del cuerpo de bloques
## colgadas de él (ver BlockBody).
##
## (LA MALLA VIEJA —el tronco, las piernas, los pies, el cuello, la cabeza, el traje, lo que se lleva encima y el
## borrador que la reusaba— se borró el 07/11/2026; estaba archivada desde el 31/10/2026 y vive en la etiqueta de git
## `malla-personaje-archivada`.)
##
## ── LA MUÑECA ES UN HUESO QUE NO EXISTE EN EL RIG ────────────────────────────────────────────────
## El rig lógico termina en `lower_arm`, y la mano tiene que colgar de ahí sin estirarse cuando el brazo
## se estira al agarrar (`ArmsController` le cambia el largo a los huesos del brazo). Una mano pesada a
## `lower_arm` se estiraría con él. Así que el esqueleto de dibujo lleva dos huesos de ANCLAJE —
## `left_wrist` / `right_wrist`— que copian la rotación del antebrazo, se paran en su punta y **rechazan
## su escala**. Es exactamente lo que hace `Inherit Scale = None` en el `wrist.L/R` de Blender, y vive
## acá porque es una decisión de dibujo: el rig lógico no sabe que existen.

## Los huesos del rig que el esqueleto de dibujo espeja, EN ORDEN PADRE→HIJO. El orden importa: un hueso
## se agrega después de su padre. La cadera (`left_hip`/`right_hip`) está porque el rig la anima y las
## piernas cuelgan de ella, aunque ninguna parte le pese.
const FIELDS: Array[String] = [
	"lower_spine", "higher_spine", "chest", "neck", "head",
	"left_shoulder", "left_upper_arm", "left_lower_arm",
	"right_shoulder", "right_upper_arm", "right_lower_arm",
	"left_hip", "left_higher_leg", "left_lower_leg", "left_foot",
	"right_hip", "right_higher_leg", "right_lower_leg", "right_foot",
]

## PRIMERA PERSONA: lo único que el jugador ve de su propio cuerpo. Brazos (con la mano) y pies, como en
## la build vieja — mirar para abajo y verse los pies es de lo poco que ancla el cuerpo en primera
## persona.
const FIRST_PERSON_VISIBLE: Array[String] = ["left_arm", "right_arm", "left_hand", "right_hand", "left_fingers",
	"right_fingers", "left_foot", "right_foot"]

## Cuánto se mete el brazo adentro del torso, en metros (lo lee SkeletonSizesUtil para el hundimiento del hombro).
const ARM_INSET := 0.06

## CUANTO BAJA LA PELVIS por debajo del ultimo anillo del tronco, en fraccion del medio-ancho de la cadera.
## Es la altura del filete: lo que la banda tiene para correrse de costado y llegar tangente al muslo. Corto
## la curva se empina y vuelve a leerse como un canto; largo, la cadera se estira.
const PELVIS_DROP := 0.45

## DONDE CUELGA UNA PIERNA, en fraccion del medio-ancho de la cadera, y CUANTO DE LA CADERA OCUPA — de aca
## sale el hueco entre las piernas, que es lo que queda. Con 0,55 y 0,35 el hueco da `2 x (0,55 - 0,35)`, o
## sea el 40% del ancho de la cadera repartido al medio y a los costados.
##
## ⚠ ESTO DECIDE EL GROSOR DEL ARRANQUE DE LAS PIERNAS, que no es un parametro del arquetipo: una pierna
## arranca con lo que LA CADERA LE PERMITE. Pierna gruesa = cadera ancha, y la cadera se arrastra en F1.
const LEG_STANCE_SHARE := 0.55
const LEG_DEPTH_SHARE := 0.80

## LO MÁS ANGOSTO QUE PUEDE QUEDAR LA ENTREPIERNA, en metros, y es un número MEDIDO: una entrepierna más
## angosta que esto se rasga al caminar. Medido en la fila de caderas del sandbox (ver
## docs/technical/hip-topology.md), con 3 cm la peor cara de la entrepierna se plegó al 32% de su área y dos
## se dieron vuelta —o sea dos agujeros—; con 5 cm queda en 42% y ninguna, y de ahí para arriba no mejora.
const CROTCH_GAP_MIN := 0.05

## Las llaves con las que una malla lleva sus datos de herramienta (ver GridPart.keep_tool_data).
const GRID_EDGES_META := "grid_edges"


## Las aristas de quads de otra superficie que la primera (las orejas, en la malla de la cabeza): `grid_edges_1`…
static func surface_edges_meta(surface: int) -> String:
	return GRID_EDGES_META if surface == 0 else "%s_%d" % [GRID_EDGES_META, surface]


const VERTEX_RING_META := "vertex_ring"
const VERTEX_COLUMN_META := "vertex_column"
## Y CUALES ESTAN AHI PARA DEFORMAR: los anillos del racimo de una articulacion (ver
## GridPart.limb_column). El panel los pinta de otro color, asi se ve de un vistazo que parte de la
## malla es para doblar y que parte para dar forma.
const JOINT_RINGS_META := "joint_rings"
## Y QUÉ TRIÁNGULOS SON EL PUENTE ENTRE LAS DOS PIERNAS: la entrepierna y las dos caras con las que la banda
## de la pelvis cruza de un muslo al otro (ver GridPart.bridge_triangles). El panel los pinta de otro color
## porque son la parte de la unión que no es simétrica a nada y la que hay que mirar aparte.
const BRIDGE_FACES_META := "bridge_faces"

var skeleton: Skeleton3D

## Paralelos, indexados por hueso del Skeleton3D.
var _bone: Array[CustomBone] = []
var _parent: PackedInt32Array = PackedInt32Array()
var _rest_len: PackedFloat32Array = PackedFloat32Array()
## Para un hueso de anclaje, de qué hueso copia la rotación. −1 en los huesos de verdad.
var _attach_source: PackedInt32Array = PackedInt32Array()
## Scratch del sync: el global sin escala y el global con la escala de estiramiento.
var _unscaled: Array[Transform3D] = []
var _global: Array[Transform3D] = []

var _rest_global: Array[Transform3D] = []
var _index_of: Dictionary = {}
var _first_person: PackedByteArray = PackedByteArray()

## LA PIEL DE ESTE PERSONAJE (ver CharacterLook.skin), o el crema de siempre, y la del cuello (ver TorsoShape.neck_tone).
var _skin_color := CharacterBodyVisual.BODY_COLOR
var _neck_color := CharacterBodyVisual.BODY_COLOR


## `_arch` ya no se usa: lo autoral de la forma está en la forma de bloques (ver BlockShape).
static func create(bones: CustomBonesUtil, sizes: SkeletonSizesUtil, _arch: EntityArchetype,
		parent: Node3D) -> ProceduralBodyUtil:
	var util := ProceduralBodyUtil.new()
	util.name = "ProcBody"
	parent.add_child(util)
	util._build(bones, sizes)
	return util


func _build(bones: CustomBonesUtil, sizes: SkeletonSizesUtil) -> void:
	_head_drop = sizes.head_drop
	_skin_color = sizes.skin if sizes.skin.a > 0.0 else CharacterBodyVisual.BODY_COLOR
	_neck_color = _skin_color
	skeleton = Skeleton3D.new()
	skeleton.name = "DrawSkeleton"
	add_child(skeleton)

	_mirror_bones(bones)
	_add_attachment("left_wrist", "left_lower_arm")
	_add_attachment("right_wrist", "right_lower_arm")
	# LOS HUESOS DE LOS DEDOS (ver `_add_tube_hand_bones`): antes de la piel, que los lleva.
	_tube_rigs = {}
	for side in ["left", "right"]:
		_add_tube_hand_bones(sizes, side)
	_resize_scratch()

	var skin := skeleton.create_skin_from_rest_transforms()
	# LAS PIEZAS: cajas y cápsulas (ver BlockBody).
	BlockBody.build(self, sizes, skin)
	# Las manos arrancan en su pose de reposo (ver `rest_pose`), sin esperar a que el brazo las mueva.
	for side in ["left", "right"]:
		pose_hand(side, Interactable.Grip.NONE, 0.0)

## Agrega al esqueleto de dibujo un hueso por cada CustomBone que exista, con el MISMO padre y el MISMO
## transform local de reposo. Que los dos árboles coincidan es lo que hace que el sync sea copiar
## transforms y no resolver nada.
##
## El padre se saca del árbol de nodos y no de una tabla: el cuello es opcional (hay arquetipos sin), y
## con una tabla habría que escribir las dos variantes.
func _mirror_bones(bones: CustomBonesUtil) -> void:
	var field_of: Dictionary = {}
	var present: Array[String] = []
	for field in FIELDS:
		var cb: CustomBone = bones.get(field)
		if not is_instance_valid(cb):
			continue
		present.append(field)
		field_of[cb] = field

	for field in present:
		var cb: CustomBone = bones.get(field)
		var idx := skeleton.get_bone_count()
		skeleton.add_bone(field)
		_index_of[field] = idx
		_bone.append(cb)
		_attach_source.append(-1)
		_rest_len.append(cb.rest_length)

		var parent_idx := -1
		var parent_cb := cb.get_parent() as CustomBone
		if parent_cb != null and field_of.has(parent_cb):
			parent_idx = int(_index_of[String(field_of[parent_cb])])
		_parent.append(parent_idx)
		if parent_idx >= 0:
			skeleton.set_bone_parent(idx, parent_idx)
		# EL REPOSO, NO LA POSE VIVA: la malla se cuece una vez y no puede salir distinta según qué
		# estaba haciendo el personaje en ese momento. Ver CustomBone.rest_transform.
		skeleton.set_bone_rest(idx, cb.rest_transform)
		var rest := cb.rest_transform
		_rest_global.append(rest if parent_idx < 0 else _rest_global[parent_idx] * rest)


## Un hueso que el rig no tiene: cuelga de `source_field`, nace en su punta y copia su rotación sin su
## escala. Ver el encabezado — es la muñeca.
func _add_attachment(field: String, source_field: String) -> void:
	if not _index_of.has(source_field):
		return
	var src: int = int(_index_of[source_field])
	var src_bone: CustomBone = _bone[src]
	if not is_instance_valid(src_bone):
		return

	var idx := skeleton.get_bone_count()
	skeleton.add_bone(field)
	skeleton.set_bone_parent(idx, src)
	var rest := Transform3D(Basis(), Vector3(0.0, src_bone.rest_length, 0.0))
	skeleton.set_bone_rest(idx, rest)

	_index_of[field] = idx
	_bone.append(null)
	_attach_source.append(src)
	_parent.append(src)
	_rest_len.append(0.0)
	_rest_global.append(_rest_global[src] * rest)


func _resize_scratch() -> void:
	_unscaled.resize(_parent.size())
	_global.resize(_parent.size())


## LA CUELGA DEL ESQUELETO, con su material: el color de `piece_colors` si lo trae, si no el de la piel (el cuello, el
## del cuello).
func _hang(part_name: String, mesh: ArrayMesh, skin: Skin) -> void:
	var mi := MeshInstance3D.new()
	mi.name = part_name
	mi.mesh = mesh
	mi.skin = skin
	if piece_colors.has(part_name):
		mi.material_override = CharacterBodyVisual.body_material(piece_colors[part_name])
	else:
		mi.material_override = CharacterBodyVisual.body_material(_neck_color if part_name == "neck" else _skin_color)
	skeleton.add_child(mi)
	meshes.append(mi)
	_first_person.append(1 if FIRST_PERSON_VISIBLE.has(part_name) else 0)


## PARA MIRAR LAS PIEZAS: nombre de parte → color plano que la pinta entera, en vez del suyo (ver la receta
## «piezas_cuerpo»). Vacío, nada cambia.
static var piece_colors: Dictionary = {}


## EL TAMAÑO DEL ARRANQUE DE UNA PIERNA: medio-ancho y medio-fondo de su huella, en metros. Sale de la
## vuelta de abajo del torso —o sea es LO QUE LA CADERA LE PERMITE— y es CUADRADO: los dos valores son el
## mismo número.
##
## ── POR QUÉ CUADRADO, Y POR QUÉ NO ES UN PARÁMETRO ───────────────────────────────
## La pierna NO AUTORA SU ARRANQUE. Su grosor inicial sale del ancho y el fondo de la cadera, y mantiene
## aspecto cuadrado — que con redondez es un círculo y sin ella un cuadrado, pero nunca una elipse. Tres
## razones, y la tercera es la que importa:
##
##   · el panel de creación de personajes tiene una perilla menos;
##   · es a prueba de tontos: no hay manera de dejar un escalón entre la cadera y la pierna, porque la
##     pierna no puede discrepar de la cadera;
##   · y hace IMPOSIBLES las formas que nadie quiere en vez de evitables. Con el ancho y el fondo saliendo
##     del MISMO número no hay valor que pueda producir una pierna elíptica ni una pierna en D.
##
## ── LA CUENTA: LO MÁS GORDO QUE ENTRA, Y NADA MÁS ────────────────────────────────
## Dos cotas, y gana la menor:
##
##   · EL FONDO deja `LEG_DEPTH_SHARE` del de la cadera. La pierna queda METIDA del frente y de la espalda,
##     y eso no deja repisa porque el filete de la pelvis entra en ella con una curva (ver
##     `GridPart.pelvis_fill`); es lo que la distingue de un fondo plano con un agujero, donde el mismo
##     recorte se ve como un escalón.
##   · EL ANCHO lo acotan las dos cosas entre las que la pierna vive: el costado de la cadera —cuelga a
##     `LEG_STANCE_SHARE` del medio-ancho, así que no puede pasarse— y el hueco de la entrepierna, que no
##     baja de `CROTCH_GAP_MIN`.
##
## Medido en el genérico (cadera de abajo de 26 × 20,6 cm): el fondo daría para 16,5 de lado y el ancho para
## 9,3, así que la sección sale de 9,3 × 9,3. Para que el fondo sea el que manda hace falta una cadera de
## unos 45 cm de ancho: con una cadera humana la pierna es tan gorda como el hueco la deja, y es correcto que
## sea así — es una relación entre dos números que se arrastran en el panel, y el panel la dice.
##
## ⚠ ANTES EL ANCHO ERA UN SHARE SUYO (`LEG_WIDTH_SHARE`, 0,35 del de la cadera) y por eso el arranque salía
## elíptico: 9,1 × 16,5 en el genérico. Que el número viejo diera casi lo mismo que la cota de ahora (9,1
## contra 9,3) no es casualidad — estaba afinado contra ella a mano. Lo que cambia es que ahora es la REGLA
## y no el número afinado, y que el fondo la sigue.
static func leg_start_half(bottom_width: float, depth: float) -> Vector2:
	var half_width: float = bottom_width * 0.5
	var stance: float = half_width * LEG_STANCE_SHARE
	var by_depth: float = depth * 0.5 * LEG_DEPTH_SHARE
	var by_width: float = minf(half_width - stance, stance - CROTCH_GAP_MIN * 0.5)
	var side: float = maxf(minf(by_depth, by_width), 0.01)
	return Vector2(side, side)


## ── LOS HUESOS DE LA MANO DE TUBOS (29/10/2026, ver TubeHand.bones) ──────────────────────────────────────────────────
## Un hueso por falange, colgados de la muñeca. El marco de cada uno es el de TubeHand llevado por el de la mano
## (`_tube_hand_frame`); en la mano espejada se le da vuelta su X, así sigue siendo un giro (un hueso no puede espejar)
## y su +Z, el eje que cierra el dedo, queda igual —pero cierra al revés: `sign`—. En reposo, la mano recta.
## Lado → {"keys" (los de TubeHand.bones), "idx" (sus huesos, en ese orden), "locals" (su reposo, del padre), "sign",
## "fist", "tip", "hole" y "palm" (los nudillos del puño, la punta del índice, el hueco del puño y el medio de la palma,
## en el marco de la muñeca), "across" (la línea de los nudillos, en ese marco), "closed" (el peso y la pose puestos)}.
var _tube_rigs := {}


func _add_tube_hand_bones(sizes: SkeletonSizesUtil, side: String) -> void:
	var wrist_field := "%s_wrist" % side
	if not _index_of.has(wrist_field) or _chain(["%s_upper_arm" % side, "%s_lower_arm" % side]).is_empty():
		return
	var hand := _tube_hand_frame(side)
	var flip := Basis.from_scale(Vector3(-1.0, 1.0, 1.0)) if hand.basis.determinant() < 0.0 else Basis.IDENTITY
	var keys := PackedStringArray()
	var idx := PackedInt32Array()
	var by_key := {}
	# LA MUÑECA: la de la forma de bloques (el ancho del brazo, ver BlockShape.apply_to).
	var width := sizes.hand_width
	for each: Dictionary in TubeHand.bones(TubeHand.current(), width):
		var frame: Transform3D = each["frame"]
		var placed := Transform3D(hand.basis * frame.basis * flip, hand * frame.origin)
		var parent: int = int(_index_of[wrist_field]) if each["parent"] == "" else int(by_key[each["parent"]])
		var local: Transform3D = (_rest_global[parent] as Transform3D).affine_inverse() * placed
		var bone := skeleton.get_bone_count()
		var bone_name := "%s_tube_%s" % [side, each["key"]]
		skeleton.add_bone(bone_name)
		skeleton.set_bone_parent(bone, parent)
		skeleton.set_bone_rest(bone, local)
		skeleton.set_bone_pose(bone, local)
		_index_of[bone_name] = bone
		_bone.append(null)
		_attach_source.append(-1)
		_parent.append(parent)
		_rest_len.append(0.0)
		_rest_global.append(placed)
		by_key[each["key"]] = bone
		keys.append(each["key"])
		idx.append(bone)
	# LOS PUNTOS CON QUE TOCA, en el marco de la muñeca (ver `hand_point`).
	var to_wrist := (_rest_global[int(_index_of[wrist_field])] as Transform3D).affine_inverse() * hand
	var locals: Array[Transform3D] = []
	for bone in idx:
		locals.append(skeleton.get_bone_rest(bone))
	_tube_rigs[side] = {"keys": keys, "idx": idx, "locals": locals, "sign": -1.0 if flip != Basis.IDENTITY else 1.0,
		"fist": to_wrist * TubeHand.knuckles(TubeHand.current(), width),
		"tip": to_wrist * TubeHand.index_tip(TubeHand.current(), width),
		"hole": to_wrist * TubeHand.fist_hole(TubeHand.current(), width),
		"across": (to_wrist.basis * Vector3.BACK).normalized(),
		"palm_dir": (to_wrist.basis * Vector3.RIGHT).normalized(),
		"palm": to_wrist * TubeHand.palm_centre(TubeHand.current(), width), "closed": ""}


## EL PUNTO CON QUE TOCA LA MANO, en el marco de la muñeca (que copia al antebrazo), según cómo se toma (`grip`, un
## Interactable.Grip): apretando, los nudillos del puño o la punta del índice (ver TubeHand.press_with); empuñando, el
## hueco del puño; si no, el medio de la palma. Sale de la mano de verdad —sus largos—, así que vale para cualquier mano o
## muñeca (ver ArmsController._reach_arm). Sin mano, la muñeca misma.
func hand_point(side: String, grip: int) -> Vector3:
	var rig: Dictionary = _tube_rigs.get(side, {})
	if rig.is_empty():
		return Vector3.ZERO
	match grip:
		Interactable.Grip.PRESS:
			return rig["fist"] if TubeHand.press_with == TubeHand.Press.FIST else rig["tip"]
		Interactable.Grip.WRAP:
			return rig["hole"]
	return rig["palm"]


## HACIA DÓNDE MIRA LA PALMA, en el marco de la muñeca: al empuñar un aro, hacia su centro (ver ArmsController).
func hand_palm(side: String) -> Vector3:
	var rig: Dictionary = _tube_rigs.get(side, {})
	return rig["palm_dir"] if not rig.is_empty() else Vector3.RIGHT


## LA LÍNEA DE LOS NUDILLOS de la mano, en el marco de la muñeca: lo que al empuñar va a lo largo del aro.
func hand_across(side: String) -> Vector3:
	var rig: Dictionary = _tube_rigs.get(side, {})
	return rig["across"] if not rig.is_empty() else Vector3.BACK


## ── EL GIRO DE LA MUÑECA SOBRE EL ANTEBRAZO (29/10/2026) ──────────────────────────────────────────────────────────
## La mano sigue alineada con el antebrazo; lo único que puede es girar sobre él (como al girar la muñeca): empuñando,
## para que los nudillos sigan el aro (ver ArmsController._reach_arm). En radianes, sobre el eje del antebrazo.
var _wrist_roll := {}


func set_wrist_roll(side: String, angle: float) -> void:
	_wrist_roll[side] = angle


## De qué brazo es el hueso `index`, si es una muñeca; si no, "".
func _wrist_side(index: int) -> String:
	if index == int(_index_of.get("left_wrist", -1)):
		return "left"
	if index == int(_index_of.get("right_wrist", -1)):
		return "right"
	return ""


## LA POSE DE LA MANO según cómo se toma (`grip`, un Interactable.Grip): apretando, el puño o el índice (ver
## TubeHand.press_with); empuñando, el puño; si no, la de reposo (`rest_pose`). Con `weight` de 0 —la de reposo— a 1.
## La pone ArmsController con el peso del brazo, así la mano se cierra mientras va y se abre al soltar.
func pose_hand(side: String, grip: int, weight: float) -> void:
	var rig: Dictionary = _tube_rigs.get(side, {})
	var pose: Dictionary = {}
	var rest := rest_pose()
	match grip:
		Interactable.Grip.PRESS:
			pose = TubeHand.press_pose()
		Interactable.Grip.WRAP:
			pose = TubeHand.FIST
		_:
			pose = rest
			weight = 0.0
	var state := "%d|%d|%.4f" % [grip, TubeHand.press_with, weight]
	if rig.is_empty() or not is_instance_valid(skeleton) or rig["closed"] == state:
		return
	rig["closed"] = state
	var keys: PackedStringArray = rig["keys"]
	var idx: PackedInt32Array = rig["idx"]
	var locals: Array[Transform3D] = rig["locals"]
	var turn: float = rig["sign"]
	for k in keys.size():
		var key := keys[k]
		var digit := key.substr(0, key.rfind("_"))
		var phalanx := int(key.substr(key.rfind("_") + 1)) - 1
		var angle := lerpf(_pose_angle(rest, digit, phalanx), _pose_angle(pose, digit, phalanx), weight)
		skeleton.set_bone_pose(idx[k], locals[k] * Transform3D(Basis(Vector3.BACK, angle * turn), Vector3.ZERO))


## LA MANO EN REPOSO (01/11/2026, el dios del juego: «una pose muy básica para las manos en reposo… pondría la misma pose
## del puño que… se hace cuando estás agarrando un volante»): el puño.
static func rest_pose() -> Dictionary:
	return TubeHand.FIST


## Cuánto gira la falange `phalanx` (desde 0, la de la base) del dedo `digit` en `pose`, en radianes; 0 si no la nombra.
static func _pose_angle(pose: Dictionary, digit: String, phalanx: int) -> float:
	var angles: Array = pose.get(digit, [])
	return deg_to_rad(float(angles[phalanx])) if phalanx < angles.size() else 0.0


## EL MARCO DE LA MANO DE TUBOS en el cuerpo, en reposo: en el medio de la muñeca, donde termina el antebrazo.
func _tube_hand_frame(side: String) -> Transform3D:
	var chain := _chain(["%s_upper_arm" % side, "%s_lower_arm" % side])
	var lengths: PackedFloat32Array = chain[1]
	var forearm: Transform3D = (chain[2] as Array)[(chain[2] as Array).size() - 1]
	return _stylized_frame(side, forearm * Vector3(0.0, lengths[lengths.size() - 1], 0.0))


## EL MARCO DE LA MANO (ver TubeHand): en `centre`, el medio de la muñeca, con −Y a lo largo del antebrazo, hacia los
## dedos; +X hacia el cuerpo, del lado de la palma; −Z hacia adelante, el frente del cuerpo. En una de las dos manos
## queda espejado, y así el pulgar va adelante en las dos.
func _stylized_frame(side: String, centre: Vector3) -> Transform3D:
	var chain := _chain(["%s_upper_arm" % side, "%s_lower_arm" % side])
	var forearm: Transform3D = (chain[2] as Array)[(chain[2] as Array).size() - 1]
	var y := -forearm.basis.y.normalized()
	var z := Vector3.BACK - y * y.z
	z = z.normalized()
	var x := y.cross(z)
	if x.dot(Vector3(-signf(centre.x), 0.0, 0.0)) < 0.0:
		x = -x
	return Transform3D(Basis(x, y, z), centre)


# ── Utilidades de cadena ─────────────────────────────────────────────────────────────────────────

## Una cadena como `[ids, largos, reposos]`, o vacía si le falta un hueso (el cuello es opcional). Los
## reposos son los GLOBALES de reposo en el espacio del esqueleto, que es lo que `GridPart` necesita
## y lo que el `Skin` invierte.
func _chain(fields: Array) -> Array:
	var ids := PackedInt32Array()
	var lengths := PackedFloat32Array()
	var rests: Array[Transform3D] = []
	for f in fields:
		var field := String(f)
		if not _index_of.has(field):
			return []
		var idx: int = int(_index_of[field])
		var cb: CustomBone = _bone[idx]
		if not is_instance_valid(cb):
			return []
		ids.append(idx)
		lengths.append(cb.length)
		# LA CABEZA CUELGA DE SU ATLAS (ver HeadForm.atlas): todo lo que se arma en su marco —la cabeza, las orejas, la
		# cara, el pelo, lo que lleva puesto— baja lo que el cuello se alargó.
		var rest: Transform3D = _rest_global[idx]
		if field == "head" and _head_drop > 0.0:
			rest = rest * Transform3D(Basis(), Vector3(0.0, -_head_drop, 0.0))
		rests.append(rest)
	return [ids, lengths, rests]


## Lo que baja la cabeza en su marco por el atlas de su forma (ver `_chain`, SkeletonSizesUtil.head_drop).
var _head_drop := 0.0


# ── Sincronización ───────────────────────────────────────────────────────────────────────────────

func sync_from_bones() -> void:
	_sync({})


func sync_from_ragdoll(bodies: Dictionary) -> void:
	_sync(bodies)


## Copia el pose del rig al esqueleto de dibujo. Un camino solo para los tres casos —hueso normal, hueso
## de anclaje, y hueso leído del cuerpo del ragdoll— porque los tres terminan en lo mismo: un GLOBAL
## deseado, que se baja a local contra el global ya calculado del padre.
##
## LA ESCALA DE ESTIRAMIENTO va en el pose y no en la geometría: un hueso cuyo `length` cambió respecto
## del reposo se escala a lo largo de sí mismo, que es lo único que estira la malla de verdad. Mover
## nada más el hueso hijo trasladaría los vértices que le pesan a ÉL y dejaría quieto el tramo del medio
## — se vería como una junta que se abre, no como un brazo largo.
func _sync(bodies: Dictionary) -> void:
	if _hidden or not is_instance_valid(skeleton):
		return
	var inv := skeleton.global_transform.affine_inverse()
	for i in _parent.size():
		var unscaled := Transform3D()
		var scale_y := 1.0
		var source: int = _attach_source[i]
		if source >= 0:
			# Hueso de anclaje: la rotación de su fuente, parado en su punta, SIN su escala. La muñeca copia al antebrazo:
			# la mano va derecha, alineada con él, girada sólo sobre su eje si quien agarra lo pide (ver `set_wrist_roll`).
			var from := _unscaled[source]
			var roll: float = _wrist_roll.get(_wrist_side(i), 0.0)
			var basis := from.basis * Basis(Vector3.UP, roll) if roll != 0.0 else from.basis
			unscaled = Transform3D(basis, from * Vector3(0.0, _current_length(source), 0.0))
		else:
			var cb: CustomBone = _bone[i]
			if not is_instance_valid(cb):
				continue
			var node: Node3D = cb
			if not bodies.is_empty():
				var rb: Node3D = bodies.get(cb)
				if is_instance_valid(rb):
					node = rb
			var g := inv * node.global_transform
			unscaled = Transform3D(g.basis.orthonormalized(), g.origin)
			if _rest_len[i] > 1e-5:
				scale_y = cb.length / _rest_len[i]

		_unscaled[i] = unscaled
		var scaled := Transform3D(unscaled.basis.scaled_local(Vector3(1.0, scale_y, 1.0)), unscaled.origin)
		_global[i] = scaled
		var parent: int = _parent[i]
		skeleton.set_bone_pose(i, scaled if parent < 0 else _global[parent].affine_inverse() * scaled)


func _current_length(index: int) -> float:
	var cb: CustomBone = _bone[index]
	return cb.length if is_instance_valid(cb) else _rest_len[index]


# ── Visibilidad ──────────────────────────────────────────────────────────────────────────────────

func set_first_person(first_person: bool) -> void:
	_in_first_person = first_person
	if _hidden:
		return
	for i in meshes.size():
		if is_instance_valid(meshes[i]):
			meshes[i].visible = (not first_person) or _first_person[i] == 1


func set_meshes_visible(value: bool) -> void:
	_hidden = not value
	if _hidden:
		for m in meshes:
			if is_instance_valid(m):
				m.visible = false
		return
	set_first_person(_in_first_person)
