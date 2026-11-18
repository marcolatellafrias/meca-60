class_name MechLeg
extends Node3D

## UNA PIERNA DE LA MECA, sólo dibujo: muslo y canilla cilíndricos, de pocas caras (ver Clay.limb), y el pie, donde dice
## el cuerpo (MechBody.leg), y sus ARTICULACIONES: la cadera, un disco del grosor de la pierna con el eje de costado; la
## rodilla y el tobillo, esferas (el usuario, 12/11/2026: «las articulaciones de las rodillas y pies esféricas también»). En el mundo (`top_level`): la
## postura ya viene en el mundo. Los largos son los del cuerpo y no se estiran: la rodilla sale de ellos.
## La usan la meca de pelea y los cubos con piernas.

var _thigh: MeshInstance3D = null
var _shin: MeshInstance3D = null
var _foot: MeshInstance3D = null
var _hip: MeshInstance3D = null
var _knee: MeshInstance3D = null
var _ankle: MeshInstance3D = null
## Las medidas del cuerpo que la lleva (ver BalanceBody.measures). Se ponen antes de agregarla.
var measures := MechBody.new()
## SUS HUESOS (MechSkeleton: el muslo, la canilla y el pie; 18/11/2026): sus piezas cuelgan de ellos y `pose` escribe
## los huesos. Se ponen antes de agregarla. Sin ellos (una maqueta suelta), las piezas van solas, como antes.
var thigh_bone: CustomBone = null
var shin_bone: CustomBone = null
var foot_bone: CustomBone = null


func _init() -> void:
	top_level = true


func _ready() -> void:
	var thickness := measures.LEG_THICKNESS
	_thigh = Clay.limb(self, thickness * 0.5, measures.THIGH, Vector3.ZERO, Clay.METAL.darkened(0.1))
	_shin = Clay.limb(self, thickness * 0.5, measures.SHIN, Vector3.ZERO, Clay.METAL.darkened(0.2))
	_foot = Clay.box(self, measures.FOOT_SIZE, Vector3.ZERO, MechBody.JOINT_COLOR)
	# El disco de la cadera, apenas más ancho que la pierna para que no se pisen las caras; la rodilla y el tobillo,
	# esferas que asoman de la pierna.
	_hip = Clay.cylinder(self, measures.JOINT_RADIUS * 1.15, thickness * 1.04, Vector3.ZERO, MechBody.JOINT_COLOR)
	_knee = Clay.sphere(self, measures.JOINT_RADIUS, Vector3.ZERO, MechBody.JOINT_COLOR)
	_ankle = Clay.sphere(self, measures.JOINT_RADIUS * MechBody.ANKLE_SHARE, Vector3.ZERO, MechBody.JOINT_COLOR)
	if thigh_bone != null:
		_hang()


## LAS PIEZAS, EN SUS HUESOS: el muslo con la cadera (arriba) y la rodilla (abajo), la canilla con el tobillo (abajo) y
## el pie. Las articulaciones van donde las ponía `pose`, que ya no las mueve: en las puntas de las piezas.
func _hang() -> void:
	var sideways := Basis(Vector3.BACK, PI * 0.5)
	MechSkeleton.hang(_thigh, thigh_bone)
	MechSkeleton.hang(_shin, shin_bone)
	_joint(_hip, _thigh, Transform3D(sideways, Vector3(0.0, 0.0, measures.THIGH * 0.5)))
	_joint(_knee, _thigh, Transform3D(sideways, Vector3(0.0, 0.0, -measures.THIGH * 0.5)))
	_joint(_ankle, _shin, Transform3D(sideways, Vector3(0.0, 0.0, -measures.SHIN * 0.5)))
	remove_child(_foot)
	foot_bone.add_child(_foot)
	_foot.transform = Transform3D(Basis(), _foot_from_ankle())


## Una articulación, colgada de la pieza `piece` en `local` (su espacio).
func _joint(part: Node3D, piece: Node3D, local: Transform3D) -> void:
	remove_child(part)
	piece.add_child(part)
	part.transform = local


## Del tobillo al centro del pie, en los ejes del pie (ver MechBody.leg: el pie va plano, adelantado, sobre el piso).
func _foot_from_ankle() -> Vector3:
	return Vector3(0.0, measures.FOOT_SIZE.y * 0.5 - measures.ANKLE, -measures.FOOT_AHEAD)

## La pone como dice `leg` (ver MechBody.leg): las partes, y las articulaciones en sus puntas (el muslo va de la cadera a la
## rodilla por su −Z; la canilla, de la rodilla al tobillo).
func pose(leg: Dictionary) -> void:
	global_transform = Transform3D()
	if thigh_bone != null:
		MechSkeleton.put(thigh_bone, leg["thigh"])
		MechSkeleton.put(shin_bone, leg["shin"])
		var foot: Transform3D = leg["foot"]
		foot_bone.global_transform = Transform3D(foot.basis, foot.origin - foot.basis * _foot_from_ankle())
		return
	var thigh: Transform3D = leg["thigh"]
	var shin: Transform3D = leg["shin"]
	_thigh.transform = thigh
	_shin.transform = shin
	_foot.transform = leg["foot"]
	# El eje del disco (su Y) va de costado: el X de la parte.
	var sideways := Basis(Vector3.BACK, PI * 0.5)
	_hip.transform = Transform3D(thigh.basis * sideways, thigh * Vector3(0.0, 0.0, measures.THIGH * 0.5))
	_knee.transform = Transform3D(thigh.basis * sideways, leg["knee"])
	_ankle.transform = Transform3D(shin.basis * sideways, shin * Vector3(0.0, 0.0, -measures.SHIN * 0.5))


## Dónde está el pie (mundo).
func foot() -> Transform3D:
	return _foot.global_transform
