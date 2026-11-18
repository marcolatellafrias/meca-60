class_name BossLegs
extends Node3D

## ── LAS PATAS QUE CAMINAN DE UN JEFE (18/11/2026; módulo Jefes, el sistema común de movimiento) ─────────────────────
## Las piernas «patas» del catálogo (BossParts.LEGS: dos o cuatro) ya no son un dibujo quieto: son PATAS DE VERDAD en EL
## MISMO ESQUELETO QUE LA MECA (MechSkeleton: el tronco con su pelvis, y por pata la cadera, el muslo, la canilla y el
## pie), y caminan con LO COMÚN: LA MARCHA (Gait: dónde va cada pie; cuatro patas pisan las diagonales) y LA IK
## (IkUtil.solve_two_bone_ik: la rodilla). El usuario: «unificar las piernas IK… para 2, 4 o 6 patas».
##   · LO QUE LAS MUEVE es dónde está el cuerpo y a qué velocidad va (`step`): no se sincronizan (ver
##     docs/technical/movimiento-comun.md, «Qué viaja por la red»).
##   · CADA PATA dice de dónde sale (la cadera, en los ejes de la cintura), dónde se para su pie quieta y hacia dónde dobla
##     la rodilla (BossParts.LEGS[…]["walk"]). Las de cuatro, como una araña: la rodilla arriba y afuera.
##   · VAN A LA ESCALA DE LOS JEFES (BossSettings): se arman con las medidas ya escaladas (la IK cuenta con el largo de
##     los huesos, que no puede llevar la escala del nodo), y se rearman si la escala cambia (`build`).
##   · EL PISO: el de debajo del cuerpo (Gait sin `ground`). *Falta: el piso de verdad, cada pie a su altura.*

## Lo que sube el pie del piso al tobillo (m de maqueta) y el tamaño de la pisada.
const ANKLE := 0.6
const PAD := Vector3(4.0, 1.2, 4.0)

var skeleton: MechSkeleton = null
var gait := Gait.new()

var _id := ""
var _size := 1.0
## Por pata: hacia dónde dobla la rodilla (en los ejes del cuerpo) y la pisada (un dibujo suelto, plano en el piso).
var _bends: Array[Vector3] = []
var _pads: Array[Node3D] = []
var _placed := false


## LAS ARMA (o las rearma: otra escala) para las piernas `id` del catálogo, a la escala `size`.
func build(id: String, size: float) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_id = id
	_size = size
	_bends.clear()
	_pads.clear()
	_placed = false
	var spec: Dictionary = BossParts.LEGS[id]["walk"]
	var hip := float(BossParts.LEGS[id]["hip"]) * size
	var thick := float(spec["thick"]) * size
	skeleton = MechSkeleton.new()
	skeleton.build_trunk(Vector3.ONE * thick * 2.0, Vector3.ONE * thick * 2.0, hip)
	add_child(skeleton)
	var rests: Array[Vector3] = []
	var hips: Array = spec["hips"]
	for leg in hips.size():
		# La cadera, de los ejes de la cintura a los de la pelvis (que apunta para abajo).
		var at: Vector3 = skeleton.pelvis.transform.affine_inverse() * ((hips[leg] as Vector3) * size)
		skeleton.add_leg(at, float(spec["thigh"]) * size, float(spec["shin"]) * size, PAD * size, thick)
		_draw(skeleton.thighs[leg], thick * 1.15, BossParts.BODY)
		_draw(skeleton.shins[leg], thick, BossParts.TRIM)
		var pad := Node3D.new()
		pad.top_level = true
		add_child(pad)
		Clay.box(pad, PAD * size, Vector3.UP * PAD.y * size * 0.5, Clay.DARK)
		_pads.append(pad)
		_bends.append(spec["bends"][leg])
		rests.append((spec["feet"][leg] as Vector3) * size)
	gait = Gait.new()
	gait.setup(rests, Gait.pattern(rests.size()))
	gait.stride = float(spec["stride"]) * size
	gait.lift = float(spec["lift"]) * size
	gait.stomp = 0.6


## UN PASO: el cuerpo en el piso en `root` (su giro y el punto debajo de su centro, sin escala) andando a `velocity`.
func step(delta: float, root: Transform3D, velocity: Vector3) -> void:
	skeleton.root.global_transform = root
	if not _placed:
		gait.place(root)
		_placed = true
	gait.update(delta, root, velocity)
	for leg in skeleton.thighs.size():
		var foot: Vector3 = gait.feet[leg]
		var hip := skeleton.thighs[leg].global_position
		IkUtil.solve_two_bone_ik(skeleton.thighs[leg], skeleton.shins[leg], foot + Vector3.UP * ANKLE * _size,
			hip + root.basis * _bends[leg] * 10.0 * _size)
		_pads[leg].global_transform = Transform3D(root.basis, foot)


## Las piernas que arma (las de `id`, a `size`).
func built(id: String, size: float) -> bool:
	return id == _id and is_equal_approx(size, _size) and skeleton != null


## Un pedazo de pata a lo largo de su hueso (+Y), del grueso `thick`.
static func _draw(bone: CustomBone, thick: float, color: Color) -> void:
	var length := bone.capsule_dimensions.y
	Clay.box(bone, Vector3(thick, length, thick), Vector3.UP * length * 0.5, color)
