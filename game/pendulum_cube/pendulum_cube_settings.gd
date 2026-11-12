class_name PendulumCubeSettings
extends HoverCubeSettings

## LAS PERILLAS DEL CUBO PÉNDULO (ver PendulumCube): las del cubo que usa (la altura, moverse, caído, recuperarse) en
## su propia copia, más las del péndulo, los pies, el giro y las piernas. Las de la línea de equilibrio no las usa: su
## panel no las muestra. Una sola copia para todos (`shared`), que arma su panel (PendulumCubePanel, F1 en su fila).

static var shared := PendulumCubeSettings.new()

@export_group("El péndulo")
## Qué tan firme está agarrado al punto de apoyo (1/s² y 1/s): la punta del palo, al piso.
@export_range(20.0, 400.0, 5.0) var pivot_kp := 120.0
@export_range(1.0, 40.0, 0.5) var pivot_kd := 12.0
## El músculo que lo quiere derecho sobre su apoyo (1/s² por radián y 1/s por rad/s): poco, lo que lo sostiene son los
## pies.
@export_range(0.0, 20.0, 0.1) var upright_kp := 1.0
@export_range(0.0, 10.0, 0.1) var upright_kd := 0.5
## Se cae pasado esto (grados).
@export_range(5.0, 80.0, 1.0) var fall_tilt := 25.0

@export_group("Los pies (el punto de apoyo)")
## El punto de apoyo sigue al torso: frena al instante, pero para alcanzarlo acelera con tope (m/s²) y hasta cierta
## velocidad (m/s). Pies más lentos: más se inclina con un golpe y más fácil se cae.
@export_range(0.5, 40.0, 0.5) var feet_accel := 7.0
## Qué tan rápido reaccionan (1/s): con menos, más se inclina hacia adelante mientras acelera (y con un golpe).
## OJO: el tope de arriba tiene que ser más que la aceleración de caminar, o al arrancar se cae de cara.
@export_range(0.5, 20.0, 0.1) var feet_react := 3.0
@export_range(1.0, 60.0, 0.5) var feet_speed := 20.0
## Cuánto busca ponerse debajo del torso (1/s, por metro de corrido).
@export_range(0.0, 10.0, 0.1) var feet_catch := 2.0

@export_group("El giro (el mouse)")
## El torso gira hacia donde se pide con velocidad tope (`turn_speed`, arriba) y un motor con dos topes (rad/s²):
## GIRAR ÉL, débil —del orden de lo que empuja caminar: apoyado en una pared, si no puede girar no gira, y no lo
## despide—, y FRENAR un giro que le dieron (un golpe descentrado), fuerte.
@export_range(0.2, 20.0, 0.1) var yaw_force := 2.0
@export_range(0.5, 60.0, 0.5) var yaw_hold := 12.0
@export_range(0.5, 20.0, 0.5) var yaw_grip := 6.0

@export_group("Las piernas (pasos por radio)")
@export_range(0.3, 8.0, 0.1) var step_radius := 2.5
@export_range(0.0, 1.5, 0.05) var step_lead := 0.35
@export_range(0.1, 1.5, 0.05) var step_time := 0.4
@export_range(0.0, 4.0, 0.1) var step_height := 1.4
## Cuánto tardan en recogerse al caer y en estirarse al enderezarse (s).
@export_range(0.05, 1.5, 0.05) var fold_time := 0.3
@export_range(0.05, 1.5, 0.05) var unfold_time := 0.25

@export_group("El F2")
## El golpe arriba, suave y fuerte (m/s que le cambiaría la velocidad suelto).
@export_range(0.5, 40.0, 0.5) var knock_soft := 5.0
@export_range(0.5, 40.0, 0.5) var knock_strong := 14.0


func _init() -> void:
	turn_speed = 90.0
