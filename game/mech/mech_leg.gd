class_name MechLeg
extends Node3D

## UNA PIERNA DE LA MECA DE PELEA, sólo dibujo: muslo, rodilla, canilla y pie donde dice el cuerpo (MechBody.leg). En el
## mundo (`top_level`): la postura ya viene en el mundo. Los largos son los del cuerpo y no se estiran: la rodilla sale
## de ellos.

var _thigh: MeshInstance3D = null
var _shin: MeshInstance3D = null
var _knee: MeshInstance3D = null
var _foot: MeshInstance3D = null


func _init() -> void:
	top_level = true


func _ready() -> void:
	var thickness := MechBody.LEG_THICKNESS
	_thigh = Clay.box(self, Vector3(thickness, thickness, MechBody.THIGH), Vector3.ZERO, Clay.METAL.darkened(0.1))
	_shin = Clay.box(self, Vector3(thickness * 0.9, thickness * 0.9, MechBody.SHIN), Vector3.ZERO,
		Clay.METAL.darkened(0.25))
	_knee = Clay.sphere(self, thickness * 0.75, Vector3.ZERO, Clay.DARK)
	_foot = Clay.box(self, MechBody.FOOT_SIZE, Vector3.ZERO, Clay.DARK)


## La pone como dice `leg` (ver MechBody.leg).
func pose(leg: Dictionary) -> void:
	global_transform = Transform3D()
	_thigh.transform = leg["thigh"]
	_shin.transform = leg["shin"]
	_knee.position = leg["knee"]
	_foot.transform = leg["foot"]
