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
	var along := reach.normalized()
	# La rodilla: ley del coseno en la cadera, doblada hacia `forward` sin la parte que va a lo largo de la pierna.
	var cosine := (THIGH * THIGH + distance * distance - SHIN * SHIN) / (2.0 * THIGH * distance)
	var angle := acos(clampf(cosine, -1.0, 1.0))
	var bend := (forward - along * forward.dot(along)).normalized()
	if bend.length_squared() < 0.01:
		bend = Vector3.FORWARD
	var knee := hip + along * cos(angle) * THIGH + bend * sin(angle) * THIGH
	var end := hip + along * distance
	Clay.segment(_thigh, hip, knee, THICKNESS)
	Clay.segment(_shin, knee, end, THICKNESS * 0.9)
	_knee.position = knee
	_foot.position = foot + Vector3(0, 0.35, -0.4)
