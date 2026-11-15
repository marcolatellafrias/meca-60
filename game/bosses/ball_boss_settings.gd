class_name BallBossSettings
extends Resource

## LAS PERILLAS DEL JEFE BOLA (ver BallBoss): una sola copia (`current`), la que muestra su panel F1, una pestaña por
## grupo. Todo en metros y segundos, como la meca simplificada: cada movimiento se define por lo que hace.

## Se carga de lo guardado con «Guardar» en el F1 (KnobsFile). El archivo es del usuario: no va al repositorio.
const SAVED := "res://game/bosses/ball_boss_settings.tres"
static var current := KnobsFile.load_into(BallBossSettings.new(), SAVED) as BallBossSettings

@export_group("Forma")
## LA FORMA (14/11/2026; el usuario: «está todo muy hardcodeado… experimentar con tamaños»). Todo esto SE REARMA AL
## GUARDAR (BallBossPanel.applied): el jefe se vuelve a armar en el lugar donde está.
## LA BOLA: el radio (m); el casco low poly (BallShell): franjas de polo a polo, cuántas del medio son la rendija (las
## dos, pares) y caras alrededor; cuánto se hunde la rendija (m). El ancho de la rendija sale de las franjas. Y cuánto
## más ancho que la bola es el cilindro que choca con lo fijo (m).
@export_range(6.0, 40.0, 0.5) var radius := 15.0
@export_range(6, 40, 2) var shell_bands := 16
@export_range(2, 10, 2) var slit_bands := 2
@export_range(6, 48, 1) var shell_sides := 18
@export_range(0.0, 4.0, 0.05) var slit_depth := 0.6
## El casco liso (la rendija sigue plana y su borde, marcado) o con caras planas.
@export var shell_smooth := true
@export_range(0.0, 6.0, 0.25) var reach_margin := 1.0
## LOS TENTÁCULOS (Tentacle): el grueso en la bola y en el pie (radio, m); el pie: el cubo del medio (radio y alto, m)
## y cada paleta (ancho de la base, largo y grueso, m). El largo, en la pestaña Tentáculos.
@export_range(0.5, 8.0, 0.1) var tentacle_root := 3.2
@export_range(0.5, 8.0, 0.1) var tentacle_tip := 2.2
@export_range(0.5, 8.0, 0.1) var hub_radius := 2.8
@export_range(0.2, 6.0, 0.1) var hub_height := 2.0
@export_range(0.5, 15.0, 0.25) var blade_width := 4.5
@export_range(1.0, 20.0, 0.25) var blade_length := 7.0
@export_range(0.1, 3.0, 0.05) var blade_thickness := 0.9
## EL CAÑÓN (BallCannon): el carro metido en la rendija (alto y fondo, m), el caño (radio y largo, m) y la boca de la
## punta (radio y largo, m).
@export_range(1.0, 15.0, 0.25) var carriage_height := 5.0
@export_range(0.5, 10.0, 0.25) var carriage_depth := 3.0
@export_range(0.3, 6.0, 0.1) var barrel_radius := 1.6
@export_range(2.0, 40.0, 0.5) var barrel_length := 12.0
@export_range(0.3, 8.0, 0.1) var muzzle_radius := 2.4
@export_range(0.5, 20.0, 0.25) var muzzle_length := 5.5

@export_group("Arena")
## EL RADIO DE LA ARENA (m; BossArena): el círculo del que no sale. El anillo del piso lo sigue al guardar; los
## edificios de afuera se acomodan regenerando la parcela (R). 150 m: 300 de punta a punta, diez veces la bola (el
## usuario, de los 100 primeros: «es muy poco»).
@export_range(60.0, 180.0, 5.0) var arena_radius := 150.0

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
## SÓLO BAJA LA BOLA: los tentáculos se doblan solos (Tentacle). Nunca baja de su radio: la bola no se mete en el piso.
@export_range(12.0, 50.0, 0.5) var stand_height := 20.0
@export_range(11.0, 40.0, 0.5) var crouch_height := 15.5
@export_range(0.1, 3.0, 0.05) var crouch_rate := 0.6

@export_group("Cañón")
## A qué velocidad corre el cañón por la rendija (grados por segundo).
@export_range(10.0, 360.0, 5.0) var pitch_speed := 60.0

@export_group("Disparos")
## EL SIMPLE: a qué velocidad va (m/s). Entre un tiro y otro (de cualquier clase), `shot_cooldown` (s).
@export_range(20.0, 400.0, 5.0) var shell_speed := 120.0
@export_range(0.1, 5.0, 0.05) var shot_cooldown := 0.8
## LOS DEL CIELO: cuántos, cada cuánto sale uno (s) y cuánto tarda cada uno en caer (s). Caen en fila hacia adelante: el
## primero a `barrage_distance` (m) y cada uno `barrage_spacing` (m) más lejos.
@export_range(1, 12, 1) var barrage_count := 5
@export_range(0.05, 2.0, 0.05) var barrage_gap := 0.35
@export_range(0.5, 6.0, 0.1) var barrage_flight := 2.5
@export_range(10.0, 200.0, 1.0) var barrage_distance := 50.0
@export_range(2.0, 40.0, 0.5) var barrage_spacing := 12.0

@export_group("Bola")
## HECHA BOLA (BallRoll): cuánto tarda en plegarse o abrirse (s) y, rodando, la velocidad tope (m/s).
@export_range(0.1, 3.0, 0.05) var fold_time := 0.8
@export_range(2.0, 60.0, 0.5) var roll_speed := 20.0
## LAS RAMPAS DE RODAR (MoveRamp; cada una, de punta a punta, con su curva): llegar a la tope apretando W, apagarse
## soltando (la inercia) y frenar apretando S (o al abrirse).
@export_range(0.0, 10.0, 0.05) var roll_up_time := 2.5
@export var roll_up_shape := MoveCurve.Shape.EASE_IN
@export_range(0.0, 15.0, 0.05) var roll_coast_time := 4.0
@export var roll_coast_shape := MoveCurve.Shape.EASE_IN
@export_range(0.0, 5.0, 0.05) var roll_brake_time := 1.0
@export var roll_brake_shape := MoveCurve.Shape.LINEAR
## EL GIRO rodando (°/s): casi quieta y a la velocidad tope.
@export_range(10.0, 360.0, 5.0) var roll_turn := 80.0
@export_range(5.0, 360.0, 5.0) var roll_turn_fast := 30.0
## PEGA AL TOCAR: desde qué velocidad (m/s) y cuánto le cambia la velocidad a lo que toca, yendo a tope (m/s).
@export_range(0.0, 20.0, 0.5) var hit_min_speed := 4.0
@export_range(1.0, 60.0, 0.5) var hit_push := 16.0

@export_group("Barrido")
## EL BARRIDO (Q; ver BallLegs): cuánto dura (s), cuántas vueltas dan los pies (negativo, para el otro lado), a cuánto
## del centro (m) y a cuánto del piso (m) pasan, y cuánto le cambia la velocidad a lo que tocan (m/s).
@export_range(0.3, 5.0, 0.05) var sweep_time := 1.4
@export_range(-3.0, 3.0, 0.25) var sweep_turns := 1.0
@export_range(15.0, 60.0, 0.5) var sweep_reach := 30.0
@export_range(0.0, 20.0, 0.5) var sweep_height := 4.0
@export_range(1.0, 60.0, 0.5) var sweep_push := 18.0

@export_group("Tentáculos")
## El largo de cada tentáculo (m) y a cuánto del centro, de costado, apoya su pie.
@export_range(10.0, 80.0, 0.5) var tentacle_length := 24.0
@export_range(8.0, 50.0, 0.5) var spread := 24.0
## LOS PASOS: un pie sale cuando quedó a más de `step_radius` (m) de su lugar, tarda `step_time` (s) y sube
## `step_lift` (m). Salen de a dos, en diagonal (el de adelante a la derecha con el de atrás a la izquierda).
@export_range(1.0, 20.0, 0.25) var step_radius := 5.0
@export_range(0.1, 2.0, 0.05) var step_time := 0.55
@export_range(0.0, 15.0, 0.25) var step_lift := 4.0
