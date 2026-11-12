class_name HoverCubeSettings
extends Resource

## LAS PERILLAS DEL CUBO (ver HoverCube): una sola copia para todos (`current`), que arma el panel de su fila (HoverPanel,
## F1 en la fila Cubo) leyendo estas propiedades. Las fuerzas van como ACELERACIONES (m/s²): la masa del cubo no las
## cambia. Las de flotar son las del cuerpo de character-parametric antes del 13/03/2026 (CharacterRigidBody3D:
## `height_kp`, `height_kd`, `max_up_force`, `max_height_error`), llevadas a este tamaño.

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

@export_group("Moverse y el retroceso")
## Lo propio (manejándolo con la O): a qué velocidad va (m/s), cuánto tarda en llegar (m/s²) y cómo frena al soltar
## (m/s²: poco, frena de a poco; mucho, en seco).
@export_range(0.5, 30.0, 0.5) var walk_speed := 8.0
@export_range(0.5, 40.0, 0.5) var walk_accel := 6.0
@export_range(0.5, 40.0, 0.5) var walk_brake := 5.0
## Cuánto gira con A/D (grados por segundo).
@export_range(5.0, 180.0, 5.0) var turn_speed := 45.0
## EL RETROCESO: cuánto más lo corre un golpe de algo que se mueve (× lo que le cambió la velocidad: la física de un
## cubo de 50 t lo corre poco) y cómo frena (m/s²: poco, patina; mucho, seco).
@export_range(0.0, 6.0, 0.05) var knock_gain := 2.5
@export_range(0.0, 20.0, 0.1) var knock_brake := 2.5

@export_group("Contra qué choca")
## Chocar contra algo fijo (una pared, un edificio) inclina esta parte de lo que inclinaría un golpe: lo frena, no lo
## voltea.
@export_range(0.0, 1.0, 0.01) var fixed_lean := 0.25
## Cuánto cuenta la altura del golpe (0: igual en cualquier lado; 1: proporcional a la altura sobre el piso, y a la altura
## del centro como siempre).
@export_range(0.0, 1.0, 0.05) var height_weight := 1.0

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

@export_group("Caído")
## Cuánto más pesa mientras está caído (1 es la gravedad de siempre): cae más rápido, sin perder la física.
@export_range(1.0, 4.0, 0.05) var fall_gravity := 1.4
## Cuánto le frena el giro mientras está caído (1/s): cae de costado y se queda (no se pone a rodar).
@export_range(0.0, 5.0, 0.05) var ground_spin_damp := 2.5
## Cuánto queda tirado antes de recuperarse (s), una vez que dejó de caer y de rodar rápido (más lento que esto, m/s y
## rad/s): no espera a quedarse quieto.
@export_range(0.0, 10.0, 0.05) var limp_time := 0.3
@export_range(0.1, 10.0, 0.1) var settle_speed := 2.5
@export_range(0.1, 10.0, 0.1) var settle_spin := 1.5

@export_group("Recuperarse (los propulsores)")
## Lo que empuja cada tobera, a todo (m/s² del cubo entero). Son cuatro por cara.
@export_range(1.0, 30.0, 0.1) var nozzle_push := 9.0
## Primero SUBE: hasta que la cara de abajo quede a esta parte de la altura de flotar, con este resorte (firme: rápido).
## En cuanto despegó lo bastante para girar sin tocar el piso, además SE ENDEREZA.
@export_range(0.2, 2.0, 0.05) var lift_share := 1.0
@export_range(0.5, 40.0, 0.1) var lift_kp := 9.0
@export_range(0.1, 20.0, 0.1) var lift_kd := 5.0
## Cómo se endereza en el aire: el resorte (firme: rápido).
@export_range(0.5, 40.0, 0.1) var right_kp := 9.0
@export_range(0.1, 20.0, 0.1) var right_kd := 5.0
## Queda derecho (y vuelve a la línea) con menos de esta inclinación (grados) y casi sin girar.
@export_range(1.0, 30.0, 0.5) var upright_done := 8.0
