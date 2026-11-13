class_name PillarSettings
extends Resource

## LAS PERILLAS DEL CUBO CINEMÁTICO (ver KinematicPillar): una sola copia (`current`), la que muestra su panel F1.

static var current := PillarSettings.new()

@export_group("Moverse")
@export_range(1.0, 30.0, 0.5) var walk_speed := 8.0
## Arrancar y frenar (m/s²).
@export_range(1.0, 60.0, 0.5) var walk_accel := 8.0
@export_range(1.0, 60.0, 0.5) var walk_brake := 10.0
@export_range(1.0, 3.0, 0.05) var sprint_multiplier := 1.8

@export_group("Girar")
## Velocidad tope (grados por segundo) y aceleración tope (grados por segundo al cuadrado).
@export_range(10.0, 360.0, 5.0) var turn_speed := 90.0
@export_range(10.0, 1000.0, 10.0) var turn_accel := 140.0

@export_group("Saltar y agacharse")
@export_range(1.0, 30.0, 0.5) var jump_height := 8.0
## En el aire pesa esto más (veces), como la meca.
@export_range(1.0, 5.0, 0.05) var air_gravity := 2.4
## Agachado, el alto que le queda (parte) y a qué ritmo cambia (partes por segundo).
@export_range(0.3, 1.0, 0.05) var crouch_share := 0.6
@export_range(0.1, 3.0, 0.05) var crouch_rate := 0.5

@export_group("Con lo suelto")
## TOPADORA CON TOPE: lo más que lo suelto sale hacia afuera más rápido que el cubo (m/s).
@export_range(0.0, 10.0, 0.25) var cap_extra := 1.5
## ATRAVIESA Y EMPUJA: cuánto más rápido que el cubo sale lo que empuja (m/s).
@export_range(0.0, 10.0, 0.25) var ghost_extra := 0.5
