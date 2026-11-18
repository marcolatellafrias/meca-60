class_name MechSkeleton
extends Node3D

## ── EL ESQUELETO DE LA MECA (18/11/2026; módulo Jefes, el sistema común) ───────────────────────────────────────────
## El usuario: «la meca debería tener un sistema de huesos similar a las de un humano… todos los huesos deberían estar
## conectados». Huesos de verdad (CustomBone, los de los personajes: un Node3D con largo, que apunta por su +Y), en un
## árbol, y LAS PIEZAS DE ARCILLA CUELGAN DE SUS HUESOS. Lo común se apoya acá: la IK, la tabla de animación, el ragdoll.
##
## EL ÁRBOL (en el mundo, `top_level`):
##   cintura (la raíz, `waist`: donde se apoya el torso)
##   ├─ pelvis ── cadera izquierda / derecha (PUNTOS FIJOS) ── muslo ── canilla ── pie
##   └─ torso (la caja) ── hombro izquierdo / derecho (PUNTOS FIJOS) ── brazo ── antebrazo
## LA PELVIS ES RÍGIDA (el usuario: «los dos huesos de la pelvis… nunca pueden quebrarse… se calculan a partir de dónde
## están las piernas»): UN SOLO HUESO que se mueve; las dos caderas son puntos colgados de él a una distancia fija, que
## nada escribe (no son huesos: no se les puede dar una pose). Lo mismo los hombros, del torso. El ragdoll toma la pelvis
## con sus caderas como un solo cuerpo.
##
## QUIÉN MUEVE QUÉ: las piernas (BodyLegs, MechLeg), los brazos (MechArm) y el cuerpo (el torso, la caja) escriben sus
## huesos; las piezas los siguen. *Paso 1 (18/11/2026): la pose la sigue calculando el código de siempre y se escribe en
## los huesos (`put`); después, una sola IK sobre los huesos.*

## Las piezas de arcilla van a lo largo de −Z (Clay.limb, MechBody.segment); los huesos, a lo largo de +Y. Lo que lleva
## una pieza al hueso: un cuarto de vuelta sobre X (−Z → +Y).
const ALONG := Basis(Vector3.RIGHT, PI * 0.5)

var waist: Node3D = null
var pelvis: CustomBone = null
var torso: CustomBone = null
## Por lado (0 izquierdo, 1 derecho).
var hips: Array[Node3D] = []
var thighs: Array[CustomBone] = []
var shins: Array[CustomBone] = []
var feet: Array[CustomBone] = []
var shoulders: Array[Node3D] = []
var uppers: Array[CustomBone] = []
var forearms: Array[CustomBone] = []


## La pelvis y los huesos de las piernas y los brazos, en reposo: para abajo (medio giro sobre X).
const DOWN := Vector3(PI, 0.0, 0.0)


## LA PELVIS en el mundo: su centro y los ejes de la cintura `waist_basis` (la pieza de BodyLegs, MechBody.pelvis),
## apuntando para abajo.
func put_pelvis(center: Transform3D) -> void:
	pelvis.global_transform = Transform3D(center.basis.orthonormalized() * Basis.from_euler(DOWN), center.origin)


## LO ARMA con las medidas `measures` y la caja `size` (m): los huesos en su reposo (parada: las piernas y los brazos
## para abajo), y `shoulder` el hombro derecho en el espacio de la caja (el izquierdo, espejado).
func build(measures: MechBody, size: Vector3, shoulder: Vector3) -> void:
	name = "Esqueleto"
	top_level = true
	waist = Node3D.new()
	waist.name = "Cintura"
	add_child(waist)
	var down := DOWN
	var up := Vector3.ZERO
	pelvis = CustomBone.create(Vector3(measures.PELVIS_SIZE.x, measures.PELVIS_SIZE.y, measures.PELVIS_SIZE.z), down)
	pelvis.name = "Pelvis"
	waist.add_child(pelvis)
	torso = CustomBone.create(Vector3(size.x, size.y, size.z), up)
	torso.name = "Torso"
	waist.add_child(torso)
	for index in 2:
		var side := -1.0 if index == 0 else 1.0
		var hip := Node3D.new()
		hip.name = "Cadera" + ("I" if index == 0 else "D")
		# La pelvis (su origen, su centro) apunta para abajo (su +Y, medio giro sobre X: la y y la z al revés): la cadera,
		# al costado y la caída de la cadera por debajo de la cintura (la cintura está media pelvis arriba del centro).
		hip.position = Vector3(side * measures.HIP_X, measures.HIP_DROP - measures.PELVIS_SIZE.y * 0.5, 0.0)
		pelvis.add_child(hip)
		hips.append(hip)
		var thigh := _bone("Muslo", measures.THIGH, measures.LEG_THICKNESS, down, hip)
		var shin := CustomBone.create(Vector3(measures.LEG_THICKNESS, measures.SHIN, measures.LEG_THICKNESS), down, thigh)
		shin.name = "Canilla"
		var foot := CustomBone.create(measures.FOOT_SIZE, down, shin)
		foot.name = "Pie"
		thighs.append(thigh)
		shins.append(shin)
		feet.append(foot)
		var shoulder_point := Node3D.new()
		shoulder_point.name = "Hombro" + ("I" if index == 0 else "D")
		shoulder_point.position = Vector3(side * shoulder.x, shoulder.y + size.y * 0.5, shoulder.z)
		torso.add_child(shoulder_point)
		shoulders.append(shoulder_point)
		var upper := _bone("Brazo", measures.UPPER_ARM, measures.LEG_THICKNESS, down, shoulder_point)
		var forearm := CustomBone.create(Vector3(measures.LEG_THICKNESS, measures.FOREARM, measures.LEG_THICKNESS), down,
			upper)
		forearm.name = "Antebrazo"
		uppers.append(upper)
		forearms.append(forearm)


## Un hueso que cuelga de un punto fijo (no de la punta de otro hueso).
static func _bone(bone_name: String, length: float, thickness: float, rest: Vector3, holder: Node3D) -> CustomBone:
	var bone := CustomBone.new()
	bone.name = bone_name
	bone.capsule_dimensions = Vector3(thickness, length, thickness)
	bone.rest_rotation = rest
	holder.add_child(bone)
	bone.rotation = rest
	bone.rest_transform = bone.transform
	bone.rest_length = length
	return bone


## PONE UN HUESO donde dice una pieza de arcilla ya armada (`piece`: su centro y sus ejes, el largo por −Z, como las da
## MechBody): el hueso nace en la punta de arriba de la pieza y va a lo largo de ella.
static func put(bone: CustomBone, piece: Transform3D) -> void:
	var basis := piece.basis.orthonormalized() * ALONG.inverse()
	bone.global_transform = Transform3D(basis, piece.origin - basis.y * bone.length * 0.5)


## GIRA UN HUESO como una pieza (`piece`, como en `put`) SIN MOVERLO DE DONDE NACE (la punta de su padre, o su punto
## fijo): sólo toma sus ejes. Para lo que sigue a un cuerpo físico (el brazo con músculos), que puede ceder en la unión:
## el hueso no se separa nunca.
static func aim(bone: CustomBone, piece: Transform3D) -> void:
	bone.position = bone.rest_transform.origin
	var parent := bone.get_parent() as Node3D
	var basis := piece.basis.orthonormalized() * ALONG.inverse()
	bone.transform.basis = parent.global_basis.orthonormalized().inverse() * basis if parent != null else basis


## LO QUE COLGABA DE UN CUERPO (`body`, con los ejes de una pieza: el largo por −Z) PASA A SU HUESO, en el mismo lugar
## respecto de él (menos sus formas de choque, que se quedan en el cuerpo).
static func move_drawing(body: Node3D, bone: CustomBone) -> void:
	for child in body.get_children():
		if child is CollisionShape3D or not (child is Node3D):
			continue
		var local := (child as Node3D).transform
		body.remove_child(child)
		bone.add_child(child)
		(child as Node3D).transform = piece_on(bone) * local


## DÓNDE VA UNA PIEZA DE ARCILLA sobre su hueso (lo inverso de `put`): en el medio del hueso, a lo largo.
static func piece_on(bone: CustomBone) -> Transform3D:
	return Transform3D(ALONG, Vector3(0.0, bone.length * 0.5, 0.0))


## CUELGA UNA PIEZA de su hueso, en el lugar de `piece_on` (lo que cuelga de la pieza, con ella).
static func hang(piece: Node3D, bone: CustomBone) -> void:
	if piece.get_parent() != null:
		piece.get_parent().remove_child(piece)
	bone.add_child(piece)
	piece.top_level = false
	piece.transform = piece_on(bone)
