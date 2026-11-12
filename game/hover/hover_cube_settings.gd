class_name HoverCubeSettings
extends Resource

## LAS PERILLAS DEL CUBO FLOTANTE (ver HoverCube): una sola copia para todos (`current`), que arma el panel de su fila
## (HoverPanel, F1 en la fila Cubo flotante) leyendo estas propiedades. Las fuerzas van como ACELERACIONES (m/s² y
## rad/s²): la masa del cubo no las cambia. Las de flotar son las del cuerpo de character-parametric antes del 13/03/2026
## (CharacterRigidBody3D: `height_kp`, `height_kd`, `upright_kp`, `upright_kd`, `max_up_force`, `max_height_error` y
## los umbrales de «dejar de intentar»), llevadas a este tamaño.

static var current := HoverCubeSettings.new()

@export_group("Flotar")
## A qué altura del piso flota la cara de abajo (m).
@export_range(0.5, 15.0, 0.1) var hover_height := 7.4
## El resorte de la altura: cuánto tira por metro de error (1/s²) y cuánto frena por m/s (1/s). Con poco freno, rebota.
@export_range(1.0, 80.0, 0.5) var height_kp := 16.0
@export_range(0.0, 20.0, 0.1) var height_kd := 3.0
## El error de altura más grande que cuenta (m): más lejos, empuja igual.
@export_range(0.1, 6.0, 0.1) var max_height_error := 2.5
## Lo más que empuja para arriba (m/s², con la gravedad).
@export_range(5.0, 60.0, 0.5) var max_up := 30.0
## El freno de costado mientras flota (m/s²): sin él, un golpe lo deja deslizándose para siempre.
@export_range(0.0, 20.0, 0.1) var slide_brake := 3.0

@export_group("Derecho")
## El torque que lo endereza: cuánto tira por radián (1/s²) y cuánto frena por rad/s (1/s).
@export_range(0.0, 40.0, 0.25) var upright_kp := 4.0
@export_range(0.0, 20.0, 0.1) var upright_kd := 1.6

@export_group("Dejar de intentar")
## Pasado esto se deja caer: inclinado más de `max_tilt` (grados), cayendo más rápido que `max_fall_speed`, o yendo de
## costado más rápido que `max_side_speed` (m/s).
@export_range(5.0, 90.0, 1.0) var max_tilt := 50.0
@export_range(1.0, 40.0, 0.5) var max_fall_speed := 12.0
@export_range(1.0, 60.0, 0.5) var max_side_speed := 18.0
## Cuánto queda tirado antes de recuperarse (s), una vez quieto.
@export_range(0.0, 10.0, 0.1) var limp_time := 2.0

@export_group("Recuperarse (los propulsores)")
## Lo que empuja cada tobera, a todo (m/s² del cubo entero). Son cuatro por cara.
@export_range(1.0, 20.0, 0.1) var nozzle_push := 5.0
## Primero SUBE: hasta que la cara de abajo quede a esta parte de la altura de flotar, con este resorte.
@export_range(0.2, 2.0, 0.05) var lift_share := 1.0
@export_range(0.5, 20.0, 0.1) var lift_kp := 3.0
@export_range(0.1, 20.0, 0.1) var lift_kd := 2.5
## Después SE ENDEREZA en el aire, con este resorte (más lento que el de flotar, para que se vea).
@export_range(0.5, 20.0, 0.1) var right_kp := 2.5
@export_range(0.1, 20.0, 0.1) var right_kd := 2.2
## Queda derecho (y vuelve a flotar) con menos de esta inclinación (grados) y casi sin girar.
@export_range(1.0, 30.0, 0.5) var upright_done := 8.0
