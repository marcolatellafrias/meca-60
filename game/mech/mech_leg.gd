class_name MechLeg
extends Node3D

## UNA PIERNA DE LA MECA, sólo dibujo: muslo, canilla y pie, puestos entre la cadera y el pie con dos huesos (la rodilla
## hacia adelante). La meca dice dónde está la cadera y dónde el pie (ver Mech, LA MARCHA); acá sólo se resuelve la
## rodilla. Vive en el espacio de la meca (su raíz, que no se inclina).

const THIGH := 4.4
const SHIN := 4.4
const THICKNESS := 1.1

var _thigh: MeshInstance3D = null
var _shin: MeshInstance3D = null
var _knee: MeshInstance3D = null
var _foot: MeshInstance3D = null


func _ready() -> void:
	_thigh = Clay.box(self, Vector3.ONE, Vector3.ZERO, Clay.METAL.darkened(0.1))
	_shin = Clay.box(self, Vector3.ONE, Vector3.ZERO, Clay.METAL.darkened(0.25))
	_knee = Clay.sphere(self, THICKNESS * 0.75, Vector3.ZERO, Clay.DARK)
	_foot = Clay.box(self, Vector3(2.2, 0.7, 3.4), Vector3.ZERO, Clay.DARK)


## Pone la pierna entre `hip` y `foot` (en el espacio del padre). `forward` es hacia dónde dobla la rodilla.
func pose(hip: Vector3, foot: Vector3, forward: Vector3) -> void:
	var ankle := foot + Vector3(0, 0.6, 0)
	var reach := ankle - hip
	var distance := clampf(reach.length(), 0.5, THIGH + SHIN - 0.01)
	var knee := MechLeg.joint(hip, ankle, THIGH, SHIN, forward)
	var end := hip + reach.normalized() * distance
	Clay.segment(_thigh, hip, knee, THICKNESS)
	Clay.segment(_shin, knee, end, THICKNESS * 0.9)
	_knee.position = knee
	_foot.position = foot + Vector3(0, 0.35, -0.4)


## LA ARTICULACIÓN DEL MEDIO de dos huesos (`first` desde `root`, `second` hasta `end`): ley del coseno en la raíz,
## doblada hacia `hint` sin la parte que va a lo largo. Sirve para la rodilla y para el codo (ver MechArm).
static func joint(root: Vector3, end: Vector3, first: float, second: float, hint: Vector3) -> Vector3:
	var reach := end - root
	var distance := clampf(reach.length(), 0.5, first + second - 0.01)
	var along := reach.normalized()
	var cosine := (first * first + distance * distance - second * second) / (2.0 * first * distance)
	var angle := acos(clampf(cosine, -1.0, 1.0))
	var bend := (hint - along * hint.dot(along)).normalized()
	if bend.length_squared() < 0.01:
		bend = Vector3.FORWARD
	return root + along * cos(angle) * first + bend * sin(angle) * first
