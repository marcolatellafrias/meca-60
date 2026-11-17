class_name BodySettings
extends Resource

## LAS PERILLAS DE UN CUERPO CON EQUILIBRIO (ver BalanceBody y sus piezas): una sola copia para todos (`current`), la
## de la meca propia; un jefe puede llevar la suya (`BalanceBody.knobs`). Las fuerzas van como ACELERACIONES (m/s²): la
## masa de la caja no las cambia. Hoy las usa entera la meca de práctica (la física, sin brazos); la jaula, cinemática,
## se mueve con las suyas (KinematicSettings, CageMech.MOVES) y de acá sólo leen sus piernas (el paso, las rodillas).
## *Hasta el 17/11/2026 las mostraba el F1 de las filas de la meca grande (MechPanel), borradas ese día con ella.*
##
## SE GUARDAN, COMO LA FORMA DEL F2 (13/11/2026; el usuario: «no entiendo por qué este panel no tiene opción de
## guardado»): `current` arranca con lo guardado en `SAVED` (si hay; ver KnobsFile).
## CADA NÚMERO TIENE UN SOLO DUEÑO (13/11/2026): la ALTURA DE LA CAJA no es una perilla —sale del cuerpo, del largo y
## lo estirado de las piernas del F2: ver BalanceBody.hover—; y el PASO de acá (`step_reach`, `step_height`,
## `settle_gap`) es el de piernas medianas, que las piernas escalan con su largo al leerlo (BodyLegs). *Hasta entonces
## MechBody.dress los escribía encima de estas perillas y la altura del F1 no hacía nada (lo vio el usuario: «la pongo
## en 0.5 y la pongo en 15 y no cambia nada»).*
## El archivo guardado es del usuario: no se sube al repositorio.

const SAVED := "res://game/balance_body/body_settings.tres"
static var current := KnobsFile.load_into(BodySettings.new(), SAVED) as BodySettings
## *Hasta el 17/11/2026 la meca física de la meca grande guardaba las suyas aparte (`physical`, en
## body_settings_fisica.tres); se borró con ella.*

@export_group("Caminar")
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

@export_group("Las piernas (pasos de largo fijo)")
## EL PASO TIENE SIEMPRE EL MISMO LARGO: el pie pisa `step_reach` adelante de su lugar (hacia donde va). Más rápido no
## pisa más lejos: da los pasos más seguido. Cuánto dura un paso es lo que tarda el torso en recorrer el doble de eso,
## entre `step_fastest` y `step_slowest`.
@export_range(0.3, 6.0, 0.1) var step_reach := 2.4
@export_range(0.1, 1.5, 0.05) var step_fastest := 0.3
@export_range(0.2, 2.0, 0.05) var step_slowest := 0.7
@export_range(0.0, 4.0, 0.1) var step_height := 1.4
## Quieta, un pie que quedó más lejos que esto de su lugar (o más girado que `settle_turn`) se acomoda con un paso.
@export_range(0.1, 3.0, 0.05) var settle_gap := 0.5
@export_range(2.0, 45.0, 1.0) var settle_turn := 10.0
## Lo más que un paso gira el pie de lo que mira el otro: girando en el lugar, gira de a pasos.
@export_range(10.0, 90.0, 1.0) var turn_per_step := 40.0
## LAS RODILLAS van hacia adelante y un poco hacia afuera; agachada, más hacia afuera (parte de adelante).
@export_range(0.0, 1.5, 0.05) var knee_out := 0.2
@export_range(0.0, 2.0, 0.05) var knee_out_crouched := 0.6
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
@export_range(0.1, 3.0, 0.05) var jump_charge_time := 0.45
@export_range(0.5, 1.0, 0.01) var jump_squat := 0.78
@export_range(0.05, 1.0, 0.05) var jump_least := 0.3
## En el aire, cuánto puede cambiar su velocidad de costado (m/s²).
@export_range(0.0, 20.0, 0.5) var air_accel := 2.5
## UN SALTO QUE NO FLOTE (13/11/2026; el usuario: «se siente como muy lento… no se siente snappy»): en el aire pesa
## `air_gravity` veces más (sube rápido y baja rápido; la altura sigue siendo la pedida), y bajando, `fall_extra` veces
## más todavía. Con el propulsor prendido pesa lo de siempre: si no, no la levantaría.
@export_range(1.0, 5.0, 0.05) var air_gravity := 2.4
@export_range(1.0, 3.0, 0.05) var fall_extra := 1.3

@export_group("Dash (en el aire)")
## EL DASH: en el aire, un impulso de costado hacia donde se pide (sin pedir nada, adelante), de las toberas: le suma
## `dash_speed` (m/s) hacia ahí y, si estaba bajando, la deja subiendo a `dash_lift`. Gasta `dash_cost` del propulsor
## y hay `dash_count` por salto.
@export_range(2.0, 40.0, 0.5) var dash_speed := 18.0
@export_range(0.0, 15.0, 0.5) var dash_lift := 3.0
@export_range(0.0, 1.0, 0.05) var dash_cost := 0.35
@export_range(1, 4, 1) var dash_count := 1

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
