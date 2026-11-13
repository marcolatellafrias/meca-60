class_name PillarSettings
extends Resource

## LAS PERILLAS DEL CUBO CINEMÁTICO (ver KinematicPillar): una sola copia (`current`), la que muestra su panel F1, una
## pestaña por grupo.

static var current := PillarSettings.new()

@export_group("Moverse")
@export_range(1.0, 30.0, 0.5) var walk_speed := 8.0
## Arrancar y frenar (m/s²). Frenar es lo que hace de roce: el cubo no tiene fricción con el piso.
@export_range(1.0, 60.0, 0.5) var walk_accel := 8.0
@export_range(1.0, 60.0, 0.5) var walk_brake := 10.0
@export_range(1.0, 3.0, 0.05) var sprint_multiplier := 1.8
## En el aire, cuánto de arrancar y frenar le queda (parte).
@export_range(0.0, 1.0, 0.05) var air_control := 0.3

@export_group("Girar")
## Velocidad tope (grados por segundo) y aceleración tope (grados por segundo al cuadrado).
@export_range(10.0, 360.0, 5.0) var turn_speed := 90.0
@export_range(10.0, 1000.0, 10.0) var turn_accel := 140.0

@export_group("Saltar y volar")
@export_range(1.0, 30.0, 0.5) var jump_height := 8.0
## En el aire pesa esto más (veces), como la meca.
@export_range(1.0, 5.0, 0.05) var air_gravity := 2.4
## EL VUELO (espacio otra vez, en el aire): empuja para arriba (m/s², sin contar la gravedad), y su barra dura
## `thrust_time` empujando y se llena en `thrust_refill`, sólo apoyado.
@export_range(1.0, 60.0, 0.5) var thrust := 14.0
@export_range(0.2, 10.0, 0.1) var thrust_time := 2.0
@export_range(0.2, 10.0, 0.1) var thrust_refill := 3.0

@export_group("Dash")
## EL DASH (la Q, con una dirección): suma `dash_speed` (m/s) hacia allá; en el aire, además, sube a `dash_lift`.
## Durante `dash_hold` (s) caminar no lo frena. Gasta `dash_cost` de su barra, que se llena sola en `dash_refill` (s).
@export_range(2.0, 60.0, 0.5) var dash_speed := 18.0
@export_range(0.0, 20.0, 0.5) var dash_lift := 3.0
@export_range(0.0, 2.0, 0.05) var dash_hold := 0.25
@export_range(0.05, 1.0, 0.05) var dash_cost := 0.35
@export_range(0.2, 20.0, 0.1) var dash_refill := 3.0

@export_group("Agacharse")
## Agachado, el alto que le queda (parte) y a qué ritmo cambia (partes por segundo).
@export_range(0.3, 1.0, 0.05) var crouch_share := 0.6
@export_range(0.1, 3.0, 0.05) var crouch_rate := 0.5

@export_group("Con lo suelto")
## TOPADORA CON TOPE: lo más que lo suelto sale hacia afuera más rápido que el cubo (m/s).
@export_range(0.0, 10.0, 0.25) var cap_extra := 1.5
## ATRAVIESA Y EMPUJA: cuánto más rápido que el cubo sale lo que empuja (m/s).
@export_range(0.0, 10.0, 0.25) var ghost_extra := 0.5
