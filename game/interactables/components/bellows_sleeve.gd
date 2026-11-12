class_name BellowsSleeve
extends Node3D

## UN FUELLE: una funda de goma acordonada entre una BASE FIJA —contra el tablero— y un EXTREMO que se mueve. No hace
## nada solo: quien lo usa le da una POSE —cuánto se dobla (`bend`, en X, en radianes) y cuánto mide (`length`)— y cada
## pliegue toma su parte según su altura: el de abajo casi nada, el de arriba todo. Así se curva de a poco y se abre o se
## cierra como uno de verdad, con la base siempre firme. Lo usan el volante (que se ESTIRA hacia quien lo agarra) y el
## mando de dos manos (que se DOBLA, y también se estira).
##
## Su origen es la base, y crece hacia +Z.

var folds: Array[Node3D] = []
## La pose de reposo de cada pliegue, en fracción del largo (0 la base, 1 el extremo).
var _t := PackedFloat32Array()
var _thickness: float = 0.01


## Arma `count` pliegues, gordos y finos alternados, del material `material`, para un fuelle de `length` en reposo.
func build(count: int, fat: float, thin: float, length: float, material: Material) -> void:
	_thickness = length / float(count) * 1.05
	for k in count:
		var fold := Node3D.new()
		add_child(fold)
		var ring := MeshInstance3D.new()
		var piece := CylinderMesh.new()
		piece.top_radius = fat if k % 2 == 0 else thin
		piece.bottom_radius = piece.top_radius
		piece.height = _thickness
		piece.radial_segments = 14
		piece.rings = 1
		ring.mesh = piece
		ring.material_override = material
		ring.rotation.x = PI * 0.5
		fold.add_child(ring)
		folds.append(fold)
		_t.append((float(k) + 0.5) / float(count))
	pose(0.0, length)


## LA POSE: doblado `bend` en su extremo y de `length` de largo. Cada pliegue va a su altura —una fracción del largo— y
## se dobla esa misma fracción; estirado, los pliegues se separan y se estiran un poco cada uno.
func pose(bend: float, length: float) -> void:
	var stretch := length / maxf(_thickness * float(folds.size()) / 1.05, 0.001)
	for i in folds.size():
		var t := _t[i]
		var turn := Basis(Vector3.RIGHT, bend * t)
		folds[i].transform = Transform3D(turn * Basis.from_scale(Vector3(1.0, 1.0, maxf(stretch, 0.2))),
			turn * Vector3(0.0, 0.0, length * t))
