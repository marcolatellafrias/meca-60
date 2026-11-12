class_name BalanceCubeSettings
extends Resource

## LAS PERILLAS DEL CUBO CON EQUILIBRIO (ver BalanceCube): la línea de equilibrio y el tropezar. Una sola copia
## (`current`), que arma su panel (BalanceCubePanel, F1 en la fila Cubo con equilibrio). Lo de flotar y recuperarse es lo
## del cubo flotante, en su propia copia (BalanceCube.hover_knobs), en el mismo panel.

static var current := BalanceCubeSettings.new()

@export_group("La línea de equilibrio")
## Cuánto lo inclina cada m/s de golpe (cualquier golpe en el cuerpo, a cualquier altura: simplificado). El golpe se suma
## a la VELOCIDAD de la inclinación (× `push_rate`): se ve el envión.
@export_range(0.02, 1.0, 0.01) var lean_per_ms := 0.3
@export_range(0.5, 15.0, 0.1) var push_rate := 6.0
## El resorte que lo vuelve derecho: cuánto tira y cuánto frena.
@export_range(0.5, 40.0, 0.25) var stiffness := 8.75
@export_range(0.1, 20.0, 0.05) var damping := 3.6
## Se cae al pasar esto.
@export_range(0.2, 1.0, 0.01) var fall_at := 0.85
## Cuánto se inclina el dibujo con la inclinación en 1 (grados).
@export_range(2.0, 60.0, 1.0) var lean_angle := 25.0

@export_group("Tropezar")
## Al caerse, cuánto se le traba la base (1: la base queda quieta y la parte de arriba sigue con el impulso; 0: cae con
## el cuerpo entero corriéndose).
@export_range(0.0, 1.5, 0.05) var base_grip := 1.0
## Cuánto de lo que se venía inclinando sigue como giro al caer.
@export_range(0.0, 2.0, 0.05) var tip_carry := 1.0
