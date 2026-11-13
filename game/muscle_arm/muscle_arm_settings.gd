class_name MuscleArmSettings
extends Resource

## LAS PERILLAS DEL BRAZO CON MÚSCULOS (ver MuscleArm): una sola copia para todos (`current`), que arma su panel
## (MuscleArmPanel, F1 en la fila Brazo).

## Se guarda (ver KnobsFile): el F1 tiene «Guardar» y «Volver a lo guardado». El archivo es del usuario.
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

@export_group("Las piñas")
## Cuánto más rápido (o más lento) se piden las piñas: los tiempos de cada una, divididos por esto.
@export_range(0.2, 3.0, 0.05) var punch_speed := 1.0

@export_group("A mano (poseído)")
## Cuánto mueve la mano el mouse (m por cada 100 píxeles) y a qué velocidad la llevan W/S adelante y atrás (m/s).
@export_range(0.2, 6.0, 0.1) var mouse_reach := 1.6
@export_range(1.0, 30.0, 0.5) var depth_speed := 9.0
