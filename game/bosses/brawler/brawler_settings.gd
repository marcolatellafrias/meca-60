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

@export_group("Modos")
## SUS MODOS (BossMode, 17/11/2026): tramos de la pelea con otras reglas, una pestaña por modo en el panel. LA IRA (cada
## 40 s tranquilo, 18 s: más rápido, encadena, variantes fuertes, se ve con ira) y EL VUELO (apagado de entrada: sube
## con sus propulsores y pelea desde arriba con lo que no pide suelo). El orden es el de los tildes de cada poder.
## `rage_time`: cuánto tarda en cambiar de color y prender el humo (s).
@export_range(0.1, 5.0, 0.1) var rage_time := 1.2
@export var rage: BossMode = BrawlerSettings.make_rage()
@export var flight: BossMode = BrawlerSettings.make_flight()

@export_group("Poderes")
## SUS PODERES (BossPower, 17/11/2026): cada uno con su tilde y sus variantes, una pestaña por poder en el panel. El
## orden es el de BrawlerBrain.Act.
@export var charge: ChargePower = ChargePower.new()
@export var slam: SlamPower = SlamPower.new()
@export var throw: ThrowPower = ThrowPower.new()
@export var spin: SpinPower = SpinPower.new()
@export var hook: HookPower = HookPower.new()
@export var flame: FlamePower = FlamePower.new()

@export_group("Golpes")
## LO QUE LE SACA UNA PIÑA DE LA MECA: en el cuerpo, y en el horno abierto (el punto débil).
@export_range(0.0, 100.0, 1.0) var punch_damage := 6.0
@export_range(0.0, 200.0, 1.0) var furnace_damage := 30.0
## LOS TIROS, EL RAYO Y EL TALADRO DE LA MECA DE TRES (ver BossHurtbox): cuánta vida le sacan por cada 100.000 kg·m/s
## de empujón (un tiro simple empuja 70.000; el súper cargado, 600.000; el rayo, 150.000 por segundo). En el horno
## abierto, tantas veces más como la piña en el horno sobre la del cuerpo. Y lo más que saca un golpe en el cuerpo (el
## taladro cargado empuja mucho: sin tope sacaba 38).
@export_range(0.0, 50.0, 0.5) var energy_damage := 4.0
@export_range(1.0, 100.0, 1.0) var energy_cap := 12.0

@export_group("Arena")
## EL RADIO DE LA ARENA (m; BossArena): el círculo del que no sale. El anillo del piso lo sigue al guardar; los edificios
## de afuera se acomodan regenerando la parcela (R).
@export_range(60.0, 220.0, 5.0) var arena_radius := 150.0


## Sus modos, en el orden de los tildes de los poderes (con su nombre).
func modes() -> Array[BossMode]:
	rage.title = "ira"
	flight.title = "vuelo"
	return [rage, flight]


static func make_rage() -> BossMode:
	return BossMode.new()


static func make_flight() -> BossMode:
	var mode := BossMode.new()
	mode.on = false
	mode.every = 60.0
	mode.lasts = 20.0
	mode.hurry = 1.0
	mode.chain = 0.0
	mode.strong = false
	mode.fly_height = 30.0
	mode.keep_from = 30.0
	mode.keep_to = 55.0
	mode.fury_look = false
	return mode


## Sus poderes, en el orden de BrawlerBrain.Act.
func powers() -> Array[BossPower]:
	return [charge, slam, throw, spin, hook, flame]
