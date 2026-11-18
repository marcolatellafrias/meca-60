class_name LegSettings
extends Resource

## LAS PERILLAS DE LOS PASOS de las piernas de la meca (ver BodyLegs): una sola copia para todas las mecas
## (`current`): las piernas son estructura y dibujo, compartidas (el usuario: «en estructura y visuales puede ser
## compartido»). Las arma su panel (LegsPanel, F4 en las filas de la meca).
##
## EL SISTEMA CLÁSICO DE PIERNAS CON IK (13/11/2026; el usuario: «empezar a reescribir desde 0… el sistema actual es uno
## derivado de los personajes y es medio rebuscado… es un trope bastante común el de piernas para mecas con IK»), hoy la
## marcha común (Gait). *El interruptor entre éstos y los de antes se fue con los de antes el 18/11/2026.*
##
## Se guarda (ver KnobsFile): el F4 tiene «Guardar» y «Volver a lo guardado». El archivo es del usuario.

const SAVED := "res://game/balance_body/leg_settings.tres"

static var current := KnobsFile.load_into(LegSettings.new(), SAVED) as LegSettings

@export_group("El paso")
## EL LARGO DEL PASO, lo que recorre un pie en el mundo (m, piernas medianas: se escala con su largo, F2): lo que avanza
## la caja en un ciclo de la marcha común (Gait; dos pasos, uno por pie).
@export_range(1.0, 24.0, 0.1) var stride := 12.0
## Cuánto sube el pie en un paso entero (m, piernas medianas).
@export_range(0.0, 4.0, 0.1) var lift := 2.0
## LO QUE DURA UN PASO EN EL AIRE, entre estos dos (s): un poco menos de medio ciclo, y el ciclo es lo que tarda la caja
## en recorrer un paso. Más rápido, más seguido; corriendo más que eso, el paso se alarga.
@export_range(0.1, 1.5, 0.05) var fastest := 0.3
@export_range(0.2, 2.0, 0.05) var slowest := 0.8

@export_group("La caja al caminar")
## LO QUE HACE LA CAJA CON LOS PASOS (18/11/2026; módulo Jefes, el sistema común: GaitSignals y la tabla de los
## personajes, ProceduralBoneAnimator; sólo dibujo). El usuario: «una curva leve de subir y bajar la pelvis… le da el
## feeling de meca»; «de costado, el torso entero se inclina un poco… adelante y atrás, nunca».
## Cuánto sube a mitad de cada paso (m, piernas medianas; 0, nada).
@export_range(0.0, 2.0, 0.05) var bob := 0.3
## EL PISOTÓN (18/11/2026; el usuario: «tunearlo para que se sienta más de una meca… pasos más largos»): el pie llega
## alto y adelante y baja de golpe (0 a 1; ver Gait.stomp), y al pisar la caja se hunde esto (m, piernas medianas).
@export_range(0.0, 1.0, 0.05) var stomp := 0.7
@export_range(0.0, 2.0, 0.05) var stomp_dip := 0.4
## Cuánto se inclina yendo de costado a la velocidad de caminar (°; 0, nada).
@export_range(0.0, 20.0, 0.5) var side_lean := 5.0

@export_group("Recogidas")
## RECOGIDAS (en el dash, levitando y en picada: KinematicMover.tucks), SUTIL: la pose de parada con el pie subido esta
## parte de la altura de la pierna (0 a 1) y la punta del pie hacia abajo (°). El usuario: «parecerse a la pose en
## reposo pero un poco más recogida nomás, y con los pies un poco apuntando hacia abajo».
@export_range(0.0, 0.8, 0.05) var tuck_lift := 0.25
@export_range(0.0, 80.0, 1.0) var tuck_toes := 30.0
