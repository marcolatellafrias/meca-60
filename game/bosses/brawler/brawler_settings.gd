class_name BrawlerSettings
extends Resource

## LAS PERILLAS DEL LUCHADOR DE ORUGAS (ver Brawler): una sola copia (`current`), la que muestra su panel F1, una pestaña
## por grupo. Todo en metros y segundos: cada movimiento se define por lo que hace (movimiento discreto, cinemático).

## Se carga de lo guardado con «Guardar» en el F1 (KnobsFile). El archivo es del usuario: no va al repositorio.
const SAVED := "res://game/bosses/brawler/brawler_settings.tres"
static var current := KnobsFile.load_into(BrawlerSettings.new(), SAVED) as BrawlerSettings

@export_group("Orugas")
## ADELANTE Y ATRÁS (MoveRamp, las rampas de la base común): la velocidad tope (m/s); cuánto tarda en llegar a ella
## (arranca pesado), en apagarse soltando (sigue un poco: la inercia) y en frenar apretando para el otro lado, cada una
## con su curva; y para atrás, qué parte de la tope.
@export_range(1.0, 40.0, 0.5) var speed := 10.0
@export_range(0.0, 8.0, 0.05) var up_time := 1.8
@export var up_shape := MoveCurve.Shape.EASE_IN
@export_range(0.0, 8.0, 0.05) var coast_time := 1.6
@export var coast_shape := MoveCurve.Shape.EASE_OUT
@export_range(0.0, 5.0, 0.05) var brake_time := 0.7
@export var brake_shape := MoveCurve.Shape.LINEAR
@export_range(0.1, 1.0, 0.05) var reverse_share := 0.5
## GIRAR LAS ORUGAS (en el lugar o andando): el giro tope (°/s) y cuánto tarda en llegar a él y en pararse (s).
@export_range(5.0, 180.0, 5.0) var turn_speed := 45.0
@export_range(0.0, 3.0, 0.05) var turn_time := 0.5

@export_group("Cintura")
## LA CINTURA gira aparte, sobre el aro de las orugas, hacia donde mira (°/s).
@export_range(10.0, 360.0, 5.0) var waist_speed := 70.0

@export_group("Horno")
## EL HORNO DEL PECHO: cuánto tarda la puerta en abrirse o cerrarse (s) y hasta cuántos grados se abre (para arriba).
@export_range(0.05, 3.0, 0.05) var door_time := 0.45
@export_range(30.0, 150.0, 5.0) var door_angle := 110.0

@export_group("Ira")
## CON IRA: cuánto tarda en cambiar de color y prender el humo (s) y cuánto más rápido andan las orugas y gira la
## cintura (veces).
@export_range(0.1, 5.0, 0.1) var rage_time := 1.2
@export_range(1.0, 3.0, 0.05) var rage_speed := 1.35

@export_group("Arena")
## EL RADIO DE LA ARENA (m; BossArena): el círculo del que no sale. El anillo del piso lo sigue al guardar; los edificios
## de afuera se acomodan regenerando la parcela (R).
@export_range(60.0, 220.0, 5.0) var arena_radius := 150.0
