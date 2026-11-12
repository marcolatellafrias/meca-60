class_name Inspector
extends Node3D

## PIEZA PARA LO TRAÍDO DE CHARACTER-PARAMETRIC (ver LEEME.md de esta carpeta): allá esto es el identificador de piezas de la ciudad (I), que acá no
## existe. Sólo está lo que lo traído le pide, sin hacer nada.

signal toggled(on: bool)


func setup(_camera: Camera3D, _body: PhysicsBody3D = null) -> void:
	pass


func set_enabled(_on: bool) -> void:
	pass
