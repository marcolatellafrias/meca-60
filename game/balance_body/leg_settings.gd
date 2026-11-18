class_name LegSettings
extends Resource

## LAS PERILLAS DE LOS PASOS NUEVOS de las piernas de la meca (ver BodyLegs): una sola copia para todas las mecas
## (`current`): las piernas son estructura y dibujo, compartidas (el usuario: «en estructura y visuales puede ser
## compartido»). Las arma su panel (LegsPanel, F4 en las filas de la meca).
##
## EL SISTEMA CLÁSICO DE PIERNAS CON IK (13/11/2026; el usuario: «empezar a reescribir desde 0… el sistema actual es uno
## derivado de los personajes y es medio rebuscado… es un trope bastante común el de piernas para mecas con IK»). Mientras
## se comparan, el interruptor elige entre los de antes y los nuevos.
##
## Se guarda (ver KnobsFile): el F4 tiene «Guardar» y «Volver a lo guardado». El archivo es del usuario.

const SAVED := "res://game/balance_body/leg_settings.tres"

static var current := KnobsFile.load_into(LegSettings.new(), SAVED) as LegSettings

@export_group("Cuáles")
## Los pasos nuevos (el sistema clásico) o los de antes (BodySettings, «Las piernas» del F1).
@export var new_steps := true

@export_group("El paso")
## EL LARGO DEL PASO, lo que recorre un pie en el mundo (m, piernas medianas: se escala con su largo, F2): lo que avanza
## la caja en un ciclo de la marcha común (Gait; dos pasos, uno por pie).
@export_range(1.0, 12.0, 0.1) var stride := 6.0
## Cuánto sube el pie en un paso entero (m, piernas medianas).
@export_range(0.0, 4.0, 0.1) var lift := 1.4
## LO QUE DURA UN PASO EN EL AIRE, entre estos dos (s): un poco menos de medio ciclo, y el ciclo es lo que tarda la caja
## en recorrer un paso. Más rápido, más seguido; corriendo más que eso, el paso se alarga.
@export_range(0.1, 1.5, 0.05) var fastest := 0.2
@export_range(0.2, 2.0, 0.05) var slowest := 0.7

