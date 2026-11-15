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

@export_group("Embestida")
## LA EMBESTIDA (ver BrawlerBrain): el aviso (s: frena, se da vuelta hacia vos y abre el horno: la ventana), la velocidad
## (m/s) y cuánto tarda en llegar a ella (s), cuánto dura como mucho (s), cuánto corrige hacia vos (°/s: poco) y, si se
## estrella contra el borde de la arena, cuánto queda aturdido (s, con el horno abierto). Si te alcanza, cuánta vida te
## saca y cuánto te cambia la velocidad (m/s; a la meca física).
## AJUSTADO CONTRA LA MECA CINEMÁTICA (15/11/2026, tests/brawler_dodge_check): 5 s cruzan la arena (con 3 no llegaba
## desde 110 m); corrigiendo 6°/s, caminar de costado no alcanza, pero dos dashes seguidos cuando le faltan 24–32 m sí
## (con 12°/s no la esquivaba nada).
## MÁS RÁPIDA (15/11/2026, el usuario: «la embestida es lentísima, hacela mucho más rápida»): de 26 a 55 m/s, llega en
## 0,3 s y dura 3 s (cruza la arena igual).
@export_range(0.2, 4.0, 0.05) var charge_windup := 1.4
@export_range(5.0, 120.0, 0.5) var charge_speed := 55.0
@export_range(0.0, 3.0, 0.05) var charge_up_time := 0.3
@export_range(0.5, 8.0, 0.1) var charge_time := 3.0
@export_range(0.0, 60.0, 1.0) var charge_homing := 6.0
@export_range(0.2, 8.0, 0.1) var stun_time := 2.5
@export_range(0.0, 100.0, 1.0) var charge_damage := 25.0
@export_range(0.0, 60.0, 0.5) var charge_push := 18.0

@export_group("Golpe al piso")
## EL GOLPE DOBLE AL PISO (ver BrawlerBrain, BrawlerWave): cuánto tiene los brazos arriba (s: el aviso, con la franja en
## el piso que sigue a la cintura), cuánto se queda después (s), y la onda: a qué velocidad corre (m/s), hasta dónde
## (m) y qué ancho tiene (m). Si te alcanza apoyada (saltando, no), cuánta vida te saca y cuánto te levanta (m/s; a la
## meca física). La onda, de 45 a 60 m/s (el usuario: «la piedra del suelo también un poco más rápida»).
@export_range(0.3, 4.0, 0.05) var slam_windup := 1.3
@export_range(0.2, 4.0, 0.05) var slam_recover := 1.4
@export_range(5.0, 120.0, 1.0) var wave_speed := 60.0
@export_range(20.0, 250.0, 5.0) var wave_reach := 140.0
@export_range(2.0, 40.0, 0.5) var wave_width := 14.0
@export_range(0.0, 100.0, 1.0) var wave_damage := 20.0
@export_range(0.0, 40.0, 0.5) var wave_push := 10.0

@export_group("Arrancar el piso")
## ARRANCAR EL PISO Y TIRARLO (ver BrawlerBrain, BrawlerRock): cuánto tarda en meter las manos y arrancarlo (s), cuánto
## la tiene arriba (s: el aviso, con el círculo rojo que te sigue), cuánto vuela (s: de lejos va más rápido, siempre
## tarda eso), cuánto sube el arco (m), el radio del golpe (m), cuánto queda en el piso si no le pegó a nadie (s) y cuánto
## se queda después de tirarla (s). Si te alcanza, cuánta vida te saca y cuánto te empuja (m/s; a la meca física).
## MEDIDO CONTRA LA MECA CINEMÁTICA (15/11/2026, tests/brawler_dodge_check --solo-piedra): con radio 9 y 1,8 s de vuelo,
## quieta le cae encima y caminando de costado (desde el aviso o desde el tiro) o con el dash, no. Es al filo: con 1,3 s
## de vuelo, caminando ya no llega (sólo el dash).
@export_range(0.2, 4.0, 0.05) var rip_time := 1.0
@export_range(0.2, 4.0, 0.05) var lift_time := 1.1
@export_range(0.3, 4.0, 0.05) var rock_flight := 1.8
@export_range(0.0, 80.0, 1.0) var rock_arc := 35.0
@export_range(3.0, 25.0, 0.5) var rock_radius := 9.0
@export_range(0.0, 30.0, 0.5) var rock_stay := 8.0
@export_range(0.2, 4.0, 0.05) var throw_recover := 1.2
@export_range(0.0, 100.0, 1.0) var rock_damage := 30.0
@export_range(0.0, 60.0, 0.5) var rock_push := 14.0

@export_group("Trompo")
## EL TROMPO (ver BrawlerBrain): abre los brazos y empieza a girar (s: el aviso), gira tanto tiempo (s) a tantos °/s
## andando hacia vos con las orugas (a tantos m/s, con su arranque corto: el de la embestida), y después queda MAREADO (s, con el horno abierto: la
## ventana). Si te alcanzan los brazos (hasta dónde llegan, m desde su medio), cuánta vida te saca y cuánto te empuja
## (m/s, de costado; a la meca física).
@export_range(0.2, 4.0, 0.05) var spin_windup := 1.0
@export_range(0.5, 8.0, 0.1) var spin_time := 3.0
@export_range(90.0, 1440.0, 10.0) var spin_speed := 540.0
@export_range(1.0, 40.0, 0.5) var spin_move := 12.0
@export_range(0.2, 6.0, 0.1) var spin_dizzy := 2.0
@export_range(10.0, 50.0, 0.5) var spin_reach := 30.0
@export_range(0.0, 100.0, 1.0) var spin_damage := 20.0
@export_range(0.0, 60.0, 0.5) var spin_push := 16.0

@export_group("Agarre")
## EL AGARRE Y REVOLEO (ver BrawlerBrain, BrawlerHook): UN SKILLSHOT. El aviso (s: la franja sigue a la cintura) y, al
## final, cuánto se queda quieta antes del tiro (s: ya apuntó, corréte); la mano: a qué velocidad sale (m/s), hasta dónde
## (m) y qué ancho tiene la franja (m). Si te agarra: cuánto te revolea (s, a tantos °/s) y te tira lejos (m), con su
## arco (m de alto, s de vuelo); al caer, cuánta vida te saca. Después se queda (s).
@export_range(0.2, 4.0, 0.05) var hook_windup := 1.0
@export_range(0.0, 2.0, 0.05) var hook_lock := 0.6
@export_range(20.0, 200.0, 5.0) var hook_speed := 90.0
@export_range(20.0, 150.0, 5.0) var hook_reach := 85.0
@export_range(2.0, 20.0, 0.5) var hook_width := 6.0
@export_range(0.2, 4.0, 0.05) var swing_time := 1.2
@export_range(90.0, 1080.0, 10.0) var swing_speed := 400.0
@export_range(10.0, 150.0, 5.0) var fling_distance := 70.0
@export_range(0.0, 60.0, 1.0) var fling_arc := 25.0
@export_range(0.3, 4.0, 0.05) var fling_time := 1.3
@export_range(0.0, 100.0, 1.0) var fling_damage := 35.0
@export_range(0.2, 4.0, 0.05) var hook_recover := 1.0

@export_group("Golpes")
## LO QUE LE SACA UNA PIÑA DE LA MECA: en el cuerpo, y en el horno abierto (el punto débil).
@export_range(0.0, 100.0, 1.0) var punch_damage := 6.0
@export_range(0.0, 200.0, 1.0) var furnace_damage := 30.0

@export_group("Arena")
## EL RADIO DE LA ARENA (m; BossArena): el círculo del que no sale. El anillo del piso lo sigue al guardar; los edificios
## de afuera se acomodan regenerando la parcela (R).
@export_range(60.0, 220.0, 5.0) var arena_radius := 150.0
