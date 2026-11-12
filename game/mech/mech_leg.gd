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


func _init() -> void:
	top_level = true


func _ready() -> void:
	var thickness := MechBody.LEG_THICKNESS
	_thigh = Clay.limb(self, thickness * 0.5, MechBody.THIGH, Vector3.ZERO, Clay.METAL.darkened(0.1))
	_shin = Clay.limb(self, thickness * 0.5, MechBody.SHIN, Vector3.ZERO, Clay.METAL.darkened(0.2))
	_foot = Clay.box(self, MechBody.FOOT_SIZE, Vector3.ZERO, MechBody.JOINT_COLOR)
	# El disco de la cadera, apenas más ancho que la pierna para que no se pisen las caras; la rodilla y el tobillo,
	# esferas que asoman de la pierna.
	_hip = Clay.cylinder(self, MechBody.JOINT_RADIUS * 1.15, thickness * 1.04, Vector3.ZERO, MechBody.JOINT_COLOR)
	_knee = Clay.sphere(self, MechBody.JOINT_RADIUS, Vector3.ZERO, MechBody.JOINT_COLOR)
	_ankle = Clay.sphere(self, MechBody.JOINT_RADIUS * 0.85, Vector3.ZERO, MechBody.JOINT_COLOR)


## La pone como dice `leg` (ver MechBody.leg): las partes, y las articulaciones en sus puntas (el muslo va de la cadera a la
## rodilla por su −Z; la canilla, de la rodilla al tobillo).
func pose(leg: Dictionary) -> void:
	global_transform = Transform3D()
	var thigh: Transform3D = leg["thigh"]
	var shin: Transform3D = leg["shin"]
	_thigh.transform = thigh
	_shin.transform = shin
	_foot.transform = leg["foot"]
	# El eje del disco (su Y) va de costado: el X de la parte.
	var sideways := Basis(Vector3.BACK, PI * 0.5)
	_hip.transform = Transform3D(thigh.basis * sideways, thigh * Vector3(0.0, 0.0, MechBody.THIGH * 0.5))
	_knee.transform = Transform3D(thigh.basis * sideways, leg["knee"])
	_ankle.transform = Transform3D(shin.basis * sideways, shin * Vector3(0.0, 0.0, -MechBody.SHIN * 0.5))
