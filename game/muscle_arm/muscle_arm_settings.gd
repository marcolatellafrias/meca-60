class_name MuscleArmSettings
extends Resource

## LAS PERILLAS DEL BRAZO CON MÚSCULOS (ver MuscleArm): una sola copia para todos (`current`), que arma su panel
## (ArmsPanel: F3 en la fila de la meca jaula; hasta el 17/11/2026, también el F1 de la fila Brazo, borrada ese día).

## Se guarda (ver KnobsFile): el F3 tiene «Guardar» y «Volver a lo guardado». El archivo es del usuario.
const SAVED := "res://game/muscle_arm/muscle_arm_settings.tres"

static var current := KnobsFile.load_into(MuscleArmSettings.new(), SAVED) as MuscleArmSettings

@export_group("Los músculos")
## Cada músculo gira su pieza hacia donde la pide la pose: cuánto tira por radián que le falta (1/s²) y cuánto frena
## por rad/s (1/s). Con más, el brazo es más firme y más rápido; con menos, más flojo.
@export_range(10.0, 1500.0, 5.0) var muscle_kp := 420.0
@export_range(1.0, 120.0, 1.0) var muscle_kd := 34.0
## LA FUERZA: lo más que puede acelerar su pieza (rad/s²). Es lo que decide si puede con lo que tiene adelante: con
## poca, algo pesado lo frena o lo traba.
@export_range(10.0, 2000.0, 10.0) var muscle_max := 420.0
## SEGUIR LA VELOCIDAD PEDIDA (14/11/2026; el usuario: «se mueven muy lento… es muy clunky y no se siente responsive»,
## pero que siga sintiéndose físico): el freno del músculo no frena contra quedarse quieto sino contra la velocidad a la
## que se mueve la pose pedida (una piña), así que arranca a tiempo en vez de esperar a quedarse atrás. 0: como antes
## (frena todo movimiento); 1: sigue la velocidad entera. La fuerza tope es la misma: no empuja más fuerte.
@export_range(0.0, 1.0, 0.05) var follow := 1.0

## *Atravesar o no (17/11/2026) pasó a los golpes de todos los brazos (StrikeSettings) el 18/11/2026.*

@export_group("Las piñas")
## Cuánto más rápido (o más lento) se piden las piñas: los tiempos de cada una, divididos por esto.
@export_range(0.2, 3.0, 0.05) var punch_speed := 1.0

@export_group("A mano (poseído)")
## Cuánto mueve la mano el mouse (m por cada 100 píxeles) y a qué velocidad la llevan W/S adelante y atrás (m/s).
@export_range(0.2, 6.0, 0.1) var mouse_reach := 1.6
@export_range(1.0, 30.0, 0.5) var depth_speed := 9.0
