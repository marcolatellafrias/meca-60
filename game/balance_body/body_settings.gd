class_name BodySettings
extends Resource

## LAS PERILLAS DE UN CUERPO CON EQUILIBRIO (ver BalanceBody y sus piezas): una sola copia para todos (`current`), la
## de la meca propia; un jefe puede llevar la suya (`BalanceBody.knobs`), que arma el panel de sus
## filas (MechPanel, F1) leyendo estas propiedades —lo que el recurso exporta es lo que se ve—. Las fuerzas van como
## ACELERACIONES (m/s²): la masa de la caja no las cambia.

static var current := BodySettings.new()

@export_group("Caminar")
## A qué altura del piso va la cara de abajo de la caja (m): de ahí sale el largo del palo del péndulo.
@export_range(0.5, 15.0, 0.1) var hover_height := 7.4
## A qué velocidad va (m/s), cuánto tarda en llegar (m/s²) y cómo frena al soltar (m/s²: poco, frena de a poco).
@export_range(0.5, 30.0, 0.5) var walk_speed := 8.0
@export_range(0.5, 40.0, 0.5) var walk_accel := 6.0
@export_range(0.5, 40.0, 0.5) var walk_brake := 5.0

@export_group("El péndulo")
## Qué tan firme está agarrado al punto de apoyo (1/s² y 1/s): la punta del palo, al piso.
@export_range(20.0, 400.0, 5.0) var pivot_kp := 120.0
@export_range(1.0, 40.0, 0.5) var pivot_kd := 12.0
## El músculo que la quiere derecha sobre su apoyo (1/s² por radián y 1/s por rad/s): poco, lo que la sostiene son los
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

@export_group("El giro")
## El torso gira hacia donde se pide con velocidad tope (grados por segundo) y un motor con dos topes (rad/s²): GIRAR
## ELLA, débil —del orden de lo que empuja caminar: apoyada en una pared, si no puede girar no gira, y no la despide—,
## y FRENAR un giro que le dieron (un golpe descentrado), fuerte.
@export_range(5.0, 180.0, 5.0) var turn_speed := 90.0
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

@export_group("Correr")
## Corriendo va hasta esto por la velocidad de caminar. Lo de arriba de la caminata es una banda que se gana —y se
## pierde— a `sprint_accel` de la aceleración de siempre.
@export_range(1.0, 4.0, 0.05) var sprint_multiplier := 1.8
@export_range(0.1, 1.0, 0.05) var sprint_accel := 0.5

@export_group("Agacharse")
## Agachada, el palo del péndulo queda en esta parte de su largo, y camina a esta parte de su velocidad.
@export_range(0.4, 1.0, 0.01) var crouch_rod := 0.68
@export_range(0.1, 1.0, 0.05) var crouch_speed := 0.5
## Cuán rápido sube y baja (partes del largo por segundo).
@export_range(0.2, 6.0, 0.1) var rod_rate := 1.2

@export_group("Saltar")
## Mantener carga, soltar salta: cuánto sube el salto entero (m), en cuánto se carga (s), cuánto baja al cargar (parte
## del largo del palo) y con qué parte del salto sale un toque sin cargar.
@export_range(1.0, 60.0, 0.5) var jump_height := 14.0
@export_range(0.1, 3.0, 0.05) var jump_charge_time := 0.9
@export_range(0.5, 1.0, 0.01) var jump_squat := 0.78
@export_range(0.05, 1.0, 0.05) var jump_least := 0.3
## En el aire, cuánto puede cambiar su velocidad de costado (m/s²).
@export_range(0.0, 20.0, 0.5) var air_accel := 2.5

@export_group("El propulsor")
## Cuánto empuja para arriba (m/s²; la gravedad es 9,8), cuánto dura lleno (s) y en cuánto se recarga en el piso (s).
@export_range(5.0, 40.0, 0.5) var thrust := 12.5
@export_range(0.2, 20.0, 0.1) var thrust_time := 2.0
@export_range(0.2, 20.0, 0.1) var thrust_refill := 3.0

@export_group("Caída")
## Cuánto más pesa mientras está caída (1 es la gravedad de siempre): cae más rápido, sin perder la física.
@export_range(1.0, 4.0, 0.05) var fall_gravity := 1.4
## Cuánto le frena el giro mientras está caída (1/s): cae de costado y se queda (no se pone a rodar).
@export_range(0.0, 5.0, 0.05) var ground_spin_damp := 2.5
## Cuánto queda tirada antes de recuperarse (s), una vez que dejó de caer y de rodar rápido (más lento que esto, m/s y
## rad/s): no espera a quedarse quieta.
@export_range(0.0, 10.0, 0.05) var limp_time := 0.3
@export_range(0.1, 10.0, 0.1) var settle_speed := 2.5
@export_range(0.1, 10.0, 0.1) var settle_spin := 1.5

@export_group("Levantarse (las toberas)")
## Lo que empuja cada tobera, a todo (m/s² de la caja entera). Son cuatro por cara.
@export_range(1.0, 30.0, 0.1) var nozzle_push := 9.0
## SUBE hasta que la cara de abajo quede a esta parte de la altura de ir parada, con este resorte; y SE ENDEREZA a la
## vez, tanto como el lugar le deja.
@export_range(0.2, 2.0, 0.05) var lift_share := 1.0
@export_range(0.5, 40.0, 0.1) var lift_kp := 9.0
@export_range(0.1, 20.0, 0.1) var lift_kd := 5.0
@export_range(0.5, 40.0, 0.1) var right_kp := 9.0
@export_range(0.1, 20.0, 0.1) var right_kd := 5.0
## Queda derecha (y vuelve a pararse) con menos de esta inclinación (grados) y casi sin girar.
@export_range(1.0, 30.0, 0.5) var upright_done := 8.0

@export_group("El F2")
## El golpe arriba, suave y fuerte (m/s que le cambiaría la velocidad suelta).
@export_range(0.5, 40.0, 0.5) var knock_soft := 5.0
@export_range(0.5, 40.0, 0.5) var knock_strong := 14.0
