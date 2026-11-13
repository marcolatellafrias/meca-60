class_name BallBossSettings
extends Resource

## LAS PERILLAS DEL JEFE BOLA (ver BallBoss): una sola copia (`current`), la que muestra su panel F1, una pestaña por
## grupo. Todo en metros y segundos, como el cubo cinemático: cada movimiento se define por lo que hace.

static var current := BallBossSettings.new()

@export_group("Moverse")
## Una velocidad y el tiempo para llegar a ella y para frenar (0: al instante). En el aire no se mueve de costado.
@export_range(1.0, 30.0, 0.5) var walk_speed := 6.0
@export_range(0.0, 3.0, 0.05) var reach_time := 0.5

@export_group("Girar")
## Velocidad tope (grados por segundo) y aceleración tope (grados por segundo al cuadrado).
@export_range(10.0, 360.0, 5.0) var turn_speed := 50.0
@export_range(10.0, 1000.0, 10.0) var turn_accel := 80.0

@export_group("Saltar")
## Sube `jump_height` (m) en `jump_time` (s), sólo para arriba, y baja igual. La gravedad sale de esos dos números.
@export_range(1.0, 30.0, 0.5) var jump_height := 8.0
@export_range(0.2, 3.0, 0.05) var jump_time := 0.9

@export_group("Agacharse")
## A qué altura va el centro de la bola parada y agachada (m), y a qué ritmo baja y sube (partes por segundo). Agacharse
## SÓLO BAJA LA BOLA: los tentáculos se doblan solos (Tentacle).
@export_range(12.0, 50.0, 0.5) var stand_height := 20.0
@export_range(11.0, 40.0, 0.5) var crouch_height := 15.5
@export_range(0.1, 3.0, 0.05) var crouch_rate := 0.6

@export_group("Tentáculos")
## El largo de cada tentáculo (m) y a cuánto del centro, de costado, apoya su pie.
@export_range(10.0, 80.0, 0.5) var tentacle_length := 24.0
@export_range(8.0, 50.0, 0.5) var spread := 24.0
## LOS PASOS: un pie sale cuando quedó a más de `step_radius` (m) de su lugar, tarda `step_time` (s) y sube
## `step_lift` (m). Salen de a dos, en diagonal (el de adelante a la derecha con el de atrás a la izquierda).
@export_range(1.0, 20.0, 0.25) var step_radius := 5.0
@export_range(0.1, 2.0, 0.05) var step_time := 0.55
@export_range(0.0, 15.0, 0.25) var step_lift := 4.0
