class_name PhysicalCubeSettings
extends HoverCubeSettings

## LAS PERILLAS DEL CUBO FÍSICO (ver PhysicalCube): las del cubo que usa (flotar —por esquina—, moverse, caído,
## recuperarse) en su propia copia, más las del cuerpo físico. Las de la línea de equilibrio no las usa: su panel no las
## muestra. Una sola copia para todos (`shared`), que arma su panel (PhysicalCubePanel, F1 en la fila Cubo físico).

static var shared := PhysicalCubeSettings.new()

@export_group("El cuerpo físico")
## LOS PIES: agarran el piso y llevan la base hacia la velocidad pedida (quieto, cero): cuánto por m/s de diferencia
## (1/s) y lo más que empujan (m/s² del cubo entero). Un golpe arriba corre el cuerpo y los pies frenan la base: vuelca.
@export_range(0.0, 20.0, 0.1) var grip_rate := 4.0
@export_range(0.0, 30.0, 0.5) var grip_max := 8.0
## Dónde agarran los pies, entre la cara de abajo (0) y el piso (1): más abajo, más lo vuelca un golpe (y arrancar y
## frenar lo cabecean más).
@export_range(0.0, 1.0, 0.05) var grip_depth := 0.8
## Qué tan afuera van los resortes de las esquinas (parte de la mitad del lado): más juntos, más se ladea con un golpe.
@export_range(0.1, 1.0, 0.05) var corner_spread := 0.4
## Lo que lo endereza además de los resortes de las esquinas (1/s² por radián y 1/s por rad/s).
@export_range(0.0, 20.0, 0.1) var upright_kp := 2.0
@export_range(0.0, 10.0, 0.1) var upright_kd := 1.5
## Se cae pasado esto (grados).
@export_range(5.0, 80.0, 1.0) var fall_tilt := 35.0
## El F2: el cambio de velocidad del empujón arriba, suave y fuerte (m/s).
@export_range(0.5, 20.0, 0.1) var knock_soft := 2.5
@export_range(0.5, 20.0, 0.1) var knock_strong := 6.0
